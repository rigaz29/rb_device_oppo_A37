#include <system/audio.h>
#include <utils/String16.h>

// Shim untuk frameworks/av/media/libstagefright/AudioSource
//
// Blob kamera OPPO (dibangun untuk Android 5.1) mencari konstruktor
// android::AudioSource yang sudah lama hilang:
//
//     AudioSource(audio_source_t, const String16&, uint32_t sampleRate,
//                 uint32_t channelCount, uint32_t outSampleRate, uid_t, pid_t)
//
// Di Android 10 konstruktor asli masih menerima audio_source_t sebagai
// parameter pertama, jadi shim lama tinggal meneruskan panggilan sambil
// menambah tiga argumen baru.
//
// Android 11 mengubah parameter pertama menjadi const audio_attributes_t*
// (frameworks/av/media/libstagefright/include/media/stagefright/AudioSource.h:39-49),
// sehingga simbol yang dirujuk shim lama tidak ada lagi dan link gagal:
//
//     ld.lld: error: undefined symbol: android::AudioSource::AudioSource(
//         audio_source_t, android::String16 const&, unsigned int, unsigned int,
//         unsigned int, unsigned int, int, int, audio_microphone_direction_t, float)
//
// Simbol yang benar-benar diekspor libstagefright.so, diverifikasi dengan
// llvm-readelf --dyn-syms:
//
//     _ZN7android11AudioSourceC1EPK18audio_attributes_tRKNS_8String16Ejjjjii28audio_microphone_direction_tf
//
// Catatan ABI: nama mangled konstruktor tidak memuat parameter `this` karena
// sifatnya implisit. Shim lama mendeklarasikan kedua simbol TANPA `this`,
// sehingga seluruh argumen tergeser satu register dan penerusannya sebenarnya
// salah. Di sini `this` dideklarasikan eksplisit di kedua sisi.

namespace android {

// Konstruktor asli milik Android 11.
extern "C" void _ZN7android11AudioSourceC1EPK18audio_attributes_tRKNS_8String16Ejjjjii28audio_microphone_direction_tf(
        void* thiz, const audio_attributes_t* attr, const String16& opPackageName,
        uint32_t sampleRate, uint32_t channels, uint32_t outSampleRate,
        uid_t uid, pid_t pid, audio_port_handle_t selectedDeviceId,
        audio_microphone_direction_t selectedMicDirection,
        float selectedMicFieldDimension);

// Simbol lama yang dicari blob; disediakan di sini.
extern "C" void _ZN7android11AudioSourceC1E14audio_source_tRKNS_8String16Ejjjji(
        void* thiz, audio_source_t inputSource, const String16& opPackageName,
        uint32_t sampleRate, uint32_t channelCount, uint32_t outSampleRate,
        uid_t uid, pid_t pid)
{
    audio_attributes_t attr = AUDIO_ATTRIBUTES_INITIALIZER;
    attr.source = inputSource;

    // 0, 0, 0.0f = AUDIO_PORT_HANDLE_NONE, MIC_DIRECTION_UNSPECIFIED,
    // MIC_FIELD_DIMENSION_NORMAL — sama dengan nilai default di header.
    _ZN7android11AudioSourceC1EPK18audio_attributes_tRKNS_8String16Ejjjjii28audio_microphone_direction_tf(
            thiz, &attr, opPackageName, sampleRate, channelCount, outSampleRate,
            uid, pid, 0, static_cast<audio_microphone_direction_t>(0), 0.0f);
}

}
