"""Uji hapus postingan di HP: buat -> hapus -> verifikasi.

Jalankan: python tools/e2e_delete_test.py
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
EMAIL = f"hd{STAMP}@gmail.com"
PASSWORD = "demo12345"
NAME = "Hapus Test"
USERNAME = f"hd{STAMP}"
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
            return 540, n["y"] + offset
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
                 "Content-Type": "application/json",
                 "Prefer": "return=representation"},
        method=method)
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def count_posts_with(text):
    st, rows = api("GET",
                   "/rest/v1/posts?select=id,content&order=created_at.desc&limit=20")
    if st != 200 or not isinstance(rows, list):
        return -1
    return sum(1 for r in rows if text in (r.get("content") or ""))


def main():
    print("=" * 64)
    print("UJI HAPUS POSTINGAN DI HP")
    print("=" * 64)

    print(f"\n[1] Siapkan akun {EMAIL}")
    st, b = api("POST", "/auth/v1/signup", {
        "email": EMAIL, "password": PASSWORD,
        "data": {"full_name": NAME, "username": USERNAME},
    })
    tok = b.get("access_token") if isinstance(b, dict) else None
    if tok:
        api("POST", "/auth/v1/logout", token=tok)
    print(f"   signup HTTP {st}")

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

    # ---------- BUAT POSTINGAN ----------
    print("\n[3] Buat postingan untuk dihapus")
    tap_xy(981, 2199, wait=2.5)
    if not wait_for("Bagikan", timeout=6):
        print("   ! composer tidak terbuka")
        return
    tap_xy(540, 1260, wait=1.2)
    T.type_text("POSTING UNTUK DIHAPUS")
    adb("shell", "input", "keyevent", str(KEY_BACK))
    time.sleep(0.8)
    # tombol Bagikan (koordinat dari inspeksi sebelumnya)
    tap_xy(540, 1564, wait=8.0)
    time.sleep(2.5)

    n_before = count_posts_with("POSTING UNTUK DIHAPUS")
    print(f"   postingan di database: {n_before}")
    shot("e2e-delete-01-dibuat")

    if n_before < 1:
        print("   ! postingan tidak terbuat, hentikan")
        return

    # ---------- BUKA MENU ⋯ PADA POSTINGAN KITA ----------
    print("\n[4] Buka menu postingan (titik tiga)")
    # postingan baru ada paling atas; menu ⋯ di kanan atas kartu
    # cari node dengan label postingan kita
    target = None
    for n in nodes():
        if "POSTING UNTUK DIHAPUS" in n["label"]:
            target = n
            break
    if not target:
        print("   ! postingan tidak terlihat di layar")
        return
    print(f"   kartu ditemukan di y={target['y']}")

    # ⋯ ada di pojok kanan atas kartu (x ~ 1010, y ~ kartu atas + 30)
    card_top = target["y"] - 60
    tap_xy(1015, max(card_top, 220), wait=2.0)
    shot("e2e-delete-02-menu")

    # ---------- PILIH HAPUS ----------
    print("\n[5] Pilih 'Hapus postingan'")
    if not tap_label("Hapus postingan", wait=2.0):
        print("   ! opsi hapus tidak ditemukan")
        return
    shot("e2e-delete-03-konfirmasi")

    # ---------- KONFIRMASI ----------
    print("\n[6] Konfirmasi hapus")
    if not tap_label("Hapus", wait=4.0, exact=True):
        print("   ! tombol konfirmasi tidak ditemukan")
        return
    time.sleep(2.5)
    shot("e2e-delete-04-setelah")

    # ---------- VERIFIKASI DB ----------
    n_after = count_posts_with("POSTING UNTUK DIHAPUS")
    print(f"\n[7] Verifikasi database: {n_after} (sebelumnya {n_before})")
    if n_after == 0:
        print("   => POSTINGAN BERHASIL DIHAPUS")
    else:
        print("   => postingan MASIH ADA")

    print("\n" + "=" * 64)


if __name__ == "__main__":
    main()
