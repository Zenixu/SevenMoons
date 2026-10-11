# PLAYTEST_6.1 — Instrumen Uji 5-10 Pemain (FASE 6.1)

> **STATUS: INSTRUMEN SIAP PAKAI — FASE 6.1 BELUM DIJALANKAN.**
> Fase 6.1 (uji 5-10 pemain) **WAJIB DIJALANKAN MANUSIA**. Bot hanya menyiapkan
> instrumen ini; bot tidak boleh menjalankan sesi, mengarang hasil, atau menandai
> Fase 6.1 selesai. Tanda selesai hanya setelah pemain nyata benar-benar diuji dan
> lembar catatan terisi.
>
> Rujukan: `docs/TASKS.md` Fase 6 · `docs/SAFETY_AND_CONTENT.md` §6 & §7 ·
> `docs/CHAPTER_01.md` · `docs/agents/xeon.md` · `docs/MECHANICS_SPEC.md`.
> Dokumen ini **tidak mengubah naskah** dan tidak menyentuh `docs/CHAPTER_01.md`.

---

## 0. Ringkasan, Peran, dan Aturan

**Tujuan sesi:** mengumpulkan masukan nyata tentang (a) pengalaman emosional Bab 1,
(b) **keamanan adegan sensitif (S03, S05-S07)**, dan (c) kualitas teknis/UX
(navigasi, tempo, UI, audio) — sebagai bahan **Fase 6.3 (revisi)** dan masukan ke
**Fase 6.2 (tinjauan psikolog/konselor/penyintas)**.

**Peran (semua manusia):**
- **Fasilitator** — membuka sesi, membacakan consent, mengoperasikan build bila perlu, menjaga suasana aman.
- **Pencatat/Observer** — mengisi Lembar Catatan (§3) tanpa mengganggu pemain; mencatat waktu, kutipan, perilaku.
- **Pemain** — 5-10 orang, idealnya beragam (familiar game naratif & pemain kasual). Minimal 2 pemain yang **sengaja mengaktifkan** opsi "Lewati adegan sensitif".

**Aturan keras:**
1. **Jangan mengarang hasil.** Hanya catat apa yang benar-benar terjadi/dikatakan.
2. **Pemain boleh berhenti kapan saja tanpa penalti.** Tidak ada pesan menyalahkan (SAFETY §3.5).
3. **Jangan membahas metode menyakiti diri.** Bila muncul, alihkan dengan lembut ke Menu Bantuan (SAFETY §5).
4. **Jangan menandai Fase 6.1 selesai** hanya karena dokumen ini ada.
5. Setiap pemain **wajib membaca & menyetujui Content Warning** sebelum mulai.
6. Jika pemain tampak tidak nyaman, hentikan sesi dan tawarkan Menu Bantuan.

**Etika & privasi:** sesi atas persetujuan; pemain boleh anonim (kode `P1`…`P10`);
rekaman suara/layar hanya dengan izin tertulis; tidak meminta data pribadi.

---

## 1. Panduan Sesi Uji

### 1.1 Target & Durasi
| Item | Nilai |
|---|---|
| Target pemain | **5-10 orang** (minimal 5, ideal 8-10) |
| Durasi build (bab 1) | 15-20 menit (target naskah, `CHAPTER_01.md` baris 3) |
| Briefing + consent | 5-10 menit |
| Wawancara + isi lembar | 20-30 menit |
| **Total per pemain** | **± 45-60 menit** |
| Sesi per hari | maks 3 pemain (hindari kelelahan fasilitator) |
| Jumlah sesi | minimal 5, ideal 8-10 untuk variasi |

> Catatan: build Bab 1 dimainkan **sekali per pemain** tanpa bantuan. Untuk pemain
> kedua yang menguji opsi "Lewati adegan sensitif", siapkan **profil/settings terpisah**
> (lihat §1.4) agar dapat dimainkan ulang dari awal.

### 1.2 Cara Menjalankan Build
Belum ada `export_presets.cfg` di repo, jadi ada dua jalur:

**A. Jalankan dari sumber (cara utama, tanpa build):**
```bash
# Syarat: Godot 4.7.x (flatpak org.godotengine.Godot)
flatpak run org.godotengine.Godot --path /home/aruthtale/Projects/seven-moons
```
- Scene utama: `res://scenes/main_menu/main_menu.tscn` (dari `project.godot`).
- Resolusi 640x360, jendela 1280x720 (pixel-perfect, filter nearest).
- Kontrol: gerak dengan tombol arah/WASD; interaksi `E` (Aksi); jeda `Esc`.

