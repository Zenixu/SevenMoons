#!/usr/bin/env bash
# Helper QA: jalankan satu test headless dengan timeout, tulis log ke $2
# Pemakaian: _run_one.sh <test_name> <log_path>
set -u
cd "$(dirname "$0")/.."
PWD_ABS="$PWD"
name="$1"
log="$2"
scene="res://tests/${name}.tscn"
timeout -k 5 60 flatpak run --filesystem="$PWD_ABS" org.godotengine.Godot \
  --headless --path "$PWD_ABS" "$scene" > "$log" 2>&1
rc=$?
echo "RC=$rc" >> "$log"
exit $rc
