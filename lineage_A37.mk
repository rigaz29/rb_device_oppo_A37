# Copyright (C) 2015-2017 The CyanogenMod Project
# Copyright (C) 2017, The LineageOS Project
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

# Sertakan jam-menit-detik di nama build, bukan cuma tanggal, supaya beberapa
# build dalam satu hari bisa dibedakan:
#   lineage-18.1-20260803-UNOFFICIAL-rigaz29-A37.zip
#   -> lineage-18.1-20260803_004500-UNOFFICIAL-rigaz29-A37.zip
# Sakelar ini dibaca vendor/lineage/config/common.mk:270 sehingga HARUS
# disetel sebelum baris inherit common_full_phone.mk di bawah.
#
# Tanpa ini, dua build pada hari yang sama menghasilkan nama file yang sama
# dan yang kedua menimpa yang pertama — persis yang terjadi pada build
# 2 Agu: mka bacon menulis ke inode yang sama sehingga ROM lama hilang
# beserta checksum-nya.
LINEAGE_VERSION_APPEND_TIME_OF_DAY := true

# USB debugging menyala sejak boot pertama, tanpa dialog otorisasi.
#
# Sakelar resmi LineageOS (vendor/lineage/config/common.mk:20-22) yang menyetel
# ro.adb.secure=0. Efek berantainya: post_process_props.py:43-50 melihat
# ro.adb.secure != 1 lalu menambahkan "adb" ke persist.sys.usb.config, sehingga
# adb hidup sejak awal DAN tidak meminta konfirmasi kunci RSA.
#
# Ini penting saat bring-up: kalau layar hitam atau UI membeku, dialog "Allow
# USB debugging" tidak bisa ditekan sehingga adb jadi tidak berguna persis ketika
# paling dibutuhkan.
#
# HARUS DIBUANG sebelum rilis publik — tanpa otorisasi, siapa pun yang mencolok
# USB mendapat shell adb, dan di userdebug "adb root" juga langsung jalan.
#
# Sama seperti sakelar di atas, harus disetel sebelum inherit common_full_phone.mk.
WITH_ADB_INSECURE := true

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_k.mk)
$(call inherit-product, device/oppo/A37/device.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Assert
# A37/A37m ikut didaftarkan: PRODUCT_DEVICE memang "A37", dan varian A37m
# disebut di README tapi belum pernah ada di daftar ini.
TARGET_OTA_ASSERT_DEVICE := A37,a37,a37f,A37f,A37fw,a37fw,A37m,a37m,msm8916,msm8939

# Must define platform variant before including any common things
TARGET_BOARD_PLATFORM_VARIANT := msm8916

# Device pertama kali rilis dengan Android 4.4 (API 19).
# product_launched_with_k.mk sudah menyetel ini, tapi deklarasi eksplisit
# memastikan FCM legacy target tetap benar meskipun inherit order berubah.
PRODUCT_SHIPPING_API_LEVEL := 19

TARGET_VENDOR := Oppo
PRODUCT_DEVICE := A37
PRODUCT_NAME := lineage_A37
BOARD_VENDOR := Oppo
PRODUCT_BRAND := Oppo
PRODUCT_MODEL := A37
PRODUCT_MANUFACTURER := Oppo

# Build fingerprint
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="msm8916_64-user 5.1.1 LMY47V eng.root.20190711.032745 release-keys" \
    TARGET_DEVICE="A37f"

BUILD_FINGERPRINT := OPPO/A37fw/A37f:5.1.1/LMY47V/1519717163:user/release-keys

# GMS
PRODUCT_GMS_CLIENTID_BASE := android-oppo
