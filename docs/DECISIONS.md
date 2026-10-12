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

## D012 — Scene uji headless wajib memanggil `get_tree().quit()` (cegah suite menggantung)

**Tanggal:** Sesi terbaru
**Konteks:** Kartu teknis t_f62da1bf (perbaikan scene/kontroler/UI Chapter 1) — audit
"error runtime headless & jalur tak tercapai". Mesin sempat kehabisan memori (worker
dimatikan sinyal 9) karena puluhan proses Godot menumpuk.

### Analisis
7 dari 12 scene uji (`test_flag_store`, `test_settings_manager`, `test_save_system`,
`test_audio_manager`, `test_loop_manager`, `test_dialogue_runner`, `test_chapter1_scenes`)
mencetak `LULUS` tetapi **tidak pernah memanggil `get_tree().quit()`**. Di Godot headless,
`_ready()` selesai namun main loop tetap berjalan tanpa akhir, jadi proses **menggantung
selamanya**. `run_tests.sh` lama juga tidak memberi batas waktu per-test, sehingga tiap
kali suite dijalankan proses yang menggantung menumpuk (pernah >100 proses, load ~8) dan
akhirnya memicu OOM.

### Keputusan
- Tiap scene uji **wajib** mengakhiri `_ready()` dengan `get_tree().quit(0)` (setelah
  mencetak `LULUS`/`SELESAI`), agar proses headless berhenti sendiri.
- `run_tests.sh` membungkus tiap test dengan `timeout` per-test (`TEST_TIMEOUT`, default
  60s); timeout (exit 124) dihitung **gagal**, bukan lulus.

### Konsekuensi
- `tests/test_*.gd` (7 file) + `run_tests.sh` diperbarui.
- Suite kini **12/12 LULUS** dan keluar dengan exit 0 tanpa menyisakan proses menggantung.

## D013 — Perbaikan node `ChoiceMenu` + pembersihan teks mentah `.tscn` (kartu t_f62da1bf)

**Tanggal:** Sesi terbaru
**Konteks:** Kartu teknis t_f62da1bf (audit scene/kontroler/UI Chapter 1). Dua temuan:
(a) `ChoiceMenu` error runtime karena jalur `@onready` tidak cocok dengan scene;
(b) laporan `docs/review/LAPORAN_TEKS_MENTAH_UI.md` (mikha) menemukan 40 nilai
default `text`/`placeholder_text` masih literal di `.tscn`.

### Keputusan
- **ChoiceMenu:** scene `choice_menu.tscn` menaruh `ButtonContainer` di dalam
  `ButtonsScroll` (ScrollContainer) agar menu panjang bisa di-scroll saat huruf
  diperbesar; `choice_menu.gd` memakai jalur
  `.../VBoxContainer/ButtonsScroll/ButtonContainer`. `PromptLabel` diberi
  `autowrap_mode = 2`.
- **Teks mentah:** seluruh 40 default `text = "..."` di `.tscn` UI/HUD **dikosongkan**
  (`text = ""`). Semua node sudah diisi lewat `tr()` saat `_ready()`/`setup()`, jadi
  tidak ada perubahan perilaku — hanya menghapus sisa default editor yang melanggar
  konvensi "semua teks lewat lokalisasi" (`AGENTS.md`, `docs/agents/lavis.md`).
- **Uji pengunci:** `tests/test_ui_accessibility.gd` menambah uji ke-4
  (`_test_no_raw_literals`) yang membaca tiap `.tscn` UI/HUD dan gagal bila ada
  `text`/`placeholder_text` berisi literal.

### Konsekuensi
- `scenes/ui/choice_menu.tscn`, `scripts/ui/choice_menu.gd`.
- 11 `.tscn` (main_menu, settings_menu, help_menu, content_warning, choice_menu,
  chat_bubble, flashback, corridor, lift, bedroom, balcony) dibersihkan.
- `tests/test_ui_accessibility.gd` +1 uji.
- Suite **15/15 LULUS**, exit 0.

## D014 — Rapikan aset Chapter 1 (bug skyline hilang, bulan samar, cermin, prop ganda)

**Tanggal:** Sesi terbaru
**Konteks:** Kartu t_41b59543 — pemilik menilai beberapa aset/UI Chapter 1 "kurang rapi".
Audit menemukan tiga cacat nyata (bukan sekadar selera) + satu bug laten generator.

### Temuan
1. **`balcony_skyline.png` TIDAK punya gedung sama sekali.** `make_balcony` menggambar
   skyline memakai handle `ImageDraw` lama setelah `Image.alpha_composite(sky, stars)`
   mengganti citra — bug yang sama seperti D009, tetapi tidak ikut diperbaiki di sini.
   Akibatnya latar klimaks Bab 1 (S04–S06) hanya langit gelap + 40 bintang (city hilang).
2. **`moon_dim.png`** (balcony/rooftop) punya garis awan horizontal selebar sprite →
   terbaca seperti scanline/glitch.
