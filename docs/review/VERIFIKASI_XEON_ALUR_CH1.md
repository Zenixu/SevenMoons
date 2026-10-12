# VERIFIKASI ALUR CH1 — kamar→lorong→lift→rooftop, gating ponsel, teks ambigu

Kartu: `t_9614dad6` (VERIFIKASI bug-hunter, assignee **xeon**).
Pendekatan: **bug-hunter** (reproduksi → bukti runtime → akar → verifikasi).
Runner: Godot `4.7.2.stable.fedora.ed1daf0bf`, `--headless`.
Workspace: `/home/aruthtale/Projects/seven-moons`.

> **Aturan kartu:** TIDAK memperbaiki fitur di sini — hanya memverifikasi, mencatat bukti,
> dan membuat kartu untuk temuan nyata. Naskah tidak diubah.

## Ringkasan hasil

| # | Yang diverifikasi | Hasil | Bukti |
|---|-------------------|-------|-------|
| 1 | Gating keluar kamar tanpa buka HP (pintu O6) | **LULUS** | §1 |
| 1 | Gating keluar kamar tanpa buka HP (jendela/balkon) | **LULUS** | §1 |
| 2 | Alur kamar→lorong→lift→rooftop (S03/S04a/S04/S05/S06 utuh) | **LULUS** | §2 |
| 2 | Tidak ada jalur "melompat ke akhir" | **LULUS** | §2 |
| 3 | Teks ambigu / kunci mati / inkonsistensi | **LULUS** (dengan catatan terbuka) | §3 |
| 4 | Boot smoke semua scene + editor import | **LULUS** (0 SCRIPT ERROR) | §4 |
| 5 | Suite resmi | **19/19 lulus, exit 0** | §5 |

**Temuan baru (1):** **S03 terulang** saat pemain kembali ke kamar lalu keluar lagi —
kartu fix `t_e95f2abf` (assignee lavis). Lihat §6.

---

## §1 Gating ponsel — bukti runtime alur NYATA

Probe `tests/_audit_flow_probe.gd` menggerakkan sinyal **asli** (`Interactable.interact()`
dan `Button.pressed`) sambil hidup sebagai anak `root` (selamat melewati
`change_scene_to_file`), lalu mencatat rantai scene yang benar-benar dilewati.

### 1a. `checked_phone=false` → pintu O6 harus MENAHAN (scene tetap kamar)
```
$ AUDIT_MODE=gate_off timeout 90 godot --headless --path "$PWD" res://tests/_audit_flow_probe.tscn
=== AUDIT FLOW PROBE (mode=gate_off) ===
SCENE[1] bedroom.tscn
  touch door (checked_phone=false)
  choice: scene=bedroom.tscn seq=1 n=2 -> press idx=0 (text=Coba buka)
  choice: scene=bedroom.tscn seq=2 n=2 -> press idx=0 (text=Keluar)
RESULT mode=gate_off reason=GATE_OFF_DONE chain=["res://scenes/bedroom/bedroom.tscn"]
FLAGS { "checked_phone": false, "tried_door": true }
```
→ Rantai scene **hanya kamar** (tidak pindah). Naskah O6 tetap dimainkan (`tried_door=true`).
**Gate bekerja.**

### 1b. `checked_phone=true` → pintu O6 boleh keluar (ke lorong)
```
$ AUDIT_MODE=gate_on timeout 90 godot --headless --path "$PWD" res://tests/_audit_flow_probe.tscn
SCENE[1] bedroom.tscn
  touch door (checked_phone=true)
  choice: ... seq=1 n=2 -> press idx=0 (text=Coba buka)
  choice: ... seq=2 n=2 -> press idx=0 (text=Keluar)
SCENE[2] corridor.tscn
RESULT mode=gate_on reason=GATE_ON_DONE chain=["bedroom.tscn", "corridor.tscn"]
FLAGS { "checked_phone": true, "tried_door": true, "visited_corridor": true }
```
**Gate bekerja** (pintu → lorong setelah ponsel diperiksa).

