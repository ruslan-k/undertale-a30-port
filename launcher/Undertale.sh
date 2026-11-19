#!/bin/sh
# Miyoo A30 / SpruceOS — Undertale (Butterscotch SDL2 + software renderer, 270 rotation)
ROM_DIR="$(cd "$(dirname "$0")" && pwd)"
GAMEDIR="$ROM_DIR/undertale"
cd "$GAMEDIR" || exit 1

export LD_LIBRARY_PATH="/mnt/SDCARD/spruce/a30/sdl2/sdl2:/mnt/SDCARD/miyoo/lib:/lib:/usr/lib:${LD_LIBRARY_PATH:-}"
export SDL_VIDEODRIVER=mali
export SDL_RENDER_DRIVER=opengles2
export SDL_FBDEV=/dev/fb0
export SDL_AUDIODRIVER=alsa
export SDL_NOMOUSE=1
export A30_ROT=270
export A30_SWAP=1
export A30_KEYS=1

# A30 pad: use js0 + explicit controller mapping (same as Moonlight port)
export SDL_JOYSTICK_DEVICE=/dev/input/js0
export SDL_LINUX_JOYSTICK_CLASSIC=1
export SDL_JOYSTICK_HIDAPI=0
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export SDL_GAMECONTROLLERCONFIG_FILE="$GAMEDIR/gamecontrollerdb.txt"
export SDL_GAMECONTROLLERCONFIG="$(grep -v "^[[:space:]]*#" "$GAMEDIR/gamecontrollerdb.txt" | grep -v "^[[:space:]]*$")"

# release event4 from joystickinput so the runner can read the analog stick
killall -q -USR2 joystickinput 2>/dev/null

# stick -> d-pad mode for gamepad-to-keyboard layer
./butterscotch_sw2 --renderer software --window-size 480x640 "$GAMEDIR/gamedata/data.win" > "$GAMEDIR/undertale.log" 2>&1
rc=$?
exit $rc
