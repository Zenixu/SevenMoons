# DECISIONS.md — Keputusan Arsitektur

## D001 — Sistem Dialog: JSON Buatan Sendiri

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Perlu memilih antara:
1. Plugin dialog (Dialogic, Dialogue Manager)
2. Sistem JSON buatan sendiri

### Keputusan
**Sistem JSON buatan sendiri** (`DialogueRunner` + `chapter_XX.json`).

### Alasan
- Game ini punya mekanik unik yang tidak standar di plugin dialog manapun:
  - **Sistem chat** dengan indikator mengetik dan gelembung — bukan dialog RPG biasa.
  - **Pilihan ragu-ragu (HesitantChoice)** — tombol muncul lalu menghilang, atau teks berubah saat kursor mendekat.
  - **Timer menunggu** yang menjadi flag (contoh: `waited_long` di S05).
  - **Meta-layer** — game "sadar" akan pemain, butuh akses fleksibel ke state.
- Plugin dialog menambah lapisan abstraksi yang justru harus di-bypass untuk mekanik di atas.
- Format JSON yang sudah didefinisikan di `GODOT_ARCHITECTURE.md` cukup sederhana dan mudah di-debug.
- Menghindari dependensi eksternal yang bisa patah saat update Godot.

### Konsekuensi
- Perlu menulis `DialogueRunner` sendiri (Fase 1.6).
- Perlu editor/validator JSON sederhana atau skrip uji untuk memastikan format benar.
- Fleksibilitas penuh untuk mekanik khusus.

## D002 — Aset Seni: Generator Pixel Art v2 (gaya OMORI)

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Aset v1 (`scripts/generate_pixel_art.py`) menghasilkan sprite kotak tanpa outline,
tanpa shading, tanpa animasi (karakter statis 1 frame). Kualitas di bawah standar
vertical slice.

### Keputusan
Tulis ulang menjadi `scripts/gen_art_v2.py` dengan gaya **OMORI / A Space for the
Unbound** (moody, outline tebal, palet terbatas).

### Rincian
- **Karakter**: spritesheet `player_sheet.png` 96x240 — 6 baris x 4 kolom, frame
  24x40. Animasi: `idle_down/up/side` (2 frame) dan `walk_down/up/side` (4 frame,
  dengan kontak + passing, ayunan lengan, bob tubuh, dan bayangan bawah).
- **Runtime**: `player.gd` membangun `SpriteFrames` dari spritesheet saat `_ready`
  (via `AtlasTexture`), jadi tidak perlu file `.tres` terpisah. Node `Visual`
  di `bedroom.tscn` adalah `AnimatedSprite2D`.
- **Props**: ponsel, foto, teh, cermin, jam, pintu, siluet — dengan outline & shading.
- **Background**: kamar (tempat tidur, jendela hujan + bulan, meja, pintu balkon,
  berkas cahaya bulan, vignette) dan langit balkon (gedung, bintang, railing, bulan).
- **Kilas balik**: 4 slide naratif (jendela tertawa, mengetik pesan, pintu menutup,
  teh ditolak).

### Catatan teknis
- `ImageDraw` dengan alpha < 255 **menimpa** piksel (bukan membaur) — selalu gambar
  lapisan tembus pandang di `Image` terpisah lalu `Image.alpha_composite`.
- Jalankan: `/usr/bin/python3 scripts/gen_art_v2.py` (butuh Pillow).

### Konsekuensi
- `scripts/generate_pixel_art.py` (v1) usang; aset v2 menggantikannya.
- Semua aset tetap dapat diregenerasi secara deterministik (seed tetap).

## D003 — Aset Seni v2.1: Redesign Karakter & Latar, Folder Aset Dirapikan

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Umpan balik pemain: proporsi karakter vs ruangan/pintu tidak cocok (pintu raksasa,
karakter kecil), desain karakter terlalu polos, dan folder `assets/` berantakan
(semua gambar menumpuk di `assets/art/`).

### Keputusan
- **Karakter** didesain ulang: memakai **hoodie** + **rambut spike biru-hitam
  (mirip Sasuke)**. Frame diperbesar **24x40 -> 32x48** (sheet 4 kolom x 6 baris).
- **Pintu** diperkecil (tinggi ~64 px) agar proporsional terhadap tinggi karakter.
- **Folder aset ditata ulang**: `assets/{characters,backgrounds,props,ui,flashbacks}`
  (plus `audio/`, `shaders/`, `fonts/`). `assets/art/` dihapus; semua referensi
  `res://assets/art/*` diganti ke folder baru.

### Konsekuensi
- `player.gd`: `FRAME_W/FRAME_H = 32/48`, `SHEET_PATH` baru.
- Semua `.tscn`/`.gd` merujuk folder baru. Regenerasi: `/usr/bin/python3 scripts/gen_art_v2.py`.

## D004 — Alur Lantai 5 = Rooftop Langsung + Scene Lift Interior

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Semula lantai 5 memunculkan **lorong dengan pintu kamar lagi**, dan menekan lift
langsung memindah lantai. Pemain ingin: lantai 5 = **atap dengan pager** langsung,
dan naik lantai lewat **interior lift** dulu (masuk -> pilih lantai).

