# AUDIO_DESIGN.md

## 1. Prinsip
- Musik adalah karakter, tumbuh bersama Arutala.
- **Keheningan adalah alat.** Banyak momen memang tanpa musik.
- Satu leitmotif ("Tema Bulan") dipakai di seluruh game, dari fragmen samar hingga utuh.

## 2. Leitmotif: Tema Bulan
Motif sederhana, mudah diingat, 4-7 nada, bisa diaransemen ulang. Pemilik proyek / komposer menentukan melodi final.
- **Fragmen A**: 4 nada pertama.
- **Fragmen B**: frasa lengkap tanpa resolusi.
- **Tema utuh**: frasa dengan resolusi harmoni.
Tonalitas awal: minor lembut, tempo lambat. Di akhir bergeser ke mayor hangat tanpa berlebihan.

## 3. Tujuh Aransemen (satu per loop)
| Loop | Aransemen | Instrumen | Suasana |
|---|---|---|---|
| 1 | Fragmen A | Piano jauh, bergema, dibalik di kilas balik | Hening, hampa |
| 2 | Fragmen A+B | Piano + pad tipis | Gelisah, berputar |
| 3 | Frasa dengan ritme ragu | Piano + detak lembut | Cemas sosial |
| 4 | Frasa hangat tapi retak | Gitar akustik/petikan | Rumah, rindu |
| 5 | Frasa penuh, nada tertahan | Strings tipis | Rasa bersalah, keberanian |
| 6 | Tema nyaris utuh | Piano + cello | Melepas |
| 7 | Tema utuh | Ansambel lembut, vokal tanpa lirik (opsional) | Damai, terhubung |

## 4. Musik Adaptif (Godot)
- Gunakan `AudioStreamInteractive` / `AudioStreamSynchronized` untuk layer.
- Layer: ambience hujan (selalu), pad, piano, perkusi lembut, strings.
- Contoh adaptif: di Loop 3, layer ritme muncul hanya saat pemain ragu memilih.
- Saat adegan tertekan, layer dikurangi sampai hening total.

## 5. Ambience dan SFX
- Hujan: intensitas turun tiap loop; hilang di Loop 7. Level awal **diredam**; ada level **quiet** (lebih pelan) saat mata tertutup (intro) dan di dalam lift.
- Hujan berlapis: `AMB_RAIN_DB` (normal, kamar) vs `AMB_RAIN_QUIET_DB` (-15 dB, intro/lift). `play_rain_quiet()` & `set_rain_level()`.
- Jam dinding: ada di Loop 1-2, memudar kemudian.
- Dengung kulkas, kipas, lift jauh sebagai lapisan kehidupan apartemen.
- Getar ponsel: SFX khas yang konsisten.
- Ketikan chat: SFX lembut, bukan mekanis keras.
- **Ketikan dialog** (`type_tick.wav`, 0.055s): bunyi tick halus yang diputar tiap beberapa karakter saat teks dialog/monolog/caption diketik.

## 6. Peta Audio Bab 1
| Scene | BGM | Ambience | Catatan |
|---|---|---|---|
| S01 (mata tertutup) | Tidak ada | **Hujan pelan (quiet)** saja | Monolog pembuka; kulkas/jam mati |
| S01 (buka mata) | Tidak ada | Hujan halus, kulkas, jam | Kamar |
| S02 | Tidak ada | Sama | Eksplorasi sunyi |
| S03 | Fragmen A, sangat pelan | Hujan | Monolog |
| S04a (rooftop) | Tidak ada | Hujan (tanpa kulkas/jam) | Jalan ke tengah atap lalu berhenti |
| S04 | Tidak ada | Hujan lebih jelas | Menuju balkon/tepi atap |
| S05 | Tidak ada | Hujan | Satu pilihan |
| S06 | Terputus | Dipotong total | Hitam total 3 detik |
| S07 | Fragmen A dibalik | Lembut | Kilas balik |
| S08 | Satu nada hangat | Hujan | Hook |

## 7. Daftar Aset Audio Bab 1 (untuk dibuat/dicari)
- [x] Ambience hujan halus (loop) — `rain_gentle_loop.wav`
- [x] Dengung kulkas jauh (loop) — `fridge_hum_loop.wav`
- [x] Jam dinding (loop) — `clock_tick_loop.wav`
- [x] Getar ponsel — `phone_vibrate.wav`
- [x] Denting jam tunggal — `clock_chime.wav`
- [x] Ketikan chat — `chat_type.wav`
- [x] **Ketikan dialog** — `type_tick.wav` (BARU)
- [x] Fragmen A (piano, normal dan versi dibalik)
- [x] Satu nada hangat penutup

*(Semua aset di atas dihasilkan oleh `scripts/generate_audio.py` — deterministik, jalankan dengan `/usr/bin/python3`.)*

## 8. Catatan untuk Komposer
Tulis musik bersama naskah. Baca STORY_BIBLE.md dan CHAPTER_01.md dulu. Pertimbangkan merilis soundtrack terpisah (Bandcamp/Spotify) sebagai sarana promosi.
