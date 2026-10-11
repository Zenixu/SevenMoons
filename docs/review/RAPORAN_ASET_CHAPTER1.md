# Raporan Aset Chapter 1 — kartu t_41b59543

**Tanggal:** Sesi terbaru
**Pelaksana:** haren
**Status:** selesai, belum di-commit (sesuai instruksi: zeal yang commit di akhir)
**Keputusan terkait:** D002, D007, D009, D014

---

## 1. Ringkasan

Audit menemukan **3 cacat visual nyata** (bukan selera) + **1 bug laten generator** pada
aset yang tampil di vertical slice Chapter 1. Semua diperbaiki di sumber (`gen_art_v2.py`)
lalu aset diregenerasi deterministik.

**Aset yang berubah PIKsel (4):**

| Aset | Ukuran | Perubahan |
|---|---|---|
| `assets/backgrounds/balcony_skyline.png` | 640×200 | **Gedung kota hilang total** → ditambah baris gedung belakang + depan berjendela + kabut |
| `assets/backgrounds/moon_dim.png` | 48×48 | Garis awan horizontal selebar sprite (glitch/scanline) → gumpalan awan lembut |
| `assets/props/mirror.png` | 24×36 | Terbaca "gambar dalam bingkai" → kaca dengan pantulan ruangan + kilau (D007) |
| `assets/backgrounds/bedroom_bg.png` | 640×360 | Prop meja digambar ganda (ghosting) → dihapus dari bg (digambar node Interactable) |

**Catatan byte:** 17 PNG lain (`corridor_bg`, `lift_bg`, `rooftop_bg`, `player_sheet`,
`fb_1..4`, `phone`, `photo_frame`, `silhouette_figure`, `tea_cup`, `wall_clock`,
`intro_panel_1..4`) hanya berbeda **byte** (IDAT/zlib) — **pikselnya identik**. Itu artefak
build Pillow yang berbeda saat PNG lama di-commit, bukan perubahan visual. Tidak perlu
ditakuti saat review.

---

## 2. Detail temuan & perbaikan

### T1 — `balcony_skyline.png` tanpa gedung (bug D009 kambuh)
`make_balcony` menggambar skyline memakai handle `ImageDraw` **lama** setelah
`sky = Image.alpha_composite(sky, stars)` mengganti citra. Semua gambar gedung hilang ke
handle basi. Akibatnya latar klimaks Bab 1 (S04–S06) hanya langit gelap + 40 bintang.
**Fix:** ambil `ImageDraw.Draw(sky)` baru setelah composite; gambar baris gedung belakang
(gelap, berkabut) + baris depan (terang, berjendela hangat) + lapisan kabut.

### T2 — `moon_dim.png` bergaris (glitch)
Awan digambar sebagai baris horizontal selebar sprite → terbaca seperti scanline.
**Fix:** awan jadi gumpalan lembut (`GaussianBlur`), hanya di area lokal.

### T3 — Prop meja kamar ganda (ghosting)
Ponsel/foto/gelas digambar di background **dan** sebagai node `Interactable` dengan offset
kecil → tepi ganda halus.
**Fix:** hapus prop dari background; biarkan node Interactable yang menggambar.

### T4 — `mirror.png` terbaca seperti lukisan (D007)
Kaca polos berbingkai mudah disalahartikan sebagai gambar dalam bingkai.
**Fix:** pantulan ruangan (pita cahaya vertikal + bulan samar + bayangan furnitur) dicampur
manual ke gradien kaca + kilau diagonal ganda → jelas terbaca sebagai cermin.

### T5 — Bug laten: generator tak mereproduksi kasur yang di-approve
Commit `dc083f5` mengubah **hanya PNG** `bedroom_bg.png` (hand-edit), tanpa memperbarui
skrip → menjalankan generator akan **menurunkan** kualitas kasur (regresi).
**Fix:** `make_bedroom` digambar ulang agar mereproduksi gaya kasur yang disetujui (bantal
horizontal terang bertimbul, duvet berkerut, headboard panel). Generator kembali jadi
**sumber tunggal**.

---

## 3. Batasan yang dipatuhi

- **Tidak** memindahkan collision/pintu atau mengubah layout.
- **Tidak** menggambarkan jatuh/darah/tubuh; makna cerita tidak diubah.
- **Tidak** commit (zeal yang commit di akhir).

## 4. Verifikasi

| Uji | Hasil |
|---|---|
| `test_reachability` | LULUS — Bedroom 1380, Corridor 3009, Lift 510 |
| Suite penuh (15 scene) | **15/15 LULUS**, exit 0 |
| Determinisme | regenerasi 2× → byte-identik (`NONE non-deterministic`) |
| Kasur disetujui | byte-identik dengan HEAD (hanya region meja yg beda) |

## 5. File yang disentuh

- `scripts/gen_art_v2.py` — `make_balcony` (skyline handle + awan), `make_bedroom`
  (kasur + hapus prop ganda), `make_props`/`mirror`.
- `docs/DECISIONS.md` — tambah **D014**.
- Aset: 4 PNG berubah piksel (tabel §1) + 17 PNG churn byte (piksel sama).
