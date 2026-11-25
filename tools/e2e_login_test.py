"""Uji login lengkap di HP dengan pengetikan per-karakter yang andal.

Jalankan: python tools/e2e_login_test.py
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
sys.path.insert(0, HERE)

import adb_typing as T  # noqa: E402

ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
T.ADB = ADB

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
EMAIL = f"login{STAMP}@gmail.com"
PASSWORD = "demo12345"
NAME = "Login Test"
USERNAME = f"login{STAMP}"
KEY_BACK = 4


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
            "top": int(b[1]), "bottom": int(b[3]),
            "click": a("clickable") == "true",
            "cls": a("class").split(".")[-1],
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


def field_pos(label, offset=95):
    for n in nodes():
        if n["label"].strip() == label:
            return 540, n["bottom"] + offset
    return None


def fill(label, value):
    pos = field_pos(label)
    if not pos:
        print(f"   ! field {label} tidak ada")
        return False
    tap_xy(*pos, wait=0.9)
    time.sleep(0.4)
    ok = T.type_text(value)
    adb("shell", "input", "keyevent", str(KEY_BACK))
    time.sleep(0.6)
    return ok


def shot(name):
    time.sleep(0.6)
    data = adb("exec-out", "screencap", "-p", binary=True)
    if data and data.startswith(b"\x89PNG"):
        p = os.path.join(HERE, "screens", f"{name}.png")
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f:
            f.write(data)
        print(f"   -> {name}.png")


def api(method, path, body=None, token=None):
    r = urllib.request.Request(
        f"{URL}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers={"apikey": KEY, "Authorization": f"Bearer {token or KEY}",
                 "Content-Type": "application/json"},
        method=method)
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def main():
    print("=" * 62)
    print("UJI LOGIN DI PERANGKAT")
    print("=" * 62)

    print(f"\n[1] Siapkan akun: {EMAIL}")
    st, body = api("POST", "/auth/v1/signup", {
        "email": EMAIL, "password": PASSWORD,
        "data": {"full_name": NAME, "username": USERNAME},
    })
    token = body.get("access_token") if isinstance(body, dict) else None
    uid = ((body or {}).get("user") or {}).get("id") if isinstance(body, dict) else None
    print(f"   signup HTTP {st}, token={'ada' if token else 'tidak'}")

    if token and uid:
        api("PATCH", f"/rest/v1/profiles?id=eq.{uid}", {
            "phone": "081234567890",
            "occupation": "Mahasiswa ITENAS",
            "bio": "Profil dibuat otomatis lewat API",
            "about_me": "Halo, saya mahasiswa ITENAS yang sedang menguji aplikasi.",
            "instagram": "itenas.official",
            "facebook": "itenas.official",
            "tiktok": "itenas.official",
        }, token=token)
        print("   profil diisi via API")
        api("POST", "/auth/v1/logout", token=token)

    print("\n[2] Login di aplikasi")
    adb("shell", "pm", "clear", PKG)
    time.sleep(2.5)
    adb("shell", "am", "start", "-n", ACTIVITY)
    time.sleep(3.0)

    if not wait_for("Selamat Datang", timeout=20):
        print("   ! layar login tidak muncul")
        return

    ok_email = fill("Email", EMAIL)
    ok_pass = fill("Password", PASSWORD)
    print(f"   email terisi benar: {ok_email}")
    print(f"   password terisi: {ok_pass}")

    for n in nodes():
        if n["click"] and n["label"].strip() == "Masuk":
            tap_xy(n["x"], n["y"], wait=6.0)
            break

    masuk = wait_for("Feed Kampus", timeout=18)
    print(f"   beranda tampil: {'YA' if masuk else 'TIDAK'}")
    shot("e2e-login-beranda")

    if masuk:
        txt = screen_text()
        print(f"   nama di beranda: {'Login Test' in txt}")
        print(f"   feed ada: {'Suka' in txt}")

        for n in nodes():
            if n["click"] and n["label"].strip() == "Profil Saya":
                tap_xy(n["x"], n["y"], wait=3.5)
                break
        if wait_for("Profil Saya", timeout=10):
            shot("e2e-login-profil")
            t = screen_text()
            print(f"   halaman profil: YA")
            print(f"   instagram tampil: {'itenas.official' in t}")
            print(f"   about me tampil: {'menguji aplikasi' in t}")

    print("\n" + "=" * 62)


if __name__ == "__main__":
    main()
