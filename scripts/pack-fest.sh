#!/usr/bin/env bash
# Cross-compile public camp + fest for kindlehf. Does not vendor source.
# Output: work/fest-kindlehf.tar.gz
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
FLAT="$WORK/flat/fest"
OUT="$WORK/fest-kindlehf.tar.gz"
FEST_VERSION="${FEST_VERSION:-v0.5.1}"
CAMP_VERSION="${CAMP_VERSION:-v0.4.0}"

mkdir -p "$FLAT/bin"
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=arm
export GOARM=7
export GOBIN="$FLAT/bin"

build_mod() {
  local name="$1" module="$2" dir="${3:-}" ver="$4"
  echo "build $name"
  if [ -n "$dir" ]; then
    if [ ! -d "$dir" ]; then
      echo "missing checkout $dir" >&2
      exit 1
    fi
    (cd "$dir" && go build -trimpath -ldflags '-s -w' -o "$GOBIN/$name" "./cmd/$name")
  else
    go install -trimpath -ldflags '-s -w' "${module}@${ver}"
  fi
  test -f "$GOBIN/$name"
  file "$GOBIN/$name"
}

build_mod fest github.com/Obedience-Corp/fest/cmd/fest "${FEST_DIR:-}" "$FEST_VERSION"
build_mod camp github.com/Obedience-Corp/camp/cmd/camp "${CAMP_DIR:-}" "$CAMP_VERSION"

cp -f "$ROOT/scripts/ash-camp.sh" "$FLAT/bin/ash-camp.sh"
cp -f "$ROOT/scripts/install-fest.sh" "$FLAT/bin/install-fest.sh"
chmod 0755 "$FLAT/bin/fest" "$FLAT/bin/camp" "$FLAT/bin/ash-camp.sh" "$FLAT/bin/install-fest.sh"

if find "$FLAT" -type l | grep -q .; then
  echo "ERROR: symlinks remain (FAT will reject them)" >&2
  find "$FLAT" -type l
  exit 1
fi
tar -C "$FLAT" -czf "$OUT" .
echo "wrote $OUT ($(du -h "$OUT" | awk '{print $1}'))"
echo "fest $FEST_VERSION  camp $CAMP_VERSION"
