#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 GCP Authentication Setup${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}✗ gcloud CLI is not installed${NC}"
    echo ""
    echo "Install gcloud CLI:"
    echo "  macOS: brew install google-cloud-sdk"
    echo "  Linux: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo -e "${GREEN}✓ gcloud CLI is installed${NC}"

# Check if user is authenticated
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo -e "${GREEN}✓ User authenticated: ${ACCOUNT}${NC}"
else
    echo -e "${YELLOW}⚠ User not authenticated${NC}"
    echo ""
    read -p "Run 'gcloud auth login' now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud auth login
        echo -e "${GREEN}✓ User authenticated${NC}"
    else
        echo -e "${RED}✗ Skipped user authentication${NC}"
    fi
fi

echo ""

# Check if application default credentials exist
ADC_PATH="$HOME/.config/gcloud/application_default_credentials.json"
if [ -f "$ADC_PATH" ]; then
    echo -e "${GREEN}✓ Application Default Credentials exist${NC}"
    
    # Try to get a token to verify they're valid
    if gcloud auth application-default print-access-token &>/dev/null; then
        echo -e "${GREEN}✓ Application Default Credentials are valid${NC}"
    else
        echo -e "${YELLOW}⚠ Application Default Credentials may be expired${NC}"
        echo ""
        read -p "Refresh Application Default Credentials? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gcloud auth application-default login
            echo -e "${GREEN}✓ Application Default Credentials refreshed${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ Application Default Credentials not found${NC}"
    echo ""
    echo "Application Default Credentials are needed for:"
    echo "  • Terraform"
    echo "  • Google Cloud SDKs (Python, Node.js, Go, etc.)"
    echo ""
    read -p "Set up Application Default Credentials now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud auth application-default login
        echo -e "${GREEN}✓ Application Default Credentials created${NC}"
    else
        echo -e "${RED}✗ Skipped Application Default Credentials setup${NC}"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Summary
if [ -f "$ADC_PATH" ] && gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    echo -e "${GREEN}✅ GCP Authentication is ready!${NC}"
    echo ""
    echo "You can now run containers with GCP access:"
    echo -e "  ${BLUE}worker-run --config=./deploy.yml${NC}"
    echo ""
    echo "The tool will automatically use your local gcloud credentials."
else
    echo -e "${YELLOW}⚠️  GCP Authentication is incomplete${NC}"
    echo ""
    echo "For full functionality, you need both:"
    echo "  1. User authentication (gcloud auth login)"
    echo "  2. Application Default Credentials (gcloud auth application-default login)"
    echo ""
    echo "Run this command again to complete setup:"
    echo -e "  ${BLUE}worker-auth${NC}"
fi

echo ""
