# USULAN PERBAIKAN TEKS AMBIGU — Chapter 1

Kartu: `t_aa20eb1c` · Assignee: **kael** (Writer/Naskah)
Sumber temuan: permintaan pemilik *"ada bagian-bagian teks yang ambigu, coba benarkan lagi."*
Metode: baca ulang `docs/CHAPTER_01.md` + `data/localization/id.csv`, lalu **bandingkan
dengan teks yang benar-benar tampil ke pemain** (jalur `tr()` di `scripts/systems/*.gd`).

> **STATUS: USULAN — BELUM DIIMPLEMENTASI.**
> Kartu ini **tidak mengubah satu baris pun** naskah/dialog/urutan adegan/flag
> (AGENTS.md aturan 2). Semua baris di bawah menunggu **persetujuan pemilik**.
> Tidak ada berkas naskah yang disentuh pada commit ini.

## Cara membaca
Tiap usulan berformat **Kunci → Teks lama → Usulan → Alasan**. Kolom "Tampil?"
menandai apakah teks benar-benar dilihat pemain (lewat `tr()` di kode) atau hanya
ada di naskah/CSV.

Tingkat prioritas:
- **P1** — membuat pemain bingung / tampak seperti bug (sebaiknya diperbaiki).
- **P2** — kalimat panjang/kabur, melelahkan dibaca, atau istilah tak konsisten.
- **P3** — sentuhan halus / keputusan selera pemilik (boleh dibiarkan).

Sisi **data/CSV** (kunci usang, kunci tak direferensikan, nilai `...`) adalah ranah
**mikha** (kartu terpisah). Di sini hanya dicatat bila menyangkut kejelasan prosa.

---

## P1 — Ambigu/tampak seperti bug

### 1. `S02_O5_N01` — jam disebut "berhenti" padahal sudah berjalan
- **Tampil?** Ya. Muncul saat jam dinding **diperiksa ulang** (kode:
  `bedroom_controller.gd` → `_handle_clock()`, cabang `_clock_running == true`).
- **Teks lama:** `Jarumnya berhenti di angka satu. Seperti menungguku.`
- **Usulan:** `Jarum menitnya bergerak pelan sekarang. Sisanya masih diam.`
- **Alasan:** Teks ini hanya tampil **setelah** pemain pertama kali memeriksa jam —
  saat itu jarum menit **sudah mulai berjalan** (lihat `CLOCK_TICK`). Menulis
  "berhenti di angka satu" membuat pemain mengira jam masih beku → bertentangan
  dengan apa yang baru saja mereka lihat.

### 2. `CLOCK_START` — metafora kabur ("angka" yang bergerak)
- **Tampil?** Ya (`_handle_clock()`, pemeriksaan pertama).
- **Teks lama:** `Hanya satu angka yang berani bergerak. Sisanya diam.`
- **Usulan:** `Hanya jarum menit yang bergerak. Jarum jamnya diam.`
- **Alasan:** Jam punya **jarum**, bukan "angka" yang bergerak; pemain bisa
  bingung apa yang dimaksud "satu angka". Sekaligus menyiapkan `CLOCK_TICK`.

### 3. `S02_O6_RES_A` vs `S02_O6_CONFIRM` — pintu "ditarik kembali" tapi lalu bisa keluar
- **Tampil?** Ya (`_handle_door()`): setelah pemain memilih **"Coba buka"**.
- **Teks lama:**
  - `S02_O6_RES_A` = `Gagang pintu terasa dingin. Ia menariknya kembali.`
  - lalu langsung `S02_O6_CONFIRM` = `Lorong di luar dingin dan kosong. Keluar sekarang?`
  - dan bila "Keluar": `S02_O6_LEAVE` = `Kunci berputar pelan. Aku melangkah ke lorong.`
- **Usulan (RES_A):** `Gagang pintu terasa dingin di tanganku.`
- **Alasan:** `RES_A` berkata ia **menarik tangannya kembali** (= tidak membuka),
  tetapi langkah berikutnya justru menawarkan "Keluar sekarang?" dan pemain bisa
  benar-benar keluar ke lorong. Pertentangan ini membuat pemain bingung apakah pintu
  terbuka atau tidak. Menghapus "menariknya kembali" membuat alur RES_A → CONFIRM → LEAVE
  jadi mulus. (Frasa "menariknya kembali" lebih pas bila dipindah ke cabang **batal**.)
