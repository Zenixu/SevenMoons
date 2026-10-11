# LAPORAN AUDIT BUG — Chapter 1 (audit oleh xeon, bug-hunter)

Tanggal: 2026-10-11 (sesi ini).
Runner: Godot `4.7.2.stable.flathub.ed1daf0bf` (flatpak, `--headless`).
Workspace: `/home/aruthtale/Projects/seven-moons`
Kartu: `t_2aae7cc3` (AUDIT bug-hunter menyeluruh Chapter 1).

Melanjutkan `docs/review/LAPORAN_BUG_ZEAL.md`. Fokus: cari bug NYATA yang **lolos
suite resmi**, memakai **geometri & visibilitas** (bukan sekadar pemanggilan method),
pada font **1x / 1.5x / 2x / 2.5x**.

## Ringkasan

- Suite resmi: **16/17 "LULUS"** — 1 test (`test_flow_s00_s08`) mencetak LULUS tetapi
  **killed (exit 137)** karena melewati timeout 60s (durasi ~59s). Lihat BUG-6.
- Boot smoke **15 scene**: tanpa SCRIPT ERROR / Parse Error; tidak ada node 0-px.
- Editor import (`--headless --editor --quit`): bersih (tanpa error/warning).
- **BUG-1 (P1 ChoiceMenu) & BUG-2 (P2 MainMenu QuitButton) SUDAH DIPERBAIKI di HEAD**
  dan terverifikasi (lihat §Verifikasi).
- **BUG-3 (`...`) BUKAN bug** — dikonfirmasi disengaja sebagai isyarat naskah
  (kartu `t_5728c5c3`, mikha: "TERVERIFIKASI DISENGAJA").
- **2 temuan BARU:**
  - **BUG-5 (P2, regresi a11y/UI):** 5 label slider di `settings_menu` tampil **KOSONG**
    (pemain tak tahu slider itu untuk apa). Akar: `_set_label()` menambahkan `_ROOT`
    dua kali. → kartu fix **lavis**.
  - **BUG-6 (P3, hygiene uji):** `test_flow_s00_s08` berjalan ~59s (di ambang timeout
    suite 60s) → flaky exit 137 walau lulus. → kartu fix **xeon**.

---

## BUG-5 (P2, KRITIS-untuk-pemain) — SettingsMenu: 5 label slider KOSONG

**Gejala pemain:** buka `Menu Utama → Pengaturan`. Di tiap tab, slider tidak punya
keterangan: baris hanya berisi slider tanpa teks ("Volume Musik", "Volume Efek Suara",
"Volume Ambience", "Kecepatan Teks", "Ukuran Huruf" semuanya hilang). Pemain tak tahu
slider apa yang sedang diatur.

**Bukti runtime** (`tests/_audit_xeon_confirm.tscn`, font 1x, locale `id`):
```
_ROOT                       = MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer
path lookup _set_label (ganda) = <_ROOT>/<_ROOT>/TabContainer/Audio/BgmRow/Label
get_node_or_null(ganda)     = <Object#null>   <-- NULL = no-op
path yang BENAR             = <_ROOT>/TabContainer/Audio/BgmRow/Label
get_node_or_null(benar)     = Label:<Label#39728449070>
-- hasil akhir text tiap label --
   .../TabContainer/Audio/BgmRow/Label         text=""  (harusnya "Volume Musik")
   .../TabContainer/Audio/SfxRow/Label         text=""  (harusnya "Volume Efek Suara")
   .../TabContainer/Audio/AmbRow/Label         text=""  (harusnya "Volume Ambience")
   .../TabContainer/Gameplay/TextSpeedRow/Label text="" (harusnya "Kecepatan Teks")
   .../TabContainer/A11y/FontSizeRow/Label     text=""  (harusnya "Ukuran Huruf")
```

**Akar masalah:** `scripts/ui/settings_menu.gd`
- Baris **88–92** memanggil `_set_label(_ROOT + "/TabContainer/.../Label", "...")`
  (argumen **sudah** mengandung `_ROOT`).
- Baris **103–106** `func _set_label(path, key)` menambahkan `_ROOT` **lagi**:
  `get_node_or_null(_ROOT + path)` → path menjadi `_ROOT + _ROOT + "..."` → `null`
  → `_set_label` menjadi **no-op** (tidak error, hanya diam).

