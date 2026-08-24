/*
 * /vendor/lib/libmedia.so untuk A37.
 *
 * libril-qc-qmi-1.so menautnya lewat DT_NEEDED, dan tanpa berkas ber-soname itu
 * di namespace vendor rild tidak pernah jalan:
 *
 *   RILD: dlopen failed: library "libmedia.so" not found:
 *         needed by /system/vendor/lib/libril-qc-qmi-1.so
 *
 * KENAPA STUB KOSONG TIDAK CUKUP
 *
 * Versi pertama berkas ini kosong, berdasarkan pengukuran yang KELIRU: saya
 * mengiris simbol UND blob dengan simbol yang MASIH ADA di libmedia sekarang,
 * hasilnya nol. Yang luput adalah simbol yang justru sudah DICABUT dari libmedia
 * modern -- karena tidak ada di libmedia sekarang, ia tidak muncul di irisan itu.
 * Akibatnya rild maju satu langkah lalu gagal lagi:
 *
 *   RILD: dlopen failed: cannot locate symbol
 *         "_ZN7android11AudioSystem13setParametersEiRKNS_7String8E"
 *
 * Pengukuran ulang yang benar -- simbol android:: milik blob dikurangi seluruh
 * simbol yang tersedia di /vendor/lib -- memberi TEPAT DUA yang hilang, dan
 * keduanya ada di bawah. Dua belas simbol android:: lainnya sudah tersedia.
 *
 * BATASAN YANG DIKETAHUI
 *
 * Keduanya no-op. setParameters mengembalikan OK tanpa meneruskan apa pun, dan
 * getParameters mengembalikan String8 kosong. Artinya parameter audio yang
 * dikirim RIL (mis. perutean audio saat panggilan) TIDAK sampai ke audio HAL.
 * Panggilan suara mungkin tidak berbunyi sebagaimana mestinya.
 *
 * Meneruskannya ke AudioSystem modern tidak bisa dilakukan dari sini: tanda
 * tangannya sudah berubah (tanpa audio_io_handle_t) dan implementasinya di
 * libaudioclient yang native:platform, tak boleh ditaut modul vendor.
 *
 * Pertukaran yang disengaja: tanpa berkas ini rild tidak jalan sama sekali,
 * sehingga tidak ada sinyal seluler apa pun. Kalau nanti panggilan suara
 * terbukti bisu, jalan yang benar adalah menjembatani ke audio HAL lewat jalur
 * vendor, bukan memperluas stub ini.
 *
 * SIMBOL KETIGA: setErrorCallback
 *
 * Perangkat ini dual-SIM dan menjalankan DUA layanan dari biner rild yang sama:
 *
 *   ril-daemon2         /vendor/bin/hw/rild -c 2   init.qcom.rc:203  -> running
 *   vendor.ril-daemon   /vendor/bin/hw/rild        rild.rc:1         -> restarting
 *
 * Hanya ril-daemon2 yang punya "setenv LD_PRELOAD /vendor/lib/libril_shim.so",
 * karena baris itu ada di init.qcom.rc milik device tree ini. Layanan satunya
 * didefinisikan di hardware/ril/rild/rild.rc milik hulu ULH, yang TIDAK memuat
 * setenv tersebut -- meski komentar di init.qcom.rc:209 menyatakan sebaliknya.
 * Klaim itu keliru; berkas hulunya tidak pernah ditambal.
 *
 * Karena itu setErrorCallback (satu-satunya simbol libril_shim yang benar-benar
 * dibutuhkan blob) ikut disediakan di sini. libmedia.so ditarik lewat DT_NEEDED
 * oleh blob itu sendiri, jadi kedua layanan mendapatkannya tanpa LD_PRELOAD dan
 * tanpa perlu menambal rc hulu.
 *
 * Pengukuran yang mendasarinya: 305 simbol UND blob dikurangi seluruh simbol
 * yang diekspor /vendor/lib TANPA libril_shim, sufiks versi (@@LIBBINDER dsb)
 * dibuang lebih dulu. Sisanya hanya simbol libc -- yang memang datang dari
 * /system/lib, di luar cakupan pindaian -- plus setErrorCallback. Pada
 * pengukuran pertama sufiks versi tidak dibuang, sehingga
 * ProcessState::self() dan startThreadPool() sempat terlihat hilang padahal
 * keduanya ada di /vendor/lib/libbinder.so sebagai simbol ber-versi.
 *
 * LD_PRELOAD di ril-daemon2 sengaja DIBIARKAN. Layanan itu sudah berjalan, dan
 * definisi ganda tidak berbahaya: pustaka preload menang lebih dulu.
 */

#define LOG_TAG "A37LibmediaStub"

#include <log/log.h>
#include <utils/Errors.h>
#include <utils/String8.h>

namespace android {

// Tanda tangan lama AudioSystem (dengan audio_io_handle_t) yang masih dituntut
// blob RIL 2016. Dideklarasikan ulang di sini supaya kompiler menghasilkan nama
// ter-mangle yang persis sama dengan yang dicari linker.
typedef void (*audio_error_callback)(int);

class AudioSystem {
public:
    static status_t setParameters(int ioHandle, const String8& keyValuePairs);
    static String8 getParameters(int ioHandle, const String8& keys);
    static void setErrorCallback(audio_error_callback cb);

    // Disalin apa adanya dari libshims/AudioSystem_ril.cpp. Specifier akses
    // tidak memengaruhi mangling, jadi nama simbolnya tetap
    // _ZN7android11AudioSystem19gAudioErrorCallbackE.
    static audio_error_callback gAudioErrorCallback;
};

audio_error_callback AudioSystem::gAudioErrorCallback = nullptr;

void AudioSystem::setErrorCallback(audio_error_callback cb) {
    gAudioErrorCallback = cb;
}

status_t AudioSystem::setParameters(int, const String8& keyValuePairs) {
    ALOGD("libmedia stub A37: setParameters diabaikan: %s", keyValuePairs.c_str());
    return NO_ERROR;
}

String8 AudioSystem::getParameters(int, const String8& keys) {
    ALOGD("libmedia stub A37: getParameters mengembalikan kosong untuk: %s", keys.c_str());
    return String8();
}

}  // namespace android
