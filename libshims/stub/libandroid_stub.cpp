/*
 * Stub /vendor/lib/libandroid.so untuk A37.
 *
 * KENAPA STUB, BUKAN IMPLEMENTASI NYATA
 *
 * Blob vendor menaut libandroid lewat DT_NEEDED dan tanpa berkas ber-soname itu
 * di namespace vendor, daemon kamera tidak pernah jalan:
 *
 *   CANNOT LINK EXECUTABLE "/vendor/bin/mm-qcamera-daemon":
 *   library "libandroid.so" not found:
 *   needed by /system/vendor/lib/libmmcamera2_stats_modules.so
 *
 * Versi pertama shim ini memakai implementasi nyata (android/sensor.cpp +
 * gui/SensorManager.cpp) di atas libsensor. Itu DITOLAK build:
 *
 *   "libandroid_a37_vendor (native:vendor) can not link against
 *    libsensor (native:platform)"
 *
 * Modul yang dipasang ke /vendor dihitung sebagai native:vendor, dan libsensor
 * tidak punya vendor_available. Membuatnya vendor_available akan berantai ke
 * libpermission dan libaconfig_storage_read_api_cc, jauh di luar cakupan.
 *
 * BATASAN YANG DIKETAHUI
 *
 * Simbol di bawah tidak melakukan apa pun. ASensorManager_getInstance dan
 * ASensorManager_createEventQueue mengembalikan nullptr, jadi modul statistik
 * kamera tidak akan menerima data sensor -- fitur 3A yang bersandar pada
 * giroskop/akselerometer (mis. stabilisasi berbantu-sensor) tidak akan aktif.
 * Pemotretan dasar tidak bergantung padanya.
 *
 * Ini pertukaran yang disengaja: tanpa berkas ini daemon kamera tidak jalan
 * sama sekali. Kalau nanti terbukti blob benar-benar menuntut data sensor,
 * jalan yang benar adalah menyediakan libsensor versi vendor, bukan memperluas
 * stub ini.
 *
 * Ketiga belas simbol di bawah diukur dari irisan simbol UND
 * libmmcamera2_stats_modules.so + camera.vendor.msm8916.so + libmm-als.so
 * terhadap simbol yang didefinisikan libandroid platform.
 */

#define LOG_TAG "A37LibandroidStub"
#include <log/log.h>
#include <stdint.h>

namespace {
void warn_once(const char* fn) {
    static bool warned = false;
    if (!warned) {
        warned = true;
        ALOGW("libandroid stub A37: %s dipanggil; API sensor tidak tersedia di "
              "namespace vendor", fn);
    }
}
}  // namespace

extern "C" {

// --- ALooper ---------------------------------------------------------------
void* ALooper_forThread() { return nullptr; }
void* ALooper_prepare(int) { warn_once("ALooper_prepare"); return nullptr; }
int ALooper_pollOnce(int, int*, int*, void**) { return -4 /* ALOOPER_POLL_ERROR */; }
void ALooper_wake(void*) {}

// --- ASensorManager --------------------------------------------------------
void* ASensorManager_getInstance() { warn_once("ASensorManager_getInstance"); return nullptr; }
void* ASensorManager_getDefaultSensor(void*, int) { return nullptr; }
void* ASensorManager_createEventQueue(void*, void*, int, void*, void*) {
    warn_once("ASensorManager_createEventQueue");
    return nullptr;
}
int ASensorManager_destroyEventQueue(void*, void*) { return 0; }

// --- ASensorEventQueue -----------------------------------------------------
int ASensorEventQueue_enableSensor(void*, void*) { return -1; }
int ASensorEventQueue_disableSensor(void*, void*) { return -1; }
int ASensorEventQueue_setEventRate(void*, void*, int32_t) { return -1; }
ssize_t ASensorEventQueue_getEvents(void*, void*, size_t) { return 0; }

// --- ASensor ---------------------------------------------------------------
int ASensor_getMinDelay(void*) { return 0; }

// android::SensorManager::SensorManager() -- konstruktor tanpa argumen yang
// dituntut libmmcamera2_stats_modules.so tapi sudah lama dicabut dari Android.
void _ZN7android13SensorManagerC1Ev(void*) { warn_once("SensorManager::SensorManager()"); }

}  // extern "C"
