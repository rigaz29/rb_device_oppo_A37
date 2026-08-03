#
# Copyright (C) 2016 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PLATFORM_PATH := device/oppo/A37

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := MSM8916
TARGET_BOARD_PLATFORM := msm8916
TARGET_NO_BOOTLOADER := true
# CATATAN: dua baris berikut dibuang karena menunjuk path mesin pembuat tree:
#   TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-android-
#   KERNEL_TOOLCHAIN := /tmp/src/android/tc/bin
# Menyetel TARGET_KERNEL_CROSS_COMPILE_PREFIX membuat vendor/lineage/config/
# BoardConfigKernel.mk melewati default KERNEL_TOOLCHAIN_arm64, sehingga
# CROSS_COMPILE menunjuk direktori yang tidak ada:
#   ccache: error: execute_noreturn of /tmp/src/android/tc/bin/aarch64-linux-android-gcc
# Tanpa keduanya, build memakai prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9.

# Temp build fix
# BUILD_BROKEN_PHONY_TARGETS dibuang: obsolete di Android 11, KATI_obsolete_var
# di build/make/core/board_config.mk membuatnya jadi hard error. Daftar
# BUILD_BROKEN_* yang masih sah ada di board_config.mk:89-94.
#
# BUILD_BROKEN_DUP_RULES masih dibutuhkan, dan penyebabnya tepat SATU target:
#   out/target/product/A37/system/vendor/lib/libmm-omxcore.so
# A37-vendor.mk menyalin blob prebuilt ke path itu, sementara modul
# libmm-omxcore juga ter-install ke sana sebagai dependensi libOmx* yang
# dibangun dari source. Yang menang adalah salinan blob (diverifikasi dari
# perintah ninja). Menghapus libmm-omxcore dari PRODUCT_PACKAGES di device.mk
# TIDAK menolong — sudah diuji, modulnya tetap ditarik lewat dependensi.
# Satu-satunya cara menghilangkan flag ini adalah membuang salinan prebuilt
# dari A37-vendor.mk, tapi itu mengganti biner yang terpasang.
BUILD_BROKEN_DUP_RULES := true
# Stack GPS device-specific (gps/core, gps/utils, gps/loc_api/*) masih memakai
# LOCAL_COPY_HEADERS, yang jadi hard error di Android 11
# (build/make/core/shared_library.mk:59-62). Flag ini menurunkannya kembali
# jadi warning. Konversi ke header_libs Soong adalah pekerjaan tersendiri.
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true

# Architecture
TARGET_BOARD_SUFFIX := _32
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a53

# Binder
TARGET_USES_64_BIT_BINDER := true

# Kernel
# console= dan androidboot.console= DIBUANG.
#
# Keduanya menyalakan shell serial dan memunculkan notifikasi permanen
# "Serial console enabled" di device. Pemicunya: init.rc:1037 mendefinisikan
# "service console /system/bin/sh" dengan opsi console, dan service.cpp:433
# menyambungkannya ke "/dev/" + ro.boot.console (dari androidboot.console).
# Kalau service itu jalan, ActivityManagerService.java:5648 melihat
# init.svc.console == "running" lalu menampilkan notifikasi tersebut terus.
#
# Nilainya kecil untuk kita: shell serial hanya berguna kalau pad UART
# benar-benar disolder. Diagnostik yang sesungguhnya tetap ada:
#   - earlyprintk=msm_hsl_uart,0x78b0000 masih jalan, karena earlyprintk
#     memetakan alamat fisik UART langsung dan tidak bergantung pada console=
#   - ramoops tetap menangkap seluruh kernel log dan logcat terakhir
#
# CONFIG_SERIAL_MSM_HSL dan node DTS blsp1_uart2 sengaja TETAP menyala, jadi
# kalau nanti butuh console serial cukup tambahkan lagi console=ttyHSL0 di sini
# tanpa perlu rebuild kernel.
BOARD_KERNEL_CMDLINE := androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci lpm_levels.sleep_disabled=1 earlyprintk=msm_hsl_uart,0x78b0000 ramoops.mem_address=0x9ff00000 ramoops.mem_size=0x400000 ramoops.record_size=0x40000
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset 0x01000000 --tags_offset 0x00000100
BOARD_KERNEL_IMAGE_NAME := Image
TARGET_KERNEL_SOURCE := kernel/oppo/msm8939
BOARD_KERNEL_SEPARATED_DT := true
TARGET_KERNEL_ARCH := arm64
TARGET_CUSTOM_DTBTOOL := dtbToolOppo
TARGET_KERNEL_CONFIG := lineageos_a37f_defconfig
# Host toolchain LOS 18.1 pakai clang/lld; kernel 3.10 butuh flag ini agar
# host tools (fixdep, conf) bisa di-link dengan lld.
# Sumber: msm8916-common lineage-18.1 BoardConfigCommon.mk
TARGET_KERNEL_ADDITIONAL_FLAGS := HOSTCFLAGS="-fuse-ld=lld -Wno-unused-command-line-argument"

