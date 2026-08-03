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
#

# Boot animation
TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 720

# AAPT CONFIG
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xhdpi

# Display
# composer@2.1-impl → composer@2.1-service (18.1: impl dihapus, service saja)
# Sumber: msm8916-common lineage-18.1
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.mapper@2.0-impl-2.1 \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    gralloc.msm8916 \
    hwcomposer.msm8916 \
    libgenlock \
    libtinyxml \
    memtrack.msm8916 \
    copybit.msm8916

# RenderScript HAL
PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0-impl

# Properties
#
# debug.sf.latch_unsignaled=1 DIBUANG — sedang diuji sebagai penyebab glitch
# wallpaper sesaat setelah layar dinyalakan. Properti itu membuat
# BufferLayer::fenceHasSignaled() (frameworks/native/.../BufferLayer.cpp:579)
# mengembalikan true tanpa memeriksa acquire fence sama sekali, sehingga
# SurfaceFlinger boleh menampilkan buffer yang render-nya BELUM selesai. Itu
# cocok dengan gejala "sebentar tidak pas lalu benar sendiri". Default AOSP
# memang 0, jadi membuangnya = kembali ke perilaku benar.
#
# debug.sf.disable_backpressure=1 SENGAJA DIPERTAHANKAN dulu meski juga tersangka
# (SurfaceFlinger.cpp:363 -> mPropagateBackpressure=false). Kalau dua-duanya
# dibuang sekaligus dan glitch hilang, tidak akan ketahuan mana penyebabnya.
# Kalau glitch masih ada setelah ini, itu variabel berikutnya yang diubah.
#
# Tujuh properti berikut dibuang karena NOL pembaca di seluruh tree
# (frameworks/, hardware/, system/, vendor/qcom/) — cuma pajangan:
#   debug.enable.sglscale, debug.egl.hw, debug.sf.disable_hwc,
#   debug.sf.recomputecrop, debug.cpurend.vsync, debug.sf.gpu_comp_tiling,
#   debug.performance.tuning
# Catatan: debug.sf.recomputecrop sekilas paling mencurigakan untuk masalah
# "tidak pas ke layar", tapi Android 10 tidak membacanya sama sekali.
#
# Yang tetap ada karena terbukti dibaca: debug.composition.type dan
# debug.mdpcomp.idletime dibaca hardware/qcom-caf/msm8916/display (tree display
# yang benar-benar dibangun device ini), debug.sf.hw dibaca SurfaceFlinger.cpp,
# debug.hwui.use_buffer_age dibaca frameworks/base/libs/hwui/Properties.h.
PRODUCT_PROPERTY_OVERRIDES += \
    debug.composition.type=c2d \
    ro.surface_flinger.max_frame_buffer_acquired_buffers=3 \
    ro.surface_flinger.vsync_event_phase_offset_ns=5000000 \
    ro.surface_flinger.vsync_sf_event_phase_offset_ns=7500000 \
    debug.mdpcomp.idletime=600 \
    persist.hwc.mdpcomp.enable=true \
    persist.hwc.ptor.enable=true \
    pm.dexopt.shared=quicken \
    pm.dexopt.downgrade_after_inactive_days=10 \
    debug.sf.hw=1 \
    debug.hwui.renderer=opengl \
    debug.sf.disable_backpressure=1 \
    video.accelerate.hw=1

# Screen density
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=280 \
    persist.graphics.vulkan.disable=true \
    persist.dbg.ims_volte_enable=1 \
    persist.dbg.volte_avail_ovr=1 

# Disable buffer age
PRODUCT_PROPERTY_OVERRIDES += \
    debug.hwui.use_buffer_age=false

# DRM
# clearkey @1.2 → @1.3 (Sumber: msm8916-common lineage-18.1)
PRODUCT_PACKAGES += \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \
    android.hardware.drm@1.3-service.clearkey

PRODUCT_PROPERTY_OVERRIDES += \
    ro.opengles.version=196608

# Trust HAL
PRODUCT_PACKAGES += \
    vendor.lineage.trust@1.0-service

