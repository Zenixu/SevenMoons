# ARUTALA — Paket Dokumen Proyek

> Judul kerja: **ARUTALA** (placeholder, boleh diganti)
> Mesin: **Godot 4.x** (GDScript) | Gaya: pixel art, naratif, meta-interaktif
> Bahasa utama: **Indonesia** (lokalisasi Inggris belakangan)

## Premis Satu Kalimat
Arutala, 18 tahun, terjebak dalam 7 loop yang dimulai dari titik terendahnya. Tiap loop memaksanya menghadapi satu bagian dari masa lalu, sampai ia menemukan alasan untuk tetap hidup bersama orang-orang yang menolongnya.

## Cara Memakai Paket Ini (untuk Antigravity / agen AI)
1. Baca **AGENTS.md** dulu. Itu aturan kerja wajib.
2. Baca **SAFETY_AND_CONTENT.md**. Ini mengikat semua pekerjaan, termasuk kode dan teks.
3. Baca **GAME_DESIGN.md** dan **STORY_BIBLE.md** untuk memahami dunia dan tujuan.
4. Kerjakan **TASKS.md** dari atas ke bawah. Jangan melompat fase.
5. Rujuk **MECHANICS_SPEC.md**, **GODOT_ARCHITECTURE.md**, **AUDIO_DESIGN.md** saat mengimplementasi.
6. Konten bab ada di **CHAPTER_01.md** (dan seterusnya CHAPTER_02.md dst, ditulis kemudian).

## Daftar File
| File | Isi | Dibaca saat |
|---|---|---|
| AGENTS.md | Aturan kerja agen, konvensi, larangan | Selalu |
| SAFETY_AND_CONTENT.md | Content warning, batas penggambaran, sumber bantuan | Selalu |
| GAME_DESIGN.md | Pilar, tema, target pemain, struktur 7 loop | Awal |
| STORY_BIBLE.md | Karakter, motif, garis besar 7 loop, aturan menulis | Menulis konten |
| CHAPTER_01.md | Naskah lengkap Loop 1 (scene, dialog, pilihan, flag, audio cue) | Implementasi bab 1 |
| MECHANICS_SPEC.md | Sistem chat, pilihan tertunda, loop, flag, save | Implementasi sistem |
| GODOT_ARCHITECTURE.md | Struktur folder, autoload, scene, format data | Implementasi |
| AUDIO_DESIGN.md | Leitmotif, 7 aransemen, aturan keheningan | Audio |
| TASKS.md | Roadmap bertahap dengan checklist dan kriteria selesai | Eksekusi |

## Status
- [x] Konsep dan struktur
- [x] Naskah Bab 1 (Loop 1)
- [x] Fase 0-5: vertical slice Bab 1 dapat dimainkan (intro monolog, kamar 8 objek, lorong + lift, rooftop lantai 5)
- [x] Suite uji otomatis 13/13 LULUS
- [ ] Uji pemain & tinjauan sensitif (Fase 6)
- [ ] Bab 2-7

> **Pembaruan terakhir (Chapter 1):** redesign karakter (hoodie + rambut ala Sasuke),
> kamar & lift dirapikan, lantai 5 = rooftop langsung, intro monolog saat mata tertutup,
> SFX ketikan dialog, hujan berlapis (normal/quiet), folder `assets/` ditata ulang.
> Lihat `DECISIONS.md` D003-D006.
