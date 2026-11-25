#!/bin/sh
# Build RetroArch with one libretro core linked in statically, for the MUN
# runtime profile linux-arm64-gl-v0. `mdk build` runs this inside the devkit's
# Debian 13 ARM64 environment (no network), from the project directory, after
# fetch.sh has filled third_party/.
#
# Why static: the card's content/ is mounted noexec, so RetroArch's usual
# dynamically loaded cores (.so) cannot be loaded on a console. The entry is
# one ELF of at most 64 MiB.
#
# Why so many things are off: the profile promises SDL2, OpenAL, Mesa (GL,
# EGL, GBM), ALSA and libstdc++, and nothing else. Every other library
# RetroArch can use (udev, X11, Wayland, PulseAudio, zlib, FreeType, ...) is
# either disabled or built in, so `mdk check` finds no E-LIB.
set -eu

JOBS=$(nproc 2>/dev/null || echo 2)
ROOT=$(pwd)
OUT=build
NAME=retroarch-2048

[ -d third_party/retroarch ] && [ -d third_party/core-2048 ] || {
    echo "build.sh: third_party/ is empty; run ./fetch.sh first (it needs the network; this build has none)" >&2
    exit 1
}
command -v pkg-config >/dev/null 2>&1 || command -v pkgconf >/dev/null 2>&1 || {
    echo "build.sh: RetroArch's configure needs pkg-config, which this environment does not have" >&2
    exit 1
}

mkdir -p "$OUT/content"

# 1. The core, as a static archive.
# CFLAGS goes in the environment, not on make's command line: the core's
# makefile appends its include paths with `CFLAGS +=`, which a command-line
# CFLAGS would silently override.
CFLAGS="-O2 -g0 -fstack-protector-strong -D_FORTIFY_SOURCE=3" \
make -C third_party/core-2048 -f Makefile.libretro platform=unix STATIC_LINKING=1 -j"$JOBS"
CORE_A=$(ls "$ROOT"/third_party/core-2048/*_libretro_unix.a)

# 2. RetroArch, with that core and only what the profile provides.
cd third_party/retroarch
CFLAGS="-O2 -g0 -fstack-protector-strong -D_FORTIFY_SOURCE=3" \
CXXFLAGS="-O2 -g0 -fstack-protector-strong" \
./configure \
    --disable-dynamic --with-libretro="$CORE_A -lm" \
    --enable-sdl2 --disable-sdl --enable-opengl --enable-alsa \
    --disable-kms --disable-egl --disable-vg --disable-udev --disable-x11 --disable-wayland \
    --disable-vulkan --disable-pulse --disable-oss --disable-jack --disable-pipewire \
    --disable-roar --disable-rsound --disable-tinyalsa --disable-audioio --disable-sndio \
    --disable-networking --disable-networkgamepad --disable-ssl --disable-discord \
    --disable-cheevos --disable-online_updater --disable-update_cores \
    --disable-update_core_info --disable-update_assets --disable-qt --disable-ffmpeg \
    --disable-freetype --disable-xmb --disable-ozone --disable-materialui \
    --disable-cdrom --disable-v4l2 --disable-systemd --disable-libusb --disable-flac \
    --disable-glslang --disable-slang --disable-spirv_cross --disable-builtinglslang \
    --disable-videoprocessor --disable-videocore --disable-parport --disable-rpiled \
    --enable-builtinzlib
make -j"$JOBS" retroarch
cd "$ROOT"

# 3. The entry, and the card's content.
cp third_party/retroarch/retroarch "$OUT/$NAME"
strip "$OUT/$NAME"
mkdir -p "$OUT/content"
cp content/retroarch.cfg "$OUT/content/retroarch.cfg"
ls -l "$OUT/$NAME"
