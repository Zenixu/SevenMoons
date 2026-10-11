# Verifikasi Kunci `id.csv` Bernilai `...` — Chapter 1

Kartu: `t_5728c5c3` · Assignee: **mikha** (Data & Lokalisasi)
Sumber temuan: `docs/review/LAPORAN_BUG_ZEAL.md` (BUG-3, ditemukan oleh zeal)
Metode: bandingkan tiap nilai CSV dengan naskah resmi `docs/CHAPTER_01.md` (+ riwayat git).

## Kesimpulan
**Kelima kunci `...` adalah TEKS NASKAH YANG DISENGAJA — bukan placeholder/bug.**
Tidak ada teks yang diubah (AGENTS.md aturan 2). Suite tetap hijau (17/17).

`...` di sini adalah **jeda/isyarat hening** ("diam") yang memang ditulis di naskah —
sesuai Gaya Teks Game AGENTS.md: *"Kalimat pendek. Boleh terputus. Jeda itu bagian dari gaya."*

## Klasifikasi per kunci (bukti kutipan naskah)

| # | Kunci | Nilai | Jenis | Kutipan naskah (`docs/CHAPTER_01.md`) | Verdict |
|---|-------|-------|-------|----------------------------------------|---------|
| 1 | `S01_N01` | `...` | Narasi | S01 **versi lama**: `[NARASI] ...` lalu `[NARASI] Aku bangun.` | **Disengaja** (lihat catatan A) |
| 2 | `S02_O1_A01` | `...` | Dialog ARU | baris 62: `[ARU] ...` (sebelum `[ARU] Aku belum siap tahu lanjutannya.`) | **Disengaja** |
| 3 | `S03_R1_OPT_C` | `...` | **Opsi pilihan** | baris 141: `- C. "..." (diam)` | **Disengaja** |
| 4 | `S03_R3_OPT_A` | `...` | **Opsi pilihan** | baris 156: `- A. "..." -> [NARASI] Arutala menatap ponsel…` | **Disengaja** |
| 5 | `ROOFTOP_WALK_2` | `...` | Dialog ARU | baris 180: `2. [ARU] ...` (di antara baris 1 & `...mungkin iya.`) | **Disengaja** |

### Bukti tambahan
- Riwayat CSV sejak commit awal (`a153b82`, fase 3) sudah bernilai `...` untuk keempat kunci
  pertama — **persis** seperti naskah saat itu, bukan nilai yang "tertinggal" karena salah tulis.
- `S03_R1_OPT_C` dan `S03_R3_OPT_A` adalah opsi pilihan; naskah menuliskannya **literal** sebagai
  `"..."` dengan arah panggung `(diam)` — jadi pemain melihat tombol `...` **secara sengaja**
  (memilih diam adalah bagian dari mekanik "semua pilihan berujung sama").
- `ROOFTOP_WALK_2` = `...` adalah baris kedua dari tiga (`...` → `...mungkin iya.`), jeda di tengah monolog.

## Catatan (bukan bug teks, tidak mengubah naskah)

**A. `S01_N01..N03` kini USANG (stale).** Naskah S01 ditulis ulang pada commit `d10c2d3`
("S01 jadi monolog mata-tertutup 6 bagian") menjadi `S01_INTRO_1..6` + `[NARASI] Gerimis di kaca…`.
Naskah S01 **sekarang tidak lagi punya** baris `[NARASI] ...`. Kunci `S01_N01..N03` (dan blok `S01`
di `chapter_01.json`) adalah sisa versi lama:
- `S01_N01` = `...` → teks naskah S01 **versi lama** (bukan bug, tapi kini tak ada di naskah).
- Nilai `...` ini **tidak tampil ke pemain**: pembuka S01 dijalankan oleh
  `scenes/intro/intro_cutscene.tscn` (`S01_INTRO_1..6`) + `bedroom_controller.gd` (`S01_A01/A02`),
  bukan lewat `DialogueRunner` (`start_scene("S01")` tidak dipanggil di kode game).
- Perlu keputusan pemilik apakah kunci usang ini dipensiunkan (lihat `QUESTIONS.md`).

**B. `S02_O1_A01` = `...` tidak dipakai implementasi.** `bedroom_controller._handle_phone()`
menampilkan N01 → N02 → PREVIEW → A02 (melewati A01). Nilai tetap benar sebagai teks naskah;
validator melaporkannya sebagai "kunci tak direferensikan" (WARN, bukan error).

## Hasil pemeriksaan
- `python3 tests/validate_data.py` → **OK** (exit 0); 186 kunci CSV, 46 kunci teks JSON, semua tersedia.
- `./run_tests.sh` → **17 lulus, 0 gagal**.
- Tidak ada perubahan pada `data/localization/id.csv`, `chapter_01.json`, atau naskah.
