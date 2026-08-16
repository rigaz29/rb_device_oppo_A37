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

# msm8916 sudah dicabut dari daftar platform hulu
# (hardware/qcom-caf/common/qcom_boards.mk — tidak ada di lineage-20.0 maupun
# lineage-21.0). Akibatnya hardware/qcom-caf/msm8916/media/Android.mk:5
#
#     ifeq ($(call is-board-platform-in-list, $(QCOM_BOARD_PLATFORMS)),true)
#
# bernilai false, sehingga mm-core/ dan libstagefrighthw/ TIDAK PERNAH
# di-include — dan enforce-product-packages-exist melaporkan modul-modul media
# hilang. (Diverifikasi ulang 14 Agustus 2026 di basis official: grep msm8916
# qcom_boards.mk = nol. Di basis UL dulu baris ini tidak perlu karena fork UL
# qcom_boards.mk:22 masih memuatnya.)
#
# Di proyek 20 masalah ini tidak muncul karena media di-pin ke
# lineage-19.0-caf-msm8916, yang belum punya gerbang tersebut. Untuk 21 kita
# memakai lineage-21.0-caf-msm8916 yang sudah bergerbang, jadi platform-nya
# perlu dideklarasikan ulang di sini.
#
# Radius dampaknya diukur, bukan diduga: QCOM_BOARD_PLATFORMS hanya dipakai di
# SATU titik gerbang di seluruh repo yang kita build — baris media di atas.
# audio/ dan display/ tidak memakainya sama sekali. qcom_boards.mk memakai '+='
# saja (tidak ada ':=' yang bisa menimpa), jadi urutan include tidak jadi soal.
QCOM_BOARD_PLATFORMS += msm8916
# CATATAN: dua baris berikut dibuang karena menunjuk path mesin pembuat tree:
#   TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-android-
#   KERNEL_TOOLCHAIN := /tmp/src/android/tc/bin
# Menyetel TARGET_KERNEL_CROSS_COMPILE_PREFIX membuat vendor/lineage/config/
# BoardConfigKernel.mk melewati default KERNEL_TOOLCHAIN_arm64, sehingga
# CROSS_COMPILE menunjuk direktori yang tidak ada:
#   ccache: error: execute_noreturn of /tmp/src/android/tc/bin/aarch64-linux-android-gcc
# Tanpa keduanya, build memakai prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9.

# BARU DI 19.1. vendor/lineage/build/tasks/kernel.mk:32 menyatakan
# TARGET_KERNEL_CLANG_COMPILE "defaults to true", dan gerbangnya di :232 adalah
# `ifneq ($(TARGET_KERNEL_CLANG_COMPILE),false)` — jadi harus disetel EKSPLISIT
# false, tidak cukup dibiarkan kosong.
#
# Tanpa ini kernel 3.10 dikompilasi clang dan mati di tahap paling awal:
#   scripts/mod/devicetable-offsets.c:10:2: error: unexpected token at start of statement
# Itu integrated assembler clang menolak keluaran asm bergaya gcc yang dipakai
# kernel 3.10 untuk menurunkan offset struktur.
#
# Fase 1 tidak menangkap ini karena build kernel mandiri memang memanggil
# gcc 4.9 langsung lewat CROSS_COMPILE; jalur clang hanya muncul saat kernel
# dibangun DARI DALAM build ROM.
#
# Dengan flag ini, CROSS_COMPILE jatuh ke KERNEL_TOOLCHAIN_arm64
# (vendor/lineage/config/BoardConfigKernel.mk:73) =
# prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin — kompiler yang
# sama persis dengan yang dipakai Fase 1 dan dengan kernel ROM referensi
# (gcc 4.9.x 20150123). a6010 lineage-19.1 memakai flag yang sama.
TARGET_KERNEL_CLANG_COMPILE := false
# BARU DI 20. vendor/lineage/config/BoardConfigKernel.mk:33 menetapkan default
# TARGET_KERNEL_LLVM_BINUTILS := true; dengan CLANG_COMPILE=false jalur LLVM
# sudah tertutup, tapi a6010 dan common meghs sama-sama menyetel false eksplisit
# (biaya nol, mencegah kejutan bila default hulu berubah).
TARGET_KERNEL_LLVM_BINUTILS := false

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