**Mengapa regresi:** di `HEAD`, `scenes/ui/settings_menu.tscn` masih punya teks default
(`text = "Volume Musik"`, dst.). Working tree (perubahan UI terbaru) mengosongkan semua
`text = ""` (konvensi "jangan string literal di UI"), TAPI satu-satunya pengisi teks
runtime (`_set_label`) rusak karena path ganda → hasilnya label benar-benar kosong.

Bukti `git show HEAD:scenes/ui/settings_menu.tscn` (label terisi):
```
83:text = "Volume Musik"
99:text = "Volume Efek Suara"
115:text = "Volume Ambience"
137:text = "Kecepatan Teks"
```
Sekarang di `scenes/ui/settings_menu.tscn` baris 97, 113, 129, 151, 184: `text = ""`.

**Cakupan:** hanya `settings_menu.gd` (bukan pola umum — `help_menu.gd`,
`pause_menu.gd`, `content_warning.gd`, `main_menu.gd` memakai `_ROOT` dengan benar).

**Fix yang disarankan (lavis, ranah `.gd`):** di `_set_label`, jangan tambah `_ROOT`
lagi (argumen sudah lengkap), ATAU ubah pemanggil agar mengirim path relatif. Contoh:
```gdscript
func _set_label(path: String, key: String) -> void:
	var node: Label = get_node_or_null(path)   # path sudah absolut dari _ROOT
	if node:
		node.text = tr(key)
```

**Gate penerimaan:** instansiasi `settings_menu.tscn`, untuk tiap tab assert
`BgmRow/Label.text == tr("SETTINGS_BGM_VOL")` dst. (kelima label **tidak kosong**),
pada font 1x & 2x. Tambahkan ke suite (`test_ui_accessibility` / test baru).

---

## BUG-6 (P3, hygiene uji) — `test_flow_s00_s08` melewati timeout suite (flaky)

**Gejala:** `./run_tests.sh` melaporkan `FAIL test_flow_s00_s08 (exit=137)` meskipun
log-nya berakhir `=== SEMUA TEST ALUR S00->S08 LULUS ===`. exit 137 = SIGKILL oleh
`timeout -k 5 60`.

**Bukti** (`bash run_tests.sh`, `TEST_TIMEOUT=60`):
```
PASS  test_flag_store
...
PASS  test_chapter1_data
FAIL  test_flow_s00_s08 (exit=137)
      ...=== SEMUA TEST ALUR S00->S08 LULUS ===
PASS  test_ui_accessibility
...
HASIL: 16 lulus, 1 gagal (total 17)
GAGAL: test_flow_s00_s08
```
Dijalankan sendiri (`timeout -k 5 120`): **EXIT=0, ELAPSED=59s**. Jadi test lulus tapi
memakan ~59s — hanya ~1s di bawah batas 60s → **flaky** (kadang 137).

**Akar:** `tests/test_flow_s00_s08.gd` menjalankan seluruh alur S00→S08 (termasuk timer
tunggu S05) secara real-time; durasinya mendekati `TEST_TIMEOUT` default 60s di
`run_tests.sh` baris 37.

**Fix yang disarankan (xeon, ranah uji):** percepat timer pada mode uji (mis. set
`SettingsManager.text_speed` lebih tinggi + scale `create_timer`, atau `Engine.time_scale`),
atau naikkan `TEST_TIMEOUT` khusus test ini. Pastikan tetap < batas agar tidak flaky.

**Gate penerimaan:** `./run_tests.sh` konsisten **17/17 lulus** (exit 0) tanpa
`FAIL ... exit=137` pada beberapa kali jalan berturut-turut.

---

## Verifikasi BUG lama (status di HEAD, bukan temuan baru)

**BUG-1 (P1 ChoiceMenu) — SUDAH DIPERBAIKI** (kartu `t_d098adfe`, lavis, done).
Bukti `tests/_audit_xeon_verify.tscn`:
```
[choice_menu x1.0] panel=(320.0, 134.0) scroll_h=108 buttons=3 terpotong=0
[choice_menu x1.5] panel=(320.0, 140.0) scroll_h=114 buttons=3 terpotong=0
[choice_menu x2.0] panel=(320.0, 161.0) scroll_h=135 buttons=3 terpotong=0
[choice_menu x2.5] panel=(320.0, 185.0) scroll_h=159 buttons=3 terpotong=0
```
`scenes/ui/choice_menu.tscn`: `ButtonsScroll.custom_minimum_size = Vector2(0, 44)`.

