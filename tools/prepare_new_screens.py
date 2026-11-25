"""Siapkan screenshot fitur baru (crop + resize) untuk slide PPT.

Jalankan: python tools/prepare_new_screens.py
"""
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "screens_new")
DST = os.path.join(HERE, "screens_new_ready")

TARGET_RATIO = 19.5 / 9


def prepare(path, out_path):
    im = Image.open(path).convert("RGB")
    w, h = im.size

    top = int(h * 0.030)
    bottom = int(h * 0.975)
    im = im.crop((0, top, w, bottom))

    w, h = im.size
    ratio = h / w
    if ratio > TARGET_RATIO:
        new_h = int(w * TARGET_RATIO)
        offset = (h - new_h) // 2
        im = im.crop((0, offset, w, offset + new_h))
    elif ratio < TARGET_RATIO:
        new_w = int(h / TARGET_RATIO)
        offset = (w - new_w) // 2
        im = im.crop((offset, 0, offset + new_w, h))

    im.thumbnail((560, 1215), Image.LANCZOS)
    im.save(out_path, "PNG", optimize=True)
    return im.size


def main():
    os.makedirs(DST, exist_ok=True)
    files = sorted(f for f in os.listdir(SRC)
                   if f.endswith(".png") and not f.startswith("_"))
    for f in files:
        size = prepare(os.path.join(SRC, f), os.path.join(DST, f))
        kb = os.path.getsize(os.path.join(DST, f)) // 1024
        print(f"{f:30} {size[0]}x{size[1]} ({kb} KB)")
    print(f"\n{len(files)} gambar siap di {DST}")


if __name__ == "__main__":
    main()
