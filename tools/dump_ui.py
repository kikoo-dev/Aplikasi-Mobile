"""Dump UI hierarchy perangkat dan tampilkan node yang punya teks/label.

Jalankan: python tools/dump_ui.py
"""
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android", "Sdk", "platform-tools", "adb.exe",
)
PKG = "com.example.social_profile_app"


def adb(*args):
    return subprocess.run(
        [ADB, *args], capture_output=True, text=True,
        encoding="utf-8", errors="ignore",
    ).stdout


def main():
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("shell", "cat", "/sdcard/ui.xml")

    pkgs = set(re.findall(r'package="([\w.]+)"', xml))
    print("Paket terdeteksi:", pkgs)

    rows = []
    for m in re.finditer(r"<node[^>]*>", xml):
        tag = m.group(0)

        def attr(name):
            r = re.search(name + r'="([^"]*)"', tag)
            return r.group(1) if r else ""

        txt = attr("text")
        desc = attr("content-desc")
        bounds = attr("bounds")
        cls = attr("class")
        clickable = attr("clickable")

        if txt or desc:
            rows.append((txt, desc, bounds, cls, clickable))

    print(f"\n{len(rows)} node dengan teks/label:\n")
    for txt, desc, bounds, cls, clickable in rows:
        b = re.findall(r"\d+", bounds)
        center = ""
        if len(b) == 4:
            cx = (int(b[0]) + int(b[2])) // 2
            cy = (int(b[1]) + int(b[3])) // 2
            center = f" center=({cx},{cy})"
        short_cls = cls.split(".")[-1]
        print(f"  text={txt!r:34} desc={desc!r:28} "
              f"{short_cls:14} click={clickable} {bounds}{center}")


if __name__ == "__main__":
    main()
