# AUDIT KUNCI AMBIGU / USANG — `id.csv` (Chapter 1)

Kartu: `t_8087ad7d` · Assignee: **mikha** (Data & Lokalisasi)
Permintaan pemilik: *"ada bagian-bagian teks yang ambigu, coba benarkan lagi."* (sisi DATA/CSV)
Alat audit: `tests/scan_unused_keys.py` (pemindai kunci) + `tests/validate_data.py` (validator).

> **Aturan yang dipatuhi:** AGENTS.md butir 2 — **naskah tidak diubah**.
> Tidak ada satu baris pun `docs/CHAPTER_01.md` yang disentuh. Yang dibenahi hanya
> **data lokalisasi** (`id.csv`, `chapter_01.json`) yang **usang/tak-terjangkau**.

## Ringkasan klasifikasi

| # | Kunci | Nilai (ringkas) | Jenis | Klasifikasi |
|---|-------|-----------------|-------|-------------|
| 1 | `UI_CONTINUE` | Lanjutkan | UI (dobel `UI_RESUME`) | **usang → diarsipkan** |
| 2 | `UI_BACK` | Kembali | UI | **usang → diarsipkan** |
| 3 | `UI_CONFIRM` | Konfirmasi | UI | **usang → diarsipkan** |
| 4 | `SETTINGS_SAVE` | Simpan | UI | **usang → diarsipkan** |
| 5 | `CLOCK_HINT` | Periksa jam di dinding. | UI hint | **usang → diarsipkan** |
| 6 | `CORRIDOR_LIFT_UP` | Naik satu lantai | label pilihan (desain lift lama) | **usang → diarsipkan** |
| 7 | `CORRIDOR_LIFT_DOWN` | Turun satu lantai | label pilihan (desain lift lama) | **usang → diarsipkan** |
| 8 | `CORRIDOR_LIFT_STAY` | Diam di sini | label pilihan (desain lift lama) | **usang → diarsipkan** |
| 9 | `CORRIDOR_LIFT_STAY_RES` | Nggak ada tempat lain yang lebih baik. | narasi (desain lift lama) | **usang → diarsipkan** |
| 10 | `CORRIDOR_ARRIVE_LINE` | Selamat datang di lantai %d… | string format sistem | **usang → diarsipkan** |
| 11 | `CORRIDOR_F5_HINT` | Di atas lantai ini hanya ada atap… | hint (desain lantai-5 lama) | **usang → diarsipkan** |
| 12 | `ROOFTOP_ARRIVE` | Lantai lima. Lift membawaku ke atap… | narasi (desain rooftop lama) | **usang → diarsipkan** |
| 13 | `ROOFTOP_ARRIVE2` | Di sini tidak ada pintu lagi… | narasi (desain rooftop lama) | **usang → diarsipkan** |
| 14 | `ROOFTOP_ARRIVE3` | Aku melangkah ke tengah atap… | narasi (desain rooftop lama) | **usang → diarsipkan** |
| 15 | `S02_O5_A02` | Mungkin justru karena itu ia berhenti. | narasi O5 (jam) | **menunggu pemilik** (QUESTIONS Q2) |
| 16 | `S01_N01` / `S01_N02` / `S01_N03` | `...` / Aku bangun… / Atau mungkin… | narasi S01 versi lama | **menunggu pemilik** (QUESTIONS Q1, sudah ada) |
| 17 | `S02_O1_A01` | `...` | dialog ARU | **disengaja — dipertahankan** |

**Bug data diperbaiki:**
- `chapter_01.json` — `sender` pesan misterius S08 bernilai `"Unknown"`, sedangkan
  kode yang benar-benar menampilkannya (`bedroom_controller.gd`) memakai `"???"`
  (`scripts/systems/bedroom_controller.gd:577,580,583,592`). Diselaraskan → `"???"`.
  (Nilai ini hanya label pengirim yang tampil di gelembung chat; bukan teks naskah.)

