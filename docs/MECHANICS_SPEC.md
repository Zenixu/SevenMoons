# MECHANICS_SPEC.md

Spesifikasi sistem. Tiap sistem punya tujuan emosional, perilaku, dan kriteria penerimaan.

## 1. Sistem Dialog Gaya Obrolan (ChatSystem)
**Tujuan:** cerita terasa seperti percakapan nyata.
**Perilaku:**
- Pesan muncul satu per satu dengan indikator mengetik (tiga titik) berdurasi proporsional panjang pesan (0.04 detik per karakter, min 0.8s, maks 3s).
- Jeda eksplisit dengan tag `(jeda Ns)`.
- Dukung "pesan dibatalkan": teks muncul lalu dihapus huruf per huruf (efek kecemasan).
- Dukung dua gaya: **Kotak Pikiran** (batin) dan **Gelembung Chat** (ponsel).
**Penerimaan:** durasi mengetik dan jeda dapat diatur di Pengaturan (kecepatan teks).

## 2. Pilihan Tertunda dan Ragu (HesitantChoice)
**Tujuan:** merasakan kecemasan sosial saat memilih kata.
**Perilaku:**
- Pilihan muncul bertahap, bukan sekaligus (jeda 0.5-2s per opsi).
- Pilihan "aman" muncul lebih dulu dan lebih jelas. Pilihan jujur muncul lebih lambat dan lebih redup.
- Opsional: batas waktu (tidak di Bab 1). Jika waktu habis, pilihan "diam" terpilih.
- Tersedia mode "Tanpa tekanan waktu" di Pengaturan (aksesibilitas).
**Penerimaan:** pilihan bisa dikonfigurasi dari data, bukan hardcode.

## 3. Pilihan Konvergen (ConvergentChoice)
**Tujuan (Loop 1):** rasa tidak punya pilihan.
**Perilaku:** beberapa opsi tampil, semuanya mengarah ke scene yang sama. Tiap opsi tetap bisa mengeset flag kecil yang berbeda.

## 4. Sistem Loop (LoopManager)
**Tujuan:** menjaga kontinuitas antar 7 loop.
**Perilaku:**
- `current_loop: int` (1-7).
- Saat loop berakhir: simpan flag, reset scene dasar, terapkan **perubahan lingkungan** berdasarkan loop dan flag (lampu lebih terang, bulan lebih jelas, benda bergeser).
- Tabel perubahan lingkungan per loop dibaca dari data (`data/loop_changes.json`).
- Adegan balkon makin singkat: durasi dari data (`balcony_scene_length`), di loop 7 diganti `balcony_choice_removed = true`.

## 5. Flag dan Memori Pilihan (FlagStore)
- Dictionary `flags: Dictionary[String, Variant]`.
- API: `set_flag(name, value)`, `get_flag(name, default)`, `has_flag(name)`.
- Flag disimpan dalam save dan dapat dipakai kondisi dialog (`if flag == true`).

## 6. Elemen "Game Sadar Pemain" (MetaLayer)
**Batas tegas:**
- Hanya memakai data dalam game: pilihan, durasi bermain di sesi, input teks yang pemain ketik di dalam game.
- DILARANG: baca nama akun OS, file sistem, kamera, mikrofon, jaringan, jam sistem yang dipakai untuk mengancam atau menekan pemain.
- Pemain boleh menutup game kapan saja tanpa pesan menyalahkan.
**Fitur (bertahap):**
- Pesan dari nomor tak dikenal yang berbicara ke pemain.
- Kotak input teks bebas dengan balasan tetap (Bab 1: S08).
- Penyimpanan jawaban pemain untuk dirujuk balik secara halus di loop berikutnya.

## 7. Sistem Interaksi Objek (Interactable)
- Objek punya: `id`, `prompt_text`, `on_interact` (dialog/pilihan), `flag_on_inspect`.
- Interaksi dengan tombol "Aksi" (default `E`). Efek highlight halus (bukan menyilaukan).
- Kamar Bab 1 punya **8 objek**: phone, photo, tea, mirror, clock, door, **fridge**, **sink**.
- Area interaksi diperbesar & digeser ke zona jalan agar interaksi muncul saat pemain
  benar-benar dekat (bukan terlalu jauh).

## 7b. Gerak Terarah (Scripted Walk)
- `PlayerCharacter.auto_walk_to(target, speed)` — berjalan otomatis ke titik tujuan,
  memainkan animasi jalan lalu berhenti. Dipakai di adegan terarah, mis. saat tiba di
  rooftop: Arutala berjalan ke tengah atap lalu berhenti sebelum dialog dimulai.

## 8. Sistem Save/Load
- Slot otomatis di awal tiap scene dan akhir tiap loop.
- Simpan: `current_loop`, `current_scene_id`, `flags`, pengaturan sensitif.
- Format JSON di `user://saves/`.
- Pemain bisa keluar kapan saja dan melanjutkan tanpa kehilangan banyak progres.

## 9. Pengaturan Wajib
- Kecepatan teks, ukuran font, kontras tinggi.
- Volume: musik, SFX, ambience terpisah.
- Opsi **Lewati adegan sensitif**.
- Mode tanpa tekanan waktu.
- Kurangi kilatan/efek glitch (aksesibilitas).

## 10. Aksesibilitas
- Semua teks dapat dibesarkan.
- Tidak mengandalkan warna saja untuk informasi.
- Efek kedip dibatasi (<3 kali per detik).