# Audio
# 18.1: audio@5.0→@6.0, service nama baru, BT audio stack baru
# Sumber: msm8916-common lineage-18.1
PRODUCT_PACKAGES += \
    audio.primary.msm8916 \
    audio.bluetooth.default \
    audio.r_submix.default \
    audio.usb.default \
    tinymix \
    libaudio-resampler \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libqcompostprocbundle \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.service \
    android.hardware.audio.effect@6.0-impl \
    android.hardware.bluetooth.audio@2.0-impl

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/acdbdata/15399/Handset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/Handset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/15399/Hdmi_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/Hdmi_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/15399/Headset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/Headset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/15399/Speaker_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/Speaker_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/15399/WorkspaceFile.qwsp:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/WorkspaceFile.qwsp \
    $(LOCAL_PATH)/audio/acdbdata/15399/Bluetooth_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/Bluetooth_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/15399/General_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/General_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/15399/Global_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/15399/Global_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_General_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_General_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Global_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Global_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Handset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Handset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Hdmi_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Hdmi_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Headset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Headset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Speaker_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Speaker_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Bluetooth_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Bluetooth_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Handset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Handset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Hdmi_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Hdmi_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Headset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Headset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Speaker_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Speaker_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Bluetooth_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Bluetooth_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_General_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_General_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Global_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/msm8939-tapan-snd-card/MTP_WCD9306_Global_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_Headset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_Headset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_Speaker_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_Speaker_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_Bluetooth_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_Bluetooth_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_General_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_General_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_Global_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_Global_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_Handset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_Handset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/QRD/QRD_Hdmi_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/QRD/QRD_Hdmi_cal.acdb \
    $(LOCAL_PATH)/audio/audio_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info.xml \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(LOCAL_PATH)/audio/mixer_paths_mtp.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_mtp.xml \
    $(LOCAL_PATH)/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/a2dp_in_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_in_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml


# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.audio.sdk.fluencetype=none \
    persist.vendor.audio.fluence.voicecall=true \
    persist.vendor.audio.fluence.voicerec=true \
    persist.vendor.audio.fluence.speaker=false \
    vendor.audio.offload_wakelock=false \
    persist.debug.wfd.enable=1 \
    persist.sys.wfd.virtual=1

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    audio.deep_buffer.media=true \
    audio.offload.min.duration.secs=30 \
    audio.offload.video=true \
    ro.af.client_heap_size_kbyte=7168 \
    ro.audio.flinger_standbytime_ms=300 \
    vendor.voice.path.for.pcm.voip=true \
    vendor.audio.av.streaming.offload.enable=true \
    vendor.audio.offload.buffer.size.kb=64 \
    ro.config.vc_call_vol_steps=7 \
    ro.config.media_vol_steps=25 \
    vendor.audio.offload.gapless.enabled=true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

# Bluetooth
PRODUCT_PACKAGES += \
    libbt-vendor \

PRODUCT_COPY_FILES += \
    prebuilts/vndk/v28/arm/arch-arm-armv7-a-neon/shared/vndk-sp/libbase.so:$(TARGET_COPY_OUT_VENDOR)/lib/libbase-v28.so

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

# Camera
PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    camera.device@1.0-impl \
    libshim_camera \
    libcamera_shim \
    camera.msm8916 \
    Snap
# CATATAN: Camera2 dibuang karena packages/apps/Snap/Android.mk memakai
# LOCAL_OVERRIDES_PACKAGES := Camera2 — apk-nya ikut dikompilasi lalu dibuang
# lagi dari image. SnapdragonCamera dibuang karena bukan nama modul yang ada di
# tree ini (satu-satunya modul di packages/apps/Snap adalah "Snap").


# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    persist.camera.cpp.duplication=false \
    persist.camera.hal.debug.mask=0

# vendor_init
PRODUCT_PACKAGES += \
    libinit_msm8916

# GPS
PRODUCT_PACKAGES += \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    gps.msm8916

# Charger images
# charger_res_images dihapus di 18.1 (Sumber: msm8916-common lineage-18.1)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/gps/flp.conf:system/etc/flp.conf \
    $(LOCAL_PATH)/gps/gps.conf:system/etc/gps.conf \
    $(LOCAL_PATH)/gps/izat.conf:system/etc/izat.conf \
    $(LOCAL_PATH)/gps/sap.conf:system/etc/sap.conf \
    $(LOCAL_PATH)/gps/quipc.conf:system/etc/quipc.conf

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml

