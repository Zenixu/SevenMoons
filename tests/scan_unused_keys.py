#!/usr/bin/env python3
"""Pemindai kunci `id.csv` vs rujukan di scripts/, scenes/, data/ (mikha).

Alat audit (bukan bagian suite game). Tujuan: mengklasifikasi SETIAP kunci
lokalisasi menjadi "dipakai" atau "tak direferensikan" agar kunci mati/usang
terdeteksi lebih awal.

Sumber rujukan (produksi):
  - scripts/**/*.gd, scenes/**/*.tscn  -> literal kunci ber-format KEY_RE
  - data/chapters/*.json               -> nilai `text`/`prompt` + `speaker`/`sender`
Sumber rujukan "hanya uji" (dilaporkan terpisah, tidak dianggap produksi):
  - tests/**/*.gd, tests/**/*.tscn

Jalankan: python3 tests/scan_unused_keys.py
Selalu keluar 0 (ini laporan, bukan gerbang keras).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(ROOT, "data/localization/id.csv")
CHAPTERS_DIR = os.path.join(ROOT, "data/chapters")

# Kunci ber-format S01_N01 / UI_* / LIFT_* / CORRIDOR_* dsb.
KEY_RE = re.compile(r'"([A-Z][A-Z0-9]*_[A-Z0-9_]+)"')
TEXT_FIELDS = ("text", "prompt")


def load_csv():
    """Kembalikan (header, {key: value}, [key berurutan])."""
    with open(CSV, encoding="utf-8") as f:
        lines = f.read().splitlines()
    header = lines[0]
    keys = {}
    order = []
    for ln in lines[1:]:
        if not ln.strip():
            continue
        key = ln.split(",", 1)[0]
        val = ln.split(",", 1)[1] if "," in ln else ""
        keys[key] = val
        order.append(key)
    return header, keys, order


def scan_text_files(root_dirs, suffixes, skip_prefixes=()):
    refs = {}
    for root_dir in root_dirs:
        for dirpath, _, files in os.walk(root_dir):
            if any(s in dirpath for s in ("/.git", "/.godot", "/__pycache__")):
                continue
            for fn in files:
                if not fn.endswith(suffixes):
                    continue
                p = os.path.join(dirpath, fn)
                rel = os.path.relpath(p, ROOT)
                if any(rel.startswith(pref) for pref in skip_prefixes):
                    continue
                txt = open(p, encoding="utf-8", errors="replace").read()
                for m in KEY_RE.finditer(txt):
                    refs.setdefault(m.group(1), set()).add(rel)
    return refs


def scan_chapters():
    """Kunci teks/prompt + speaker/sender dari data/chapters/*.json."""
    refs = {}
    for fn in sorted(os.listdir(CHAPTERS_DIR)):
        if not fn.endswith(".json"):
            continue
        rel = os.path.relpath(os.path.join(CHAPTERS_DIR, fn), ROOT)
        with open(os.path.join(CHAPTERS_DIR, fn), encoding="utf-8") as f:
            chap = json.load(f)

        def walk(o):
            if isinstance(o, dict):
                for k, v in o.items():
                    if k in TEXT_FIELDS and isinstance(v, str):
                        refs.setdefault(v, set()).add(rel)
                    # `speaker`/`sender` biasanya KUNCI lokalisasi (ARU, SUARA),
                    # tetapi bisa juga label tampil apa adanya (mis. "???" untuk
                    # nomor tak dikenal) — hanya anggap kunci bila HURUF BESAR semua.
                    if k in ("speaker", "sender") and isinstance(v, str) and re.fullmatch(r"[A-Z][A-Z0-9_]*", v):
                        refs.setdefault(v, set()).add(rel)
                    walk(v)
            elif isinstance(o, list):
                for i in o:
                    walk(i)

        walk(chap)
    return refs


def main():
    header, keys, order = load_csv()
    prod = {}
    for src in (
        scan_text_files([os.path.join(ROOT, "scripts")], (".gd",)),
        scan_text_files([os.path.join(ROOT, "scenes")], (".tscn",)),
        scan_chapters(),
    ):
        for k, v in src.items():
            prod.setdefault(k, set()).update(v)
    tests_refs = scan_text_files(
        [os.path.join(ROOT, "tests")], (".gd", ".tscn")
    )

    missing = sorted(k for k in prod if k not in keys)
    unused = [k for k in order if k not in prod]
    test_only = [k for k in unused if k in tests_refs]
    dead = [k for k in unused if k not in tests_refs]

    print("== PEMINDAI KUNCI id.csv ==")
    print("CSV header        :", header)
    print("Total kunci CSV   :", len(keys))
    print("Kunci dirujuk     :", len(keys) - len(unused))
    print("Tak direferensikan:", len(unused))
    print()
    if missing:
        print("!! Kunci dipakai tapi TAK ADA di CSV (%d):" % len(missing))
        for k in missing:
            print("   %-24s <- %s" % (k, ", ".join(sorted(prod[k]))))
        print()
    if dead:
        print("KUNCI MATI (tak dirujuk produksi MAUPUN uji) (%d):" % len(dead))
        for k in dead:
            print("   %-24s = %s" % (k, keys[k]))
        print()
    if test_only:
        print("HANYA dirujuk uji (probe) — bukan produksi (%d):" % len(test_only))
        for k in test_only:
            print("   %-24s <- %s" % (k, ", ".join(sorted(tests_refs[k]))))
        print()
    if not dead and not test_only and not missing:
        print("Bersih: semua kunci CSV dirujuk, tak ada kunci hilang.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
