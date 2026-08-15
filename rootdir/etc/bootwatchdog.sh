#!/system/bin/sh
#
# Pengaman boot A37 — menjamin kegagalan boot berakhir di recovery, bukan diam
# di logo OPPO selamanya.
#
# DI-PORT DARI BRANCH lineage-21, tanpa perubahan logika.
#
# Sebagian komentar di bawah merujuk bukti dari pengerjaan LOS 21 (report/bootfail*,
# tanggal Agustus 2026). Rujukan itu SENGAJA dipertahankan: yang dijelaskannya
# adalah ALASAN tiap keputusan — kenapa 120 detik, kenapa `on init`, kenapa waktu
# kompilasi ART tidak dihitung — dan alasan itu berlaku sama di LOS 20 karena
# perangkat, kernel, dan partisinya identik. Bukti mentahnya ada di proyek 21.
#
# Yang PERLU DIPERIKSA saat memakai ini di LOS 20: parameter ramoops di
# BOARD_KERNEL_CMDLINE hanya berfungsi kalau kernel yang dipakai punya patch
# pstore/ram platform_data. Branch kernel lineage-20 dengan patch itu SUDAH
# dibuat (rigaz29/kernel_oppo_msm8939), jadi tinggal memastikan manifest LOS 20
# menunjuk ke sana. Rinciannya di BoardConfig.mk di atas blok ramoops.
#
# KENAPA INI ADA
#
# Tiga kelas kegagalan boot sudah punya penanganan otomatis:
#
#   kernel panic       CONFIG_PANIC_TIMEOUT=5 -> reboot sendiri setelah 5 detik
#   CPU hang           CONFIG_MSM_WATCHDOG_V2=y -> watchdog bite -> reset
#   init FATAL         androidboot.init_fatal_reboot_target=recovery -> recovery
#
# Yang TIDAK tertangani adalah kelas keempat, dan justru itu yang kita hadapi:
# kernel hidup, init hidup, tapi userspace MENGGANTUNG. Watchdog kernel tetap
# di-pet oleh thread kernel, tidak ada panic, tidak ada FATAL — jadi perangkat
# diam tanpa batas dan tidak ada log yang bisa diambil.
#
# Skrip ini menutup celah itu. Kalau boot tidak selesai dalam $BATAS detik, ia
# mengumpulkan jejak lalu reboot ke recovery — di sana adb hidup, dan /data
# TIDAK terenkripsi di perangkat ini (fstab tanpa `encryptable=`), jadi berkas
# di /data/bootfail bisa langsung dibaca.
#
# Reboot itu sendiri juga berguna: buffer console pstore hanya bertahan pada
# reboot HANGAT. Cabut baterai = RAM hilang = tidak ada ramoops. Jadi kegagalan
# boot yang berakhir dengan reboot terkendali jauh lebih informatif daripada
# yang berakhir dengan pencabutan baterai.
#
# MENGATURNYA — keduanya properti persist, jadi bertahan lintas reboot dan bisa
# diubah dari recovery tanpa membangun ulang ROM:
#
#   setprop persist.a37.bootwatchdog 0            matikan sama sekali
#   setprop persist.a37.bootwatchdog.timeout 90   ganti batas (detik)
#
# BATAS DEFAULT 120 DETIK — DARI PENGUKURAN, BUKAN TEBAKAN.
#
# Diukur dari bugreport perangkat nyata yang menjalankan LOS 20 dengan sehat
# (report/bugreport.zip, properti ro.boottime.* dalam nanodetik):
#
#   timekeep         17,2 s
#   bootanim         19,2 s
#   wpa_supplicant   34,3 s   <- servis boot terakhir
#
# Jadi boot sehat di perangkat ini selesai sekitar 40 detik, dan 120 detik
# memberi margin 3x.
#
# ⚠️ ASUMSI "WITH_DEXPREOPT=true jadi tidak ada dexopt besar di boot pertama"
# TERBUKTI SALAH, dan pengaman ini sempat MEMBUNUH BOOT YANG SEHAT karenanya.
# dexpreopt menghilangkan dexopt APLIKASI, tapi tidak menyentuh `odrefresh` —
# kompilasi ulang BOOT CLASSPATH ART, yang dipicu artefak APEX yang tidak cocok
# dengan hasil build. Terukur di report/bootfail3/:
#
#   odrefresh: No prior cache-info file     -> kompilasi penuh, 190x dex2oat
#   21:20:52,6 -> 21:22:14,2                = 81,5 detik
#   celah ro.boottime odsign 15,8s -> apexd-snapshotde 98,3s cocok persis
#
# Boot itu sampai OnBootPhase_600 (PHASE_THIRD_PARTY_APPS_CAN_START) dan sudah
# mem-fork com.android.launcher3 ketika dipotong di detik 120. Sehat sepenuhnya,
# hanya lambat sekali sekali.
#
# Karena itu waktu selama ART mengompilasi TIDAK DIHITUNG (lihat loop di bawah).
# Batas 120 detik dipertahankan sebagai anggaran "tidak ada kemajuan", karena
# untuk mendeteksi hang sungguhan ia memang tepat.
#
# Kenapa tidak lebih longgar: false positive di sini MURAH — perangkat masuk
# recovery, tempat adb hidup dan semuanya bisa dibereskan lewat properti di
# atas. Yang mahal justru menunggu, karena setiap percobaan diagnosis menahan
# orang di depan layar. Asimetrinya berpihak pada batas yang lebih pendek.
#
# Kalau boot pertama setelah flash ternyata butuh lebih dari 120 detik di eMMC
# yang lambat, gejalanya jelas: perangkat masuk recovery padahal /data/bootfail
# menunjukkan boot sedang berjalan normal. Naikkan lewat properti, bukan rebuild.