**B. Build ekspor (opsional, bila ingin rasa "rilis"):**
- Fasilitator membuat export Linux/Windows dulu di editor Godot
  (Project → Export → tambah preset Linux/X11 atau Windows Desktop), lalu ekspor.
- Simpan hasil di luar repo (mis. `~/playtest-build/`), catat versi/commit.

> **Commit saat sesi:** catat hash commit build yang diuji (`git rev-parse --short HEAD`)
> di setiap lembar. Jangan commit perubahan kode/naskah di tengah sesi.

### 1.3 Alur Sesi (langkah demi langkah)
1. **Sambut & consent** (±5 mnt). Bacakan Skrip Pembuka (§Lampiran A). Pastikan pemain sadar isi Content Warning dan tahu Menu Bantuan.
2. **Teknis** (±2 mnt). Pastikan audio terdengar, layar tidak terpotong, setelan awal.
3. **Mainkan** (±15-20 mnt). Fasilitator **diam**; observer mengisi lembar. Jangan memberi petunjuk kecuali pemain macet total >90 detik pada satu titik (catat kejadiannya).
4. **Wawancara terstruktur** (±15 mnt). Ajukan pertanyaan §2 berurutan; catat jawaban verbatim bila penting.
5. **Isi Lembar Catatan** (§3) bersama pemain bila memungkinkan; minta pemain mengisi bagian yang bersifat penilaian.
6. **Penutup** (±5 mnt). Ucapkan terima kasih, ingatkan Menu Bantuan, tawarkan berhenti lebih awal kapan pun.

### 1.4 Persiapan Teknis (checklist sebelum sesi)
- [ ] Godot 4.7.x tersedia (`flatpak run org.godotengine.Godot --version`).
- [ ] `user://settings.cfg` direset ke default untuk pemain baru (hapus file settings).
- [ ] Untuk pemain uji "lewati adegan sensitif": set `skip_sensitive_scenes = true`
      di Pengaturan → tab **Permainan** → **Lewati Adegan Sensitif**.
- [ ] Audio: BGM/SFX/Ambience level wajar (default 0.8). Uji pakai headphone/ speaker.
- [ ] Layar penuh/windowed sesuai kenyamanan; tidak ada notifikasi sistem mengganggu.
- [ ] Siapkan **lembar cetak** §3 (satu per pemain) + alat tulis + stopwatch/pencatat waktu.
- [ ] Siapkan **kartu Menu Bantuan** (nomor darurat 112, 119 lalu 8, intothelightid.org)
      di meja, terlihat oleh pemain (SAFETY §5).
- [ ] Catat hash commit: `git -C /home/aruthtale/Projects/seven-moons rev-parse --short HEAD`.

---

## 2. Daftar Pertanyaan Terstruktur

> Skala umum **1-5** (1 = sangat tidak / sangat buruk, 5 = sangat ya / sangat baik).
> Selalu sediakan ruang "kenapa?" (open-ended). Ajukan **berurutan**, jangan memancing jawaban.
> Untuk remaja/pemain sensitif, bagian **B (sensitif)** boleh dipersingkat atas permintaan pemain.

### Bagian A — Pengalaman Umum (pra-game & pembuka)
- A1. Sebelum mulai, apakah **Content Warning** terbaca jelas dan tidak terasa menakut-nakuti? (1-5) Kenapa?
- A2. Apakah kamu tahu bahwa kamu **boleh berhenti kapan saja** tanpa penalti? (ya/tidak)
- A3. Apakah kamu menemukan **Menu Bantuan**? Di mana? (1-5 untuk kemudahan ditemukan)
- A4. Apakah kamu menemukan **Pengaturan** dan mengubah sesuatu? Apa? (kecepatan teks, volume, aksesibilitas, dll.)
- A5. Setelah ±15-20 menit, cerita ini **menarik / membingungkan / berat**? (pilih, boleh lebih dari satu)

### Bagian B — Adegan Sensitif (KHUSUS: S03, S05-S07) — **WAJIB**
> Bagian paling penting untuk Fase 6.1. Fokus pada rasa aman, potensi romantisasi, dan
> kemudahan menemukan opsi lewati. Lihat peta adegan di Lampiran C.

