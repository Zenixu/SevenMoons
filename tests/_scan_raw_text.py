#!/usr/bin/env python3
"""Pindai teks mentah (belum lewat lokalisasi) yang tampil di UI.

Fokus: nilai default node `.tscn` (text/placeholder_text) dan string literal
di skrip `.gd` yang berpotensi tampil ke pemain tanpa `tr()`.

Bukan bagian suite game; alat bantu laporan ke lavis.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# String yang jelas bukan teks tampil (kunci, path, nama node, format).
def looks_like_key(s):
    return bool(re.fullmatch(r"[A-Z][A-Z0-9]*_[A-Z0-9_]+", s))

def looks_like_path(s):
    return s.startswith("res://") or s.startswith("user://") or "/" in s or "." in s and s.split(".")[-1] in {"png","tscn","gd","json","wav","csv","tres","gdshader"}

print("== .tscn: nilai default text/placeholder_text ==")
for dirpath, _, files in os.walk(os.path.join(ROOT, "scenes")):
    for fn in sorted(files):
        if not fn.endswith(".tscn"):
            continue
        p = os.path.join(dirpath, fn)
        rel = os.path.relpath(p, ROOT)
        for i, line in enumerate(open(p, encoding="utf-8", errors="replace"), 1):
            m = re.match(r'\s*(text|placeholder_text)\s*=\s*"(.*)"\s*$', line)
            if m and m.group(2).strip():
                print(f"  {rel}:{i}  {m.group(1)} = \"{m.group(2)}\"")

print()
print("== .gd: string literal berhuruf yang mungkin teks tampil ==")
lit_re = re.compile(r'"([^"\\]{3,})"')
for dirpath, _, files in os.walk(os.path.join(ROOT, "scripts")):
    for fn in sorted(files):
        if not fn.endswith(".gd"):
            continue
        p = os.path.join(dirpath, fn)
        rel = os.path.relpath(p, ROOT)
        for i, line in enumerate(open(p, encoding="utf-8", errors="replace"), 1):
            s = line.strip()
            if s.startswith("#"):
                continue
            for m in lit_re.finditer(line):
                v = m.group(1)
                if looks_like_key(v) or looks_like_path(v):
                    continue
                # Lewati nama node/path internal (mengandung '/', '$', '%').
                if any(c in v for c in ("/", "$", "%", "\\n", ":")):
                    continue
                # Heuristik: mengandung huruf & spasi atau kata Indonesia.
                if re.search(r"[A-Za-z]", v) and (" " in v or len(v) > 3):
                    print(f"  {rel}:{i}  \"{v}\"")