### 1c. `checked_phone=false` → jendela/balkon harus MENAHAN (S03 tidak jalan)
```
$ AUDIT_MODE=window_off timeout 60 godot --headless --path "$PWD" res://tests/_audit_flow_probe.tscn
SCENE[1] bedroom.tscn
  BEDROOM: enter balcony trigger
RESULT mode=window_off reason=WINDOW_OFF_BLOCKED chain=["res://scenes/bedroom/bedroom.tscn"]
FLAGS { "checked_phone": false, "noticed_tea": true, "talked_to_mirror": true,
        "noticed_clock": true, "clock_started": true }
```
→ Tetap di kamar; `heard_phone_buzz` (penanda S03) **tidak** terpasang. **Gate bekerja.**

Uji regresi resmi `tests/test_phone_gate.gd` (4 kasus: pintu/balkon × sebelum/sesudah):
```
=== TEST: GATE PONSEL SEBELUM KELUAR KAMAR ===
  - Kunci lokalisasi S02_EXIT_NEED_PHONE... Kunci lokalisasi: OK
  - Pintu O6 tanpa ponsel: harus tertahan... OK
  - Pintu O6 setelah ponsel: harus berfungsi... OK
  - Balkon tanpa ponsel: harus tertahan... OK
  - Balkon setelah ponsel: harus berfungsi... OK
=== SEMUA TEST GATE PONSEL LULUS ===   (exit 0)
```

---

## §2 Alur kamar→lorong→lift→rooftop — rantai scene NYATA (S00→S08)

```
$ AUDIT_MODE=full timeout 200 godot --headless --path "$PWD" res://tests/_audit_flow_probe.tscn
SCENE[1] content_warning.tscn
SCENE[2] main_menu.tscn
SCENE[3] intro_cutscene.tscn
SCENE[4] bedroom.tscn
  BEDROOM: touch phone
  choice: ... seq=1 n=2 -> idx=0 (text=Buka pesannya)     <- O1
  BEDROOM: touch door
  choice: ... seq=2 n=2 -> idx=0 (text=Coba buka)          <- O6
  choice: ... seq=3 n=2 -> idx=0 (text=Keluar)             <- konfirmasi O6
  choice: ... seq=4 n=1 -> idx=0 (text=Aku tahu.)          <- S03 R1
  choice: ... seq=5 n=3 -> idx=0 (text=Mungkin.)           <- S03 R2
  choice: ... seq=6 n=3 -> idx=0 (text=...)                <- S03 R3
SCENE[5] corridor.tscn
  CORRIDOR: touch elevator
SCENE[6] lift.tscn
  choice: ... seq=1 n=3 -> idx=2 (text=Lantai 5 — Atap)    <- pilih lantai 5
SCENE[7] balcony.tscn
  choice: ... seq=1 n=1 -> idx=0 (text=Lompat)             <- S05
SCENE[8] flashback.tscn
SCENE[9] bedroom.tscn                                       <- S08
RESULT mode=full reason=S08_REACHED
chain=["content_warning", "main_menu", "intro_cutscene", "bedroom",
       "corridor", "lift", "balcony", "flashback", "bedroom"]
FLAGS { "checked_phone": true, "tried_open_message": true, "tried_door": true,
        "heard_phone_buzz": true, "saw_moon_hidden": true,
        "received_mystery_message": true, "saw_flashback_1": true,
        "rooftop_from_lift": false, "rooftop_arrived": true,
        "corridor_floor": 5, "reached_floor5_balcony": true, "visited_corridor": true,
        "loop1_player_reply": "Siapa kamu?" }
```

**Kesimpulan:**
- Urutan **kamar → lorong → lift → rooftop** benar-benar dilewati (bukan langsung cutscene).
- **S03** dimainkan **sebelum** berangkat (R1/R2/R3 terlihat). S04a (`rooftop_from_lift` →
  `rooftop_arrived`), S04 (`saw_moon_hidden`), S05 ([Lompat]), S06 → flashback → S08 utuh.
- `corridor_floor=5`, `reached_floor5_balcony=true` diset `lift_controller`; `rooftop_from_lift`
  di-*consume* `balcony_controller._arrive_then_start()` → `rooftop_arrived=true` (memang begitu).
- **Tidak ada jalur kamar→balcony langsung.** `grep -rn "balcony.tscn" scripts/` hanya
  menemukan `lift_controller.gd:23` (ROOFTOP_SCENE) + komentar di `bedroom_controller.gd:455`.