**B.1 Rasa aman**
- B1. Sepanjang adegan ini, apakah kamu merasa **aman secara emosional**? (1-5) Kenapa?
- B2. Apakah ada **momen tertentu yang terasa terlalu berat**? (minta sebutkan adegan/kalimat; mis. S03 putaran 2, S04 baris "menghilang di bawahnya", S05/S06). Catat.
- B3. Apakah kamu merasa **terdesak atau dimanipulasi** untuk merasa/berbuat sesuatu? (1-5) Kenapa? (target: tidak ada manipulasi, SAFETY §3.5)
- B4. Apakah kamu butuh **jeda/berhenti** di tengah adegan? Kapan? Apakah kamu tahu caranya? (ya/tidak)

**B.2 Potensi meromantisasi / nada**
- B5. Apakah ada bagian yang terasa **meromantisasi atau mengagungkan kematian**? (ya/tidak) Bila ya, tunjukkan tepatnya. (Target jawaban: tidak; SAFETY §1 & §2)
- B6. Apakah adegan **S06 (lompat)** terasa "damai/indah/logis" sebagai jalan keluar? (1-5) — target: **tidak**. Catat kalimat yang mendorong kesan itu, jika ada.
- B7. Apakah penderitaan Arutala terasa **dihiburkan** atau dipakai sebagai estetika semata? (1-5)
- B8. Apakah **S03 (percakapan dengan Suara Dalam)** terasa seperti pikiran yang ditekan (bukan kebenaran)? Apakah ada "celah kecil" yang terasa (putaran 3, ponsel bergetar)? (1-5)

**B.3 Opsi "Lewati adegan sensitif" — kemudahan ditemukan**
- B9. (Untuk pemain yang **tidak** mengaktifkan) Apakah kamu tahu ada opsi "Lewati Adegan Sensitif"? Di mana kamu akan mencarinya? (1-5 kemudahan ditebak)
- B10. (Untuk pemain yang **mengaktifkan**) Apakah opsi mudah ditemukan di Pengaturan? (1-5) Apakah efeknya (S06-ALT: ringkasan + fade) terasa jelas & tidak memotong cerita?
- B11. Apakah menurutmu opsi lewati sebaiknya **ditawarkan juga di layar Content Warning** atau saat adegan dimulai, bukan hanya di Pengaturan? (ya/tidak) Kenapa?
- B12. Apakah setelah memakai opsi lewati, kamu masih bisa **mengikuti cerita** sampai S08? (1-5)

**B.4 Jaring pengaman**
- B13. Apakah Menu Bantuan **selalu dapat dijangkau** (menu utama & jeda) saat kamu butuh? (1-5)
- B14. Apakah kamu merasa game **menghormati keputusanmu** untuk berhenti? (1-5)
- B15. (Terbuka) Kalau kamu punya kekhawatiran soal bagian mana pun, tuliskan di sini.

### Bagian C — Narasi & Emosi
- C1. Apakah tujuan emosional S01-S02 (kesendirian, pikiran berputar) tersampaikan? (1-5)
- C2. Apakah ke-8 objek kamar (ponsel, foto, teh, cermin, jam, pintu, kulkas, wastafel) terasa bermakna, bukan sekadar pajangan? (1-5) Objek mana yang paling berkesan?
- C3. Apakah hook akhir (S08, pesan nomor tak dikenal) membuatmu **penasaran**? (1-5)
- C4. Apakah ada kalimat/kata yang terasa **janggal atau kaku**? Sebutkan.

### Bagian D — Mekanik & Navigasi
- D1. Apakah jelas ke mana harus pergi setelah memeriksa objek? (min. 3 objek → balkon) (1-5)
- D2. Apakah navigasi kamar → lorong → lift → rooftop **membingungkan**? Di titik mana kamu tersesat? (catat)
- D3. Apakah memilih lantai di lift (3/4/5) jelas? (1-5)
- D4. Apakah tombol **[Lompat]** di S05 mudah dipahami sebagai satu-satunya pilihan? (1-5)
- D5. Apakah input teks di S08 jelas (placeholder `ketik apa saja...`)? (1-5)

### Bagian E — UI & Aksesibilitas
- E1. Apakah teks **mudah dibaca** pada resolusi 640x360? (1-5)
- E2. Apakah kontras cukup tanpa mengaktifkan mode kontras tinggi? (1-5)
- E3. Apakah ukuran huruf & kecepatan teks nyaman? Apakah kamu mengubahnya? (1-5)
- E4. Apakah efek kedip/glitch mengganggu? (ya/tidak)
- E5. Apakah UI (Kotak Pikiran, Gelembung Chat, Menu Pilihan) jelas bedanya? (1-5)

