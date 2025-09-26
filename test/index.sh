#!/usr/bin/env bash
set -euo pipefail

# Test script for local debugging of worker deployment
echo "🧪 Testing worker deployment locally..."
echo ""

# Test all three GCP authentication methods
test_gcp_auth_methods() {
    echo "🔐 Testing GCP Authentication Methods..."
    echo ""
    
    # Test 1: Service Account Key (gcp-key.json)
    echo "🔑 Test 1: Service Account Key Authentication"
    mkdir -p /tmp/test-gcp-key
    echo '{"type": "service_account", "test": "key"}' > /tmp/test-gcp-key/gcp-key.json
    cd /tmp/test-gcp-key
    /Users/jonyfq/git/udx/worker-deployment/src/lib/config.sh --output=test-deploy.yml
    mkdir -p src data
    echo "test file" > src/test.txt
    echo "Testing Service Account Key auth..."
    /Users/jonyfq/git/udx/worker-deployment/src/lib/deploy.sh --config=test-deploy.yml --dry-run
    echo ""
    
    # Test 2: Token Credentials (gcp-credentials.json)
    echo "🎫 Test 2: Token Credentials Authentication"
    mkdir -p /tmp/test-gcp-creds
    echo '{"type": "external_account", "token": "test-token"}' > /tmp/test-gcp-creds/gcp-credentials.json
    cd /tmp/test-gcp-creds
    /Users/jonyfq/git/udx/worker-deployment/src/lib/config.sh --output=test-deploy.yml
    mkdir -p src data
    echo "test file" > src/test.txt
    echo "Testing Token Credentials auth..."
    /Users/jonyfq/git/udx/worker-deployment/src/lib/deploy.sh --config=test-deploy.yml --dry-run
    echo ""
    
    # Test 3: Local gcloud (no credential files)
    echo "👤 Test 3: Local gcloud Authentication"
    mkdir -p /tmp/test-gcp-local
    cd /tmp/test-gcp-local
    /Users/jonyfq/git/udx/worker-deployment/src/lib/config.sh --output=test-deploy.yml
    mkdir -p src data
    echo "test file" > src/test.txt
    echo "Testing Local gcloud auth..."
    /Users/jonyfq/git/udx/worker-deployment/src/lib/deploy.sh --config=test-deploy.yml --dry-run
    echo ""
    
    echo "✅ All GCP authentication methods tested!"
    echo ""
}

# Run GCP auth tests
test_gcp_auth_methods

# Original comprehensive test (keep for backward compatibility)
echo "🔄 Running comprehensive integration test..."
mkdir -p /tmp/test-gcp
echo '{"test": "key"}' > /tmp/test-gcp/gcp-key.json

# Generate test config using the actual config module
echo "📝 Generating test config using worker-deploy-config..."
cd /tmp/test-gcp
# Remove any existing test config to avoid overwrite prompt
rm -f test-deploy.yml
/Users/jonyfq/git/udx/worker-deployment/src/lib/config.sh --output=test-deploy.yml

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
/Users/jonyfq/git/udx/worker-deployment/src/lib/deploy.sh --config=test-deploy.yml --dry-run

echo ""
echo "✅ Dry-run test completed!"

# Run the deployment script locally
echo ""
echo "🚀 Running actual deployment with local script..."
/Users/jonyfq/git/udx/worker-deployment/src/lib/deploy.sh --config=test-deploy.yml

echo ""
echo "✅ All tests completed successfully!"

# Cleanup test directories
echo "🧹 Cleaning up test directories..."
rm -rf /tmp/test-gcp-key /tmp/test-gcp-creds /tmp/test-gcp-local /tmp/test-gcp
echo "✅ Cleanup completed!"