# BARU DI 19.1. Android 12 menolak prebuilt ELF di PRODUCT_COPY_FILES:
#   out/.../system/lib/libFileMux.so: error: found ELF prebuilt in
#   PRODUCT_COPY_FILES, use cc_prebuilt_binary / cc_prebuilt_library_shared instead.
#
# Pemeriksaannya (build/make/core/Makefile:74-76) kena pada SETIAP pasangan
# PRODUCT_COPY_FILES yang tujuannya memuat komponen path `bin`, `lib`, atau
# `lib64` — tidak peduli partisi. Di A37-vendor.mk itu 291 dari 320 blob.
# Ninja berhenti di kegagalan pertama, jadi log hanya menyebut libFileMux.so;
# memperbaikinya satu per satu cuma memunculkan yang berikutnya.
#
# Mengonversi 291 blob ke cc_prebuilt_library_shared bukan pekerjaan yang
# sepadan untuk ROM legacy ini. a6010 lineage-19.1 memakai flag yang sama.
#
# CATATAN: ini BERBEDA dari `check_elf_files: false` yang sudah dipakai delapan
# modul prebuilt di vendor/oppo/A37/Android.bp. Yang itu mematikan pemeriksaan
# dependensi ELF untuk modul Soong; yang ini soal jalur PRODUCT_COPY_FILES.
# Keduanya tidak saling menggantikan.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# WAJIB DI 19.1 — tanpa ini SELURUH /vendor/ueventd.rc (220 aturan) diabaikan.
#
# Gejalanya: SurfaceFlinger crash-loop, ROM berhenti di logo OPPO. Ditemukan
# lewat logcat di perangkat:
#   E Adreno-GSL: open(/dev/kgsl-3d0) failed: errno 13. Permission denied
#   F DEBUG   : Abort message: 'no suitable EGLConfig found, giving up'
# dan `ls -l /dev/kgsl-3d0` menunjukkan `crw------- root root` — nilai BAWAAN
# ueventd, artinya aturan kita memang tidak pernah diterapkan.
#
# Rantai sebabnya:
#   1. system/core/init/ueventd.cpp:271 —
#        if (GetIntProperty("ro.product.first_api_level", 10000) <= __ANDROID_API_S__)
#            ParseConfig({"/system/etc/ueventd.rc", "/vendor/ueventd.rc", ...});
#        return ParseConfig({"/system/etc/ueventd.rc"});
#      Gerbang ini BARU di Android 12; komentarnya sendiri berbunyi "TODO: Remove
#      these legacy paths once Android S is no longer supported". Di Android 11
#      /vendor/ueventd.rc dibaca tanpa syarat — itulah sebabnya kernel yang sama
#      lolos saat diuji lewat AnyKernel3 di atas ROM 18.1.
#   2. `getprop ro.product.first_api_level` di perangkat: KOSONG. Defaultnya
#      jadi 10000, dan 10000 > 31, sehingga hanya /system/etc/ueventd.rc dibaca.
#   3. Propertinya kosong karena build/make/core/sysprop.mk:314-316 mem-BLACKLIST
#      ro.product.first_api_level dari system/build.prop TANPA SYARAT — bukan
#      karena kita menyetelnya manual di device.mk.
#   4. Dan karena split ini mati, sysprop.mk:308-313 melebur
#      ADDITIONAL_VENDOR_PROPERTIES (yang memuat ro.product.first_api_level dari
#      PRODUCT_SHIPPING_API_LEVEL, main.mk:292) ke dalam prop SYSTEM — lalu kena
#      blacklist yang sama. Jadi propertinya tidak pernah sampai ke runtime.
#
# Dengan split menyala, ADDITIONAL_VENDOR_PROPERTIES menuju vendor/build.prop,
# dan blacklist di jalur itu (sysprop.mk:363) hanya PRODUCT_VENDOR_PROPERTY_BLACKLIST
# yang kosong. Propertinya lolos, gerbangnya terbuka, 220 aturan kembali terpakai.
#
# Diperbaiki di akarnya, bukan dengan chmod /dev/kgsl-3d0 di init.rc: kgsl hanya
# korban pertama. 219 aturan lain — audio, kamera, sensor, RIL — sama-sama
# terbuang, dan menambalnya satu per satu berarti menunggu ranjau berikutnya.
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Architecture
TARGET_BOARD_SUFFIX := _32
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a53

