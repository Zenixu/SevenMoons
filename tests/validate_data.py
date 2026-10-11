#!/usr/bin/env python3
"""Validator data Chapter 1 (mikha) — konsistensi kunci & format JSON.

Memeriksa:
  1. chapter_01.json valid & sesuai format resmi (tipe step didukung; teks lewat kunci).
  2. Semua kunci yang dipakai chapter_01.json / skrip / scene ada di id.csv.
  3. Kunci id.csv yang tidak direferensikan apa pun (kandidat usang).
  4. Urutan adegan JSON mengikuti rantai naskah (next_scene).

Jalankan: python3 tests/validate_data.py
Keluar 0 bila tidak ada masalah keras (kunci hilang / step tak dikenal).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(ROOT, "data/localization/id.csv")
JSON = os.path.join(ROOT, "data/chapters/chapter_01.json")

SUPPORTED_STEPS = {
    "narration", "line", "pause", "choice", "set_flag", "ui",
    "sfx", "bgm", "vfx", "next_scene", "chat_message", "text_input",
}
TEXT_FIELDS = ("text", "prompt")
# Nilai yang memang bukan kunci (identifiers/values, bukan teks tampil).
NON_KEY = {"ARU", "SUARA"}  # speaker: diharapkan ada sebagai kunci tampil

errors = []
warnings = []


def load_csv_keys():
    keys = {}
    with open(CSV, encoding="utf-8") as f:
        lines = f.read().splitlines()
    header = lines[0]
    for ln in lines[1:]:
        if not ln.strip():
            continue
        key = ln.split(",", 1)[0]
        keys[key] = ln
    return header, keys


def collect_json_keys(chap):
    """Semua kunci teks + tipe step + speaker/sender + urutan scene."""
    text_keys = {}
    step_types = set()
    speakers = set()
    senders = set()

    def walk(o):
        if isinstance(o, dict):
            t = o.get("type")
            if isinstance(t, str):
                step_types.add(t)
            if t == "line" and "speaker" in o:
                speakers.add(o["speaker"])
            if t == "chat_message" and "sender" in o:
                senders.add(o["sender"])
            for k, v in o.items():
                if k in TEXT_FIELDS and isinstance(v, str):
                    text_keys.setdefault(v, 0)
                    text_keys[v] += 1
                walk(v)
        elif isinstance(o, list):
            for i in o:
                walk(i)

    walk(chap)
    return text_keys, step_types, speakers, senders


KEY_RE = re.compile(r'"([A-Z][A-Z0-9]*_[A-Z0-9_]+)"')


def collect_code_keys():
    """Kunci bergaya S01_N01 / UI_* / LIFT_* dsb. yang muncul di .gd/.tscn."""
    refs = {}
    for dirpath, _, files in os.walk(ROOT):
        if "/.git" in dirpath or "/.godot" in dirpath or "/__pycache__" in dirpath:
            continue
        for fn in files:
            if not fn.endswith((".gd", ".tscn")):
                continue
            p = os.path.join(dirpath, fn)
            rel = os.path.relpath(p, ROOT)
            if rel.startswith("tests/"):
                continue  # fixture uji, bukan konten game
            txt = open(p, encoding="utf-8", errors="replace").read()
            for m in KEY_RE.finditer(txt):
                refs.setdefault(m.group(1), set()).add(rel)
    return refs


def main():
    header, csv_keys = load_csv_keys()
    with open(JSON, encoding="utf-8") as f:
        chap = json.load(f)

    print("== VALIDATOR DATA CHAPTER 1 ==")
    print("CSV header   :", header)
    print("CSV keys     :", len(csv_keys))

    text_keys, step_types, speakers, senders = collect_json_keys(chap)

    # 1. Tipe step
    unknown = sorted(step_types - SUPPORTED_STEPS)
    if unknown:
        errors.append("Tipe step tak didukung di chapter_01.json: %s" % unknown)
    print("Step types   :", sorted(step_types))
    print("Speaker      :", sorted(speakers))
    print("Chat sender  :", sorted(senders))

    # 2. Semua kunci JSON ada di CSV
    missing_json = sorted(k for k in text_keys if k not in csv_keys)
    if missing_json:
        errors.append("Kunci JSON tak ada di id.csv: %s" % missing_json)
    print("JSON text keys:", len(text_keys))

    # 3. Speaker harus punya kunci tampil
    for sp in sorted(speakers):
        if sp not in csv_keys:
            errors.append("Kunci speaker '%s' tak ada di id.csv" % sp)

    # 4. Kunci skrip/scene
    code_refs = collect_code_keys()
    missing_code = {k: v for k, v in code_refs.items() if k not in csv_keys}
    if missing_code:
        for k, v in sorted(missing_code.items()):
            errors.append("Kunci skrip/scene '%s' tak ada di id.csv (%s)" % (k, ", ".join(sorted(v))))

    # 5. Urutan rantai scene
    scenes = chap["scenes"]
    order = list(scenes.keys())
    print("Scene order  :", order)
    for sid, data in scenes.items():
        for step in data.get("steps", []):
            if step.get("type") == "next_scene":
                tgt = step.get("target")
                if tgt not in scenes:
                    errors.append("next_scene %s -> %s tidak ada" % (sid, tgt))
        if "next" in data and data["next"] not in scenes:
            errors.append("scene %s.next -> %s tidak ada" % (sid, data["next"]))

    # 6. Kunci CSV tak terpakai
    used = set(text_keys) | set(code_refs) | speakers | senders
    unused = sorted(k for k in csv_keys if k not in used)
    if unused:
        warnings.append("Kunci id.csv tak direferensikan (%d): %s" % (len(unused), ", ".join(unused)))

    print()
    if warnings:
        for w in warnings:
            print("WARN :", w)
    if errors:
        print()
        for e in errors:
            print("ERROR:", e)
        print("\nHASIL: GAGAL (%d masalah)" % len(errors))
        return 1
    print("\nHASIL: OK — format JSON valid, semua kunci terpakai tersedia di id.csv.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
