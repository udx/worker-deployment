#!/usr/bin/env bash
set -euo pipefail

# Test script for local debugging of worker deployment
echo "Testing worker deployment locally..."

# Create a fake GCP key file for testing
mkdir -p /tmp/test-gcp
echo '{"test": "key"}' > /tmp/test-gcp/gcp-key.json

# Create test config with volumes
cat > /tmp/test-deploy.yml << 'EOF'
---
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  # Test image
  image: "alpine:latest"

  # Environment variables to pass to container
  env:
    TEST_ENV: "debug-test"
    DEBUG: "true"

  # Volume mappings (source:destination format)
  volumes:
    - "/tmp/test-volume1:/test1"
    - "/tmp/test-volume2:/test2"

  # Simple test command
  command: "echo 'Testing volumes and env vars'"

  # Additional arguments
  args:
    - "arg1"
    - "arg2"
EOF

# Create test volumes
mkdir -p /tmp/test-volume1 /tmp/test-volume2
echo "test1 content" > /tmp/test-volume1/test.txt
echo "test2 content" > /tmp/test-volume2/test.txt

echo "Created test config at /tmp/test-deploy.yml"
echo "Created test GCP key at /tmp/test-gcp/gcp-key.json"
echo "Created test volumes at /tmp/test-volume1 and /tmp/test-volume2"

# Run the deployment script locally
echo ""
echo "Running deployment with local script..."
cd /tmp/test-gcp
/Users/jonyfq/git/udx/worker-deployment/src/lib/deploy.sh --config=/tmp/test-deploy.yml

echo ""
echo "Test completed!"