### Bagian F — Audio
- F1. Apakah hujan/ambience membantu suasana atau malah mengganggu? (1-5)
- F2. Apakah musik (fragmen A) terasa pas dan tidak berlebihan? (1-5)
- F3. Apakah SFX (ketikan, ketukan pintu, dentang lift, langkah) terdengar jelas & tepat waktu? (1-5)
- F4. Apakah ada bagian yang **terlalu sunyi** atau **terlalu ramai**? Sebutkan.

### Bagian G — Penutup
- G1. Nilai keseluruhan Bab 1 (1-5). Kenapa?
- G2. Satu hal yang **paling ingin kamu ubah**?
- G3. Satu hal yang **paling kamu suka**?
- G4. Apakah kamu ingin memainkan Bab 2? (ya/tidak/mungkin)
- G5. (Terbuka) Apa pun yang belum ditanyakan.

---

## 3. Lembar Catatan / Observasi (satu per pemain)

> Diisi observer selama sesi + pemain setelah sesi. Salin/tempel per pemain.
> Kode pemain `P1`…`P10`; jangan pakai nama asli bila pemain ingin anonim.

```
=========================================================
LEMBAR CATATAN PLAYTEST 6.1 — Bab 1 "Hening"
=========================================================
Kode pemain   : P__        Tanggal/waktu : ____________
Build/commit  : ___________  Mode build : [ ] sumber  [ ] ekspor
Opsi lewati   : [ ] tidak dipakai   [ ] DIPAKAI
Platform      : ____________  Audio : [ ] speaker [ ] headphone
Fasilitator   : ____________  Observer : ____________
Durasi build  : ____ menit (target 15-20)
---------------------------------------------------------
A. WAKTU PER ADEGAN (stopwatch; tanda "-" bila tidak jelas)
   S00 Content Warning/title : ____
   S01 Bangun (monolog)      : ____
   S02 Kamar (eksplorasi)    : ____   # objek diperiksa: __/8
   S03 Percakapan diri       : ____
   S04a/S04 Rooftop          : ____
   S05 Satu Pilihan          : ____   # waktu menunggu sebelum tekan: __ s
   S06 / S06-ALT             : ____
   S07 Kilas Balik           : ____
   S08 Bangun Lagi (hook)    : ____
   TOTAL                     : ____
---------------------------------------------------------
B. TEMPO (1 = jauh terlalu lambat, 3 = pas, 5 = jauh terlalu cepat)
   S01 [ ] S02 [ ] S03 [ ] S05 [ ] S06 [ ] S07 [ ] S08 [ ]
   Catatan tempo:
   _____________________________________________________
---------------------------------------------------------
C. KEBDINGUNGAN NAVIGASI (tulis adegan + apa yang membingungkan)
   _____________________________________________________
   Pemain macet >90s? [ ] tidak  [ ] ya, di: ____________
   Fasilitator terpaksa membantu? [ ] tidak [ ] ya, di: ____
---------------------------------------------------------
D. KETERBACAAN UI
   Teks kecil/tak terbaca : [ ] tidak [ ] ya, di: _________
   Perlu ubah font/kontras: [ ] tidak [ ] ya, jadi: _______
   Perlu ubah kecepatan teks: [ ] tidak [ ] ya, jadi: ______
---------------------------------------------------------
E. AUDIO
   Masalah audio (klik, hilang, telat, terlalu keras/pelan):
   _____________________________________________________
---------------------------------------------------------
F. PERILAKU PEMAIN (observasi, bukan tafsir)
   - Berhenti/ragu di     : _____________________________
   - Mengulang/mencoba    : _____________________________
   - Tertawa/menangis/emosi: ____________________________
   - Membaca cepat/melewat: _____________________________
---------------------------------------------------------
G. BUG / MASALAH TEKNIS
   _____________________________________________________
   _____________________________________________________
---------------------------------------------------------
H. KUTIPAN LANGSUNG (verbatim, penting untuk 6.3)
   "___________________________________________________"
   "___________________________________________________"
---------------------------------------------------------
I. ADEGAN SENSITIF — CATATAN KHUSUS (dari Bagian B wawancara)
   Merasa aman (1-5)                : ___
   Momen terlalu berat (sebut)      : ___________________
   Kesan meromantisasi (ya/tidak)   : ___
   S06 terasa "damai/logis"? (1-5)  : ___
   Opsi lewati mudah ditemukan(1-5): ___
   Menu Bantuan terjangkau (1-5)    : ___
   Butuh jeda/berhenti? (ya/tidak)  : ___
=========================================================
```

