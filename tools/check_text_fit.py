"""Cek apakah ada teks yang terpotong/meluber di slide tertentu.

Membandingkan estimasi tinggi teks dengan tinggi kotak.
Jalankan: python tools/check_text_fit.py
"""
import os

from pptx import Presentation
from pptx.util import Emu

EMU_IN = 914400
PPTX = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    "Presentasi_ProfilKita_ITENAS.pptx")


def main():
    prs = Presentation(PPTX)
    problems = []

    for idx, slide in enumerate(prs.slides, 1):
        for shp in slide.shapes:
            if not shp.has_text_frame:
                continue
            tf = shp.text_frame
            full = "\n".join(p.text for p in tf.paragraphs)
            if not full.strip():
                continue

            box_w = (shp.width or 0) / EMU_IN
            box_h = (shp.height or 0) / EMU_IN
            if box_w < 0.2 or box_h < 0.15:
                continue

            total_h = 0.0
            for p in tf.paragraphs:
                sizes = [r.font.size.pt for r in p.runs if r.font.size]
                size = max(sizes) if sizes else 12
                chars_per_line = max(1, int(box_w * 72 / (size * 0.52)))
                lines = max(1, -(-len(p.text) // chars_per_line))
                spacing = p.line_spacing if isinstance(p.line_spacing, float) else 1.0
                total_h += lines * (size * 1.22 * spacing) / 72

            if total_h > box_h * 1.30 and total_h - box_h > 0.18:
                problems.append(
                    f"slide {idx:02d}: butuh {total_h:.2f}in, box {box_h:.2f}in "
                    f"-> {full[:50].replace(chr(10), ' ')!r}"
                )

    if problems:
        print(f"{len(problems)} teks berpotensi meluber:")
        for p in problems:
            print("  -", p)
    else:
        print("Semua teks muat di kotaknya.")


if __name__ == "__main__":
    main()
