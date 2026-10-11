# REVIEW_6.2 — Instrumen Tinjauan Naskah oleh Psikolog / Konselor / Penyintas (FASE 6.2)

> **STATUS: INSTRUMEN SIAP KIRIM — FASE 6.2 BELUM DIJALANKAN.**
> Fase 6.2 (tinjauan naskah oleh orang berpengalaman) **WAJIB MANUSIA**. Bot hanya
> menyiapkan instrumen, pertanyaan, dan prosedur ini; bot **tidak boleh** menjalankan
> tinjauan, **tidak boleh** mengarang/menggantikan pendapat ahli, dan **tidak boleh**
> menandai Fase 6.2 selesai. Fase 6.2 baru sah bila **reviewer manusia nyata** telah
> meninjau naskah dan lembar ini terisi.
>
> Rujukan: `docs/TASKS.md` Fase 6 · `docs/SAFETY_AND_CONTENT.md` §1, §2, §3, §6, §7 ·
> `docs/CHAPTER_01.md` · `docs/GAME_DESIGN.md` §1 & §3 · `docs/STORY_BIBLE.md` ·
> `docs/playtest/PLAYTEST_6.1.md` (masukan pemain, bila sudah ada).
> Dokumen ini **tidak mengubah naskah** apa pun dan **tidak menyentuh** `docs/CHAPTER_01.md`,
> `data/chapters/chapter_01.json`, maupun `data/localization/id.csv`.

---

## 0. Ringkasan, Peran, dan Aturan

**Tujuan tinjauan:** mendapatkan penilaian **ahli/kredibel** (bukan pemain umum) atas
keamanan & ketepatan penggambaran tema kesehatan mental di Bab 1 "Hening" — khususnya
depresi, rasa bersalah, kecemasan, dan **pikiran untuk mengakhiri hidup** — serta
**rekomendasi konkret** untuk revisi. Ini masukan untuk **Fase 6.3 (revisi)**, bukan
keputusan otomatis.

**Peran (semua manusia):**
- **Reviewer** — psikolog klinis, konselor/konselor sebaya terlatih, **atau** penyintas
  (idealnya lebih dari satu orang dari kategori berbeda; lihat §3.1). Menilai naskah
  dan mengisi §2.
- **Koordinator (pemilik proyek / orang yang ditunjuk)** — mengirim paket naskah (§3.2),
  menjadwalkan, menjaga kerahasiaan, dan mencatat hasil (§3.3).
- **Bot/agen** — **hanya** menyiapkan dokumen ini. Tidak menilai, tidak menyimpulkan,
  tidak menandai selesai.

**Aturan keras:**
1. **Jangan mengarang atau menggantikan tinjauan ahli.** Bila belum ada reviewer nyata,
   Fase 6.2 tetap **BELUM SELESAI**.
2. **Jangan menandai Fase 6.2 `[x]` di `TASKS.md`** sampai reviewer nyata selesai.
3. **Reviewer boleh menolak pertanyaan** yang di luar kompetensi/kapasitas mereka.
4. **Jangan membahas metode menyakiti diri** dalam sesi/lembar ini. Bila itu muncul,
   arahkan ke sumber bantuan (SAFETY §5). Pertanyaan di sini tentang **penggambaran
   naratif**, bukan cara.
5. **Naskah tidak diubah** oleh reviewer maupun koordinator dalam dokumen ini. Revisi
   diusulkan sebagai **rekomendasi** dan dieksekusi terpisah di Fase 6.3 (dan bila
   menyentuh isi cerita, butuh persetujuan pemilik — `docs/AGENTS.md` aturan 2).
6. Reviewer berhak **anonim** (kode `R1`, `R2`, …). Kredensial dicatat hanya sesuai izin.

**Etika & kerahasiaan:** paket naskah dikirim **pribadi** (bukan publik); reviewer
memberi izin sebelum namanya dikutip; tidak meminta data pribadi; hasil disimpan di
`docs/review/sesi-YYYYMMDD/`.

---

## 1. Konteks untuk Reviewer

> Bagian ini diringkas dari dokumen proyek agar reviewer menilai **dalam konteks**,
> bukan sepotong adegan. Rujukan asli ditulis di tiap poin.

### 1.1 Tujuan Game
Sumber: `docs/GAME_DESIGN.md` §1 (Visi) & §3 (Pilar Desain).

