LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := sensors.$(TARGET_BOARD_PLATFORM)
LOCAL_HEADER_LIBRARIES += libhardware_headers
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_MODULE_TAGS := optional
LOCAL_VENDOR_MODULE := true

LOCAL_CFLAGS += -DLOG_TAG=\"Sensors\"

# KERNEL_OBJ/usr DICABUT -- dua baris ini dulu berbunyi:
#   LOCAL_C_INCLUDES := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr/include
#   LOCAL_ADDITIONAL_DEPENDENCIES := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr
#
# vendor/lineage/build/tasks/kernel.mk di LineageOS 23.2 tidak pernah
# menjalankan headers_install, jadi KERNEL_OBJ/usr/include tidak pernah ada dan
# -I itu selalu menunjuk ke ruang kosong. Konstanta UAPI yang benar-benar
# dibutuhkan sudah didefinisikan langsung di sensors.h (SYN_TIME_SEC,
# SYN_TIME_NSEC), diambil dari include/uapi/linux/input.h kernel ini.
#
# LOCAL_ADDITIONAL_DEPENDENCIES-nya lebih berbahaya: KERNEL_OBJ/usr adalah
# direktori kerja kernel (gen_init_cpio, initramfs_data.cpio), bukan target
# yang punya aturan di ninja. Selama sisa build sebelumnya masih tergeletak di
# out/ ninja menganggapnya berkas sumber biasa dan diam; begitu out/ bersih,
# build berhenti sebelum satu perintah pun jalan:
#
#   FAILED: ninja: 'out/target/product/A37/obj/KERNEL_OBJ/usr', needed by
#   '.../sensors.msm8916_intermediates/sensors.o', missing and no known rule
#
# Artinya build ini hanya bisa berhasil di pohon out yang kotor. Tidak ada satu
# pun berkas dari direktori itu yang dipakai, jadi keduanya dibuang.

LOCAL_SRC_FILES :=	\
		sensors.cpp 			\
		SensorBase.cpp			\
		LightSensor.cpp			\
		ProximitySensor.cpp		\
		CompassSensor.cpp		\
		Accelerometer.cpp				\
		InputEventReader.cpp \
		CalibrationManager.cpp \
		NativeSensorManager.cpp \
		VirtualSensor.cpp

LOCAL_C_INCLUDES += external/libxml2/include	\
		    external/icu/icu4c/source/common

LOCAL_SHARED_LIBRARIES := liblog libcutils libdl libutils

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := calmodule.cfg
LOCAL_HEADER_LIBRARIES += libhardware_headers
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_ETC)
LOCAL_SRC_FILES := calmodule.cfg

include $(BUILD_PREBUILT)
