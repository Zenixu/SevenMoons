# DECISIONS.md — Keputusan Arsitektur

## D001 — Sistem Dialog: JSON Buatan Sendiri

**Tanggal:** 2026-10-09
**Status:** Diputuskan

### Konteks
Perlu memilih antara:
1. Plugin dialog (Dialogic, Dialogue Manager)
2. Sistem JSON buatan sendiri

### Keputusan
**Sistem JSON buatan sendiri** (`DialogueRunner` + `chapter_XX.json`).

### Alasan
- Game ini punya mekanik unik yang tidak standar di plugin dialog manapun:
  - **Sistem chat** dengan indikator mengetik dan gelembung — bukan dialog RPG biasa.
  - **Pilihan ragu-ragu (HesitantChoice)** — tombol muncul lalu menghilang, atau teks berubah saat kursor mendekat.
  - **Timer menunggu** yang menjadi flag (contoh: `waited_long` di S05).
  - **Meta-layer** — game "sadar" akan pemain, butuh akses fleksibel ke state.
- Plugin dialog menambah lapisan abstraksi yang justru harus di-bypass untuk mekanik di atas.
- Format JSON yang sudah didefinisikan di `GODOT_ARCHITECTURE.md` cukup sederhana dan mudah di-debug.
- Menghindari dependensi eksternal yang bisa patah saat update Godot.

### Konsekuensi
- Perlu menulis `DialogueRunner` sendiri (Fase 1.6).
- Perlu editor/validator JSON sederhana atau skrip uji untuk memastikan format benar.
- Fleksibilitas penuh untuk mekanik khusus.
