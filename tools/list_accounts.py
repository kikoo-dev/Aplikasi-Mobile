"""Daftar semua akun yang ada di database (email + nama).

Password TIDAK bisa diambil: Supabase menyimpannya sebagai hash bcrypt
(one-way), tidak dapat didekripsi oleh siapa pun termasuk admin.

Jalankan: python tools/list_accounts.py
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

# Akun yang dibuat oleh script pengujian otomatis -> password: demo12345
TEST_PASSWORD = "demo12345"
TEST_PREFIXES = ("demo", "uji", "verif", "login", "post", "pf", "fix",
                 "kom", "share", "dbg", "cekauth", "del", "hd")


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


def is_test_account(email):
    local = (email or "").lower().split("@")[0]
    return any(local.startswith(p) for p in TEST_PREFIXES)


def main():
    st, rows = get(
        "/rest/v1/profiles?select=email,full_name,username,occupation,created_at"
        "&order=created_at.asc"
    )
    if st != 200 or not isinstance(rows, list):
        print("Gagal:", str(rows)[:300])
        return

    test = [r for r in rows if is_test_account(r.get("email"))]
    other = [r for r in rows if not is_test_account(r.get("email"))]

    print("=" * 78)
    print(f"DAFTAR AKUN — total {len(rows)}")
    print("=" * 78)

    print(f"\n[A] AKUN UJI DIBUAT OTOMATIS ({len(test)})")
    print("    Password semua akun di bawah ini: demo12345")
    print("-" * 78)
    print(f"{'EMAIL':42} {'NAMA':20} PASSWORD")
    print("-" * 78)
    for r in test:
        print(f"{r.get('email',''):42} "
              f"{(r.get('full_name') or '-')[:19]:20} {TEST_PASSWORD}")

    print(f"\n[B] AKUN LAIN ({len(other)})")
    print("    Password TIDAK dapat ditampilkan (hash bcrypt, one-way)")
    print("-" * 78)
    if other:
        print(f"{'EMAIL':42} {'NAMA':20}")
        print("-" * 78)
        for r in other:
            print(f"{r.get('email',''):42} "
                  f"{(r.get('full_name') or '-')[:19]:20}")
    else:
        print("    (tidak ada)")

    print("\n" + "=" * 78)
    print("CATATAN KEAMANAN")
    print("=" * 78)
    print("  - Supabase menyimpan password sebagai hash bcrypt, tidak dapat")
    print("    dibaca balik. Untuk akun non-uji, gunakan 'Lupa Password'.")
    print("  - Akun uji sebaiknya dihapus: jalankan supabase/cleanup_test_data.sql")
    print("  - Jangan bagikan kredensial akun asli ke siapa pun.")
    print("=" * 78)


if __name__ == "__main__":
    main()
