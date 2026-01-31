#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKER="$PKG_DIR/bin/worker"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Dry-run repo generation..."
"$WORKER" gen repo --output-dir="$TMP_DIR" </dev/null >/dev/null || true

echo "Apply dockerfile generation..."
"$WORKER" gen dockerfile --output-dir="$TMP_DIR" --apply --force

if [[ ! -f "$TMP_DIR/Dockerfile" ]]; then
    echo "❌ Dockerfile not created"
    exit 1
fi

echo "✅ gen test passed"
