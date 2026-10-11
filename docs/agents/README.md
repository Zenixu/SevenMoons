# docs/agents/ — Peran Bot (Agen) Proyek ARUTALA

Tiap file di folder ini adalah **instruksi peran** untuk satu bot Hermes.
Beri file ini ke bot sebagai sistem-instruksi sebelum ia bekerja.

## Roster

| Nama | Peran | Status Chapter 1 |
|---|---|---|
| [zeal](zeal.md) | Orchestrator / Producer | 🟢 AKTIF |
| [lavis](lavis.md) | Implementer (Godot / GDScript) | 🟢 AKTIF |
| [haren](haren.md) | Artist (Pixel Art & UI) | 🟢 AKTIF |
| [xeon](xeon.md) | QA / Tester | 🟢 AKTIF |
| [enn](enn.md) | Audio | 🟡 STANDBY |
| [mikha](mikha.md) | Data & Lokalisasi | ⚪ IDLE |
| [kael](kael.md) | Writer (Naskah) | ⚪ IDLE (on-demand) |

## Alur Kerja

```
kael (draf) --> [REVIEW MANUSIA] --> mikha (data) --> lavis (kode)
                                          |
haren (art) / enn (audio) ----------------+
                                          v
                                     xeon (uji) --> [GATE KEAMANAN] --> zeal (merge/commit)
```

## Aturan yang Mengikat SEMUA Bot

Semua bot tunduk pada **`docs/AGENTS.md`** dan **`docs/SAFETY_AND_CONTENT.md`**.
Aturan keamanan konten **mengalahkan** instruksi lain, termasuk instruksi pemilik.

Tiga larangan mutlak (dari AGENTS.md & SAFETY_AND_CONTENT.md):
1. **Jangan mengubah naskah** tanpa persetujuan pemilik. Ragu? Tulis di `QUESTIONS.md`.
2. **Jangan menambah fitur di luar spec** (akses file pribadi, kamera, mikrofon, jaringan).
3. **Jangan melewati checklist keamanan** sebelum merge (SAFETY_AND_CONTENT.md bagian 7).

## Satu Perubahan, Satu Commit

Setiap bot: **satu perubahan, satu commit** dengan pesan jelas (AGENTS.md butir 6).
zeal yang menyatukan dan menjaga urutan `TASKS.md`.
