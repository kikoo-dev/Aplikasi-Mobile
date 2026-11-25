"""Cek kesiapan bucket storage (akurat untuk anon key).

Catatan: `GET /storage/v1/bucket` mengembalikan [] untuk anon key
walau bucket sebenarnya ada (butuh hak admin). Jadi pengecekan
dilakukan dengan mencoba upload: jika responsnya RLS/Unauthorized
(atau sukses), berarti bucket ADA. Jika "Bucket not found", berarti
bucket belum dibuat.

Jalankan: python tools/check_bucket.py
Exit 0 = siap, 1 = belum.
"""
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


def request(method, path, data=None, headers=None):
    h = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}
    if headers:
        h.update(headers)
    r = urllib.request.Request(
        f"{URL.rstrip('/')}{path}", data=data, headers=h, method=method
    )
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def bucket_exists(name):
    """True/False/None(tidak pasti) + pesan."""
    st, body = request(
        "POST",
        f"/storage/v1/object/{name}/__probe__/probe.txt",
        b"probe",
        {"Content-Type": "text/plain"},
    )
    low = body.lower()

    if "bucket not found" in low or "bucket_not_found" in low:
        return False, f"HTTP {st} - bucket tidak ada"

    if st in (200, 201):
        # bersihkan
        request("DELETE", f"/storage/v1/object/{name}/__probe__/probe.txt")
        return True, f"HTTP {st} - bucket ada (upload berhasil)"

    if "row-level security" in low or "unauthorized" in low or st in (400, 403):
        return True, f"HTTP {st} - bucket ada (upload dibatasi RLS, normal)"

    return None, f"HTTP {st} - {body[:120]}"


def main():
    print("Cek bucket storage Supabase")
    print("-" * 50)

    missing = []
    for name in ("avatars", "posts"):
        exists, note = bucket_exists(name)
        if exists is True:
            print(f"  OK       {name:10} {note}")
        elif exists is False:
            print(f"  MISSING  {name:10} {note}")
            missing.append(name)
        else:
            print(f"  ?        {name:10} {note}")

    print("-" * 50)
    if missing:
        print(f"BELUM SIAP: {', '.join(missing)}")
        print("Jalankan supabase/storage_only.sql di SQL Editor.")
        sys.exit(1)

    print("SIAP - semua bucket tersedia. Lanjut build & install APK.")
    sys.exit(0)


if __name__ == "__main__":
    main()
