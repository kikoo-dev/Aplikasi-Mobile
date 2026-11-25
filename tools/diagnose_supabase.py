"""Diagnosa lengkap project Supabase: tabel, kolom, fungsi RPC, bucket, policy.

Jalankan: python tools/diagnose_supabase.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("SB_URL", "")
KEY = os.environ.get("SB_KEY", "")


def http(method, path, body=None, headers=None):
    h = {"apikey": KEY, "Authorization": f"Bearer {KEY}",
         "Accept": "application/json"}
    if body is not None:
        h["Content-Type"] = "application/json"
    if headers:
        h.update(headers)
    r = urllib.request.Request(
        f"{URL.rstrip('/')}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers=h, method=method,
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

    print("=" * 62)
    print("DIAGNOSA SUPABASE")
    print("=" * 62)

    # ---------- Tabel ----------
    print("\n[TABEL]")
    for t in ("profiles", "posts", "post_likes"):
        st, bd = http("GET", f"/rest/v1/{t}?select=*&limit=1")
        n = len(bd) if isinstance(bd, list) else "-"
        print(f"  {t:12} HTTP {st:4}  rows(limit1)={n}")

    # ---------- Kolom posts ----------
    print("\n[KOLOM posts]")
    st, bd = http("GET", "/rest/v1/posts?select=*&limit=1")
    if st == 200 and isinstance(bd, list):
        if bd:
            print("  ", sorted(bd[0].keys()))
        else:
            # kosong -> pakai OpenAPI
            st2, spec = http("GET", "/rest/v1/")
            if st2 == 200 and isinstance(spec, dict):
                props = (spec.get("definitions", {}).get("posts", {})
                         .get("properties", {}))
                print("  ", sorted(props.keys()) or "(tidak terbaca)")
    else:
        print("   gagal:", str(bd)[:200])

    # ---------- RPC ----------
    print("\n[RPC]")
    for fn in ("increment_like", "decrement_like"):
        st, bd = http("POST", f"/rest/v1/rpc/{fn}",
                      {"post_id": "00000000-0000-0000-0000-000000000000"})
        ok = "ADA" if st in (200, 204, 400) else "TIDAK ADA"
        if st == 404:
            ok = "TIDAK ADA"
        print(f"  {fn:16} HTTP {st:4}  {ok}")

    # ---------- Storage ----------
    print("\n[STORAGE BUCKET]")
    st, bd = http("GET", "/storage/v1/bucket")
    if st == 200 and isinstance(bd, list):
        if not bd:
            print("   (kosong)")
        for b in bd:
            print(f"   - {b.get('name'):12} public={b.get('public')} "
                  f"size_limit={b.get('file_size_limit')}")
    else:
        print("   gagal:", str(bd)[:200])

    # ---------- Trigger profil ----------
    print("\n[TRIGGER handle_new_user]")
    print("   (tidak bisa dicek via anon key — perlu SQL Editor)")

    print("\n" + "=" * 62)


if __name__ == "__main__":
    main()