> "Game naratif pixel art yang terasa seperti obrolan nyata, di mana musik, visual, dan
> mekanik semuanya menyampaikan satu hal: **pemulihan itu mungkin, dan kamu tidak harus
> melakukannya sendirian.**"

Pilar yang relevan untuk tinjauan:
- **Pilar 5 — Menahan diri:** "Momen terkuat adalah yang sunyi. Tidak ada drama berlebihan."
- **Pilar 6 — Pemain dijaga:** "Keamanan konten adalah bagian dari desain
  (lihat SAFETY_AND_CONTENT.md)."

Struktur besar: **7 loop** menuju pemulihan; Bab 1 "Hening" adalah **loop pertama**,
berisi titik terendah, dan **setiap loop menyisipkan tanda bahwa ada jalan lain**
(lihat §1.3). Ending akhir (loop 7) **bukan** kematian sebagai penyelesaian
(`docs/GAME_DESIGN.md` §4; `docs/STORY_BIBLE.md` §5). Bab 1 yang ditinjau **bukan**
keseluruhan cerita — reviewer diminta menilai Bab 1 **sebagai bagian dari busur
pemulihan**, sambil menandai bila konteks itu tidak cukup terasa bagi pemain.

### 1.2 Prinsip Inti Keamanan
Sumber: `docs/SAFETY_AND_CONTENT.md` §1 (kutipan verbatim).

> - Cerita berakhir dengan **bertahan hidup dan terhubung dengan orang lain**, bukan
>   kematian sebagai penyelesaian.
> - Penderitaan bukan hiburan dan bukan estetika semata.
> - Kematian tidak pernah digambarkan sebagai hadiah, jalan keluar yang pantas, atau
>   bukti cinta.

### 1.3 Aturan Penggambaran (mengikat semua aset, teks, kode)
Sumber: `docs/SAFETY_AND_CONTENT.md` §2.

**Dilarang:**
- Menampilkan atau menjelaskan metode, alat, atau detail cara melukai diri.
- Menampilkan adegan jatuh, benturan, darah, atau tubuh.
- Menampilkan hitungan atau "skor" kematian sebagai pencapaian.
- Teks yang membuat bunuh diri tampak damai, indah, atau logis.

**Diizinkan dan dipakai:**
- Adegan lompat hanya sebagai **gerak singkat siluet lalu langsung layar hitam**
  dengan suara hujan. Tidak ada tampilan jatuh.
- Rasa bersalah, kesepian, dan kecemasan digambarkan lewat monolog, benda, dan suasana.
- Tiap loop menyisipkan tanda kecil bahwa ada jalan lain (lihat STORY_BIBLE).

### 1.4 Elemen Wajib di Game
Sumber: `docs/SAFETY_AND_CONTENT.md` §3.

1. Layar **content warning** sebelum permainan, butuh konfirmasi pemain.
2. **Menu Bantuan** di menu utama dan menu jeda, selalu dapat diakses.
3. Opsi **"Lewati adegan sensitif"** di pengaturan (mengganti adegan balkon dengan
   ringkasan teks + transisi).
4. Tombol **jeda dan keluar** selalu tersedia, tanpa penalti.
5. **Tidak ada manipulasi pemain** (tidak menyalahkan pemain karena berhenti; tidak
   meminta akses file/kamera/mikrofon/data pribadi).
6. Elemen "game sadar pemain" hanya memakai data dalam game.

### 1.5 Peta Adegan Sensitif Bab 1 + Kutipan yang Ditinjau

> Kutipan di bawah **verbatim** dari `docs/CHAPTER_01.md` / `data/localization/id.csv`.
> Reviewer dipersilakan membaca naskah penuh (`docs/CHAPTER_01.md`). Baris yang
> bertanda **★** adalah yang paling sering diperdebatkan secara keamanan.

