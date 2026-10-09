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
- Hujan: intensitas turun tiap loop; hilang di Loop 7.
- Jam dinding: ada di Loop 1-2, memudar kemudian.
- Dengung kulkas, kipas, lift jauh sebagai lapisan kehidupan apartemen.
- Getar ponsel: SFX khas yang konsisten.
- Ketikan chat: SFX lembut, bukan mekanis keras.

## 6. Peta Audio Bab 1
| Scene | BGM | Ambience | Catatan |
|---|---|---|---|
| S01 | Tidak ada | Hujan halus, kulkas, jam | Pembuka sepi |
| S02 | Tidak ada | Sama | Eksplorasi sunyi |
| S03 | Fragmen A, sangat pelan | Hujan | Monolog |
| S04 | Tidak ada | Hujan lebih jelas | Menuju balkon |
| S05 | Tidak ada | Hujan | Satu pilihan |
| S06 | Terputus | Dipotong total | Hitam total 3 detik |
| S07 | Fragmen A dibalik | Lembut | Kilas balik |
| S08 | Satu nada hangat | Hujan | Hook |

## 7. Daftar Aset Audio Bab 1 (untuk dibuat/dicari)
- [ ] Ambience hujan halus (loop)
- [ ] Dengung kulkas jauh (loop)
- [ ] Jam dinding (loop)
- [ ] Getar ponsel
- [ ] Denting jam tunggal
- [ ] Ketikan chat
- [ ] Fragmen A (piano, normal dan versi dibalik)
- [ ] Satu nada hangat penutup

## 8. Catatan untuk Komposer
Tulis musik bersama naskah. Baca STORY_BIBLE.md dan CHAPTER_01.md dulu. Pertimbangkan merilis soundtrack terpisah (Bandcamp/Spotify) sebagai sarana promosi.
