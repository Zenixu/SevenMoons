# ARSIP KUNCI USANG — `id.csv` (Chapter 1)

Kartu: `t_8087ad7d` · Assignee: **mikha** (Data & Lokalisasi)
Lihat analisis: `docs/review/AUDIT_KUNCI_AMBIGU.md`.

## Kenapa diarsipkan (bukan dihapus permanen)
Kunci-kunci ini **tidak dirujuk** produksi (`scripts/`, `scenes/`, `data/`) maupun uji
mana pun — sisa desain lama yang sudah **digantikan** kunci baru (lihat AUDIT untuk
bukti riwayat git). Teksnya adalah naskah yang sudah disetujui, jadi **tidak dibuang**;
hanya dipindahkan dari `id.csv` ke arsip ini agar tabel lokalisasi bersih.

## Cara memulihkan
Tambahkan baris di bawah kembali ke `data/localization/id.csv` (di posisi semula,
urutan tidak kritis), lalu jalankan `python3 tests/validate_data.py`.

## Kunci yang diarsipkan (14)

```csv
UI_CONTINUE,Lanjutkan
UI_BACK,Kembali
UI_CONFIRM,Konfirmasi
SETTINGS_SAVE,Simpan
CLOCK_HINT,Periksa jam di dinding.
CORRIDOR_LIFT_UP,Naik satu lantai
CORRIDOR_LIFT_DOWN,Turun satu lantai
CORRIDOR_LIFT_STAY,Diam di sini
CORRIDOR_LIFT_STAY_RES,Nggak ada tempat lain yang lebih baik.
CORRIDOR_ARRIVE_LINE,Selamat datang di lantai %d. Pintu lift terbuka lagi.
CORRIDOR_F5_HINT,Di atas lantai ini hanya ada atap. Lift akan membawaku ke sana.
ROOFTOP_ARRIVE,Lantai lima. Lift membawaku ke atap, bukan ke lorong.
ROOFTOP_ARRIVE2,Di sini tidak ada pintu lagi — hanya pager besi, langit, dan hujan yang belum berhenti.
ROOFTOP_ARRIVE3,Aku melangkah ke tengah atap. Anginnya dingin, dan untuk sesaat, pikiranku ikut diam.
```

## Pengganti (kunci yang dipakai sekarang)

| Kunci lama | Digantikan oleh |
|---|---|
| `CORRIDOR_LIFT_UP/DOWN/STAY/STAY_RES` | `LIFT_PANEL`, `LIFT_HINT`, `LIFT_FLOOR_3/4/5`, `LIFT_SAME_FLOOR`, `CORRIDOR_LIFT_MOVE` |
| `CORRIDOR_F5_HINT` | lorong hanya lantai 3–4; lantai 5 = atap lewat `LIFT_FLOOR_5` |
| `ROOFTOP_ARRIVE/2/3` | `ROOFTOP_WALK_1/2/3` (dialog saat berjalan ke tengah atap) |
| `CLOCK_HINT` | `CLOCK_START`, `CLOCK_TICK` |
| `UI_CONTINUE` | `UI_RESUME` (menu jeda) |
| `UI_BACK`, `UI_CONFIRM`, `SETTINGS_SAVE` | tidak dipakai; tombol memakai `UI_CLOSE` / `UI_START` / dsb. |
| `CORRIDOR_ARRIVE_LINE` | tidak dipakai (lantai diumumkan lewat `CORRIDOR_F3_INTRO*` / `CORRIDOR_F4_ARRIVE*`) |