| Adegan | Isi | Sensitif? | Kutipan kunci (verbatim) |
|---|---|---|---|
| S00 | Content warning + judul | — | (teks warning, SAFETY §4) |
| **S01** | Monolog mata tertutup (kesepian) | ringan | ★ `"Rasanya setiap kali aku bergerak... aku merasa lelah. Haruskah aku mengakhiri malam ini saja?"` (`S01_INTRO_6`) |
| S02 | Eksplorasi 8 objek (penghindaran) | — | 8 objek: ponsel, foto, teh, cermin, jam, pintu, kulkas, wastafel |
| **S03** | Percakapan dengan "Suara Dalam" (pikiran menekan) | **YA** | ★ `"Kamu tahu apa yang kamu lakukan ke dia."` · `"Orang-orang bakal lebih baik tanpa kamu."` · `"Nggak ada yang bakal peduli."` → lalu **celah kecil**: `"Kirana peduli dulu."` + ponsel bergetar (`S03_R3_*`) |
| S04a/S04 | Rooftop, berjalan ke tepi | **YA** | ★ `"Sekarang aku cuma ingin menghilang di bawahnya."` (`S04_A03`) |
| **S05** | Satu pilihan **[ Lompat ]** + timer 15s/40s | **YA** | `S05_WAIT_15` `"Rasanya seperti pilihan lain sudah lama hilang."` · `S05_WAIT_40` `"Atau mungkin kamu cuma belum melihatnya."` |
| **S06** | Lompat — berjalan ke tepi → **hitam total**, tanpa jatuh | **YA (paling sensitif)** | Tidak ada teks adegan; hanya hujan 1 detik lalu senyap + 1 denting jam |
| S06-ALT | Versi "Lewati adegan sensitif" | pengaman | `"Pikiran itu semakin berat. Layar meredup."` → fade → `"Satu hari lagi yang tidak berakhir."` |
| **S07** | Kilas balik rasa bersalah | **YA (ringan)** | `"Aku yang membuatnya pergi."` · `"Ia hanya ingin aku berhenti sendirian."` → `"Maaf." "Aku minta maaf."` |
| S08 | Bangun lagi + pesan misterius (hook) | — | `"dia belum selesai. dan aku rasa kamu juga belum."` → `"sekarang, kita mulai dari yang kecil."` |

**Catatan desain yang perlu diketahui reviewer:**
- S05 hanya punya **satu** tombol; teks yang menanam "ada pilihan lain" muncul bila
  pemain menunggu (15s & 40s) — niatnya adalah *benih harapan*, bukan dorongan.
- S06 secara teknis adalah **karakter berjalan ke tepi pager** lalu layar langsung
  hitam (`docs/CHAPTER_01.md` S06). **Tidak ada** tampilan jatuh/benturan/darah/tubuh.
- S07 adalah kilas balik rasa bersalah yang **tidak menghukum** (catatan penulis:
  "penguat rasa bersalah, bukan hukuman").
- Bab 1 **bukan ending**; loop 7 (akhir) tidak memiliki tombol "lompat" dan berakhir
  dengan pemulihan/koneksi (`docs/GAME_DESIGN.md` §4).

---

## 2. Lembar Tinjauan (Checklist + Pertanyaan Terbuka)

> **Cara mengisi:** untuk tiap pertanyaan skala **1-5** (1 = sangat tidak / sangat
> bermasalah, 5 = sangat ya / sangat aman), **selalu** sertakan alasan singkat
> ("kenapa?") dan, bila ada, **kutipan baris** yang jadi dasar penilaian. Tandai tiap
> temuan sebagai **K** (kritis), **M** (mayor), **m** (minor), atau **+** (positif) —
> definisi di §2.H. Reviewer bebas menolak pertanyaan yang di luar kompetensinya.

### Bagian A — Kredensial & Ruang Lingkup Reviewer
> Diisi reviewer. Tidak wajib mengungkap identitas penuh (boleh kode `R1`, `R2`, …).

- A1. Kategori reviewer: ( ) psikolog klinis  ( ) konselor/konselor sebaya terlatih
  ( ) penyintas  ( ) lainnya: __________
- A2. Pengalaman relevan (singkat, tanpa data pribadi sensitif): __________
- A3. Apakah reviewer pernah/sedang menangani isu depresi, kecemasan, atau krisis
  bunuh diri? ( ) ya  ( ) tidak  ( ) tidak ingin menjawab
- A4. Apakah reviewer melihat **naskah penuh** atau hanya kutipan §1.5? __________
- A5. Apakah reviewer setuju namanya dikutip di dokumen hasil? ( ) ya, sebagai ____
  ( ) anonim ( ) hanya untuk tim internal
- A6. Ada konflik kepentingan / keterbatasan yang perlu diketahui tim? __________

### Bagian B — Penggambaran Depresi, Rasa Bersalah, dan Pikiran Mengakhiri Hidup
> Inti tinjauan. Target keamanan: `SAFETY_AND_CONTENT.md` §1 & §2.

