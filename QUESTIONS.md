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

> **Status (kartu `t_8087ad7d`):** masih **terbuka**. `S01_N01..N03` + blok `S01`
> JSON **tidak disentuh** menunggu jawaban ini.

---

## Q2 (keputusan pemilik, non-blokir) — inkonsistensi naskah O5 ↔ kode (jam)

Naskah `docs/CHAPTER_01.md` O5 (baris 94–99) menulis:
- `[NARASI] Jarumnya tidak sama dengan jam di pojok layar.`
- `[ARU] Mana yang benar?`
- `[ARU] Nggak penting juga.`

…tetapi kode `bedroom_controller.gd:_handle_clock()` memakai kunci **lain**:
- Pemeriksaan pertama → `CLOCK_START` + `CLOCK_TICK`
- Pemeriksaan ulang → `S02_O5_N01` + `S02_O5_A01`

Akibatnya:
- Kunci `S02_O5_A02` ("Mungkin justru karena itu ia berhenti.") **tak pernah dirujuk** —
  sisa versi lama. Ia juga **tidak** cocok lagi dengan alur sekarang (jam sudah
  **berjalan** setelah diperiksa, bukan berhenti).
- Ada gagasan **dua jam** yang tak tuntas: HUD jam kecil `01:00` vs `S08` `02:47`
  (lihat juga usulan kael `docs/review/USULAN_TEKS_KAEL.md` #4 & #8).

**Pertanyaan (menyangkut naskah → mikha tidak mengubah tanpa izin):**
1. Apakah teks naskah O5 (baris 96–98) sudah **usang** dan boleh diselaraskan dengan
   implementasi (`CLOCK_START`/`CLOCK_TICK`)? **atau** pemilik ingin dua-jam tetap ada
   dan kode yang disesuaikan?
2. Bila O5 diselaraskan: bolehkah kunci `S02_O5_A02` **diarsipkan** (sudah dipindah ke
   `docs/review/ARSIP_KUNCI_USANG.md` **belum**, karena menyangkut naskah — menunggu
   jawaban ini)?

> Mikha **tidak** mengubah teks/kunci O5 apa pun sampai pemilik memutuskan.