3. **Prop meja kamar digambar dua kali** (di bg + node Interactable) → ghosting halus.
4. **`mirror.png`** terbaca seperti "gambar dalam bingkai", bukan cermin (D007 meminta
   jelas terbaca sebagai cermin).
5. Bug laten: `make_bedroom` di skrip lama tidak lagi mereproduksi kasur yang disetujui
   pemilik (commit `dc083f5` mengubah hanya PNG). Skrip kini menggambar kasur bergaya
   disetujui (bantal horizontal terang bertimbul + duvet berkerut) sehingga generator jadi
   **sumber tunggal** (regenerasi tidak lagi menurunkan kualitas kasur).

### Keputusan
- **`make_balcony`:** ambil handle `ImageDraw.Draw(sky)` baru setelah composite; gambar
  baris gedung belakang (gelap, berkabut) + baris depan (terang, berjendela) + kabut.
- **`make_balcony` (moon):** awan jadi gumpalan lembut (`GaussianBlur`), bukan garis.
- **`make_bedroom`:** hapus prop meja dari background (digambar node Interactable).
- **`make_props` (mirror):** kaca gradien + pantulan ruangan dicampur manual (alpha
  di-blend, bukan ditimpa) + kilau diagonal ganda → terbaca sebagai cermin.
- **`make_bedroom` (kasur):** reproduksi gaya kasur yang disetujui (lihat temuan 5).

### Batasan & keamanan
- **Tidak ada collision/pintu/layout yang diubah** (hanya aset PNG + `gen_art_v2.py`).
  `test_reachability` LULUS (Bedroom 1380, Corridor 3009, Lift 510).
- Tidak ada gambar jatuh/darah/tubuh; makna cerita tidak diubah (SAFETY_AND_CONTENT).

### Konsekuensi
- `scripts/gen_art_v2.py` (make_balcony, make_bedroom, make_props/mirror).
- Aset diregenerasi deterministik: `assets/backgrounds/balcony_skyline.png`,
  `assets/backgrounds/bedroom_bg.png`, `assets/backgrounds/moon_dim.png`,
  `assets/props/mirror.png` (+ PNG lain yang ikut di-commit di branch ini).
- Verifikasi: regenerasi dua kali → byte-identik; suite **15/15 LULUS**.

## D015 — Content Warning sebagai scene boot + Menu Jeda (Esc)

**Tanggal:** Sesi terbaru
**Status:** Diputuskan (keputusan pemilik; dapat diubah)
**Konteks:** GATE Chapter 1 (`t_cf5fa9e3`, komentar 20) menolak merge: item keamanan wajib #3
gagal karena **Content Warning tidak pernah tampil** (`project.godot` `run/main_scene` =
`main_menu.tscn`; `content_warning.tscn` tak dirujuk jalur boot mana pun) dan **tidak ada
Menu Jeda** sama sekali. Melanggar SAFETY_AND_CONTENT.md §3.1/§3.2/§3.4 dan urutan
CHAPTER_01.md S00. Kartu perbaikan: `t_cc015717`.

### Keputusan
1. **`content_warning.tscn` dirutekan sebagai scene boot** (`run/main_scene`), sehingga
   peringatan **SELALU tampil setiap kali game dijalankan** dan **butuh konfirmasi**
   ("Aku mengerti, lanjutkan" → `main_menu.tscn`; "Lihat bantuan" → HelpMenu; "Keluar" → quit).
   Ini pembacaan **paling ketat** dari SAFETY §3.1 ("sebelum permainan dimulai") dan
   **tidak mengarang flag persisten** first-run yang tidak diminta spesifikasi.
   *Rasional:* kartu menyerahkan pilihan "sekali vs setiap boot" ke pemilik, tetapi tidak ada
   sinyal first-run yang dibutuhkan di tempat lain; menampilkan tiap boot paling aman bagi
   pemain dan paling sederhana untuk diaudit. **Bila pemilik ingin "hanya sekali",** tambahkan
   flag di `SettingsManager` (mis. `content_warning_acknowledged`) dan cek di awal boot —
   **tanpa mengubah** `content_warning.tscn` itu sendiri.
2. **Menu Jeda (Esc)** dibuat sebagai komponen dapat-pakai-ulang
   (`scripts/ui/pause_menu.gd` + `scenes/ui/pause_menu.tscn`) dan dipasang di **semua scene
   yang dilihat pemain**: bedroom, corridor, lift, balcony, intro, flashback. Berisi
   **Menu Bantuan** + **Keluar** (tanpa penalti). Saat jeda, `get_tree().paused = true`
   (waktu permainan benar-benar berhenti); node memakai `process_mode = ALWAYS` agar tetap
   menerima input. `Esc` menutup Menu Bantuan lebih dulu bila terbuka, lalu menutup jeda.
