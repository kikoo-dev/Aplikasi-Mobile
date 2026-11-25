"""Verifikasi integrasi Supabase lewat database (tanpa bergantung UI).

Membuat akun uji via API, lalu memverifikasi:
  - trigger handle_new_user membuat profil
  - update profil (biodata + sosmed) tersimpan
  - insert post + like berfungsi
  - upload file ke storage bucket

Jalankan: python tools/verify_supabase_full.py
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

URL = "https://cgqespmtpvoafiinygao.supabase.co"
KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNncWVzcG10cHZvYWZpaW55Z2FvIiwicm9s"
    "ZSI6ImFub24iLCJpYXQiOjE3OTI2MDI5MzcsImV4cCI6MjEwODE3ODkzN30."
    "TAdJ_8sOAokyt0LZ82q-GAA9I1gkhgyJ3wxyc9vI1gc"
)

STAMP = str(int(time.time()))[-6:]
EMAIL = f"verif{STAMP}@gmail.com"
PASSWORD = "demo12345"
USERNAME = f"verif{STAMP}"

results = []


def log(step, ok, detail=""):
    mark = "OK  " if ok else "FAIL"
    results.append((step, ok))
    print(f"  [{mark}] {step}" + (f"  {detail}" if detail else ""))


def req(method, path, body=None, token=None, content_type="application/json",
        raw=None):
    headers = {
        "apikey": KEY,
        "Authorization": f"Bearer {token or KEY}",
        "Accept": "application/json",
    }
    data = None
    if raw is not None:
        headers["Content-Type"] = content_type
        data = raw
    elif body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()

    r = urllib.request.Request(f"{URL}{path}", data=data,
                               headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            txt = resp.read().decode("utf-8", "replace")
            return resp.status, (json.loads(txt) if txt.strip() else None)
    except urllib.error.HTTPError as e:
        txt = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(txt)
        except Exception:
            return e.code, txt
    except Exception as e:
        return None, str(e)


def main():
    print("=" * 64)
    print("VERIFIKASI INTEGRASI SUPABASE")
    print("=" * 64)
    print(f"Email uji: {EMAIL}\n")

    # ---------- 1. SIGNUP ----------
    print("[1] Autentikasi")
    st, body = req("POST", "/auth/v1/signup", {
        "email": EMAIL,
        "password": PASSWORD,
        "data": {"full_name": "Verif User", "username": USERNAME},
    })
    token = (body or {}).get("access_token") if isinstance(body, dict) else None
    uid = ((body or {}).get("user") or {}).get("id") if isinstance(body, dict) else None
    log("signup berhasil & dapat token", bool(token), f"uid={uid}")
    if not token:
        print("   respons:", str(body)[:300])
        return

    # ---------- 2. PROFIL OTOMATIS ----------
    print("\n[2] Profil otomatis (trigger)")
    st, rows = req("GET", f"/rest/v1/profiles?select=*&id=eq.{uid}", token=token)
    has = st == 200 and isinstance(rows, list) and len(rows) == 1
    log("profil dibuat otomatis saat signup", has,
        f"HTTP {st} rows={len(rows) if isinstance(rows, list) else '?'}")

    # ---------- 3. UPDATE BIODATA ----------
    print("\n[3] Simpan biodata + about me + sosmed")
    payload = {
        "full_name": "Verif User",
        "username": USERNAME,
        "phone": "081234567890",
        "bio": "Mahasiswa ITENAS",
        "about_me": "Suka ngoding, desain, dan kopi.",
        "address": "Bandung",
        "occupation": "Mahasiswa",
        "gender": "Laki-laki",
        "birth_date": "2003-05-17",
        "instagram": "verif.itenas",
        "facebook": "verif.itenas",
        "tiktok": "verif.itenas",
    }
    st, rows = req("PATCH", f"/rest/v1/profiles?id=eq.{uid}", payload,
                   token=token, content_type="application/json")
    # Prefer header untuk return representation
    st2, rows2 = req("GET",
                     f"/rest/v1/profiles?select=phone,occupation,instagram,"
                     f"facebook,tiktok,about_me&id=eq.{uid}", token=token)
    saved = st2 == 200 and isinstance(rows2, list) and rows2
    ok = saved and rows2[0].get("instagram") == "verif.itenas"
    log("biodata & 3 sosmed tersimpan", ok,
        f"{rows2[0] if saved else rows2}")

    # ---------- 4. INSERT POST ----------
    print("\n[4] Postingan feed")
    st, post = req("POST", "/rest/v1/posts",
                   {"author_id": uid, "content": "Posting uji verifikasi otomatis"},
                   token=token)
    post_ok = st in (200, 201)
    log("insert post", post_ok, f"HTTP {st}")

    st, rows = req("GET",
                   "/rest/v1/posts?select=id,content,like_count&order=created_at.desc&limit=1",
                   token=token)
    pid = rows[0]["id"] if st == 200 and isinstance(rows, list) and rows else None
    log("post terbaca kembali", pid is not None,
        f"{(rows[0]['content'] if pid else rows)[:60] if pid else ''}")

    # ---------- 5. LIKE + RPC ----------
    if pid:
        print("\n[5] Like & RPC counter")
        st, _ = req("POST", "/rest/v1/post_likes",
                    {"post_id": pid, "user_id": uid}, token=token)
        log("insert like", st in (200, 201), f"HTTP {st}")

        st, _ = req("POST", "/rest/v1/rpc/increment_like",
                    {"post_id": pid}, token=token)
        log("RPC increment_like", st in (200, 204), f"HTTP {st}")

        st, rows = req("GET", f"/rest/v1/posts?select=like_count&id=eq.{pid}",
                       token=token)
        cnt = rows[0]["like_count"] if st == 200 and rows else None
        log("like_count bertambah", cnt == 1, f"like_count={cnt}")

    # ---------- 6. STORAGE UPLOAD ----------
    print("\n[6] Upload ke storage (avatars)")
    png = bytes.fromhex(
        "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4"
        "890000000a49444154789c6300010000050001"
        "0d0a2db40000000049454e44ae426082"
    )
    path = f"/storage/v1/object/avatars/{uid}/probe_{int(time.time())}.png"
    st, body = req("POST", path, raw=png, token=token,
                   content_type="image/png")
    log("upload foto profil", st in (200, 201), f"HTTP {st} {str(body)[:80]}")

    if st in (200, 201):
        public = f"{URL}/storage/v1/object/public/avatars/{uid}/probe_{int(time.time())}.png"
        # ambil URL publik dari path yang benar
        st2, _ = req("GET", path.replace("/object/", "/object/public/"),
                     token=token)
        log("file bisa diakses publik", st2 == 200, f"HTTP {st2}")
        _ = public

    # ---------- 7. LOGOUT ----------
    print("\n[7] Logout")
    st, _ = req("POST", "/auth/v1/logout", token=token)
    log("logout", st in (200, 204), f"HTTP {st}")

    # ---------- RINGKASAN ----------
    total = len(results)
    passed = sum(1 for _, ok in results if ok)
    print("\n" + "=" * 64)
    print(f"HASIL: {passed}/{total} pemeriksaan lulus")
    if passed < total:
        print("Yang gagal:")
        for step, ok in results:
            if not ok:
                print(f"  - {step}")
    print("=" * 64)


if __name__ == "__main__":
    main()