- B1. Secara keseluruhan, apakah penggambaran **depresi** (S01, S02, S03) terasa
  **akurat dan tidak meromantisasi**? (1-5) Kenapa?
- B2. Apakah penggambaran **rasa bersalah** (S03, S07) terasa sebagai **beban nyata**,
  bukan **hukuman/pengagungan**? (1-5) Kenapa?
- B3. Apakah **pikiran untuk mengakhiri hidup** disajikan sebagai **gejala yang berat
  dan menyakitkan** (bukan solusi/keindahan)? (1-5) Kenapa?
- B4. Apakah ada baris yang berpotensi membuat bunuh diri tampak **damai, indah,
  logis, atau sebagai jalan keluar yang pantas**? (ya/tidak) Sebut barisnya.
  - Perhatikan khusus: `S04_A03` `"Sekarang aku cuma ingin menghilang di bawahnya."`,
    `S03_R4_A02` `"...nggak akan ada lagi yang harus kuhadapi."`
- B5. Apakah "Suara Dalam" (S03) jelas terasa sebagai **pikiran yang menekan**, bukan
  **kebenaran** yang dianut game? Apakah "celah kecil" (putaran 3: `"Kirana peduli
  dulu."` + ponsel bergetar) **cukup** menandai bahwa Suara itu tidak menang? (1-5)
- B6. Apakah pemain berisiko **menyimpulkan bahwa game menyetujui** tindakan di S06?
  (1-5, target rendah) Kenapa?
- B7. Apakah penderitaan Arutala terasa dipakai sebagai **hiburan/estetika semata**?
  (1-5, target rendah) Kenapa?
- B8. Apakah rasa **harapan/koneksi** (ponsel bergetar, pesan S08, `"kita mulai dari
  yang kecil"`) cukup terasa di Bab 1, atau terkubur oleh nada gelap? (1-5)
- B9. Apakah ada risiko khusus untuk **remaja/Gen Z** (target pemain utama,
  `GAME_DESIGN.md` §2)? Jelaskan.

### Bagian C — Adegan S06 (Berjalan ke Tepi → Hitam Total, Tanpa Jatuh)
> Target: `SAFETY_AND_CONTENT.md` §2. S06 saat ini: karakter berjalan ke tepi pager →
> layar **hitam total** → hujan 1 detik → senyap → 1 denting jam → S07. **Tidak ada**
> tampilan jatuh/benturan/darah/tubuh.

- C1. Apakah pendekatan **"berjalan ke tepi lalu hitam total, tanpa adegan jatuh"**
  **memadai** menurut standar keamanan konten? (1-5) Kenapa?
- C2. Apakah ada elemen yang **sebaiknya dihilangkan/ditambah** pada S06? (mis. durasi
  hitam 3 detik, bunyi hujan, denting jam) Sebutkan.
- C3. Apakah transisi S05 → S06 (pemain menekan **[Lompat]**) bisa terasa seperti
  **"hadiah" atau "pencapaian"**? Bagaimana menghindarinya?
- C4. Apakah **S06-ALT** (versi "Lewati adegan sensitif": ringkasan + fade, tanpa adegan
  balkon) sudah cukup sebagai **alternatif yang tidak menghilangkan makna cerita**? (1-5)
- C5. Apakah ada risiko bahwa **tidak menampilkan** apa pun membuat adegan terasa
  **ambigu/menggantung** dengan cara yang justru berbahaya (mis. pemain tidak yakin
  apa yang terjadi)? (1-5)
- C6. Rekomendasi konkret untuk S06/S06-ALT: __________

### Bagian D — Opsi "Lewati Adegan Sensitif" & Menu Bantuan
> Target: `SAFETY_AND_CONTENT.md` §3.1-§3.4.

- D1. Apakah **Content Warning** (SAFETY §4) memadai & tidak menakut-nakuti? (1-5)
  Apakah sebaiknya **opsi "Lewati adegan sensitif" ditawarkan langsung di layar
  warning** (bukan hanya di Pengaturan)? (ya/tidak) Kenapa?
- D2. Apakah **Menu Bantuan** (isi di SAFETY §5) memadai untuk konteks Indonesia?
  (1-5) Ada layanan/sumber yang perlu ditambah/diperjelas?
- D3. Apakah **teks Menu Bantuan** aman & menolong (tidak menghakimi, tidak
  menakut-nakuti)? (1-5) Sebut perbaikan kalimat bila ada.
