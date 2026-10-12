#!/usr/bin/env bash
# run_tests.sh — jalankan seluruh suite uji Godot secara headless.
# Pemakaian: ./run_tests.sh
set -u
cd "$(dirname "$0")"

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  # Fallback: Godot via flatpak
  GODOT_RUN=(flatpak run --filesystem="$PWD" org.godotengine.Godot)
else
  GODOT_RUN=("$GODOT_BIN")
fi

TESTS=(
  test_flag_store
  test_settings_manager
  test_save_system
  test_audio_manager
  test_loop_manager
  test_dialogue_runner
  test_ui
  test_intro
  test_corridor
  test_reachability
  test_chapter1_scenes
  test_chapter1_full
  test_chapter1_data
  test_flow_s00_s08
  test_ui_accessibility
  test_pause_and_warning
  test_choice_menu_geometry
  test_phone_gate
  test_route_room_rooftop
)

# Batas waktu per-test (detik). Mencegah suite menggantung selamanya bila
# sebuah scene uji lupa memanggil get_tree().quit().
TEST_TIMEOUT="${TEST_TIMEOUT:-60}"

pass=0; fail=0; failed_names=()
for t in "${TESTS[@]}"; do
  scene="res://tests/${t}.tscn"
  if [ ! -f "tests/${t}.tscn" ]; then
    echo "SKIP  $t (scene tidak ada)"; continue
  fi
  # timeout membatasi tiap scene; bila habis -> exit 124 (dianggap gagal).
  out="$(timeout -k 5 "$TEST_TIMEOUT" "${GODOT_RUN[@]}" --headless --path "$PWD" "$scene" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ] && echo "$out" | grep -q "LULUS\|SELESAI\|SEMUA TEST"; then
    echo "PASS  $t"; pass=$((pass+1))
  else
    if [ "$rc" -eq 124 ]; then
      echo "FAIL  $t (timeout ${TEST_TIMEOUT}s — scene tidak memanggil get_tree().quit())"
    else
      echo "FAIL  $t (exit=$rc)"
    fi
    fail=$((fail+1)); failed_names+=("$t")
    echo "$out" | tail -12 | sed 's/^/      /'
  fi
done

echo "-----------------------------------------"
echo "HASIL: ${pass} lulus, ${fail} gagal (total $((pass+fail)))"
if [ "$fail" -gt 0 ]; then
  echo "GAGAL: ${failed_names[*]}"
  exit 1
fi
