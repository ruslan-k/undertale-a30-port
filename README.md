# Undertale for Miyoo A30 (SpruceOS)

A working Butterscotch-based Undertale runner for the Miyoo A30. Rendering, audio, and controls were confirmed on hardware.

## Status

| Subsystem | State |
|---|---|
| Launch from the SpruceOS ports menu | working |
| Portrait-panel rendering with rotation | working |
| Audio | working |
| Controls (D-pad, face buttons, start) | working |
| Y button opens the in-game menu (ITEM/STAT/CELL) | working |
| Analog stick and D-pad movement at the same time | working |
| Memory | about 162 MB RSS, no OOM |

## Repository contents

- `runtime/butterscotch_sw2` — prebuilt armhf runner (SDL2 + software renderer, glibc 2.23). MD5: `1e09e12d1e0b2b043eefbbfd4707d0e4`. This is the exact binary used on the device.
- `launcher/Undertale.sh` — launcher
- `launcher/gamecontrollerdb.txt` — controller mapping
- `patches/butterscotch-a30.patch` — source changes
- `build/build_bs_a30.sh` — cross-build script

## Installation

1. Copy `launcher/Undertale.sh` to `/mnt/SDCARD/Roms/A30PORTS/` and make it executable (`chmod +x`).
2. Create `/mnt/SDCARD/Roms/A30PORTS/undertale/`.
3. Copy `runtime/butterscotch_sw2` there and make it executable.
4. Copy `launcher/gamecontrollerdb.txt` into the same directory.
5. Put the game assets in `undertale/gamedata/`: `data.win` and the 212 `.ogg` audio files it references.
6. Start the port from the SpruceOS ports menu.

The prebuilt binary targets the A30 toolchain ABI (glibc 2.23, armhf) and expects the device SDL2/Mali libraries from `/mnt/SDCARD/spruce/a30/sdl2/sdl2`. Rebuild it with `build/build_bs_a30.sh` if the toolchain or base branch changes.

Controls: A = confirm (Z), B/X = cancel (X), START = confirm (Enter), Y = game menu (GML `C` = 67). Movement comes from both the D-pad (`event3` key events) and the analog stick (`event4` axes 16/17); the launcher sends SIGUSR2 to joystickinput to release that device. Long-press the physical Menu/Esc button for about one second to quit cleanly to SpruceOS. Undertale 1.08 has no in-game "return to title" command; restart the game to see the title screen again.

## Device layout

- `/mnt/SDCARD/Roms/A30PORTS/Undertale.sh` — launcher
- `/mnt/SDCARD/Roms/A30PORTS/undertale/butterscotch_sw2` — built runner (SDL2 + software renderer)
- `/mnt/SDCARD/Roms/A30PORTS/undertale/gamedata/data.win` — game data
- `/mnt/SDCARD/Roms/A30PORTS/undertale/gamedata/*.ogg` — 212 audio files
- `/mnt/SDCARD/Roms/A30PORTS/undertale/gamecontrollerdb.txt` — controller mapping

The launcher relies on the runner default that places runtime files next to `data.win`, so no extra directory option is needed.

## Build

Base: `cobaltgit/Butterscotch`, branch `miyoomini-v2`. Cross-build with the public A30 buildroot toolchain from `steward-fu/website`, release `miyoo-a30` (`a30_toolchain-v1.0.tar.gz`, glibc 2.23, SDL2 2.28.5). See `build/build_bs_a30.sh`.

Patches are in `patches/butterscotch-a30.patch` and apply to that branch:

1. `src/sw/defines.h` — `PIXEL_SIZE` 16 → 32. The software renderer produced RGB565 while the SDL backend read a 32-bit buffer, which caused green/purple stripes and duplicated images.
2. `src/backends/sdl2.c`:
   - the SDL renderer is created before `SDL_GetWindowSurface()` (otherwise: `Renderer already associated with window`); the frame is rotated 270 degrees with `SDL_RenderCopyEx` using an explicit swapped destination rect (a `NULL` destination stretches first and leaves black bars), and the texture comes from `SDL_CreateTextureFromSurface`.
   - `A30_SWAP`: the game renders 640x480 while the SDL window is 480x640 to match the portrait panel.
   - controllers are opened after loading `gamecontrollerdb.txt`; `SDL_CONTROLLERDEVICEADDED` can arrive before the mapping is available, leaving the device closed otherwise.
   - `A30_KEYS`: direct reads of `/dev/input/event3` (`gpio-keys-polled`) translate the physical buttons to GML keys. On the A30 these buttons arrive as keyboard events, not on the virtual SDL joystick. This follows the approach used by `spruceUI/mupen64plus-spruce` (`tools/a30_input_shim.c`).
3. `src/runner_gamepad.c` — enables the existing `RawToGPUndertale` button translation instead of `RawToGPDelta`.

`A30_ROT` allows changing the rotation angle without rebuilding.

## Notes

- Ready-made SDL2 + modern GL builds run out of memory on this device: 41 texture pages of about 16 MB each with 512 MB RAM. The working configuration is SDL2 with the software renderer.
- `/dev/mem` cannot be read on this firmware, and writing to it is unsafe.
- `kmsgrab` is unavailable: there is no `/dev/dri`, and the firmware binary is aarch64 while the device is 32-bit.
- No system SpruceOS files are modified by this port.