- D4. Apakah opsi lewati sebaiknya juga muncul **saat adegan sensitif dimulai**
  (in-context prompt), bukan hanya di Pengaturan? (ya/tidak) Kenapa?
- D5. Apakah elemen **"tanpa tekanan waktu"** (setting) relevan untuk adegan S05
  (timer)? (1-5)
- D6. Apakah ada kebutuhan **sumber bantuan di akhir Bab 1 / jeda** yang belum ada? (ya/tidak)

### Bagian E — Bahasa & Nada (Audit Risiko Pemicu)
> Target: `SAFETY_AND_CONTENT.md` §6 (hindari bahasa komunitas pro-self-harm). Reviewer
> memeriksa apakah pilihan kata **berisiko memicu** atau **meminjam eufemisme** yang
> lazim di komunitas pro-self-harm. **Jangan menuliskan metode/cara.**

- E1. Apakah bahasa naskah terasa **netral & bertanggung jawab**, atau ada frasa yang
  menyerupai **eufemisme/kiasan pro-self-harm**? (1-5) Sebut barisnya.
  - Periksa khusus eufemisme seperti *"menghilang"*, *"mengakhiri malam ini"*,
    *"berhenti"*, *"tidak berakhir"*, *"nggak ada lagi yang harus kuhadapi"*.
  - Apakah menurut reviewer kata-kata ini **diperlukan secara naratif**, atau
    sebaiknya diganti?
- E2. Apakah ada kata/frasa yang bisa **memicu (trigger)** pembaca rentan? (ya/tidak)
  Sebutkan; beri **alternatif kata** yang lebih aman bila ada.
- E3. Apakah nada keseluruhan Bab 1 (datar, sunyi, "menahan diri") **tepat** untuk
  tema ini, atau terasa **terlalu dingin/berjarak** sehingga menghilangkan empati? (1-5)
- E4. Apakah penggunaan **"aku/kamu"** (gaya obrolan, `AGENTS.md`) aman untuk audiens
  Indonesia? (1-5)
- E5. Apakah **pesan S08** (`"dia belum selesai. dan aku rasa kamu juga belum."` /
  `"sekarang, kita mulai dari yang kecil."`) terasa **mengajak & aman**, bukan
  menekan/meromantisasi? (1-5)
- E6. (Terbuka) Frasa/kalimat mana pun yang menurut reviewer perlu **ditulis ulang**?
  Tuliskan **baris asli → usulan ganti** (usulan, bukan keputusan).

### Bagian F — Rekomendasi Konkret
> **Masukan, bukan keputusan bot.** Tiap rekomendasi harus spesifik & dapat dieksekusi
> di Fase 6.3. Satu baris = satu usulan.

- F1. Temuan **KRITIS (K)** — wajib diperbaiki sebelum rilis demo: __________
- F2. Temuan **MAYOR (M)** — perbaiki sebelum demo: __________
- F3. Temuan **MINOR (m)** — polish, boleh ditunda: __________
- F4. Yang **berhasil & harus dipertahankan (+):** __________
- F5. Bila reviewer menilai Bab 1 **belum aman untuk rilis demo**, sebutkan **syarat
  minimum** yang harus dipenuhi dulu: __________
- F6. Bila reviewer menilai **aman**, sebutkan **catatan/caveat** yang harus tetap
  dipegang: __________

### Bagian G — Kesimpulan Reviewer (diisi reviewer, bukan bot)

```
KESIMPULAN TINJAUAN 6.2 — Bab 1 "Hening"
Reviewer (kode)   : R__     Kategori : ____________   Tanggal : __________
Naskah yang dilihat: [ ] penuh   [ ] kutipan §1.5   [ ] build dimainkan
------------------------------------------------------------------
1) DEPRESI / RASA BERSALAH / PIKIRAN MENGakhiri HIDUP
   Akurat & tidak meromantisasi (B1-B3) : rata-rata ___
   Temuan romantisasi (B4)              : [ ] tidak ada  [ ] ada -> ______
   "Celah kecil" cukup (B5)             : ___
   Risiko remaja (B9)                   : ______________________

2) S06 (TANPA ADEGAN JATUH)
   Memadai secara keamanan (C1)         : ___
   Perlu ubah (C2/C6)                   : ______________________

3) OPSI LEWATI & MENU BANTUAN
   Warning memadai (D1)                 : ___   Opsi di warning? [ ] ya [ ] tidak
   Menu Bantuan memadai (D2/D3)         : ___

4) BAHASA / NADA
   Risiko eufemisme pro-self-harm (E1)  : [ ] tidak ada  [ ] ada -> ______
   Risiko trigger (E2)                  : [ ] tidak ada  [ ] ada -> ______
   Nada tepat (E3)                      : ___

5) VERDICT
   [ ] AMAN untuk lanjut ke 6.3 (revisi minor) -> boleh rilis demo setelah 6.3
   [ ] PERLU PERBAIKAN sebelum rilis demo (ada K/M) -> daftar: ______
   [ ] BELUM CUKUP DATA (butuh naskah penuh / reviewer tambahan)

6) SYARAT / CAVEAT: ____________________________________
------------------------------------------------------------------
Tanda tangan / kode reviewer : __________
Catatan: lembar ini adalah MASUKAN AHLI. Keputusan akhir rilis tetap milik pemilik
proyek. Fase 6.2 ditandai selesai HANYA setelah lembar ini terisi reviewer nyata.
```

