"""Uji end-to-end Supabase: signup -> insert profil -> baca profil.

Memakai anon key saja (bukan service_role).
Jalankan: python tools/test_auth.py
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

URL = os.environ.get("SB_URL", "")
KEY = os.environ.get("SB_KEY", "")

TEST_EMAIL = os.environ.get("TEST_EMAIL", f"demo{int(time.time())}@itenas.test")
TEST_PASS = "demo12345"
TEST_NAME = "Demo Test"
TEST_USER = f"demo{int(time.time())}"


def req(method, path, body=None, token=None, extra=None):
    headers = {
        "apikey": KEY,
        "Authorization": f"Bearer {token or KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if extra:
        headers.update(extra)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(
        f"{URL.rstrip('/')}{path}", data=data, headers=headers, method=method
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


def main():
    if not URL or not KEY:
        print("Set SB_URL dan SB_KEY.")
        sys.exit(1)

    print(f"URL: {URL}")
    print(f"Test email: {TEST_EMAIL}\n")

    # ---------- 1. SIGN UP ----------
    print("[1] Sign up")
    status, body = req("POST", "/auth/v1/signup", {
        "email": TEST_EMAIL,
        "password": TEST_PASS,
        "data": {"full_name": TEST_NAME, "username": TEST_USER},
    })
    print(f"    HTTP {status}")
    if status not in (200, 201):
        print("    GAGAL:", json.dumps(body, indent=2)[:500])
        return

    token = (body or {}).get("access_token")
    user = (body or {}).get("user") or {}
    uid = user.get("id")
    print(f"    user id: {uid}")
    print(f"    session: {'ADA' if token else 'TIDAK ADA'}")

    if not token:
        print("\n    !  Project mengaktifkan 'Confirm email'.")
        print("    Matikan di: Authentication -> Providers -> Email -> "
              "Confirm email = OFF")
        return

    # ---------- 2. BACA PROFIL (dibuat trigger) ----------
    print("\n[2] Baca profil (hasil trigger handle_new_user)")
    status, body = req("GET", f"/rest/v1/profiles?select=*&id=eq.{uid}",
                       token=token)
    print(f"    HTTP {status}")
    if status == 200 and body:
        p = body[0]
        print(f"    full_name: {p.get('full_name')!r}")
        print(f"    username : {p.get('username')!r}")
        print(f"    email    : {p.get('email')!r}")
    else:
        print("    profil belum ada / error:", str(body)[:300])

    # ---------- 3. UPDATE PROFIL ----------
    print("\n[3] Update profil (bio + sosmed)")
    status, body = req(
        "PATCH", f"/rest/v1/profiles?id=eq.{uid}",
        {
            "bio": "Mahasiswa ITENAS",
            "about_me": "Suka ngoding dan desain.",
            "instagram": "demo.itenas",
            "facebook": "demo.itenas",
            "tiktok": "demo.itenas",
        },
        token=token,
        extra={"Prefer": "return=representation"},
    )
    print(f"    HTTP {status}  {str(body)[:200]}")

    # ---------- 4. CEK TABEL FEED ----------
    print("\n[4] Cek tabel feed")
    for table in ("posts", "post_likes"):
        st, bd = req("GET", f"/rest/v1/{table}?select=*&limit=1", token=token)
        ok = "OK" if st == 200 else "BELUM ADA"
        print(f"    {table:12} HTTP {st}  {ok}")

    # ---------- 5. CEK STORAGE ----------
    print("\n[5] Cek storage bucket")
    st, bd = req("GET", "/storage/v1/bucket", token=token)
    if st == 200 and isinstance(bd, list):
        if bd:
            for b in bd:
                print(f"    - {b.get('name')} (public={b.get('public')})")
        else:
            print("    (kosong — bucket avatars/posts belum dibuat)")
    else:
        print("    gagal:", str(bd)[:200])

    # ---------- 6. SIGN OUT ----------
    print("\n[6] Sign out")
    st, _ = req("POST", "/auth/v1/logout", token=token)
    print(f"    HTTP {st}")

    print("\nOK Selesai. Cek hasil di atas.")


if __name__ == "__main__":
    main()

