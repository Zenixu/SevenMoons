# CHAPTER_01 — LOOP 1: "HENING"

Durasi target: 15-20 menit. Pemain: Arutala. Jam dalam game: 02:47. Hujan gerimis.
Tujuan emosional: pemain merasakan kesendirian, beratnya pikiran yang berputar, dan hilangnya rasa punya pilihan. Diakhiri dengan hook penasaran.

> Catatan implementasi: format di bawah dirancang agar mudah dikonversi ke data (lihat GODOT_ARCHITECTURE.md bagian format).
> Keamanan: adegan S06 mengikuti SAFETY_AND_CONTENT.md. Tidak ada adegan jatuh. Opsi "Lewati adegan sensitif" mengganti S05-S06 dengan ringkasan (lihat S06-ALT).

Notasi:
- `[NARASI]` teks batin/narator tanpa kotak dialog karakter
- `[ARU]` ucapan/pikiran Arutala
- `[SFX]`, `[BGM]`, `[VFX]`, `[UI]` cue teknis
- `{flag}` set flag. `->` lompat ke scene.
- `(jeda Ns)` jeda dalam detik

---

## S00 — Layar Awal (sebelum game)
1. Content warning (SAFETY_AND_CONTENT.md bagian 4)
2. Layar judul: "ARUTALA". Menu: Mulai | Pengaturan | Bantuan | Keluar
3. Jika Mulai -> fade hitam 3 detik -> S01

---

## S01 — Bangun
**Latar:** Kamar apartemen, gelap. Cahaya biru kelabu dari jendela dan balkon. Suara gerimis.
**[BGM]** Tidak ada musik. Hanya ambience: hujan halus, dengung kulkas jauh, jam dinding.
**[VFX]** Layar mulai hitam, fade-in sangat lambat (4s). Piksel noise tipis.

[NARASI] ...
(jeda 2s)
[NARASI] Aku bangun.
(jeda 2s)
[NARASI] Atau mungkin tidak pernah benar-benar tidur.
**[UI]** Muncul jam kecil di pojok: `02:47`. (Flag tampilan jam: `ui_clock_visible`)
[ARU] Hujan lagi.
(jeda 1.5s)
[ARU] Selalu hujan kalau aku nggak ingin ada suara.
**[UI]** Kontrol gerak aktif. Pemain boleh menggerakkan Arutala di kamar.
-> S02

---

## S02 — Kamar (eksplorasi terbatas)
**Aturan:** Kamar kecil. Ada 6 objek interaktif. Pemain tidak wajib memeriksa semuanya, tapi minimal 3 sebelum balkon bisa dipilih. Tiap objek memberi satu potongan suasana dan menyetel flag untuk loop berikutnya.
**Pintu apartemen:** Terkunci secara naratif. Interaksi menghasilkan teks (lihat O6).

### O1 — Ponsel di meja
**Aksi:** Periksa
[NARASI] Layarnya menyala sendiri. Empat belas pesan belum dibuka.
[NARASI] Yang paling atas: **Kirana**. Terkirim tiga hari lalu.
**[UI]** Pratinjau pesan: `Kamu masih di sana? Aku cuma mau bilang`
(pratinjau terpotong, tidak bisa dibuka)
[ARU] ...
[ARU] Aku belum siap tahu lanjutannya.
**{checked_phone = true}**
**Pilihan:**
- A. "Buka pesannya" -> [NARASI] Jari Arutala berhenti di atas layar. (jeda 2s) Layar mati sendiri. **{tried_open_message = true}**
- B. "Letakkan lagi" -> [ARU] Nanti. Selalu nanti. **{avoided_message = true}**
*(Kedua pilihan berujung sama: pesan tidak terbuka. Pemain merasakan penghindaran.)*

### O2 — Foto yang dibalik
**Aksi:** Periksa
[NARASI] Sebuah bingkai kecil di meja, tertelungkup.
[NARASI] Debunya tipis. Tidak ada yang menyentuhnya akhir-akhir ini.
**Pilihan:**
- A. "Balikkan" -> **[UI]** Gambar buram: dua siluet, wajah tidak jelas. [ARU] Aku nggak bisa lihat lama-lama. -> bingkai kembali tertelungkup. **{turned_photo = true}**
- B. "Biarkan" -> [ARU] Lebih baik begitu. **{left_photo = true}**

### O3 — Gelas teh dingin
**Aksi:** Periksa
[NARASI] Teh yang dibuat entah kapan. Sudah tidak ada uapnya.
[ARU] Dulu ada yang bilang teh itu bisa bikin tenang.
[ARU] Dulu.
**{noticed_tea = true}**
*(Tidak ada pilihan. Gelas tidak bisa diminum.)*

### O4 — Cermin gelap
**Aksi:** Periksa
[NARASI] Pantulannya samar di kaca lemari. Wajahnya tampak lelah dan jauh.
[ARU] Kamu juga nggak tidur, ya.
(jeda 2s)
[NARASI] Pantulan itu tidak menjawab.
**{talked_to_mirror = true}**

