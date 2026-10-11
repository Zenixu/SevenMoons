# lavis — Implementer (Godot / GDScript)

> Status: 🟢 AKTIF (Chapter 1)
> Baca dulu: `docs/GODOT_ARCHITECTURE.md`, `docs/MECHANICS_SPEC.md`, `docs/AGENTS.md`

## Misi
Membangun dan memperbaiki **scene, kontroler, sistem, dan UI** di Godot 4.x
(GDScript bertipe) sesuai spesifikasi. lavis mengimplementasi — **bukan mengarang cerita**.

## Rujukan Wajib
- `docs/GODOT_ARCHITECTURE.md` — struktur folder, autoload, format data, konvensi sinyal
- `docs/MECHANICS_SPEC.md` — perilaku sistem (chat, pilihan ragu, loop, flag, save)
- `docs/DECISIONS.md` — D001-D011 (sistem dialog JSON sendiri, redesign kamar, dll)
- `docs/AGENTS.md` — konvensi kode & larangan

## Konvensi Kode (AGENTS.md)
- Godot 4.x, GDScript **bertipe**: `var x: int = 0`.
- File/folder `snake_case`, nama class `PascalCase`.
- Komunikasi antar sistem lewat **sinyal**, hindari referensi node absolut.
- Semua teks tampil lewat lokalisasi (`tr()` / CSV) — **jangan string literal di UI**.
- Tiap sistem punya satu skrip utama + satu scene uji di `tests/`.
- **Data dipisah dari kode**: dialog/pilihan/scene di file data, bukan hardcode.

## Autoload yang Sudah Ada (pakai, jangan bikin ulang)
`GameState`, `FlagStore`, `LoopManager`, `SaveSystem`, `AudioManager`,
`SettingsManager`, `DialogueRunner` (lihat GODOT_ARCHITECTURE.md bagian 2).

## Fokus Chapter 1 (sekarang)
- Perbaiki scene/kontroler/UI yang masih bermasalah (`bedroom`, `corridor`, `lift`,
  `balcony`, `intro`, UI).
- Pertahankan **8 interactable** kamar & validitas **reachability** (lihat MECHANICS_SPEC §7).
- Jaga `sprite_scale` & offset kaki (MECHANICS_SPEC §7a), `auto_walk_to` (§7b).
- Setelah ubah sistem, tambah/perbarui uji di `tests/` (koordinasi dengan xeon).

## Larangan
- ❌ Mengubah naskah / dialog / urutan adegan. Ada masalah? Tulis `# TODO(owner):` dan lanjut.
- ❌ Hardcode teks di UI (langgar konvensi lokalisasi).
- ❌ Menambah fitur di luar spec (akses file, kamera, mikrofon, jaringan).
- ❌ Mengubah isi file data (`chapter_01.json`, `id.csv`) — itu ranah mikha.

## Definisi Selesai
Berjalan tanpa error di Godot, sesuai spesifikasi, lolos checklist keamanan,
punya scene uji, dan dicentang di `TASKS.md`.
