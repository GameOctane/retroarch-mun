#!/bin/sh
# Make the Game Card image for this project: build/retroarch-2048.img.
#
# `mdk pack` cannot say "these files are saves" yet (mun-project.toml has no
# [saves] table), so this runs the same checks and then MUN OS's own card tool
# with the directory-save flags. A save is whatever RetroArch writes into
# $HOME/.mun/saves, which the patched RetroArch sets as its save and
# save-state directory (docs/saves.md in MUN OS, "Directory saves").
#
#   MDK         the devkit's mdk            (default ../mun-devkit/mdk)
#   MUN_OS_DIR  a MUN OS checkout           (default ../mun-os)
set -eu

cd "$(dirname "$0")"
MDK=${MDK:-../mun-devkit/mdk}
MUN_OS_DIR=${MUN_OS_DIR:-../mun-os}
CARD_TOOL="$MUN_OS_DIR/tools/mun-card/mun-card"
[ -f "$CARD_TOOL" ] || { echo "pack.sh: no card tool at $CARD_TOOL (set MUN_OS_DIR)" >&2; exit 1; }

"$MDK" check --mun-os "$MUN_OS_DIR"

# The three patterns cover states (.state, .state1, .state.auto), battery RAM
# (.srm) and clocks (.rtc). `any` is a choice the tool makes us write down: a
# state cannot be shown complete by its bytes, and the console copies a file
# only when nobody has it open for writing.
python3 "$CARD_TOOL" create build/retroarch-2048.img \
    --variant game-gl --game build/retroarch-2048 --content build/content \
    --title="RetroArch: 2048" --id=retroarch.2048 --version=0.1.0 --size 128 \
    --saves-directory .mun/saves \
    --saves-unit '*.state*:any' --saves-unit '*.srm:any' --saves-unit '*.rtc:any' \
    --saves-max-bytes 8388608 --force
python3 "$CARD_TOOL" inspect build/retroarch-2048.img