Uji regresi resmi `tests/test_route_room_rooftop.gd` (menggerakkan alur nyata):
```
=== TEST: RUTE KAMAR -> LORONG -> LIFT -> ROOFTOP ===
SCENE[1] bedroom.tscn ... SCENE[2] corridor.tscn ... SCENE[3] lift.tscn ... SCENE[4] balcony.tscn
RUTE OK: chain=["bedroom.tscn", "corridor.tscn", "lift.tscn", "balcony.tscn"]
=== SEMUA TEST RUTE KAMAR->ROOFTOP LULUS ===   (exit 0)
```

---

## §3 Teks ambigu — kunci mati/usang & inkonsistensi

Alat: `python3 tests/scan_unused_keys.py` + `python3 tests/validate_data.py`.

```
== PEMINDAI KUNCI id.csv ==
Total kunci CSV   : 173
Kunci dirujuk     : 171
Tak direferensikan: 2
KUNCI MATI (tak dirujuk produksi MAUPUN uji) (1):
   S02_O5_A02               = Mungkin justru karena itu ia berhenti.
HANYA dirujuk uji (probe) — bukan produksi (1):
   S02_O1_A01               <- tests/_audit_xeon_confirm.gd
```

Verifikasi langsung terhadap kunci yang disebut kartu:

| Kunci | Status | Bukti |
|-------|--------|-------|
| `CLOCK_HINT` | **sudah diarsipkan** (usang) | tak ada di `id.csv`; di `docs/review/ARSIP_KUNCI_USANG.md` |
| `S02_O5_A02` | **kunci mati** (menunggu pemilik) | ada di `id.csv:74`; tak dirujuk kode (QUESTIONS **Q2**) |
| `ROOFTOP_ARRIVE`/`2`/`3` | **sudah diarsipkan** (usang) | digantikan `ROOFTOP_WALK_1..3` (`balcony_controller`) |
| `CORRIDOR_LIFT_UP/DOWN/STAY`/`STAY_RES` | **sudah diarsipkan** (usang) | desain lift lama → `LIFT_FLOOR_3/4/5` |
| `CORRIDOR_ARRIVE_LINE` | **sudah diarsipkan** (usang) | string format lama, tak ditampilkan |
| `CORRIDOR_F5_HINT` | **sudah diarsipkan** (usang) | desain lantai-5 lama (`FLOOR_MAX=4`) |
| `S01_N01..N03` | **menunggu pemilik** | masih dirujuk `chapter_01.json` blok S01 (QUESTIONS **Q1**) |
| `S02_EXIT_NEED_PHONE` | **aktif** | `id.csv:86` = "Ada yang belum kulihat di ponsel."; dipakai gate |

**Kesimpulan:** semua kunci usang yang bisa dibenahi **sudah** diarsipkan oleh kartu data
(`t_8087ad7d`, `f4f8531`). Yang tersisa = 2 kunci yang **menyangkut naskah** dan
**sengaja** menunggu keputusan pemilik (QUESTIONS Q1 & Q2) — bukan bug baru.
`validate_data.py`: **HASIL: OK** (format JSON valid, semua kunci terpakai tersedia).

---

## §4 Boot smoke + editor import

```
$ godot --headless --path "$PWD" res://tests/_audit_xeon_boot.tscn
=== AUDIT XEON: BOOT SMOKE ===
  boot content_warning.tscn children=3 zero_px=0
  boot main_menu.tscn children=5 zero_px=0
  boot intro_cutscene.tscn children=7 zero_px=0
  boot bedroom.tscn children=8 zero_px=0
  boot corridor.tscn children=6 zero_px=0
  boot lift.tscn children=5 zero_px=0
  boot balcony.tscn children=10 zero_px=0
  boot flashback.tscn children=4 zero_px=0
  boot pause_menu/help_menu/settings_menu/choice_menu/chat_ui/thought_box/chat_bubble -> zero_px=0
=== AUDIT XEON: SINYAL TAK TERSAMBUNG (menu utama) ===
  StartButton/SettingsButton/HelpButton/QuitButton .pressed connections = 1 masing-masing
```
`corridor` & `lift` ikut di-boot → **tanpa SCRIPT ERROR**. Editor import:
```
$ timeout 180 godot --headless --path "$PWD" --editor --quit 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|ERROR"
(kosong)   -> IMPORT_EXIT=0, bersih
```

