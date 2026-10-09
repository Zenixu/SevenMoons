# GAME_DESIGN.md

## 1. Visi
Game naratif pixel art yang terasa seperti obrolan nyata, di mana musik, visual, dan mekanik semuanya menyampaikan satu hal: **pemulihan itu mungkin, dan kamu tidak harus melakukannya sendirian.**

## 2. Target Pemain
Gen Z (utama), milenial muda, dan pemain naratif (penggemar OMORI, A Space for the Unbound, Undertale, OneShot). Pemain fasih dengan bahasa chat dan internet.

## 3. Pilar Desain
1. **Tema = Mekanik.** Kecemasan sosial dirasakan lewat cara memilih jawaban. Penghindaran dirasakan lewat pintu dan topik yang terkunci.
2. **Terasa seperti obrolan.** Dialog pendek, jeda, indikator mengetik, pesan yang dibatalkan.
3. **Penasaran yang ditepati.** Tiap loop menutup satu pertanyaan dan membuka satu pertanyaan baru.
4. **Musik adalah karakter.** Satu leitmotif tumbuh dari samar menjadi utuh.
5. **Menahan diri.** Momen terkuat adalah yang sunyi. Tidak ada drama berlebihan.
6. **Pemain dijaga.** Keamanan konten adalah bagian dari desain (lihat SAFETY_AND_CONTENT.md).

## 4. Struktur Besar: 7 Loop
| Loop | Judul kerja | Inti emosional | Mekanik penanda |
|---|---|---|---|
| 1 | Hening | Kesendirian, penghindaran | Pilihan konvergen, jeda panjang |
| 2 | Lari | Penyangkalan | Rute yang ternyata berputar |
| 3 | Terlalu Ramai | Kecemasan sosial | Pilihan balasan lambat dan ragu |
| 4 | Rumah | Kurang kasih sayang | Ruang/pintu keluarga yang terkunci |
| 5 | Yang Kusakiti | Rasa bersalah ke orang terluka | Permintaan maaf tanpa jaminan diterima |
| 6 | Aku yang Dulu | Memaafkan diri | Dialog dengan versi lama dirinya |
| 7 | Berkumpul | Terhubung dan bertahan | Pilihan "lompat" hilang |

Tiap loop berakhir dengan **satu perubahan kecil yang nyata** (satu pesan terkirim, satu pintu terbuka, satu permintaan maaf).

## 5. Loop Inti Permainan
```
Mulai loop (kamar, jam sama) -> Eksplorasi & percakapan -> Hadapi satu inti masalah
-> Perubahan kecil tercapai -> Adegan balkon (makin singkat) -> Loop berikutnya
```
Adegan balkon makin singkat tiap loop dan di loop 7 tidak ada lagi.

## 6. Elemen "Game Sadar Pemain"
Dipakai hemat dan selalu bermakna:
- Sosok/suara misterius yang sesekali berbicara kepada pemain, bukan kepada Arutala (muncul sebagai pesan dari nomor tak dikenal).
- Game mengingat pilihan pemain antar loop (flag), misalnya benda apa yang diperiksa.
- Pemain boleh mengetik satu nama/kata tertentu di momen tertentu (data dalam game saja).
- Dilarang: membaca file, nama akun sistem, kamera, mikrofon.

## 7. Motif Visual dan Naratif
- **Bulan**: tertutup awan di awal, makin jelas tiap loop, purnama di akhir (arti nama Arutala dan cita-cita tinggi).
- **Hujan**: gerimis konstan di awal, reda di akhir.
- **Jam 02:47**: waktu yang selalu sama saat loop mulai.
- **Lampu**: mati di loop 1, makin terang tiap loop.
- **Tombol "Lompat"**: satu-satunya pilihan di loop 1, makin jarang, hilang di loop 7.
- **Kulkas & wastafel**: penanda "hidup sehari-hari" yang tersisa di kamar; diperiksa untuk
  merasakan rutinitas yang kini terasa berat (objek interaktif baru, lihat CHAPTER_01.md O7/O8).

## 8. Cakupan Rilis Pertama
- Target durasi: 3-5 jam.
- Vertical slice: Bab 1 lengkap (±20 menit).
- Platform: PC (Steam/itch.io) dulu. Demo untuk Steam Next Fest.

## 9. Pertanyaan Terbuka (isi pemilik proyek)
- Nama dan hubungan orang yang disakiti (placeholder: **Kirana**).
- Identitas sosok misterius (placeholder: **"Bulan"**, suara yang menyapa pemain).
- Cita-cita besar Arutala sebelum terkubur.
