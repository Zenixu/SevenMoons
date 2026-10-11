#!/usr/bin/env bash
# Helper QA: jalankan satu test headless dengan timeout, tulis log ke $2
# Pemakaian: _run_one.sh <test_name> <log_path>
set -u
cd "$(dirname "$0")/.."
PWD_ABS="$PWD"
name="$1"
log="$2"
scene="res://tests/${name}.tscn"

# Utamakan Godot native; fallback ke flatpak bila tidak terpasang.
if command -v godot >/dev/null 2>&1; then
  GODOT_RUN=(godot)
else
  GODOT_RUN=(flatpak run --filesystem="$PWD_ABS" org.godotengine.Godot)
fi

timeout -k 5 60 "${GODOT_RUN[@]}" \
  --headless --path "$PWD_ABS" "$scene" > "$log" 2>&1
rc=$?
echo "RC=$rc" >> "$log"
exit $rc
