LOCAL_PATH := $(call my-dir)
A37_CAMERA_PATH := $(LOCAL_PATH)
include $(CLEAR_VARS)

LOCAL_C_INCLUDES := \
    system/media/camera/include \
    frameworks/native/include

LOCAL_SRC_FILES := \
    CameraWrapper.cpp

LOCAL_SHARED_LIBRARIES := \
    libhardware \
    liblog \
    libcamera_client \
    libutils \
    libcutils \
    libbase \
    libsensor \
    libhidltransport \
    libnativewindow \
    libgui \
    android.hidl.token@1.0-utils \
    android.hardware.graphics.bufferqueue@1.0

LOCAL_STATIC_LIBRARIES := \
    libarect

LOCAL_HEADER_LIBRARIES := libnativebase_headers
LOCAL_MODULE_RELATIVE_PATH := hw
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