# Binder
# TARGET_USES_64_BIT_BINDER DIBUANG di LOS 21 — build/make memperingatkan
# "has been deprecated. All devices use 64-bit binder by default now."
# Ia sudah tidak berpengaruh apa pun; menyimpannya hanya menghasilkan
# peringatan di setiap build.

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
#   - ramoops tetap menangkap seluruh kernel log dan logcat terakhir
#
# CONFIG_SERIAL_MSM_HSL dan node DTS blsp1_uart2 sengaja TETAP menyala, jadi
# kalau nanti butuh console serial cukup tambahkan lagi console=ttyHSL0 di sini
# tanpa perlu rebuild kernel.
#
# DUA PARAMETER DEBUG DIBUANG setelah fase bring-up selesai:
#
#   msm_rtb.filter=0x237
#       Percuma sekarang — CONFIG_MSM_RTB sudah dimatikan di defconfig, jadi
#       parameter ini akan diabaikan diam-diam. Dibuang supaya tidak
#       menyesatkan.
#
#   earlyprintk=msm_hsl_uart,0x78b0000
#       Setiap pesan boot awal dikirim lewat UART 115200 baud dan MEMBLOKIR
#       sampai terkirim, jadi biayanya nyata di fase paling awal. Hanya
#       berguna kalau device gagal boot sebelum pstore siap — di luar itu
#       ramoops sudah cukup.
#
# Untuk menghidupkannya lagi saat mendiagnosis bootloop: kembalikan
# earlyprintk di sini, dan msm_rtb.filter hanya bermakna kalau CONFIG_MSM_RTB
# ikut dinyalakan lagi di defconfig.
# ⚠️ PARAMETER ramoops.* DI BAWAH SELAMA INI TIDAK BEREFEK APA PUN.
#
# Ditemukan 10 Agustus 2026. fs/pstore/ram.c versi kernel ini mengalokasikan
# pdata BARU yang seluruhnya nol lalu HANYA mengisinya dari device tree:
#
#   ramoops_probe():
#     pdata = devm_kzalloc(dev, sizeof(*pdata), GFP_KERNEL);   /* semua nol */
#     if (pdev->dev.of_node) ramoops_of_init(pdev);            /* DT saja */
#     if (!pdata->mem_size || ...) { pr_err("...must be non-zero"); goto fail_out; }
#
# Upstream memakai `pdata = pdev->dev.platform_data`, yaitu data yang dikirim
# ramoops_register_dummy() dari parameter modul di cmdline. Backport dukungan DT
# di kernel ini menghapus jalur itu, dan TIDAK ADA node `ramoops` di DTS mana pun
# — jadi probe selalu gagal dan pstore tidak pernah punya backend.
#
# Buktinya dari perangkat nyata yang menjalankan LOS 20 (report/bugreport.zip):
#   incidentd: GZipSection failed to open file /sys/fs/pstore/console-ramoops
#   incidentd: GZipSection failed to open file /sys/fs/pstore/console-ramoops-0
#
# Perbaikannya di kernel, bukan di sini: patches/kernel/0001 memulihkan jalur
# platform_data (aktif hanya bila of_node NULL, jadi jalur DT tidak tersentuh).
# Sengaja TIDAK lewat node DT supaya dt.img tetap byte-identik dengan LOS 20 yang
# boot — menambah variabel baru ke kegagalan boot yang belum terpecahkan.
#
# console_size dan pmsg_size WAJIB disebut eksplisit: default keduanya
# MIN_MEM_SIZE = 4096 (ram.c:47,55), dan 4 KB hanya menahan puluhan baris
# terakhir. Semua ukuran harus pangkat dua — ram.c:533-543 membulatkannya ke
# bawah tanpa memberi tahu.
#
#   mem_size      4 MB   total
#   console_size  1 MB   log kernel berjalan -> /sys/fs/pstore/console-ramoops
#   pmsg_size   256 KB   logcat terakhir     -> /sys/fs/pstore/pmsg-ramoops-0
#   record_size 256 KB   per dump oops/panic -> dmesg-ramoops-N (sisa ~10 slot)
#
# ramoops.ecc=1 — ECC Reed-Solomon 16 byte per blok 128 byte (ram.c:687
# memetakan nilai 1 ke ecc_size 16). Ditambahkan setelah tangkapan ramoops
# pertama dari perangkat terbaca rusak di tingkat bit: "init:" jadi "inht:",
# "console" jadi "contzol" — galat tersebar, bukan buffer yang ter-wrap.
#
# ⚠️ HARUS SAMA DI KEDUA SISI. ECC mengubah TATA LETAK buffer, bukan cuma cara
# membacanya:
#     ram_core.c:212   prz->buffer_size -= ecc_total;
#                      prz->par_buffer   = buffer->data + prz->buffer_size;
# Kernel yang menulis tanpa ECC lalu dibaca kernel ber-ECC akan membuat pembaca
# menghitung buffer_size lebih kecil, memperlakukan ekor data log sebagai
# paritas, dan menjalankan koreksi terhadap sampah. Hasilnya lebih buruk
# daripada tanpa ECC sama sekali.
#
# Karena itu parameter ini ditambahkan BERSAMAAN di device tree TWRP
# (rigaz29/android_device_oppo_A37f, BoardConfig.mk) — recovery-lah yang membaca
# buffer yang ditulis ROM ini. Kalau salah satu diubah, yang lain WAJIB ikut.
#
# Ongkosnya ~12,5% kapasitas buffer (16 byte paritas per 128 byte data), jadi
# console_size 1 MB efektif menjadi ~896 KB. Sepadan.

