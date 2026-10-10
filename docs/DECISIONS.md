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

## D008 — Perbaikan Karakter (idle diam + tangan), Kasur, & Ukuran Kulkas

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Umpan balik pemain: **kasur masih sangat jelek**, **kulkas terlalu besar**, karakter
**perlu sedikit lebih besar**, dan saat berdiam karakter **harus langsung idle diam**
(tangannya "sangat annoying" karena berayun/menekuk).

### Keputusan
- **Karakter:**
  - **Idle benar-benar diam.** Sebelumnya frame idle memakai tabel langkah yang sama
	dengan walk, sehingga lengan berayun +/-2-3 px dan badan naik-turun. Sekarang
	`draw_char(..., walking=False)` memakai pose statis; frame idle identik.
  - **Tangan & lengan dirapikan:** lengan lebih ramping, diwarnai `hood_sh` (lebih
	gelap dari torso) agar tidak menyatu, dan tangan dibuat kecil (3x2 + ibu jari),
	bukan balok peach besar.
  - **Ukuran sedikit lebih besar:** `player.gd` `sprite_scale = 1.25` (murni visual,
	collision tak berubah) + kompensasi offset agar kaki tetap menempel lantai.
- **Kasur:** digambar ulang — headboard berkepala tiang, matras tebal (highlight atas /
  bayangan bawah), **bantal persegi jelas**, selimut dengan tepi terlipat + kerutan +
  menggantung di sisi kanan, kaki & bayangan kontak. Kini jelas terbaca sebagai kasur.
- **Kulkas:** diperkecil dari ~66x126 -> **48x90** (badan 134..182 x 152..242); collision
  `RectangleShape2D_fridge` 68x124 -> **50x92** dan dipindah ke (158,197); anchor
  interactable disesuaikan agar tetap terjangkau.

### Konsekuensi
- `gen_art_v2.py`: `draw_char(direction, frame, walking=True)`, `build_sheet` mengoper
  flag `walking`; `make_bedroom` (kasur + kulkas) diperbarui.
- Regenerasi: `/usr/bin/python3 scripts/gen_art_v2.py`.
- Uji: `test_reachability` (Bedroom 1364 titik), `test_intro`, `test_chapter1_scenes` LULUS.

## D009 — Lorong/lift/rooftop diselaraskan dengan kamar baru + audio diperkuat

**Tanggal:** Sesi terbaru
**Konteks:** Setelah kamar dirombak (D007) dan karakter diperbaiki (D008), scene lain
(lorong, interior lift, atap) terasa pucat dan tidak senada. Audio juga kurang: ketukan
pintu tetangga memakai SFX *ketikan*, lift tidak punya suara mesin/dentang, dan langkah
kaki tidak berbunyi.

### Keputusan
- **Lorong (`make_corridor`, 1120x360):** palet indigo dingin senada kamar — wainscot +
  baseboard, pipa langit-langit, **kolam cahaya lampu** (dither lembut), keset, tanaman,
  poster penghuni, kontak shadow di ambang pintu. **Posisi x pintu/lift DIPERTAHANKAN**
  (room 40-84, stairs 150-194, nbrA 300-344, nbrB 520-564, elevator 896-984) agar
  interactable tetap valid.
- **Interior lift (`make_lift`, 640x360):** kotak lift sempit di tengah, sisi kiri/kanan
  dibiarkan gelap. Logam brushed (grain halus), langit-langit berpanel + lampu & glow,
  dua daun pintu, **cermin lebih jelas**, panel tombol, peta lantai, grounding lantai.
  Geometri dipertahankan (L=208, R=432, pintu 250-390, peta 398-426 x 200-240).
- **Atap (`make_rooftop`, 640x360):** lantai beton **basah** (grid + retakan + genangan
  dengan highlight pantulan), unit AC/vent bertekstur, pagar memanjang + kontak shadow.
  **Berkas cahaya bulan diperbaiki:** sebelumnya terlihat seperti stiker trapesium keras;
  kini gradien lembut (per-pixel falloff + `GaussianBlur(4)`) dan **diredam di dekat
  pagar**, tidak lagi menembus lantai.
- **Audio diperkuat:**
  - SFX baru: `door_knock.wav` (3 ketuk kayu), `lift_ding.wav` (bell 2 nada), `footstep.wav`.
  - Ambience baru: `lift_hum_loop.wav` (dengung mesin lift, 60Hz + harmonik).
  - `corridor_controller`: ketukan tetangga kini `play_knock()` (sebelumnya keliru memakai
	SFX ketikan).
  - `lift_controller`: masuk lift -> `play_lift_ambience()` (hujan diredam + hum lift);
	pindah lantai -> `play_lift_ding()` lalu hentikan hum.
  - `player.gd`: SFX langkah kaki berkala (`STEP_INTERVAL = 0.34s`) saat berjalan manual
	maupun `auto_walk_to`; langsung berhenti saat diam.

### Konsekuensi
- `gen_art_v2.py`: `make_corridor`/`make_lift`/`make_rooftop` ditulis ulang. **Catatan
  bug:** setelah `Image.alpha_composite(img, ...)`, handle `ImageDraw` lama menunjuk ke
  citra yang dibuang — objek yang digambar setelahnya tak terlihat. Wajib
  `d = ImageDraw.Draw(img)` ulang setelah setiap composite.
