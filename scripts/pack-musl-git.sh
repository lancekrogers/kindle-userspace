#!/usr/bin/env bash
# Build a FAT-safe musl/armv7 git tree (no symlinks, no chroot).
# Output: work/git-kindlehf.tar.gz
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
DL="$WORK/dl/git"
EXT="$WORK/extract/git"
FLAT="$WORK/flat/git"
OUT="$WORK/git-kindlehf.tar.gz"
ALPINE="${ALPINE_VERSION:-v3.21}"
BASE="https://dl-cdn.alpinelinux.org/alpine/${ALPINE}/main/armv7"

# Pin when you know versions; override with GIT_APKS="pkg-ver ..."
APKS=(
  git-2.47.3-r0
  git-init-template-2.47.3-r0
  pcre2-10.43-r0
  libexpat-2.8.2-r0
  libcurl-8.14.1-r2
  brotli-libs-1.1.0-r2
  c-ares-1.34.8-r0
  libidn2-2.3.7-r0
  libunistring-1.2-r0
  nghttp2-libs-1.69.0-r0
  libpsl-0.21.5-r3
  zstd-libs-1.5.6-r2
  libcrypto3-3.3.7-r0
  libssl3-3.3.7-r0
  ca-certificates-bundle-20260413-r0
  libgcc-14.2.0-r4
  musl-1.2.5-r11
)

mkdir -p "$DL" "$EXT" "$FLAT/bin" "$FLAT/lib" "$FLAT/libexec/git-core" "$FLAT/share/git-core" "$FLAT/ssl"
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

# musl loader + libc soname (same bytes; FAT has no symlinks)
LOADER=$(find "$EXT" -name 'ld-musl-armhf.so.1' | head -1)
test -n "$LOADER"
cp -f "$LOADER" "$FLAT/lib/ld-musl-armhf.so.1"
cp -f "$LOADER" "$FLAT/lib/libc.musl-armv7.so.1"

copy_so "$EXT/usr/lib/libpcre2-8.so.0" libpcre2-8.so.0
copy_so "$EXT/usr/lib/libz.so.1" libz.so.1
copy_so "$EXT/usr/lib/libcurl.so.4" libcurl.so.4
copy_so "$EXT/usr/lib/libexpat.so.1" libexpat.so.1
copy_so "$EXT/usr/lib/libbrotlidec.so.1" libbrotlidec.so.1
copy_so "$EXT/usr/lib/libbrotlicommon.so.1" libbrotlicommon.so.1
copy_so "$EXT/usr/lib/libcares.so.2" libcares.so.2
copy_so "$EXT/usr/lib/libidn2.so.0" libidn2.so.0
copy_so "$EXT/usr/lib/libunistring.so.5" libunistring.so.5
copy_so "$EXT/usr/lib/libnghttp2.so.14" libnghttp2.so.14
copy_so "$EXT/usr/lib/libpsl.so.5" libpsl.so.5
copy_so "$EXT/usr/lib/libzstd.so.1" libzstd.so.1
copy_so "$EXT/usr/lib/libssl.so.3" libssl.so.3
copy_so "$EXT/usr/lib/libcrypto.so.3" libcrypto.so.3
copy_so "$EXT/usr/lib/libgcc_s.so.1" libgcc_s.so.1

cp -f "$EXT/usr/bin/git" "$FLAT/bin/git"
chmod 0755 "$FLAT/bin/git"
find "$EXT/usr/libexec/git-core" -type f -exec cp -f {} "$FLAT/libexec/git-core/" \;
if [ -f "$FLAT/libexec/git-core/git-remote-http" ]; then
  cp -f "$FLAT/libexec/git-core/git-remote-http" "$FLAT/libexec/git-core/git-remote-https"
fi
if [ -d "$EXT/usr/share/git-core/templates" ]; then
  cp -R "$EXT/usr/share/git-core/templates" "$FLAT/share/git-core/"
fi
python3 - <<PY
import os, shutil
from pathlib import Path
src = Path("$EXT")
dest = Path("$FLAT/ssl/cert.pem")
for c in (src/"etc/ssl/certs/ca-certificates.crt", src/"etc/ssl/cert.pem"):
    if c.exists() or c.is_symlink():
        real = Path(os.path.realpath(c))
        if real.is_file():
            shutil.copy(real, dest)
            print("cert", real)
            break
PY

cat > "$FLAT/bin/git-kindle.sh" <<'WRAP'
#!/bin/sh
ROOT=/mnt/us/opt/git
export GIT_EXEC_PATH="$ROOT/libexec/git-core"
export GIT_TEMPLATE_DIR="$ROOT/share/git-core/templates"
export SSL_CERT_FILE="$ROOT/ssl/cert.pem"
export GIT_SSL_CAINFO="$ROOT/ssl/cert.pem"
exec "$ROOT/lib/ld-musl-armhf.so.1" --library-path "$ROOT/lib" "$ROOT/bin/git" "$@"
WRAP
chmod 0755 "$FLAT/bin/git-kindle.sh"

if find "$FLAT" -type l | grep -q .; then
  echo "ERROR: symlinks remain (FAT will reject them)" >&2
  find "$FLAT" -type l
  exit 1
fi
tar -C "$FLAT" -czf "$OUT" .
echo "wrote $OUT ($(du -h "$OUT" | awk '{print $1}'))"
