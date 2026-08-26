/*
 * Copyright (C) 2016 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#define LOG_TAG "PowerHAL"

#include <hardware/hardware.h>
#include <hardware/power.h>

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <utils/Log.h>

/*
 * DT2W memakai gesture firmware Synaptics yang dikendalikan lewat procfs.
 *
 * Driver hanya memasang IRQ wake gesture pada suspend berikutnya; sehingga
 * perubahan toggle saat layar hidup berlaku ketika layar kembali dimatikan.
 */

/*
 * Tunables governor "interactive". init.qcom.power.rc menyetel governor ini
 * lewat path GLOBAL (bukan per-policy), jadi atributnya ada di direktori ini.
 *
 * Yang dipakai:
 *   boost      - sustained boost; 1 menahan frekuensi tinggi sampai ditulis 0
 *   boostpulse - pulse sepanjang boostpulse_duration (120 ms; init.qcom.power.rc
 *                menulis 120000 us ke boostpulse_duration)
 *
 * Parameter cpu_boost di bawah /sys/module/cpu_boost/parameters sengaja TIDAK
 * dipakai di sini:
 * boost_ms cuma module_param biasa tanpa callback, jadi menulisnya hanya
 * mengubah durasi untuk event sync cpufreq — bukan pemicu boost on-demand.
 * Sentuhan layar sendiri sudah ditangani cpu_boost langsung di kernel lewat
 * input_register_handler(), tanpa perlu userspace.
 */
#define INTERACTIVE_PATH "/sys/devices/system/cpu/cpufreq/interactive/"
#define BOOST_PATH       INTERACTIVE_PATH "boost"
#define BOOSTPULSE_PATH  INTERACTIVE_PATH "boostpulse"
#define DOUBLE_TAP_TO_WAKE_PATH "/proc/touchpanel/double_tap_enable"

/*
 * Pembatasan frekuensi untuk LOW_POWER dan SUSTAINED_PERFORMANCE.
 *
 * Keempat inti berada dalam SATU domain frekuensi (related_cpus = 0 1 2 3),
 * jadi menulis scaling_max_freq milik cpu0 saja sudah merambat ke cpu1-3.
 * Diverifikasi di perangkat: setelah menulis 998400 ke cpu0, keempat inti
 * melaporkan max 998400 dan scaling_cur_freq langsung turun mengikutinya.
 * Tidak ada path cpufreq global seperti interactive/ untuk atribut ini.
 *
 * Berkasnya milik system:system dengan mode 0664; HAL ini berjalan sebagai
 * user system (android.hardware.power@1.0-service), jadi berhak menulis.
 *
 * Frekuensi yang tersedia di msm8916 A37:
 *   200000 400000 533333 800000 998400 1094400 1152000 1209600
 */
#define CPUFREQ_PATH          "/sys/devices/system/cpu/cpu0/cpufreq/"
#define SCALING_MAX_FREQ_PATH CPUFREQ_PATH "scaling_max_freq"

/*
 * LOW_POWER dipakai battery saver: hemat nyata tapi perangkat tetap terpakai.
 * SUSTAINED_PERFORMANCE menuntut performa STABIL yang bisa dipertahankan tanpa
 * throttling termal, bukan performa tertinggi -- karena itu dibatasi di bawah
 * puncak. Perangkat ini tidak punya HAL thermal; proteksi panas ada di kernel
 * (msm_thermal), jadi memberi jarak dari 1209600 membuat frekuensinya tidak
 * naik-turun saat msm_thermal ikut campur.
 */
#define LOW_POWER_MAX_FREQ  "800000"
#define SUSTAINED_MAX_FREQ  "998400"

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

/* Keadaan pembatasan frekuensi. Semuanya hanya disentuh sambil memegang lock. */
static int  low_power_active = 0;
static int  sustained_active = 0;
static char saved_max_freq[32] = "";  /* nilai sebelum kami membatasi */
static char applied_cap[32]    = "";  /* batas yang terakhir kami tulis */

static void sysfs_write(const char *path, const char *val)
{
    char errbuf[80];
    int fd;
    ssize_t len;

    fd = open(path, O_WRONLY);
    if (fd < 0) {
        /*
         * ENOENT itu wajar: governor sedang bukan "interactive" (init.qcom.power.rc
         * memakai "powersave" pada mode charger), jadi atributnya memang tidak
         * ada. Jangan banjiri log untuk kondisi normal.
         */
        if (errno != ENOENT) {
            strerror_r(errno, errbuf, sizeof(errbuf));
            ALOGE("open %s: %s", path, errbuf);
        }
        return;
    }

    len = write(fd, val, strlen(val));
    if (len < 0) {
        strerror_r(errno, errbuf, sizeof(errbuf));
        ALOGE("write %s: %s", path, errbuf);
    }

    close(fd);
}

