#!/usr/bin/env python3
"""SevenMoons — Pixel Art Generator v2
Gaya: OMORI / A Space for the Unbound (moody, outline tebal, palet terbatas).
Karakter ber-anatomi + spritesheet animasi (idle/walk 4 arah), props, background,
dan kilas balik.

Jalankan:  /usr/bin/python3 scripts/gen_art_v2.py
"""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

# ----------------------------------------------------------------------------
# Palet Loop 1 — biru kelabu gelap, sedikit cahaya hangat
# ----------------------------------------------------------------------------
P = {
    "outline":    (13, 15, 23, 255),
    "hair":       (46, 41, 53, 255),
    "hair_hi":    (78, 70, 86, 255),
    "hair_sh":    (30, 27, 37, 255),
    "skin":       (233, 203, 183, 255),
    "skin_sh":    (196, 163, 146, 255),
    "skin_hi":    (248, 224, 206, 255),
    "sweater":    (54, 84, 95, 255),
    "sweater_sh": (34, 57, 66, 255),
    "sweater_hi": (78, 114, 126, 255),
    "pants":      (56, 59, 80, 255),
    "pants_sh":   (38, 40, 56, 255),
    "pants_hi":   (72, 76, 98, 255),
    "shoe":       (26, 26, 36, 255),
    "shoe_hi":    (52, 53, 68, 255),
    "eye":        (18, 20, 28, 255),
}

FW, FH = 24, 40          # ukuran satu frame karakter
ANIMS = [                # (nama, baris, jumlah frame)
    ("idle_down", 0, 2), ("walk_down", 1, 4),
    ("idle_up",   2, 2), ("walk_up",   3, 4),
    ("idle_side", 4, 2), ("walk_side", 5, 4),
]


# ----------------------------------------------------------------------------
# Helper grid
# ----------------------------------------------------------------------------
def new_grid():
    return [[None for _ in range(FW)] for _ in range(FH)]


def px(g, x, y, c):
    if 0 <= x < FW and 0 <= y < FH and c is not None:
        g[y][x] = c


