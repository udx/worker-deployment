#!/bin/bash
set -e

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/../../." && pwd)"
cd "$ROOT_DIR"

if [ ! -f "package.json" ]; then
  printf "Error: package.json not found in %s\n" "$ROOT_DIR" >&2
  exit 1
fi

# Get dist directory from package.json
DIST_DIR=$(node -e "console.log(require('$ROOT_DIR/package.json').config.dist)")

OUT_DIR="$ROOT_DIR/$DIST_DIR"
mkdir -p "$OUT_DIR"

# Keep dist clean so the generated tarball is easy to find.
rm -f "$OUT_DIR"/*.tgz

printf "Packing npm tarball into %s\n" "$OUT_DIR"
npm pack --pack-destination "$OUT_DIR"

printf "Copying package.json to %s\n" "$OUT_DIR"
cp "$ROOT_DIR/package.json" "$OUT_DIR"
