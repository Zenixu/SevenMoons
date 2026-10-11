#!/usr/bin/env bash
# _qa_run_all.sh — QA harness: jalankan tiap test headless dengan timeout,
# deteksi status keluar sendiri vs menggantung, dan cetak ringkasan.
# Pemakaian: tests/_qa_run_all.sh [timeout_detik]
set -u
cd "$(dirname "$0")/.."
ROOT="$PWD"
TMO="${1:-45}"

# Utamakan Godot native; fallback ke flatpak bila tidak terpasang.
if command -v godot >/dev/null 2>&1; then
  GODOT_RUN=(godot)
else
  GODOT_RUN=(flatpak run --filesystem="$ROOT" org.godotengine.Godot)
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
)

mkdir -p /tmp/qa_logs
pass=0; fail=0; hang=0
for t in "${TESTS[@]}"; do
  scene="res://tests/${t}.tscn"
  log="/tmp/qa_logs/${t}.log"
  if [ ! -f "tests/${t}.tscn" ]; then
    echo "SKIP  $t (scene tidak ada)"; continue
  fi
  timeout -k 5 "$TMO" "${GODOT_RUN[@]}" \
    --headless --path "$ROOT" "$scene" > "$log" 2>&1
  rc=$?
  if grep -q "SEMUA TEST\|LULUS\|SELESAI" "$log"; then
    if [ "$rc" -eq 0 ]; then
      echo "PASS  $t (exit 0)"
    else
      echo "PASS* $t (cetak lulus TAPI exit=$rc -> menggantung, tidak quit())"
      hang=$((hang+1))
    fi
    pass=$((pass+1))
  else
    echo "FAIL  $t (exit=$rc)"
    fail=$((fail+1))
    sed 's/^/      /' "$log" | tail -15
  fi
done
echo "-----------------------------------------"
echo "HASIL: ${pass} lulus, ${fail} gagal (total $((pass+fail))); ${hang} test menggantung (tanpa quit())"