### Keputusan
- Scene baru `scenes/lift/lift.tscn` + `scripts/systems/lift_controller.gd`.
  Pemain **masuk ke dalam lift**, lalu memilih lantai (3 / 4 / 5) dari **peta lantai**
  di dinding.
- Interior lift dibuat **sempit** (kotak lift di tengah, sisi kiri/kanan dibiarkan
  kosong gelap) agar terasa seperti lift sungguhan.
- Lantai 5 membawa pemain **langsung ke `balcony.tscn` (rooftop)** — langit malam,
  bulan, skyline, hujan, dan **pager/railing** memanjang. Tidak ada pintu kamar.
- `corridor_controller.gd`: `FLOOR_MIN=3`, `FLOOR_MAX=4`; lift -> `lift.tscn`.
  `lift_controller.gd`: `ROOF_FLOOR=5`, `ROOFTOP_SCENE=balcony.tscn`.

### Konsekuensi
- Kunci lokalisasi `ROOFTOP_ARRIVE*` menggantikan `CORRIDOR_F5_ARRIVE*`.
- Flag baru: `rooftop_from_lift`, `rooftop_arrived`, `corridor_floor`.

## D005 — Monolog Pembuka Dimainkan Saat Mata Tertutup (Intro)

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Pemain ingin dialog pembuka panjang muncul **di awal game saat pandangan masih
gelap (mata tertutup)**, diketik perlahan, dan **dipotong per bagian** — bukan satu
blok panjang yang tampil sekaligus.

### Keputusan
- Monolog dipindah ke `scenes/intro/intro_cutscene.tscn` (bukan di kamar).
- **Fase 1 (mata tertutup):** layar hitam; monolog Arutala diketik huruf demi huruf,
  **6 bagian** berurutan (kunci `S01_INTRO_1..6`), tiap bagian diberi jeda.
- **Fase 2 (membuka mata):** tirai hitam memudar, hujan mengeras, panel komik muncul.
- `MonologueLabel` digambar **di atas** `FadeRect` (kalau tidak, teks tertutup kotak
  hitam dan layar tampak hitam tanpa teks — sudah diperbaiki + assertion regresi).

### Konsekuensi
- Kecepatan ketik menghormati setting **Kecepatan Teks** (aksesibilitas).

## D006 — Audio: Hujan Berlapis + SFX Ketikan Dialog

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Hujan terasa terlalu berisik; pemain ingin volume hujan turun, hujan lebih pelan
saat mata tertutup & di dalam lift, dan ingin ada **bunyi ketikan saat dialog**.

### Keputusan
- Gerimis dinormalisasi `0.34 -> 0.16`; `AMB_RAIN_DB -4.0 -> -6.0`.
- Lapisan hujan punya level: **normal** (`AMB_RAIN_DB`) dan **pelan/quiet**
  (`AMB_RAIN_QUIET_DB = -15.0`). Dipakai `play_rain_quiet()` saat mata tertutup dan
  di dalam lift; `set_rain_level()` mengeraskan saat "membuka mata".
- SFX baru `type_tick.wav` (0.055s) diputar saat teks dialog/monolog/caption diketik
  (`AudioManager.play_type_tick()`, volume 0 dB). `thought_box.gd` & intro memicunya
  tiap ~0.045-0.05s per 2 karakter.

## D007 — Redesign Kamar Mengikuti Referensi #2 (lantai mengkilap + pita cahaya bulan)

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Pemain memberi **dua gambar referensi** (`assets/example_1.png`, `assets/example_2.png`)
untuk perbaikan kamar, dan minta **condong ke contoh #2** bila memungkinkan.
Referensi #2: suasana indigo dingin monokrom, **lantai keramik mengkilap** dengan
**pita cahaya bulan** memanjang dari jendela, jendela **berkorden tebal**, moonlight
sebagai satu-satunya sumber cahaya.

### Keputusan
- Kamar digambar ulang (`make_bedroom` di `scripts/gen_art_v2.py`) mengikuti #2:
  palet indigo dingin, lantai ubin mengkilap + pantulan bulan berbentuk pita vertikal
  (soft falloff + GaussianBlur), jendela berkorden dengan treeline + hujan + bulan.
- **Tata letak & collision dipertahankan** (wastafel->pintu->kulkas->cermin->kasur->
  jendela->meja) agar 8 interactable & reachability tetap valid.
- Prop `mirror.png` didesain ulang: kaca bergradien + kilau diagonal tipis + pantulan
  samar, agar jelas terbaca sebagai **cermin** (bukan gambar/retak).
- Bayangan kontak ditambah di bawah wastafel/meja/kasur agar furnitur "menempel" lantai.

### Konsekuensi
- Referensi dipindah ke `docs/references/` (bukan `assets/`) supaya tidak ikut jadi aset game.
- Regenerasi latar: `/usr/bin/python3 scripts/gen_art_v2.py` (butuh PIL).
- Referensi #1 dipakai hanya bila #2 tidak memungkinkan; di sini #2 dipakai.
