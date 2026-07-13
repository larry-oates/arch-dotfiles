#!/usr/bin/env python3
"""Monitor for Xbox controller guide button and open Steam Big Picture.

Two modes:
  - No arguments (persistent watcher): launches steam://open/bigpicture on guide press
  - With flag file argument (startup menu): writes flag file on guide press
"""
import struct
import sys
import os
import select
import subprocess
import time

EVENT_FORMAT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

EV_KEY = 0x01
BTN_GUIDE = 0x0ac  # Xbox guide button

FLAG_FILE = sys.argv[1] if len(sys.argv) > 1 else None


def is_steam_running():
    """Check if Steam is already running."""
    try:
        result = subprocess.run(
            ["pgrep", "-x", "steam"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return result.returncode == 0
    except Exception:
        return False


def handle_guide_button():
    """Handle guide button press: write flag file or launch Big Picture."""
    if FLAG_FILE:
        with open(FLAG_FILE, "w") as f:
            f.write("1")
    else:
        if is_steam_running():
            return
        try:
            subprocess.Popen(
                ["steam", "steam://open/bigpicture"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except Exception:
            pass


def find_xbox_controller():
    """Scan /proc/bus/input/devices for Xbox controllers."""
    try:
        with open("/proc/bus/input/devices") as f:
            content = f.read()
    except OSError:
        return None

    blocks = content.split("\n\n")
    for block in blocks:
        lower = block.lower()
        if "xbox" in lower or "microsoft" in lower or "x-box" in lower:
            for line in block.splitlines():
                if line.startswith("H: Handlers="):
                    for token in line.split():
                        if token.startswith("event"):
                            path = f"/dev/input/{token}"
                            if os.path.exists(path):
                                return path
    return None


def main():
    while True:
        device_path = find_xbox_controller()

        if device_path is None:
            time.sleep(2)
            continue

        try:
            fd = os.open(device_path, os.O_RDONLY)
        except (PermissionError, OSError):
            time.sleep(2)
            continue

        try:
            while True:
                r, _, _ = select.select([fd], [], [], 1.0)
                if not r:
                    continue
                data = os.read(fd, EVENT_SIZE)
                if len(data) < EVENT_SIZE:
                    break
                _, _, ev_type, ev_code, ev_value = struct.unpack(
                    EVENT_FORMAT, data
                )
                if ev_type == EV_KEY and ev_code == BTN_GUIDE and ev_value == 1:
                    handle_guide_button()
        except (OSError, IOError):
            try:
                os.close(fd)
            except Exception:
                pass
            time.sleep(1)


if __name__ == "__main__":
    main()
