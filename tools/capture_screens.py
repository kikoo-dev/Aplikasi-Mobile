"""Capture screenshot aplikasi (ROG Phone 3) — alur lengkap.

Koordinat sudah diverifikasi langsung pada perangkat 1080x2340
(area aplikasi 1080x2298). Form diisi bertahap dengan keyboard
ditutup di antara field agar posisi tidak bergeser.

Jalankan: python tools/capture_screens.py
Output  : tools/screens/*.png
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

EMAIL = "demo@itenas.ac.id"
PASSWORD = "demo12345"
NAME = "Demo Mahasiswa"
USERNAME = "demomahasiswa"

XC = 540
KEY_BACK = 4

# ---- Login ----
Y_LOGIN_EMAIL = 1180
Y_LOGIN_PASSWORD = 1390
Y_LOGIN_BTN = 1688
Y_LOGIN_DAFTAR = 1875

# ---- Register (posisi label/field terverifikasi) ----
Y_REG_NAME = 620
Y_REG_USERNAME = 815
Y_REG_EMAIL = 1028
Y_REG_PASSWORD = 1242
Y_REG_CONFIRM = 1562
Y_REG_SUBMIT = 1813

# ---- Beranda ----
NAV_KALKULATOR = (910, 141)
NAV_PROFIL = (872, 749)


# ------------------------------------------------------------
def adb(*args, binary=False):
    if binary:
        return subprocess.run([ADB, *args], capture_output=True).stdout
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    )


def focused_pkg():
    out = adb("shell", "dumpsys", "window", "displays").stdout
    m = re.search(r"mCurrentFocus=Window\{[^}]*?\s([\w.]+)/", out)
    return m.group(1) if m else ""


def ensure_app():
    if focused_pkg() == PKG:
        return True
    adb("shell", "am", "start", "-n", ACTIVITY)
    time.sleep(2.5)
    return focused_pkg() == PKG


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


def wait_for(keyword, timeout=12.0, poll=0.8):
    end = time.time() + timeout
    while time.time() < end:
        if keyword.lower() in screen_text().lower():
            return True
        time.sleep(poll)
    return False


def tap_label(keyword, wait=1.4, exact=False, required=True):
    for desc, cx, cy, clickable in dump_labels():
        if not clickable:
            continue
        hit = (desc == keyword) if exact else (keyword.lower() in desc.lower())
        if hit:
            adb("shell", "input", "tap", str(cx), str(cy))
            time.sleep(wait)
            return True
    if required:
        print(f"     ! label tidak ditemukan: {keyword!r}")
    return False


def tap(x, y, wait=0.9):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))
    time.sleep(wait)


def swipe(x1, y1, x2, y2, dur=500, wait=1.5):
    adb("shell", "input", "swipe", str(int(x1)), str(int(y1)),
        str(int(x2)), str(int(y2)), str(int(dur)))
    time.sleep(wait)


def type_text(txt):
    adb("shell", "input", "text", txt)
    time.sleep(0.6)


def key(code, wait=0.5):
    adb("shell", "input", "keyevent", str(code))
    time.sleep(wait)


def shot(name):
    ensure_app()
    time.sleep(0.6)
    data = adb("exec-out", "screencap", "-p", binary=True)
    if not data or not data.startswith(b"\x89PNG"):
        print(f"     ! gagal ambil {name}")
        return None
    path = os.path.join(OUT, f"{name}.png")
    with open(path, "wb") as f:
        f.write(data)
    print(f"     -> {name}.png ({len(data)//1024} KB)")
    return path


def fill(x, y, value):
    """Tap field, ketik, tutup keyboard (posisi field jadi stabil lagi)."""
    tap(x, y, wait=0.8)
    type_text(value)
    key(KEY_BACK, wait=0.7)


# ------------------------------------------------------------
def main():
    if not os.path.exists(ADB):
        print("adb tidak ditemukan:", ADB)
        sys.exit(1)
    if "device" not in adb("devices").stdout:
        print("Tidak ada perangkat terhubung.")
        sys.exit(1)

    os.makedirs(OUT, exist_ok=True)
    adb("shell", "cmd", "uimode", "night", "no")
    for k in ("window_animation_scale", "transition_animation_scale",
              "animator_duration_scale"):
        adb("shell", "settings", "put", "global", k, "0")
    time.sleep(1.0)

    adb("shell", "pm", "clear", PKG)
    time.sleep(2.5)

    # ================= 1. SPLASH =================
    print("[1] Splash")
    adb("shell", "am", "start", "-n", ACTIVITY)
    # Splash oranye penuh muncul sekitar 2.4s setelah launch
    time.sleep(2.4)
    shot("01-splash")

    # ================= 2. LOGIN =================
    print("[2] Login")
    wait_for("Selamat Datang", timeout=16)
    time.sleep(0.6)
    shot("02-login")

    # ================= 3. REGISTER =================
    print("[3] Register")
    tap(688, Y_LOGIN_DAFTAR, wait=2.6)
    wait_for("Buat Akun", timeout=8)
    time.sleep(0.8)
    shot("03-register")

    # ================= 4. DAFTAR =================
    print("[4] Daftar akun demo")
    fill(XC, Y_REG_NAME, NAME)
    fill(XC, Y_REG_USERNAME, USERNAME)
    fill(XC, Y_REG_EMAIL, EMAIL)
    fill(XC, Y_REG_PASSWORD, PASSWORD)
    fill(XC, Y_REG_CONFIRM, PASSWORD)
    time.sleep(0.6)

    tap_label("Daftar Sekarang", wait=6.0, required=False)
    time.sleep(2.0)

    if not wait_for("Feed Kampus", timeout=10):
        print("     ! register gagal -> login manual")
        if wait_for("Selamat Datang", timeout=6):
            fill(XC, Y_LOGIN_EMAIL, EMAIL)
            fill(XC, Y_LOGIN_PASSWORD, PASSWORD)
            tap_label("Masuk", wait=5.0, exact=True, required=False)
            wait_for("Feed Kampus", timeout=10)

    # ================= 5. BERANDA =================
    print("[5] Beranda")
    time.sleep(1.8)
    shot("04-beranda")

    print("[6] Feed scroll")
    swipe(540, 1950, 540, 700, 550)
    shot("05-feed-scroll")
    swipe(540, 1950, 540, 700, 550)
    shot("06-feed-scroll-2")

    # ================= 7. KALKULATOR =================
    print("[7] Kalkulator")
    tap(NAV_KALKULATOR[0], NAV_KALKULATOR[1], wait=3.0)
    wait_for("Kalkulator", timeout=6)
    time.sleep(0.8)
    shot("07-kalkulator")

    print("     hitung 12 + 5 x 3 =")
    for lbl in ["1", "2", "+", "5", "×", "3", "="]:
        tap_label(lbl, wait=0.55, exact=True, required=False)
    time.sleep(1.2)
    shot("08-kalkulator-hasil")

    # ================= 8. PROFIL =================
    print("[8] Profil")
    key(KEY_BACK)
    # Tunggu kembali ke beranda (feed) dulu
    if not wait_for("Feed Kampus", timeout=8):
        print("     ! belum kembali ke beranda, coba back lagi")
        key(KEY_BACK)
        wait_for("Feed Kampus", timeout=6)

    # Scroll ke atas agar kartu profil terlihat
    swipe(540, 700, 540, 1900, 400)
    swipe(540, 700, 540, 1900, 400)
    time.sleep(1.0)

    tap(NAV_PROFIL[0], NAV_PROFIL[1], wait=3.0)
    wait_for("Profil Saya", timeout=8)
    time.sleep(1.0)
    shot("09-profil")

    # ================= 9. EDIT PROFIL =================
    print("[9] Edit Profil")
    tap_label("Edit", wait=3.5, required=False)
    wait_for("Biodata", timeout=8)
    time.sleep(1.0)
    shot("10-edit-profil")

    for k in ("window_animation_scale", "transition_animation_scale",
              "animator_duration_scale"):
        adb("shell", "settings", "put", "global", k, "1")

    print("\nSelesai. File di:", OUT)


if __name__ == "__main__":
    main()