- **Catatan naskah:** `docs/CHAPTER_01.md` baris 54 menulis *"Pintu apartemen: Terkunci
  secara naratif"* dan baris 109 *"(Pintu tidak terbuka di Loop 1…)"* — **berlawanan**
  dengan perilaku yang diimplementasi (pintu **bisa** dibuka → lorong, ditambahkan di
  Fase 5.6). Naskah perlu diselaraskan **atau** pintu dibatasi; ini keputusan pemilik.

### 4. Jam 01:00 vs 02:47 — dua jam yang saling bertentangan (tak pernah dijelaskan)
- **Tampil?** Ya, tersebar.
- **Fakta di pemain:**
  - Header `CHAPTER_01.md` & `GAME_DESIGN.md` & `STORY_BIBLE.md`: jam dalam game **02:47**.
  - S01: HUD jam kecil di pojok = **01:00**; narasi `[NARASI] Jam di dinding berhenti di angka satu.`
  - S08: `Jam 02:47`.
- **Alasan:** Pemain melihat **01:00** di awal, tetapi cerita menyebut **02:47**, dan
  naskah O5 lama justru menunjuk pertentangan itu (`Mana yang benar?`) **tanpa pernah
  menyelesaikannya**. Ini sumber kebingungan nyata ("jam mana yang benar?").
- **Usulan (prosa, tanpa mengubah alur):** perjelas bahwa jam dinding adalah jam yang
  **rusak/mati**, sedangkan jam kecil di HUD adalah waktu nyata. Contoh narasi S01:
  `Jam dinding berhenti di angka satu. Jam kecil di pojok masih menghitung.`
  *(Alternatif: selaraskan angkanya menjadi 02:47 sejak S01 — **keputusan pemilik**,
  karena menyangkut fakta cerita, bukan sekadar redaksi.)*

---

## P2 — Kalimat panjang/kabur atau istilah tak konsisten

### 5. `ROOFTOP_WALK_1` — tiga pertanyaan dalam satu tarikan napas
- **Tampil?** Ya (`balcony_controller.gd` → `_arrive_then_start()`).
- **Teks lama:** `Apakah ini pilihan yang tepat? Apakah semua ini adalah jawaban dari
  segalanya? Apa aku akan bebas dengan semua hal yang sudah kurenggut, sekaligus rasa
  bersalah yang kian hari semakin terasa di diriku?`
- **Usulan (dipecah, gaya kalimat pendek):**
  > Apakah ini pilihan yang tepat?
  > Apakah semua ini jawabannya?
  > Aku ingin bebas. Tapi rasa bersalah ini justru makin berat.
- **Alasan:** Kalimat lama ~35 kata dalam satu baris, melanggar Gaya Teks Game
  ("kalimat pendek, boleh terputus"). Frasa *"bebas dengan semua hal yang sudah
  kurenggut"* ambigu (bebas **dari** hal itu, atau bebas **karena** itu?), dan
  *"kian hari semakin"* berlebihan. Usulan mempertahankan makna (keraguan + rasa
  bersalah) tanpa mengubah cerita.
