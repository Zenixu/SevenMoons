#!/usr/bin/env python3
import os
import random
from PIL import Image, ImageDraw

def create_bedroom_bg(path):
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), (18, 20, 30, 255))
    draw = ImageDraw.Draw(img)

    # Floor (y: 200 to 360) - dark warm wood planks
    for y in range(200, h):
        c = (28 + (y % 4), 22 + (y % 4), 26 + (y % 3), 255)
        draw.line([(0, y), (w, y)], fill=c)
    # Floor plank seams every 40px horizontal
    for x in range(0, w, 40):
        draw.line([(x, 200), (x, h)], fill=(16, 12, 16, 180))

    # Wall baseboard
    draw.rectangle([0, 196, w, 200], fill=(35, 38, 50, 255))

    # Window (x: 240 to 400, y: 50 to 180)
    draw.rectangle([236, 46, 404, 184], fill=(30, 35, 48, 255)) # frame
    draw.rectangle([240, 50, 400, 180], fill=(10, 14, 26, 255)) # glass
    # Rain streaks on window
    random.seed(101)
    for _ in range(80):
        rx = random.randint(242, 398)
        ry = random.randint(52, 170)
        rlen = random.randint(6, 14)
        draw.line([(rx, ry), (rx - 2, ry + rlen)], fill=(60, 80, 120, 140), width=1)
    # Window panes
    draw.line([(320, 50), (320, 180)], fill=(30, 35, 48, 255), width=3)
    draw.line([(240, 115), (400, 115)], fill=(30, 35, 48, 255), width=3)

    # Bed area (left side: x: 30 to 170, y: 170 to 280)
    draw.rectangle([30, 170, 170, 280], fill=(22, 25, 38, 255)) # bed frame
    draw.rectangle([34, 174, 166, 276], fill=(38, 44, 62, 255)) # blanket
    draw.rectangle([40, 176, 90, 200], fill=(50, 58, 80, 255))   # pillow

    # Desk area (right side: x: 470 to 590, y: 210 to 290)
    draw.rectangle([470, 210, 590, 230], fill=(42, 34, 38, 255)) # table top
    draw.rectangle([476, 230, 484, 290], fill=(32, 25, 28, 255)) # leg 1
    draw.rectangle([576, 230, 584, 290], fill=(32, 25, 28, 255)) # leg 2

    # Balcony door on far left (x: 5, y: 60 to 200)
    draw.rectangle([4, 56, 26, 204], fill=(35, 40, 55, 255))
    draw.rectangle([6, 60, 24, 200], fill=(12, 16, 28, 255))

    img.save(path)
    print(f"Created: {path}")

