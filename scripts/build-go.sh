#!/usr/bin/env bash
# Static kindlehf binary: linux/arm GOARM=7, no CGO.
# Usage: ./scripts/build-go.sh ./out/myapp-kindlehf ./cmd/myapp
set -euo pipefail
if [ $# -lt 2 ]; then
  echo "usage: $0 OUT_PATH PKG" >&2
  exit 2
fi
out=$1
pkg=$2
CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 \
  go build -trimpath -ldflags '-s -w' -o "$out" "$pkg"
file "$out"
