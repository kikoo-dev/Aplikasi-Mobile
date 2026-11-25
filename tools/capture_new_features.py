"""Ambil screenshot fitur baru (komentar & hapus) untuk PPT.

Jalankan: python tools/capture_new_features.py
Output  : tools/screens_new/*.png
"""
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "screens_new")
ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
PKG = "com.example.social_profile_app"


def adb(*args, binary=False):
    if binary:
        return subprocess.run([ADB, *args], capture_output=True).stdout
    return subprocess.run([ADB, *args], capture_output=True, text=True,
                          encoding="utf-8", errors="ignore")


def nodes():
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("shell", "cat", "/sdcard/ui.xml").stdout
    out = []
    for m in re.finditer(r"<node[^>]*>", xml):
        tag = m.group(0)

        def a(n):
            r = re.search(n + r'="([^"]*)"', tag)
            return r.group(1) if r else ""

        b = re.findall(r"\d+", a("bounds"))
        if len(b) != 4:
            continue
        out.append({
            "label": a("content-desc") or a("text"),
            "x": (int(b[0]) + int(b[2])) // 2,
            "y": (int(b[1]) + int(b[3])) // 2,
            "click": a("clickable") == "true",
        })
    return out


def screen_text():
    return " | ".join(n["label"] for n in nodes())


def wait_for(kw, timeout=12.0, poll=0.7):
    end = time.time() + timeout
    while time.time() < end:
        if kw.lower() in screen_text().lower():
            return True
        time.sleep(poll)
    return False


def tap_xy(x, y, wait=0.9):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))
    time.sleep(wait)


def tap_label(kw, wait=1.5, exact=False):
    for n in nodes():
        if not n["click"]:
            continue
        hit = (n["label"] == kw) if exact else (kw.lower() in n["label"].lower())
        if hit:
            tap_xy(n["x"], n["y"], wait)
            return True
    return False


def shot(name):
    os.makedirs(OUT, exist_ok=True)
    time.sleep(0.6)
    data = adb("exec-out", "screencap", "-p", binary=True)
    if data and data.startswith(b"\x89PNG"):
        p = os.path.join(OUT, f"{name}.png")
        with open(p, "wb") as f:
            f.write(data)
        print(f"   -> {name}.png ({len(data)//1024} KB)")
        return p
    print(f"   ! gagal {name}")
    return None


def main():
    os.makedirs(OUT, exist_ok=True)
    adb("shell", "cmd", "uimode", "night", "no")
    time.sleep(1.2)

    # Pastikan app di depan
    adb("shell", "am", "start", "-n", f"{PKG}/.MainActivity")
    time.sleep(5)
    if not wait_for("Feed Kampus", timeout=15):
        print("! tidak di beranda, coba scroll")
        adb("shell", "input", "keyevent", "4")
        time.sleep(2)
        wait_for("Feed Kampus", timeout=8)

    # ---------- 1. Feed dengan foto ----------
    print("[1] Feed dengan foto")
    adb("shell", "input", "swipe", "540", "1800", "540", "900", "400")
    time.sleep(1.5)
    shot("fitur-01-feed")

    # ---------- 2. Komentar ----------
    print("[2] Halaman komentar")
    # cari postingan yang punya komentar
    target = None
    for n in nodes():
        if "komentar" in n["label"].lower() and n["click"]:
            target = n
            break
    if target:
        tap_xy(target["x"], target["y"], wait=3.5)
        if wait_for("Komentar", timeout=8):
            time.sleep(1.0)
            shot("fitur-02-komentar")
            adb("shell", "input", "keyevent", "4")
            time.sleep(2.0)
    else:
        print("   ! tombol komentar tidak ditemukan")

    # ---------- 3. Menu hapus ----------
    print("[3] Menu hapus postingan")
    # buka menu ⋯ pada postingan pertama
    for n in nodes():
        if "Feed Kampus" in n["label"]:
            break
    time.sleep(1.0)
    # ⋯ di kanan atas kartu pertama
    cards = [n for n in nodes() if n["label"].count("komentar") > 0]
    if cards:
        cy = cards[0]["y"]
        tap_xy(1015, cy - 60, wait=2.0)
        if wait_for("Hapus postingan", timeout=5):
            shot("fitur-03-menu-hapus")
            # konfirmasi dialog
            tap_label("Hapus postingan", wait=2.0)
            if wait_for("Hapus Postingan?", timeout=5):
                shot("fitur-04-konfirmasi")
                tap_label("Batal", wait=1.5)
    else:
        print("   ! kartu postingan tidak ditemukan")

    print("\nSelesai. File di:", OUT)


if __name__ == "__main__":
    main()