# Nilai bukan-angka jatuh ke default. Nilai di bawah 30 detik juga ditolak:
# `timeout 0` akan membuat loop tidak pernah berjalan dan perangkat langsung
# reboot ke recovery — orang yang menyetel 0 hampir pasti bermaksud MEMATIKAN,
# dan untuk itu ada persist.a37.bootwatchdog=0.
BATAS="$(getprop persist.a37.bootwatchdog.timeout)"
case "$BATAS" in
    ''|*[!0-9]*) BATAS=120 ;;
esac
[ "$BATAS" -lt 30 ] && BATAS=120
JEDA=5
OUT=/data/bootfail

# Jangan pernah aktif di mode selain boot normal. Di charger mode, reboot ke
# recovery berarti perangkat yang sedang dicas malah masuk recovery.
case "$(getprop ro.bootmode)" in
    charger|ffbm*|*recovery*) exit 0 ;;
esac

[ "$(getprop persist.a37.bootwatchdog)" = "0" ] && exit 0

# PAGU MUTLAK. Tanpa ini, dex2oat yang benar-benar menggantung membuat pengaman
# ini menunggu selamanya — persis kegagalan yang ia ada untuk ditangkap.
BATAS_MAKS="$(getprop persist.a37.bootwatchdog.timeout.maks)"
case "$BATAS_MAKS" in
    ''|*[!0-9]*) BATAS_MAKS=600 ;;
esac
[ "$BATAS_MAKS" -lt "$BATAS" ] && BATAS_MAKS=$((BATAS * 4))