- `generate_audio.py`: fungsi `generate_door_knock`, `generate_lift_ding`,
  `generate_lift_hum`, `generate_footstep`.
- `audio_manager.gd`: preload stream baru, layer ambience `AMB_LIFT`, `play_lift_ambience`,
  `stop_lift_hum`, `play_knock`, `play_lift_ding`, `play_footstep`.
- Regenerasi: `/usr/bin/python3 scripts/gen_art_v2.py` dan
  `/usr/bin/python3 scripts/generate_audio.py`.
- Uji: suite 13/13 LULUS (audio, ui, flag, save, settings, dialogue, loop, intro, corridor,
  reachability, chapter1 scenes/full).

## D010 — Kasur dirombak (kecil + bantal horizontal), cermin diturunkan, ThoughtBox auto-hide, teks lift diganti, karakter diperbesar

**Tanggal:** Sesi terbaru
**Konteks:** User menilai kasur "masih sangat jelek" (bantal terasa vertikal, kasur terlalu
besar), minta karakter sedikit lebih besar lagi, teks saat masuk lift diganti, kotak latar
dialog dibuat menghilang saat tak ada teks, dan cermin diturunkan.

### Keputusan
- **Kasur (`make_bedroom`):** diperkecil dari 174 px (b0=296..b1=470) -> **136 px
  (b0=316..b1=452)**.
  - **Headboard:** dari tiang tipis (16 px) -> **panel kokoh** (18 px, `rounded_rectangle`,
	bibir atas terang + garis panel) yang benar-benar menopang.
  - **Bantal:** dibuat jelas **HORIZONTAL & empuk** — `rounded_rectangle` membulat dengan
	highlight atas, **cekung/kerut di tengah**, dan bayangan bawah (sebelumnya balok tipis
	yang terbaca seperti kertas). Bantal lama sebenarnya sudah horizontal (lebar 68 x
	tinggi 24), tetapi kepala kasur yang tinggi-tipis di sisi kiri membuatnya terbaca
	seperti elemen vertikal.
  - **Duvet:** tepi lipatan + kerutan + menggantung di kanan; **kontak shadow** bawah.
- **Cermin:** backing di dinding diturunkan **y 130..172 -> 146..188**; node `Interactables/Mirror`
  `position (254,150) -> (254,166)`, collision `(0,90) -> (0,74)`.
- **Karakter:** `sprite_scale` **1.25 -> 1.4** (murni visual; collision tak berubah).
- **Teks masuk lift:** `LIFT_ENTER` diganti menjadi *"Apakah ini pilihan yang tepat? ..."*
  (sebelumnya deskripsi ruang lift).
- **ThoughtBox auto-hide:** `PanelContainer` kini **disembunyikan saat tak ada teks**
  (`_ready`, `clear`, selesai erase) dan muncul lagi saat `display_thought`. Jadi kotak latar
  tidak mengganggu saat berjalan/idle.

### Konsekuensi
- `gen_art_v2.py`: blok kasur ditulis ulang; backing cermin diturunkan.
- `bedroom.tscn`: collision Bed `176x76 -> 152x74` @ (383,210)->(381,212); Mirror node +
  collision disesuaikan.
- `player.gd`: `sprite_scale = 1.4`.
- `thought_box.gd`: `_set_panel_visible()`; `test_ui.gd` ditambah assertion auto-hide.
- `id.csv`: `LIFT_ENTER` baru.
- Uji: suite 13/13 LULUS (`test_reachability` Bedroom 1364 -> **1380** titik karena kasur
  lebih kecil menambah ruang jalan).

## D011 — Bantal digambar ulang: duduk DI ATAS matras (punya tinggi), tetap horizontal

**Tanggal:** Sesi terbaru
**Konteks:** User menegaskan bantal salah orientasi: "bantal jangan seperti itu, tapi ke arah
atas, jangan ke samping... bantal di atas bukan dari arah atas ke bawah, tapi di atas dan
horizontal ke samping".

### Analisis
Perbandingan langsung (referensi #2 vs render sendiri) menunjukkan **bantal sebelumnya
digambar DATAR menempel di permukaan matras** — seperti stiker/decal, bukan objek dengan
volume. Bentuknya sudah melebar ke samping (horizontal), tetapi karena **tanpa tinggi**,
bantal terbaca "tenggelam" di matras, bukan bantal yang duduk di atasnya.

### Keputusan
- Bantal digambar ulang sebagai **objek bertimbul (punya tinggi/volume)**:
  - badan bantal naik **di atas garis matras** (y176..206, sebelumnya 194..216 yang menempel
    di matras);
  - sisi atas terang + sisi bawah gelap (pencahayaan dari jendela) untuk kesan empuk;
  - sudut membulat (`rounded_rectangle` radius 10) + cekung/kerut tengah + lipatan ujung;
  - **bayangan jatuh ke matras** agar jelas "duduk di atas", bukan menempel.
- Bantal tetap **HORIZONTAL** (melebar ke samping, lebar ~70px) dan **rapat ke headboard**
  (celah 1-2 px dihilangkan: px0 = b0+2).

### Konsekuensi
- `gen_art_v2.py`: blok bantal di `make_bedroom` ditulis ulang.
- Uji: `test_reachability` (Bedroom 1380), `test_chapter1_scenes`, `test_ui` LULUS.
