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
- [ ] 2.1 Kotak Pikiran (teks muncul pelan, bisa terhapus/diganti).
- [ ] 2.2 Gelembung Chat dengan indikator mengetik.
- [ ] 2.3 Menu pilihan (konvergen dan tertunda/ragu).
- [ ] 2.4 Layar content warning.
- [ ] 2.5 Menu utama, Pengaturan, **Menu Bantuan** (teks dari SAFETY_AND_CONTENT.md bagian 5).
**Selesai jika:** semua UI dapat dipanggil dari scene uji dan responsif pada resolusi pixel.

## FASE 3 — Scene Bab 1
- [ ] 3.1 `bedroom.tscn` dengan placeholder art, kamera tetap, gerak pemain.
- [ ] 3.2 6 objek interaktif (phone, photo, tea, mirror, clock, door) dengan flag sesuai CHAPTER_01.md.
- [ ] 3.3 `balcony.tscn` dengan siluet dan tombol [Lompat] tunggal.
- [ ] 3.4 Transisi: fade lambat, hitam total, vignette, kilas balik.
- [ ] 3.5 Konversi CHAPTER_01.md ke `data/chapters/chapter_01.json` + `data/localization/id.csv`.
**Selesai jika:** S01-S08 dapat dimainkan dengan placeholder.

## FASE 4 — Implementasi Bab 1 Penuh
- [ ] 4.1 Hubungkan monolog S03 (4 putaran) dengan pilihan konvergen.
- [ ] 4.2 Timer menunggu di S05 (15 detik dan 40 detik) + flag `waited_long`.
- [ ] 4.3 S06: siluet lalu hitam total 3 detik. **Verifikasi tidak ada tampilan jatuh.**
- [ ] 4.4 S06-ALT jika opsi lewati aktif.
- [ ] 4.5 S07 kilas balik 4 potongan.
- [ ] 4.6 S08: bangun lagi, perubahan lingkungan berdasarkan flag, pesan misterius dengan indikator mengetik, input teks bebas.
- [ ] 4.7 Loop counter "LOOP 2/7" dan transisi ke Bab 2.
**Selesai jika:** Bab 1 berjalan penuh dari S00 sampai S08 dan lolos checklist CHAPTER_01.md.

## FASE 5 — Audio dan Polish Bab 1
- [ ] 5.1 Pasang aset audio (lihat AUDIO_DESIGN.md bagian 7).
- [ ] 5.2 Atur timing audio sesuai peta bagian 6.
- [ ] 5.3 Pixel art final untuk kamar, balkon, bulan, siluet.
- [ ] 5.4 Penyetelan jeda dan tempo dengan uji manual.
- [ ] 5.5 Aksesibilitas: font besar, kontras tinggi, batas kedip.
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