# ⚠️ RISIKO YANG DIAKUI: region 0x9ff00000 TIDAK dicadangkan di DTS, dan LK
# mengisi node memory sehingga alamat itu masuk RAM yang dikelola kernel
# (pfn_valid true -> jalur persistent_ram_vmap, ram_core.c:347). Buffer akan
# terbentuk dan terbaca, tapi halamannya tidak dilindungi dari alokasi lain.
# Kalau isinya nanti tampak rusak, langkah berikutnya menambahkan cadangan
# lewat DT — dan baru saat itu dt.img boleh berubah.
BOARD_KERNEL_CMDLINE := androidboot.hardware=qcom ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci lpm_levels.sleep_disabled=1 ramoops.mem_address=0x9ff00000 ramoops.mem_size=0x400000 ramoops.record_size=0x40000 ramoops.console_size=0x100000 ramoops.pmsg_size=0x40000 ramoops.dump_oops=1 ramoops.ecc=1
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

# Kalau init mati fatal, boot ke recovery — jangan menggantung di logo OPPO.
# Ini alat diagnosis utama Fase 9: stuck di logo TANPA reboot ke recovery berarti
# bukan init yang fatal (tersangka jadi kernel panic atau init macet menunggu),
# sedangkan reboot ke recovery berarti init fatal dan alasannya ada di ramoops.
# Percobaan 19.1 yang lama sudah memakainya; dipertahankan.
BOARD_KERNEL_CMDLINE += androidboot.init_fatal_reboot_target=recovery

