#!/usr/bin/env python3
"""Project layout check (see README "Layout"). Looks at tracked files only."""
import re
import subprocess

files = subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout.split("\n")
files = [f for f in files if f and not f.startswith("addons/")]
dirs = {"/".join(f.split("/")[:i]) for f in files for i in range(1, f.count("/") + 1)}
name = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_.]+)?$")
# assets/kenney/ keeps the names as shipped (hyphens, capitals): third-party, never renamed.
kenney = re.compile(r"^[A-Za-z0-9_-]+(\.[A-Za-z0-9_.-]+)?$")
not_godot = {"rust", "cpp", "raw", "docs", "tools"}
bad = []
for f in files:
    top, parts = f.split("/")[0], f.split("/")
    if f.endswith(".gd") and top not in ("scripts", "test"):
        bad.append(f"{f}: .gd files live under scripts/ or test/")
    if f.endswith(".tscn") and top != "game":
        bad.append(f"{f}: .tscn files live under game/")
    if len(parts) > 1 and not top.startswith(".") and top not in not_godot:
        rx = kenney if f.startswith("assets/kenney/") else name
        if not all(rx.match(p) for p in parts):
            bad.append(f"{f}: every path segment must be lowercase snake_case")
    if top == "scripts" and f.endswith(".gd") and len(parts) > 2 and parts[1] not in ("components", "autoloads"):
        game_dir = "game/" + "/".join(parts[1:-1])
        if game_dir not in dirs:
            bad.append(f"{f}: needs a matching feature folder {game_dir}/")
print("\n".join(sorted(set(bad))))
raise SystemExit(bool(bad))
