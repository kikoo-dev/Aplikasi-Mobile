"""Cek status data uji di Supabase (read-only).

Menampilkan berapa banyak akun/data uji yang masih ada, dan menjelaskan
cara membersihkannya dengan benar (RLS memblokir penghapusan via anon key).

Jalankan: python tools/cleanup_test_data.py
"""
import json
import urllib.error
import urllib.request

URL = "https://cgqespmtpvoafiinygao.supabase.co"
KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNncWVzcG10cHZvYWZpaW55Z2FvIiwicm9s"
    "ZSI6ImFub24iLCJpYXQiOjE3OTI2MDI5MzcsImV4cCI6MjEwODE3ODkzN30."
    "TAdJ_8sOAokyt0LZ82q-GAA9I1gkhgyJ3wxyc9vI1gc"
)

PATTERNS = ("demo", "uji", "verif", "login", "post", "pf", "fix", "kom",
            "share", "dbg", "cekauth")


def get(path):
    r = urllib.request.Request(
        f"{URL}{path}",
        headers={"apikey": KEY, "Authorization": f"Bearer {KEY}",
                 "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def is_test(email):
    local = (email or "").lower().split("@")[0]
    return any(local.startswith(p) for p in PATTERNS)


def main():
    print("=" * 66)
    print("STATUS DATA UJI")
    print("=" * 66)

    st, profiles = get("/rest/v1/profiles?select=id,email,full_name"
                       "&order=created_at.asc")
    st2, posts = get("/rest/v1/posts?select=id,content")
    st3, comments = get("/rest/v1/post_comments?select=id")

    if not isinstance(profiles, list):
        print("Gagal ambil profil:", str(profiles)[:200])
        return

    test = [p for p in profiles if is_test(p.get("email"))]
    real = [p for p in profiles if not is_test(p.get("email"))]

    print(f"\nTotal profil   : {len(profiles)}")
    print(f"  akun uji     : {len(test)}")
    print(f"  akun asli    : {len(real)}")
    print(f"Total postingan: {len(posts) if isinstance(posts, list) else '?'}")
    print(f"Total komentar : {len(comments) if isinstance(comments, list) else '?'}")

    if real:
        print("\nAkun asli (dipertahankan):")
        for p in real:
            print(f"  - {p.get('email')}")

    if not test:
        print("\nTidak ada akun uji. Database bersih.")
        return

    print(f"\nAkun uji ({len(test)}):")
    for p in test:
        print(f"  - {p.get('email')}")

    print("\n" + "-" * 66)
    print("CARA MEMBERSIHKAN")
    print("-" * 66)
    print("RLS memblokir penghapusan data user lain memakai anon key.")
    print("Ini fitur keamanan yang benar, bukan bug.\n")
    print("Buka Supabase -> SQL Editor -> New query, lalu jalankan isi file:")
    print("  supabase/cleanup_test_data.sql\n")
    print("Atau hapus manual:")
    print("  - Authentication -> Users  (hapus akun uji)")
    print("  - Table Editor -> profiles / posts  (data ikut terhapus cascade)")
    print("=" * 66)


if __name__ == "__main__":
    main()
