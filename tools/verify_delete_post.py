"""Uji fitur hapus postingan + RLS (hanya pemilik yang boleh hapus).

Jalankan: python tools/verify_delete_post.py
"""
import json
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

results = []


def log(step, ok, detail=""):
    results.append((step, ok))
    print(f"  [{'OK  ' if ok else 'FAIL'}] {step}" + (f"  {detail}" if detail else ""))


def req(method, path, body=None, token=None):
    r = urllib.request.Request(
        f"{URL}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers={
            "apikey": KEY,
            "Authorization": f"Bearer {token or KEY}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Prefer": "return=representation",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw
    except Exception as e:
        return None, str(e)


def signup(tag, stamp):
    st, b = req("POST", "/auth/v1/signup", {
        "email": f"del{tag}{stamp}@gmail.com",
        "password": "demo12345",
        "data": {"full_name": f"Del {tag.upper()}", "username": f"del{tag}{stamp}"},
    })
    if isinstance(b, dict) and b.get("access_token"):
        return {"token": b["access_token"], "id": b["user"]["id"]}
    return None


def main():
    stamp = str(int(time.time()))[-6:]
    print("=" * 64)
    print("UJI HAPUS POSTINGAN")
    print("=" * 64)

    print("\n[1] Siapkan 2 pengguna")
    ua = signup("a", stamp)
    ub = signup("b", stamp)
    log("user A", ua is not None)
    log("user B", ub is not None)
    if not ua or not ub:
        return

    print("\n[2] User A buat postingan + komentar")
    st, post = req("POST", "/rest/v1/posts?select=*",
                   {"author_id": ua["id"], "content": "Posting akan dihapus"},
                   ua["token"])
    pid = post[0]["id"] if st == 201 and isinstance(post, list) else None
    log("postingan dibuat", pid is not None, f"HTTP {st}")
    if not pid:
        return

    req("POST", "/rest/v1/post_comments?select=*",
        {"post_id": pid, "author_id": ub["id"], "content": "komentar uji"},
        ub["token"])
    st, cs = req("GET", f"/rest/v1/post_comments?select=id&post_id=eq.{pid}")
    log("komentar menempel", isinstance(cs, list) and len(cs) == 1,
        f"n={len(cs) if isinstance(cs, list) else '?'}")

    print("\n[3] RLS: user B coba hapus postingan A")
    st, _ = req("DELETE", f"/rest/v1/posts?id=eq.{pid}", token=ub["token"])
    st2, chk = req("GET", f"/rest/v1/posts?select=id&id=eq.{pid}")
    masih_ada = isinstance(chk, list) and len(chk) == 1
    log("postingan A tetap ada (RLS bekerja)", masih_ada,
        f"delete HTTP {st}")

    print("\n[4] User A hapus postingannya sendiri")
    st, _ = req("DELETE", f"/rest/v1/posts?id=eq.{pid}", token=ua["token"])
    st2, chk = req("GET", f"/rest/v1/posts?select=id&id=eq.{pid}")
    hilang = isinstance(chk, list) and len(chk) == 0
    log("postingan terhapus", hilang, f"HTTP {st}")

    print("\n[5] Cascade: komentar ikut terhapus")
    st, cs = req("GET", f"/rest/v1/post_comments?select=id&post_id=eq.{pid}")
    log("komentar ikut hilang", isinstance(cs, list) and len(cs) == 0,
        f"n={len(cs) if isinstance(cs, list) else '?'}")

    print("\n[6] Like ikut terhapus")
    st, ls = req("GET", f"/rest/v1/post_likes?select=id&post_id=eq.{pid}")
    log("like ikut hilang", isinstance(ls, list) and len(ls) == 0,
        f"n={len(ls) if isinstance(ls, list) else '?'}")

    total = len(results)
    passed = sum(1 for _, ok in results if ok)
    print("\n" + "=" * 64)
    print(f"HASIL: {passed}/{total} pemeriksaan lulus")
    for step, ok in results:
        if not ok:
            print(f"  GAGAL: {step}")
    print("=" * 64)


if __name__ == "__main__":
    main()