# Panic saat ada task menggantung di D state, berpasangan dengan
# CONFIG_DETECT_HUNG_TASK=y + CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=90 di defconfig
# kernel. Parameternya diverifikasi di kernel/hung_task.c:57 —
# __setup("hung_task_panic=", ...).
#
# Disetel lewat cmdline, BUKAN CONFIG_BOOTPARAM_HUNG_TASK_PANIC, supaya bisa
# dimatikan dengan mengganti boot.img saja tanpa membangun ulang kernel.
#
# Rantainya: task terblokir >90s -> panic -> CONFIG_PANIC_TIMEOUT=5 -> reboot.
# Stack trace task yang terblokir masuk kmsg, jadi tertangkap console-ramoops
# dan terbaca setelah perangkat hidup lagi.
#
# ⚠️ Reboot-nya ke boot NORMAL, bukan recovery — kernel tidak menulis BCB saat
# panic. Yang membawa ke recovery adalah bootwatchdog.sh (userspace) dan
# androidboot.init_fatal_reboot_target di atas (init FATAL).
BOARD_KERNEL_CMDLINE += hung_task_panic=1
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

# A37 adalah perangkat NON-A/B: satu slot, tanpa partisi _a/_b.
#
# WAJIB DISETEL EKSPLISIT SEJAK ANDROID 15. Sebelumnya nilai kosong berarti
# non-A/B, jadi device tree ini tidak pernah perlu menyebutnya. Di A15
# build/make/core/board_config.mk:945-947 membalik defaultnya:
#
#   ifeq ($(AB_OTA_UPDATER),)
#   AB_OTA_UPDATER := true
#   endif
#
# Akibatnya misc_info.txt memuat ab_update=true, dan pengemasan OTA gagal di
# langkah paling akhir (100%, setelah seluruh image jadi):
#
#   AssertionError: META/ab_partitions.txt is required for ab_update.
#
# Berkas itu tidak akan pernah ada karena perangkat ini memang tidak punya
# partisi A/B.
AB_OTA_UPDATER := false
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
#
# Precompile PENUH: semua aplikasi sistem dikompilasi di sini, bukan di device.
#
# Sebelumnya hanya boot image + system_server yang di-preopt
# (WITH_DEXPREOPT_BOOT_IMG_AND_SYSTEM_SERVER_ONLY := true), sehingga seluruh
# aplikasi sistem dikompilasi dex2oat DI DEVICE pada boot pertama. Di Cortex-A53
# 4 inti dengan RAM 2 GB itu membuat boot pertama setelah flash sangat lama —
# terkonfirmasi di device: boot pertama lambat sekali, boot kedua cepat karena
# hasil kompilasinya sudah tersimpan di /data.
#
# Ruangnya ada: partisi system 2.859.466.752 B (2727 MiB), terpakai 1088 MiB,
# jadi 1639 MiB menganggur — dan ruang partisi system tidak bisa dipakai untuk
# apa pun selain system.
#
# Konsekuensinya: system image dan ZIP membesar (perkiraan kasar 300-800 MB),
# dan build di host jauh lebih lama karena dex2oat mengerjakan semuanya.
ifeq ($(HOST_OS),linux)
  ifneq ($(TARGET_BUILD_VARIANT),eng)
      WITH_DEXPREOPT := true
      WITH_DEXPREOPT_BOOT_IMG_AND_SYSTEM_SERVER_ONLY := false
      DONT_DEXPREOPT_PREBUILTS := false
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
# HAL legacy/vendor yang device manifest deklarasikan tapi tidak ada di matrix
# framework hulu (lihat framework_compatibility_matrix.xml) — wajib agar
# check-vintf-all lolos (PLAN.md §4.6).
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := $(PLATFORM_PATH)/framework_compatibility_matrix.xml
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

