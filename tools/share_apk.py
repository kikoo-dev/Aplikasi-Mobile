"""Server APK untuk instalasi tanpa kabel data (versi tahan-banting).

Perbaikan penting:
  - Logging aman terhadap karakter non-ASCII (penyebab crash sebelumnya).
  - ThreadingHTTPServer agar bisa melayani banyak request paralel.
  - Dukungan HTTP Range agar unduhan besar (APK 20-57 MB) tidak putus.
  - Tampilkan QR code agar device lain tinggal scan.

Jalankan: python tools/share_apk.py
"""
import http.server
import os
import socket
import socketserver
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RELEASE = os.path.join(ROOT, "release")
WEB_BUILD = os.path.join(ROOT, "build", "web")
PORT = 8081


# ------------------------------------------------------------
# Pastikan stdout bisa menulis karakter apa pun (fix crash Windows)
# ------------------------------------------------------------
def _safe_stdout():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def find_apks():
    if not os.path.isdir(RELEASE):
        return []
    out = []
    for f in sorted(os.listdir(RELEASE)):
        if f.lower().endswith(".apk"):
            p = os.path.join(RELEASE, f)
            out.append((f, os.path.getsize(p)))
    return out


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TB"


HTML = """<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Install ProfilKita ITENAS</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(160deg, #FF9A4D 0%, #F26522 45%, #D14E0E 100%);
    min-height: 100vh; padding: 24px 16px;
    display: flex; align-items: center; justify-content: center;
  }}
  .card {{
    background: #fff; border-radius: 24px; max-width: 460px; width: 100%;
    padding: 30px 24px; box-shadow: 0 20px 60px rgba(0,0,0,.25);
  }}
  .logo {{
    width: 74px; height: 74px; border-radius: 20px; margin: 0 auto 16px;
    background: linear-gradient(135deg, #FF9A4D, #F26522, #D14E0E);
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-weight: 900; font-size: 25px; letter-spacing: .5px;
    box-shadow: 0 8px 24px rgba(242,101,34,.4);
  }}
  h1 {{ font-size: 21px; color: #241A12; text-align: center; margin-bottom: 5px; }}
  .sub {{ font-size: 12.5px; color: #9E9189; text-align: center; margin-bottom: 22px; }}
  .apk {{
    display: block; text-decoration: none; background: #FFF1E8;
    border: 1.5px solid #FFD9C2; border-radius: 16px; padding: 15px;
    margin-bottom: 11px; transition: .15s;
  }}
  .apk:active {{ transform: scale(.98); background: #FFE3D2; }}
  .apk-name {{ font-size: 13.5px; font-weight: 800; color: #241A12;
               word-break: break-all; }}
  .apk-meta {{ font-size: 11px; color: #6E6157; margin-top: 3px; }}
  .apk-btn {{
    display: inline-block; margin-top: 10px;
    background: linear-gradient(135deg,#FF9A4D,#F26522);
    color: #fff; font-size: 12.5px; font-weight: 800; padding: 9px 18px;
    border-radius: 10px;
  }}
  .note {{
    background: #F7F3EF; border-radius: 14px; padding: 14px 16px; margin-top: 16px;
  }}
  .note h2 {{ font-size: 12.5px; color: #241A12; margin-bottom: 8px; }}
  .note ol {{ font-size: 11.5px; color: #6E6157; padding-left: 18px; line-height: 1.75; }}
  .note code {{ background: #FFE3D2; padding: 1px 5px; border-radius: 4px; font-size: 10.5px; }}
  .footer {{ text-align: center; font-size: 10.5px; color: #9E9189; margin-top: 18px; }}
</style>
</head>
<body>
<div class="card">
  <div class="logo">ITN</div>
  <h1>ProfilKita ITENAS</h1>
  <div class="sub">Pilih APK sesuai perangkat kamu</div>
  {apk_list}
  <div class="note">
    <h2>Cara install</h2>
    <ol>
      <li>Tap <b>Unduh APK</b> &rarr; tunggu selesai</li>
      <li>Buka <b>File Manager</b> &rarr; <b>Downloads</b></li>
      <li>Tap file <code>.apk</code></li>
      <li>Jika muncul peringatan, tap <b>Settings</b> &rarr; aktifkan
          <b>Allow from this source</b></li>
      <li>Tap <b>Install</b> &rarr; <b>Open</b></li>
    </ol>
  </div>
  <div class="footer">Institut Teknologi Nasional Bandung</div>
</div>
</body>
</html>
"""


