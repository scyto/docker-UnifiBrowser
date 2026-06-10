#!/usr/bin/env python3
"""Print the minimum PHP major.minor a UniFi-API-browser release needs to RUN.

Reads vendor/composer/platform_check.php on stdin and extracts the PHP floor it
enforces. This is the AUTHORITATIVE runtime requirement: Composer generates this
file from the union of the root project and every locked dependency's PHP
constraint, so it is correct even when composer.json's `require.php` lags behind.

This distinction is not academic -- it is exactly the bug that shipped a broken
image: v3.0.0's composer.json declares `"php": ">=8.1"`, but its locked deps need
PHP >= 8.2, and platform_check.php enforces that with `PHP_VERSION_ID >= 80200`.
Running such an image on 8.1 makes every request 500. Reading composer.json gave
8.1; reading platform_check.php gives the real answer, 8.2.

The file contains a guard like:
    if (!(PHP_VERSION_ID >= 80200)) { $issues[] = '... ">= 8.2.0" ...'; }
We take the highest PHP_VERSION_ID asserted and print it as major.minor. If the
integer form is absent we fall back to the human-readable '">= X.Y.0"' string.
"""
import re
import sys

text = sys.stdin.read()

# Primary: the integer guard composer emits, e.g. `PHP_VERSION_ID >= 80200`.
ids = [int(m) for m in re.findall(r"PHP_VERSION_ID\s*>=\s*(\d+)", text)]
if ids:
    vid = max(ids)
    print(f"{vid // 10000}.{(vid // 100) % 100}")
    sys.exit(0)

# Fallback: the human-readable requirement string, e.g. '">= 8.2.0"'.
pairs = re.findall(r">=\s*(\d+)\.(\d+)", text)
if pairs:
    major, minor = max((int(a), int(b)) for a, b in pairs)
    print(f"{major}.{minor}")
    sys.exit(0)

sys.exit("php-floor: no PHP version requirement found in platform_check.php")
