#!/bin/sh
# Run on the Kindle. Unpack a FAT-safe vim tree.
set -e
TAR="${1:-/mnt/us/vim-kindlehf.tar.gz}"
DEST=/mnt/us/opt/vim

if [ ! -f "$TAR" ]; then
  echo "missing $TAR" >&2
  exit 1
fi

mkdir -p "$DEST" /mnt/us/bin
tar -xzf "$TAR" -C "$DEST"
cp -f "$DEST/bin/vim-kindle.sh" /mnt/us/bin/vim
cp -f "$DEST/bin/xxd" /mnt/us/bin/xxd
chmod 0755 /mnt/us/bin/vim /mnt/us/bin/xxd "$DEST/bin/vim"

export PATH=/mnt/us/bin:$PATH
vim --version | head -3
echo "installed /mnt/us/bin/vim"
