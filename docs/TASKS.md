# TASKS.md — Roadmap Eksekusi

Kerjakan berurutan. Centang `[x]` saat selesai dan lolos kriteria. Rujuk AGENTS.md, SAFETY_AND_CONTENT.md.

## FASE 0 — Setup Proyek
- [x] 0.1 Buat proyek Godot 4.x, atur resolusi dasar pixel-perfect (mis. 640x360, scaling integer, filter nearest).
- [x] 0.2 Buat struktur folder sesuai GODOT_ARCHITECTURE.md.
- [x] 0.3 Salin file md ke `docs/`.
- [x] 0.4 Inisialisasi git, `.gitignore` Godot.
- [x] 0.5 Putuskan: sistem dialog JSON sendiri (rekomendasi) vs plugin. Tulis di `docs/DECISIONS.md`.
**Selesai jika:** proyek terbuka tanpa error dan menjalankan scene kosong.

## FASE 1 — Fondasi Sistem (autoload)
- [x] 1.1 `FlagStore` + uji.
- [x] 1.2 `SettingsManager` (kecepatan teks, volume, lewati adegan sensitif, tanpa tekanan waktu).
- [x] 1.3 `SaveSystem` (JSON di `user://saves/`).
- [x] 1.4 `AudioManager` (BGM, SFX, ambience terpisah, fade).
- [x] 1.5 `LoopManager` (current_loop, loop_changes.json).
- [x] 1.6 `DialogueRunner` membaca `chapter_XX.json` dan menjalankan step.
**Selesai jika:** tiap autoload punya scene uji yang lulus.

## FASE 2 — UI Inti
- [x] 2.1 Kotak Pikiran (teks muncul pelan, bisa terhapus/diganti).
- [x] 2.2 Gelembung Chat dengan indikator mengetik.
- [x] 2.3 Menu pilihan (konvergen dan tertunda/ragu).
- [x] 2.4 Layar content warning.
- [x] 2.5 Menu utama, Pengaturan, **Menu Bantuan** (teks dari SAFETY_AND_CONTENT.md bagian 5).
**Selesai jika:** semua UI dapat dipanggil dari scene uji dan responsif pada resolusi pixel.

## FASE 3 — Scene Bab 1
- [x] 3.1 `bedroom.tscn` dengan placeholder art, kamera tetap, gerak pemain.
- [x] 3.2 6 objek interaktif (phone, photo, tea, mirror, clock, door) dengan flag sesuai CHAPTER_01.md.
- [x] 3.3 `balcony.tscn` dengan siluet dan tombol [Lompat] tunggal.
- [x] 3.4 Transisi: fade lambat, hitam total, vignette, kilas balik.
- [x] 3.5 Konversi CHAPTER_01.md ke `data/chapters/chapter_01.json` + `data/localization/id.csv`.
**Selesai jika:** S01-S08 dapat dimainkan dengan placeholder.

## FASE 4 — Implementasi Bab 1 Penuh
- [x] 4.1 Hubungkan monolog S03 (4 putaran) dengan pilihan konvergen.
- [x] 4.2 Timer menunggu di S05 (15 detik dan 40 detik) + flag `waited_long`.
- [x] 4.3 S06: siluet lalu hitam total 3 detik. **Verifikasi tidak ada tampilan jatuh.**
- [x] 4.4 S06-ALT jika opsi lewati aktif.
- [x] 4.5 S07 kilas balik 4 potongan.
- [x] 4.6 S08: bangun lagi, perubahan lingkungan berdasarkan flag, pesan misterius dengan indikator mengetik, input teks bebas.
- [x] 4.7 Loop counter "LOOP 2/7" dan transisi ke Bab 2.
**Selesai jika:** Bab 1 berjalan penuh dari S00 sampai S08 dan lolos checklist CHAPTER_01.md.

## FASE 5 — Audio dan Polish Bab 1
- [ ] 5.1 Pasang aset audio (lihat AUDIO_DESIGN.md bagian 7).
- [ ] 5.2 Atur timing audio sesuai peta bagian 6.
- [x] 5.3 Pixel art final untuk kamar, balkon, bulan, siluet, karakter (spritesheet 4 arah), dan lorong apartemen.
- [x] 5.4 Penyetelan jeda dan tempo dengan uji manual (temuan pemain: tembok/furnitur bocor + pintu salah tempat — diperbaiki).
- [x] 5.5 Aksesibilitas: font besar, kontras tinggi, batas kedip.
- [x] 5.6 Lorong apartemen + lift antar lantai (3→4→5) dengan dialog per lantai, pintu tetangga terkunci, tangga buntu.
**Selesai jika:** vertical slice layak dijadikan trailer/demo.

## FASE 6 — Uji dan Tinjauan
- [ ] 6.1 Uji dengan 5-10 pemain, kumpulkan masukan (terutama adegan sensitif).
- [ ] 6.2 **Tinjauan naskah oleh psikolog/konselor/penyintas.** Wajib sebelum rilis demo.
- [ ] 6.3 Revisi berdasarkan masukan.
- [ ] 6.4 Verifikasi nomor dan layanan di Menu Bantuan masih berlaku.

## FASE 7 — Bab 2-7
Ulangi pola Fase 3-5 untuk tiap bab. Buat `CHAPTER_02.md` dst. dengan format yang sama dengan CHAPTER_01.md sebelum implementasi.
- [ ] Bab 2 (Lari)
- [ ] Bab 3 (Terlalu Ramai) — implementasi penuh HesitantChoice
- [ ] Bab 4 (Rumah)
- [ ] Bab 5 (Yang Kusakiti)
- [ ] Bab 6 (Aku yang Dulu)
- [ ] Bab 7 (Berkumpul) — pilihan "lompat" hilang, ending

## FASE 8 — Rilis
- [ ] Demo untuk Steam Next Fest / itch.io
- [ ] Trailer dari vertical slice
- [ ] Rilis soundtrack terpisah
- [ ] Halaman toko dengan content warning jelas
