# GODOT_ARCHITECTURE.md

Godot 4.x, GDScript bertipe. Prinsip: **data terpisah dari kode**, sistem saling bicara lewat sinyal.

## 1. Struktur Folder
```
res://
├── project.godot
├── assets/
│   ├── art/            (sprite, tileset, UI)
│   ├── audio/
│   │   ├── bgm/
│   │   ├── sfx/
│   │   └── ambience/
│   └── fonts/
├── data/
│   ├── chapters/       (chapter_01.json, ...)
│   ├── loop_changes.json
│   └── localization/   (id.csv, en.csv)
├── scenes/
│   ├── main_menu/
│   ├── bedroom/
│   ├── balcony/
│   ├── ui/             (dialogue_box, chat_bubble, choice_menu, settings, help)
│   └── transitions/
├── scripts/
│   ├── autoload/       (GameState, LoopManager, FlagStore, SaveSystem, AudioManager, SettingsManager)
│   ├── systems/        (ChatSystem, HesitantChoice, Interactable, MetaLayer)
│   └── ui/
├── tests/
└── docs/               (file md proyek ini)
```

## 2. Autoload (Singleton)
| Nama | Tugas |
|---|---|
| `GameState` | Status global: bab/loop aktif, scene aktif |
| `FlagStore` | Dictionary flag + API |
| `LoopManager` | Alur loop, penerapan perubahan lingkungan |
| `SaveSystem` | Simpan/muat JSON |
| `AudioManager` | BGM, SFX, ambience, leitmotif adaptif |
| `SettingsManager` | Pengaturan pemain, termasuk lewati adegan sensitif |
| `DialogueRunner` | Membaca data bab dan menjalankan scene/dialog |

## 3. Format Data Bab (JSON)
Konversikan CHAPTER_01.md ke `data/chapters/chapter_01.json`.

```json
{
  "chapter": 1,
  "loop": 1,
  "scenes": {
    "S01": {
      "setting": "bedroom_dark",
      "bgm": null,
      "ambience": "rain_light",
      "steps": [
        { "type": "narration", "text": "S01_N01", "pause_after": 2.0 },
        { "type": "ui", "action": "show_clock", "value": "02:47" },
        { "type": "next_scene", "target": "S02" }
      ]
    },
    "S02": {
      "interactables": ["phone","photo","tea","mirror","clock","door"],
      "min_inspected": 3,
      "next": "S03"
    }
  }
}
```
**Tipe step yang didukung:** `narration`, `line` (speaker+text), `pause`, `choice`, `set_flag`, `ui`, `sfx`, `bgm`, `vfx`, `next_scene`, `chat_message`, `text_input`.

**Pilihan:**
```json
{ "type": "choice", "mode": "convergent",
  "options": [
    { "text": "S03_P1_A", "set_flag": null },
    { "text": "S03_P1_B", "set_flag": null }
  ],
  "next": "S03_P2" }
```

## 4. Lokalisasi
- Semua teks lewat kunci (`S01_N01`) di `data/localization/id.csv`.
- Kolom: `key,id,en`. Awalnya hanya `id`.

## 5. Scene Utama
- `main_menu.tscn`: Mulai, Pengaturan, Bantuan, Keluar.
- `content_warning.tscn`: tampil sebelum game.
- `bedroom.tscn`: kamar, 6 interactable, kamera tetap.
- `balcony.tscn`: balkon, siluet, tombol pilihan.
- `ui/dialogue_box.tscn`, `ui/chat_ui.tscn`, `ui/choice_menu.tscn`, `ui/help_screen.tscn`.

## 6. Konvensi Sinyal
- `DialogueRunner.step_started(step)`, `step_finished`.
- `FlagStore.flag_changed(name, value)`.
- `LoopManager.loop_started(n)`, `loop_ended(n)`.
- `AudioManager.leitmotif_stage_changed(stage)`.

## 7. Aset Placeholder
Sebelum art final, gunakan kotak warna dan font sistem agar sistem dapat diuji. Tandai `placeholder_` pada nama file.

## 8. Plugin (opsional, putuskan di fase 0)
- *Dialogue Manager* atau *Dialogic* untuk dialog bercabang, **atau** sistem JSON buatan sendiri (rekomendasi: JSON sendiri karena mekanik chat/ragu khusus).
- Pertimbangkan *Godot Resonate/ SoundManager* untuk audio adaptif, atau pakai `AudioStreamInteractive` / `AudioStreamSynchronized` bawaan Godot 4.3+.

## 9. Build dan Uji
- Uji tiap sistem di scene terpisah (`tests/`).
- Skrip uji alur: jalankan bab 1 dari S00 sampai S08 dengan input otomatis.
- Ekspor: Windows, Linux dulu.