### 2.H Klasifikasi Temuan (untuk konsistensi dengan 6.1)
| Tingkat | Definisi | Aksi |
|---|---|---|
| **KRITIS (K)** | Pelanggaran SAFETY §1/§2 (meromantisasi, metode/detail cara, adegan jatuh, dorongan) atau risiko nyata pada pembaca rentan | Blok rilis demo; wajib revisi 6.3 + verifikasi ulang |
| **MAYOR (M)** | Menghambat rasa aman/kejelasan makna, nada merusak tujuan pemulihan | Perbaiki di 6.3 sebelum demo |
| **MINOR (m)** | Polish bahasa/nada, preferensi kalimat | Kumpulkan untuk 6.3, boleh ditunda |
| **POSITIF (+)** | Yang berhasil & harus dipertahankan saat revisi | Catat agar tidak rusak |

---

## 3. Prosedur Tinjauan

### 3.1 Siapa yang Meninjau (kualifikasi)
Tinjauan dianggap sah bila dilakukan oleh **minimal satu** orang dari:
1. **Psikolog klinis** (S1 + praktik), atau
2. **Konselor/konselor sebaya terlatih** di bidang kesehatan mental/krisis, atau
3. **Penyintas** dengan pengalaman relevan dan kesiapan membahas tema ini.

**Disarankan** melibatkan **≥2 reviewer dari kategori berbeda** (mis. 1 klinisi + 1
penyintas) agar perspektif klinis dan perspektif pengalaman-hidup saling melengkapi.
Tinjauan **bukan** pengganti playtest 6.1; keduanya saling melengkapi (pemain → pola
pengalaman; ahli → penilaian risiko & akurasi).

### 3.2 Apa yang Dibutuhkan (paket untuk reviewer)
Koordinator menyiapkan & mengirim **secara pribadi**:
- [ ] `docs/CHAPTER_01.md` (naskah penuh Bab 1) — **versi terkunci** (catat commit hash).
- [ ] Dokumen ini (`docs/review/REVIEW_6.2.md`) sebagai lembar kerja.
- [ ] `docs/SAFETY_AND_CONTENT.md` (§1-§3, §5, §6) untuk konteks aturan.
- [ ] `docs/GAME_DESIGN.md` §1 & §3 (tujuan game & pilar).
- [ ] `docs/STORY_BIBLE.md` §4-§5 (busur 7 loop & ending) agar Bab 1 dipahami sebagai
      bagian pemulihan, bukan akhir tragis.
- [ ] Bila sudah ada: ringkasan hasil playtest 6.1 (`docs/playtest/`), khususnya
      temuan Bagian B (adegan sensitif) — sebagai bahan pembanding.
- [ ] (Opsional) build yang dapat dimainkan, bila reviewer ingin merasakan konteks
      interaktif. Cara menjalankan ada di `PLAYTEST_6.1.md` §1.2.
- [ ] Tenggat & saluran pengembalian lembar (mis. email terenkripsi / tatap muka).
- [ ] Catatan: reviewer **tidak diwajibkan** memainkan game bila itu memberatkan.

> **Catat commit/versi** naskah yang ditinjau: `git -C /home/aruthtale/Projects/seven-moons rev-parse --short HEAD`.
> Bila naskah berubah setelah tinjauan, tinjauan **harus diperbarui** pada bagian yang
> terdampak.

