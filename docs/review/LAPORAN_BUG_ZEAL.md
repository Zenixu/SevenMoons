# LAPORAN BUG — Chapter 1 (audit oleh zeal)

Tanggal: sesi ini. Runner: Godot 4.7.2.stable.flathub (flatpak, `--headless`).
Workspace: `/home/aruthtale/Projects/seven-moons`

> **PEMBARUAN (audit lanjutan oleh xeon, kartu `t_2aae7cc3`):** lihat
> `docs/review/AUDIT_XEON_CH1.md`. Ringkas: BUG-1 (ChoiceMenu) & BUG-2 (MainMenu
> QuitButton @2x) **sudah diperbaiki** di HEAD & terverifikasi; BUG-3 (`...`)
> **dikonfirmasi disengaja** (bukan bug). Dua temuan BARU: **BUG-5** (SettingsMenu
> 5 label slider KOSONG — kartu fix `t_48893ff8`, lavis) dan **BUG-6**
> (`test_flow_s00_s08` flaky exit 137 karena ambang timeout — kartu `t_ce7adb8c`, xeon).

## Ringkasan
- Suite uji resmi: **16/16 LULUS** (termasuk `test_pause_and_warning` baru). Semua scene boot tanpa SCRIPT ERROR.
- **1 bug KRITIS (P1)**: ChoiceMenu — semua tombol pilihan terpotong → pemain TIDAK BISA memilih.
- 1 bug a11y (P2): MainMenu QuitButton terpotong pada Ukuran Huruf 2x.
- 1 item data (P2): 5 kunci `id.csv` bernilai literal `"..."` (termasuk 1 opsi pilihan).
- 1 hygiene (P3): proses Godot orphan.
- 1 usulan uji regresi (P2).

---

## BUG-1 (P1, KRITIS) — ChoiceMenu: semua tombol pilihan TERPOTONG (tinggi panel 0)
**Gejala pemain:** "menu choice tampilannya choice-nya tidak ada" — panel pilihan muncul tapi tombolnya tak terlihat.

**Bukti runtime** (`tests/_probe_choice.gd`, 3 opsi seperti S03):
```
panel  size=(320.0, 26.0) min=(320.0, 26.0)
scroll size=(290.0, 0.0)   <-- viewport ScrollContainer = 0 px
bc     size=(282.0, 108.0) min=(280.0, 108.0)   <-- 3 tombol butuh 108 px
btn[0] global_y=180.0..212.0  panel_y=167.0..193.0  TERPOTONG=true
btn[1] global_y=218.0..250.0  panel_y=167.0..193.0  TERPOTONG=true
btn[2] global_y=256.0..288.0  panel_y=167.0..193.0  TERPOTONG=true
```

**Akar masalah:** `scenes/ui/choice_menu.tscn` — `PanelContainer` TIDAK punya tinggi minimum; `ButtonsScroll`
(ScrollContainer, `size_flags_vertical=3`) di dalam VBoxContainer menyusut jadi 0 px karena VBox tak punya
tinggi tetap dan PanelContainer hanya 26 px. Konten 108 px di-clip → semua tombol tak terlihat.

**Asal:** regresi dari t_691aaaf0 (menambah ScrollContainer + `horizontal_scroll_mode=0` untuk a11y, tapi
tak memberi tinggi minimum). Versi HEAD tidak punya ScrollContainer sehingga tombol tampil.

**Kenapa lolos uji:** `test_flow_s00_s08` memanggil `choice_menu._on_button_pressed(0)` **langsung** via
`visibility_changed` (tidak butuh tombol terlihat), jadi tak ada uji yang memeriksa geometri/visibilitas.

**Fix terbukti (runtime, `tests/_probe_fix.gd`):**
| Kandidat | panel | scroll | btn terpotong |
|---|---|---|---|
| BASELINE | (320, 26) | (290, 0) | 3 |
| A: hapus expand | (320, 26) | (290, 0) | 3 (gagal) |
| **B: PanelContainer min.y=180** | (320, 180) | (290, 154) | **0** |
| **C: ButtonsScroll min.y=120** | (320, 146) | (290, 120) | **0** |

Rekomendasi: beri tinggi minimum (mis. `ButtonsScroll custom_minimum_size.y ≈ 120`, atau panel
`custom_minimum_size.y` cukup untuk 3 tombol). Pastikan tetap tidak terpotong pada font 1x/1.5x/2x/2.5x.

---

## BUG-2 (P2, aksesibilitas) — MainMenu QuitButton terpotong pada Ukuran Huruf 2x
**Bukti** (`tests/_probe_clip.gd`, `SettingsManager.font_size_multiplier = 2.0`):
```
[main_menu.tscn x2] tombol terpotong=1
  CLIP: MainMenu/.../MenuButtons/QuitButton di luar .../ScrollContainer (btn_y=324..366 scroll_y=12..348)
```
`ScrollContainer` MainMenu membatasi tinggi konten; pada font 2x konten (judul+4 tombol) melebihi viewport
dan tombol Keluar terpotong. Saat 1x aman. Perlu diuji & diperbaiki (scroll harus bisa menggulir ke bawah /
tinggi panel mengikuti konten) pada 2x–2.5x.

---

## BUG-3 (P2, data) — 5 kunci `id.csv` bernilai literal `"..."`
`S01_N01, S02_O1_A01, S03_R1_OPT_C, S03_R3_OPT_A, ROOFTOP_WALK_2` → nilai `...`.
Dua di antaranya ADALAH opsi pilihan (S03_R1_OPT_C, S03_R3_OPT_A) → pemain bisa melihat tombol berisi "...".
Kemungkinan disengaja sebagai isyarat naskah ("..."), tapi harus diverifikasi pemilik naskah.
**Jangan ubah teks tanpa persetujuan** (AGENTS.md aturan 2).

---

## BUG-4 (P3, hygiene) — proses Godot orphan
Beberapa proses `bwrap`/`Godot` sisa run lama masih hidup (OOM/timeout lama). Tidak berbahaya tapi
sebaiknya dibersihkan sebelum sesi uji berikutnya.

---

## USULAN UJI REGRESI (P2)
1. **ChoiceMenu tidak terpotong**: instansiasi + `present_choices` 3 opsi → assert tiap tombol
   `is_visible_in_tree()` DAN `btn.get_global_rect().end.y <= scroll.get_global_rect().end.y` pada
   font 1x dan 2x. (Uji geometri, bukan hanya pemanggilan `_on_button_pressed`.)
2. **Boot smoke**: instantiate tiap scene UI/gameplay → assert tanpa SCRIPT ERROR dan node UI penting
   berukuran > 0.

## Bukti pendukung (skrip probe)
- `tests/_probe_choice.gd` — geometri ChoiceMenu.
- `tests/_probe_fix.gd` — eksperimen 3 kandidat fix.
- `tests/_probe_scenes.gd` — boot smoke 12 scene.
- `tests/_probe_clip.gd` — cek tombol terpotong semua menu (1x & 2x).
- `tests/_probe_dynui.gd` — ChatUI & ThoughtBox (keduanya OK).
