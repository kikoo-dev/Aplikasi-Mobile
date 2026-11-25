"""Ambil screenshot + info layar saat ini, lalu analisis warnanya."""
import os
import subprocess

from PIL import Image, ImageStat

HERE = os.path.dirname(os.path.abspath(__file__))
ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
OUT = os.path.join(HERE, "screens", "_now.png")


def adb(*args, binary=False):
    if binary:
        return subprocess.run([ADB, *args], capture_output=True).stdout
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    )


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    data = adb("exec-out", "screencap", "-p", binary=True)
    with open(OUT, "wb") as f:
        f.write(data)

    im = Image.open(OUT).convert("RGB")
    st = ImageStat.Stat(im)
    print("ukuran :", im.size)
    print("mean   :", [round(x) for x in st.mean])
    print("stddev :", [round(x) for x in st.stddev])
    print("file   :", OUT)

    # cek apakah gambar hampir seragam (blank)
    if max(st.stddev) < 5:
        print("\n=> Layar hampir polos (blank/putih/hitam).")
    else:
        print("\n=> Ada konten di layar.")

    # cek crash log terakhir
    logs = adb("logcat", "-d", "-t", "1500")
    keywords = ("FATAL EXCEPTION", "E/flutter", "Unhandled Exception",
                "DartError", "crash")
    hits = [ln for ln in logs.splitlines()
            if any(k.lower() in ln.lower() for k in keywords)]
    print(f"\nLog mencurigakan: {len(hits)}")
    for ln in hits[-15:]:
        print("  ", ln[:200])


if __name__ == "__main__":
    main()