# File System
TARGET_FS_CONFIG_GEN := $(PLATFORM_PATH)/config.fs
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_CACHEIMAGE_PARTITION_SIZE := 126877696
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PERSISTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2859466752
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11632902144
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SUPPRESS_EMMC_WIPE := true
# CATATAN: TARGET_EXFAT_DRIVER := sdfat dibuang. Variabel itu tidak dibaca oleh
# apa pun di LineageOS 17.1 — satu-satunya kemunculannya di seluruh tree adalah
# baris ini sendiri. Di 17.1 vold menentukan dukungan exFAT lewat
# IsFilesystemSupported("exfat") yang membaca /proc/filesystems.
# Kernel ini tidak punya driver exFAT sama sekali (nol berkas exfat/sdfat),
# sedangkan ROM sudah memasang mkfs.exfat dan fsck.exfat. Jadi kartu microSD
# ber-exFAT (umumnya yang >32GB) tidak akan ter-mount sampai driver exFAT
# di-port ke kernel. Membiarkan variabel ini hanya menyamarkan masalahnya.
TARGET_RECOVERY_FSTAB := $(PLATFORM_PATH)/rootdir/etc/fstab.qcom
TARGET_USES_MKE2FS := true
BOARD_ROOT_EXTRA_FOLDERS := firmware persist

# Dexpreopt
ifeq ($(HOST_OS),linux)
  ifneq ($(TARGET_BUILD_VARIANT),eng)
      WITH_DEXPREOPT := true
      WITH_DEXPREOPT_BOOT_IMG_AND_SYSTEM_SERVER_ONLY := true
      DONT_DEXPREOPT_PREBUILTS := true
      USE_DEX2OAT_DEBUG := false
      WITH_DEXPREOPT_DEBUG_INFO := false
  endif
endif

DISABLE_APEX_TEST_MODULE := true

# Init
TARGET_INIT_VENDOR_LIB := libinit_msm8916
TARGET_PLATFORM_DEVICE_BASE := /devices/soc.0/
TARGET_RECOVERY_DEVICE_MODULES := libinit_msm8916

# Security Patch Level
VENDOR_SECURITY_PATCH := 2016-01-01

# Qualcomm support
BOARD_USES_QCOM_HARDWARE := true
MALLOC_SVELTE := true

# Kernel 3.10 tidak punya memfd_create (baru di 3.17). Android 11 butuh ini
# untuk ashmem-to-memfd transition. Flag ini mengaktifkan backport di tree.
# Sumber: msm8916-common lineage-18.1 BoardConfigCommon.mk
TARGET_HAS_MEMFD_BACKPORT := true

# Dedupe VNDK libraries with identical core variants.
# Sumber: msm8916-common lineage-18.1 BoardConfigCommon.mk
TARGET_VNDK_USE_CORE_VARIANT := true

