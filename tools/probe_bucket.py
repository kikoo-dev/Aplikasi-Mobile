"""Uji langsung keberadaan bucket dengan mencoba upload file kecil.

Lebih akurat daripada listing bucket (endpoint listing bisa kosong
untuk anon key walau bucket sebenarnya ada).

Jalankan: python tools/probe_bucket.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("SB_URL", "https://cgqespmtpvoafiinygao.supabase.co")
KEY = os.environ.get(
    "SB_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNncWVzcG10cHZvYWZpaW55Z2FvIiwicm9s"
    "ZSI6ImFub24iLCJpYXQiOjE3OTI2MDI5MzcsImV4cCI6MjEwODE3ODkzN30."
    "TAdJ_8sOAokyt0LZ82q-GAA9I1gkhgyJ3wxyc9vI1gc",
)

PAYLOAD = b"probe"


def request(method, path, data=None, headers=None):
    h = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}
    if headers:
        h.update(headers)
    r = urllib.request.Request(
        f"{URL.rstrip('/')}{path}", data=data, headers=h, method=method
    )
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, raw
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def main():
    print("=" * 62)
    print("PROBE BUCKET STORAGE")
    print("=" * 62)

    # ---------- 1. List bucket ----------
    st, body = request("GET", "/storage/v1/bucket")
    print(f"\n[1] List bucket   -> HTTP {st}")
    print("   ", body[:400])

    # ---------- 2. Coba upload ke tiap bucket ----------
    for bucket in ("avatars", "posts"):
        path = f"/storage/v1/object/{bucket}/probe/test.txt"
        st, body = request(
            "POST", path, PAYLOAD,
            {"Content-Type": "text/plain", "x-upsert": "true"},
        )
        print(f"\n[2] Upload ke '{bucket}' -> HTTP {st}")
        snippet = body[:300].replace("\n", " ")
        print("   ", snippet)

        if st in (200, 201):
            print("    => BUCKET ADA (upload berhasil)")
            # hapus lagi
            st2, _ = request(
                "DELETE", f"/storage/v1/object/{bucket}/probe/test.txt"
            )
            print(f"    cleanup: HTTP {st2}")
        elif "Bucket not found" in body or "bucket_not_found" in body:
            print("    => BUCKET TIDAK ADA")
        elif "row-level security" in body or "Unauthorized" in body or st == 403:
            print("    => BUCKET ADA, tapi ditolak RLS/auth")
            print("       (wajar untuk anon tanpa login — bukan masalah)")
        else:
            print("    => status tidak pasti, lihat pesan di atas")

    # ---------- 3. Cek via storage objects list ----------
    for bucket in ("avatars", "posts"):
        st, body = request("POST", "/storage/v1/object/list/" + bucket,
                           json.dumps({"prefix": "", "limit": 1}).encode(),
                           {"Content-Type": "application/json"})
        print(f"\n[3] List objek '{bucket}' -> HTTP {st}  {body[:160]}")

    print("\n" + "=" * 62)


if __name__ == "__main__":
    main()
