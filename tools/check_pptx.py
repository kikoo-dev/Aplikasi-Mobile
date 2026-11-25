"""Cek kualitas layout PPTX: shape keluar batas & estimasi teks meluber."""
import os
from pptx import Presentation
from pptx.util import Emu

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PPTX = os.path.join(ROOT, "Presentasi_ProfilKita_ITENAS.pptx")

EMU_IN = 914400


def main():
    prs = Presentation(PPTX)
    W = prs.slide_width
    H = prs.slide_height
    issues = []

    for idx, slide in enumerate(prs.slides, start=1):
        for shp in slide.shapes:
            # Lewati shape dekoratif besar (background & lingkaran bleed)
            if shp.width and shp.width >= W and shp.height >= H:
                continue
            if shp.shape_type is not None and "OVAL" in str(shp.shape_type):
                continue
            if shp.shape_type is not None and "AUTO_SHAPE" in str(shp.shape_type) \
                    and shp.width == shp.height and (shp.width or 0) > int(2.5 * EMU_IN):
                continue

            left = shp.left or 0
            top = shp.top or 0
            right = left + (shp.width or 0)
            bottom = top + (shp.height or 0)

            # toleransi 0.35 inci untuk shape dekoratif yang memang keluar
            tol = int(0.35 * EMU_IN)
            if left < -tol or top < -tol or right > W + tol or bottom > H + tol:
                issues.append(
                    f"slide {idx:02d}: shape '{shp.shape_type}' keluar batas "
                    f"(L={left/EMU_IN:.2f} T={top/EMU_IN:.2f} "
                    f"R={right/EMU_IN:.2f} B={bottom/EMU_IN:.2f})"
                )

            # Estimasi teks meluber
            if not shp.has_text_frame:
                continue
            tf = shp.text_frame
            full = "\n".join(p.text for p in tf.paragraphs)
            if not full.strip():
                continue

            box_w_in = (shp.width or 0) / EMU_IN
            box_h_in = (shp.height or 0) / EMU_IN
            if box_w_in <= 0.1 or box_h_in <= 0.1:
                continue

            # estimasi baris: lebar rata-rata karakter ~0.5 * font size
            total_lines = 0
            max_size = 0
            for p in tf.paragraphs:
                sizes = [r.font.size.pt for r in p.runs if r.font.size]
                size = max(sizes) if sizes else 12
                max_size = max(max_size, size)
                chars_per_line = max(
                    1, int(box_w_in * 72 / (size * 0.50))
                )
                text_len = len(p.text)
                total_lines += max(1, -(-text_len // chars_per_line))

            needed_h = total_lines * (max_size * 1.30) / 72
            if needed_h > box_h_in * 1.45 and needed_h - box_h_in > 0.25:
                issues.append(
                    f"slide {idx:02d}: teks mungkin meluber "
                    f"(butuh ~{needed_h:.2f}in, box {box_h_in:.2f}in) -> "
                    f"'{full[:45].replace(chr(10), ' ')}...'"
                )

    if issues:
        print(f"Ditemukan {len(issues)} potensi masalah:\n")
        for i in issues:
            print(" -", i)
    else:
        print("Layout OK: tidak ada shape keluar batas / teks meluber.")


if __name__ == "__main__":
    main()
