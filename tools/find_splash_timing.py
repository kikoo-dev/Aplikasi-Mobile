"""Cari timing terbaik untuk menangkap splash screen (oranye penuh).

Jalankan: python tools/find_splash_timing.py
"""
import os
import subprocess
import time

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
PKG = "com.example.social_profile_app"
TMP = os.path.join(HERE, "_splash_test.png")


def adb(*args, binary=False):
    if binary:
        return subprocess.run([ADB, *args], capture_output=True).stdout
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    )


def orange_ratio(path):
    im = Image.open(path).convert("RGB").resize((40, 87))
    px = list(im.getdata())
    n = len(px)
    return sum(
        1 for r, g, b in px if r > 170 and 50 < g < 175 and b < 120
    ) / n


def main():
    adb("shell", "pm", "clear", PKG)
    time.sleep(2.0)
    adb("shell", "am", "start", "-n", f"{PKG}/.MainActivity")

    start = time.time()
    best = (0.0, 0.0)
    for _ in range(30):
        elapsed = time.time() - start
        data = adb("exec-out", "screencap", "-p", binary=True)
        if data and data.startswith(b"\x89PNG"):
            with open(TMP, "wb") as f:
                f.write(data)
            try:
                ratio = orange_ratio(TMP)
                print(f"t={elapsed:5.2f}s  orange={ratio:.2f}")
                if ratio > best[0]:
                    best = (ratio, elapsed)
            except Exception as e:
                print(f"t={elapsed:5.2f}s  err {e}")
        time.sleep(0.15)

    print(f"\nTiming terbaik: {best[1]:.2f}s (orange={best[0]:.2f})")
    if os.path.exists(TMP):
        os.remove(TMP)


if __name__ == "__main__":
    main()