# BARU DI 20 — Lineage Health (vendor.lineage.health-service.default).
# Nilai dari a6010 lineage-20.0 dan meghs A37 lineage-20 (keduanya sepakat),
# dan path-nya diverifikasi di kernel kita sendiri:
#   qpnp-linear-charger.c:206,1672-1679 mengekspos POWER_SUPPLY_PROP_CHARGING_ENABLED
#   (set_property + qpnp_lbc_charger_enable), :1554-1566 property_is_writeable,
#   :3372 batt_psy bernama "battery"; power_supply_sysfs.c:148 memetakannya ke
#   atribut sysfs "charging_enabled". CONFIG_QPNP_LINEAR_CHARGER=y di defconfig
#   (lineageos_a37f_defconfig:334).
TARGET_HEALTH_CHARGING_CONTROL_CHARGING_PATH := /sys/class/power_supply/battery/charging_enabled
TARGET_HEALTH_CHARGING_CONTROL_CHARGING_ENABLED := 1
TARGET_HEALTH_CHARGING_CONTROL_CHARGING_DISABLED := 0
# KOREKSI Fase 9: SUPPORTS_TOGGLE TIDAK boleh dimatikan — hulu
# (ChargingControl.cpp) hanya mendefinisikan constructor ChargingControl()
# di bawah #ifdef TOGGLE atau #ifdef DEADLINE; mematikan keduanya membuat
# constructor tanpa definisi dan link gagal. Dengan TOGGLE=true, constructor
# ber-loop menunggu node charging yang writable oleh user system — node sysfs
# power_supply dibuat 0644 root:root (power_supply_sysfs.c:257,267), jadi
# akses W_OK gagal dan loop tak pernah berhenti -> IChargingControl tak
# register -> waitForDeclaredService di main thread system_server menggantung
# -> Watchdog membunuh system_server -> bootloop. Node dibuat writable oleh
# chmod di init.qcom.rc (on fs) — lihat komentar di sana.
TARGET_HEALTH_CHARGING_CONTROL_SUPPORTS_BYPASS := false

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
# Menyalakan qti_camera_device_defaults: -DQTI_CAMERA_DEVICE +
# vendor.qti.hardware.camera.device@1.0 pada libcameraservice. Dibutuhkan patch
# HAL1 retiredtab frameworks/av 0004; antarmukanya ada di tree
# (vendor/qcom/opensource/interfaces/camera/device/1.0/Android.bp:4) dan HAL1 CAF
# A37 memakai QDataCallback. Definisi Soong-nya dikembalikan di vendor/lineage
# (revert f224255c) — lihat tools/apply-legacy-patches.sh.
TARGET_USES_QTI_CAMERA_DEVICE := true
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
#
# CATATAN: dua pemetaan libhidlbase_shim SEMPAT ada di sini (15 Agustus 2026) untuk
# netmgrd dan perf-hal, lalu DIBUANG. Shim itu memindahkan kegagalan satu tahap
# lebih dalam, bukan menyelesaikannya: ia mendeklarasikan gBnConstructorMap SENDIRI,
# terpisah dari peta yang dipakai libhidlbase, sehingga blob mendaftar ke satu peta
# dan HidlBinderSupport.cpp:256 mencari di peta lain ->
#   F HidlSupport: getOrCreateCachedBinder getBnConstructorMap returned null
# Akarnya diperbaiki di patches/system_libhidl: simbol lama dipulihkan DI DALAM
# libhidlbase sebagai penyimpan asli, sehingga semua blob lama tertangani sekaligus
# tanpa pemetaan per-blob.
#
# MEKANISMENYA DIVERIFIKASI BEKERJA — dan cara memverifikasinya penting.
#
# Shim TIDAK PERNAH muncul di DT_NEEDED blob. Ia dimuat LINKER saat runtime:
#   vendor/lineage/build/soong/Android.bp:211  shim_libs_defaults
#       -> cppflags -DLD_SHIM_LIBS="<daftar>"
#   bionic/linker/Android.bp:78                memakai shim_libs_defaults
#   bionic/linker/linker.cpp:693,712,1367      parse_LD_SHIM_LIBS()
#
# Jadi `readelf -d <blob>` adalah INSTRUMEN YANG SALAH untuk memeriksanya, dan
# hasil nol darinya BUKAN bukti shim mati. Instrumen yang benar adalah string
# LD_SHIM_LIBS di dalam biner linker:
#
#   strings out/soong/.intermediates/bionic/linker/linker/<varian>/<hash>/linker \
#     | grep "libshim_camera.so:"
#
# ⚠️ Ambil hash intermediate yang mtime-nya sesuai build terakhir — direktori
# hash lama tetap tertinggal dan membaca yang basi memberi jawaban lama.
#
# Diverifikasi 15 Agustus 2026 pada linker build 07:48 (20.029 string terbaca
# sebagai kontrol): pemetaan di bawah ADA. (Saat itu enam; kedua libhidlbase_shim
# kemudian dibuang, lihat CATATAN di atas — tersisa empat.)
#
# Catatan sejarah: delta build/soong UL sempat diduga menyimpan mekanisme ini dan
# diekstrak untuk memastikan (patches/ul21/build_soong, 3 patch). Ternyata BUKAN —
# isinya allowlist xz, workaround manifest_check.py, dan revert makefile_goal.
# Mekanismenya memang sudah lengkap di basis official.
TARGET_LD_SHIM_LIBS := \
    /system/vendor/lib/libmmcamera2_stats_modules.so|libshim_camera.so \
    /system/vendor/lib/libmmcamera2_stats_algorithm.so|libshim_camera.so \
    /system/vendor/lib/hw/camera.vendor.msm8916.so|libshim_camera.so \
    /system/vendor/lib/libril-qc-qmi-1.so|libril_shim.so

