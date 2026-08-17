HAL3ON1_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_PATH := $(HAL3ON1_PATH)
LOCAL_C_INCLUDES := \
    system/media/camera/include \
    frameworks/native/include \
    external/libyuv/include \
    hardware/qcom-caf/msm8916/display/libgralloc

LOCAL_SRC_FILES := \
    HAL3on1-adapter.cpp

LOCAL_SHARED_LIBRARIES := \
    libhardware \
    liblog \
    libutils \
    libcutils \
    libbase \
    libhidltransport \
    libcamera_metadata \
    libgui_vendor \
    libui \
    android.hidl.token@1.0-utils \
    android.hardware.graphics.bufferqueue@1.0 \
    libbinder \
    libjpeg

LOCAL_STATIC_LIBRARIES := \
    android.hardware.camera.common-helper \
    libarect \
    libyuv_static

LOCAL_CPP_FLAGS += -DLOG_NDEBUG

# A37 tidak punya node torch sama sekali -- /sys/class/leds hanya berisi
# lcd-backlight. Makro ini tetap HARUS terdefinisi karena kodenya berpagar runtime
# (properties.use_sysfs_torch, default false) dan bukan #ifdef, sehingga tanpa
# definisi kompilasi gagal dengan "use of undeclared identifier".
#
# Diberi jalur yang sengaja tidak ada: kalau seseorang menyalakan
# persist.camera.hal3on1.use_sysfs_torch, open() gagal dan HAL3on1 menonaktifkan
# jalur itu sendiri -- persis penanganan yang sudah ada di adapter.
ifneq ($(TARGET_SYSFS_FLASH_PATH_BRIGHTNESS),)
    LOCAL_CFLAGS += -DSYSFS_FLASH_PATH_BRIGHTNESS=\"$(TARGET_SYSFS_FLASH_PATH_BRIGHTNESS)\"
else
    LOCAL_CFLAGS += -DSYSFS_FLASH_PATH_BRIGHTNESS=\"/nonexistent/hal3on1-no-sysfs-torch\"
endif

ifneq ($(TARGET_SYSFS_FLASH_PATH_BRIGHTNESS_FALLBACK),)
    LOCAL_CFLAGS += -DSYSFS_FLASH_PATH_BRIGHTNESS_FALLBACK=\"$(TARGET_SYSFS_FLASH_PATH_BRIGHTNESS_FALLBACK)\"
else
    LOCAL_CFLAGS += -DSYSFS_FLASH_PATH_BRIGHTNESS_FALLBACK=\"/nonexistent/hal3on1-no-sysfs-torch\"
endif

LOCAL_HEADER_LIBRARIES := libnativebase_headers
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_MODULE := camera.$(TARGET_BOARD_PLATFORM)
LOCAL_MODULE_TAGS := optional
LOCAL_32_BIT_ONLY := true
LOCAL_PROPRIETARY_MODULE := true

include $(BUILD_SHARED_LIBRARY)
