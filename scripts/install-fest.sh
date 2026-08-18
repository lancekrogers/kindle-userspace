#!/bin/sh
# Run on the Kindle. Unpack camp + fest into /mnt/us/bin and install ash hooks.
# Requires git on PATH if you want fest init to talk to GitHub.
set -e
TAR="${1:-/mnt/us/fest-kindlehf.tar.gz}"
DEST=/mnt/us/opt/fest
HERE=$(dirname "$0")

mkdir -p "$DEST" /mnt/us/bin

if [ -f "$HERE/fest" ] && [ -f "$HERE/camp" ]; then
  SRC="$HERE"
elif [ -f "$TAR" ]; then
  tar -xzf "$TAR" -C "$DEST"
  SRC="$DEST/bin"
else
  echo "missing $TAR (or run this from an unpacked pack)" >&2
  exit 1
fi

cp -f "$SRC/fest" /mnt/us/bin/fest
cp -f "$SRC/camp" /mnt/us/bin/camp
if [ -f "$SRC/ash-camp.sh" ]; then
  cp -f "$SRC/ash-camp.sh" /mnt/us/.ash_camp
else
  echo "missing ash-camp.sh next to fest" >&2
  exit 1
fi
chmod 0755 /mnt/us/bin/fest /mnt/us/bin/camp /mnt/us/.ash_camp

if [ ! -f /mnt/us/.profile ]; then
  printf '%s\n' '. /mnt/us/.ash_camp' 'export ENV=/mnt/us/.ash_camp' > /mnt/us/.profile
elif ! grep -q '\.ash_camp' /mnt/us/.profile 2>/dev/null; then
  printf '\n%s\n' '. /mnt/us/.ash_camp' 'export ENV=/mnt/us/.ash_camp' >> /mnt/us/.profile
fi

export PATH=/mnt/us/bin:$PATH
fest version
camp version
echo "installed /mnt/us/bin/fest and /mnt/us/bin/camp"
echo "hooks: /mnt/us/.ash_camp  (source from .profile)"