habis=0      # detik TANPA kemajuan — hanya ini yang dibandingkan dengan BATAS
total=0      # detik sebenarnya sejak start, dibandingkan dengan pagu mutlak
kompilasi=0  # detik yang dihabiskan ART untuk mengompilasi, untuk laporan
while [ "$habis" -lt "$BATAS" ] && [ "$total" -lt "$BATAS_MAKS" ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && exit 0
    sleep "$JEDA"
    total=$((total + JEDA))
    # odsign membungkus seluruh odrefresh -> dex2oat. Dipakai getprop dan bukan
    # pgrep/pidof karena getprop sudah pasti ada di sini, sementara ketersediaan
    # keduanya bergantung pada toybox yang terpasang.
    if [ "$(getprop init.svc.odsign)" = "running" ]; then
        kompilasi=$((kompilasi + JEDA))
    else
        habis=$((habis + JEDA))
    fi
done

# Boot gagal.
#
# PERTAMA tulis alasannya ke /dev/kmsg. Ini yang paling penting, karena kmsg
# ditangkap console-ramoops dan BERTAHAN lewat reboot — sementara berkas di
# /data belum tentu bisa ditulis sama sekali (lihat di bawah). Baris ini akan
# terbaca lagi di /sys/fs/pstore/console-ramoops setelah perangkat masuk
# recovery.
echo "bootwatchdog: sys.boot_completed tidak muncul — reboot ke recovery" > /dev/kmsg 2>/dev/null
echo "bootwatchdog: tanpa-kemajuan=${habis}s (batas ${BATAS}s) total=${total}s (pagu ${BATAS_MAKS}s) kompilasi-ART=${kompilasi}s" > /dev/kmsg 2>/dev/null
# kompilasi-ART besar + tanpa-kemajuan kecil = pagu mutlak yang kena, artinya
# dex2oat sendiri yang menggantung — bukan boot yang lambat.
echo "bootwatchdog: init.svc.zygote=$(getprop init.svc.zygote) init.svc.surfaceflinger=$(getprop init.svc.surfaceflinger) init.svc.adbd=$(getprop init.svc.adbd)" > /dev/kmsg 2>/dev/null
echo "bootwatchdog: sys.usb.state=$(getprop sys.usb.state) ro.bootmode=$(getprop ro.bootmode)" > /dev/kmsg 2>/dev/null

# Sejak pengaman ini dipasang di `on init`, hang bisa terjadi SEBELUM /data
# ter-mount. Kalau begitu, menulis ke $OUT hanya membuat berkas di tmpfs yang
# hilang saat reboot — dan lebih buruk, ia tertimpa mount /data berikutnya.
# Jadi dites dulu; kalau gagal, cukup kmsg di atas yang jadi jejaknya.
if mkdir -p "$OUT" 2>/dev/null && touch "$OUT/.w" 2>/dev/null; then
    rm -f "$OUT/.w" 2>/dev/null
    # $total, bukan $habis — namanya "tertahan berapa detik", jadi yang dimaksud
    # lama sebenarnya. Rinciannya (tanpa-kemajuan vs kompilasi-ART) ada di kmsg,
    # yang ikut terkumpul di dmesg.txt dan console-ramoops.
    echo "$total"                > "$OUT/tertahan-detik.txt" 2>/dev/null
    getprop ro.build.display.id  > "$OUT/build.txt"     2>/dev/null
    getprop                      > "$OUT/getprop.txt"   2>/dev/null

    # /data/system/environ — MEMILAH KEGAGALAN BOOTCLASSPATH.
    #
    # Ditambahkan setelah report/bootfail5 (basis official): zygote SIGABRT 24x
    # dengan "BOOTCLASSPATH and DEX2OATBOOTCLASSPATH must not be empty" dan
    # odrefresh dengan "BOOTCLASSPATH is not defined." Boot tidak pernah sampai
    # system_server.
    #
    # Rantainya (system/core/rootdir/init.rc:1047-1048):
    #     exec_start derive_classpath          -> tulis /data/system/environ/classpath
    #     load_exports /data/system/environ/classpath  -> ekspor *CLASSPATH
    #
    # Semua yang bisa diperiksa dari luar sudah sehat, jadi putusnya PASTI di
    # antara kedua baris itu: bootclasspath.pb ada di ROM (18 jar),
    # com.android.sdkext.apex ada, APEX ter-mount (odrefresh JALAN dari
    # /apex/com.android.art/bin), urutan servis benar (derive_classpath 15,75s ->
    # odsign 15,98s -> zygote 18,29s), dan SELinux permissive.
    #
    # Berkas ini memilah dua kemungkinan yang tersisa dalam SATU kali boot:
    #   kosong / tidak ada  -> derive_classpath yang gagal menulis
    #   isinya lengkap      -> load_exports yang tidak memuatnya
    #
    # Kenapa tidak cukup mengandalkan dmesg: pesan init soal load_exports ada di
    # kmsg detik ~15, sementara dmesg.txt di bootfail5 hanya mencakup detik
    # 130-135 karena ring buffer kernel habis dibanjiri audit SELinux permissive.
    #
    # 2>&1 disengaja, bukan 2>/dev/null: pesan galat "No such file or directory"
    # justru JAWABAN yang dicari, jadi harus ikut tersimpan.
    {
        # Ukuran lebih dulu: satu angka ini saja sudah memilah kedua kemungkinan,
        # tanpa perlu membaca sisanya. Kosong/hilang = derive_classpath.
        echo "== ukuran classpath (byte)"
        wc -c /data/system/environ/classpath 2>&1
        echo
        echo "== ls -laZ /data/system/environ/"
        ls -laZ /data/system/environ/ 2>&1
        echo
        echo "== isi /data/system/environ/classpath"
        cat /data/system/environ/classpath 2>&1
        echo
        echo "== /data/system (ada tidaknya induknya)"
        ls -ldZ /data/system 2>&1
    } > "$OUT/environ.txt" 2>&1

    dmesg                        > "$OUT/dmesg.txt"     2>/dev/null
    logcat -d -v threadtime      > "$OUT/logcat.txt"    2>/dev/null
    cat /proc/last_kmsg          > "$OUT/last_kmsg.txt" 2>/dev/null
    cp /sys/fs/pstore/*          "$OUT/"                2>/dev/null
    sync
    echo "bootwatchdog: jejak tersimpan di $OUT" > /dev/kmsg 2>/dev/null
else
    echo "bootwatchdog: /data belum bisa ditulis — hang terjadi sebelum post-fs-data; jejak hanya di ramoops" > /dev/kmsg 2>/dev/null
fi

setprop sys.powerctl reboot,recovery
