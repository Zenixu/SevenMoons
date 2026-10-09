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
from PIL import Image, ImageDraw

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
    W, H = 640, 360
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

    # Jendela (x 240..400, y 46..184)
    d.rectangle([234, 42, 406, 188], fill=(36, 42, 60, 255))   # kusen luar
    d.rectangle([240, 48, 400, 182], fill=(16, 23, 44, 255))   # kaca
    # bulan di luar jendela
    d.ellipse([296, 66, 348, 118], fill=(58, 70, 108, 255))
    d.ellipse([304, 74, 340, 110], fill=(150, 162, 194, 255))
    d.ellipse([310, 80, 330, 96], fill=(206, 216, 236, 255))
    # hujan (opaque supaya tidak melubangi)
    random.seed(101)
    for _ in range(150):
        rx = random.randint(242, 398)
        ry = random.randint(50, 176)
        rl = random.randint(5, 13)
        d.line([(rx, ry), (rx - 3, ry + rl)], fill=(74, 96, 138, 255))
    # palang
    d.rectangle([317, 48, 323, 182], fill=(36, 42, 60, 255))
    d.rectangle([240, 112, 400, 118], fill=(36, 42, 60, 255))
    d.rectangle([240, 48, 243, 182], fill=(52, 60, 82, 255))

    # Tempat tidur (kiri) — tinggi wajar (~55px, sebanding karakter 40px)
    d.rectangle([44, 194, 168, 252], fill=(30, 34, 50, 255))   # rangka
    d.rectangle([48, 186, 164, 200], fill=(56, 63, 88, 255))   # kepala kasur
    d.rectangle([48, 200, 164, 246], fill=(54, 61, 86, 255))   # selimut
    d.rectangle([48, 200, 164, 216], fill=(68, 77, 104, 255))  # selimut atas
    d.rectangle([54, 202, 104, 222], fill=(96, 106, 134, 255)) # bantal
    d.line([(54, 202), (104, 202)], fill=(120, 130, 158, 255))
    d.rectangle([48, 240, 164, 246], fill=(36, 42, 60, 255))   # bayangan bawah

    # Meja (kanan) — meja rendah (permukaan di y~212, tempat props diletakkan)
    d.rectangle([466, 212, 598, 224], fill=(64, 50, 55, 255))  # permukaan
    d.rectangle([466, 212, 598, 215], fill=(86, 68, 74, 255))
    d.rectangle([474, 224, 482, 272], fill=(44, 35, 39, 255))  # kaki
    d.rectangle([582, 224, 590, 272], fill=(44, 35, 39, 255))
    d.rectangle([470, 226, 594, 236], fill=(36, 29, 33, 255))  # laci
    d.line([(478, 231), (486, 231)], fill=(120, 104, 88, 255)) # gagang laci

    # Pintu balkon (kiri jauh)
    d.rectangle([2, 54, 30, 206], fill=(48, 54, 72, 255))
    d.rectangle([5, 58, 27, 202], fill=(18, 24, 40, 255))
    d.rectangle([15, 58, 17, 202], fill=(48, 54, 72, 255))
    d.ellipse([19, 124, 23, 128], fill=(188, 168, 96, 255))

    # --- Lapisan tembus cahaya (composite, bukan overwrite) ---
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.polygon([(252, 60), (398, 60), (468, 300), (184, 300)], fill=(70, 92, 140, 46))
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
    print("Kilas balik:")
    make_flashbacks(art)
    print("Selesai: semua aset v2 dihasilkan.")
