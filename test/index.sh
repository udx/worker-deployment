#!/usr/bin/env bash
set -euo pipefail

# Test script for local debugging of worker deployment
echo "🧪 Testing worker deployment locally..."
echo ""

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_SCRIPT="$PKG_DIR/bin/worker"
DEPLOY_SCRIPT="$PKG_DIR/bin/worker"

# Test all three GCP authentication methods
test_gcp_auth_methods() {
    echo "🔐 Testing GCP Authentication Methods..."
    echo ""
    
    # Test 1: Service Account Key (gcp-key.json)
    echo "🔑 Test 1: Service Account Key Authentication"
    mkdir -p /tmp/test-gcp-key
    echo '{"type": "service_account", "test": "key"}' > /tmp/test-gcp-key/gcp-key.json
    cd /tmp/test-gcp-key
    rm -f test-deploy.yml
    "$CONFIG_SCRIPT" config --output=test-deploy.yml --force
    mkdir -p src data
    echo "test file" > src/test.txt
    echo "Testing Service Account Key auth..."
    "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run
    echo ""
    
    # Test 2: Token Credentials (gcp-credentials.json)
    echo "🎫 Test 2: Token Credentials Authentication"
    mkdir -p /tmp/test-gcp-creds
    echo '{"type": "external_account", "token": "test-token"}' > /tmp/test-gcp-creds/gcp-credentials.json
    cd /tmp/test-gcp-creds
    rm -f test-deploy.yml
    "$CONFIG_SCRIPT" config --output=test-deploy.yml --force
    mkdir -p src data
    echo "test file" > src/test.txt
    echo "Testing Token Credentials auth..."
    "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run
    echo ""
    
    # Test 3: Local gcloud (no credential files)
    echo "👤 Test 3: Local gcloud Authentication"
    mkdir -p /tmp/test-gcp-local
    cd /tmp/test-gcp-local
    rm -f test-deploy.yml
    "$CONFIG_SCRIPT" config --output=test-deploy.yml --force
    mkdir -p src data
    echo "test file" > src/test.txt
    echo "Testing Local gcloud auth..."
    "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run
    echo ""
    
    echo "✅ All GCP authentication methods tested!"
    echo ""
}

# Run GCP auth tests
test_gcp_auth_methods

# Test network configuration
test_network_config() {
    echo "🌐 Testing Network Configuration..."
    echo ""
    
    mkdir -p /tmp/test-network
    cd /tmp/test-network
    
    # Create a test config with network setting
    cat > test-deploy.yml <<EOF
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
    
    echo "Testing network configuration with --dry-run..."
    "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run
    echo ""
    
    # Verify the output contains --network flag (strip ANSI codes if present)
    if "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g' | grep -q -- "--network host"; then
        echo "✅ Network configuration test passed!"
    else
        echo "❌ Network configuration test failed - --network flag not found in output"
        exit 1
    fi
    
    echo ""
}

# Run network test
test_network_config

# Test container name configuration
test_container_name_config() {
    echo "🏷️  Testing Container Name Configuration..."
    echo ""
    
    mkdir -p /tmp/test-container-name
    cd /tmp/test-container-name
    
    # Create a test config with container_name setting
    cat > test-deploy.yml <<EOF
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
    
    echo "Testing container_name configuration with --dry-run..."
    "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run
    echo ""
    
    # Verify the output contains --name flag (strip ANSI codes if present)
    if "$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g' | grep -q -- "--name test-worker-123"; then
        echo "✅ Container name configuration test passed!"
    else
        echo "❌ Container name configuration test failed - --name flag not found in output"
        exit 1
    fi
    
    echo ""
}

# Run container name test
test_container_name_config

# Original comprehensive test (keep for backward compatibility)
echo "🔄 Running comprehensive integration test..."
mkdir -p /tmp/test-gcp
echo '{"test": "key"}' > /tmp/test-gcp/gcp-key.json

# Generate test config using the actual config module
echo "📝 Generating test config using worker-config..."
cd /tmp/test-gcp
# Remove any existing test config to avoid overwrite prompt
rm -f test-deploy.yml
"$CONFIG_SCRIPT" config --output=test-deploy.yml --force

# Create the default directories that the config expects
echo "📁 Creating default directories for testing..."
mkdir -p /tmp/test-gcp/src /tmp/test-gcp/data
echo "test source code" > /tmp/test-gcp/src/example.txt
echo "test data file" > /tmp/test-gcp/data/sample.txt

echo "✅ Created test config at test-deploy.yml"
echo "✅ Created test GCP key at gcp-key.json"
echo "✅ Created test directories: src/ and data/"

# Test dry-run first
echo "🔍 Testing dry-run functionality..."
"$DEPLOY_SCRIPT" run --config=test-deploy.yml --dry-run

echo ""
echo "✅ Dry-run test completed!"

# Run the deployment script locally (optional)
echo ""
if [[ "${RUN_DOCKER_TESTS:-}" == "1" ]]; then
    echo "🚀 Running actual deployment with local script..."
    "$DEPLOY_SCRIPT" run --config=test-deploy.yml
    echo ""
    echo "✅ All tests completed successfully!"
else
    echo "⏭️  Skipping actual docker run. Set RUN_DOCKER_TESTS=1 to enable."
    echo "✅ Dry-run tests completed successfully!"
fi

# Cleanup test directories
echo "🧹 Cleaning up test directories..."
rm -rf /tmp/test-gcp-key /tmp/test-gcp-creds /tmp/test-gcp-local /tmp/test-gcp /tmp/test-network /tmp/test-container-name
echo "✅ Cleanup completed!"
