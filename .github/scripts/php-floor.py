#!/usr/bin/env python3
"""Print the minimum PHP major.minor required by an upstream composer.json.

Reads composer.json on stdin and prints the floor of its `require.php`
constraint (e.g. ">=8.1", "^8.1", ">=8.1 <9.0", "8.1.*" all -> "8.1").

The floor is the smallest major.minor mentioned in the constraint: for a
range like ">=8.1 <9.0" the lower bound 8.1 is the requirement; the 9.0 upper
bound is not. Exits non-zero if no version can be parsed, so callers fail loud
rather than silently shipping against an unknown requirement.

Used by both check-releases.yml (to decide whether to raise the tracked PHP)
and build.yml (to assert the built image satisfies upstream before publishing).
"""
import json
import re
import sys

try:
    data = json.load(sys.stdin)
except json.JSONDecodeError as exc:
    sys.exit(f"php-floor: could not parse composer.json: {exc}")

constraint = data.get("require", {}).get("php", "")
versions = re.findall(r"(\d+)\.(\d+)", constraint)
if not versions:
    sys.exit(f"php-floor: no PHP version found in require.php: {constraint!r}")

major, minor = min((int(a), int(b)) for a, b in versions)
print(f"{major}.{minor}")
