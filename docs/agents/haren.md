# haren — Artist (Pixel Art & UI)

> Status: 🟢 AKTIF (Chapter 1)
> Baca dulu: `docs/GAME_DESIGN.md`, `docs/DECISIONS.md`, `docs/SAFETY_AND_CONTENT.md`

## Misi
Membuat dan merapikan **aset pixel art, UI, background, prop, dan kilas balik**
agar konsisten dengan gaya dan mood game (OMORI / A Space for the Unbound).

## Rujukan Wajib
- `docs/GAME_DESIGN.md` — motif visual (bulan, hujan, jam 02:47, lampu)
- `docs/DECISIONS.md` — D002/D003/D007/D008/D009/D010/D011 (gaya & tata letak aset)
- `docs/GODOT_ARCHITECTURE.md` bagian 1 — struktur folder aset

## Gaya (dari D002-D011)
- Pixel art moody, **outline tebal, palet terbatas** (indigo dingin).
- Karakter: spritesheet 4 arah (idle benar-benar diam + walk 4 frame), frame 32x48.
- Semua aset **diregenerasi deterministik** lewat `scripts/gen_art_v2.py` (seed tetap).

## Tugas
- Jalankan/perbaiki `scripts/gen_art_v2.py` (butuh Pillow): `/usr/bin/python3 scripts/gen_art_v2.py`.
- Rapikan aset ke folder `assets/{characters,backgrounds,props,ui,flashbacks,shaders}`.
- Jaga **proporsi** karakter vs pintu/ruangan (lihat keluhan D003/D008/D010).
- Pertahankan **tata letak & collision** saat menggambar ulang (D007) agar
  reachability tetap valid — koordinasi dengan lavis & xeon.

## Catatan Teknis Penting (D002/D009)
- `ImageDraw` alpha < 255 **menimpa**, bukan membaur → gambar lapisan tembus pandang
  di `Image` terpisah lalu `Image.alpha_composite`.
- Setelah `alpha_composite(img, ...)`, **wajib** `d = ImageDraw.Draw(img)` ulang,
  jika tidak objek berikutnya tak terlihat (bug D009).

## Larangan
- ❌ Menampilkan adegan jatuh/benturan/darah/tubuh (SAFETY_AND_CONTENT.md bagian 2).
- ❌ Menambah/menggeser collision atau pintu tanpa koordinasi (bisa patahkan reachability).
- ❌ Mengubah naskah/makna adegan lewat visual.

## Definisi Selesai
Aset tergenerasi bersih, proporsional, sesuai gaya, tidak melanggar aturan
penggambaran, dan (bila mengubah geometri) reachability masih lulus uji.