# SEpolicy
# SELINUX_IGNORE_NEVERALLOWS masih WAJIB, dan alasannya bukan lagi
# "file_contexts device belum lengkap" — itu sudah beres (semua 18 HAL service
# yang dideklarasikan device.mk kini berlabel).
#
# Alasan sebenarnya, diukur ulang pada Fase 3 (10 Agustus 2026) dengan
# `m sepolicy_neverallows` — flag dimatikan lewat edit sementara pada DUA sumber
# (baris di bawah DAN device/qcom/sepolicy-legacy/sepolicy.mk:11; memakai override
# command-line `m ... SELINUX_IGNORE_NEVERALLOWS=` TIDAK diteruskan ke Soong):
# 3.298 pelanggaran neverallow, ~3.216 di antaranya milik system/sepolicy sendiri
# (property.te 2.232, domain.te 828, dst.). Dari device tree ini: 16 — adbd.te 15
# (seri adb bring-up Fase 1) + timekeep_app.te 1 (app_domain). Selebihnya:
# qcom/sepolicy-legacy 59, device/lineage/sepolicy 7.
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
# wcnss_service + lib_driver_cmd_qcwcn disediakan hardware/qcom-caf/wlan, yang
# dipilih OTOMATIS lewat pathmap qcom-wlan di vendor/lineage/build/core/
# qcom_target.mk karena BOARD_USES_QCOM_HARDWARE=true. (hardware/qcom/wlan
# resmi dijaga hanya keymaster oleh os_pickup_aosp.mk pada device CAF.)
#
# Versi CAF punya jalur OSS: USES_QCOM_WCNSS_QMI=true + PROVIDES_WCNSS_QMI=true
# -> -DWCNSS_QMI_OSS + libdl, TANPA lib QMI proprietary (wcnss_service.c
# men-dlopen libwcnss_qmi.so saat runtime dan sudah include <string.h>).
# Ini konfigurasi yang PERSIS dipakai ROM LOS 20 A37 yang wifi-nya berfungsi
# (meghs BoardConfig.mk:91). Jangan set USES=true tanpa PROVIDES=true: cabang
# itu menuntut libqmi_cci/libqmi_common_so/libmdmdetect yang tak ada di tree.
TARGET_USES_QCOM_WCNSS_QMI := true
TARGET_PROVIDES_WCNSS_QMI := true
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_STA := "sta"
WPA_SUPPLICANT_VERSION := VER_0_8_X
# WIFI_HIDL_FEATURE_DISABLE_AP_MAC_RANDOMIZATION dibuang — tidak ada di 18.1.
# Sumber: msm8916-common lineage-18.1 (flag ini dihapus di diff resmi)
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

# Proprietary Prebuilt
-include vendor/oppo/A37/BoardConfigVendor.mk