def rect(g, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(g, x, y, c)


def hline(g, x0, x1, y, c):
    for x in range(x0, x1 + 1):
        px(g, x, y, c)


def ellipse(g, cx, cy, rx, ry, c):
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / (rx + 0.0001)
            dy = (y - cy) / (ry + 0.0001)
            if dx * dx + dy * dy <= 1.0:
                px(g, x, y, c)


def grid_to_img(g):
    """Bakar grid -> gambar, lalu tambahkan outline 1px di sekeliling siluet."""
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    for y in range(FH):
        for x in range(FW):
            if g[y][x] is not None:
                img.putpixel((x, y), g[y][x])
    oc = P["outline"]
    out = img.copy()
    for y in range(FH):
        for x in range(FW):
            if img.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < FW and 0 <= ny < FH and img.getpixel((nx, ny))[3] != 0:
                    out.putpixel((x, y), oc)
                    break
    return out


# ----------------------------------------------------------------------------
# Kaki: digambar sebagai dua kolom dengan lutut + sepatu, bisa diangkat
# ----------------------------------------------------------------------------
def draw_leg(g, x, top, lift, forward, c_leg, c_sh, c_shoe, c_shoe_hi):
    """x = kolom kiri kaki, top = y pinggul, lift = berapa px terangkat,
    forward = geser horizontal (kaki depan + / belakang -)."""
    y_bottom = 35 - lift
    x0 = x + forward
    # paha
    rect(g, x0, top, x0 + 3, top + 4, c_leg)
    # betis (sedikit geser bila terangkat -> kesan lutut menekuk)
    knee_shift = 1 if lift > 0 else 0
    rect(g, x0 + knee_shift, top + 4, x0 + 3 + knee_shift, y_bottom, c_leg)
    # shading sisi kanan
    rect(g, x0 + 2, top, x0 + 3, top + 4, c_sh)
    rect(g, x0 + 2 + knee_shift, top + 4, x0 + 3 + knee_shift, y_bottom, c_sh)
    # sepatu
    sx = x0 + knee_shift
    rect(g, sx - 1, y_bottom + 1, sx + 4, y_bottom + 2, c_shoe)
    hline(g, sx - 1, sx + 4, y_bottom + 1, c_shoe_hi)


# ----------------------------------------------------------------------------
# Karakter — Arutala (sweater teal longgar, celana gelap)
# ----------------------------------------------------------------------------
def draw_char(direction, frame):
    g = new_grid()
    down = direction in ("down", "up")
    side = direction == "side"

    # Parameter langkah per frame
    # Setiap frame: dua kaki (dx, lift), ayunan lengan, dan bob tubuh.
    # Pola baca: kontak (kaki renggang) -> passing (kaki rapat, terangkat) -> dst.
    if side:
        # (legA_dx, legA_lift, legB_dx, legB_lift, ayun_lengan, bob)
        STEPS = [
            (4, 0, -3, 0, -3, 0),   # kontak: A depan, B belakang
            (0, 0, 0, 3, 0, 1),     # passing: B terangkat
            (-3, 0, 4, 0, 3, 0),    # kontak kebalikan
            (0, 3, 0, 0, 0, 1),     # passing: A terangkat
        ]
        adx, alift, bdx, blift, aswing, bob = STEPS[frame]
        draw_leg(g, 8, 27, blift, bdx, P["pants_sh"], P["pants_sh"], P["shoe"], P["shoe_hi"])
        draw_leg(g, 8, 27, alift, adx, P["pants"], P["pants_sh"], P["shoe"], P["shoe_hi"])
    else:
        # (legL_dx, legL_lift, legR_dx, legR_lift, lenganL, lenganR, bob)
        # lengan mengayun berlawanan dengan kaki; dipakai sebagai offset vertikal
        STEPS = [
            (-1, 0, 1, 0, 3, -3, 0),   # kontak: kaki renggang, lengan ayun
            (0, 3, 0, 0, 0, 0, 1),     # kiri terangkat (passing)
            (1, 0, -1, 0, -3, 3, 0),   # kontak kebalikan
            (0, 0, 0, 3, 0, 0, 1),     # kanan terangkat (passing)
        ]
        ldx, llift, rdx, rlift, larm, rarm, bob = STEPS[frame]
        aswing = 0
        draw_leg(g, 5, 27, llift, ldx, P["pants"], P["pants_sh"], P["shoe"], P["shoe_hi"])
        draw_leg(g, 13, 27, rlift, rdx, P["pants"], P["pants_sh"], P["shoe"], P["shoe_hi"])
        for y in range(27 - max(llift, rlift), 36):
            px(g, 12, y, P["outline"])
    # pinggul
    rect(g, 5, 26 - bob, 18, 28 - bob, P["pants"])

    # ---------------- Torso ----------------
    ty0, ty1 = 16 - bob, 29 - bob
    rect(g, 5, ty0, 18, ty1, P["sweater"])
    rect(g, 5, ty1 - 4, 18, ty1, P["sweater_sh"])
    rect(g, 16, ty0, 18, ty1, P["sweater_sh"])
    rect(g, 6, ty0, 7, ty1 - 3, P["sweater_hi"])
    rect(g, 9, ty0 - 1, 14, ty0, P["sweater_sh"])   # kerah

    # ---------------- Lengan ----------------
    if side:
        # satu lengan tampak, mengayun ke depan/belakang
        ax = 8 + aswing
        rect(g, ax - 3, ty0 + 2, ax + 1, ty1 - 3, P["sweater"])
        rect(g, ax + 1, ty0 + 2, ax + 1, ty1 - 3, P["sweater_sh"])
        rect(g, ax - 3, ty0 + 2, ax - 3, ty1 - 3, P["sweater_hi"])
        rect(g, ax - 3, ty1 - 3, ax + 1, ty1 - 1, P["skin"])
    else:
        rect(g, 3, ty0 + 2 + larm, 5, ty1 - 2 + larm, P["sweater"])
        rect(g, 18, ty0 + 2 + rarm, 20, ty1 - 2 + rarm, P["sweater"])
        rect(g, 3, ty0 + 2 + larm, 3, ty1 - 2 + larm, P["sweater_hi"])
        rect(g, 20, ty0 + 2 + rarm, 20, ty1 - 2 + rarm, P["sweater_sh"])
        rect(g, 3, ty1 - 2 + larm, 5, ty1 - 1 + larm, P["skin"])
        rect(g, 18, ty1 - 2 + rarm, 20, ty1 - 1 + rarm, P["skin"])

    # ---------------- Leher & kepala ----------------
    rect(g, 10, ty0 - 3, 13, ty0 - 1, P["skin_sh"])
    hx, hy = 12, 8 - bob
    ellipse(g, hx, hy, 6, 7, P["skin"])
    rect(g, 16, hy - 1, 17, hy + 4, P["skin_sh"])

    # ---------------- Rambut ----------------
    ellipse(g, hx, hy - 2, 7, 6, P["hair"])
    rect(g, 5, hy - 2, 18, hy + 3, P["hair"])
    rect(g, 5, hy - 2, 6, hy + 6, P["hair"])
    rect(g, 17, hy - 2, 18, hy + 6, P["hair"])
    rect(g, 8, hy - 7, 11, hy - 5, P["hair_hi"])
    rect(g, 6, hy - 6, 7, hy - 4, P["hair_hi"])
    rect(g, 16, hy - 5, 18, hy + 4, P["hair_sh"])

    if direction == "down":
        for bx in (7, 10, 13, 16):
            px(g, bx, hy + 3, P["hair"])
        rect(g, 8, hy + 2, 9, hy + 3, P["eye"])
        rect(g, 14, hy + 2, 15, hy + 3, P["eye"])
        px(g, 8, hy + 2, P["skin_hi"])
        px(g, 14, hy + 2, P["skin_hi"])
    elif direction == "up":
        ellipse(g, hx, hy, 6, 7, P["hair"])
        rect(g, 6, hy - 4, 17, hy + 6, P["hair"])
        rect(g, 8, hy - 6, 12, hy - 3, P["hair_hi"])
        rect(g, 15, hy - 4, 17, hy + 5, P["hair_sh"])
    elif direction == "side":
        ellipse(g, hx + 1, hy, 6, 7, P["skin"])
        ellipse(g, hx, hy - 2, 6, 6, P["hair"])
        rect(g, 5, hy - 4, 12, hy + 5, P["hair"])
        rect(g, 5, hy - 6, 10, hy - 3, P["hair_hi"])
        rect(g, 5, hy - 4, 7, hy + 5, P["hair_sh"])
        rect(g, 14, hy + 2, 15, hy + 3, P["eye"])
        px(g, 14, hy + 2, P["skin_hi"])
        px(g, 18, hy + 2, P["skin_sh"])
    return grid_to_img(g)


def _shadow_frame():
    """Bayangan lembut di bawah kaki (24x40, transparan)."""
    sh = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.ellipse([5, 36, 18, 39], fill=(0, 0, 0, 90))
    sd.ellipse([7, 37, 16, 39], fill=(0, 0, 0, 70))
    return sh


def build_sheet(path):
    sheet = Image.new("RGBA", (FW * 4, FH * len(ANIMS)), (0, 0, 0, 0))
    shadow = _shadow_frame()
    for name, row, count in ANIMS:
        direction = "down" if "down" in name else "up" if "up" in name else "side"
        for i in range(count):
            frame = i if "walk" in name else (i * 2)
            cell = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
            cell.alpha_composite(shadow)
            cell.alpha_composite(draw_char(direction, frame))
            sheet.alpha_composite(cell, (i * FW, row * FH))
    sheet.save(path)
    print(f"  sheet  -> {path}  {sheet.size}")


# ----------------------------------------------------------------------------
# Outline generik untuk gambar apa pun
# ----------------------------------------------------------------------------
def add_outline(img, color=(13, 15, 23, 255)):
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0:
                    dst[x, y] = color
                    break
    return out


def prop(w, h, fn, outline=True):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fn(d)
    return add_outline(img) if outline else img


# ----------------------------------------------------------------------------
# Props — ponsel, foto, teh, cermin, jam, pintu, siluet
# ----------------------------------------------------------------------------
def make_props(art):
    OL = P["outline"]

    def phone(d):
        d.rounded_rectangle([2, 0, 13, 15], radius=2, fill=(24, 27, 36, 255))
        d.rectangle([4, 2, 11, 12], fill=(12, 15, 24, 255))
        d.rectangle([4, 2, 11, 4], fill=(30, 40, 60, 255))      # pantulan kaca
        d.point([(8, 3)], fill=(120, 180, 240, 255))
        d.rectangle([7, 1, 8, 1], fill=(70, 78, 96, 255))       # speaker
        d.point([(5, 5), (6, 6), (7, 7)], fill=(90, 150, 210, 255))  # notif
    prop(16, 16, phone).save(os.path.join(art, "phone.png"))

    def photo(d):
        d.rectangle([0, 0, 19, 23], fill=(72, 54, 42, 255))
        d.rectangle([1, 1, 18, 22], fill=(54, 40, 31, 255))
        d.rectangle([3, 3, 16, 20], fill=(168, 152, 132, 255))
        d.rectangle([3, 12, 16, 20], fill=(140, 124, 106, 255))
        d.ellipse([7, 6, 12, 12], fill=(96, 82, 74, 255))       # kepala
        d.rectangle([6, 12, 13, 20], fill=(96, 82, 74, 255))    # badan
        d.line([(3, 3), (16, 3)], fill=(190, 176, 156, 255))
    prop(20, 24, photo).save(os.path.join(art, "photo_frame.png"))

    def tea(d):
        d.ellipse([1, 12, 14, 15], fill=(46, 50, 60, 255))      # tatakan
        d.rectangle([3, 5, 11, 12], fill=(176, 182, 192, 255))  # mug
        d.rectangle([3, 5, 4, 12], fill=(200, 206, 214, 255))   # highlight
        d.rectangle([11, 5, 12, 12], fill=(140, 146, 158, 255)) # bayangan
        d.arc([10, 6, 15, 11], 270, 90, fill=(150, 156, 168, 255))
        d.rectangle([3, 5, 11, 6], fill=(90, 70, 55, 255))      # teh dingin
        d.point([(6, 2)], fill=(180, 190, 200, 120))            # uap tipis
        d.point([(7, 3)], fill=(180, 190, 200, 90))
    prop(16, 16, tea).save(os.path.join(art, "tea_cup.png"))

    def mirror(d):
        d.rectangle([0, 0, 23, 35], fill=(58, 48, 42, 255))
        d.rectangle([2, 2, 21, 33], fill=(70, 88, 110, 235))
        d.rectangle([2, 2, 21, 8], fill=(92, 112, 138, 235))    # langit kaca
        d.line([(4, 5), (12, 30)], fill=(140, 165, 195, 150), width=2)
        d.line([(16, 5), (20, 18)], fill=(120, 145, 175, 110), width=1)
        d.ellipse([8, 14, 15, 22], fill=(60, 76, 96, 200))      # bayangan wajah
    prop(24, 36, mirror).save(os.path.join(art, "mirror.png"))

    def clock(d):
        d.ellipse([0, 0, 23, 23], fill=(44, 49, 60, 255))
        d.ellipse([2, 2, 21, 21], fill=(226, 230, 234, 255))
        for i in range(12):                                     # tanda jam
            a = math.radians(i * 30)
            x = 11.5 + 8 * math.sin(a)
            y = 11.5 - 8 * math.cos(a)
            d.point([(round(x), round(y))], fill=(60, 64, 72, 255))
        d.line([(11.5, 11.5), (17, 11)], fill=(20, 20, 24, 255), width=2)  # jam ~02
        d.line([(11.5, 11.5), (4, 10)], fill=(30, 30, 36, 255), width=1)   # menit ~47
        d.point([(11, 11)], fill=(20, 20, 24, 255))
    prop(24, 24, clock).save(os.path.join(art, "wall_clock.png"))

    def door(d):
        d.rectangle([0, 0, 27, 47], fill=(46, 38, 42, 255))
        d.rectangle([2, 2, 25, 45], fill=(36, 29, 32, 255))
        d.rectangle([5, 6, 22, 22], fill=(30, 24, 27, 255))     # panel atas
        d.rectangle([5, 26, 22, 41], fill=(30, 24, 27, 255))    # panel bawah
        d.line([(5, 6), (22, 6)], fill=(52, 43, 47, 255))
        d.line([(5, 26), (22, 26)], fill=(52, 43, 47, 255))
        d.ellipse([18, 22, 21, 25], fill=(188, 168, 96, 255))   # kenop kuningan
        d.point([(19, 23)], fill=(224, 208, 140, 255))
    prop(28, 48, door).save(os.path.join(art, "door.png"))

    # Siluet di balkon (berdiri membelakangi, sedikit menunduk)
    def sil(d):
        d.ellipse([8, 0, 19, 12], fill=(9, 11, 17, 255))        # kepala
        d.ellipse([7, 0, 20, 9], fill=(6, 8, 12, 255))          # rambut
        d.rectangle([7, 12, 20, 34], fill=(9, 11, 17, 255))     # torso
        d.rectangle([6, 13, 8, 30], fill=(9, 11, 17, 255))      # lengan kiri
        d.rectangle([19, 13, 21, 30], fill=(9, 11, 17, 255))    # lengan kanan
        d.rectangle([9, 34, 12, 48], fill=(7, 9, 13, 255))      # kaki kiri
        d.rectangle([15, 34, 18, 48], fill=(7, 9, 13, 255))     # kaki kanan
    sil_img = Image.new("RGBA", (28, 50), (0, 0, 0, 0))
    ImageDraw.Draw(sil_img).rectangle([0, 0, 27, 49], fill=(0, 0, 0, 0))
    sil(ImageDraw.Draw(sil_img))
    sil_img.save(os.path.join(art, "silhouette_figure.png"))
    print("  props  -> phone, photo_frame, tea_cup, mirror, wall_clock, door, silhouette")


# ----------------------------------------------------------------------------
# Background — kamar tidur & langit balkon
# ----------------------------------------------------------------------------
def make_bedroom(art):
    """Kamar Arutala — 960px lebar agar kamera bisa mengikuti pemain.
    Pintu utama (kiri) -> lorong. Kasur dijauhkan dari pintu."""
    W, H = 960, 360
    img = Image.new("RGBA", (W, H), (20, 23, 34, 255))
    d = ImageDraw.Draw(img)

    # Dinding: gradien gelap (atas lebih gelap)
    for y in range(0, 200):
        t = y / 200.0
        c = (int(26 + 12 * t), int(29 + 13 * t), int(42 + 14 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    # alas dinding
    d.rectangle([0, 196, W, 202], fill=(44, 48, 63, 255))
    d.rectangle([0, 200, W, 202], fill=(32, 35, 47, 255))

    # Lantai kayu (y 202..360) dengan papan & perspektif
    for y in range(202, H):
        t = (y - 202) / 158.0
        c = (int(36 + 18 * t), int(29 + 15 * t), int(32 + 16 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    for y in range(202, H, 22):
        d.line([(0, y), (W, y)], fill=(20, 16, 19, 255))
    for x in range(-40, W, 64):
        d.line([(x, 202), (x + 30, H)], fill=(24, 19, 22, 255))

    # Pintu balkon geser (kaca, tengah) — dari langit-langit ke lantai
    bx0, bx1 = 470, 660
    d.rectangle([bx0, 36, bx1, 198], fill=(40, 46, 64, 255))    # kusen luar
    d.rectangle([bx0 + 6, 42, bx1 - 6, 196], fill=(15, 22, 42, 255))  # kaca
    # bulan di luar
    d.ellipse([538, 62, 592, 116], fill=(58, 70, 108, 255))
    d.ellipse([546, 70, 584, 108], fill=(150, 162, 194, 255))
    d.ellipse([552, 76, 574, 96], fill=(206, 216, 236, 255))
    # hujan (opaque supaya tidak melubangi)
    random.seed(101)
    for _ in range(220):
        rx = random.randint(bx0 + 8, bx1 - 8)
        ry = random.randint(44, 190)
        rl = random.randint(5, 13)
        d.line([(rx, ry), (rx - 3, ry + rl)], fill=(74, 96, 138, 255))
    # bingkai pintu geser (dua daun + rel + ambang)
    mid = (bx0 + bx1) // 2
    d.rectangle([mid - 3, 42, mid + 3, 196], fill=(40, 46, 64, 255))
    d.rectangle([bx0 + 6, 42, bx0 + 9, 196], fill=(56, 64, 86, 255))
    d.rectangle([bx1 - 9, 42, bx1 - 6, 196], fill=(56, 64, 86, 255))
    d.rectangle([bx0 + 6, 44, bx1 - 6, 50], fill=(56, 64, 86, 255))
    d.rectangle([bx0 + 6, 190, bx1 - 6, 196], fill=(34, 40, 56, 255))   # ambang

    # Tempat tidur (kiri-tengah) — jauh dari pintu utama (x 40..96)
    d.rectangle([196, 194, 344, 252], fill=(30, 34, 50, 255))   # rangka
    d.rectangle([200, 186, 340, 200], fill=(56, 63, 88, 255))   # kepala kasur
    d.rectangle([200, 200, 340, 246], fill=(54, 61, 86, 255))   # selimut
    d.rectangle([200, 200, 340, 216], fill=(68, 77, 104, 255))  # selimut atas
    d.rectangle([206, 202, 262, 222], fill=(96, 106, 134, 255)) # bantal
    d.line([(206, 202), (262, 202)], fill=(120, 130, 158, 255))
    d.rectangle([200, 240, 340, 246], fill=(36, 42, 60, 255))   # bayangan bawah

    # Meja (kanan) — diletakkan lebih rendah di lantai
    d.rectangle([720, 236, 892, 248], fill=(64, 50, 55, 255))  # permukaan
    d.rectangle([720, 236, 892, 239], fill=(86, 68, 74, 255))
    d.rectangle([730, 248, 738, 296], fill=(44, 35, 39, 255))  # kaki
    d.rectangle([874, 248, 882, 296], fill=(44, 35, 39, 255))
    d.rectangle([724, 250, 888, 260], fill=(36, 29, 33, 255))  # laci
    d.line([(732, 255), (740, 255)], fill=(120, 104, 88, 255)) # gagang laci

    # Cermin di dinding (kiri-tengah, di atas kasur)
    d.rectangle([404, 128, 448, 194], fill=(58, 48, 42, 255))
    d.rectangle([408, 132, 444, 190], fill=(70, 88, 110, 235))
    d.rectangle([408, 132, 444, 146], fill=(92, 112, 138, 235))
    d.line([(414, 138), (432, 184)], fill=(140, 165, 195, 120), width=2)

    # Jam dinding (kanan atas)
    d.ellipse([866, 66, 902, 102], fill=(44, 49, 60, 255))
    d.ellipse([869, 69, 899, 99], fill=(226, 230, 234, 255))
    for i in range(12):
        a = math.radians(i * 30)
        px_ = 884 + 12 * math.sin(a)
        py_ = 84 - 12 * math.cos(a)
        d.point([(round(px_), round(py_))], fill=(60, 64, 72, 255))
    d.line([(884, 84), (889, 75)], fill=(20, 20, 24, 255), width=2)   # jarum jam (01:00)
    d.line([(884, 84), (884, 74)], fill=(30, 30, 36, 255), width=1)   # jarum menit
    d.point([(884, 84)], fill=(20, 20, 24, 255))

    # Pintu utama (kiri jauh) — kayu, menuju lorong apartemen
    d.rectangle([40, 50, 96, 200], fill=(48, 39, 43, 255))
    d.rectangle([44, 54, 92, 196], fill=(66, 53, 55, 255))
    d.rectangle([44, 54, 92, 58], fill=(80, 66, 68, 255))
    d.rectangle([50, 62, 86, 116], fill=(52, 41, 43, 255))       # panel atas
    d.rectangle([50, 124, 86, 190], fill=(52, 41, 43, 255))      # panel bawah
    d.ellipse([80, 122, 87, 130], fill=(190, 170, 98, 255))      # kenop kuningan
    d.point([(82, 124)], fill=(226, 210, 142, 255))

    # --- Lapisan tembus cahaya (composite, bukan overwrite) ---
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.polygon([(492, 60), (638, 60), (708, 300), (424, 300)], fill=(70, 92, 140, 46))
    img = Image.alpha_composite(img, glow)

    # Vignette — gelapkan tepi
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(70):
        vd.rectangle([i, i, W - i, H - i], outline=min(255, int(3.2 * (70 - i))))
    dark = Image.new("RGBA", (W, H), (6, 7, 12, 255))
    img = Image.composite(Image.alpha_composite(img, dark), img, vig)
    img.save(os.path.join(art, "bedroom_bg.png"))
    print(f"  bg     -> bedroom_bg.png {img.size}")


def make_balcony(art):
    W, H = 640, 200
    sky = Image.new("RGBA", (W, H), (9, 11, 20, 255))
    d = ImageDraw.Draw(sky)
    # gradien langit
    for y in range(H):
        t = y / H
        c = (int(9 + 12 * t), int(11 + 14 * t), int(20 + 20 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    # bintang samar (lapisan terpisah agar tidak melubangi langit)
    stars = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stars)
    random.seed(77)
    for _ in range(40):
        x, y = random.randint(0, W), random.randint(0, 90)
        sd.point([(x, y)], fill=(120, 130, 160, random.randint(40, 110)))
    sky = Image.alpha_composite(sky, stars)
    # gedung
    x = 0
    while x < W:
        bw = random.randint(24, 56)
        bh = random.randint(60, 160)
        by = H - bh
        base = 14 + random.randint(0, 10)
        d.rectangle([x, by, x + bw, H], fill=(base, base + 3, base + 14, 255))
        d.line([(x, by), (x + bw, by)], fill=(base + 10, base + 12, base + 22, 255))
        for wx in range(x + 4, x + bw - 4, 7):
            for wy in range(by + 6, H - 8, 12):
                if random.random() < 0.22:
                    wc = (200, 190, 130, 200) if random.random() < 0.5 else (110, 150, 190, 170)
                    d.rectangle([wx, wy, wx + 3, wy + 5], fill=wc)
        x += bw + random.randint(2, 8)
    sky.save(os.path.join(art, "balcony_skyline.png"))

    # Railing
    rw, rh = 640, 32
    rail = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rail)
    rd.rectangle([0, 0, rw, 6], fill=(56, 61, 78, 255))
    rd.rectangle([0, 1, rw, 3], fill=(84, 92, 114, 255))
    for bx in range(8, rw, 15):
        rd.rectangle([bx, 6, bx + 3, rh], fill=(46, 50, 66, 255))
        rd.point([(bx, 6)], fill=(70, 76, 96, 255))
    rd.rectangle([0, rh - 4, rw, rh], fill=(38, 42, 56, 255))
    rail = add_outline(rail, (13, 15, 23, 200))
    rail.save(os.path.join(art, "balcony_railing.png"))

    # Bulan samar (awan digambar sebagai lapisan terpisah lalu di-composite)
    mw, mh = 48, 48
    moon = Image.new("RGBA", (mw, mh), (0, 0, 0, 0))
    md = ImageDraw.Draw(moon)
    md.ellipse([6, 6, 42, 42], fill=(150, 162, 190, 90))
    md.ellipse([10, 10, 38, 38], fill=(206, 214, 232, 220))
    md.ellipse([14, 14, 26, 24], fill=(224, 230, 244, 235))
    clouds = Image.new("RGBA", (mw, mh), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    for cy in range(16, 36, 3):                                # awan tipis
        cd.line([(2, cy), (46, cy)], fill=(28, 34, 52, 150), width=2)
    moon = Image.alpha_composite(moon, clouds)
    moon.save(os.path.join(art, "moon_dim.png"))
    print("  bg     -> balcony_skyline, balcony_railing, moon_dim")


def make_corridor(art):
    """Latar lorong apartemen (lantai 3-5), 1120px agar kamera bisa mengikuti.
    Pintu kamar, tangga, 2 pintu tetangga, dan lift. Nomor lantai diisi Label."""
    W, H = 1120, 360
    img = Image.new("RGBA", (W, H), (17, 19, 28, 255))
    d = ImageDraw.Draw(img)

    # Langit-langit
    d.rectangle([0, 0, W, 34], fill=(14, 16, 24, 255))
    d.line([(0, 34), (W, 34)], fill=(30, 33, 44, 255))

    # Dinding (gradien)
    for y in range(34, 192):
        t = (y - 34) / 158.0
        c = (int(30 + 14 * t), int(33 + 15 * t), int(47 + 16 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    d.rectangle([0, 188, W, 196], fill=(42, 46, 60, 255))   # alas dinding
    d.rectangle([0, 194, W, 196], fill=(30, 33, 44, 255))

    # Lantai (ubin)
    for y in range(196, H):
        t = (y - 196) / 164.0
        c = (int(32 + 16 * t), int(34 + 16 * t), int(44 + 18 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    for y in range(196, H, 24):
        d.line([(0, y), (W, y)], fill=(21, 23, 31, 255))
    for x in range(-40, W, 70):
        d.line([(x, 196), (x + 22, H)], fill=(25, 27, 35, 255))

    # Lampu langit-langit
    for lx in (200, 560, 920):
        d.rectangle([lx - 44, 2, lx + 44, 12], fill=(52, 58, 76, 255))
        d.rectangle([lx - 38, 4, lx + 38, 10], fill=(158, 168, 196, 255))

    def wood_door(x0, x1):
        d.rectangle([x0 - 4, 54, x1 + 4, 196], fill=(48, 39, 43, 255))
        d.rectangle([x0, 58, x1, 192], fill=(66, 53, 55, 255))
        d.rectangle([x0 + 3, 62, x1 - 3, 188], fill=(57, 46, 48, 255))
        d.rectangle([x0 + 7, 68, x1 - 7, 116], fill=(48, 38, 40, 255))
        d.rectangle([x0 + 7, 124, x1 - 7, 172], fill=(48, 38, 40, 255))
        d.line([(x0 + 7, 68), (x1 - 7, 68)], fill=(80, 66, 68, 255))
        d.line([(x0 + 7, 124), (x1 - 7, 124)], fill=(80, 66, 68, 255))
        d.ellipse([x1 - 15, 122, x1 - 8, 130], fill=(190, 170, 98, 255))
        d.point([(x1 - 13, 124)], fill=(226, 210, 142, 255))

    wood_door(60, 124)                                     # pintu kamar Arutala
    # Pintu tangga (logam, sempit)
    d.rectangle([206, 56, 262, 196], fill=(44, 48, 62, 255))
    d.rectangle([210, 60, 258, 192], fill=(58, 62, 78, 255))
    d.rectangle([214, 64, 254, 84], fill=(72, 78, 96, 255))
    d.line([(234, 64), (234, 84)], fill=(44, 48, 62, 255))
    d.ellipse([246, 120, 255, 129], fill=(156, 164, 186, 255))
    wood_door(400, 464)                                    # tetangga A
    wood_door(600, 664)                                    # tetangga B
    # Lift (kanan)
    d.rectangle([860, 44, 974, 196], fill=(40, 44, 58, 255))
    d.rectangle([864, 48, 970, 192], fill=(56, 60, 76, 255))
    d.rectangle([868, 52, 915, 188], fill=(44, 48, 62, 255))
    d.rectangle([919, 52, 966, 188], fill=(44, 48, 62, 255))
    d.line([(915, 52), (915, 188)], fill=(28, 31, 41, 255))
    d.line([(919, 52), (919, 188)], fill=(28, 31, 41, 255))
    d.rectangle([972, 92, 986, 152], fill=(34, 38, 50, 255))   # panel tombol
    for by in (100, 116, 132):
        d.ellipse([975, by, 981, by + 6], fill=(150, 122, 84, 255))
    d.point([(978, 103)], fill=(240, 212, 152, 255))
    d.rectangle([902, 28, 934, 46], fill=(18, 22, 32, 255))    # display lantai
    d.rectangle([903, 29, 933, 45], fill=(26, 34, 48, 255))
    # Papan nomor lantai (frame; teks diisi Label)
    d.rectangle([530, 34, 586, 56], fill=(38, 42, 56, 255))
    d.rectangle([532, 36, 584, 54], fill=(52, 57, 74, 255))

    # Pintu balkon atap (ujung kanan lorong) — kaca, hanya berarti di lantai 5
    d.rectangle([1024, 44, 1096, 198], fill=(40, 46, 64, 255))
    d.rectangle([1030, 50, 1090, 196], fill=(16, 23, 43, 255))       # kaca
    d.ellipse([1048, 70, 1080, 102], fill=(150, 162, 194, 255))      # bulan di luar
    d.ellipse([1054, 76, 1074, 96], fill=(206, 216, 236, 255))
    random.seed(303)
    for _ in range(60):
        rx = random.randint(1032, 1088)
        ry = random.randint(52, 192)
        d.line([(rx, ry), (rx - 3, ry + random.randint(5, 11))], fill=(74, 96, 138, 255))
    d.rectangle([1058, 50, 1062, 196], fill=(40, 46, 64, 255))       # daun tengah
    d.rectangle([1030, 50, 1033, 196], fill=(56, 64, 86, 255))
    d.rectangle([1087, 50, 1090, 196], fill=(56, 64, 86, 255))

    # Kolam cahaya lampu (lapisan tembus pandang)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for lx in (200, 560, 920):
        gd.polygon([(lx - 30, 12), (lx + 30, 12), (lx + 90, H), (lx - 90, H)],
                   fill=(80, 96, 140, 22))
    img = Image.alpha_composite(img, glow)

    # Vignette tepi
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(80):
        vd.rectangle([i, i, W - i, H - i], outline=min(255, int(2.6 * (80 - i))))
    dark = Image.new("RGBA", (W, H), (5, 6, 11, 255))
    img = Image.composite(Image.alpha_composite(img, dark), img, vig)
    img.save(os.path.join(art, "corridor_bg.png"))
    print(f"  bg     -> corridor_bg.png {img.size}")


# ----------------------------------------------------------------------------
# Panel komik intro — Arutala bangun (gaya cutscene komik)
# ----------------------------------------------------------------------------
def make_intro_panels(art):
    """4 panel gaya komik untuk pembuka: mata terpejam -> mengerjap -> blur
    -> membuka mata. Tiap panel 320x180 dengan bingkai komik tebal."""
    W, H = 320, 180
    OL = (10, 11, 17, 255)
    panels = []

    def base(bg_top, bg_bot):
        im = Image.new("RGBA", (W, H), (*bg_top, 255))
        dd = ImageDraw.Draw(im)
        for y in range(H):
            t = y / H
            c = tuple(int(bg_top[i] + (bg_bot[i] - bg_top[i]) * t) for i in range(3))
            dd.line([(0, y), (W, y)], fill=(*c, 255))
        return im, dd

    # Panel 1 — gelap total, hanya siluet mata terpejam
    im, dd = base((8, 9, 14), (14, 16, 24))
    for (ex, ey) in ((120, 92), (200, 92)):
        dd.line([(ex - 16, ey), (ex + 16, ey)], fill=(70, 74, 90, 255), width=3)
        dd.line([(ex - 16, ey), (ex + 16, ey)], fill=(120, 126, 146, 255), width=1)
    panels.append(im)

    # Panel 2 — cahaya pucat menembus, mata setengah terbuka + blur
    im, dd = base((18, 20, 30), (26, 30, 44))
    dd.ellipse([60, 30, 260, 170], fill=(70, 82, 118, 70))
    dd.ellipse([90, 55, 230, 145], fill=(120, 134, 176, 60))
    for (ex, ey) in ((120, 92), (200, 92)):
        dd.ellipse([ex - 14, ey - 6, ex + 14, ey + 6], fill=(150, 156, 176, 220))
        dd.ellipse([ex - 6, ey - 4, ex + 6, ey + 4], fill=(40, 44, 60, 255))
    panels.append(im)

    # Panel 3 — blur kuat, dunia kabur (blok warna lantai/dinding)
    im, dd = base((22, 25, 36), (30, 34, 48))
    blur = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blur)
    bd.rectangle([0, 110, W, H], fill=(44, 40, 44, 150))
    bd.rectangle([30, 60, 120, 130], fill=(60, 70, 96, 120))     # kasur kabur
    bd.rectangle([200, 55, 300, 120], fill=(70, 78, 104, 110))   # jendela kabur
    blur = blur.filter(ImageFilter.GaussianBlur(6))
    im = Image.alpha_composite(im, blur)
    panels.append(im)

    # Panel 4 — jelas: kamar terbaca, mata terbuka
    im, dd = base((20, 23, 34), (30, 34, 48))
    dd.rectangle([0, 112, W, H], fill=(40, 34, 36, 255))         # lantai
    dd.rectangle([20, 60, 118, 130], fill=(56, 63, 88, 255))     # kasur
    dd.rectangle([26, 66, 74, 86], fill=(96, 106, 134, 255))     # bantal
    dd.rectangle([206, 46, 296, 120], fill=(15, 22, 42, 255))    # jendela
    dd.rectangle([206, 46, 296, 120], outline=(56, 64, 86, 255), width=3)
    dd.ellipse([240, 58, 272, 90], fill=(206, 216, 236, 255))    # bulan
    for (ex, ey) in ((150, 92), (176, 92)):
        dd.ellipse([ex - 7, ey - 8, ex + 7, ey + 8], fill=(233, 203, 183, 255))
        dd.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], fill=(18, 20, 28, 255))
    panels.append(im)

    # Tambahkan bingkai komik + sedikit vignette ke tiap panel
    out_paths = []
    for idx, p in enumerate(panels):
        frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        fd = ImageDraw.Draw(frame)
        fd.rectangle([3, 3, W - 4, H - 4], outline=OL, width=6)
        p = Image.alpha_composite(p, frame)
        path = os.path.join(art, f"intro_panel_{idx + 1}.png")
        p.save(path)
        out_paths.append(path)
    print(f"  intro  -> {len(out_paths)} panel komik")


# ----------------------------------------------------------------------------
# Kilas balik — 4 potongan (160x120)
# ----------------------------------------------------------------------------
def make_flashbacks(art):
    def blend(fg, alpha, bg):
        a = alpha / 255.0
        return (int(fg[0] * a + bg[0] * (1 - a)),
                int(fg[1] * a + bg[1] * (1 - a)),
                int(fg[2] * a + bg[2] * (1 - a)), 255)

    slides = [
        # (bg atas, bg bawah, aksen, jenis)
        ((46, 40, 52), (30, 26, 36), (196, 170, 178), "window_laugh"),
        ((28, 34, 50), (18, 22, 36), (120, 150, 190), "typing"),
        ((40, 28, 34), (24, 16, 20), (170, 110, 120), "door"),
        ((40, 38, 32), (26, 24, 20), (190, 176, 130), "tea"),
    ]
    for idx, (bg0, bg1, acc, kind) in enumerate(slides):
        im = Image.new("RGBA", (160, 120), (*bg0, 255))
        d = ImageDraw.Draw(im)
        for y in range(120):                                   # gradien
            t = y / 120.0
            c = tuple(int(bg0[i] + (bg1[i] - bg0[i]) * t) for i in range(3))
            d.line([(0, y), (160, y)], fill=(*c, 255))
        if kind == "window_laugh":
            d.rectangle([40, 18, 120, 78], fill=(20, 26, 42, 255))   # jendela
            d.rectangle([40, 18, 120, 78], outline=(60, 66, 88, 255))
            d.line([(80, 18), (80, 78)], fill=(60, 66, 88, 255))
            d.ellipse([70, 40, 90, 62], fill=(*acc, 255))            # kepala tertawa
            d.arc([72, 48, 88, 62], 0, 180, fill=(60, 40, 45, 255))
            d.rectangle([66, 62, 94, 96], fill=blend(acc, 200, bg1))
        elif kind == "typing":
            d.rectangle([48, 40, 112, 92], fill=(14, 18, 30, 255))   # ponsel besar
            d.rectangle([52, 44, 108, 84], fill=(24, 32, 52, 255))
            for i in range(4):
                d.line([(58, 52 + i * 8), (58 + (40 if i != 3 else 16), 52 + i * 8)],
                       fill=blend(acc, 190, (24, 32, 52)))
            d.line([(58, 76), (74, 76)], fill=(200, 90, 90, 255))    # teks dihapus
            d.rectangle([70, 88, 90, 108], fill=blend(acc, 160, bg1))
        elif kind == "door":
            d.rectangle([30, 8, 90, 118], fill=(34, 24, 26, 255))    # pintu
            d.rectangle([30, 8, 90, 118], outline=(20, 14, 16, 255))
            d.rectangle([36, 16, 84, 60], fill=(28, 20, 22, 255))
            d.rectangle([36, 68, 84, 110], fill=(28, 20, 22, 255))
            d.ellipse([78, 62, 83, 67], fill=(*acc, 255))
            d.rectangle([92, 20, 150, 116], fill=blend((18, 12, 14), 180, bg1))  # celah gelap
        elif kind == "tea":
            d.ellipse([50, 78, 110, 100], fill=(40, 42, 52, 255))    # tatakan
            d.rectangle([60, 46, 96, 82], fill=(150, 156, 168, 255)) # mug
            d.rectangle([60, 46, 64, 82], fill=(178, 184, 196, 255))
            d.arc([94, 54, 110, 72], 270, 90, fill=(140, 146, 158, 255))
            d.rectangle([60, 46, 96, 50], fill=(96, 74, 58, 255))
            d.line([(72, 36), (72, 44)], fill=blend((200, 208, 220), 120, bg1))  # uap
            d.line([(84, 34), (84, 44)], fill=blend((200, 208, 220), 100, bg1))
        # bingkai & vignette lembut
        d.rectangle([6, 6, 153, 113], outline=blend(acc, 70, bg1))
        im.save(os.path.join(art, f"fb_{idx + 1}.png"))
    print("  fb     -> fb_1..fb_4")


if __name__ == "__main__":
    art = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/art"))
    os.makedirs(art, exist_ok=True)
    print("Karakter:")
    build_sheet(os.path.join(art, "player_sheet.png"))
    print("Props:")
    make_props(art)
    print("Background:")
    make_bedroom(art)
    make_balcony(art)
    make_corridor(art)
    make_intro_panels(art)
    print("Kilas balik:")
    make_flashbacks(art)
    print("Selesai: semua aset v2 dihasilkan.")