**Arsip:** 14 kunci usang dipindah ke `docs/review/ARSIP_KUNCI_USANG.md` (dapat dipulihkan),
lalu dihapus dari `id.csv`. Tidak ada kunci yang hilang dari jalur produksi.

## Bukti: kenapa kunci-kunci itu usang (bukan sekadar "tak dipakai")

Riwayat git + kode menunjukkan tiap grup **digantikan** oleh desain/kunci baru:

- **`CORRIDOR_LIFT_UP/DOWN/STAY/STAY_RES`** — menu lift di lorong (commit `ff25479`).
  Sejak `283954b` pemain **masuk ke dalam lift** (`scenes/lift/lift.tscn`) dan memilih
  dari peta lantai: `LIFT_FLOOR_3/4/5`, `LIFT_PANEL`, `LIFT_HINT`
  (`scripts/systems/lift_controller.gd`). Menu lama tak pernah dipanggil lagi.
- **`CORRIDOR_ARRIVE_LINE`** — string format `%d` untuk "selamat datang di lantai N"
  yang tak lagi ditampilkan (lantai diumumkan lewat `CORRIDOR_F3_INTRO*` / `CORRIDOR_F4_ARRIVE*`).
- **`CORRIDOR_F5_HINT`** — petunjuk lantai 5 versi lama (`6efd33c`, saat `FLOOR_MAX=5`).
  Sekarang lorong hanya lantai 3–4 (`FLOOR_MAX=4`) dan lantai 5 = atap lewat lift.
- **`ROOFTOP_ARRIVE/2/3`** — ditambahkan `283954b` menggantikan `CORRIDOR_F5_ARRIVE*`
  (D004), lalu digantikan lagi oleh `ROOFTOP_WALK_1/2/3` (dialog perenungan saat berjalan
  ke tengah atap, `scripts/systems/balcony_controller.gd:_arrive_then_start`).
- **`CLOCK_HINT`** — petunjuk lama "Periksa jam di dinding."; alur jam sekarang memakai
  `CLOCK_START`/`CLOCK_TICK` (`scripts/systems/bedroom_controller.gd:_handle_clock`).
- **`UI_CONTINUE` / `UI_BACK` / `UI_CONFIRM` / `SETTINGS_SAVE`** — label UI generik yang
  tak pernah dirujuk skrip/scene mana pun (mis. `UI_CONTINUE` dobel dengan `UI_RESUME`).

## Kunci bernilai `...` (dikonfirmasi ulang — disengaja)

Lima kunci `S01_N01`, `S02_O1_A01`, `S03_R1_OPT_C`, `S03_R3_OPT_A`, `ROOFTOP_WALK_2`
bernilai `...` — **terverifikasi disengaja** sebagai isyarat hening/jeda
(`docs/review/VERIFIKASI_KUNCI_TITIK.md`, kutipan naskah ada). **Tidak diubah.**
Karena itu pula `S02_O1_A01` **tidak** diarsipkan walau tak dirujuk kode: nilainya
adalah teks naskah yang sah (hanya tak ditampilkan implementasi).

## Verifikasi

- `python3 tests/validate_data.py` → **OK (exit 0)**; 173 kunci CSV.
- `python3 tests/scan_unused_keys.py` → tinggal 2 kunci:
  `S02_O5_A02` (menunggu pemilik, Q2) & `S02_O1_A01` (disengaja, nilai `...`).
- `./run_tests.sh` → **18 lulus, 0 gagal**.
- `id.id.translation` (artefak build lokalisasi yang ikut ter-commit) di-regenerasi
  lewat `godot --headless --import` agar runtime cocok dengan `id.csv` baru.

## Yang TIDAK disentuh (menunggu keputusan pemilik)

1. **Naskah `docs/CHAPTER_01.md`** — utuh, tidak ada perubahan.
2. **Blok `S01` `chapter_01.json` + `S01_N01..N03`** — QUESTIONS **Q1** (sudah ada).
3. **Inkonsistensi jam O5** (naskah vs kode) — QUESTIONS **Q2** (baru).
