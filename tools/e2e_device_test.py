"""Uji E2E di HP dengan navigasi berbasis label (tahan perubahan layout).

Register -> isi profil -> posting feed, lalu verifikasi ke Supabase.

Jalankan: python tools/e2e_device_test.py
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
PKG = "com.example.social_profile_app"
ACTIVITY = f"{PKG}/.MainActivity"

URL = "https://cgqespmtpvoafiinygao.supabase.co"
KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNncWVzcG10cHZvYWZpaW55Z2FvIiwicm9s"
    "ZSI6ImFub24iLCJpYXQiOjE3OTI2MDI5MzcsImV4cCI6MjEwODE3ODkzN30."
    "TAdJ_8sOAokyt0LZ82q-GAA9I1gkhgyJ3wxyc9vI1gc"
)

STAMP = str(int(time.time()))[-6:]
EMAIL = f"uji{STAMP}@gmail.com"
PASSWORD = "demo12345"
NAME = "Uji Otomatis"
USERNAME = f"uji{STAMP}"

KEY_BACK = 4


# ------------------------------------------------------------
def adb(*args, binary=False):
    if binary:
        return subprocess.run([ADB, *args], capture_output=True).stdout
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    )


def nodes():
    """Semua node: dict(label, x, y, click, cls, top, bottom)."""
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
            "top": int(b[1]),
            "bottom": int(b[3]),
            "click": a("clickable") == "true",
            "cls": a("class").split(".")[-1],
        })
    return out


def screen_text():
    return " | ".join(n["label"] for n in nodes())


def wait_for(keyword, timeout=12.0, poll=0.7):
    end = time.time() + timeout
    while time.time() < end:
        if keyword.lower() in screen_text().lower():
            return True
        time.sleep(poll)
    return False


def tap_xy(x, y, wait=0.9):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))
    time.sleep(wait)


def tap_label(keyword, wait=1.5, exact=False):
    for n in nodes():
        if not n["click"]:
            continue
        hit = (n["label"] == keyword) if exact else \
              (keyword.lower() in n["label"].lower())
        if hit:
            tap_xy(n["x"], n["y"], wait)
            return True
    print(f"     ! label tidak ditemukan: {keyword!r}")
    return False


def type_text(t):
    adb("shell", "input", "text", t)
    time.sleep(0.6)


def key(code, wait=0.5):
    adb("shell", "input", "keyevent", str(code))
    time.sleep(wait)


def field_below(label_text, offset=90):
    """Cari koordinat input di bawah sebuah label form."""
    ns = nodes()
    anchor = None
    for n in ns:
        if n["label"].strip() == label_text:
            anchor = n
            break
    if anchor is None:
        for n in ns:
            if label_text.lower() in n["label"].lower():
                anchor = n
                break
    if anchor is None:
        return None
    return anchor["x"] if anchor["x"] > 200 else 540, anchor["bottom"] + offset


def fill_field(label_text, value, offset=90):
    pos = field_below(label_text, offset)
    if pos is None:
        print(f"     ! field {label_text!r} tidak ditemukan")
        return False
    tap_xy(*pos, wait=0.8)
    type_text(value)
    key(KEY_BACK, wait=0.7)
    return True


def shot(name):
    time.sleep(0.6)
    data = adb("exec-out", "screencap", "-p", binary=True)
    if data and data.startswith(b"\x89PNG"):
        path = os.path.join(HERE, "screens", f"{name}.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)
        print(f"     -> {name}.png")


def api(method, path, body=None):
    r = urllib.request.Request(
        f"{URL}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers={
            "apikey": KEY, "Authorization": f"Bearer {KEY}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw
    except Exception as e:
        return None, str(e)


# ------------------------------------------------------------
def main():
    print("=" * 64)
    print("UJI E2E DI PERANGKAT + VERIFIKASI SUPABASE")
    print("=" * 64)
    print(f"Email uji: {EMAIL}\n")

    adb("shell", "cmd", "uimode", "night", "no")
    adb("shell", "pm", "clear", PKG)
    time.sleep(2.5)
    adb("shell", "am", "start", "-n", ACTIVITY)
    time.sleep(3.0)

    if not wait_for("Selamat Datang", timeout=20):
        print("! layar login tidak muncul")
        return

    txt = screen_text()
    print("[1] Banner mode demo:",
          "MASIH ADA (demo!)" if "Mode demo aktif" in txt else "TIDAK ADA (Supabase aktif)")
    shot("e2e-01-login")

    # ---------- REGISTER ----------
    print("\n[2] Register di aplikasi")
    tap_label("Daftar sekarang", wait=2.8)
    if not wait_for("Buat Akun", timeout=8):
        print("     ! halaman register tidak terbuka")
        return

    ok = True
    ok &= fill_field("Nama Lengkap", NAME)
    ok &= fill_field("Username", USERNAME)
    ok &= fill_field("Email", EMAIL)
    ok &= fill_field("Password", PASSWORD)
    ok &= fill_field("Konfirmasi Password", PASSWORD)
    print(f"     field terisi: {'semua' if ok else 'sebagian'}")

    shot("e2e-02-register-terisi")
    tap_label("Daftar Sekarang", wait=6.0)
    time.sleep(2.5)

    masuk = wait_for("Feed Kampus", timeout=12)
    print(f"     masuk beranda: {'YA' if masuk else 'TIDAK'}")
    shot("e2e-03-beranda")

    # ---------- VERIFIKASI DB ----------
    print("\n[3] Verifikasi profil di Supabase")
    st, rows = api(
        "GET", f"/rest/v1/profiles?select=email,full_name,username&email=eq.{EMAIL}"
    )
    print(f"     HTTP {st}")
    if st == 200 and rows:
        print(f"     DATA: {rows[0]}")
        print("     => trigger handle_new_user bekerja OK")
    else:
        print(f"     ! tidak ditemukan: {rows}")

    # ---------- EDIT PROFIL ----------
    print("\n[4] Isi profil dari aplikasi")
    if tap_label("Edit Profil", wait=3.0):
        wait_for("Biodata", timeout=8)
        fill_field("No. Telepon", "081234567890")
        fill_field("Pekerjaan", "Mahasiswa Teknik")
        time.sleep(0.6)
        tap_label("Simpan", wait=5.0)
        time.sleep(2.0)
        shot("e2e-04-profil")

        st, rows = api(
            "GET",
            f"/rest/v1/profiles?select=phone,occupation&email=eq.{EMAIL}",
        )
        print(f"     verifikasi HTTP {st}: {rows}")

    # ---------- POSTING FEED ----------
    print("\n[5] Posting ke feed")
    key(KEY_BACK)
    time.sleep(2.0)
    wait_for("Feed Kampus", timeout=8)

    # FAB ada di kanan bawah
    tap_xy(960, 2120, wait=2.5)
    if wait_for("Bagikan", timeout=6):
        tap_xy(540, 900, wait=1.0)
        type_text("Halo dari uji otomatis ITENAS")
        key(KEY_BACK, wait=0.8)
        tap_label("Bagikan", wait=5.0)
        time.sleep(2.5)
        shot("e2e-05-posting")

        st, rows = api(
            "GET",
            "/rest/v1/posts?select=content,like_count&order=created_at.desc&limit=3",
        )
        print(f"     verifikasi posts HTTP {st}:")
        if st == 200 and isinstance(rows, list):
            for r in rows:
                print(f"       - {r}")
    else:
        print("     ! composer tidak terbuka")

    print("\n" + "=" * 64)


if __name__ == "__main__":
    main()


