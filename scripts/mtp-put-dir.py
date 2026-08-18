#!/usr/bin/env python3
"""Put a host file into a folder on Kindle MTP storage.

Quit the Calibre GUI first. Run with calibre-debug, not system Python:

  calibre-debug -e scripts/mtp-put-dir.py -- LOCAL_FILE FOLDER DEST_NAME
"""
from __future__ import annotations

import os
import sys
import traceback


def main(argv: list[str]) -> int:
    args = [a for a in argv if a != "--"]
    if args and args[0].endswith("mtp-put-dir.py"):
        args = args[1:]
    if len(args) < 3:
        print(
            "Usage: calibre-debug -e scripts/mtp-put-dir.py -- <local> <folder> <name>",
            file=sys.stderr,
        )
        return 2

    local_path = os.path.abspath(args[0])
    folder_name = args[1].strip("/").split("/")[0]
    dest_name = os.path.basename(args[2])
    if not os.path.isfile(local_path):
        print(f"ERROR: not a file: {local_path}", file=sys.stderr)
        return 2
    size = os.path.getsize(local_path)
    print(f"[*] {local_path} ({size} bytes) → /{folder_name}/{dest_name}")

    from calibre.devices.scanner import DeviceScanner
    from calibre.devices.mtp.driver import MTP_DEVICE

    dev = MTP_DEVICE(None)
    dev.startup()
    scanner = DeviceScanner()
    scanner.scan()
    connected = dev.detect_managed_devices(scanner.devices)
    if not connected:
        print("ERROR: no MTP device", file=sys.stderr)
        return 1
    print(f"[*] opening {connected!r}")
    dev.open(connected, "mtp-put-dir")
    try:
        fs = dev.filesystem_cache
        storages = list(getattr(fs, "entries", []) or [])
        if not storages:
            print("ERROR: no storage", file=sys.stderr)
            return 1
        parent = storages[0]
        print(f"[*] storage {getattr(parent, 'name', parent)!r}")

        folder = None
        children = getattr(parent, "files", None) or getattr(parent, "children", None) or []
        for c in children:
            if getattr(c, "name", None) == folder_name:
                folder = c
                break
        if folder is None:
            print(f"[*] create_folder {folder_name!r}")
            folder = dev.create_folder(parent, folder_name)

        fchildren = getattr(folder, "files", None) or getattr(folder, "children", None) or []
        for c in fchildren:
            if getattr(c, "name", None) == dest_name:
                print(f"[*] replace {dest_name}")
                dev.delete_file_or_folder(c)
                break

        with open(local_path, "rb") as stream:
            try:
                result = dev.put_file(parent if folder is None else folder, dest_name, stream, size, callback=None, replace=True)
            except TypeError:
                stream.seek(0)
                result = dev.put_file(
                    folder, dest_name, stream, size, callback=None, replace_file=True
                )
        print(f"[*] put_file result={result!r}")
        print("[*] OK")
        return 0
    except Exception:
        traceback.print_exc()
        return 1
    finally:
        for fn in ("eject", "shutdown"):
            try:
                getattr(dev, fn)()
            except Exception:
                pass


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
