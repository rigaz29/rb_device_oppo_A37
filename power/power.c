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
 *   boostpulse - pulse sepanjang boostpulse_duration (60 ms, diset init.qcom.power.rc)
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

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

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

    default:
        /*
         * POWER_HINT_LOW_POWER sengaja tidak ditangani: membatasi frekuensi
         * butuh mengubah scaling_max_freq dan memulihkannya lagi, yang perlu
         * diuji di perangkat. Battery saver tetap bekerja di level framework.
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
