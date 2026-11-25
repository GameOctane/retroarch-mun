# RetroArch on MUN

RetroArch, with one libretro core linked into it, as a game for MUN OS's
`linux-arm64-gl-v0` runtime profile. The first card carries the public-domain
**2048** core, so the whole path can be proven without any ROM.

## Status

Built and checked in CI on an ARM64 runner (GitHub Actions, green). Not yet run
in MUN OS's virtual console or on any display, so video, sound and keys are
untried.

| Check | Result |
| --- | --- |
| Patches apply to RetroArch v1.22.2 at its pinned commit; sources fetched at pinned commits | Yes |
| Compiles and links in the devkit's Debian 13 ARM64 environment | Yes: a 9.8 MiB ELF |
| `mdk check`: needs only libraries the profile provides (libm, libasound, libGL, SDL2, libc) | Passes; one warning, no BTI/PAC branch protection (the devkit's "report" level) |
| Started as a console starts it (no arguments, empty HOME, `MUN_CONTENT_DIR`), headless | Yes: runs the core directly, no menu |
| SIGTERM | Exits 0, after writing `2048.state.auto` and `2048.srm` into `.mun/saves` (the directory the card declares) |
| Card image made and inspected by MUN OS's card tool | Yes, valid; directory saves declared |
| Real display (SDL2 over KMS/DRM), sound, keyboard, restoring the state in a second session, card removal | **Not tried** |

Known: with the null audio driver RetroArch logs `failed_to_start_audio_driver`
and carries on without sound; on a console the audio path is SDL2 over ALSA and
is untested.

## How it fits MUN's contracts

| MUN contract ([runtime](https://github.com/Play-MUN/mun-os/blob/main/docs/runtime.md)) | What this does |
| --- | --- |
| The entry is one AArch64 ELF of at most 64 MiB; `content/` is `noexec` | RetroArch is built with `--disable-dynamic` and the core as a static archive. No `.so` core can load on a console |
| Started with no arguments | The patch (`retroarch.c`, `main`) builds RetroArch's command line from `MUN_CONTENT_DIR` when it is given none: `--appendconfig` and, if `rom/` holds a file, that file |
| `HOME` is empty RAM, gone with the session | The patch writes `$HOME/.mun/session.cfg`: it includes the card's `retroarch.cfg` and points saves and states at `$HOME/.mun/saves` |
| Only the profile's libraries | `build.sh` turns off udev, X11, Wayland, Pulse, zlib, FreeType and the rest, or builds them in. `mdk check` reads the result (`E-LIB`) |
| SIGTERM, then 3 s | RetroArch's own handler ends its loop; `main` returns 0. `tests/smoke.sh` checks it |
| Saves live on the card ([saves](https://github.com/Play-MUN/mun-os/blob/main/docs/saves.md)) | Directory saves: `.mun/saves`, units `*.state*`, `*.srm`, `*.rtc`, check `any`, at most 8 MiB. Auto save and auto load of the state are on, so a player resumes |
| Keyboard only | Arrows, X, Z, Enter, Right Shift, Escape to quit |

## Build

Needs docker running `linux/arm64` (an ARM64 computer, or emulation: slow),
git, Python 3.9+, and e2fsprogs 1.47+. The devkit and MUN OS are used as they
are, not changed. On macOS or Linux ARM64:

```sh
git clone https://github.com/Play-MUN/mun-devkit ../mun-devkit
../mun-devkit/mdk os fetch && ../mun-devkit/mdk env build
./fetch.sh                          # RetroArch and the core, pinned, patched (network)
../mun-devkit/mdk build             # inside the SDK environment (no network)
../mun-devkit/mdk check
sh tests/smoke.sh                   # headless run, SIGTERM, exit 0, state saved
MUN_OS_DIR=../mun-devkit/.local/mun-os sh pack.sh    # build/retroarch-2048.img
```

On Windows the devkit does not run (its docs say so). Push this folder to a
GitHub repository and let `.github/workflows/build.yml` do it on an ARM64
runner; the card image comes back as the workflow's artifact.

Then, from a MUN OS checkout: `./mun get`, `./mun dev run --window`, and
`./mun dev vm dev card-attach NAME` with the image copied to
`.local/gamecards/NAME.img` ([getting started](https://github.com/Play-MUN/mun-os/blob/main/docs/getting-started.md)).

## Another core, and real ROMs

One card is one core: the entry is one ELF, so a different system is a
different build. To change it, edit `fetch.sh` (core URL and commit), the
core's archive name in `build.sh`, and `mun-project.toml`. A core that needs
a ROM reads it from the card: put the file in `content/rom/` (the patch passes
the first file by name), and give the card only what you own the right to
copy. Cores that need BIOS files read them from `system_directory`, which is
`$HOME/.mun/system` and empty: either embed them in `content/` and point
`system_directory` at `$MUN_CONTENT_DIR`'s copy through `retroarch.cfg`, or
accept that the core will not start. Save states of larger cores can exceed
the 8 MiB bound on directory saves, and then do not save.

## Licence

RetroArch is GPL-3.0-or-later; the 2048 core is public domain. A binary
that contains RetroArch may be shared only with its corresponding source
(this folder, `fetch.sh`'s pins and the patch). Nothing is published from
here. MUN OS and the devkit never carry a third-party game: this project stays
outside both.
