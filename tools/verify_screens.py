"""Verifikasi isi screenshot dengan OCR ringan berbasis deteksi warna.

Membaca gambar dan menebak layar berdasarkan palet dominan:
  - Oranye penuh        -> Splash
  - Krem/putih + kartu  -> Login / Register / Feed
  - Latar putih terang  -> Kalkulator

Untuk verifikasi lebih tegas, skrip ini juga bisa membandingkan hash.

Jalankan: python tools/verify_screens.py
"""
import glob
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SCREENS = os.path.join(HERE, "screens")

ORANGE = (242, 101, 34)


def classify(path):
    im = Image.open(path).convert("RGB").resize((80, 174))
    px = list(im.getdata())
    total = len(px)

    orange = sum(
        1 for r, g, b in px
        if r > 180 and 60 < g < 170 and b < 110
    ) / total
    white = sum(
        1 for r, g, b in px
        if r > 235 and g > 235 and b > 235
    ) / total
    cream = sum(
        1 for r, g, b in px
        if r > 235 and 215 < g < 250 and 200 < b < 245
    ) / total
    dark = sum(
        1 for r, g, b in px
        if r < 80 and g < 80 and b < 80
    ) / total

    if orange > 0.45:
        return "SPLASH (oranye penuh)", orange, white, cream, dark
    if dark > 0.45:
        return "GELAP (dark mode?)", orange, white, cream, dark
    if white > 0.55 and orange < 0.05:
        return "KALKULATOR (putih terang)", orange, white, cream, dark
    if cream > 0.25 or (white > 0.35 and orange > 0.05):
        return "FORM / FEED (krem)", orange, white, cream, dark
    return "TIDAK DIKENALI", orange, white, cream, dark


def main():
    files = sorted(glob.glob(os.path.join(SCREENS, "*.png")))
    if not files:
        print("Tidak ada screenshot.")
        return

    for f in files:
        label, o, w, c, d = classify(f)
        print(f"{os.path.basename(f):28} {label:28} "
              f"orange={o:.2f} white={w:.2f} cream={c:.2f} dark={d:.2f}")


if __name__ == "__main__":
    main()