### O5 — Jam dinding
**Aksi:** Periksa
[NARASI] Jarumnya tidak sama dengan jam di pojok layar.
[ARU] Mana yang benar?
[ARU] Nggak penting juga.
**{noticed_clock = true}**

### O6 — Pintu apartemen
**Aksi:** Periksa
[NARASI] Pintu itu ada di sana. Tidak dikunci.
[NARASI] Tapi tangan Arutala tidak mau terangkat.
[ARU] Di luar terlalu ramai. Walaupun sebenarnya kosong.
**Pilihan:**
- A. "Coba buka" -> [NARASI] Gagang pintu terasa dingin. Ia menariknya kembali. **{tried_door = true}**
- B. "Mundur" -> [ARU] Nggak malam ini.
*(Pintu tidak terbuka di Loop 1. Di Loop 2 pintu ini jadi pusat cerita.)*

**Kondisi lanjut:** setelah minimal 3 objek diperiksa, muncul teks petunjuk halus: `[NARASI] Ada udara dingin dari arah balkon.` dan pemain bisa bergerak ke balkon. -> S03

---

## S03 — Percakapan dengan Diri Sendiri (monolog interaktif)
**Pemicu:** Arutala duduk di tepi kasur/lantai sebelum ke balkon. Layar redup.
**[BGM]** Masuk tipis, hanya 4 nada piano jauh dari leitmotif (lihat AUDIO_DESIGN.md, "Tema Bulan - fragmen A"), sangat pelan, bergema.
**[UI]** Kotak dialog berbentuk "pikiran": teks muncul pelan, kadang terhapus dan diganti.

Format: ada **Suara Dalam** (pikiran yang menekan) dan **Aku** (Arutala). Pemain memilih balasan Arutala, tapi semua pilihan berujung ke arah yang sama.

### Putaran 1
[SUARA] Kamu tahu apa yang kamu lakukan ke dia.
**Pilihan (muncul lambat, 2s jeda):**
- A. "Aku tahu."
- B. "Jangan mulai lagi."
- C. "..." (diam)
-> semua: [SUARA] Dan kamu masih di sini, seolah nggak apa-apa.

### Putaran 2
[SUARA] Orang-orang bakal lebih baik tanpa kamu.
**Pilihan:**
- A. "Mungkin."
- B. "Bukan itu masalahnya."
- C. "Aku capek."
-> semua: [NARASI] Pilihan tadi terasa seperti pintu yang terbuka ke ruangan yang sama.
*(Catatan penulis: ini pikiran yang ditekan, bukan kebenaran. Jangan biarkan Suara menang tanpa celah; lihat putaran 3.)*

### Putaran 3 (celah kecil)
[SUARA] Nggak ada yang bakal peduli.
**Pilihan:**
- A. "..." -> [NARASI] Arutala menatap ponsel yang gelap di meja.
- B. "Kirana peduli dulu."
- C. "Aku nggak tahu."
-> semua: **[UI]** Nada pertama dari melodi muncul sedikit lebih jelas. Ponsel di meja bergetar halus sekali, lalu diam. **{heard_phone_buzz = true}**
[NARASI] Ada sesuatu yang belum selesai di sana. Tapi ia terlalu lelah untuk mengejarnya.

### Putaran 4 (penutup monolog)
[ARU] Kalau aku berhenti sekarang...
(jeda 3s)
[ARU] ...nggak akan ada lagi yang harus kuhadapi.
**[UI]** Teks "terhapus" huruf per huruf. Muncul teks pengganti:
[NARASI] Pikiran itu berat. Dan ia sudah membawanya terlalu lama.
**[BGM]** Fragmen A berhenti di tengah nada. Hening.
-> S04

---

## S04 — Menuju Balkon
**Latar:** Pintu geser balkon. Hujan terdengar jelas. Lantai dingin.
**[BGM]** Tidak ada.
**[VFX]** Warna layar makin pucat. Tepi layar menggelap (vignette).
[NARASI] Gerimis menempel di kaca.
[NARASI] Di atas, awan menutup hampir seluruh langit. Ada cahaya pucat di balik awan.
**{saw_moon_hidden = true}**
[ARU] Bulan.
(jeda 2s)
[ARU] Dulu aku suka lihat itu.
[ARU] Sekarang aku cuma ingin menghilang di bawahnya.
*(Catatan keamanan: baris di atas dipakai karena menggambarkan perasaan, bukan metode. Jangan ditambahi detail.)*
-> S05

---

## S05 — Satu Pilihan
**Latar:** Balkon. Siluet Arutala dari belakang. Pemandangan kota samar dari ketinggian.
**[UI]** Kotak pilihan muncul di tengah layar.
**Pilihan (hanya satu):**
- **[ Lompat ]**

**Aturan UI:** Tombol satu-satunya. Pemain bisa menunggu selama apa pun, tapi tidak ada opsi lain.
**[UI]** Jika pemain menunggu >15 detik: teks kecil muncul `[NARASI] Rasanya seperti pilihan lain sudah lama hilang.`
**[UI]** Jika pemain menunggu >40 detik: `[NARASI] Atau mungkin kamu cuma belum melihatnya.`
**{waited_long = true}** jika menunggu >40 detik.
*(Teks tambahan ini menanam benih bahwa "ada pilihan lain" dan membangun penasaran.)*
-> pemain menekan [Lompat] -> S06