# HIDL
DEVICE_MANIFEST_FILE := $(PLATFORM_PATH)/manifest.xml
DEVICE_MATRIX_FILE := $(PLATFORM_PATH)/compatibility_matrix.xml
PRODUCT_VENDOR_MOVE_ENABLED := true

# Display
MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024
TARGET_CONTINUOUS_SPLASH_ENABLED := true
TARGET_USES_ION := true
TARGET_USES_NEW_ION_API := true
USE_OPENGL_RENDERER := true
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
TARGET_USES_C2D_COMPOSITION := true
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS := 0x2000U | 0x02000000U | 0x02002000U
OVERRIDE_RS_DRIVER := libRSDriver_adreno.so
# Sumber: msm8916-common lineage-18.1 BoardConfigCommon.mk
TARGET_DISABLE_POSTRENDER_CLEANUP := true
TARGET_USES_LEGACY_WFD := true

# Audio
AUDIO_FEATURE_ENABLED_MULTI_VOICE_SESSIONS := true
AUDIO_FEATURE_ENABLED_SND_MONITOR := true
BOARD_USES_ALSA_AUDIO := true
BOARD_USES_GENERIC_AUDIO := true
TARGET_USES_QCOM_MM_AUDIO := true
USE_XML_AUDIO_POLICY_CONF := 1

# Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(PLATFORM_PATH)/bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_QCOM := true
QCOM_BT_READ_ADDR_FROM_PROP := true

# Lights
TARGET_PROVIDES_LIBLIGHT := true

# Charger
# BOARD_CHARGER_ENABLE_SUSPEND dibuang — di 18.1 diganti properti
# ro.charger.enable_suspend=true di device.mk.
# Sumber: msm8916-common lineage-18.1 (commit "Replace BOARD_CHARGER_ENABLE_SUSPEND")
BOARD_CHARGER_DISABLE_INIT_BLANK := true
BACKLIGHT_PATH := /sys/class/leds/lcd-backlight/brightness

# Encryption
TARGET_HW_DISK_ENCRYPTION := true
TARGET_LEGACY_HW_DISK_ENCRYPTION := true
TARGET_KEYMASTER_WAIT_FOR_QSEE := true

# FM (Wired Radio)
AUDIO_FEATURE_ENABLED_FM_POWER_OPT := true
BOARD_HAVE_QCOM_FM := true
TARGET_QCOM_NO_FM_FIRMWARE := true

# Media extentions
TARGET_USES_MEDIA_EXTENSIONS := true

# Camera
BOARD_GLOBAL_CFLAGS += -DCAMERA_VENDOR_L_COMPAT
BOARD_GLOBAL_CFLAGS += -DCONFIG_OPPO_CAMERA_51
USE_DEVICE_SPECIFIC_CAMERA := true
TARGET_HAS_LEGACY_CAMERA_HAL1 := true
TARGET_PROCESS_SDK_VERSION_OVERRIDE := \
	/system/bin/mediaserver=22 \
	/system/vendor/bin/mm-qcamera-daemon=22

# GPS
TARGET_NO_RPC := true
USE_DEVICE_SPECIFIC_GPS := true