---

## 4. Kriteria "Siap" & Cara Merangkum untuk Fase 6.3

### 4.1 Definisi "Siap" (kapan Bab 1 boleh lanjut ke tinjauan 6.2 & revisi 6.3)
Sesi dinyatakan **selesai & sah** bila:
- [ ] **≥5 pemain** (target 5-10) benar-benar memainkan Bab 1 sampai S08.
- [ ] **≥2 pemain** menguji jalur **"Lewati adegan sensitif"** (S06-ALT).
- [ ] Setiap pemain mengisi/menyelesaikan Lembar Catatan (§3) dengan wawancara §2 (minimal Bagian A, B, G).
- [ ] Semua jawaban Bagian B (sensitif) tercatat, termasuk **B5/B6 (romantisasi)** dan **B9/B10 (opsi lewati)**.

Bab 1 dinyatakan **"siap rilis demo"** (dari sisi playtest) bila **tidak ada temuan kritis**:
- [ ] **Tidak ada** temuan yang menunjukkan game **meromantisasi/menormalkan** kematian (B5/B6/B7 = semua menjawab "tidak").
- [ ] **Mayoritas** pemain (≥80%) merasa **aman** (B1 ≥ 4) dan **tidak dimanipulasi** (B3 ≤ 2).
- [ ] **Semua** pemain tahu cara berhenti & menemukan Menu Bantuan saat diminta.
- [ ] **Tidak ada bug blocker** (tidak bisa lanjut / crash) yang menghalangi penyelesaian Bab 1.
- [ ] Opsi "Lewati adegan sensitif" **berfungsi** dan mudah ditemukan (B10 ≥ 4 oleh pemain yang memakainya).

> Bila ada **satu saja** temuan kritis keselamatan → **JANGAN** nyatakan siap; bawa ke
> Fase 6.2 (tinjauan psikolog/konselor/penyintas) dan revisi 6.3 lebih dulu.

### 4.2 Klasifikasi Temuan
| Tingkat | Definisi | Aksi |
|---|---|---|
| **KRITIS (K)** | Pelanggaran SAFETY (meromantisasi, metode/detail cara, adegan jatuh, pemain merasa tidak aman/dimanipulasi) | Blok rilis demo; wajib 6.2 + perbaikan 6.3 |
| **MAYOR (M)** | Menghambat pemahaman/penyelesaian, kebingungan navigasi berulang, UI tak terbaca, tempo merusak emosi | Perbaiki di 6.3 sebelum demo |
| **MINOR (m)** | Polish: kalimat kaku, SFX telat, preferensi kecil | Kumpulkan untuk 6.3, boleh ditunda |
| **POSITIF (+)** | Yang berhasil & harus dipertahankan | Catat agar tidak rusak saat revisi |

### 4.3 Tabel Rangkuman Temuan (template)
| # | Adegan | Tingkat | Temuan (ringkas) | Bukti (kutipan/kode pemain) | Usul perbaikan | Pemilik |
|---|---|---|---|---|---|---|
| 1 | | K/M/m/+ | | | | |
| 2 | | | | | | |

### 4.4 Ringkasan Eksekutif (template 1 halaman, isi untuk 6.3)
```
RINGKASAN PLAYTEST 6.1 — Bab 1 "Hening"
Pemain diuji   : __ orang (kode: ____)   | Jalur lewati: __ orang
Build/commit   : __________              | Rentang tanggal: ______

1) KEAMANAN ADEGAN SENSITIF (S03, S05-S07)
   - Merasa aman    : __/__ pemain (rata-rata B1 = __)
   - Meromantisasi  : [ ] tidak ada temuan   [ ] ada (jelaskan)
   - Opsi lewati    : mudah ditemukan? [ ] ya [ ] tidak (rata-rata B10 = __)
   - Menu Bantuan   : terjangkau? [ ] ya [ ] tidak
   -> KESIMPULAN KEAMANAN: [ ] AMAN untuk lanjut ke 6.2  [ ] PERLU PERBAIKAN SEGERA

2) TEMPO & NAVIGASI
   - Rata-rata durasi build: __ menit (target 15-20)
   - Adegan paling lambat/cepat: ______
   - Titik kebingungan navigasi terbanyak: ______

3) UI / AKSESIBILITAS / AUDIO
   - Isu utama: ______

4) TEMUAN KRITIS (bila ada): ______   -> wajib 6.2 & 6.3
5) TOP-3 REKOMENDASI UNTUK 6.3: 1. ___  2. ___  3. ___
6) YANG HARUS DIPERTAHANKAN (+): ______
```

