#!/usr/bin/env bash
# Smoke-test a UniFi-API-browser image: boot it, confirm it serves the login
# page (HTTP 200), and confirm its PHP satisfies upstream's real runtime floor
# (vendor/composer/platform_check.php -- the locked requirement, not the lagging
# composer.json require.php).
#
# Shared by ci.yml (tests a locally-built amd64 image) and smoke.yml (tests an
# image pulled from ghcr by digest), so both gates run the identical checks.
#
# Usage: smoke-test.sh <image-ref> <upstream-version>
#   <image-ref>        anything `docker run` accepts (a local tag or image@sha256:...)
#   <upstream-version> the UniFi-API-browser tag, e.g. v3.0.0 (for the floor lookup)
set -euo pipefail

IMAGE="${1:?usage: smoke-test.sh <image-ref> <upstream-version>}"
VERSION="${2:?usage: smoke-test.sh <image-ref> <upstream-version>}"
HERE="$(cd "$(dirname "$0")" && pwd)"

cid=$(docker run -d -p 8000:8000 "$IMAGE")
trap 'docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT

code=000
for _ in $(seq 1 20); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/UniFi-API-browser/ || true)
  [ "$code" = "200" ] && break
  sleep 1
done
echo "HTTP status: ${code}"
if [ "$code" != "200" ]; then
  echo "::error title=smoke-test::app did not return HTTP 200"
  docker logs "$cid" || true
  exit 1
fi

# Catches a fatal PHP/Twig error that still returns 200 with an error body.
if ! curl -s http://localhost:8000/UniFi-API-browser/ | grep -qi 'UniFi API Browser'; then
  echo "::error title=smoke-test::login page title missing -- likely a PHP/Twig fatal"
  docker logs "$cid" || true
  exit 1
fi

# Assert PHP satisfies upstream's AUTHORITATIVE runtime floor. composer.json's
# require.php lags (v3.0.0 declares >=8.1 but the locked deps need >=8.2, and an
# 8.1 image 500s on every request), so read the floor from platform_check.php.
FLOOR=$(curl -fsSL "https://raw.githubusercontent.com/Art-of-WiFi/UniFi-API-browser/${VERSION}/vendor/composer/platform_check.php" | python3 "${HERE}/php-floor.py")
FLOOR_ID=$(awk -F. '{ printf "%d%02d00", $1, $2 }' <<<"$FLOOR")
echo "upstream PHP floor: ${FLOOR} (id ${FLOOR_ID})"
if ! docker exec -e FLOOR_ID="$FLOOR_ID" "$cid" php -r 'exit(PHP_VERSION_ID >= (int)getenv("FLOOR_ID") ? 0 : 1);'; then
  echo "::error title=smoke-test::image PHP $(docker exec "$cid" php -r 'echo PHP_VERSION;') is below upstream's required ${FLOOR}. Bump base.php in .github/tracked-versions.json."
  exit 1
fi

echo "smoke-test OK (PHP satisfies upstream floor ${FLOOR})"
