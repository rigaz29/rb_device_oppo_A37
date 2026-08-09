#
# Copyright (C) 2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    atomic.cpp \
    android/sensor.cpp \
    gui/SensorManager.cpp \
    ui/GraphicBuffer.cpp \
    MediaCodec.cpp \
    AudioSource.cpp \
    MetaData.cpp \
    camera_parameters/CameraParameters.cpp \
    justshoot_shim.cpp

LOCAL_C_INCLUDES := gui
LOCAL_SHARED_LIBRARIES := libsensor libutils liblog libbinder \
                          libandroid libui libstagefright libmedia

LOCAL_MODULE := libshim_camera
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
# BUKAN modul vendor — lihat "Kenapa dua shim ini bukan LOCAL_VENDOR_MODULE" di bawah.

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := camera_shim.c
LOCAL_SHARED_LIBRARIES := libutils libgui liblog
LOCAL_MODULE := libcamera_shim
# LOS 21: hardware/*.h harus diminta eksplisit sebagai header library di
# Android 14; jalur include implisitnya sudah tidak ada. Headernya sendiri masih
# ada di hardware/libhardware/include_all/, dan libhardware_headers mengekspor
# direktori itu dengan vendor_available:true.
LOCAL_HEADER_LIBRARIES += libhardware_headers

LOCAL_MODULE_TAGS := optional
# BUKAN modul vendor — lihat catatan di bawah.
include $(BUILD_SHARED_LIBRARY)

# ===========================================================================
# Kenapa dua shim di atas BUKAN LOCAL_VENDOR_MODULE (berubah di Android 14)
# ===========================================================================
# Di Android 14 build/make/core/binary.mk:1328 memberi modul vendor
# my_allowed_types = "native:vendor native:vndk native:platform_vndk". Lima
# dependensi shim kamera tidak ada di daftar itu, jadi main.mk:1143 menolak:
#
#   libshim_camera (native:vendor) can not link against libsensor (native:platform)
#     ... juga libandroid, libstagefright, libmedia
#   libcamera_shim (native:vendor) can not link against libgui.vendor (native:vndk_private)
#
# Aturan itu memodelkan perangkat Treble/VNDK. A37 bukan: BOARD_VNDK_VERSION
# sengaja tidak disetel (device.mk:581), vendor tinggal di /system/vendor, dan
# tidak ada namespace VNDK yang dibangun. Diverifikasi pada ROM LineageOS 20 kita
# yang TERPASANG DAN BOOT di perangkat:
#
#   /linkerconfig/ld.config.txt:
#     namespace.default.isolated    = false
#     namespace.default.search.paths = /system/${LIB} ... /vendor/${LIB}
#
# Hanya ada satu namespace non-isolated yang mencakup system maupun vendor.
# Bukti bahwa lintas-direktori memang bekerja: llvm-readelf -d pada
# /system/vendor/lib/libshim_camera.so milik ROM tersebut menunjukkan DT_NEEDED
# ke libsensor/libandroid/libstagefright/libmedia, sedangkan kelima pustaka itu
# HANYA ada di /system/lib (tidak ada duplikat di /system/vendor/lib) — dan ROM
# itu boot dengan normal.
#
# Karena itu shim dipindah ke partisi system: dependensinya tetap identik dan
# kini sah menurut pemeriksaan link-type (native:platform boleh menaut
# native:platform). Yang perlu dipastikan hanya satu hal — blob di
# /system/vendor/lib masih menemukan shim-nya. Masih: TARGET_LD_SHIM_LIBS bukan
# injeksi DT_NEEDED saat build, melainkan cppflag LD_SHIM_LIBS ke linker
# (vendor/lineage/build/soong/Android.bp:177). bionic/linker/linker.cpp:1368
# memuat shim lewat LoadTask::create(name, si, ns, ...) — BY NAME, ke namespace
# `ns` yang sama dengan blob. Jadi resolusinya lewat search path namespace
# default, yang memuat /system/${LIB}.
#
# libril_shim di bawah SENGAJA dibiarkan sebagai modul vendor: ia tidak punya
# LOCAL_SHARED_LIBRARIES sama sekali sehingga lolos pemeriksaan tanpa diubah,
# dan RIL adalah subsistem yang sudah terbukti berfungsi di proyek 20. Jangan
# diutak-atik tanpa alasan.

# Shim untuk libril-qc-qmi-1.so. Menyediakan
# android::AudioSystem::setErrorCallback(void(*)(int)) yang dihapus dari
# libaudioclient di Android 11. Lihat AudioSystem_ril.cpp untuk rinciannya.
include $(CLEAR_VARS)
LOCAL_SRC_FILES := AudioSystem_ril.cpp
LOCAL_MODULE := libril_shim
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_VENDOR_MODULE := true
include $(BUILD_SHARED_LIBRARY)