> Catatan: probe boot lama juga melaporkan "TERPOTONG @2x/2.5x" pada
> `content_warning/DescScroll` & `help_menu/ItemsScroll`. Itu **bukan** teks hilang —
> keduanya `ScrollContainer` (bisa digulir penuh, lihat `AUDIT_XEON_CH1.md` §BERSIH), dan
> kartu a11y `t_236f5bdd` (haren) masih `running` untuk keterbacaan UI. Tidak dibuat kartu baru.

---

## §5 Suite resmi

```
$ ./run_tests.sh
PASS  test_flag_store ... PASS  test_phone_gate ... PASS  test_route_room_rooftop
-----------------------------------------
HASIL: 19 lulus, 0 gagal (total 19)   (exit 0)
```

---

## §6 TEMUAN BARU — S03 terulang saat kembali ke kamar

**Gejala.** Penjaga "S03 tepat sekali" (`_play_s03_once`, `var _s03_played: bool = false`,
`bedroom_controller.gd:48`) bersifat **per-instance**. Setiap perpindahan scene membuat
controller baru → penjaga reset. Rute: kamar → lorong (lantai 3) → **pintu kamar**
(`corridor_controller._handle_room_door`, `_floor == FLOOR_MIN`) → kamar lagi → keluar lagi
→ **S03 diputar ulang**.

**Bukti runtime** (`AUDIT_MODE=loop`, probe alur nyata):
```
SCENE[1] bedroom.tscn
  LOOP: bedroom#1 -> touch door (s03_play_count=0)
  choice: ... seq=3 n=1 -> idx=0 (text=Aku tahu.)   <- S03 R1
  choice: ... seq=4 n=3 -> idx=0 (text=Mungkin.)     <- S03 R2
  choice: ... seq=5 n=3 -> idx=0 (text=...)          <- S03 R3
SCENE[2] corridor.tscn
  LOOP: corridor#1 -> touch room_door (kembali ke kamar)
SCENE[3] bedroom.tscn
  LOOP: bedroom#2 -> touch door (s03_play_count=0)   <- instance baru: hitungan reset
  choice: ... seq=3 n=1 -> idx=0 (text=Aku tahu.)   <- S03 R1 MUNCUL LAGI
  choice: ... seq=4 n=3 -> idx=0 (text=Mungkin.)     <- S03 R2 LAGI
  choice: ... seq=5 n=3 -> idx=0 (text=...)          <- S03 R3 LAGI
SCENE[4] corridor.tscn
RESULT mode=loop reason=LOOP_DONE
```

**Akar.** `_s03_played` tidak dipersistensikan ke `FlagStore`; instance kamar baru = reset.
Melanggar gate kartu `t_033e8f70` ("S03 tetap diputar tepat sekali").

**Tindakan.** Dibuat kartu fix **`t_e95f2abf`** (assignee **lavis**, ranah systems/`.gd`),
induk `t_9614dad6`. *Tidak diperbaiki di kartu verifikasi ini.*

---

## Skrip probe (bukti pendukung)

- `tests/_audit_flow_probe.gd` / `.tscn` — driver alur **nyata** (read-only): hidup di luar
  `current_scene` sehingga selamat dari `change_scene_to_file`; menggerakkan
  `Interactable.interact()` + `Button.pressed` asli. Mode: `full`, `gate_off`, `gate_on`,
  `window`, `window_off`, `loop`. Hasil ditulis ke `tests/_audit_flow_result.txt`.
  Perintah: `AUDIT_MODE=<mode> timeout 90 godot --headless --path "$PWD" res://tests/_audit_flow_probe.tscn`.
- `tests/_audit_xeon_boot.gd` — boot smoke 15 scene + geometri + sinyal.
- `tests/test_phone_gate.gd` — regresi gating ponsel (resmi, ikut suite).
- `tests/test_route_room_rooftop.gd` — regresi rute kamar→rooftop (resmi, ikut suite).