# PrivApp Permissions
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/privapp-permissions-qti.xml:system/etc/permissions/privapp-permissions-qti.xml

# Overlay
# overlay-lineage/ sebelumnya tidak pernah didaftarkan, sehingga isinya mati:
#   - config_deviceHardwareKeys=83 (Home+Back+AppSwitch+Volume) tidak pernah
#     terpasang, jadi menu Settings > Buttons tidak cocok dengan tombol fisik.
#   - config_deviceHardwareWakeKeys=64, config_trustLegacyEncryption=true dan
#     config_buttonBrightnessSettingDefault=0 juga ikut terabaikan.
# Nilai 83 cocok dengan keylayout/ft5x06_ts.kl (HOME, BACK, APP_SWITCH) plus
# gpio-keys.kl (VOLUME_UP/DOWN), jadi overlay ini memang milik device ini.
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay \
    $(LOCAL_PATH)/overlay-lineage

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.qcom.bluetooth.soc=smd \
    ro.bluetooth.dun=true \
    ro.bluetooth.hfp.ver=1.7 \
    ro.bluetooth.sap=true \
    ro.qualcomm.bt.hci_transport=smd

# Keymaster HAL
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service

# Keystore
# keystore.msm8916 dihapus di 18.1 (Sumber: msm8916-common lineage-18.1)

# Network stack — 18.1: varian in-process (tanpa APEX)
# Sumber: msm8916-common lineage-18.1
#
# InProcessTethering WAJIB berpasangan dengan InProcessNetworkStack.
# Tanpa TetheringService, TetheringManager.isTetheringSupported() menunggu
# ConditionVariable yang tidak pernah di-signal, dan itu membekukan MAIN THREAD
# Settings saat homepage resume:
#
#   TetheringManager$RequestDispatcher.waitForResult(TetheringManager.java:406)
#   TetheringManager.isTetheringSupported(TetheringManager.java:1321)
#   settingslib.TetherUtil.isTetherAvailable(TetherUtil.java:32)
#   TetherPreferenceController.isAvailable(TetherPreferenceController.java:115)
#   TopLevelNetworkEntryPreferenceController.getSummary(...:74)
#   DashboardFragment.updatePreferenceStates -> onResume
#
# Gejalanya di device: Settings tampil putih polos tanpa toolbar (yang terlihat
# cuma Splash Screen window), tombol Back mati, dan "dumpsys activity" untuk
# proses itu balas "java.io.IOException: Timeout". Sub-halaman seperti
# DISPLAY_SETTINGS tetap normal karena tidak memanggil TetherUtil.
#
# Kenapa HARUS nama apex, bukan nama app-nya:
# com.android.tethering.inprocess adalah override_apex dengan
# base: "com.android.tethering" dan apps: ["InProcessTethering"]
# (frameworks/base/packages/Tethering/apex/Android.bp:40-47). Menambahkannya
# MENGGANTI isi apex dari Tethering (bersertifikat networkstack) menjadi
# InProcessTethering (bersertifikat platform). Menambahkan modul
# "InProcessTethering" saja tidak menggantikan apa pun — apex bawaan tetap
# terpasang dan tidak ada yang berubah.
#
# Sertifikat itulah inti masalahnya. MAINLINE_NETWORK_STACK berproteksi
# signature dan didefinisikan PlatformNetworkPermissionConfig (bersertifikat
# platform), sehingga Tethering.apk bersertifikat networkstack tidak bisa
# memperolehnya:
#   E SystemServer: BOOT FAILURE starting Tethering
#   java.lang.SecurityException: Networking module does not have permission
#     android.permission.MAINLINE_NETWORK_STACK
#     at ConnectivityModuleConnector.checkModuleServicePermission(...:291)
# Layanan tethering gagal start, lalu semua pemanggilan TetheringManager
# menggantung sampai timeout.
#
# Pasangan kanoniknya terlihat di build/make/target/product/go_defaults_common.mk:40-43
# (InProcessNetworkStack + com.android.tethering.inprocess). msm8916-common
# mendapatkannya otomatis lewat common_full_go_phone.mk; device ini memakai
# common_full_phone.mk sehingga harus dideklarasikan eksplisit.
PRODUCT_PACKAGES += \
    InProcessNetworkStack \
    com.android.tethering.inprocess

