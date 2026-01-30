#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKER="$PKG_DIR/bin/worker"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

echo "Generating config..."
"$WORKER" config --output=deploy.yml --force

if [[ ! -f deploy.yml ]]; then
    echo "❌ deploy.yml not created"
    exit 1
fi

echo "✅ config test passed"