def create_balcony_art(skyline_path, railing_path, moon_path, sil_path):
    # 1. City Skyline
    w, h = 640, 200
    sky = Image.new("RGBA", (w, h), (8, 10, 18, 255))
    draw = ImageDraw.Draw(sky)
    random.seed(77)
    # Buildings silhouette
    x = 0
    while x < w:
        bw = random.randint(25, 60)
        bh = random.randint(60, 160)
        by = h - bh
        bcol = (14 + random.randint(0, 8), 16 + random.randint(0, 10), 26 + random.randint(0, 12), 255)
        draw.rectangle([x, by, x + bw, h], fill=bcol)
        # Windows
        for wx in range(x + 4, x + bw - 4, 8):
            for wy in range(by + 8, h - 10, 14):
                if random.random() < 0.25:
                    win_col = (180, 190, 140, 180) if random.random() < 0.5 else (100, 140, 180, 150)
                    draw.rectangle([wx, wy, wx + 4, wy + 6], fill=win_col)
        x += bw + random.randint(2, 8)
    sky.save(skyline_path)
    print(f"Created: {skyline_path}")

    # 2. Balcony Railing (640x32)
    rw, rh = 640, 32
    rail = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
    rdraw = ImageDraw.Draw(rail)
    # Top handrail
    rdraw.rectangle([0, 0, rw, 5], fill=(50, 55, 70, 255))
    rdraw.rectangle([0, 1, rw, 3], fill=(70, 78, 98, 255))
    # Vertical balusters
    for bx in range(10, rw, 16):
        rdraw.rectangle([bx, 5, bx + 3, rh], fill=(42, 46, 60, 255))
    # Bottom rail
    rdraw.rectangle([0, rh - 4, rw, rh], fill=(36, 40, 52, 255))
    rail.save(railing_path)
    print(f"Created: {railing_path}")

    # 3. Dim Moon (48x48)
    mw, mh = 48, 48
    moon = Image.new("RGBA", (mw, mh), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(moon)
    # Moon circle
    mdraw.ellipse([8, 8, 40, 40], fill=(170, 180, 205, 180))
    mdraw.ellipse([12, 10, 36, 34], fill=(210, 220, 235, 230))
    # Soft mist/cloud over moon
    for cy in range(18, 36, 3):
        mdraw.line([(4, cy), (44, cy)], fill=(30, 38, 55, 140), width=2)
    moon.save(moon_path)
    print(f"Created: {moon_path}")

    # 4. Silhouette figure (22x52)
    sw, sh = 22, 52
    sil = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sil)
    # Head
    sdraw.ellipse([6, 2, 16, 14], fill=(8, 10, 15, 255))
    # Hair silhouette
    sdraw.ellipse([5, 1, 17, 10], fill=(5, 6, 10, 255))
    # Torso/Coat
    sdraw.rectangle([4, 14, 18, 38], fill=(8, 10, 15, 255))
    # Legs
    sdraw.rectangle([5, 38, 10, 50], fill=(6, 8, 12, 255))
    sdraw.rectangle([12, 38, 17, 50], fill=(6, 8, 12, 255))
    sil.save(sil_path)
    print(f"Created: {sil_path}")

