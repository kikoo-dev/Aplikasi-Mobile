"""Crop & siapkan screenshot HP agar pas untuk frame di slide PPT.

- Memotong status bar + navigation bar.
- Menyeragamkan rasio (9:19.5).
- Menyimpan ke tools/screens_ready/

Jalankan: python tools/prepare_screens.py
"""
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "screens")
DST = os.path.join(HERE, "screens_ready")

# Rasio tampilan HP modern (tinggi : lebar) — portrait
TARGET_RATIO = 19.5 / 9


def prepare(path, out_path):
    im = Image.open(path).convert("RGB")
    w, h = im.size

    # Buang status bar atas (~3.5%) dan navigation bar bawah (~2.5%)
    top = int(h * 0.030)
    bottom = int(h * 0.975)
    im = im.crop((0, top, w, bottom))

    w, h = im.size
    current_ratio = h / w

    if current_ratio > TARGET_RATIO:
        # Terlalu tinggi -> potong atas & bawah
        new_h = int(w * TARGET_RATIO)
        offset = (h - new_h) // 2
        im = im.crop((0, offset, w, offset + new_h))
    elif current_ratio < TARGET_RATIO:
        # Terlalu lebar -> potong kiri & kanan
        new_w = int(h / TARGET_RATIO)
        offset = (w - new_w) // 2
        im = im.crop((offset, 0, offset + new_w, h))

    # Perkecil agar file PPT tidak terlalu besar
    im.thumbnail((560, 1215), Image.LANCZOS)
    im.save(out_path, "PNG", optimize=True)
    return im.size


def main():
    os.makedirs(DST, exist_ok=True)
    files = sorted(f for f in os.listdir(SRC) if f.endswith(".png"))
    if not files:
        print("Tidak ada screenshot di", SRC)
        return

    for f in files:
        src = os.path.join(SRC, f)
        dst = os.path.join(DST, f)
        size = prepare(src, dst)
        kb = os.path.getsize(dst) // 1024
        print(f"{f:26} -> {size[0]}x{size[1]} ({kb} KB)")

    print(f"\n{len(files)} gambar siap di {DST}")


if __name__ == "__main__":
    main()
