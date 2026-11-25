#!/bin/sh
# Runs inside the devkit's environment, with the project mounted read-only at
# /work. See smoke.sh.
set -eu

HOME=$(mktemp -d)
CONTENT=$(mktemp -d)
export HOME MUN_CONTENT_DIR="$CONTENT"
export MUN_SESSION=smoke MUN_RUNTIME_PROFILE=linux-arm64-gl-v0

# The card's own config, with only the display, sound and input drivers swapped
# for null ones: everything else, saves included, is what a card carries.
grep -v -E '^(video_driver|audio_driver|input_driver|input_joypad_driver|video_fullscreen|video_windowed_fullscreen)[ =]' \
    /work/build/content/retroarch.cfg > "$CONTENT/retroarch.cfg"
cp -R /work/build/content/rom "$CONTENT/rom"
cat >> "$CONTENT/retroarch.cfg" <<'EOF'
video_driver = "null"
audio_driver = "null"
input_driver = "null"
input_joypad_driver = "null"
log_verbosity = "true"
EOF

cd "$HOME"
/work/build/retroarch-2048 > "$HOME/run.log" 2>&1 &
pid=$!
sleep 8
kill -0 "$pid" 2>/dev/null || { echo "FAIL: exited before SIGTERM"; cat "$HOME/run.log"; exit 1; }
kill -TERM "$pid"
rc=0
wait "$pid" || rc=$?

echo "--- session.cfg"; cat "$HOME/.mun/session.cfg" 2>&1
echo "--- run.log"; cat "$HOME/run.log"
echo "--- exit code: $rc"
[ "$rc" -eq 0 ] || { echo "FAIL: exit code $rc after SIGTERM, wanted 0"; exit 1; }
[ -f "$HOME/.mun/session.cfg" ] || { echo "FAIL: no session.cfg: the MUN start-up did not run"; exit 1; }
ls -l "$HOME/.mun/saves"
ls "$HOME"/.mun/saves/*.state* >/dev/null 2>&1 || { echo "FAIL: no state in .mun/saves after SIGTERM"; exit 1; }
echo "PASS"