def create_props(base_dir):
    # Phone (16x16)
    ph = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(ph)
    pdraw.rectangle([3, 1, 13, 15], fill=(25, 28, 35, 255)) # body
    pdraw.rectangle([4, 2, 12, 13], fill=(12, 15, 22, 255)) # screen
    pdraw.point([(8, 4), (8, 5)], fill=(120, 180, 240, 255)) # notif dot
    ph.save(os.path.join(base_dir, "phone.png"))

    # Photo frame (20x24)
    pf = Image.new("RGBA", (20, 24), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(pf)
    pdraw.rectangle([1, 1, 18, 22], fill=(60, 45, 35, 255)) # wood frame
    pdraw.rectangle([3, 3, 16, 20], fill=(140, 130, 120, 255)) # sepia photo
    pdraw.ellipse([8, 6, 12, 11], fill=(80, 70, 65, 255)) # small head silhouette
    pdraw.rectangle([6, 12, 14, 18], fill=(80, 70, 65, 255))
    pf.save(os.path.join(base_dir, "photo_frame.png"))

    # Tea cup (16x16)
    tc = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(tc)
    tdraw.ellipse([2, 11, 14, 15], fill=(45, 48, 56, 255)) # saucer
    tdraw.rectangle([4, 6, 12, 12], fill=(160, 165, 175, 255)) # mug
    tdraw.rectangle([12, 7, 14, 11], fill=(140, 145, 155, 255)) # handle
    tdraw.line([(7, 3), (7, 5)], fill=(180, 190, 200, 100)) # faint cold steam
    tc.save(os.path.join(base_dir, "tea_cup.png"))

    # Mirror (24x36)
    mr = Image.new("RGBA", (24, 36), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(mr)
    mdraw.rectangle([1, 1, 22, 34], fill=(50, 42, 38, 255)) # wooden border
    mdraw.rectangle([3, 3, 20, 32], fill=(60, 75, 95, 230)) # reflective glass
    mdraw.line([(5, 5), (12, 28)], fill=(120, 145, 175, 150), width=2) # glare line
    mr.save(os.path.join(base_dir, "mirror.png"))

    # Wall clock (24x24)
    ck = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(ck)
    cdraw.ellipse([1, 1, 22, 22], fill=(40, 45, 55, 255)) # frame
    cdraw.ellipse([3, 3, 20, 20], fill=(220, 225, 230, 255)) # clock face
    cdraw.point([(12, 12)], fill=(20, 20, 20, 255)) # center
    cdraw.line([(12, 12), (8, 9)], fill=(20, 20, 20, 255), width=2)  # hour hand ~02
    cdraw.line([(12, 12), (18, 14)], fill=(40, 40, 40, 255), width=1) # minute hand ~47
    ck.save(os.path.join(base_dir, "wall_clock.png"))

    # Door (28x48)
    dr = Image.new("RGBA", (28, 48), (0, 0, 0, 0))
    ddraw = ImageDraw.Draw(dr)
    ddraw.rectangle([1, 1, 26, 46], fill=(42, 35, 38, 255)) # door frame
    ddraw.rectangle([3, 3, 24, 45], fill=(32, 26, 28, 255)) # wood door
    ddraw.point([(21, 25), (21, 26)], fill=(180, 160, 90, 255)) # brass handle
    dr.save(os.path.join(base_dir, "door.png"))

    # Player sprite (16x28)
    pl = Image.new("RGBA", (16, 28), (0, 0, 0, 0))
    pldraw = ImageDraw.Draw(pl)
    # Head & hair
    pldraw.ellipse([4, 2, 12, 10], fill=(40, 36, 38, 255)) # messy hair
    pldraw.rectangle([5, 6, 11, 11], fill=(225, 200, 185, 255)) # face skin
    pldraw.point([(6, 8), (9, 8)], fill=(45, 40, 45, 255)) # eyes
    # Torso (teal loose sweater)
    pldraw.rectangle([3, 12, 13, 20], fill=(38, 64, 72, 255))
    # Trousers (dark grey)
    pldraw.rectangle([4, 20, 7, 26], fill=(30, 32, 38, 255))
    pldraw.rectangle([9, 20, 12, 26], fill=(30, 32, 38, 255))
    pl.save(os.path.join(base_dir, "player.png"))

def create_flashbacks(base_dir):
    slides = [
        ((40, 35, 45), (140, 120, 130), "fb_1.png"), # 1. Kirana laughing by window
        ((30, 35, 48), (110, 130, 160), "fb_2.png"), # 2. Typing & erasing message
        ((45, 30, 35), (130, 100, 110), "fb_3.png"), # 3. Door closing hard
        ((38, 38, 32), (150, 140, 110), "fb_4.png")  # 4. Tea offered and refused
    ]
    for bg_col, fig_col, name in slides:
        im = Image.new("RGBA", (160, 120), (*bg_col, 255))
        d = ImageDraw.Draw(im)
        # Vignette / soft frame
        d.rectangle([10, 10, 150, 110], outline=(*fig_col, 80), width=1)
        # Distorted nostalgic shapes
        d.ellipse([60, 30, 100, 70], fill=(*fig_col, 160))
        d.rectangle([50, 70, 110, 105], fill=(*fig_col, 140))
        im.save(os.path.join(base_dir, name))
        print(f"Created: {name}")

if __name__ == '__main__':
    art_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/art"))
    os.makedirs(art_dir, exist_ok=True)
    create_bedroom_bg(os.path.join(art_dir, "bedroom_bg.png"))
    create_balcony_art(
        os.path.join(art_dir, "balcony_skyline.png"),
        os.path.join(art_dir, "balcony_railing.png"),
        os.path.join(art_dir, "moon_dim.png"),
        os.path.join(art_dir, "silhouette_figure.png")
    )
    create_props(art_dir)
    create_flashbacks(art_dir)
    print("All pixel-art assets generated successfully!")
