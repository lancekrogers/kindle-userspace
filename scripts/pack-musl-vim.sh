#!/usr/bin/env bash
# Build a FAT-safe musl/armv7 vim tree (no symlinks, no chroot).
# Output: work/vim-kindlehf.tar.gz
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
DL="$WORK/dl/vim"
EXT="$WORK/extract/vim"
FLAT="$WORK/flat/vim"
OUT="$WORK/vim-kindlehf.tar.gz"
ALPINE="${ALPINE_VERSION:-v3.21}"
BASE="https://dl-cdn.alpinelinux.org/alpine/${ALPINE}/main/armv7"

APKS=(
  vim-9.1.1105-r0
  vim-common-9.1.1105-r0
  xxd-9.1.1105-r0
  libncursesw-6.5_p20241006-r3
  ncurses-terminfo-base-6.5_p20241006-r3
  musl-1.2.5-r11
)

mkdir -p "$DL" "$EXT" "$FLAT/bin" "$FLAT/lib" "$FLAT/share/vim" "$FLAT/share/terminfo"
cd "$DL"
for p in "${APKS[@]}"; do
  if [ ! -f "$p.apk" ]; then
    echo "GET $p.apk"
    curl -fL --retry 3 -o "$p.apk" "$BASE/$p.apk"
  fi
  tar -xzf "$p.apk" -C "$EXT" --exclude='.SIGN.*' --exclude='.PKGINFO' 2>/dev/null \
    || gzip -dc "$p.apk" | tar -xf - -C "$EXT" --exclude='.SIGN.*' --exclude='.PKGINFO'
done

copy_so() {
  local src="$1" dest="$2"
  python3 - "$src" "$FLAT/lib/$dest" <<'PY'
import os, shutil, sys
src, dest = sys.argv[1], sys.argv[2]
shutil.copy(os.path.realpath(src), dest)
print("so", dest)
PY
}

copy_tree() {
  python3 - "$1" "$2" <<'PY'
import os, shutil, sys
src, dest = sys.argv[1], sys.argv[2]
os.makedirs(dest, exist_ok=True)
for root, dirs, files in os.walk(src):
    rel = os.path.relpath(root, src)
    out = dest if rel == "." else os.path.join(dest, rel)
    os.makedirs(out, exist_ok=True)
    for name in files:
        s = os.path.join(root, name)
        d = os.path.join(out, name)
        real = os.path.realpath(s)
        if os.path.isfile(real):
            shutil.copy(real, d)
print("tree", dest)
PY
}

LOADER=$(find "$EXT" -name 'ld-musl-armhf.so.1' | head -1)
test -n "$LOADER"
cp -f "$LOADER" "$FLAT/lib/ld-musl-armhf.so.1"
cp -f "$LOADER" "$FLAT/lib/libc.musl-armv7.so.1"

NC=$(find "$EXT" -name 'libncursesw.so.6' | head -1)
test -n "$NC"
copy_so "$NC" libncursesw.so.6

cp -f "$EXT/usr/bin/vim" "$FLAT/bin/vim"
cp -f "$EXT/usr/bin/xxd" "$FLAT/bin/xxd"
chmod 0755 "$FLAT/bin/vim" "$FLAT/bin/xxd"

if [ -d "$EXT/usr/share/vim/vim91" ]; then
  copy_tree "$EXT/usr/share/vim/vim91" "$FLAT/share/vim/vim91"
fi

if [ -d "$EXT/etc/terminfo" ]; then
  copy_tree "$EXT/etc/terminfo" "$FLAT/share/terminfo"
elif [ -d "$EXT/usr/share/terminfo" ]; then
  copy_tree "$EXT/usr/share/terminfo" "$FLAT/share/terminfo"
fi

cat > "$FLAT/bin/vim-kindle.sh" <<'WRAP'
#!/bin/sh
ROOT=/mnt/us/opt/vim
export VIMRUNTIME="$ROOT/share/vim/vim91"
export TERMINFO="$ROOT/share/terminfo"
export TERM="${TERM:-xterm}"
exec "$ROOT/lib/ld-musl-armhf.so.1" --library-path "$ROOT/lib" "$ROOT/bin/vim" "$@"
WRAP
chmod 0755 "$FLAT/bin/vim-kindle.sh"

if find "$FLAT" -type l | grep -q .; then
  echo "ERROR: symlinks remain (FAT will reject them)" >&2
  find "$FLAT" -type l
  exit 1
fi
tar -C "$FLAT" -czf "$OUT" .
echo "wrote $OUT ($(du -h "$OUT" | awk '{print $1}'))"
