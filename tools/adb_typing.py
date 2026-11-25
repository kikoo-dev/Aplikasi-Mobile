"""Ketik teks ke field Android dengan aman (termasuk @ . _ +).

`adb shell input text` tidak andal untuk karakter khusus dan teks panjang.
Modul ini memakai pendekatan bertahap:
  1. Coba `input text` dengan escaping
  2. Verifikasi isi field; jika tidak cocok, ketik per-karakter
     memakai keyevent (0-9, a-z, dan keyevent khusus untuk @ . _ +)

Dipakai oleh script e2e lainnya.
"""
import re
import subprocess
import time

ADB = None  # diisi oleh pemanggil


def _adb(*args):
    return subprocess.run([ADB, *args], capture_output=True, text=True,
                          encoding="utf-8", errors="ignore")


# Keycode untuk karakter khusus (KEYCODE_*)
SPECIAL = {
    "@": 77,     # KEYCODE_AT
    ".": 56,     # KEYCODE_PERIOD
    "_": 69,     # KEYCODE_MINUS dengan shift -> gunakan minus
    "-": 69,     # KEYCODE_MINUS
    "+": 81,     # KEYCODE_PLUS
    " ": 62,     # KEYCODE_SPACE
    ",": 55,
    "/": 76,
    ":": 74,
}


def _keyevent_for(ch):
    if ch.isdigit():
        return 7 + int(ch)          # 0 -> 7 ... 9 -> 16
    if ch.isalpha():
        return 29 + (ord(ch.lower()) - ord("a"))   # a -> 29 ... z -> 54
    return SPECIAL.get(ch)


def type_char_by_char(text, delay=0.045):
    """Ketik per karakter via keyevent. Return True jika semua terkirim."""
    ok = True
    for ch in text:
        code = _keyevent_for(ch)
        if code is None:
            ok = False
            continue
        _adb("shell", "input", "keyevent", str(code))
        time.sleep(delay)
    return ok


def read_focused_text():
    """Baca teks field yang sedang fokus dari UI hierarchy."""
    _adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = _adb("shell", "cat", "/sdcard/ui.xml").stdout
    for m in re.finditer(r"<node[^>]*>", xml):
        tag = m.group(0)
        if 'focused="true"' not in tag:
            continue
        t = re.search(r'text="([^"]*)"', tag)
        if t and "EditText" in tag:
            return t.group(1)
    return None


def clear_field():
    """Hapus isi field yang fokus."""
    _adb("shell", "input", "keyevent", "KEYCODE_MOVE_END")
    for _ in range(60):
        _adb("shell", "input", "keyevent", "67")  # DEL
    time.sleep(0.3)


def type_text(text, verify=True):
    """Ketik teks ke field fokus. Verifikasi hasilnya bila diminta."""
    _adb("shell", "input", "text", text.replace(" ", "%s"))
    time.sleep(0.7)

    if not verify:
        return True

    current = read_focused_text()
    if current is not None and current == text:
        return True

    # fallback: ketik per karakter
    clear_field()
    type_char_by_char(text)
    time.sleep(0.5)

    current = read_focused_text()
    return current == text
