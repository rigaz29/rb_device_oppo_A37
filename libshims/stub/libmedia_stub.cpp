/*
 * Stub kosong untuk /vendor/lib/libmedia.so.
 *
 * libril-qc-qmi-1.so mencantumkan libmedia.so di DT_NEEDED tetapi TIDAK memakai
 * satu pun simbolnya -- diukur dengan mengiris simbol UND-nya terhadap simbol
 * yang didefinisikan libmedia platform: hasilnya NOL. Yang dibutuhkan hanya agar
 * linker menemukan berkas dengan soname itu, sehingga rild bisa dlopen blob RIL:
 *
 *   RILD: dlopen failed: library "libmedia.so" not found:
 *         needed by /system/vendor/lib/libril-qc-qmi-1.so
 *
 * Sengaja kosong. Kalau suatu saat ada blob yang benar-benar memanggil simbol
 * libmedia dari namespace vendor, ia akan gagal saat memuat dengan pesan simbol
 * yang jelas -- bukan diam-diam berperilaku salah.
 */
namespace {
[[maybe_unused]] const char kA37LibmediaStub[] = "A37 libmedia stub";
}