---

## S06 — Lompat (sensitif)
**Aturan keras:** tidak ada tampilan jatuh, benturan, atau akibat fisik. Tidak ada detail cara.
**[BGM]** Fragmen A terputus.
**[VFX]** Siluet Arutala bergerak melewati batas sisi kanan layar, lalu layar langsung menjadi hitam total.
**[SFX]** Suara hujan terdengar sedetik, lalu seluruh suara dipotong.
(jeda 3s hitam total, tanpa suara)
**[SFX]** Satu denting jam tunggal, jauh.
(jeda 2s)
-> S07

### S06-ALT (jika "Lewati adegan sensitif" aktif)
**Gantikan S05-S06 dengan:**
[NARASI] Pikiran itu semakin berat. Layar meredup.
(fade ke hitam, 3 detik, hening)
[NARASI] Satu hari lagi yang tidak berakhir.
-> S07

---

## S07 — Kilas Balik (penguat rasa bersalah, bukan hukuman)
**Latar:** Layar hitam, lalu potongan adegan pendek muncul seperti kenangan yang berputar. Visual pixel hangat, sedikit pudar.
**[BGM]** Fragmen A kembali, tapi dibalik/mundur (reversed), lembut.
Potongan (masing-masing 3-4 detik, tanpa dialog panjang):
1. Siluet seseorang tertawa di tepi jendela (Kirana). Teks kecil: `[NARASI] Aku ingat dia pernah tertawa seperti itu.`
2. Pesan yang diketik lalu dihapus berulang-ulang. `[NARASI] Aku mengetik, lalu menghapus.`
3. Pintu yang tertutup keras. `[NARASI] Aku yang membuatnya pergi.`
4. Teh yang disodorkan, ditolak. `[NARASI] Ia hanya ingin aku berhenti sendirian.`
**{saw_flashback_1 = true}**
[ARU] (suara samar) Maaf.
[ARU] (lebih samar) Aku minta maaf.
**[VFX]** Kilas balik pecah menjadi piksel dan hilang. Hitam.
(jeda 3s)
-> S08

---

## S08 — Bangun Lagi (hook)
**Latar:** Kamar yang sama. Gelap. Hujan. Jam `02:47`.
**[BGM]** Hening. Hanya hujan.
**[UI]** Layar kembali seperti awal S01. Tapi:
- Gelas teh sekarang bergeser sedikit di meja (jika `noticed_tea = true`).
- Jika `turned_photo = true`, bingkai kini sedikit miring ke atas.
[NARASI] Aku bangun.
(jeda 2s)
[NARASI] Lagi.
(jeda 2s)
**[UI]** Ponsel di meja bergetar. Pemain bisa memeriksa.
**Periksa ponsel:**
[NARASI] Bukan dari Kirana. Nomor tak dikenal.
**[UI]** Pesan masuk dengan indikator mengetik (tiga titik, 3 detik):
`kamu yang di sana.`
(jeda 2s)
`iya. kamu. bukan dia.`
(jeda 3s)
`dia belum selesai. dan aku rasa kamu juga belum.`
**[UI]** Kotak balasan muncul untuk pemain (bukan Arutala). Placeholder: `ketik apa saja...` (pemain mengetik bebas atau pilih "Siapa kamu?" / "Aku nggak tahu harus apa").
- Jawaban apa pun -> balasan tetap: `nanti kamu tahu. sekarang, kita mulai dari yang kecil.`
**{received_mystery_message = true}**
**[UI]** Teks "LOOP 2/7" muncul kecil di pojok, lalu memudar.
**[BGM]** Satu nada dari leitmotif (nada pertama), bersih dan hangat, bukan lagi gema.
Fade out.
-> AKHIR BAB 1

---

## Ringkasan Flag Bab 1
| Flag | Dipakai di |
|---|---|
| checked_phone, tried_open_message, avoided_message | Loop 3, 5 (variasi dialog Kirana) |
| turned_photo, left_photo | Loop 4-5 (siapa di foto) |
| noticed_tea | Loop 7 (seseorang menyeduhkan teh) |
| talked_to_mirror | Loop 6 |
| tried_door | Loop 2 (pintu jadi pusat cerita) |
| heard_phone_buzz | Loop 2-3 |
| saw_moon_hidden | Loop 7 (purnama) |
| waited_long | Loop 2 (suara misterius menyinggung "kamu menunggu lama") |
| received_mystery_message | Seluruh game |

## Checklist Penerimaan Bab 1
- [ ] Content warning dan opsi lewati berfungsi
- [ ] S06 hanya siluet lalu hitam, tanpa adegan jatuh
- [ ] Semua flag tersimpan dan terbaca di Loop 2
- [ ] Jeda dan waktu sesuai naskah
- [ ] Hook S08 muncul dengan indikator mengetik
- [ ] Bab berdurasi 15-20 menit saat dimainkan normal