3. **Aksi input `pause`** ditambahkan di `project.godot` `[input]`, dipetakan ke **Esc**
   (`physical_keycode 4194304 + 1`). Tidak menabrak `ui_cancel`/`ui_accept` bawaan.

### Batasan & keamanan
- **Tidak ada naskah/dialog/urutan adegan yang diubah**: `git diff` untuk
  `docs/CHAPTER_01.md`, `docs/STORY_BIBLE.md`, `data/chapters/chapter_01.json` **kosong**.
- Semua teks lewat `tr()`; kunci baru di `data/localization/id.csv`
  (`UI_RESUME`, `PAUSE_TITLE`, `PAUSE_HINT`) — `test_ui_accessibility` tetap lulus
  (tidak ada literal mentah di `.tscn`).
- Uji regresi baru `tests/test_pause_and_warning.gd` memverifikasi: (a) scene boot =
  content warning & `ContentWarning.MAIN_MENU_SCENE` menuju menu utama; (b) aksi `pause`
  terpetakan ke Esc; (c) content warning butuh konfirmasi & memancarkan
  `warning_acknowledged`; (d) Menu Bantuan terjangkau dari menu utama; (e) Menu Jeda ada di
  keenam scene, `Esc` membuka/menutup, `paused` menyala/mati, Menu Bantuan (memuat 119)
  terjangkau dari jeda, tombol keluar selalu ada.
- Suite: **16/16 lulus** (headless Godot 4.7.2), exit 0, tanpa proses menggantung.

### Konsekuensi
- `project.godot` (`run/main_scene`, bagian `[input]`), `data/localization/id.csv`
  (+ `.id.translation` diregenerasi), `scripts/ui/content_warning.gd` (konstanta
  `MAIN_MENU_SCENE`), berkas baru `scripts/ui/pause_menu.gd` + `scenes/ui/pause_menu.tscn`,
  sisipan `PauseMenu` di 6 `.tscn` scene, `tests/test_pause_and_warning.gd`/`.tscn`,
  `run_tests.sh` (+1 entri).

## D016 — Alur kamar wajib lewat lorong + lift ke rooftop (bukan cutscene langsung)

**Tanggal:** Sesi terbaru
**Status:** Diputuskan (kartu `t_033e8f70`)
**Konteks:** Pemilik: *"ketika selesai membaca chat kenapa langsung cutscene ke akhir,
tidak berjalan ke lorong dan melewati liftnya?"* Dari kamar, trigger jendela/balkon
(`BalconyTrigger`) memanggil `start_s03_monologue()` lalu **langsung**
`change_scene_to_file("balcony.tscn")`. Karena `balcony_controller` memutar S04a→S04→S05→S06,
pemain dilempar ke rangkaian akhir tanpa melewati lorong & lift — bertentangan dengan
naskah S04a ("Setelah naik lift ke lantai 5, Arutala berjalan otomatis ke tengah atap…")
dan scene `corridor.tscn` + `lift.tscn` yang sudah ada.

### Keputusan
- **Keluar kamar selalu menuju LORONG.** Baik pintu O6 (`_handle_door`) maupun jendela/balkon
  (`_on_balcony_trigger_entered`) kini memanggil helper bersama `_leave_room_via_corridor()`
  yang memindahkan scene ke `corridor.tscn`. Rangkaian akhir hanya dicapai lewat
  **lorong → lift → lantai 5**.
- **S03 tetap dimainkan, tepat sekali.** Helper `_play_s03_once()` menjalankan
  `start_s03_monologue()` (naskah: S03 = monolog sebelum ke balkon) sebelum pemain
  berangkat; dijaga flag per-instans `_s03_played` agar tidak terlewat maupun berulang.
- **Kedatangan rooftop dipertahankan.** `balcony_controller._arrive_then_start()` (jalur
  `rooftop_from_lift`), `FlagStore` `corridor_floor=5` + `rooftop_from_lift=true` dari
  `lift_controller` — **tidak diubah**. Tidak ada naskah/urutan adegan/flag yang diubah.
- **Uji alur scene baru** `tests/test_route_room_rooftop.{gd,tscn}`: driver menjalankan
  RANTAI SCENE NYATA (menyentuh Interactable & menekan tombol asli, aman melewati
  `change_scene_to_file`), lalu meng-assert `bedroom → corridor → lift → balcony`,
  tidak ada lompatan langsung kamar→balcony, S03 tepat sekali, dan flag rooftop benar.

### Konsekuensi
- `scripts/systems/bedroom_controller.gd` (helper `_play_s03_once`, `_leave_room_via_corridor`;
  kedua jalur keluar dirutekan ke lorong), `tests/test_route_room_rooftop.gd`/`.tscn`,
  `run_tests.sh` (+1 entri). Suite: **19/19 lulus** (headless Godot 4.7.2), exit 0.
- `python3 tests/validate_data.py` → OK (exit 0). Tidak ada kunci lokalisasi baru.