# FM
PRODUCT_PACKAGES += \
    FMRadio \
    libfmjni

# Google Assistant
PRODUCT_PROPERTY_OVERRIDES += \
    ro.opa.eligible_device=true

# Init scripts
PRODUCT_PACKAGES += \
    fstab.qcom \
    init.target.rc \
    init.qcom.rc \
    init.qcom.power.rc \
    init.qcom.ssr.rc \
    init.qcom.usb.rc \
    init.recovery.qcom.rc \
    ueventd.qcom.rc

# For config.fs
PRODUCT_PACKAGES += \
    fs_config_files

# Encryption
# manifest.xml mendeklarasikan vendor.qti.hardware.cryptfshw sebagai hwbinder dan
# BoardConfig menyalakan TARGET_HW_DISK_ENCRYPTION, tapi hanya -base yang ikut
# dibangun dan vendor tree tidak membawa prebuilt service-nya. Tanpa service ini
# vold tidak mendapat HAL-nya saat menyiapkan /data.
PRODUCT_PACKAGES += \
    vendor.qti.hardware.cryptfshw@1.0-base \
    vendor.qti.hardware.cryptfshw@1.0-service-qti.qsee

# Media
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video.xml

# Media
# CATATAN duplicate rule libmm-omxcore (lihat BUILD_BROKEN_DUP_RULES di
# BoardConfig.mk): modul ini juga disalin sebagai prebuilt oleh
# vendor/oppo/A37/A37-vendor.mk ke path output yang PERSIS SAMA. Yang menang
# adalah aturan PRODUCT_COPY_FILES alias blob — diverifikasi dari perintah
# ninja-nya: "cp vendor/oppo/A37/proprietary/vendor/lib/libmm-omxcore.so".
# Menghapus baris di bawah TIDAK menyelesaikan duplikat: libmm-omxcore tetap
# ter-install karena jadi dependensi modul libOmx* lain yang dibangun dari
# source (sudah diuji). Satu-satunya cara menghilangkan duplikat adalah
# membuang salinan prebuilt di A37-vendor.mk, dan itu MENGGANTI biner yang
# terpasang (blob -> hasil build source). Belum dilakukan karena kombinasi
# blob + libOmx* source itulah yang terbukti boot di 17.1.
PRODUCT_PACKAGES += \
    libmm-omxcore \
    libOmxAacEnc \
    libOmxAmrEnc \
    libOmxCore \
    libOmxEvrcEnc \
    libOmxQcelp13Enc \
    libOmxVdec \
    libOmxVdecHevc \
    libOmxSwVencHevc \
    libOmxVenc \
    libOmxVidcCommon \
    libstagefrighthw

# Media config
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml

# Media
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

# Power
# CATATAN: referensi msm8916-common 18.1 pakai AIDL power-service-qti.
# Sementara tetap power@1.0 HIDL (sudah proven di 17.1 dengan powerHint +
# setInteractive custom). Upgrade ke AIDL bisa menyusul setelah boot stabil.
PRODUCT_PACKAGES += \
    power.msm8916

PRODUCT_PACKAGES += \
    android.hardware.power@1.0-impl \
    android.hardware.power@1.0-service

# Gatekeeper — baru di 18.1, wajib (Sumber: msm8916-common lineage-18.1)
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software

PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.max_starting_bg=8

# Perf
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.extension_library=libqti-perfd-client.so

# IOP
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.iop.enable_uxe=0 \
    vendor.iop.enable_prefetch_ofr=0

# IRSC
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sec_config:$(TARGET_COPY_OUT_VENDOR)/etc/sec_config

# First api level, device has been commercially launched
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.first_api_level=19

# Properti baru 18.1 (Sumber: msm8916-common lineage-18.1 + a6000 ref)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.charger.enable_suspend=true \
    ro.control_privapp_permissions=enforce \
    ro.oem_unlock_supported=0

# Properties
# persist.data.qmi.adb_logmask, persist.radio.apm_sim_not_pwdn dan
# ro.telephony.call_ring.multiple sudah diset di blok RIL di bawah; di sini
# tinggal yang unik saja supaya tidak ada dua sumber untuk nilai yang sama.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.radio.add_power_save=1

