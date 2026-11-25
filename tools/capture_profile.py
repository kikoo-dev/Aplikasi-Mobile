"""Ambil screenshot halaman Profil & Edit Profil secara terpisah.

Dijalankan setelah aplikasi berada di beranda/feed.
Jalankan: python tools/capture_profile.py
"""
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "screens")
ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
PKG = "com.example.social_profile_app"
ACTIVITY = f"{PKG}/.MainActivity"


def adb(*args, binary=False):
    if binary:
        return subprocess.run([ADB, *args], capture_output=True).stdout
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    )


def dump_labels():
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("shell", "cat", "/sdcard/ui.xml").stdout
    rows = []
    for m in re.finditer(r"<node[^>]*>", xml):
        tag = m.group(0)

        def a(n):
            r = re.search(n + r'="([^"]*)"', tag)
            return r.group(1) if r else ""

        desc = a("content-desc") or a("text")
        b = re.findall(r"\d+", a("bounds"))
        if desc and len(b) == 4:
            rows.append((
                desc,
                (int(b[0]) + int(b[2])) // 2,
                (int(b[1]) + int(b[3])) // 2,
                a("clickable") == "true",
            ))
    return rows


def screen_text():
    return " | ".join(r[0] for r in dump_labels())


def wait_for(keyword, timeout=10.0, poll=0.7):
    end = time.time() + timeout
    while time.time() < end:
        if keyword.lower() in screen_text().lower():
            return True
        time.sleep(poll)
    return False


def tap_label(keyword, wait=1.5, exact=False):
    for desc, cx, cy, clickable in dump_labels():
        if not clickable:
            continue
        hit = (desc == keyword) if exact else (keyword.lower() in desc.lower())
        if hit:
            adb("shell", "input", "tap", str(cx), str(cy))
            time.sleep(wait)
            return True
    print(f"  ! label tidak ditemukan: {keyword!r}")
    return False


def tap(x, y, wait=1.2):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))
    time.sleep(wait)


def swipe(x1, y1, x2, y2, dur=450, wait=1.2):
    adb("shell", "input", "swipe", str(int(x1)), str(int(y1)),
        str(int(x2)), str(int(y2)), str(int(dur)))
    time.sleep(wait)


def shot(name):
    time.sleep(0.7)
    data = adb("exec-out", "screencap", "-p", binary=True)
    if not data or not data.startswith(b"\x89PNG"):
        print(f"  ! gagal ambil {name}")
        return None
    path = os.path.join(OUT, f"{name}.png")
    with open(path, "wb") as f:
        f.write(data)
    print(f"  -> {name}.png ({len(data)//1024} KB)")
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    adb("shell", "cmd", "uimode", "night", "no")

    # Pastikan app di depan
    focus = adb("shell", "dumpsys", "window", "displays").stdout
    if PKG not in focus:
        adb("shell", "am", "start", "-n", ACTIVITY)
        time.sleep(4.0)

    print("[A] Edit Profil (layar saat ini)")
    shot("10-edit-profil")

    print("[B] Kembali ke Profil Saya")
    adb("shell", "input", "keyevent", "4")
    time.sleep(2.5)
    if not wait_for("Profil Saya", timeout=6):
        # jika sudah di beranda, buka Profil Saya
        if wait_for("Feed Kampus", timeout=4):
            tap(872, 749, wait=3.0)
            wait_for("Profil Saya", timeout=6)
    shot("09-profil")

    print("\nSelesai.")


if __name__ == "__main__":
    main()
