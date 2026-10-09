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
