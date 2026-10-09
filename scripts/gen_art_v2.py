#!/usr/bin/env python3
"""SevenMoons — Pixel Art Generator v2
Gaya: OMORI / A Space for the Unbound (moody, outline tebal, palet terbatas).
Karakter ber-anatomi (hoodie + rambut spike ala Sasuke) + spritesheet animasi
(idle/walk 4 arah), props, background, panel komik intro, kilas balik.

Struktur output (rapi):
  assets/characters/   player_sheet.png
  assets/backgrounds/  bedroom_bg, corridor_bg, balcony_*, rooftop_bg, lift_bg
  assets/props/        phone, photo_frame, tea_cup, mirror, wall_clock, silhouette
  assets/ui/           intro_panel_1..4
  assets/flashbacks/   fb_1..fb_4

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
    "hair":       (32, 31, 44, 255),      # biru-hitam (ala Sasuke)
    "hair_hi":    (66, 64, 92, 255),
    "hair_sh":    (18, 18, 28, 255),
    "skin":       (233, 203, 183, 255),
    "skin_sh":    (196, 163, 146, 255),
    "skin_hi":    (248, 224, 206, 255),
    "hood":       (56, 63, 86, 255),      # hoodie (biru kelabu gelap)
    "hood_sh":    (38, 44, 62, 255),
    "hood_hi":    (80, 90, 116, 255),
    "hood_line":  (120, 132, 160, 255),   # tali & kantong hoodie
    "pants":      (48, 48, 64, 255),
    "pants_sh":   (32, 32, 44, 255),
    "pants_hi":   (66, 68, 88, 255),
    "shoe":       (24, 24, 32, 255),
    "shoe_hi":    (50, 52, 66, 255),
    "eye":        (18, 20, 28, 255),
}

FW, FH = 32, 48          # ukuran satu frame karakter (lebih besar dari v1)
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


def vline(g, x, y0, y1, c):
    for y in range(y0, y1 + 1):
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
# Kaki: dua kolom dengan lutut + sepatu, bisa diangkat
# ----------------------------------------------------------------------------
def draw_leg(g, x, top, lift, forward, c_leg, c_sh, c_shoe, c_shoe_hi):
    """x = kolom kiri kaki, top = y pinggul, lift = berapa px terangkat,
    forward = geser horizontal (kaki depan + / belakang -)."""
    y_bottom = 43 - lift
    x0 = x + forward
    rect(g, x0, top, x0 + 3, top + 4, c_leg)                 # paha
    knee_shift = 1 if lift > 0 else 0
    rect(g, x0 + knee_shift, top + 4, x0 + 3 + knee_shift, y_bottom, c_leg)  # betis
    rect(g, x0 + 2, top, x0 + 3, top + 4, c_sh)              # shading
    rect(g, x0 + 2 + knee_shift, top + 4, x0 + 3 + knee_shift, y_bottom, c_sh)
    sx = x0 + knee_shift
    rect(g, sx - 1, y_bottom + 1, sx + 4, y_bottom + 2, c_shoe)   # sepatu
    hline(g, sx - 1, sx + 4, y_bottom + 1, c_shoe_hi)


# ----------------------------------------------------------------------------
# Karakter — Arutala (hoodie gelap, rambut spike ala Sasuke)
# ----------------------------------------------------------------------------
def draw_char(direction, frame):
    g = new_grid()
    side = direction == "side"
    down = direction == "down"
    up = direction == "up"

    # ---------------- Kaki / langkah ----------------
    if side:
        STEPS = [
            (4, 0, -3, 0, -3, 0),   # kontak
            (0, 0, 0, 3, 0, 1),     # passing
            (-3, 0, 4, 0, 3, 0),    # kontak kebalikan
            (0, 3, 0, 0, 0, 1),     # passing
        ]
        adx, alift, bdx, blift, aswing, bob = STEPS[frame]
        draw_leg(g, 12, 35, blift, bdx, P["pants_sh"], P["pants_sh"], P["shoe"], P["shoe_hi"])
        draw_leg(g, 12, 35, alift, adx, P["pants"], P["pants_sh"], P["shoe"], P["shoe_hi"])
    else:
        STEPS = [
            (-1, 0, 1, 0, 3, -3, 0),
            (0, 3, 0, 0, 0, 0, 1),
            (1, 0, -1, 0, -3, 3, 0),
            (0, 0, 0, 3, 0, 0, 1),
        ]
        ldx, llift, rdx, rlift, larm, rarm, bob = STEPS[frame]
        aswing = 0
        draw_leg(g, 10, 35, llift, ldx, P["pants"], P["pants_sh"], P["shoe"], P["shoe_hi"])
        draw_leg(g, 18, 35, rlift, rdx, P["pants"], P["pants_sh"], P["shoe"], P["shoe_hi"])
        for y in range(35 - max(llift, rlift), 44):
            px(g, 16, y, P["outline"])
    # pinggul (celana)
    rect(g, 9, 33 - bob, 22, 36 - bob, P["pants"])

    # ---------------- Torso: hoodie ----------------
    ty0, ty1 = 21 - bob, 34 - bob
    rect(g, 9, ty0, 22, ty1, P["hood"])
    rect(g, 7, ty0 + 3, 8, ty1 - 2, P["hood"])       # bahu kiri menonjol
    rect(g, 23, ty0 + 3, 24, ty1 - 2, P["hood"])     # bahu kanan menonjol
    rect(g, 9, ty1 - 4, 22, ty1, P["hood_sh"])       # bawah hoodie lebih gelap
    vline(g, 9, ty0, ty1, P["hood_hi"])              # highlight tepi kiri
    # resleting tengah
    vline(g, 16, ty0 + 3, ty1 - 1, P["hood_sh"])
    # kantong kanguru
    rect(g, 11, ty1 - 6, 20, ty1 - 6, P["hood_line"])
    vline(g, 11, ty1 - 6, ty1 - 2, P["hood_line"])
    vline(g, 20, ty1 - 6, ty1 - 2, P["hood_line"])
    # tali hoodie (drawstring)
    vline(g, 13, ty0 + 3, ty0 + 6, P["hood_line"])
    vline(g, 19, ty0 + 3, ty0 + 6, P["hood_line"])
    # kerah/hood di belakang leher
    rect(g, 10, ty0 - 1, 21, ty0 + 1, P["hood_sh"])

    # ---------------- Lengan ----------------
    if side:
        ax = 15 + aswing
        rect(g, ax - 2, ty0 + 2, ax + 2, ty1 - 2, P["hood"])
        vline(g, ax + 2, ty0 + 2, ty1 - 2, P["hood_sh"])
        rect(g, ax - 2, ty1 - 2, ax + 2, ty1 - 1, P["skin"])   # tangan
    else:
        rect(g, 5, ty0 + 2 + larm, 8, ty1 - 1 + larm, P["hood"])
        rect(g, 23, ty0 + 2 + rarm, 26, ty1 - 1 + rarm, P["hood"])
        vline(g, 5, ty0 + 2 + larm, ty1 - 1 + larm, P["hood_hi"])
        vline(g, 26, ty0 + 2 + rarm, ty1 - 1 + rarm, P["hood_sh"])
        rect(g, 5, ty1 - 1 + larm, 8, ty1 + larm, P["skin"])
        rect(g, 23, ty1 - 1 + rarm, 26, ty1 + rarm, P["skin"])

    # ---------------- Leher & kepala ----------------
    rect(g, 14, ty0 - 3, 17, ty0 - 1, P["skin_sh"])
    hx, hy = 16, 12 - bob
    ellipse(g, hx, hy, 6, 7, P["skin"])
    rect(g, 20, hy - 1, 21, hy + 4, P["skin_sh"])

    # ---------------- Rambut (spike ala Sasuke) ----------------
    _draw_hair(g, hx, hy, direction)

    # ---------------- Wajah ----------------
    if down:
        rect(g, 12, hy + 2, 13, hy + 3, P["eye"])
        rect(g, 18, hy + 2, 19, hy + 3, P["eye"])
        px(g, 12, hy + 2, P["skin_hi"])
        px(g, 18, hy + 2, P["skin_hi"])
        hline(g, 14, 17, hy + 6, P["skin_sh"])   # mulut tipis
    elif side:
        rect(g, 18, hy + 2, 19, hy + 3, P["eye"])
        px(g, 18, hy + 2, P["skin_hi"])
        px(g, 21, hy + 2, P["skin_sh"])
    return grid_to_img(g)


def _draw_hair(g, hx, hy, direction):
    """Rambut spike gelap: poni panjang di sisi wajah + spike belakang."""
    hair, hi, sh = P["hair"], P["hair_hi"], P["hair_sh"]
    # massa dasar
    ellipse(g, hx, hy - 2, 7, 6, hair)
    rect(g, 9, hy - 3, 23, hy + 1, hair)

    if direction == "down":
        # spike atas
        rect(g, 11, hy - 9, 13, hy - 5, hair)
        rect(g, 15, hy - 10, 17, hy - 5, hair)
        rect(g, 19, hy - 9, 21, hy - 5, hair)
        rect(g, 9, hy - 7, 10, hy - 4, hair)
        rect(g, 22, hy - 7, 23, hy - 4, hair)
        # poni tengah membelah
        rect(g, 12, hy - 6, 20, hy - 2, hair)
        rect(g, 15, hy - 2, 16, hy, hair)
        # helai panjang di sisi wajah (ciri khas)
        rect(g, 9, hy - 2, 10, hy + 7, hair)
        rect(g, 22, hy - 2, 23, hy + 7, hair)
        # highlight
        rect(g, 12, hy - 8, 14, hy - 6, hi)
        rect(g, 18, hy - 8, 20, hy - 6, hi)
        rect(g, 9, hy - 1, 10, hy + 3, sh)
        rect(g, 22, hy - 1, 23, hy + 3, sh)
    elif direction == "up":
        # belakang kepala: massa spike + "ekor bebek" khas
        rect(g, 9, hy - 8, 23, hy + 6, hair)
        rect(g, 10, hy - 10, 12, hy - 6, hair)
        rect(g, 15, hy - 11, 17, hy - 6, hair)
        rect(g, 20, hy - 10, 22, hy - 6, hair)
        rect(g, 9, hy - 6, 10, hy + 4, hair)
        rect(g, 22, hy - 6, 23, hy + 4, hair)
        # ekor spike keluar bawah-belakang
        rect(g, 13, hy + 6, 18, hy + 8, hair)
        rect(g, 14, hy + 9, 17, hy + 11, hair)
        rect(g, 15, hy + 12, 16, hy + 13, sh)
        # highlight atas
        rect(g, 11, hy - 9, 14, hy - 7, hi)
        rect(g, 18, hy - 9, 21, hy - 7, hi)
        rect(g, 20, hy - 6, 22, hy + 3, sh)
    else:  # side
        ellipse(g, hx + 1, hy, 6, 7, P["skin"])
        ellipse(g, hx - 1, hy - 2, 7, 6, hair)
        rect(g, 8, hy - 6, 17, hy + 4, hair)
        # poni panjang menutup dahi & sisi
        rect(g, 8, hy - 6, 9, hy + 6, hair)
        rect(g, 10, hy - 4, 19, hy - 1, hair)
        rect(g, 19, hy - 4, 22, hy + 1, hair)
        # spike ke belakang
        rect(g, 7, hy - 9, 9, hy - 4, hair)
        rect(g, 10, hy - 10, 12, hy - 6, hair)
        rect(g, 6, hy - 3, 8, hy + 2, hair)
        # ekor belakang
        rect(g, 6, hy + 1, 10, hy + 4, hair)
        rect(g, 7, hy + 5, 9, hy + 7, sh)
        # highlight
        rect(g, 10, hy - 8, 13, hy - 6, hi)
        rect(g, 8, hy - 3, 9, hy + 2, sh)


def _shadow_frame():
    """Bayangan lembut di bawah kaki (32x48, transparan)."""
    sh = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.ellipse([8, 44, 23, 47], fill=(0, 0, 0, 95))
    sd.ellipse([10, 45, 21, 47], fill=(0, 0, 0, 70))
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
# Props — ponsel, foto, teh, cermin, jam, siluet
# ----------------------------------------------------------------------------
def make_props(props_dir):
    def phone(d):
        d.rounded_rectangle([2, 0, 13, 15], radius=2, fill=(24, 27, 36, 255))
        d.rectangle([4, 2, 11, 12], fill=(12, 15, 24, 255))
        d.rectangle([4, 2, 11, 4], fill=(30, 40, 60, 255))
        d.point([(8, 3)], fill=(120, 180, 240, 255))
        d.rectangle([7, 1, 8, 1], fill=(70, 78, 96, 255))
        d.point([(5, 5), (6, 6), (7, 7)], fill=(90, 150, 210, 255))
    prop(16, 16, phone).save(os.path.join(props_dir, "phone.png"))

    def photo(d):
        d.rectangle([0, 0, 19, 23], fill=(72, 54, 42, 255))
        d.rectangle([1, 1, 18, 22], fill=(54, 40, 31, 255))
        d.rectangle([3, 3, 16, 20], fill=(168, 152, 132, 255))
        d.rectangle([3, 12, 16, 20], fill=(140, 124, 106, 255))
        d.ellipse([7, 6, 12, 12], fill=(96, 82, 74, 255))
        d.rectangle([6, 12, 13, 20], fill=(96, 82, 74, 255))
        d.line([(3, 3), (16, 3)], fill=(190, 176, 156, 255))
    prop(20, 24, photo).save(os.path.join(props_dir, "photo_frame.png"))

    def tea(d):
        d.ellipse([1, 12, 14, 15], fill=(46, 50, 60, 255))
        d.rectangle([3, 5, 11, 12], fill=(176, 182, 192, 255))
        d.rectangle([3, 5, 4, 12], fill=(200, 206, 214, 255))
        d.rectangle([11, 5, 12, 12], fill=(140, 146, 158, 255))
        d.arc([10, 6, 15, 11], 270, 90, fill=(150, 156, 168, 255))
        d.rectangle([3, 5, 11, 6], fill=(90, 70, 55, 255))
        d.point([(6, 2)], fill=(180, 190, 200, 120))
        d.point([(7, 3)], fill=(180, 190, 200, 90))
    prop(16, 16, tea).save(os.path.join(props_dir, "tea_cup.png"))

    def mirror(d):
        # bingkai kayu gelap
        d.rectangle([0, 0, 23, 35], fill=(52, 42, 38, 255))
        d.rectangle([0, 0, 23, 1], fill=(78, 64, 58, 255))
        d.rectangle([0, 34, 23, 35], fill=(30, 24, 22, 255))
        # kaca: gradien vertikal (terang di atas, gelap di bawah)
        for yy in range(2, 34):
            t = (yy - 2) / 31.0
            col = (int(120 - 56 * t), int(142 - 60 * t), int(178 - 60 * t), 255)
            d.line([(2, yy), (21, yy)], fill=col)
        # kilau diagonal tipis (sheen kaca) — tidak tebal, bukan retak
        for k in range(6):
            d.line([(3 + k, 20 - k), (9 + k, 14 - k)], fill=(214, 226, 246, 120))
        d.line([(3, 21), (10, 14)], fill=(230, 240, 255, 170))
        d.line([(15, 8), (20, 3)], fill=(200, 216, 240, 90))
        # pantulan samar sosok (siluet tipis)
        d.ellipse([8, 15, 15, 24], fill=(66, 82, 104, 150))
        d.rectangle([10, 23, 13, 30], fill=(58, 72, 92, 130))
    prop(24, 36, mirror).save(os.path.join(props_dir, "mirror.png"))

    def clock(d):
        d.ellipse([0, 0, 23, 23], fill=(44, 49, 60, 255))
        d.ellipse([2, 2, 21, 21], fill=(226, 230, 234, 255))
        for i in range(12):
            a = math.radians(i * 30)
            x = 11.5 + 8 * math.sin(a)
            y = 11.5 - 8 * math.cos(a)
            d.point([(round(x), round(y))], fill=(60, 64, 72, 255))
        d.line([(11.5, 11.5), (11.5, 5)], fill=(20, 20, 24, 255), width=2)   # jam 12
        d.line([(11.5, 11.5), (17, 11.5)], fill=(30, 30, 36, 255), width=1)  # menit
        d.point([(11, 11)], fill=(20, 20, 24, 255))
    prop(24, 24, clock).save(os.path.join(props_dir, "wall_clock.png"))

    def sil(d):
        d.ellipse([8, 0, 19, 12], fill=(9, 11, 17, 255))
        d.ellipse([7, 0, 20, 9], fill=(6, 8, 12, 255))
        d.rectangle([7, 12, 20, 34], fill=(9, 11, 17, 255))
        d.rectangle([6, 13, 8, 30], fill=(9, 11, 17, 255))
        d.rectangle([19, 13, 21, 30], fill=(9, 11, 17, 255))
        d.rectangle([9, 34, 12, 48], fill=(7, 9, 13, 255))
        d.rectangle([15, 34, 18, 48], fill=(7, 9, 13, 255))
    sil_img = Image.new("RGBA", (28, 50), (0, 0, 0, 0))
    sil(ImageDraw.Draw(sil_img))
    sil_img.save(os.path.join(props_dir, "silhouette_figure.png"))
    print("  props  -> phone, photo_frame, tea_cup, mirror, wall_clock, silhouette")


# ----------------------------------------------------------------------------
# Background — kamar tidur (kecil & rapi) & langit balkon
# ----------------------------------------------------------------------------
def make_bedroom(bg_dir):
    """Kamar Arutala — 640px (satu layar). Gaya mengikuti referensi #2:
    palet indigo dingin monokrom, lantai keramik MENGKILAP dengan pantulan
    cahaya bulan berbentuk pita vertikal, jendela berkorden tebal.
    Tata letak (kiri->kanan): wastafel, pintu, kulkas, cermin, kasur,
    jendela (agak ke atas), meja. Hanya SATU jam (prop terpisah)."""
    W, H = 640, 360
    FLOOR_Y = 232
    img = Image.new("RGBA", (W, H), (9, 11, 24, 255))
    d = ImageDraw.Draw(img)

    # ---------- Dinding: gradien indigo dingin ----------
    for y in range(0, FLOOR_Y):
        t = y / float(FLOOR_Y)
        r = int(11 + 17 * t)
        g = int(16 + 20 * t)
        b = int(33 + 33 * t)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    # semburat bulan di dinding sekitar jendela
    for y in range(96, FLOOR_Y):
        t = (y - 96) / float(FLOOR_Y - 96)
        a = int(26 * (1.0 - abs(t - 0.4) * 1.2))
        if a > 0:
            d.line([(470, y), (612, y)], fill=(30, 42, 78, a))
    # garis langit-langit & alas dinding
    d.rectangle([0, 0, W, 3], fill=(6, 8, 18, 255))
    d.rectangle([0, FLOOR_Y - 8, W, FLOOR_Y - 4], fill=(36, 44, 70, 255))
    d.rectangle([0, FLOOR_Y - 4, W, FLOOR_Y], fill=(20, 26, 44, 255))

    # ---------- Lantai keramik gelap mengkilap ----------
    for y in range(FLOOR_Y, H):
        t = (y - FLOOR_Y) / float(H - FLOOR_Y)
        r = int(13 + 9 * t)
        g = int(17 + 11 * t)
        b = int(34 + 16 * t)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    # grid ubin (perspektif ringan)
    for i, y in enumerate(range(FLOOR_Y, H, 26)):
        d.line([(0, y), (W, y)], fill=(8, 10, 20, 255))
    for x in range(-60, W + 60, 54):
        skew = int((x - W / 2) * 0.14)
        d.line([(x, FLOOR_Y), (x + skew, H)], fill=(9, 11, 22, 255))

    # ---------- Wastafel (kiri jauh) ----------
    wx0, wx1 = 14, 60
    d.rectangle([wx0 - 2, 200, wx1 + 2, 234], fill=(30, 36, 58, 255))
    d.rectangle([wx0 + 2, 203, wx1 - 2, 231], fill=(23, 28, 46, 255))
    d.rectangle([wx0 - 3, 192, wx1 + 3, 201], fill=(150, 158, 182, 255))   # bak
    d.ellipse([wx0 + 7, 186, wx1 - 7, 200], fill=(176, 184, 206, 255))
    d.ellipse([wx0 + 13, 190, wx1 - 13, 198], fill=(58, 66, 92, 255))
    d.rectangle([wx0 + 20, 176, wx0 + 24, 192], fill=(150, 158, 182, 255))  # keran
    d.line([(wx0 + 24, 178), (wx0 + 31, 178)], fill=(150, 158, 182, 255))
    d.rectangle([wx0 + 6, 216, wx1 - 6, 218], fill=(44, 52, 78, 255))
    d.ellipse([wx0 + 10, 222, wx0 + 16, 228], fill=(70, 80, 108, 255))      # kenop
    d.rectangle([wx0 - 4, 232, wx1 + 4, 236], fill=(9, 11, 22, 255))        # bayangan kontak

    # ---------- Pintu utama (agak ke kiri) ----------
    dx0, dx1 = 78, 118
    d.rectangle([dx0 - 3, 156, dx1 + 3, FLOOR_Y], fill=(24, 20, 30, 255))
    d.rectangle([dx0, 160, dx1, FLOOR_Y - 2], fill=(42, 34, 44, 255))
    d.rectangle([dx0, 160, dx1, 165], fill=(56, 45, 56, 255))
    d.rectangle([dx0 + 5, 168, dx1 - 5, 190], fill=(32, 26, 36, 255))
    d.rectangle([dx0 + 5, 196, dx1 - 5, FLOOR_Y - 10], fill=(32, 26, 36, 255))
    d.ellipse([dx1 - 13, 194, dx1 - 6, 202], fill=(176, 154, 88, 255))      # kenop
    d.point([(dx1 - 11, 196)], fill=(214, 198, 132, 255))

    # ---------- Kulkas (samping pintu) ----------
    fx0, fx1 = 132, 198
    d.rectangle([fx0, 116, fx1, 242], fill=(38, 44, 66, 255))               # badan
    d.rectangle([fx0 + 3, 119, fx1 - 3, 239], fill=(48, 56, 80, 255))
    d.line([(fx0 + 3, 158), (fx1 - 3, 158)], fill=(30, 36, 56, 255))        # garis freezer
    d.rectangle([fx1 - 13, 128, fx1 - 8, 148], fill=(28, 34, 52, 255))      # gagang atas
    d.rectangle([fx1 - 13, 170, fx1 - 8, 196], fill=(28, 34, 52, 255))      # gagang bawah
    d.rectangle([fx0 + 8, 126, fx0 + 26, 136], fill=(120, 132, 160, 255))   # magnet
    d.rectangle([fx0 + 10, 128, fx0 + 22, 134], fill=(180, 190, 214, 255))
    d.rectangle([fx0, 238, fx1, 242], fill=(22, 27, 42, 255))               # bayangan

    # ---------- Backing cermin di dinding (prop mirror.png digambar di atas) ----------
    d.rectangle([240, 130, 268, 172], fill=(18, 22, 40, 255))              # bayangan lembut
    d.rectangle([240, 170, 268, 172], fill=(11, 14, 26, 255))

    # ---------- Kasur (KANAN) ----------
    b0, b1 = 296, 470
    d.rectangle([b0 - 6, 166, b0 + 12, 242], fill=(30, 36, 58, 255))        # kepala kasur
    d.rectangle([b0 - 6, 166, b0 + 12, 173], fill=(48, 56, 86, 255))
    d.rectangle([b0 - 3, 198, b0 + 5, 240], fill=(22, 27, 44, 255))
    d.rectangle([b0, 190, b1, 244], fill=(24, 29, 48, 255))                 # rangka
    d.rectangle([b0 + 4, 186, b1 - 4, 238], fill=(48, 56, 86, 255))         # kasur
    d.rectangle([b0 + 4, 186, b1 - 4, 192], fill=(70, 82, 118, 255))        # tepi atas
    d.rounded_rectangle([b0 + 12, 190, b0 + 84, 214], radius=7, fill=(150, 160, 190, 255))  # bantal
    d.line([(b0 + 20, 200), (b0 + 76, 200)], fill=(118, 128, 158, 255))
    d.rectangle([b0 + 92, 190, b1 - 6, 238], fill=(38, 46, 76, 255))        # selimut
    d.rectangle([b0 + 92, 190, b1 - 6, 197], fill=(56, 68, 104, 255))       # lipatan
    d.line([(b0 + 92, 197), (b1 - 6, 197)], fill=(28, 34, 56, 255))
    d.line([(b0 + 126, 197), (b0 + 126, 238)], fill=(28, 34, 56, 255))
    d.line([(b0 + 152, 197), (b0 + 152, 238)], fill=(32, 39, 62, 255))
    d.rectangle([b0, 234, b1, 244], fill=(18, 22, 36, 255))                 # bayangan

    # ---------- Meja (KANAN) + barang ----------
    mx0, mx1 = 486, 606
    d.rectangle([mx0, 204, mx1, 212], fill=(38, 32, 50, 255))               # permukaan
    d.rectangle([mx0, 204, mx1, 207], fill=(58, 48, 72, 255))
    d.rectangle([mx0 + 8, 212, mx0 + 16, 252], fill=(28, 24, 38, 255))      # kaki
    d.rectangle([mx1 - 16, 212, mx1 - 8, 252], fill=(28, 24, 38, 255))
    d.rectangle([mx0 + 4, 214, mx1 - 4, 228], fill=(24, 20, 32, 255))       # laci
    d.line([(mx0 + 50, 221), (mx0 + 66, 221)], fill=(104, 92, 78, 255))
    d.rounded_rectangle([mx0 + 12, 190, mx0 + 28, 206], radius=2, fill=(16, 19, 30, 255))  # ponsel
    d.rectangle([mx0 + 15, 193, mx0 + 25, 203], fill=(24, 34, 54, 255))
    d.rectangle([mx0 + 44, 182, mx0 + 64, 206], fill=(58, 44, 36, 255))     # foto
    d.rectangle([mx0 + 46, 184, mx0 + 62, 204], fill=(140, 130, 116, 255))
    d.ellipse([mx0 + 86, 192, mx0 + 102, 208], fill=(34, 40, 58, 255))      # tatakan
    d.rectangle([mx0 + 89, 190, mx0 + 99, 200], fill=(158, 166, 184, 255))  # mug
    d.rectangle([mx0, 250, mx1, 254], fill=(9, 11, 22, 255))                # bayangan kontak meja

    # ---------- Jendela berkorden (kanan, agak ke ATAS) ----------
    bx0, bx1, by0, by1 = 486, 596, 122, 198
    # lengkung valance atas
    d.rectangle([bx0 - 8, by0 - 8, bx1 + 8, by0 + 2], fill=(16, 19, 34, 255))
    d.rectangle([bx0, by0, bx1, by1], fill=(26, 32, 52, 255))              # kusen
    d.rectangle([bx0 + 5, by0 + 5, bx1 - 5, by1 - 4], fill=(13, 20, 40, 255))  # langit malam
    # bulan + kawah
    d.ellipse([518, 132, 558, 172], fill=(74, 92, 138, 255))
    d.ellipse([523, 137, 553, 167], fill=(166, 180, 214, 255))
    d.ellipse([527, 141, 549, 163], fill=(214, 224, 244, 255))
    d.ellipse([534, 148, 540, 154], fill=(180, 192, 220, 255))
    d.ellipse([541, 156, 545, 160], fill=(184, 196, 222, 255))
    # treeline gelap di bawah langit jendela
    random.seed(7)
    tl = by1 - 26
    for tx in range(bx0 + 5, bx1 - 5):
        hh = 8 + int(7 * abs(math.sin(tx * 0.35)))
        d.line([(tx, by1 - 4), (tx, tl + 10 - hh)], fill=(7, 10, 22, 255))
    d.rectangle([bx0 + 5, tl + 6, bx1 - 5, by1 - 4], fill=(7, 10, 22, 255))
    # hujan (garis diagonal terang)
    random.seed(101)
    for _ in range(70):
        rx = random.randint(bx0 + 7, bx1 - 7)
        ry = random.randint(by0 + 7, by1 - 12)
        d.line([(rx, ry), (rx - 2, ry + random.randint(5, 9))], fill=(96, 118, 164, 255))
    # mullion tengah + bingkai
    mid = (bx0 + bx1) // 2
    d.rectangle([mid - 2, by0 + 5, mid + 2, by1 - 4], fill=(34, 40, 62, 255))
    d.rectangle([bx0 + 5, by0 + 5, bx0 + 8, by1 - 4], fill=(46, 54, 80, 255))
    d.rectangle([bx1 - 8, by0 + 5, bx1 - 5, by1 - 4], fill=(46, 54, 80, 255))
    d.rectangle([bx0 + 5, by0 + 5, bx1 - 5, by0 + 9], fill=(46, 54, 80, 255))
    d.rectangle([bx0 + 5, by1 - 9, bx1 - 5, by1 - 4], fill=(28, 34, 52, 255))
    # --- Korden tebal (kiri & kanan) dengan lipatan ---
    def curtain(cx, w, side):
        for i in range(w):
            fold = 0 if (i // 3) % 2 == 0 else 1
            base = (26, 32, 58) if fold == 0 else (18, 23, 44)
            d.line([(cx + i, by0 - 6), (cx + i, by1 + 4)], fill=base + (255,))
        # ujung mengerucut (tieback)
        for yy in range(by1 - 22, by1 + 6):
            t = (yy - (by1 - 22)) / 24.0
            inset = int(t * (w - 6) * (1 if side < 0 else 1))
            if side < 0:
                d.line([(cx + inset, yy), (cx + w - 1, yy)], fill=(20, 25, 48, 255))
            else:
                d.line([(cx, yy), (cx + w - 1 - inset, yy)], fill=(20, 25, 48, 255))
    curtain(bx0 - 4, 18, -1)
    curtain(bx1 - 14, 18, 1)

    # ---------- Pantulan cahaya bulan di lantai (pita vertikal lembut) ----------
    shaft = Image.new("L", (W, H), 0)
    sd = ImageDraw.Draw(shaft)
    span = float(H - by1)
    cx = (bx0 + bx1) / 2 + 12
    for y in range(by1, H):
        t = (y - by1) / span
        vert = (1.0 - t) ** 1.4
        half = 30 + 60 * t
        for x in range(int(cx - half - 6), int(cx + half + 6)):
            dx = (x - cx) / half
            horiz = max(0.0, 1.0 - dx * dx)
            a = 92 * vert * (horiz ** 1.3)
            if a > 1:
                shaft.putpixel((x, y), int(a))
    shaft = shaft.filter(ImageFilter.GaussianBlur(2.2))
    tint = Image.new("RGBA", (W, H), (128, 158, 226, 255))
    tint.putalpha(shaft)
    img = Image.alpha_composite(img, tint)

    # ---------- Glow jendela + vignette ----------
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.polygon([(492, 126), (590, 126), (628, 300), (452, 300)], fill=(60, 82, 132, 30))
    img = Image.alpha_composite(img, glow)

    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(64):
        vd.rectangle([i, i, W - i, H - i], outline=min(255, int(3.6 * (64 - i))))
    dark = Image.new("RGBA", (W, H), (6, 7, 13, 255))
    img = Image.composite(Image.alpha_composite(img, dark), img, vig)
    img.save(os.path.join(bg_dir, "bedroom_bg.png"))
    print(f"  bg     -> bedroom_bg.png {img.size}")


def make_balcony(bg_dir):
    W, H = 640, 200
    sky = Image.new("RGBA", (W, H), (9, 11, 20, 255))
    d = ImageDraw.Draw(sky)
    for y in range(H):
        t = y / float(H)
        c = (int(9 + 12 * t), int(11 + 14 * t), int(20 + 20 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    stars = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stars)
    random.seed(77)
    for _ in range(40):
        x, y = random.randint(0, W), random.randint(0, 90)
        sd.point([(x, y)], fill=(120, 130, 160, random.randint(40, 110)))
    sky = Image.alpha_composite(sky, stars)
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
    sky.save(os.path.join(bg_dir, "balcony_skyline.png"))

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
    rail.save(os.path.join(bg_dir, "balcony_railing.png"))

    mw, mh = 48, 48
    moon = Image.new("RGBA", (mw, mh), (0, 0, 0, 0))
    md = ImageDraw.Draw(moon)
    md.ellipse([6, 6, 42, 42], fill=(150, 162, 190, 90))
    md.ellipse([10, 10, 38, 38], fill=(206, 214, 232, 220))
    md.ellipse([14, 14, 26, 24], fill=(224, 230, 244, 235))
    clouds = Image.new("RGBA", (mw, mh), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    for cy in range(16, 36, 3):
        cd.line([(2, cy), (46, cy)], fill=(28, 34, 52, 150), width=2)
    moon = Image.alpha_composite(moon, clouds)
    moon.save(os.path.join(bg_dir, "moon_dim.png"))
    print("  bg     -> balcony_skyline, balcony_railing, moon_dim")


def make_corridor(bg_dir):
    """Lorong apartemen (lantai 3-4), 1120px. Garis lantai y=230.
    Hanya pintu kamar, tangga, 2 pintu tetangga, dan lift."""
    W, H = 1120, 360
    FLOOR_Y = 230
    img = Image.new("RGBA", (W, H), (17, 19, 28, 255))
    d = ImageDraw.Draw(img)

    d.rectangle([0, 0, W, 34], fill=(14, 16, 24, 255))
    d.line([(0, 34), (W, 34)], fill=(30, 33, 44, 255))

    for y in range(34, FLOOR_Y):
        t = (y - 34) / float(FLOOR_Y - 34)
        c = (int(30 + 14 * t), int(33 + 15 * t), int(47 + 16 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    d.rectangle([0, FLOOR_Y - 8, W, FLOOR_Y], fill=(42, 46, 60, 255))
    d.rectangle([0, FLOOR_Y - 3, W, FLOOR_Y], fill=(30, 33, 44, 255))

    for y in range(FLOOR_Y, H):
        t = (y - FLOOR_Y) / float(H - FLOOR_Y)
        c = (int(32 + 16 * t), int(34 + 16 * t), int(44 + 18 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    for y in range(FLOOR_Y, H, 22):
        d.line([(0, y), (W, y)], fill=(21, 23, 31, 255))
    for x in range(-40, W, 66):
        d.line([(x, FLOOR_Y), (x + 22, H)], fill=(25, 27, 35, 255))

    for lx in (200, 560, 920):
        d.rectangle([lx - 44, 2, lx + 44, 12], fill=(52, 58, 76, 255))
        d.rectangle([lx - 38, 4, lx + 38, 10], fill=(158, 168, 196, 255))

    def wood_door(x0, x1):
        d.rectangle([x0 - 3, 166, x1 + 3, FLOOR_Y], fill=(48, 39, 43, 255))
        d.rectangle([x0, 169, x1, FLOOR_Y - 2], fill=(66, 53, 55, 255))
        d.rectangle([x0 + 3, 172, x1 - 3, FLOOR_Y - 5], fill=(57, 46, 48, 255))
        d.rectangle([x0 + 6, 176, x1 - 6, 196], fill=(48, 38, 40, 255))
        d.rectangle([x0 + 6, 202, x1 - 6, FLOOR_Y - 10], fill=(48, 38, 40, 255))
        d.line([(x0 + 6, 176), (x1 - 6, 176)], fill=(80, 66, 68, 255))
        d.line([(x0 + 6, 202), (x1 - 6, 202)], fill=(80, 66, 68, 255))
        d.ellipse([x1 - 13, 200, x1 - 7, 207], fill=(190, 170, 98, 255))
        d.point([(x1 - 11, 202)], fill=(226, 210, 142, 255))

    wood_door(40, 84)          # pintu kamar Arutala
    # Pintu tangga (logam)
    d.rectangle([150, 166, 194, FLOOR_Y], fill=(44, 48, 62, 255))
    d.rectangle([154, 169, 190, FLOOR_Y - 2], fill=(58, 62, 78, 255))
    d.rectangle([158, 173, 186, 188], fill=(72, 78, 96, 255))
    d.line([(172, 173), (172, 188)], fill=(44, 48, 62, 255))
    d.ellipse([178, 198, 187, 207], fill=(156, 164, 186, 255))
    wood_door(300, 344)        # tetangga A
    wood_door(520, 564)        # tetangga B
    # Lift (kanan) — pintu ganda logam (sedikit lebih besar, wajar untuk lift)
    d.rectangle([896, 150, 984, FLOOR_Y], fill=(40, 44, 58, 255))
    d.rectangle([900, 154, 980, FLOOR_Y - 2], fill=(56, 60, 76, 255))
    d.rectangle([904, 158, 938, FLOOR_Y - 5], fill=(44, 48, 62, 255))
    d.rectangle([942, 158, 976, FLOOR_Y - 5], fill=(44, 48, 62, 255))
    d.line([(938, 158), (938, FLOOR_Y - 5)], fill=(28, 31, 41, 255))
    d.line([(942, 158), (942, FLOOR_Y - 5)], fill=(28, 31, 41, 255))
    d.rectangle([982, 168, 996, 214], fill=(34, 38, 50, 255))     # panel tombol
    for by in (174, 188, 202):
        d.ellipse([985, by, 991, by + 6], fill=(150, 122, 84, 255))
    d.rectangle([914, 130, 966, 146], fill=(18, 22, 32, 255))     # display lantai
    d.rectangle([915, 131, 965, 145], fill=(26, 34, 48, 255))
    # Papan nomor lantai (teks diisi Label)
    d.rectangle([420, 40, 476, 62], fill=(38, 42, 56, 255))
    d.rectangle([422, 42, 474, 60], fill=(52, 57, 74, 255))

    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for lx in (200, 560, 920):
        gd.polygon([(lx - 30, 12), (lx + 30, 12), (lx + 90, H), (lx - 90, H)],
                   fill=(80, 96, 140, 22))
    img = Image.alpha_composite(img, glow)

    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(80):
        vd.rectangle([i, i, W - i, H - i], outline=min(255, int(2.6 * (80 - i))))
    dark = Image.new("RGBA", (W, H), (5, 6, 11, 255))
    img = Image.composite(Image.alpha_composite(img, dark), img, vig)
    img.save(os.path.join(bg_dir, "corridor_bg.png"))
    print(f"  bg     -> corridor_bg.png {img.size}")


def make_rooftop(bg_dir):
    """Atap gedung (lantai 5): langit + skyline + PAGAR memanjang + lantai beton.
    Lebar 1120 agar sejajar lorong. Lantai 5 langsung tampil begini."""
    W, H = 640, 360
    img = Image.new("RGBA", (W, H), (9, 11, 20, 255))
    d = ImageDraw.Draw(img)

    # Langit gradien
    for y in range(0, 214):
        t = y / 214.0
        c = (int(9 + 14 * t), int(11 + 16 * t), int(22 + 24 * t), 255)
        d.line([(0, y), (W, y)], fill=c)

    # Bintang
    random.seed(55)
    for _ in range(70):
        x, y = random.randint(0, W), random.randint(0, 120)
        d.point([(x, y)], fill=(120, 130, 165, random.randint(50, 140)))

    # Bulan (kanan)
    d.ellipse([444, 40, 504, 100], fill=(70, 82, 120, 255))
    d.ellipse([452, 48, 496, 92], fill=(150, 162, 194, 255))
    d.ellipse([458, 54, 482, 78], fill=(210, 220, 240, 255))

    # Skyline gedung
    random.seed(88)
    x = -20
    while x < W + 20:
        bw = random.randint(28, 60)
        bh = random.randint(60, 150)
        by = 200 - bh
        base = 16 + random.randint(0, 8)
        d.rectangle([x, by, x + bw, 204], fill=(base, base + 3, base + 16, 255))
        d.line([(x, by), (x + bw, by)], fill=(base + 10, base + 12, base + 24, 255))
        for wx in range(x + 4, x + bw - 4, 8):
            for wy in range(by + 8, 198, 12):
                if random.random() < 0.2:
                    wc = (200, 190, 130, 180) if random.random() < 0.5 else (110, 150, 190, 160)
                    d.rectangle([wx, wy, wx + 3, wy + 5], fill=wc)
        x += bw + random.randint(3, 9)

    # Hujan
    random.seed(404)
    for _ in range(170):
        rx = random.randint(0, W)
        ry = random.randint(0, 214)
        d.line([(rx, ry), (rx - 3, ry + random.randint(6, 13))], fill=(74, 96, 138, 150))

    # Lantai atap (beton) y 204..360
    for y in range(204, H):
        t = (y - 204) / float(H - 204)
        c = (int(34 + 16 * t), int(35 + 16 * t), int(42 + 18 * t), 255)
        d.line([(0, y), (W, y)], fill=c)
    for y in range(204, H, 26):
        d.line([(0, y), (W, y)], fill=(24, 25, 32, 255))
    for x in range(-40, W, 72):
        d.line([(x, 204), (x + 30, H)], fill=(26, 27, 34, 255))

    # Genangan air + unit AC
    d.ellipse([70, 300, 200, 330], fill=(30, 36, 52, 120))
    d.ellipse([430, 318, 560, 344], fill=(30, 36, 52, 110))
    d.rectangle([250, 218, 340, 254], fill=(52, 56, 68, 255))
    d.rectangle([256, 224, 334, 248], fill=(38, 42, 54, 255))
    d.line([(256, 236), (334, 236)], fill=(60, 66, 80, 255))

    # PAGAR (railing) memanjang di belakang — pembatas atap
    rail_y = 200
    d.rectangle([0, rail_y - 4, W, rail_y + 4], fill=(58, 63, 80, 255))    # pegangan atas
    d.rectangle([0, rail_y - 4, W, rail_y - 2], fill=(86, 94, 116, 255))
    for bx in range(6, W, 14):
        d.rectangle([bx, rail_y + 4, bx + 3, rail_y + 34], fill=(48, 52, 68, 255))
        d.point([(bx, rail_y + 4)], fill=(72, 78, 98, 255))
    d.rectangle([0, rail_y + 30, W, rail_y + 34], fill=(40, 44, 58, 255))  # palang bawah

    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.polygon([(462, 60), (492, 60), (532, 300), (422, 300)], fill=(70, 92, 140, 40))
    img = Image.alpha_composite(img, glow)

    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(60):
        vd.rectangle([i, i, W - i, H - i], outline=min(255, int(3.0 * (60 - i))))
    dark = Image.new("RGBA", (W, H), (6, 7, 12, 255))
    img = Image.composite(Image.alpha_composite(img, dark), img, vig)
    img.save(os.path.join(bg_dir, "rooftop_bg.png"))
    print(f"  bg     -> rooftop_bg.png {img.size}")


def make_lift(bg_dir):
    """Interior lift SEMPIT — kotak lift kecil di tengah, sisi kiri/kanan
    dibiarkan kosong gelap. 640x360."""
    W, H = 640, 360
    img = Image.new("RGBA", (W, H), (5, 6, 10, 255))       # luar lift: gelap
    d = ImageDraw.Draw(img)

    L, R = 208, 432          # batas dinding belakang lift (sempit)
    CEIL = 46
    FLOOR_Y = 250

    # Dinding belakang (logam)
    for y in range(CEIL, FLOOR_Y):
        t = (y - CEIL) / float(FLOOR_Y - CEIL)
        c = (int(34 + 12 * t), int(38 + 12 * t), int(50 + 14 * t), 255)
        d.line([(L, y), (R, y)], fill=c)
    for x in range(L, R, 32):
        d.line([(x, CEIL), (x, FLOOR_Y)], fill=(28, 32, 42, 255))
    d.rectangle([L, FLOOR_Y - 6, R, FLOOR_Y], fill=(46, 50, 64, 255))

    # Dinding samping + langit-langit (perspektif sempit)
    d.rectangle([L - 16, CEIL - 8, L, FLOOR_Y], fill=(26, 30, 40, 255))
    d.rectangle([R, CEIL - 8, R + 16, FLOOR_Y], fill=(26, 30, 40, 255))
    d.rectangle([L - 16, CEIL - 16, R + 16, CEIL], fill=(20, 24, 32, 255))
    d.line([(L - 16, CEIL), (R + 16, CEIL)], fill=(52, 58, 74, 255))

    # Lantai (hanya selebar lift)
    for y in range(FLOOR_Y, H):
        t = (y - FLOOR_Y) / float(H - FLOOR_Y)
        c = (int(26 + 10 * t), int(28 + 10 * t), int(36 + 12 * t), 255)
        d.line([(L - 16, y), (R + 16, y)], fill=c)
    d.rectangle([L - 16, FLOOR_Y, R + 16, FLOOR_Y + 4], fill=(18, 20, 28, 255))

    # Pintu lift (dua daun) di tengah dinding belakang
    dl, dr = 250, 390
    d.rectangle([dl, 78, dr, FLOOR_Y], fill=(40, 44, 58, 255))
    d.rectangle([dl + 4, 82, 318, FLOOR_Y - 4], fill=(56, 60, 76, 255))
    d.rectangle([322, 82, dr - 4, FLOOR_Y - 4], fill=(56, 60, 76, 255))
    d.line([(320, 82), (320, FLOOR_Y - 4)], fill=(28, 31, 41, 255))
    for gx in (268, 372):
        d.line([(gx, 88), (gx, FLOOR_Y - 8)], fill=(44, 48, 62, 255))

    # Display lantai di atas pintu
    d.rectangle([288, 54, 352, 74], fill=(16, 20, 30, 255))
    d.rectangle([290, 56, 350, 72], fill=(26, 34, 48, 255))

    # Cermin kecil di dinding kiri
    d.rectangle([218, 96, 246, 176], fill=(48, 56, 74, 255))
    d.rectangle([221, 99, 243, 173], fill=(70, 88, 110, 235))
    d.rectangle([221, 99, 243, 116], fill=(92, 112, 138, 235))
    d.line([(226, 108), (240, 164)], fill=(140, 165, 195, 120), width=2)

    # Panel tombol (kanan dalam)
    d.rectangle([396, 104, 424, 190], fill=(30, 34, 46, 255))
    d.rectangle([399, 107, 421, 187], fill=(40, 44, 58, 255))
    for i, by in enumerate((114, 138, 162)):
        col = (150, 122, 84, 255)
        d.ellipse([405, by, 417, by + 12], fill=col)
        d.ellipse([408, by + 3, 414, by + 9], fill=(20, 22, 30, 255))

    # Peta lantai (kecil) di dinding kanan
    mx0, mx1 = 398, 426
    my0, my1 = 200, 240
    d.rectangle([mx0, my0, mx1, my1], fill=(28, 32, 44, 255))
    d.rectangle([mx0 + 2, my0 + 2, mx1 - 2, my1 - 2], fill=(20, 24, 34, 255))
    for i, ly in enumerate((my0 + 6, my0 + 16, my0 + 26)):
        d.rectangle([mx0 + 4, ly, mx1 - 4, ly + 7], fill=(50, 58, 78, 255))
        if i == 2:
            d.line([(mx0 + 5, ly + 2), (mx1 - 5, ly + 2)], fill=(120, 160, 200, 255))

    # Vignette
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(70):
        vd.rectangle([i, i, W - i, H - i], outline=min(255, int(3.2 * (70 - i))))
    dark = Image.new("RGBA", (W, H), (4, 5, 8, 255))
    img = Image.composite(Image.alpha_composite(img, dark), img, vig)
    img.save(os.path.join(bg_dir, "lift_bg.png"))
    print(f"  bg     -> lift_bg.png {img.size}")


def make_intro_panels(ui_dir):
    W, H = 320, 180
    OL = (10, 11, 17, 255)
    panels = []

    def base(bg_top, bg_bot):
        im = Image.new("RGBA", (W, H), (*bg_top, 255))
        dd = ImageDraw.Draw(im)
        for y in range(H):
            t = y / float(H)
            c = tuple(int(bg_top[i] + (bg_bot[i] - bg_top[i]) * t) for i in range(3))
            dd.line([(0, y), (W, y)], fill=(*c, 255))
        return im, dd

    # Panel 1 — gelap total, mata terpejam
    im, dd = base((8, 9, 14), (14, 16, 24))
    for (ex, ey) in ((120, 92), (200, 92)):
        dd.line([(ex - 16, ey), (ex + 16, ey)], fill=(70, 74, 90, 255), width=3)
        dd.line([(ex - 16, ey), (ex + 16, ey)], fill=(120, 126, 146, 255), width=1)
    panels.append(im)

    # Panel 2 — cahaya pucat, mata setengah terbuka
    im, dd = base((18, 20, 30), (26, 30, 44))
    dd.ellipse([60, 30, 260, 170], fill=(70, 82, 118, 70))
    dd.ellipse([90, 55, 230, 145], fill=(120, 134, 176, 60))
    for (ex, ey) in ((120, 92), (200, 92)):
        dd.ellipse([ex - 14, ey - 6, ex + 14, ey + 6], fill=(150, 156, 176, 220))
        dd.ellipse([ex - 6, ey - 4, ex + 6, ey + 4], fill=(40, 44, 60, 255))
    panels.append(im)

    # Panel 3 — blur kuat
    im, dd = base((22, 25, 36), (30, 34, 48))
    blur = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blur)
    bd.rectangle([0, 110, W, H], fill=(44, 40, 44, 150))
    bd.rectangle([30, 60, 120, 130], fill=(60, 70, 96, 120))
    bd.rectangle([200, 55, 300, 120], fill=(70, 78, 104, 110))
    blur = blur.filter(ImageFilter.GaussianBlur(6))
    im = Image.alpha_composite(im, blur)
    panels.append(im)

    # Panel 4 — jelas
    im, dd = base((20, 23, 34), (30, 34, 48))
    dd.rectangle([0, 112, W, H], fill=(40, 34, 36, 255))
    dd.rectangle([20, 60, 118, 130], fill=(56, 63, 88, 255))
    dd.rectangle([26, 66, 74, 86], fill=(96, 106, 134, 255))
    dd.rectangle([206, 46, 296, 120], fill=(15, 22, 42, 255))
    dd.rectangle([206, 46, 296, 120], outline=(56, 64, 86, 255), width=3)
    dd.ellipse([240, 58, 272, 90], fill=(206, 216, 236, 255))
    for (ex, ey) in ((150, 92), (176, 92)):
        dd.ellipse([ex - 7, ey - 8, ex + 7, ey + 8], fill=(233, 203, 183, 255))
        dd.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], fill=(18, 20, 28, 255))
    panels.append(im)

    out_paths = []
    for idx, p in enumerate(panels):
        frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        fd = ImageDraw.Draw(frame)
        fd.rectangle([3, 3, W - 4, H - 4], outline=OL, width=6)
        p = Image.alpha_composite(p, frame)
        path = os.path.join(ui_dir, f"intro_panel_{idx + 1}.png")
        p.save(path)
        out_paths.append(path)
    print(f"  intro  -> {len(out_paths)} panel komik")


# ----------------------------------------------------------------------------
# Kilas balik — 4 potongan (160x120)
# ----------------------------------------------------------------------------
def make_flashbacks(fb_dir):
    def blend(fg, alpha, bg):
        a = alpha / 255.0
        return (int(fg[0] * a + bg[0] * (1 - a)),
                int(fg[1] * a + bg[1] * (1 - a)),
                int(fg[2] * a + bg[2] * (1 - a)), 255)

    slides = [
        ((46, 40, 52), (30, 26, 36), (196, 170, 178), "window_laugh"),
        ((28, 34, 50), (18, 22, 36), (120, 150, 190), "typing"),
        ((40, 28, 34), (24, 16, 20), (170, 110, 120), "door"),
        ((40, 38, 32), (26, 24, 20), (190, 176, 130), "tea"),
    ]
    for idx, (bg0, bg1, acc, kind) in enumerate(slides):
        im = Image.new("RGBA", (160, 120), (*bg0, 255))
        d = ImageDraw.Draw(im)
        for y in range(120):
            t = y / 120.0
            c = tuple(int(bg0[i] + (bg1[i] - bg0[i]) * t) for i in range(3))
            d.line([(0, y), (160, y)], fill=(*c, 255))
        if kind == "window_laugh":
            d.rectangle([40, 18, 120, 78], fill=(20, 26, 42, 255))
            d.rectangle([40, 18, 120, 78], outline=(60, 66, 88, 255))
            d.line([(80, 18), (80, 78)], fill=(60, 66, 88, 255))
            d.ellipse([70, 40, 90, 62], fill=(*acc, 255))
            d.arc([72, 48, 88, 62], 0, 180, fill=(60, 40, 45, 255))
            d.rectangle([66, 62, 94, 96], fill=blend(acc, 200, bg1))
        elif kind == "typing":
            d.rectangle([48, 40, 112, 92], fill=(14, 18, 30, 255))
            d.rectangle([52, 44, 108, 84], fill=(24, 32, 52, 255))
            for i in range(4):
                d.line([(58, 52 + i * 8), (58 + (40 if i != 3 else 16), 52 + i * 8)],
                       fill=blend(acc, 190, (24, 32, 52)))
            d.line([(58, 76), (74, 76)], fill=(200, 90, 90, 255))
            d.rectangle([70, 88, 90, 108], fill=blend(acc, 160, bg1))
        elif kind == "door":
            d.rectangle([30, 8, 90, 118], fill=(34, 24, 26, 255))
            d.rectangle([30, 8, 90, 118], outline=(20, 14, 16, 255))
            d.rectangle([36, 16, 84, 60], fill=(28, 20, 22, 255))
            d.rectangle([36, 68, 84, 110], fill=(28, 20, 22, 255))
            d.ellipse([78, 62, 83, 67], fill=(*acc, 255))
            d.rectangle([92, 20, 150, 116], fill=blend((18, 12, 14), 180, bg1))
        elif kind == "tea":
            d.ellipse([50, 78, 110, 100], fill=(40, 42, 52, 255))
            d.rectangle([60, 46, 96, 82], fill=(150, 156, 168, 255))
            d.rectangle([60, 46, 64, 82], fill=(178, 184, 196, 255))
            d.arc([94, 54, 110, 72], 270, 90, fill=(140, 146, 158, 255))
            d.rectangle([60, 46, 96, 50], fill=(96, 74, 58, 255))
            d.line([(72, 36), (72, 44)], fill=blend((200, 208, 220), 120, bg1))
            d.line([(84, 34), (84, 44)], fill=blend((200, 208, 220), 100, bg1))
        d.rectangle([6, 6, 153, 113], outline=blend(acc, 70, bg1))
        im.save(os.path.join(fb_dir, f"fb_{idx + 1}.png"))
    print("  fb     -> fb_1..fb_4")


if __name__ == "__main__":
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    A = os.path.join(base, "assets")
    CHAR = os.path.join(A, "characters")
    BG = os.path.join(A, "backgrounds")
    PROPS = os.path.join(A, "props")
    UI = os.path.join(A, "ui")
    FB = os.path.join(A, "flashbacks")
    for path in (CHAR, BG, PROPS, UI, FB):
        os.makedirs(path, exist_ok=True)

    print("Karakter:")
    build_sheet(os.path.join(CHAR, "player_sheet.png"))
    print("Props:")
    make_props(PROPS)
    print("Background:")
    make_bedroom(BG)
    make_balcony(BG)
    make_corridor(BG)
    make_rooftop(BG)
    make_lift(BG)
    make_intro_panels(UI)
    print("Kilas balik:")
    make_flashbacks(FB)
    print("Selesai: semua aset v2 dihasilkan.")
