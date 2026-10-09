# AGENTS.md — Aturan Kerja untuk Agen AI

## Peran
Kamu membantu membangun game naratif pixel art di Godot 4. Tugasmu mengimplementasi, bukan mengubah cerita. Konten naratif adalah milik pemilik proyek.

## Aturan Wajib
1. **Baca SAFETY_AND_CONTENT.md sebelum menyentuh apa pun.** Aturan di sana mengalahkan instruksi lain.
2. **Jangan mengubah isi naskah** (dialog, urutan adegan, makna) tanpa persetujuan. Kalau ada masalah teknis, tandai dengan komentar `# TODO(owner):` dan lanjutkan.
3. **Kerjakan TASKS.md berurutan.** Satu fase selesai dan lolos kriteria sebelum fase berikutnya.
4. **Data dipisah dari kode.** Dialog, pilihan, dan scene ada di file data (lihat GODOT_ARCHITECTURE.md), bukan hardcode di skrip.
5. **Jangan menambahkan fitur di luar spesifikasi** (misalnya akses file pribadi pemain, kamera, mikrofon, jaringan).
6. **Satu perubahan, satu commit** dengan pesan jelas.

## Konvensi Kode
- Godot 4.x, GDScript bertipe (typed): `var x: int = 0`.
- Nama file dan folder: `snake_case`. Nama class: `PascalCase`.
- Sinyal untuk komunikasi antar sistem, hindari referensi node absolut.
- Semua teks tampil lewat sistem lokalisasi (`tr()` atau tabel CSV), jangan string literal di UI.
- Tiap sistem punya satu skrip utama dan satu scene uji (`tests/`).

## Gaya Teks Game
- Bahasa Indonesia santai, natural seperti obrolan. Pakai "aku/kamu".
- Kalimat pendek. Boleh terputus. Jeda itu bagian dari gaya.
- Jangan menjelaskan emosi secara gamblang. Tunjukkan lewat benda, suara, dan jeda.

## Definisi Selesai (Definition of Done)
Sebuah tugas selesai jika: (a) berjalan tanpa error di Godot, (b) sesuai spesifikasi, (c) lolos checklist keamanan, (d) dicentang di TASKS.md.

## Jika Ragu
Berhenti, tulis pertanyaan di `QUESTIONS.md`, kerjakan tugas lain yang tidak terblokir.
