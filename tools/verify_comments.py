"""Uji fitur komentar end-to-end (API + RLS + counter).

Jalankan: python tools/verify_comments.py
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
            # Wajib agar Supabase mengembalikan body (bukan null).
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


def main():
    stamp = str(int(time.time()))[-6:]
    print("=" * 64)
    print("UJI FITUR KOMENTAR")
    print("=" * 64)

    # ---------- 2 user ----------
    print("\n[1] Siapkan 2 pengguna")
    users = {}
    for tag in ("a", "b"):
        st, b = req("POST", "/auth/v1/signup", {
            "email": f"kom{tag}{stamp}@gmail.com",
            "password": "demo12345",
            "data": {
                "full_name": f"Komentator {tag.upper()}",
                "username": f"kom{tag}{stamp}",
            },
        })
        if isinstance(b, dict) and b.get("access_token"):
            users[tag] = {"token": b["access_token"], "id": b["user"]["id"]}
            log(f"signup user {tag}", True, b["user"]["id"][:8])
        else:
            log(f"signup user {tag}", False, str(b)[:120])

    if len(users) < 2:
        print("\nGagal menyiapkan pengguna.")
        return

    ua, ub = users["a"], users["b"]

    # ---------- postingan ----------
    print("\n[2] User A membuat postingan")
    st, post = req("POST", "/rest/v1/posts?select=*",
                   {"author_id": ua["id"], "content": "Posting untuk uji komentar"},
                   ua["token"])
    pid = post[0]["id"] if st == 201 and isinstance(post, list) else None
    log("buat postingan", pid is not None, f"HTTP {st}")
    if not pid:
        return

    # ---------- user A komentar ----------
    print("\n[3] User A berkomentar")
    st, rows = req(
        "POST",
        "/rest/v1/post_comments?select=*,profiles(full_name,avatar_url)",
        {"post_id": pid, "author_id": ua["id"], "content": "Komentar dari A"},
        ua["token"],
    )
    log("insert komentar A", st == 201 and isinstance(rows, list),
        f"HTTP {st}")

    st, _ = req("POST", "/rest/v1/rpc/increment_comment",
                {"post_id": pid}, ua["token"])
    log("RPC increment_comment", st in (200, 204), f"HTTP {st}")

    # ---------- user B komentar ----------
    print("\n[4] User B berkomentar di postingan A")
    st, rows = req(
        "POST",
        "/rest/v1/post_comments?select=*,profiles(full_name,avatar_url)",
        {"post_id": pid, "author_id": ub["id"], "content": "Komentar dari B"},
        ub["token"],
    )
    log("insert komentar B", st == 201 and isinstance(rows, list),
        f"HTTP {st}")
    req("POST", "/rest/v1/rpc/increment_comment", {"post_id": pid},
        ub["token"])

    # ---------- baca semua komentar ----------
    print("\n[5] Baca daftar komentar")
    st, rows = req(
        "GET",
        f"/rest/v1/post_comments?select=*,profiles(full_name)&post_id=eq.{pid}"
        "&order=created_at.asc",
        token=ua["token"],
    )
    n = len(rows) if isinstance(rows, list) else 0
    log("jumlah komentar = 2", n == 2, f"HTTP {st} n={n}")
    if isinstance(rows, list):
        for r in rows:
            who = (r.get("profiles") or {}).get("full_name")
            print(f"       - {who}: {r.get('content')!r}")

    # ---------- counter ----------
    print("\n[6] Counter komentar di postingan")
    st, rows = req("GET", f"/rest/v1/posts?select=comment_count&id=eq.{pid}",
                   token=ua["token"])
    cnt = rows[0]["comment_count"] if st == 200 and rows else None
    log("comment_count = 2", cnt == 2, f"comment_count={cnt}")

    # ---------- RLS: user B tidak bisa hapus komentar A ----------
    print("\n[7] RLS: user B coba hapus komentar A")
    st, rows_a = req(
        "GET",
        f"/rest/v1/post_comments?select=id,author_id&post_id=eq.{pid}"
        f"&author_id=eq.{ua['id']}",
        token=ub["token"],
    )
    cid_a = rows_a[0]["id"] if isinstance(rows_a, list) and rows_a else None
    if cid_a:
        st, _ = req("DELETE", f"/rest/v1/post_comments?id=eq.{cid_a}",
                    token=ub["token"])
        # Cek apakah benar-benar terhapus
        st2, chk = req("GET", f"/rest/v1/post_comments?select=id&id=eq.{cid_a}",
                       token=ua["token"])
        still_there = isinstance(chk, list) and len(chk) == 1
        log("komentar A tetap ada (RLS bekerja)", still_there,
            f"delete HTTP {st}")

    # ---------- user A hapus komentarnya sendiri ----------
    print("\n[8] User A hapus komentarnya sendiri")
    if cid_a:
        st, _ = req("DELETE", f"/rest/v1/post_comments?id=eq.{cid_a}",
                    token=ua["token"])
        st2, chk = req("GET", f"/rest/v1/post_comments?select=id&id=eq.{cid_a}",
                       token=ua["token"])
        gone = isinstance(chk, list) and len(chk) == 0
        log("komentar sendiri terhapus", gone, f"HTTP {st}")

    # ---------- ringkasan ----------
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