# Shim
# libmmcamera2_stats_algorithm.so dulu dipetakan ke libcamera_shim.so, padahal
# satu-satunya simbol yang tidak bisa dipenuhi library non-shim mana pun untuk
# blob itu adalah android_atomic_acquire_load — dan itu hanya ada di
# libshim_camera.so. libcamera_shim.so tidak menyediakan satu pun simbol yang
# dibutuhkan blob tersebut, jadi pemetaan lama salah sasaran dan resolusinya
# cuma bergantung pada urutan pemuatan (libshim_camera kebetulan sudah dimuat
# oleh libmmcamera2_stats_modules.so di proses yang sama).
# Diverifikasi: dengan libshim_camera.so, simbol libmmcamera2_stats_algorithm.so
# yang tak terpenuhi = 0.
# CATATAN: pemetaan libril-qc-qmi-1.so|libcutils_shim.so DIBUANG.
#
# TARGET_LD_SHIM_LIBS bekerja dengan MENYUNTIKKAN DT_NEEDED ke blob. Karena
# modul libcutils_shim tidak pernah ada di tree ini (dicari di seluruh
# Android.bp/Android.mk: nihil, dan tidak ada aturan install di ninja),
# penyuntikan itu membuat blob bergantung pada library yang tidak pernah
# terpasang, sehingga rild gagal total sejak boot:
#
#   E RILD: dlopen failed: library "libcutils_shim.so" not found:
#           needed by /system/vendor/lib/libril-qc-qmi-1.so
#
# Akibat berantainya: IRadio tidak pernah register, lalu com.android.phone
# menggantung di IRadio.getService() saat PhoneGlobals.onCreate dan kena ANR
# berulang (Reason: Broadcast of LOCKED_BOOT_COMPLETED), lalu di-kill "bg anr".
#
# Shim-nya memang tidak dibutuhkan: property_get dan property_set MASIH
# diekspor libcutils.so di build ini (diverifikasi dengan llvm-readelf
# --dyn-syms), dan seluruh simbol UND non-libc milik blob itu ditemukan di
# library yang terpasang. ROM LineageOS 18.1 A37 yang beredar juga tidak
# memuat libcutils_shim.so sama sekali.
TARGET_LD_SHIM_LIBS := \
    /system/vendor/lib/libmmcamera2_stats_modules.so|libshim_camera.so \
    /system/vendor/lib/libmmcamera2_stats_algorithm.so|libshim_camera.so \
    /system/vendor/lib/hw/camera.vendor.msm8916.so|libshim_camera.so

# SEpolicy
# SELINUX_IGNORE_NEVERALLOWS masih WAJIB, dan alasannya bukan lagi
# "file_contexts device belum lengkap" — itu sudah beres (semua 18 HAL service
# yang dideklarasikan device.mk kini berlabel).
#
# Alasan sebenarnya, diukur dengan `m sepolicy_neverallows` memakai override
# SETELAH include di bawah (kalau disetel sebelum include, nilainya ditimpa
# oleh device/qcom/sepolicy-legacy/sepolicy.mk:11 yang memaksa := true):
# ada ~1.500 pelanggaran neverallow, hampir semuanya dari sepolicy legacy QCOM
# dan platform, mis. 626 dari system/sepolicy/public/property.te dan 46 masing-
# masing dari domain aplikasi (priv_app, untrusted_app, radio, ...).
# Hanya 8 yang berasal dari device tree ini, semuanya dari
# app_domain(timekeep_app) di sepolicy/timekeep_app.te:7.
#
# Catatan: baris di bawah ini redundan karena sepolicy-legacy juga menyetelnya,
# tapi dipertahankan supaya niatnya eksplisit saat file itu nanti diganti.
# Flag ini hanya mematikan pemeriksaan neverallow saat BUILD; mode permissive
# runtime datang dari androidboot.selinux=permissive di BOARD_KERNEL_CMDLINE.
SELINUX_IGNORE_NEVERALLOWS := true
include device/qcom/sepolicy-legacy/sepolicy.mk
# Di 18.1 BOARD_SEPOLICY_DIRS diganti BOARD_VENDOR_SEPOLICY_DIRS.
# Sumber: msm8916-common lineage-18.1 BoardConfigCommon.mk
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(PLATFORM_PATH)/sepolicy

# Wi-Fi
BOARD_HAS_QCOM_WLAN := true
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_qcwcn
BOARD_WLAN_DEVICE := qcwcn
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_qcwcn
TARGET_USES_QCOM_WCNSS_QMI := true
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_STA := "sta"
WPA_SUPPLICANT_VERSION := VER_0_8_X
# WIFI_HIDL_FEATURE_DISABLE_AP_MAC_RANDOMIZATION dibuang — tidak ada di 18.1.
# Sumber: msm8916-common lineage-18.1 (flag ini dihapus di diff resmi)
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

# Proprietary Prebuilt
-include vendor/oppo/A37/BoardConfigVendor.mk