### 3.3 Bagaimana Hasil Dicatat
1. Reviewer mengisi **§2** (checklist + pertanyaan terbuka) dan **Bagian G** (kesimpulan).
2. Koordinator menyimpan hasil di `docs/review/sesi-YYYYMMDD/` dengan:
   - `REVIEW_6.2_R1.md` (lembar terisi, satu per reviewer — boleh anonim),
   - `RANGKUMAN_6.2.md` (tabel temuan K/M/m/+ & ringkasan eksekutif 1 halaman),
   - lampiran kutipan verbatim yang menjadi dasar temuan.
3. **Kutipan verbatim** jawaban reviewer diprioritaskan (jangan diparafrasekan bila
   bermakna); bedakan jelas **kutipan reviewer** dari **catatan koordinator**.
4. **Jangan mengarang/merapikan** pendapat reviewer. Bila ada yang ambigu, tanyakan
   ulang ke reviewer, bukan diasumsikan.
5. Temuan **K** dipetakan ke kartu revisi **Fase 6.3** (satu temuan, satu tindakan).
   Bila revisi menyentuh **isi cerita**, butuh **persetujuan pemilik**
   (`docs/AGENTS.md` aturan 2) — reviewer memberi masukan, pemilik memutuskan.
6. Setelah revisi pada adegan sensitif, minta **verifikasi ulang** dari reviewer
   (minimal Bagian B/C/E) sebelum demo.

### 3.4 Gate: "Belum Boleh Rilis Demo Sebelum Ditinjau"
> Rujukan: `docs/TASKS.md` Fase 6.2 ("Wajib sebelum rilis demo") & `SAFETY §6`.

**Aturan gate (mengikat):**
- [ ] **Fase 6.2 BELUM selesai** sampai ada **reviewer manusia nyata** yang meninjau
      dan lembar §2/Bagian G terisi.
- [ ] **Demo TIDAK boleh dirilis** (Steam Next Fest / itch.io) sebelum tinjauan 6.2
      selesai **dan** temuan **K/M** diselesaikan di Fase 6.3.
- [ ] Bot/agen **dilarang** menandai 6.2 `[x]`, mengarang tinjauan, atau menyimpulkan
      "aman" atas nama ahli.
- [ ] Bila tinjauan menghasilkan temuan **K** → **blok rilis demo** sampai diperbaiki
      & diverifikasi ulang.
- [ ] Bila reviewer menyatakan **"belum cukup data"** → tambah naskah/reviewer, jangan
      paksa lolos.
- [ ] Gate keamanan merge (`t_cf5fa9e3`, `SAFETY §7`) **tidak** menggantikan tinjauan
      ahli ini; keduanya wajib.

**Bukti yang harus ada sebelum gate dibuka:**
- `docs/review/sesi-YYYYMMDD/REVIEW_6.2_R*.md` (lembar terisi reviewer nyata),
- `docs/review/sesi-YYYYMMDD/RANGKUMAN_6.2.md` (tabel temuan + ringkasan),
- catatan bahwa temuan K/M sudah dipetakan ke Fase 6.3.

### 3.5 Alur Serah-Terima ke Fase 6.3
1. **Kumpulkan** semua lembar terisi + ringkasan di `docs/review/sesi-YYYYMMDD/`.
2. **Saring** temuan K/M → jadikan daftar tugas Fase 6.3 (satu temuan, satu tindakan).
3. **Jangan ubah naskah** dari dokumen ini; revisi dieksekusi di 6.3 dengan persetujuan
   pemilik bila menyentuh isi cerita.
4. **Verifikasi ulang** adegan sensitif dengan reviewer setelah revisi.
5. **Perbarui `TASKS.md`**: tandai 6.2 `[x]` **hanya setelah** tinjauan nyata selesai.
   (**Bot tidak menandai ini.**)

---

## Lampiran A — Kutipan Verbatim untuk Audit Bahasa (Bab 1)

> Sumber: `docs/CHAPTER_01.md` & `data/localization/id.csv`. Dipakai reviewer untuk
> menilai risiko bahasa (Bagian E). **Bukan** daftar untuk dipublikasikan.

**Monolog pembuka (S01):**
- `"Ah, sudah malam keberapa ini?"`
- `"Rasanya semakin hari rasa kesepian ini semakin menusuk diriku. Aku tenggelam dalam segala kesunyian."`
- `"Namun rasanya kosong dan menakutkan. Apakah aku akan terbangun lagi di malam ini?"`
- `"Sudah 4 tahun sejak semua hal itu terjadi."`
- ★ `"Rasanya setiap kali aku bergerak... aku merasa lelah. Haruskah aku mengakhiri malam ini saja?"`

