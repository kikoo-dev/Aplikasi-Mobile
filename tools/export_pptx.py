"""Export PPTX ke PNG per slide memakai PowerPoint (Windows COM).

Jalankan: python tools/export_pptx.py
Output  : tools/preview/slide-01.png ...
"""
import os
import sys
import win32com.client

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PPTX = os.path.join(ROOT, "Presentasi_ProfilKita_ITENAS.pptx")
OUT_DIR = os.path.join(HERE, "preview")


def main():
    if not os.path.exists(PPTX):
        print("File PPTX tidak ditemukan:", PPTX)
        sys.exit(1)

    os.makedirs(OUT_DIR, exist_ok=True)

    app = win32com.client.Dispatch("PowerPoint.Application")
    # PowerPoint butuh window visible untuk beberapa operasi export
    try:
        app.Visible = True
    except Exception:
        pass

    pres = app.Presentations.Open(PPTX, WithWindow=False)
    try:
        total = pres.Slides.Count
        print(f"Total slide: {total}")
        for i in range(1, total + 1):
            out = os.path.join(OUT_DIR, f"slide-{i:02d}.png")
            pres.Slides(i).Export(out, "PNG", 1600, 900)
            print("  ->", out)
    finally:
        pres.Close()
        app.Quit()

    print("Selesai.")


if __name__ == "__main__":
    main()
