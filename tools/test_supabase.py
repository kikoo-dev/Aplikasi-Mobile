"""Uji koneksi ke project Supabase (read-only, tanpa menyimpan kredensial).

Jalankan: python tools/test_supabase.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("SB_URL", "")
KEY = os.environ.get("SB_KEY", "")


def call(path, key, extra_headers=None):
    req = urllib.request.Request(
        f"{URL.rstrip('/')}/rest/v1/{path}",
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Accept": "application/json",
            **(extra_headers or {}),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            body = r.read().decode("utf-8", "replace")
            return r.status, body
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def main():
    if not URL or not KEY:
        print("Set SB_URL dan SB_KEY dulu.")
        sys.exit(1)

    print(f"URL  : {URL}")
    print(f"Key  : {KEY[:14]}... ({len(KEY)} chars)\n")

    for table in ("profiles", "posts", "post_likes"):
        status, body = call(f"{table}?select=*&limit=1", KEY)
        snippet = body[:180].replace("\n", " ")
        print(f"{table:12} -> HTTP {status}  {snippet}")

    # Cek storage buckets
    req = urllib.request.Request(
        f"{URL.rstrip('/')}/storage/v1/bucket",
        headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            buckets = json.loads(r.read().decode())
            print("\nBuckets:")
            for b in buckets:
                print(f"  - {b.get('name'):12} public={b.get('public')}")
    except Exception as e:
        print("\nBuckets: gagal ->", e)


if __name__ == "__main__":
    main()
