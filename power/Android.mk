#
# Copyright 2016 The CyanogenMod Project
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

LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)
LOCAL_SRC_FILES := power.c
LOCAL_SHARED_LIBRARIES := liblog libcutils
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := power.msm8916
# LOS 21: hardware/*.h harus diminta eksplisit sebagai header library di
# Android 14; jalur include implisitnya sudah tidak ada. Headernya sendiri masih
# ada di hardware/libhardware/include_all/, dan libhardware_headers mengekspor
# direktori itu dengan vendor_available:true.
LOCAL_HEADER_LIBRARIES += libhardware_headers
# utils/Log.h juga tidak lagi terjangkau implisit. Modul ini menaut liblog dan
# libcutils saja -- tidak libutils -- jadi headernya harus diminta terpisah.
# Modul lain (sensors, camera, libshims) sudah menaut libutils sehingga ikut.
LOCAL_HEADER_LIBRARIES += libutils_headers

LOCAL_PROPRIETARY_MODULE      := true
include $(BUILD_SHARED_LIBRARY)