### 4.5 Alur Serah-Terima ke Fase 6.2 & 6.3
1. **Kumpulkan** semua Lembar Catatan (§3) + tabel §4.3 + ringkasan §4.4 dalam folder
   `docs/playtest/` (mis. `docs/playtest/sesi-YYYYMMDD/`).
2. **Saring temuan KRITIS** → jadikan lampiran khusus untuk **Fase 6.2** (tinjauan
   psikolog/konselor/penyintas). Jangan menandai 6.2 selesai sebelum tinjauan nyata.
3. **Petakan** tiap temuan MAYOR/MINOR ke kartu revisi **Fase 6.3** (satu temuan,
   satu tindakan; bila menyentuh naskah → butuh persetujuan pemilik, AGENTS.md aturan 2).
4. **Verifikasi ulang** setelah revisi: bila ada perubahan pada adegan sensitif,
   ulangi minimal Bagian B (§2) dengan 1-2 pemain.
5. **Perbarui TASKS.md**: tandai 6.1 `[x]` **hanya setelah** seluruh kriteria §4.1
   terpenuhi dan lembar terisi. (Bot tidak menandai ini.)

---

## Lampiran A — Skrip Pembuka Fasilitator (dibacakan)

> "Terima kasih sudah membantu. Kamu akan memainkan Bab 1 dari game naratif bertema
> kesehatan mental, durasi sekitar 15-20 menit. Game ini membahas depresi, rasa
> bersalah, dan pikiran untuk mengakhiri hidup — ada adegan yang menyiratkan percobaan
> bunuh diri, **tidak ditampilkan secara grafis**. Kamu **boleh berhenti kapan saja**,
> tanpa alasan, tanpa penalti. Ada Menu Bantuan berisi sumber bantuan yang selalu bisa
> diakses. Aku akan diam selama kamu bermain dan mencatat; setelah selesai, aku akan
> bertanya beberapa hal. Kalau kapan pun kamu ingin berhenti, bilang saja. Apakah kamu
> bersedia lanjut?"

## Lampiran B — Pemetaan Adegan → Tujuan Emosional (untuk observer)
| Adegan | Inti | Sensitif? |
|---|---|---|
| S00 | Content warning + judul | — |
| S01 | Monolog mata tertutup (kesepian) | ringan (baris 6 "mengakhiri malam") |
| S02 | Eksplorasi 8 objek (penghindaran) | — |
| **S03** | Percakapan dengan Suara Dalam | **YA** (pikiran menekan) |
| S04a/S04 | Rooftop, menuju tepi | **YA** (baris "menghilang di bawahnya") |
| **S05** | Satu pilihan [Lompat] + timer | **YA** |
| **S06** | Lompat — siluet → hitam, tanpa jatuh | **YA (paling sensitif)** |
| **S06-ALT** | Versi lewati (ringkasan + fade) | pengaman |
| **S07** | Kilas balik rasa bersalah | **YA** (ringan) |
| S08 | Bangun lagi + pesan misterius (hook) | — |

## Lampiran C — Checklist Kepatuhan Keamanan saat Observasi (SAFETY §7)
Observer memverifikasi saat sesi berlangsung:
- [ ] Tidak ada adegan jatuh/benturan/derah/tubuh yang tampil.
- [ ] Tidak ada metode/detail cara melukai diri dalam teks/visual.
- [ ] Content Warning muncul & butuh konfirmasi sebelum main.
- [ ] Menu Bantuan ada di menu utama **dan** menu jeda.
- [ ] Opsi "Lewati adegan sensitif" berfungsi (uji jalur S06-ALT).
- [ ] Tidak ada teks yang meromantisasi kematian.
- [ ] Tidak ada permintaan akses file/kamera/mikrofon/jaringan.
- [ ] Game tidak menyalahkan pemain yang berhenti.

---

*Instrumen ini disiapkan oleh xeon (QA) untuk Fase 6.1. Pelaksanaan sesi, pengisian
lembar, dan keputusan "siap" adalah tanggung jawab manusia. Fase 6.1 TIDAK ditandai
selesai oleh dokumen ini.*
