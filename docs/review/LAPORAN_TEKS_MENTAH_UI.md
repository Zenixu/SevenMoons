# Laporan Teks Mentah UI — Chapter 1 (untuk lavis)

Dibuat oleh: **mikha** (kartu `t_0580c8ee`, Data & lokalisasi Chapter 1)
Metode: `tests/_scan_raw_text.py` (pindai nilai default `text`/`placeholder_text`
di `scenes/**.tscn` + string literal di `scripts/**.gd`).

## Ringkasan
**Tidak ada teks mentah yang benar-benar tampil ke pemain.** Semua nilai default
di `.tscn` di bawah ini **ditimpa lewat `tr()`** saat `_ready()`/`setup()` sebelum
node terlihat. Jadi ini bukan bug pemain, melainkan **sisa default editor** yang
melanggar konvensi "jangan string literal di UI" (`docs/agents/lavis.md`).

## Daftar default `.tscn` yang ditimpa runtime (aman, tapi sebaiknya dikosongkan)

| File | Baris | Nilai default | Ditimpa oleh |
|---|---|---|---|
| `scenes/main_menu/main_menu.tscn` | 55,62,78,84,90,96 | ARUTALA / Tujuh Malam… / Mulai / Pengaturan / Bantuan / Keluar | `main_menu.gd` → `tr("MAIN_TITLE")`, `UI_START`, … |
| `scenes/ui/settings_menu.tscn` | 77–220 | Pengaturan / Volume… / … / Tutup | `settings_menu.gd` → `tr("SETTINGS_*")`, `UI_CLOSE` |
| `scenes/ui/help_menu.tscn` | 72–129 | Sumber Bantuan / … / Tutup | `help_menu.gd` → `tr("HELP_*")`, `UI_CLOSE` |
| `scenes/ui/content_warning.tscn` | 73–112 | Peringatan Konten / … | `content_warning.gd` → `tr("CW_*")` |
| `scenes/ui/choice_menu.tscn` | 55 | "Pilih respon:" | `choice_menu.gd` → `tr(prompt_text)` |
| `scenes/ui/chat_bubble.tscn` | 47,54 | Pengirim / Isi pesan… | `chat_bubble.gd` → `setup()` (sender/message) |
| `scenes/transitions/flashback.tscn` | 65,87 | "Aku ingat dia…" / "Maaf." | `flashback.gd` → `tr(slide["text"])`, `tr("S07_A01")` |
| `scenes/corridor/corridor.tscn` | 131 | "Lantai 3" | `corridor_controller.gd` → `tr("CORRIDOR_FLOOR")` |
| `scenes/lift/lift.tscn` | 88 | "Lantai 3" | `lift_controller.gd` → `tr("CORRIDOR_FLOOR")` |
| `scenes/bedroom/bedroom.tscn` | 246 | "01:00" | `bedroom_controller.gd` → `_update_clock_label()` |
| `scenes/bedroom/bedroom.tscn` | 275 | "LOOP 2/7" | `bedroom_controller.gd` → `tr("S08_LOOP_LABEL")` |
| `scenes/balcony/balcony.tscn` | 115 | "Petunjuk tunggu…" | `balcony_controller.gd` → `tr("S05_WAIT_15/40")` |

### Saran tindakan (lavis, ranah `.gd`/`.tscn`)
Kosongkan nilai `text = ""` pada node-node di atas agar `.tscn` bebas literal,
karena semuanya sudah diisi via `tr()` saat runtime. Tidak ada perubahan perilaku.

## Catatan positif (bukan temuan)
- `scenes/ui/chat_ui.tscn` sudah bersih (`text = ""`, `placeholder_text = ""`),
  diisi `chat_system.gd` lewat `tr("UI_CHAT_*")`.
- Semua kunci yang dipakai skrip/scene **sudah ada di `id.csv`** (diverifikasi
  `tests/validate_data.py`).
