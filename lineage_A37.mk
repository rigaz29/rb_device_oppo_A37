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
# DIMATIKAN untuk rilis publik. Tanpa otorisasi, siapa pun yang mencolok USB
# mendapat shell adb tanpa persetujuan pemilik device.
#
# Dengan baris ini dikomentari, common.mk:25 menyetel ro.adb.secure=1 sehingga
# dialog "Allow USB debugging" kembali muncul dan kunci RSA harus disetujui
# manual.
#
# PERHATIAN: ini TIDAK menutup "adb root". Itu ditentukan varian build
# (ro.debuggable=1 pada userdebug), bukan oleh sakelar ini. Untuk menutupnya,
# bangun dengan varian user.
#
# Nyalakan lagi (uncomment) kalau kembali ke fase bring-up: saat layar hitam
# atau UI membeku, dialog otorisasi tidak bisa ditekan sehingga adb jadi tidak
# berguna persis ketika paling dibutuhkan.
#
# Sama seperti sakelar di atas, harus disetel sebelum inherit common_full_phone.mk.
# WITH_ADB_INSECURE := true

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_l.mk)
$(call inherit-product, device/oppo/A37/device.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# CATATAN DynamicSystemInstallationService — JANGAN coba filter-out di sini.
#
# DSU mensyaratkan partisi dinamis; BoardConfig.mk tidak punya
# PRODUCT_USE_DYNAMIC_PARTITIONS maupun BOARD_SUPER_PARTITION, jadi device ini
# berpartisi statis dan DSU tidak akan pernah berfungsi. Prosesnya tetap
# dijalankan tiap boot ("Start proc com.android.dynsystem"), memakai 184 KB.
#
# Percobaan membuangnya dengan
#   PRODUCT_PACKAGES := $(filter-out DynamicSystemInstallationService,$(PRODUCT_PACKAGES))
# di sini TIDAK BEKERJA — sudah diuji, APK-nya tetap terpasang.
#
# Sebabnya PRODUCT_PACKAGES tidak diselesaikan dengan aturan make biasa:
# _expand-inherited-values (build/make/core/node_fns.mk:148) menggabungkan nilai
# dari SELURUH node dalam graf inherit setelah tiap node di-include. Paketnya
# disumbang build/make/target/product/base_system.mk:82, jadi menghapusnya dari
# nilai node daun tidak berpengaruh — sumbangan leluhurnya digabungkan setelah
# itu.
#
# Satu-satunya jalan yang benar-benar bekerja adalah modul lain yang memakai
# LOCAL_OVERRIDES_PACKAGES / "overrides" di Android.bp. Untuk 184 KB, itu tidak
# sepadan; dibiarkan saja.

# Assert
# A37/A37m ikut didaftarkan: PRODUCT_DEVICE memang "A37", dan varian A37m
# disebut di README tapi belum pernah ada di daftar ini.
TARGET_OTA_ASSERT_DEVICE := A37,a37,a37f,A37f,A37fw,a37fw,A37m,a37m,msm8916,msm8939

# Must define platform variant before including any common things
TARGET_BOARD_PLATFORM_VARIANT := msm8916

# Device pertama kali rilis dengan Android 5.1.1 (API 22) — terbaca di fingerprint
# stok yang dipakai ROM referensi: OPPO/A37fw/A37f:5.1.1/LMY47V/1519717163.
# Dipakai 21 ("launched with L") mengikuti ROM referensi 19.1 A37 dan device tree
# a6010; 19 (KitKat) yang diwarisi dari 18.1 memang keliru secara fakta.
# product_launched_with_l.mk sudah menyetel ini, tapi deklarasi eksplisit
# memastikan FCM legacy target tetap benar meskipun inherit order berubah.
#
# ⚠️ INERT secara fungsi — seluruh gerbang di tree 19.1 ada di ambang 26/27/28/30/31,
# tidak ada satu pun antara 19 dan 21. Lihat catatan di device.mk.
PRODUCT_SHIPPING_API_LEVEL := 21

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