class Handler(http.server.SimpleHTTPRequestHandler):
    """Handler dengan dukungan Range & logging aman."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=RELEASE, **kwargs)

    # ---------- logging aman ----------
    def log_message(self, fmt, *args):
        try:
            msg = fmt % args
            # buang karakter non-ASCII agar tidak crash di Windows
            msg = msg.encode("ascii", "replace").decode("ascii")
            print(f"  {self.client_address[0]} -> {msg}", flush=True)
        except Exception:
            pass

    def log_error(self, fmt, *args):
        self.log_message(fmt, *args)

    # ---------- halaman utama ----------
    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            try:
                body = self.build_html().encode("utf-8")
            except Exception as e:
                self.send_error(500, f"render error: {e}")
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

    def do_HEAD(self):
        super().do_HEAD()

    # ---------- dukungan Range untuk unduhan besar ----------
    def send_head(self):
        path = self.translate_path(self.path)
        if not os.path.isfile(path):
            return super().send_head()

        size = os.path.getsize(path)
        range_header = self.headers.get("Range")
        if not range_header:
            return super().send_head()

        # parse "bytes=start-end"
        try:
            unit, _, spec = range_header.partition("=")
            if unit.strip().lower() != "bytes":
                return super().send_head()
            start_s, _, end_s = spec.partition("-")
            start = int(start_s) if start_s else 0
            end = int(end_s) if end_s else size - 1
            end = min(end, size - 1)
            if start > end:
                self.send_error(416, "Range Not Satisfiable")
                return None
        except Exception:
            return super().send_head()

        f = open(path, "rb")
        f.seek(start)
        self.send_response(206)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.send_header("Content-Length", str(end - start + 1))
        self.end_headers()
        return _RangeFile(f, end - start + 1)

    def end_headers(self):
        self.send_header("Accept-Ranges", "bytes")
        super().end_headers()

    def build_html(self):
        apks = find_apks()
        labels = {
            "arm64": ("HP Android modern (2017+)", 0),
            "universal": ("Semua perangkat - kalau ragu pilih ini", 1),
            "armv7": ("HP Android lama / 32-bit", 2),
        }
        apks.sort(
            key=lambda x: (labels.get(
                "arm64" if "arm64" in x[0] else
                "universal" if "universal" in x[0] else "armv7",
                ("", 9))[1], x[0])
        )
        blocks = []
        for name, size in apks:
            tag = ("arm64" if "arm64" in name else
                   "universal" if "universal" in name else "armv7")
            desc = labels.get(tag, ("", 9))[0]
            blocks.append(
                f'<a class="apk" href="/{name}" download="{name}">'
                f'<div class="apk-name">{name}</div>'
                f'<div class="apk-meta">{human(size)} &middot; {desc}</div>'
                f'<div class="apk-btn">Unduh APK</div></a>'
            )
        if not blocks:
            blocks.append('<div class="apk-meta">Belum ada APK. Jalankan '
                          'flutter build apk --release</div>')
        return HTML.format(apk_list="\n".join(blocks))


class _RangeFile:
    """Pembungkus file untuk pengiriman partial content."""

    def __init__(self, fileobj, length):
        self._f = fileobj
        self._remaining = length

    def read(self, n=-1):
        if self._remaining <= 0:
            return b""
        if n is None or n < 0:
            n = self._remaining
        n = min(n, self._remaining)
        data = self._f.read(n)
        self._remaining -= len(data)
        return data

    def close(self):
        try:
            self._f.close()
        except Exception:
            pass


class ThreadedServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def print_qr(url):
    """Tampilkan QR code di terminal (aman untuk Windows cp1252)."""
    try:
        import qrcode
    except ImportError:
        return False
    try:
        qr = qrcode.QRCode(border=1)
        qr.add_data(url)
        qr.make(fit=True)
        matrix = qr.get_matrix()

        # Render manual memakai karakter ASCII agar tidak crash di terminal
        # Windows dengan encoding cp1252.
        lines = []
        for row in matrix:
            lines.append("".join("##" if cell else "  " for cell in row))
        print("\n".join(lines), flush=True)
        return True
    except Exception:
        return False


def main():
    _safe_stdout()

    if not os.path.isdir(RELEASE):
        print("Folder release/ tidak ditemukan.")
        sys.exit(1)

    apks = find_apks()
    if not apks:
        print("Tidak ada APK di folder release/.")
        print("Build dulu: flutter build apk --release")
        sys.exit(1)

    ip = get_local_ip()
    url = f"http://{ip}:{PORT}"

    print("=" * 64)
    print("SHARE APK - INSTALL TANPA KABEL")
    print("=" * 64)
    print(f"\n  Buka di browser device lain (Wi-Fi sama):\n")
    print(f"      {url}\n")
    print("  File tersedia:")
    for name, size in apks:
        print(f"    - {name:34} {human(size)}")
    print()
    if print_qr(url):
        print("  Scan QR di atas dari kamera device lain.\n")
    print("  Tekan Ctrl+C untuk berhenti.")
    print("=" * 64, flush=True)

    httpd = ThreadedServer(("0.0.0.0", PORT), Handler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
    finally:
        httpd.server_close()


if __name__ == "__main__":
    main()
