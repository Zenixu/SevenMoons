# Bukti Perbaikan BUG-6 — `test_flow_s00_s08` flaky timeout (exit 137)

Kartu: `t_ce7adb8c` (xeon). Rujukan: `docs/review/AUDIT_XEON_CH1.md` §BUG-6.

## Perubahan (harness uji saja — tidak menyentuh perilaku game)
`tests/test_flow_s00_s08.gd`:
- Di `_ready()`: simpan `Engine.time_scale`, lalu set `Engine.time_scale = 6.0`
  (di samping `SettingsManager.text_speed = 100.0` yang sudah ada) sehingga
  seluruh timer/tween alur (`get_tree().create_timer`, tween mengetik,
  `player.auto_walk_to`) berjalan ~6x lebih cepat.
- Sebelum `get_tree().quit(0)`: pulihkan `Engine.time_scale` (dan `text_speed`).

Tidak ada perubahan pada `scripts/`, naskah, atau `run_tests.sh`.

## Dampak durasi
| Kondisi | Durasi |
|---|---|
| Sebelum (standalone, `timeout -k 5 120`) | ~59.3s (ambang 60s → flaky) |
| Sesudah (standalone) | **~11.1s** |

Selisih jauh di bawah `TEST_TIMEOUT=60` (margin ~49s), jadi tidak lagi flaky.

## Bukti: 5 kali `./run_tests.sh` berturut-turut
```
===== RUN 1 =====  HASIL: 17 lulus, 0 gagal (total 17)   SUITE_EXIT=0
===== RUN 2 =====  HASIL: 17 lulus, 0 gagal (total 17)   SUITE_EXIT=0
===== RUN 3 =====  HASIL: 17 lulus, 0 gagal (total 17)   SUITE_EXIT=0
===== RUN 4 =====  HASIL: 17 lulus, 0 gagal (total 17)   SUITE_EXIT=0
===== RUN 5 =====  HASIL: 17 lulus, 0 gagal (total 17)   SUITE_EXIT=0
```
Tidak ada `FAIL ... (exit=137)` pada satu pun run. `test_flow_s00_s08` selalu `PASS`.

## Catatan pengamatan tambahan
Pada satu run di tengah pekerjaan (saat sistem sangat terbebani — load average ~7
akibat `chrome` + satu proses `godot` audit lama yang bocor 17 menit), `test_dialogue_runner`
(yang normalnya ~2s) sempat di-SIGKILL di teardown (exit 137) meski log-nya LULUS.
Setelah proses bocor itu dimatikan, 5 run bersih berturut-turut di atas
mengonfirmasi suite stabil. Ini murni efek beban sistem, bukan regresi suite.
