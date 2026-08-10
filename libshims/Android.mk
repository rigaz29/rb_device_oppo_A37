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

# BUKAN modul vendor di Android 14 — LOCAL_VENDOR_MODULE dihapus di sini.
#
# build/make/core/binary.mk:1328 hanya mengizinkan modul vendor menaut
# native:vendor, native:vndk, atau native:platform_vndk. Shim ini menaut
# libsensor, libandroid, libstagefright, libmedia, dan libgui — semuanya
# native:platform, jadi sebagai modul vendor ia ditolak build.
#
# Memindahkannya ke /system aman, dan itu dibuktikan dari perangkat yang
# menjalankan ROM LOS 20 kita plus dari artefak build kita sendiri, bukan dari
# dokumentasi:
#
#   /linkerconfig/ld.config.txt   namespace.default.isolated = false
#                                 search.paths = /system/${LIB} … /vendor/${LIB}
#
#   readelf -d out/…/system/lib/libshim_camera.so   (12 DT_NEEDED terbaca)
#     DELAPAN di antaranya ada di /system/lib dan TIDAK ADA di
#     /system/vendor/lib: libsensor, libutils, liblog, libbinder, libandroid,
#     libui, libstagefright, libmedia.
#     Empat sisanya libc++/libc/libm/libdl (tersedia di kedua namespace).
#
#   Modul ini juga terbukti terpasang ke /system/lib, bukan /system/vendor/lib —
#   itu hasil langsung dari membuang LOCAL_VENDOR_MODULE di bawah.
#
# ⚠️ Pengukuran ini diulang 10 Agustus 2026. Versi pertama komentar ini menyebut
# `llvm-readelf`, yang TIDAK ADA di mesin build ini; perintahnya gagal dan
# hasilnya nol yang menyesatkan. Pakai readelf/nm GNU, dan selalu sertakan uji
# kontrol (`readelf -d <berkas> | grep -c NEEDED` harus > 0).
#
# Blob tetap menemukan shim: TARGET_LD_SHIM_LIBS bukan injeksi DT_NEEDED saat
# build, melainkan cppflag LD_SHIM_LIBS ke linker, dan
# bionic/linker/linker.cpp:1368 memuatnya BY NAME ke namespace yang sama
# dengan blob pemanggilnya.

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := camera_shim.c
LOCAL_SHARED_LIBRARIES := libutils libgui liblog
LOCAL_MODULE := libcamera_shim
LOCAL_MODULE_TAGS := optional
# LOCAL_VENDOR_MODULE dihapus — alasan sama dengan libshim_camera di atas.
# hardware/*.h tidak lagi implisit di Android 14, jadi diminta eksplisit.
LOCAL_HEADER_LIBRARIES := libhardware_headers
include $(BUILD_SHARED_LIBRARY)

# Shim untuk libril-qc-qmi-1.so. Menyediakan
# android::AudioSystem::setErrorCallback(void(*)(int)) yang dihapus dari
# libaudioclient di Android 11. Lihat AudioSystem_ril.cpp untuk rinciannya.
#
# ⚠️ JANGAN samakan dengan dua shim di atas. libril_shim TETAP modul vendor.
#
# Ia hanya menaut libaudioclient/libutils/liblog, jadi tidak kena batasan
# link-type — dan RIL adalah satu-satunya subsistem A37 yang terbukti berfungsi
# di perangkat. Mengubahnya "demi konsistensi" adalah risiko tanpa keuntungan.
#
include $(CLEAR_VARS)
LOCAL_SRC_FILES := AudioSystem_ril.cpp
LOCAL_MODULE := libril_shim
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_VENDOR_MODULE := true
include $(BUILD_SHARED_LIBRARY)
