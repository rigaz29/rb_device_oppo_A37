#!/system/bin/sh
#
# Pengaman boot A37 — menjamin kegagalan boot berakhir di recovery, bukan diam
# di logo OPPO selamanya.
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
# MEMATIKANNYA
#
#   setprop persist.a37.bootwatchdog 0
#
# Batas 300 detik dipilih karena WITH_DEXPREOPT=true di device ini, jadi tidak
# ada dexopt besar saat boot pertama. Kalau suatu saat dexpreopt dimatikan,
# NAIKKAN batas ini — kalau tidak, boot pertama yang sah akan diputus.

BATAS=300
JEDA=5
OUT=/data/bootfail

# Jangan pernah aktif di mode selain boot normal. Di charger mode, reboot ke
# recovery berarti perangkat yang sedang dicas malah masuk recovery.
case "$(getprop ro.bootmode)" in
    charger|ffbm*|*recovery*) exit 0 ;;
esac

[ "$(getprop persist.a37.bootwatchdog)" = "0" ] && exit 0

habis=0
while [ "$habis" -lt "$BATAS" ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && exit 0
    sleep "$JEDA"
    habis=$((habis + JEDA))
done

# Boot gagal. Kumpulkan apa pun yang masih terbaca, best-effort — setiap
# perintah di bawah boleh gagal tanpa menghentikan yang lain, karena tujuan
# akhirnya (reboot ke recovery) lebih penting daripada kelengkapan berkas.
mkdir -p "$OUT" 2>/dev/null
getprop ro.build.display.id  > "$OUT/build.txt"    2>/dev/null
getprop                      > "$OUT/getprop.txt"  2>/dev/null
dmesg                        > "$OUT/dmesg.txt"    2>/dev/null
logcat -d -v threadtime      > "$OUT/logcat.txt"   2>/dev/null
cat /proc/last_kmsg          > "$OUT/last_kmsg.txt" 2>/dev/null
cp /sys/fs/pstore/*          "$OUT/"               2>/dev/null
sync

# Tinggalkan penanda supaya boot berikutnya tahu ini bukan reboot biasa.
echo "$habis" > "$OUT/tertahan-detik.txt" 2>/dev/null
sync

setprop sys.powerctl reboot,recovery
