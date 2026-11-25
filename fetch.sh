#!/bin/sh
# Fetch RetroArch and the libretro core this card carries, each at one pinned
# commit, into third_party/, and apply the MUN patch to RetroArch.
#
# `mdk build` compiles with no network, so this runs first, on the host.
# Needs git. Safe to run again: it starts from nothing each time.
set -eu

cd "$(dirname "$0")"

RETROARCH_URL=https://github.com/libretro/RetroArch.git
RETROARCH_COMMIT=69a4f0ea1e8aaf442ae4858f2e7f2b31a1776576   # v1.22.2
CORE_URL=https://github.com/libretro/libretro-2048.git
CORE_COMMIT=39333f7b13dc4daea7c151d9c38d22b961246343
# Patches, in order, each with its SHA-256.
PATCHES="patches/0001-mun-session.patch:c3d4906c34c5a81506cef184d253e115946c528d7b58af0963d60eb5827c0465
patches/0002-static-core-configure.patch:7a884ba7e2a6e19d5bb4293385f159a42fc9e1a2fbc97c9cc5cd58e8e97d982e"

fetch() { # url commit directory
    rm -rf "$3"
    mkdir -p "$3"
    git -C "$3" init -q
    git -C "$3" remote add origin "$1"
    git -C "$3" -c advice.detachedHead=false fetch -q --depth 1 origin "$2"
    git -C "$3" -c advice.detachedHead=false checkout -q FETCH_HEAD
    [ "$(git -C "$3" rev-parse HEAD)" = "$2" ] || { echo "fetch.sh: $3 is not at $2" >&2; exit 1; }
    echo "fetched $3 at $2"
}

mkdir -p third_party
fetch "$RETROARCH_URL" "$RETROARCH_COMMIT" third_party/retroarch
fetch "$CORE_URL" "$CORE_COMMIT" third_party/core-2048

for entry in $PATCHES; do
    file=${entry%%:*}
    want=${entry##*:}
    got=$(sha256sum "$file" | cut -d' ' -f1)
    [ "$got" = "$want" ] || { echo "fetch.sh: $file does not match its SHA-256" >&2; exit 1; }
    git -C third_party/retroarch apply --whitespace=nowarn "../../$file"
    echo "applied $file"
done

# The build reads sources, not history.
rm -rf third_party/retroarch/.git third_party/core-2048/.git
