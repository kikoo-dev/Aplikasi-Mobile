"""Tampilkan node UI (semantics) perangkat saat ini, plus status paket fokus."""
import os
import re
import subprocess
import sys

ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)


def adb(*args):
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    ).stdout


def main():
    focus = adb("shell", "dumpsys", "window", "displays")
    m = re.search(r"mCurrentFocus=Window\{[^}]*?\s([\w.]+)/", focus)
    print("FOKUS:", m.group(1) if m else "?")

    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("shell", "cat", "/sdcard/ui.xml")

    print()
    for mm in re.finditer(r"<node[^>]*>", xml):
        tag = mm.group(0)

        def a(name):
            r = re.search(name + r'="([^"]*)"', tag)
            return r.group(1) if r else ""

        desc = a("content-desc") or a("text")
        if not desc:
            continue
        cls = a("class").split(".")[-1]
        print(f"{cls:14} {a('bounds'):28} click={a('clickable'):5} "
              f"focus={a('focused'):5} {desc[:72]!r}")


if __name__ == "__main__":
    main()
