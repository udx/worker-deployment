#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKER="$PKG_DIR/bin/worker"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Testing dry-run with gcp-key.json..."
mkdir -p "$TMP_DIR/key-test"
echo '{"type": "service_account", "test": "key"}' > "$TMP_DIR/key-test/gcp-key.json"
cat > "$TMP_DIR/key-test/deploy.yml" <<EOF
---
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "usabilitydynamics/udx-worker:latest"
  command: "echo 'Testing dry-run'"
  volumes:
    - "./:/workspace"
EOF
cd "$TMP_DIR/key-test"
"$WORKER" run --config=deploy.yml --dry-run

echo "Testing --network flag..."
mkdir -p "$TMP_DIR/network-test"
cat > "$TMP_DIR/network-test/deploy.yml" <<EOF
---
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "usabilitydynamics/udx-worker:latest"
  command: "echo 'Testing network configuration'"
  network: "host"
  volumes:
    - "./:/workspace"
EOF
if "$WORKER" run --config="$TMP_DIR/network-test/deploy.yml" --dry-run 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g' | grep -q -- "--network host"; then
    echo "✅ network flag present"
else
    echo "❌ network flag missing"
    exit 1
fi

echo "Testing --name flag..."
mkdir -p "$TMP_DIR/name-test"
cat > "$TMP_DIR/name-test/deploy.yml" <<EOF
---
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "usabilitydynamics/udx-worker:latest"
  command: "echo 'Testing container name configuration'"
  container_name: "test-worker-123"
  volumes:
    - "./:/workspace"
EOF
if "$WORKER" run --config="$TMP_DIR/name-test/deploy.yml" --dry-run 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g' | grep -q -- "--name test-worker-123"; then
    echo "✅ container name flag present"
else
    echo "❌ container name flag missing"
    exit 1
fi

if [[ "${RUN_DOCKER_TESTS:-}" == "1" ]]; then
    echo "Running actual docker test..."
    "$WORKER" run --config="$TMP_DIR/key-test/deploy.yml"
else
    echo "Skipping docker run; set RUN_DOCKER_TESTS=1 to enable."
fi

echo "✅ run test passed"
