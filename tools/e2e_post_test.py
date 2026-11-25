"""Uji fitur bagikan postingan + komentar di HP.

Jalankan: python tools/e2e_post_test.py
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
EMAIL = f"post{STAMP}@gmail.com"
PASSWORD = "demo12345"
NAME = "Post Test"
USERNAME = f"post{STAMP}"
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


def tap_label(kw, wait=1.5, exact=False):
    for n in nodes():
        if not n["click"]:
            continue
        hit = (n["label"] == kw) if exact else (kw.lower() in n["label"].lower())
        if hit:
            tap_xy(n["x"], n["y"], wait)
            return True
    return False


def field_pos(label, offset=95):
    for n in nodes():
        if n["label"].strip() == label:
            return 540, n["bottom"] + offset
    return None


def fill(label, value):
    pos = field_pos(label)
    if not pos:
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
    print("UJI BAGIKAN POSTINGAN DI HP")
    print("=" * 62)

    # siapkan akun
    print(f"\n[1] Siapkan akun {EMAIL}")
    st, b = api("POST", "/auth/v1/signup", {
        "email": EMAIL, "password": PASSWORD,
        "data": {"full_name": NAME, "username": USERNAME},
    })
    tok = b.get("access_token") if isinstance(b, dict) else None
    if tok:
        api("POST", "/auth/v1/logout", token=tok)
    print(f"   signup HTTP {st}")

    # login di app
    print("\n[2] Login di aplikasi")
    adb("shell", "pm", "clear", PKG)
    time.sleep(2.5)
    adb("shell", "am", "start", "-n", ACTIVITY)
    time.sleep(3.0)
    if not wait_for("Selamat Datang", timeout=20):
        print("   ! layar login tidak muncul")
        return

    fill("Email", EMAIL)
    fill("Password", PASSWORD)
    tap_label("Masuk", wait=6.0, exact=True)
    if not wait_for("Feed Kampus", timeout=18):
        print("   ! gagal masuk beranda")
        return
    print("   beranda OK")

    # ---------- BAGIKAN POSTINGAN ----------
    print("\n[3] Bagikan postingan baru")
    # FAB kanan bawah
    tap_xy(981, 2199, wait=2.5)
    if not wait_for("Bagikan", timeout=6):
        print("   ! composer tidak terbuka")
        return
    print("   composer terbuka")

    # tulis teks
    tap_xy(540, 850, wait=1.0)
    T.type_text("Posting dari uji otomatis di HP")
    adb("shell", "input", "keyevent", str(KEY_BACK))
    time.sleep(0.8)
    shot("e2e-post-composer")

    # tombol Bagikan
    if tap_label("Bagikan", wait=8.0):
        time.sleep(3.0)
    shot("e2e-post-hasil")

    # verifikasi di database
    st, rows = api(
        "GET",
        "/rest/v1/posts?select=content,image_url,profiles(full_name)"
        "&order=created_at.desc&limit=3",
    )
    print(f"\n[4] Verifikasi di Supabase (HTTP {st})")
    if st == 200 and isinstance(rows, list):
        for r in rows:
            print(f"   - {r.get('content')!r} oleh "
                  f"{(r.get('profiles') or {}).get('full_name')}")
        found = any("uji otomatis" in (r.get("content") or "") for r in rows)
        print(f"   postingan baru ditemukan: {'YA' if found else 'TIDAK'}")
    else:
        print("   ", str(rows)[:200])

    print("\n" + "=" * 62)


if __name__ == "__main__":
    main()
