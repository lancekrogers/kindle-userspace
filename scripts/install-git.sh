#!/bin/sh
# Run on the Kindle. Unpack a FAT-safe git tree. Do not extract Alpine here.
set -e
TAR="${1:-/mnt/us/git-kindlehf.tar.gz}"
DEST=/mnt/us/opt/git

if [ ! -f "$TAR" ]; then
  echo "missing $TAR" >&2
  exit 1
fi

mkdir -p "$DEST" /mnt/us/bin
tar -xzf "$TAR" -C "$DEST"
cp -f "$DEST/bin/git-kindle.sh" /mnt/us/bin/git
chmod 0755 /mnt/us/bin/git "$DEST/bin/git" "$DEST/lib/ld-musl-armhf.so.1"

HERE=$(dirname "$0")
if [ -f "$HERE/wrap-git-https.sh" ]; then
  sh "$HERE/wrap-git-https.sh"
elif [ -f /mnt/us/opt/git/libexec/git-core/git-remote-http.bin ] || [ -f /mnt/us/opt/git/libexec/git-core/git-remote-http ]; then
  :
fi

export PATH=/mnt/us/bin:$PATH
git --version
echo "installed /mnt/us/bin/git"
