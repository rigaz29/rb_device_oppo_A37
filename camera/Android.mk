LOCAL_PATH := $(call my-dir)
A37_CAMERA_PATH := $(LOCAL_PATH)
include $(CLEAR_VARS)

LOCAL_C_INCLUDES := \
    system/media/camera/include \
    frameworks/native/include \
    frameworks/av/camera/include

# CameraParameters dikompilasi langsung ke modul ini, tidak lewat libcamera_client.
#
# libcamera_client TIDAK vendor_available (frameworks/av/camera/Android.bp:77),
# sedangkan modul ini WAJIB berada di /vendor/lib/hw -- lihat LOCAL_VENDOR_MODULE
# di bawah. Menautnya ditolak build dengan "native:vendor can not link against
# native:platform".
#
# Berkasnya dirujuk langsung dari pohon hulu, BUKAN disalin, supaya tidak ada
# duplikat 538 baris yang harus dirawat sendiri dan semantik flatten/unflatten
# tetap persis sama dengan AOSP. Diperiksa: CameraParameters.cpp hanya menyertakan
# utils/Log.h, header C standar, camera/CameraParameters.h, dan system/graphics.h,
# serta hanya memakai String8/Vector (libutils), ALOG (liblog), dan libc -- semuanya
# tersedia untuk modul vendor.
LOCAL_SRC_FILES := \
    CameraWrapper.cpp \
    ../../../../frameworks/av/camera/CameraParameters.cpp

# libsensor dibuang dan penjaga sensorservice dialihkan ke libbinder_ndk; alasannya
# ada di komentar can_talk_to_sensormanager() di CameraWrapper.cpp.
LOCAL_SHARED_LIBRARIES := \
    libhardware \
    liblog \
    libutils \
    libcutils \
    libbinder_ndk

LOCAL_HEADER_LIBRARIES := libnativebase_headers
LOCAL_MODULE_RELATIVE_PATH := hw

# WAJIB. Tanpa ini modul terpasang di /system/lib/hw, dan HAL3on1 tidak akan
# pernah menemukannya:
#
#   E cameraserver: failed to open legacy HAL1 camera module
#   F libc: Fatal signal 6 (SIGABRT) ... android::hardware::camera::common::
#           helper::CameraModule::init()
#
# Rantainya: cameraserver memuat android.hardware.camera.provider@2.4-impl.so
# (passthrough, jadi masuk namespace sphal), yang memuat /vendor/lib/hw/
# camera.msm8916.so (HAL3on1). Adapter itu memanggil
# hw_get_module_by_class("camera", "legacy") -- HAL3on1-adapter.cpp:122 --
# sehingga dlopen dijalankan DARI namespace sphal, dan sphal tidak menjangkau
# /system/lib sama sekali. Modulnya ada, hanya di partisi yang salah.
#
# Backend-nya sendiri sudah benar: modul ini memanggil
# hw_get_module_by_class("camera", "vendor") (CameraWrapper.cpp:122) yang menunjuk
# /vendor/lib/hw/camera.vendor.msm8916.so, nama blob asli sejak pohon 18.1.
LOCAL_VENDOR_MODULE := true
# HAL3on1 kini menempati nama camera.$(TARGET_BOARD_PLATFORM); wrapper HAL1 ini
# menjadi backend-nya dan dimuat lewat hw_get_module_by_class("camera", "legacy").
LOCAL_MODULE := camera.legacy.$(TARGET_BOARD_PLATFORM)
LOCAL_HEADER_LIBRARIES += libhardware_headers
LOCAL_MODULE_TAGS := optional
LOCAL_32_BIT_ONLY := true

include $(BUILD_SHARED_LIBRARY)

# all-makefiles-under di device/oppo/A37/Android.mk hanya turun SATU tingkat, jadi
# camera/hal3on1/Android.mk tidak ikut tanpa baris ini. Gejalanya menyesatkan: build
# gagal dengan "includes non-existent modules in PRODUCT_PACKAGES: camera.msm8916",
# seolah modulnya salah nama, padahal makefile-nya tidak pernah dibaca.
#
# Memakai A37_CAMERA_PATH yang disimpan di atas, BUKAN $(call all-subdir-makefiles):
# makro itu memanggil my-dir, dan my-dir tidak boleh dipanggil setelah makefile lain
# di-include ("my-dir must be called before including any other makefile").
include $(call all-makefiles-under,$(A37_CAMERA_PATH))
