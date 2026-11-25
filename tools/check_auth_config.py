"""Cek konfigurasi auth Supabase: apakah 'Confirm email' aktif?

Jalankan: python tools/check_auth_config.py
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

URL = os.environ.get("SB_URL", "")
KEY = os.environ.get("SB_KEY", "")


def post(path, body, token=None):
    r = urllib.request.Request(
        f"{URL.rstrip('/')}{path}",
        data=json.dumps(body).encode(),
        headers={
            "apikey": KEY,
            "Authorization": f"Bearer {token or KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            return resp.status, json.loads(resp.read().decode() or "null")
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw
    except Exception as e:
        return None, str(e)


def main():
    email = f"cekauth{int(time.time())}@gmail.com"
    print("Mendaftar dengan:", email)

    status, body = post("/auth/v1/signup", {
        "email": email,
        "password": "demo12345",
        "data": {"full_name": "Cek Auth", "username": f"cekauth{int(time.time())}"},
    })

    print("HTTP:", status)
    print("Respons:", json.dumps(body, indent=2)[:900] if isinstance(body, dict)
          else str(body)[:500])

    if isinstance(body, dict):
        session = body.get("session")
        user = body.get("user") or {}
        has_token = bool(body.get("access_token"))
        print("\n--- ANALISIS ---")
        print("user id          :", user.get("id"))
        print("email confirmed  :", user.get("email_confirmed_at"))
        print("access_token ada :", has_token)
        if has_token or session:
            print("\n=> 'Confirm email' NONAKTIF. Login langsung bisa.")
        else:
            print("\n=> 'Confirm email' AKTIF.")
            print("   Matikan: Dashboard -> Authentication -> Sign In / Providers")
            print("            -> Email -> matikan 'Confirm email'")


if __name__ == "__main__":
    if not URL or not KEY:
        print("Set SB_URL dan SB_KEY.")
        sys.exit(1)
    main()