# HIDL
# 18.1: tambah libhidltransport/libhwbinder, VINTF override, RRO
# Sumber: msm8916-common lineage-18.1
PRODUCT_PACKAGES += \
    android.hidl.base@1.0 \
    android.hidl.manager@1.0 \
    libhidltransport \
    libhidltransport.vendor \
    libhwbinder \
    libhwbinder.vendor

PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := true

# RRO (Runtime Resource Overlay) — wajib di Android 11
# Sumber: msm8916-common lineage-18.1
# CATATAN: WifiOverlay/TetheringConfigOverlay dihapus — tidak ada di
# base tree LOS 18.1 (diverifikasi dari source). Jika build gagal
# karena RRO, hapus juga PRODUCT_ENFORCE_RRO_TARGETS.
PRODUCT_ENFORCE_RRO_TARGETS := *

# Health
# 18.1: @2.0 → @2.1 (Sumber: msm8916-common lineage-18.1)
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Touchscreen
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml

# Vibrator
PRODUCT_PACKAGES += \
    android.hardware.vibrator@1.0-impl

# RIL
PRODUCT_PACKAGES += \
    libcnefeatureconfig \
    librmnetctl \
    libxml2 \
    libcutils_shim

# Baseband Fix
PRODUCT_PACKAGES += \
    set_baseband.sh

# Lights
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service.oppo_msm8916

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    drm.service.enabled=1 \
    debug.stagefright.ccodec=0 \
    debug.stagefright.omx_default_rank.sw-audio=1 \
    debug.stagefright.omx_default_rank=0 \
    vendor.mediacodec.binder.size=6 \
    vidc.enc.narrow.searchrange=1

# Keylayout
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/gpio-keys.kl:system/usr/keylayout/gpio-keys.kl \
    $(LOCAL_PATH)/keylayout/ft5x06_ts.kl:system/usr/keylayout/ft5x06_ts.kl \
    $(LOCAL_PATH)/keylayout/synaptics-s3203.kl:system/usr/keylayout/synaptics-s3203.kl \
    $(LOCAL_PATH)/keylayout/qpnp_pon.kl:system/usr/keylayout/qpnp_pon.kl

# Storage
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sys.sdcardfs=true

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0

# WiFi HAL
# .legacy → regular (Sumber: msm8916-common lineage-18.1)
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0-service

# Wifi
PRODUCT_PACKAGES += \
    libwcnss_qmi \
    wcnss_service

# libwpa_client dibutuhkan oleh prebuilt vendor/bin/imsdatadaemon (DT_NEEDED),
# tapi tidak ikut terpasang sehingga daemon-nya gagal dlopen dan tidak pernah
# jalan. init.target.rc menyalakannya saat sys.ims.QMI_DAEMON_STATUS=1 dan
# device ini memang mengaktifkan VoLTE (persist.dbg.ims_volte_enable=1,
# persist.dbg.volte_avail_ovr=1), jadi tanpa ini VoLTE tidak mungkin bekerja.
# Modulnya ada di external/wpa_supplicant_8 dan sudah LOCAL_PROPRIETARY_MODULE,
# jadi terpasang ke /vendor/lib tempat biner vendor bisa melihatnya.
PRODUCT_PACKAGES += \
    libwpa_client

PRODUCT_PACKAGES += \
    hostapd \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(LOCAL_PATH)/configs/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/configs/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/WCNSS_qcom_cfg.ini

# Wifi
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/wifi/WCNSS_cfg.dat:$(TARGET_COPY_OUT_VENDOR)/firmware/wlan/prima/WCNSS_cfg.dat \
    $(LOCAL_PATH)/wifi/WCNSS_qcom_wlan_nv.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin \
    $(LOCAL_PATH)/wifi/WCNSS_wlan_dictionary.dat:$(TARGET_COPY_OUT_VENDOR)/firmware/wlan/prima/WCNSS_wlan_dictionary.dat

# USB HAL
PRODUCT_PACKAGES += \
    android.hardware.usb@1.0-service.cyanogen_8916

# Driver prima membaca konfigurasinya lewat request_firmware, jadi file yang
# sama harus ada juga di bawah firmware/wlan/prima. Ini satu-satunya aturan yang
# meng-install file tersebut — aturan symlink kembar di Android.mk sudah dibuang.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_VENDOR)/firmware/wlan/prima/WCNSS_qcom_cfg.ini