- **Tambahan:** `ROOFTOP_WALK_1` mengulang persis kalimat pembuka `LIFT_ENTER`
  (*"Apakah ini pilihan yang tepat?"*) hanya beberapa detik sebelumnya → terasa
  seperti pengulangan/bug. Sebaiknya salah satu dibedakan (lihat #6).

### 6. `LIFT_ENTER` — pertanyaan menggantung saat masuk lift
- **Tampil?** Ya (`lift_controller.gd` → `_enter_lift()`).
- **Teks lama:** `Apakah ini pilihan yang tepat? ...`
- **Usulan:** `Ke atas lagi. Entah ini pilihan yang tepat atau bukan.`
- **Alasan:** Kalimat menggantung (`...`) + pertanyaan retoris yang **objeknya tidak
  jelas** (pilihan apa? pemain belum memilih apa pun — baru masuk lift). Juga duplikat
  #5. Usulan menyebut konteksnya (naik ke atas) agar jelas, tanpa mengubah maksud.

### 7. Istilah "balkon" vs "atap/rooftop" — tidak konsisten
- **Tampil?** Ya, di beberapa tempat.
  - `UI_PROMPT_BALCONY` = `Ada udara dingin dari arah balkon.` (kamar)
  - Judul naskah S04 = *"Menuju Balkon (bulan)"*, tetapi latar S04 = *"Tepi atap, dekat pager."*
  - Naskah S04a = *"Tiba di Rooftop (lantai 5)"*.
  - Scene teknis bernama `balcony.tscn` tetapi isinya **atap gedung lantai 5**.
- **Alasan:** Pemain dituntun ke **"balkon"** tetapi tiba di **atap gedung** yang dicapai
  lewat **lift lantai 5** — dua hal berbeda secara spasial. Pemain bisa bingung "ini
  balkon apartemenku atau atap gedung?".
- **Usulan:** Pilih **satu** istilah untuk teks yang dilihat pemain dan pakai konsisten
  (mis. semua "atap", atau "balkon atap"). Bila pemilik ingin mempertahankan dua lokasi
  berbeda (balkon kamar ≠ atap lantai 5), perlu teks pembeda yang jelas. **Keputusan
  pemilik** (menyangkut penamaan/lokasi).
- **Koordinasikan dengan mikha:** ada 3 kunci `ROOFTOP_ARRIVE`, `ROOFTOP_ARRIVE2`,
  `ROOFTOP_ARRIVE3` yang **tidak dipakai** padahal bunyinya lebih jelas
  (mis. *"Lantai lima. Lift membawaku ke atap, bukan ke lorong."*) — mungkin lebih baik
  dipakai daripada `ROOFTOP_WALK_1`. Ini ranah data (mikha).

### 8. Naskah O5 (`docs/CHAPTER_01.md` baris 96–99) — versi yang tak pernah tampil
- **Tampil?** **Tidak.** Teks naskah ini tidak dipakai kode (kode memakai
  `CLOCK_START`/`CLOCK_TICK`/`S02_O5_N01`/`S02_O5_A01`).
- **Teks naskah lama:**
  - `[NARASI] Jarumnya tidak sama dengan jam di pojok layar.`
  - `[ARU] Mana yang benar?`
  - `[ARU] Nggak penting juga.`
- **Alasan:** Menimbulkan gagasan **dua jam yang saling bertentangan** yang tidak pernah
  dijelaskan (lihat #4), dan **berbeda** dari teks yang benar-benar dilihat pemain.
- **Usulan:** Selaraskan naskah O5 dengan implementasi (pakai `CLOCK_START`/`CLOCK_TICK`),
  **atau** bila memang ingin dua jam, tambahkan satu kalimat yang menuntaskan teka-teki itu.
  **Keputusan pemilik** (menyentuh isi naskah).

---

## P3 — Sentuhan halus / selera pemilik

### 9. Kunci `...` sebagai isi/opsi — sudah disengaja (tak diusulkan berubah)
- **Kunci:** `S01_N01`, `S02_O1_A01`, `S03_R1_OPT_C`, `S03_R3_OPT_A`, `ROOFTOP_WALK_2`.
- **Status:** mikha sudah memverifikasi **disengaja** sebagai isyarat hening/"diam"
  (`docs/review/VERIFIKASI_KUNCI_TITIK.md`). **Tidak diusulkan berubah.**
- **Catatan kejelasan (opsional, P3):** dua di antaranya adalah **tombol pilihan**
  (`S03_R1_OPT_C`, `S03_R3_OPT_A`). Tombol berisi `...` saja **bisa** dibaca pemain
  sebagai tombol belum termuat. Bila pemilik ingin lebih jelas, opsi bisa diberi label
  `(diam)` — namun ini **mengubah naskah yang sudah disetujui**, jadi biarkan apa adanya
  kecuali pemilik memutuskan lain. **Bukan bug.**

### 10. `S08_MSG_1/2/3` — "kamu" yang beralih sasaran (Arutala → pemain)
- **Tampil?** Ya (`bedroom_controller.gd` → `_start_s08_sequence()`).
- **Teks lama:** `kamu yang di sana.` / `iya. kamu. bukan dia.` /
  `dia belum selesai. dan aku rasa kamu juga belum.`
- **Alasan:** Sepanjang game "kamu" = **Arutala** (mis. `S02_O4_A01` = *"Kamu juga nggak
  tidur, ya."*). Di S08 pengirim misterius memakai "kamu" untuk **pemain**, sementara
  "dia" untuk Arutala. Peralihan sudut pandang ini bisa membingungkan siapa "kamu"/"dia".
- **Usulan:** **Pertahankan** (ini disengaja — "Bulan" berbicara ke pemain, lihat
  `STORY_BIBLE.md`). Bila ingin lebih jelas, cukup andalkan label pengirim `???` (sudah
  ada) dan/atau satu baris naskah yang menegaskan "bukan Arutala yang diajak bicara".
  **Keputusan pemilik**, P3.

### 11. `INTRO_CAP_1` vs `S01_INTRO_1` — "berhenti menghitung" vs "malam keberapa?"
- **Tampil?** Ya (keduanya).
  - `INTRO_CAP_1` = `Malam keberapa pun, aku berhenti menghitung.`
  - `S01_INTRO_1` = `Ah, sudah malam keberapa ini?`
- **Alasan:** Satu baris berkata ia **sudah berhenti menghitung**, baris lain justru
  **menanyakan** malam keberapa — terasa seperti ketidakkonsistenan (walau bisa dibaca
  sebagai lupa). P3.
- **Usulan (opsional):** `S01_INTRO_1` → `Ah, malam keberapa lagi ini?` atau biarkan
  sebagai nuansa. **Keputusan pemilik.**

### 12. `S02_O1_PREVIEW` — prefiks "Kirana:" ternyata perlu (bukan dobel)
- **Tampil?** Ya (`_handle_phone()`), lewat **ThoughtBox** (`display_thought`).
- **Teks lama:** `Kirana: Kamu masih di sana? Aku cuma mau bilang...`
- **Verifikasi:** pratinjau ini tampil di **kotak pikiran** (bukan gelembung chat),
  dan `ThoughtBox.display_thought()` **tidak** menambahkan nama pengirim. Jadi prefiks
  `"Kirana:"` **diperlukan** agar pemain tahu pesan itu dari siapa → **bukan dobel,
  tidak diusulkan berubah.** (Awalnya dicurigai dobel; setelah cek kode, aman.)

---

## Ringkasan untuk pemilik

| # | Kunci/berkas | Prioritas | Inti masalah | Usulan (ringkas) |
|---|---|---|---|---|
| 1 | `S02_O5_N01` | P1 | "berhenti" padahal sudah berjalan | "Jarum menitnya bergerak pelan sekarang…" |
| 2 | `CLOCK_START` | P1 | "angka" bergerak (kabur) | "Hanya jarum menit yang bergerak…" |
| 3 | `S02_O6_RES_A` + naskah O6 | P1 | pintu "ditarik kembali" tapi bisa keluar | "Gagang pintu terasa dingin di tanganku." |
| 4 | jam 01:00 vs 02:47 (S01/S08) | P1 | dua jam bertentangan, tak dijelaskan | bedakan jam rusak vs jam nyata |
| 5 | `ROOFTOP_WALK_1` | P2 | kalimat panjang, ambigu | pecah jadi 3 kalimat pendek |
| 6 | `LIFT_ENTER` | P2 | pertanyaan menggantung, duplikat | sebut konteks ("Ke atas lagi…") |
| 7 | "balkon" vs "atap/rooftop" | P2 | istilah tak konsisten | pilih satu istilah |
| 8 | naskah O5 (baris 96–99) | P2 | versi tak dipakai + teka-teki dua jam | selaraskan dengan implementasi |
| 9 | kunci `...` (5) | P3 | tombol "..." bisa tampak kosong | biarkan (disengaja) — catatan saja |
| 10 | `S08_MSG_1..3` | P3 | "kamu" beralih ke pemain | biarkan (disengaja) |
| 11 | `INTRO_CAP_1`/`S01_INTRO_1` | P3 | "berhenti menghitung" vs "keberapa?" | opsional |
| 12 | `S02_O1_PREVIEW` | — | dicek: prefiks "Kirana:" **perlu** (bukan dobel) | tidak diubah |

**Tidak ada perubahan naskah/dialog/urutan adegan/flag pada dokumen ini** — semuanya
usulan yang menunggu persetujuan pemilik. Setelah disetujui, perubahan diterapkan oleh
**mikha** (data `id.csv`/`chapter_01.json`) dan **lavis** (kode), bukan oleh kael.

### Koordinasi dengan mikha (ranah data — jangan tumpang tindih)
- `S01_N01..N03` usang (nilai `...`) — sudah dicatat di `QUESTIONS.md` (Q1).
- `ROOFTOP_ARRIVE*`, `CORRIDOR_LIFT_*`, `S02_O1_A01`, `S02_O5_A02`, dll. tak
  direferensikan — lihat `tests/validate_data.py` (WARN) & `VERIFIKASI_KUNCI_TITIK.md`.
- Bila usulan #5/#7 disetujui dan kunci berubah, **mikha** yang menyunting `id.csv`.

### Verifikasi
- `python3 tests/validate_data.py` → **OK** (exit 0), 186 kunci CSV, semua kunci
  terpakai tersedia. Tidak ada berkas data/naskah yang diubah.