**BUG-2 (P2 MainMenu QuitButton @2x) — SUDAH DIPERBAIKI di HEAD** (kartu `t_eb382931`,
haren, masih `running`). Bukti `tests/_audit_xeon_verify.tscn` (scroll ke bawah, cek
QuitButton masuk penuh dalam ScrollContainer):
```
[main_menu x1.0] QuitButton in_scroll=TERLIHAT
[main_menu x1.5] QuitButton in_scroll=TERLIHAT
[main_menu x2.0] QuitButton in_scroll=TERLIHAT
[main_menu x2.5] QuitButton in_scroll=TERLIHAT
```
`scenes/main_menu/main_menu.tscn` kini punya `MarginContainer/ScrollContainer` +
`follow_focus = true`; konten bisa digulir penuh pada 1x–2.5x.

**BUG-3 (P2 `...`) — BUKAN bug.** Kartu `t_5728c5c3` (mikha) menyimpulkan kelima kunci
disengaja sebagai jeda/hening ("diam"), dengan kutipan `docs/CHAPTER_01.md`. Tidak ada
teks diubah. (Satu opsi pilihan `S03_R1_OPT_C` memang menampilkan tombol `"..."` — itu
**naskah yang disetujui**, bukan placeholder.)

---

## Yang diperiksa & dinyatakan BERSIH (tidak ada bug)

- **Boot smoke 15 scene** (`tests/_audit_xeon_boot.tscn`): content_warning, main_menu,
  intro_cutscene, bedroom, corridor, lift, balcony, flashback, pause_menu, help_menu,
  settings_menu, choice_menu, chat_ui, thought_box, chat_bubble → **0 SCRIPT ERROR,
  0 node 0-px**.
- **Editor import** (`--headless --editor --quit`): tanpa error/warning.
- **Geometri/visibilitas semua menu** 1x/2x/2.5x (`tests/_audit_xeon_v3.tscn`):
  tak ada kontrol yang benar-benar tak-terjangkau. Teks tinggi pada
  `content_warning` (`DescScroll`) & `help_menu` (`ItemsScroll`) **bisa digulir sampai
  bawah** (vmax ≥ needed) pada semua skala (`tests/_audit_xeon_v4.tscn`).
- **Scene gameplay/HUD** pada 1x/2x/2.5x (`tests/_audit_xeon_v5.tscn`): intro, bedroom,
  corridor, lift, balcony, flashback, thought_box, chat_ui → bersih.
- **Sinyal menu utama** tersambung semua: StartButton/SettingsButton/HelpButton/
  QuitButton `pressed` → 1 koneksi masing-masing.
- **Teks kosong yang WAJAR** (bukan bug, diisi runtime):
  - `intro_cutscene/Caption` → diisi `_show_panel()` (`caption.text = tr(p["cap"])`).
  - `chat_bubble/SenderLabel` & `MessageLabel` → diisi `setup()`.
  - Label tombol menu → diisi `tr()` di `_ready()`.

---

## Catatan hygiene (bukan kartu)

- Proses Godot/bwrap sisa run lama sesekali tersisa (2 proses teramati). Tidak
  berbahaya; sebaiknya dibersihkan sebelum sesi uji berikutnya (BUG-4 di laporan zeal).

## Skrip probe (bukti pendukung)

- `tests/_audit_xeon_boot.gd` — boot smoke 15 scene + geometri/visibilitas + teks kosong + sinyal.
- `tests/_audit_xeon_v3.gd` — keterjangkauan menu 1x/2x/2.5x (logika benar: cari posisi
  scroll yang menampilkan penuh).
- `tests/_audit_xeon_v4.gd` — label settings per-tab + bisakah teks tinggi digulir penuh.
- `tests/_audit_xeon_v5.gd` — scene gameplay/HUD 1x/2x/2.5x (0-px & keluar viewport).
- `tests/_audit_xeon_confirm.gd` — konfirmasi BUG-5 (path ganda) & kunci `...`.
- `tests/_audit_xeon_verify.gd` — status BUG-1 & BUG-2 di HEAD.