static int sysfs_read(const char *path, char *buf, size_t size)
{
    char errbuf[80];
    int fd;
    ssize_t len;

    fd = open(path, O_RDONLY);
    if (fd < 0) {
        if (errno != ENOENT) {
            strerror_r(errno, errbuf, sizeof(errbuf));
            ALOGE("open %s: %s", path, errbuf);
        }
        return 0;
    }

    len = read(fd, buf, size - 1);
    close(fd);

    if (len <= 0) {
        return 0;
    }

    buf[len] = '\0';
    while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r')) {
        buf[--len] = '\0';
    }

    return 1;
}

/*
 * Menerapkan batas frekuensi efektif dari kedua mode, atau memulihkannya.
 * Pemanggil WAJIB sudah memegang `lock`.
 *
 * LOW_POWER dan SUSTAINED_PERFORMANCE memakai knob yang sama dan bisa aktif
 * bersamaan, jadi yang berlaku adalah batas TERENDAH di antara keduanya.
 *
 * Pemulihan sengaja berhati-hati: nilai asli hanya dibaca sekali (saat batas
 * pertama dipasang), dan dikembalikan HANYA kalau batas kami masih yang
 * berlaku saat itu. Kalau ada pihak lain -- msm_thermal misalnya -- sempat
 * menurunkan scaling_max_freq sendiri, kami tidak menimpanya.
 */
static void apply_freq_cap_locked(void)
{
    const char *cap = NULL;
    char now[32];

    if (low_power_active && sustained_active) {
        cap = (atoi(LOW_POWER_MAX_FREQ) < atoi(SUSTAINED_MAX_FREQ))
                ? LOW_POWER_MAX_FREQ : SUSTAINED_MAX_FREQ;
    } else if (low_power_active) {
        cap = LOW_POWER_MAX_FREQ;
    } else if (sustained_active) {
        cap = SUSTAINED_MAX_FREQ;
    }

    if (cap != NULL) {
        if (applied_cap[0] == '\0') {
            /*
             * Belum ada batas terpasang: simpan nilai asli lebih dulu. Kalau
             * pembacaan gagal, jangan menyentuh apa pun -- lebih baik hint ini
             * diabaikan daripada frekuensi tertinggal terbatas selamanya.
             */
            if (!sysfs_read(SCALING_MAX_FREQ_PATH, saved_max_freq,
                            sizeof(saved_max_freq))) {
                ALOGE("%s: gagal membaca %s, batas tidak dipasang",
                      __func__, SCALING_MAX_FREQ_PATH);
                return;
            }
        }

        sysfs_write(SCALING_MAX_FREQ_PATH, cap);
        snprintf(applied_cap, sizeof(applied_cap), "%s", cap);
        ALOGI("%s: batas frekuensi %s kHz (low_power=%d sustained=%d)",
              __func__, cap, low_power_active, sustained_active);
        return;
    }

    if (applied_cap[0] == '\0') {
        return;  /* tidak pernah membatasi, tidak ada yang perlu dipulihkan */
    }

    if (sysfs_read(SCALING_MAX_FREQ_PATH, now, sizeof(now))
            && strcmp(now, applied_cap) != 0) {
        ALOGI("%s: scaling_max_freq kini %s, bukan batas kami %s -- dibiarkan",
              __func__, now, applied_cap);
    } else {
        sysfs_write(SCALING_MAX_FREQ_PATH, saved_max_freq);
        ALOGI("%s: batas dilepas, dipulihkan ke %s kHz",
              __func__, saved_max_freq);
    }

    applied_cap[0] = '\0';
}

static void power_init(__attribute__((unused)) struct power_module *module)
{
    ALOGI("%s", __func__);
}

static void power_set_interactive(__attribute__((unused)) struct power_module *module,
                                  int on)
{
    /*
     * Layar mati: lepaskan sustained boost kalau masih tertahan, supaya
     * frekuensi tidak ditahan tinggi selama layar padam. Saat layar menyala
     * tidak ada yang perlu dilakukan — governor interactive dan cpu_boost
     * sudah menangani sendiri.
     */
    if (!on) {
        pthread_mutex_lock(&lock);
        sysfs_write(BOOST_PATH, "0");
        pthread_mutex_unlock(&lock);
    }
}

static void power_set_feature(__attribute__((unused)) struct power_module *module,
                              feature_t feature, int state)
{
    switch (feature) {
    case POWER_FEATURE_DOUBLE_TAP_TO_WAKE:
        /* The driver accepts exactly 0 or 1; state is supplied by PowerManager. */
        pthread_mutex_lock(&lock);
        sysfs_write(DOUBLE_TAP_TO_WAKE_PATH, state ? "1" : "0");
        pthread_mutex_unlock(&lock);
        break;

    default:
        /* Unsupported features are intentionally ignored by this legacy HAL. */
        break;
    }
}

