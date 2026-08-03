/*
 * Shim untuk /system/vendor/lib/libril-qc-qmi-1.so
 *
 * Blob RIL OPPO (dibangun untuk Android 5.1) merujuk simbol:
 *
 *     android::AudioSystem::setErrorCallback(void (*)(int))
 *     _ZN7android11AudioSystem16setErrorCallbackEPFviE
 *
 * Simbol itu DIHAPUS SEPENUHNYA dari libaudioclient di Android 11 —
 * diverifikasi dua arah: tidak ada di ekspor libaudioclient.so hasil build
 * (llvm-readelf --dyn-syms) dan tidak ada lagi deklarasinya di
 * frameworks/av/media/libaudioclient/include/media/AudioSystem.h.
 *
 * Tanpa simbol ini rild gagal memuat blob sejak boot:
 *
 *     E RILD: dlopen failed: cannot locate symbol
 *       "_ZN7android11AudioSystem16setErrorCallbackEPFviE"
 *       referenced by "/system/vendor/lib/libril-qc-qmi-1.so"
 *
 * Akibat berantainya: IRadio tidak pernah register, com.android.phone
 * menggantung di IRadio.getService() saat PhoneGlobals.onCreate, lalu kena
 * ANR berulang dan di-kill "bg anr".
 *
 * Dulu fungsi ini mendaftarkan callback yang dipanggil ketika audioserver
 * mati, supaya klien bisa membangun ulang state audionya. Di Android 11
 * penanganan kematian audioserver sudah ditangani internal oleh
 * libaudioclient lewat death recipient, sehingga stub kosong sudah memadai:
 * blob hanya perlu simbolnya ada agar dlopen berhasil, dan callback-nya
 * memang tidak akan pernah dipanggil siapa pun.
 *
 * Callback-nya tetap disimpan supaya stub ini tidak membuang argumen tanpa
 * jejak, dan agar mudah dipasangi logging kalau nanti perlu diselidiki.
 */

namespace android {

typedef void (*audio_error_callback)(int);

class AudioSystem {
public:
    static void setErrorCallback(audio_error_callback cb);

private:
    static audio_error_callback gAudioErrorCallback;
};

audio_error_callback AudioSystem::gAudioErrorCallback = nullptr;

void AudioSystem::setErrorCallback(audio_error_callback cb) {
    gAudioErrorCallback = cb;
}

}  // namespace android
