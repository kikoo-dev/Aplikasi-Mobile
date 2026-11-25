"""Generate ikon aplikasi ProfilKita (logo ITENAS) untuk Android & iOS.

Membuat PNG di berbagai ukuran lalu menimpa ikon default Flutter.

Jalankan: python tools/generate_icons.py
"""
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# Warna tema ITENAS
ORANGE = (242, 101, 34)
ORANGE_LIGHT = (255, 154, 77)
ORANGE_DARK = (209, 78, 14)
WHITE = (255, 255, 255)

# Ukuran ikon Android (mipmap)
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def make_icon(size, rounded=True):
    """Buat ikon: background gradient oranye + perisai putih + 'ITN'."""
    scale = 4  # supersampling agar halus
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # ---------- Background gradient ----------
    grad = Image.new("RGB", (1, s))
    gd = ImageDraw.Draw(grad)
    for y in range(s):
        t = y / max(1, s - 1)
        if t < 0.5:
            k = t / 0.5
            c = tuple(int(ORANGE_LIGHT[i] + (ORANGE[i] - ORANGE_LIGHT[i]) * k)
                      for i in range(3))
        else:
            k = (t - 0.5) / 0.5
            c = tuple(int(ORANGE[i] + (ORANGE_DARK[i] - ORANGE[i]) * k)
                      for i in range(3))
        gd.point((0, y), fill=c)
    grad = grad.resize((s, s))

    if rounded:
        mask = Image.new("L", (s, s), 0)
        md = ImageDraw.Draw(mask)
        radius = int(s * 0.22)
        md.rounded_rectangle([0, 0, s - 1, s - 1], radius=radius, fill=255)
        img.paste(grad, (0, 0), mask)
    else:
        img.paste(grad, (0, 0))

    d = ImageDraw.Draw(img)

    # ---------- Perisai putih ----------
    cx = s // 2
    top = int(s * 0.20)
    shield_w = int(s * 0.52)
    shield_h = int(s * 0.50)
    left = cx - shield_w // 2
    right = cx + shield_w // 2
    bottom = top + shield_h

    # Badan perisai (persegi atas + lengkung bawah)
    d.rounded_rectangle(
        [left, top, right, bottom - int(shield_h * 0.22)],
        radius=int(s * 0.05),
        fill=WHITE,
    )
    d.pieslice(
        [left, bottom - int(shield_h * 0.46), right, bottom + int(shield_h * 0.02)],
        start=0, end=180, fill=WHITE,
    )

    # ---------- Teks ITN ----------
    txt = "ITN"
    # Font default PIL; ukur manual
    try:
        from PIL import ImageFont
        font = None
        for candidate in (
            "C:/Windows/Fonts/seguisb.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
            "C:/Windows/Fonts/arial.ttf",
        ):
            if os.path.exists(candidate):
                font = ImageFont.truetype(candidate, int(s * 0.155))
                break
        if font is None:
            font = ImageFont.load_default()
    except Exception:
        font = None

    if font is not None:
        bbox = d.textbbox((0, 0), txt, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        d.text(
            (cx - tw / 2 - bbox[0], top + shield_h * 0.30 - bbox[1]),
            txt, font=font, fill=ORANGE_DARK,
        )
        _ = th

    # ---------- Pita "ITENAS" ----------
    try:
        from PIL import ImageFont
        small = ImageFont.truetype(
            "C:/Windows/Fonts/seguisb.ttf", int(s * 0.082)
        )
    except Exception:
        small = None

    if small is not None:
        band_txt = "ITENAS"
        bb = d.textbbox((0, 0), band_txt, font=small)
        bw = bb[2] - bb[0]
        by = int(s * 0.755)
        pad = int(s * 0.035)
        d.rounded_rectangle(
            [cx - bw / 2 - pad, by - pad * 0.55,
             cx + bw / 2 + pad, by + (bb[3] - bb[1]) + pad * 0.75],
            radius=int(s * 0.028),
            fill=WHITE,
        )
        d.text((cx - bw / 2 - bb[0], by - bb[1]), band_txt,
               font=small, fill=ORANGE_DARK)

    return img.resize((size, size), Image.LANCZOS)


def main():
    # ---------- Android ----------
    android_res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    for folder, size in ANDROID_SIZES.items():
        out_dir = os.path.join(android_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        icon = make_icon(size)
        path = os.path.join(out_dir, "ic_launcher.png")
        icon.save(path, "PNG")
        print(f"Android {folder:18} {size}x{size} -> {path}")

    # ---------- iOS ----------
    ios_dir = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets",
                           "AppIcon.appiconset")
    if os.path.isdir(ios_dir):
        ios_sizes = {
            "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40,
            "Icon-App-20x20@3x.png": 60, "Icon-App-29x29@1x.png": 29,
            "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
            "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80,
            "Icon-App-40x40@3x.png": 120, "Icon-App-60x60@2x.png": 120,
            "Icon-App-60x60@3x.png": 180, "Icon-App-76x76@1x.png": 76,
            "Icon-App-76x76@2x.png": 152, "Icon-App-83.5x83.5@2x.png": 167,
            "Icon-App-1024x1024@1x.png": 1024,
        }
        for name, size in ios_sizes.items():
            path = os.path.join(ios_dir, name)
            if os.path.exists(path):
                # iOS tidak boleh transparan & tidak rounded
                icon = make_icon(size, rounded=False).convert("RGB")
                icon.save(path, "PNG")
                print(f"iOS {name:28} {size}x{size}")

    # ---------- Web favicon ----------
    web_dir = os.path.join(ROOT, "web")
    if os.path.isdir(web_dir):
        for name, size in (("favicon.png", 32), ("icons/Icon-192.png", 192),
                           ("icons/Icon-512.png", 512)):
            path = os.path.join(web_dir, name)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            make_icon(size).save(path, "PNG")
            print(f"Web {name:28} {size}x{size}")

    # Simpan juga versi besar untuk dokumentasi
    os.makedirs(os.path.join(HERE, "icon"), exist_ok=True)
    make_icon(1024).save(os.path.join(HERE, "icon", "app_icon_1024.png"))
    print("\nSelesai. Ikon aplikasi diperbarui.")


if __name__ == "__main__":
    main()
