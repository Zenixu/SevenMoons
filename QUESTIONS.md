# QUESTIONS.md — Pertanyaan untuk Pemilik

Dari **mikha** (kartu `t_5728c5c3`, verifikasi kunci `...`). Lihat
`docs/review/VERIFIKASI_KUNCI_TITIK.md` untuk bukti lengkap.

Semua 5 kunci bernilai `...` (`S01_N01`, `S02_O1_A01`, `S03_R1_OPT_C`, `S03_R3_OPT_A`,
`ROOFTOP_WALK_2`) **terverifikasi disengaja** (ada kutipan naskah) — jadi tidak ada
teks yang diubah. Tidak memblokir pekerjaan.

## Q1 (keputusan pemilik, non-blokir) — kunci S01 usang
Naskah S01 ditulis ulang (commit `d10c2d3`) menjadi monolog mata-tertutup `S01_INTRO_1..6`,
tetapi `chapter_01.json` blok `S01` **masih memuat** langkah `narration` lama
(`S01_N01`, `S01_N02`, `S01_N03`) dan `id.csv` masih menyimpan kunci itu.
- `S01_N01` = `...` (baris `[NARASI] ...` dari naskah S01 **versi lama**).
- Nilainya tidak tampil ke pemain (S01 dijalankan oleh `intro_cutscene` + `bedroom_controller`).

**Pertanyaan:** bolehkah mikha **memensiunkan** kunci `S01_N01..N03` + langkah narasi
lama di blok `S01` JSON (hapus dari data, bukan dari naskah)? Atau dibiarkan sebagai arsip?
Mikha menunggu persetujuan sebelum menyentuh data yang menyangkut naskah.