# Optimize
PRODUCT_SYSTEM_SERVER_COMPILER_FILTER := speed-profile
PRODUCT_ALWAYS_PREOPT_EXTRACTED_APK := true
PRODUCT_USE_PROFILE_FOR_BOOT_IMAGE := true
PRODUCT_DEXPREOPT_SPEED_APPS += SystemUI

# Strip debug
PRODUCT_MINIMIZE_JAVA_DEBUG_INFO := true
PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false

# CATATAN dalvik: nilai di bawah ini cuma jadi cadangan di build.prop. Yang
# benar-benar dipakai saat boot ditentukan init/init_msm8916.cpp
# (set_device_dalvik_properties), karena vendor_load_properties() dijalankan
# SETELAH /system/build.prop dibaca oleh init dan dalvik.vm.* bukan properti
# ro. sehingga boleh ditimpa. Sebelumnya kedua tempat ini berbeda (128m/256m
# vs 256m/512m) sehingga isi build.prop menyesatkan. Sekarang keduanya sama
# untuk A37 yang RAM-nya 2GB + zram LZ4 256 MB.
# heapgrowthlimit 192m (bukan 256m): app pakai lebih sedikit RAM per-proses,
# sehingga lebih banyak app bisa tetap di background sebelum LMK/swap.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=16m \
    dalvik.vm.heapgrowthlimit=192m \
    dalvik.vm.heapsize=384m \
    dalvik.vm.heaptargetutilization=0.75 \
    dalvik.vm.heapminfree=4m \
    dalvik.vm.heapmaxfree=6m \
    dalvik.vm.zygotemaxfailedboots=5 \
    dalvik.vm.foreground-heap-growth-multiplier=2.0 \
    dalvik.vm.dex2oat-flags=--no-watch-dog \
    dalvik.vm.dex2oat-swap=false \
    dalvik.vm.dex2oat-threads=2 \
    ro.vendor.qti.am.reschedule_service=true \
    sys.use_fifo_ui=1

# TextClassifier
PRODUCT_PACKAGES += \
    textclassifier.bundle1

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    persist.data.qmi.adb_logmask=0 \
    persist.data.target=dpm3 \
    persist.radio.apm_sim_not_pwdn=1 \
    ro.telephony.call_ring.multiple=false \
    ro.use_data_netmgrd=true \
    persist.radio.multisim.config=dsds \
    persist.radio.custom_ecc=1 \
    persist.radio.ecc_hard_1=112,911,110,122,119,120,000,118 \
    persist.radio.ecc_hard_count=1 \
    rild.libpath=/system/vendor/lib/libril-qc-qmi-1.so \
    ril.subscription.types=NV,RUIM \
    ro.telephony.default_network=9,1 \
    persist.data.netmgrd.qos.enable=false

# RIL
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/data/netmgr_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/data/netmgr_config.xml \
    $(LOCAL_PATH)/configs/data/qmi_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/data/qmi_config.xml \
    $(LOCAL_PATH)/configs/data/dsi_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/data/dsi_config.xml

# Seccomp
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/seccomp/mediacodec-seccomp.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy

# Sensors
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-impl \
    accelcal \
    AccCalibration \
    sensord \
    calmodule.cfg \
    sensors.msm8916

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml \
    $(LOCAL_PATH)/configs/sensors/_hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/_hals.conf

# USB ID
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.usb.id.midi=90BA \
    ro.usb.id.midi_adb=90BB \
    ro.usb.id.mtp=2281 \
    ro.usb.id.mtp_adb=2282 \
    ro.usb.id.ptp=2284 \
    ro.usb.id.ptp_adb=2283 \
    ro.usb.id.ums=2286 \
    ro.usb.id.ums_adb=2285 \
    ro.usb.vid=2970

# TimeKeep
PRODUCT_PACKAGES += \
    timekeep \
    TimeKeep    

# LiveDisplay
PRODUCT_PACKAGES += \
    vendor.lineage.livedisplay@2.0-service-legacymm \
    vendor.lineage.livedisplay@2.0-service-sysfs

$(call inherit-product, vendor/oppo/A37/A37-vendor.mk)
