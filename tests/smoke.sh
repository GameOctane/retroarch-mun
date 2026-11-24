#!/bin/sh
# Run the built entry as a console would start it (no arguments, HOME empty,
# MUN_CONTENT_DIR set), headless, inside the devkit's build environment, then
# stop it with SIGTERM and check what the contracts promise:
#   - it exits 0 (docs/runtime.md: "end cleanly on SIGTERM"),
#   - it wrote its session config and its auto save state under HOME/.mun/saves,
#     the directory the card declares as saves.
#
# Needs docker (linux/arm64) and a built project (`mdk build`). It does not
# show a picture or play a sound: the drivers are null. What it cannot say is
# whether the display, sound and keys work on a console.
set -eu

cd "$(dirname "$0")/.."
MDK=${MDK:-../mun-devkit/mdk}
IMAGE=$("$MDK" env | awk '$1 == "image" { print $2 }')
[ -n "$IMAGE" ] || { echo "smoke.sh: the devkit's environment is not built (mdk env build)" >&2; exit 1; }
[ -x build/retroarch-2048 ] || { echo "smoke.sh: build/retroarch-2048 missing (mdk build)" >&2; exit 1; }

exec docker run --rm --platform linux/arm64 --network none -v "$PWD:/work:ro" -w /work "$IMAGE" sh tests/smoke-inner.sh
