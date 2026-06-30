#!/usr/bin/env bash
# Show a space only if it exists AND (has windows OR is focused).
# Spaces that don't exist in Mission Control are hidden too.

python3 <<'PY'
import json, subprocess

def sh(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout

spaces = {s["index"]: s for s in json.loads(sh("yabai", "-m", "query", "--spaces") or "[]")}

args = []
for idx in range(1, 11):                       # space.1 .. space.10 items exist
    s = spaces.get(idx)
    show = bool(s) and (bool(s.get("windows")) or s.get("has-focus", False))
    args += ["--set", f"space.{idx}", "drawing=" + ("on" if show else "off")]

subprocess.run(["sketchybar", *args])
PY