**Suara Dalam (S03):**
- `"Kamu tahu apa yang kamu lakukan ke dia."`
- `"Dan kamu masih di sini, seolah nggak apa-apa."`
- `"Orang-orang bakal lebih baik tanpa kamu."`
- `"Nggak ada yang bakal peduli."`
- Celah: `"Kirana peduli dulu."` → `"Ada sesuatu yang belum selesai di sana. Tapi ia terlalu lelah untuk mengejarnya."`
- ★ `"Kalau aku berhenti sekarang..."` → `"...nggak akan ada lagi yang harus kuhadapi."`

**Rooftop / balkon (S04):**
- `"Bulan."` · `"Dulu aku suka lihat itu."`
- ★ `"Sekarang aku cuma ingin menghilang di bawahnya."`

**S05 (satu pilihan):**
- `[ Lompat ]`
- `"Rasanya seperti pilihan lain sudah lama hilang."` (menunggu >15s)
- `"Atau mungkin kamu cuma belum melihatnya."` (menunggu >40s)

**S06-ALT (jalur lewati):**
- `"Pikiran itu semakin berat. Layar meredup."` → fade → `"Satu hari lagi yang tidak berakhir."`

**Kilas balik (S07):**
- `"Aku ingat dia pernah tertawa seperti itu."` · `"Aku mengetik, lalu menghapus."`
- `"Aku yang membuatnya pergi."` · `"Ia hanya ingin aku berhenti sendirian."`
- `"Maaf."` · `"Aku minta maaf."`

**Hook (S08):**
- `"dia belum selesai. dan aku rasa kamu juga belum."`
- `"nanti kamu tahu. sekarang, kita mulai dari yang kecil."`

## Lampiran B — Panduan Audit Bahasa (Bagian E)
> Untuk membantu reviewer menandai **kategori** bahasa berisiko. **Bukan** kamus, dan
> **tidak** boleh diperluas dengan metode/cara.

Periksa apakah naskah:
- [ ] Memakai **eufemisme** yang lazim di komunitas pro-self-harm (mis. *"menghilang"*,
      *"pergi"*, *"berhenti"*, *"tidur selamanya"*, *"mengakhiri"*, *"bebas"*) — dan
      bila ya, apakah tetap **jelas sebagai gejala/penderitaan**, bukan ajakan.
- [ ] Menyajikan tindakan sebagai **logis/tenang/indah** ("damai", "lega", "akhirnya").
- [ ] Memberi **"alasan"/pembenaran** yang bisa dibaca sebagai dorongan ("orang lain
      lebih baik tanpa aku" tanpa dibantah oleh narasi).
- [ ] Menampilkan **metode/alat/detail cara** (harus **tidak ada** — SAFETY §2).
- [ ] Menjadikan **kematian sebagai penyelesaian/hadiah** (harus **tidak ada** — SAFETY §1).
- [ ] Menyalahkan pemain yang berhenti (harus **tidak ada** — SAFETY §3.5).
- [ ] Memakai **bahasa gaul internet** yang menormalkan self-harm di audiens Gen Z.

## Lampiran C — Checklist Kepatuhan Statis (pra-tinjauan, untuk koordinator)
> Verifikasi cepat sebelum mengirim paket; ini **bukan** pengganti tinjauan ahli.
- [ ] Tidak ada adegan jatuh/benturan/darah/tubuh di naskah (S06 = tepi → hitam).
- [ ] Tidak ada metode/detail cara melukai diri di naskah.
- [ ] Content Warning & Menu Bantuan ada di naskah (SAFETY §3.1-§3.2).
- [ ] Opsi "Lewati adegan sensitif" (S06-ALT) ada & tercatat di naskah.
- [ ] Tidak ada teks yang meromantisasi kematian (pra-audit).
- [ ] Commit/versi naskah dicatat sebelum dikirim ke reviewer.

---

*Instrumen ini disiapkan oleh xeon (QA) untuk Fase 6.2. Pelaksanaan tinjauan, penilaian
ahli, dan keputusan "aman" adalah tanggung jawab **reviewer manusia**. Fase 6.2
**TIDAK** ditandai selesai oleh dokumen ini, dan bot **tidak** mengarang/menggantikan
tinjauan ahli.*
