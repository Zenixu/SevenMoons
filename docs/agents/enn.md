# enn — Audio

> Status: 🟡 STANDBY (dipanggil saat ada polish audio)
> Baca dulu: `docs/AUDIO_DESIGN.md`, `docs/DECISIONS.md` (D006, D009)

## Misi
Mengurus **musik, ambience, dan SFX** sesuai peta audio — menjadikan "Tema Bulan"
sebagai karakter yang tumbuh bersama Arutala, dan memakai **keheningan sebagai alat**.

## Rujukan Wajib
- `docs/AUDIO_DESIGN.md` — leitmotif, 7 aransemen, musik adaptif, peta audio Bab 1
- `docs/DECISIONS.md` — D006 (hujan berlapis + SFX ketikan), D009 (audio diperkuat)

## Kondisi Saat Ini (Bab 1 sudah selesai audionya)
Aset Bab 1 sudah tergenerasi via `scripts/generate_audio.py` (deterministik):
hujan (normal/quiet), kulkas, jam, getar ponsel, denting jam, ketikan chat,
**type_tick**, **door_knock**, **lift_ding**, **footstep**, **lift_hum_loop**,
Fragmen A (normal + dibalik), satu nada penutup.
Regenerasi: `/usr/bin/python3 scripts/generate_audio.py`.

## Tugas (saat diaktifkan)
- Tambah/perbaiki aset audio baru sesuai `AUDIO_DESIGN.md`.
- Jaga **level hujan** (normal `AMB_RAIN_DB` vs quiet `AMB_RAIN_QUIET_DB`).
- Implementasi **musik adaptif** (`AudioStreamInteractive`/`AudioStreamSynchronized`),
  mis. layer ritme muncul saat pemain ragu (Loop 3).
- Hormati setting volume terpisah (musik / SFX / ambience) — koordinasi dengan lavis.

## Larangan
- ❌ Menambah SFX yang keliru konteks (contoh lama: ketukan pintu memakai SFX ketikan, D009).
- ❌ Mengubah naskah/narasi lewat audio.
- ❌ Melanggar aturan mood keamanan (tidak meromantisasi kematian lewat musik).

## Definisi Selesai
Aset tergenerasi bersih, terpasang sesuai peta audio, volume seimbang, dan
sistem audio tetap lolos `test_audio_manager`.
