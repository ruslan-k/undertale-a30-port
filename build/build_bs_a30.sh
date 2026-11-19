#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq 2>/dev/null
apt-get install -y -qq --no-install-recommends build-essential pkg-config git ca-certificates wget make python3 file >/dev/null 2>&1

cd /tmp
wget -q https://github.com/steward-fu/website/releases/download/miyoo-a30/a30_toolchain-v1.0.tar.gz -O a30_toolchain.tar.gz
tar xzf a30_toolchain.tar.gz -C /opt
rm -f a30_toolchain.tar.gz

TARGET=arm-a30-linux-gnueabihf
SYSROOT=/opt/a30/$TARGET/sysroot
export PATH=/opt/a30/bin:$PATH

rm -f /opt/a30/bin/$TARGET-gcc /opt/a30/bin/$TARGET-g++
printf '#!/bin/sh\nexec /opt/a30/bin/%s-gcc-13.2.0.br_real --sysroot=%s "$@"\n' "$TARGET" "$SYSROOT" > /opt/a30/bin/$TARGET-gcc
printf '#!/bin/sh\nexec /opt/a30/bin/%s-c++.br_real --sysroot=%s "$@"\n' "$TARGET" "$SYSROOT" > /opt/a30/bin/$TARGET-g++
chmod +x /opt/a30/bin/$TARGET-gcc /opt/a30/bin/$TARGET-g++

printf '#!/bin/sh\nexport PKG_CONFIG_SYSROOT_DIR=%s\nexport PKG_CONFIG_LIBDIR=%s/usr/lib/pkgconfig:%s/usr/share/pkgconfig\nexec pkg-config "$@"\n' "$SYSROOT" "$SYSROOT" "$SYSROOT" > /opt/a30/bin/$TARGET-pkg-config
chmod +x /opt/a30/bin/$TARGET-pkg-config

cd "$SYSROOT/lib"
for pair in "ld-2.23.so ld-linux-armhf.so.3" "libc-2.23.so libc.so.6" "libpthread-2.23.so libpthread.so.0" "libdl-2.23.so libdl.so.2" "libm-2.23.so libm.so.6" "librt-2.23.so librt.so.1"; do
  set -- $pair
  [ -e "$1" ] && ln -sf "$1" "$2" || true
done

echo "TOOLCHAIN: $($TARGET-gcc --version | head -1)"
echo "SDL2: $($TARGET-pkg-config --modversion sdl2 2>&1 || true)"

cd /src
make clean >/dev/null 2>&1 || true
make -j4 CC=$TARGET-gcc PKG_CONFIG=$TARGET-pkg-config BACKEND=sdl2 AUDIO_BACKEND=miniaudio DISABLE_LEGACY_GL=1 DISABLE_MODERN_GL=1 2>&1 | tail -25
echo "=== result ==="
file build/butterscotch
readelf -d build/butterscotch | grep NEEDED