static void power_hint(__attribute__((unused)) struct power_module *module,
                       power_hint_t hint, void *data)
{
    switch (hint) {
    case POWER_HINT_LAUNCH:
        /*
         * PENTING: jangan dereference `data`. android.hardware.power@1.0-impl
         * (Power.cpp) hanya mengirim pointer non-NULL kalau nilainya bukan nol:
         *   if (data) powerHint(..., &param); else powerHint(..., NULL);
         * RootActivityContainer.java mengirim 1 saat peluncuran mulai dan 0 saat
         * selesai, jadi 0 sampai ke sini sebagai NULL. Keberadaan pointernya
         * sendiri yang menjadi flag.
         */
        pthread_mutex_lock(&lock);
        sysfs_write(BOOST_PATH, data ? "1" : "0");
        pthread_mutex_unlock(&lock);
        break;

    case POWER_HINT_INTERACTION:
        /*
         * Selalu dikirim dengan data=0, jadi `data` di sini selalu NULL —
         * jangan dibaca. Yang benar-benar butuh ini adalah interaksi TANPA
         * sentuhan: rotasi layar (DisplayRotation.java) dan animasi window
         * (SurfaceAnimationRunner.java). Untuk sentuhan sendiri pulse ini
         * berlebihan tapi tidak berbahaya — cuma memperpanjang boostpulse_endtime.
         */
        pthread_mutex_lock(&lock);
        sysfs_write(BOOSTPULSE_PATH, "1");
        pthread_mutex_unlock(&lock);
        break;

    case POWER_HINT_LOW_POWER:
        /*
         * Battery saver menyala/mati. Sama seperti LAUNCH, `data` non-NULL
         * berarti aktif dan NULL berarti nonaktif (Power.cpp:47-54 hanya
         * mengirim pointer kalau nilainya bukan nol) -- jangan di-dereference.
         *
         * Sebelumnya hint ini sengaja diabaikan karena pemulihan
         * scaling_max_freq belum teruji. Sudah diuji sekarang: menulis 998400
         * lalu 1209600 ke cpu0 berhasil dan merambat ke keempat inti.
         */
        pthread_mutex_lock(&lock);
        low_power_active = data ? 1 : 0;
        apply_freq_cap_locked();
        pthread_mutex_unlock(&lock);
        break;

    case POWER_HINT_SUSTAINED_PERFORMANCE:
        /*
         * Aplikasi meminta performa yang bisa dipertahankan lama (umumnya game
         * lewat Window.setSustainedPerformanceMode). Kontraknya BUKAN performa
         * tertinggi, melainkan performa yang STABIL: lebih baik sedikit lebih
         * rendah tetapi rata daripada tinggi lalu dijatuhkan termal di tengah
         * jalan. Karena itu dibatasi ke SUSTAINED_MAX_FREQ.
         *
         * Semantik `data` sama dengan LOW_POWER di atas.
         */
        pthread_mutex_lock(&lock);
        sustained_active = data ? 1 : 0;
        apply_freq_cap_locked();
        pthread_mutex_unlock(&lock);
        break;

    default:
        /*
         * Hint lain sengaja diabaikan. VSYNC dan VIDEO_ENCODE/DECODE tidak
         * punya padanan yang berarti pada governor interactive di perangkat
         * ini, dan VR_MODE tidak relevan.
         */
        break;
    }
}

static int power_open(const hw_module_t* module, const char* name,
                    hw_device_t** device)
{
    ALOGD("%s: enter; name=%s", __FUNCTION__, name);

    if (strcmp(name, POWER_HARDWARE_MODULE_ID)) {
        return -EINVAL;
    }

    power_module_t *dev = (power_module_t *)calloc(1,
            sizeof(power_module_t));

    if (!dev) {
        ALOGD("%s: failed to allocate memory", __FUNCTION__);
        return -ENOMEM;
    }

    dev->common.tag = HARDWARE_MODULE_TAG;
    dev->common.module_api_version = POWER_MODULE_API_VERSION_0_3;
    dev->common.hal_api_version = HARDWARE_HAL_API_VERSION;

    dev->init = power_init;
    dev->setInteractive = power_set_interactive;
    dev->powerHint = power_hint;
    dev->setFeature = power_set_feature;
    *device = (hw_device_t*)dev;

    ALOGD("%s: exit", __FUNCTION__);

    return 0;
}

static struct hw_module_methods_t power_module_methods = {
    .open = power_open,
};

struct power_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = POWER_MODULE_API_VERSION_0_3,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = POWER_HARDWARE_MODULE_ID,
        .name = "msm8916 Power HAL",
        .author = "The LineageOS Project",
        .methods = &power_module_methods,
    },

    .init = power_init,
    .setInteractive = power_set_interactive,
    .powerHint = power_hint,
    .setFeature = power_set_feature

};
