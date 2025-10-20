# GCP Provider - Credential Detection and Mounting
# This module handles GCP authentication for containers
#
# Authentication Strategy:
# - Service Account Key: Works for both local dev and CI/CD
#   Sets both GCP_CREDS (for UDX workers) and GOOGLE_APPLICATION_CREDENTIALS (standard)
#
# Note: Local user credentials (ADC) are not supported due to UID/GID mismatch issues
# when the container runs as a non-root user. Use service account keys instead.

# Credential paths for auto-detection
# Check both current directory and config file directory
CONFIG_DIR ?= $(PWD)
GCP_KEY_PATH_PWD = $(PWD)/gcp-key.json
GCP_KEY_PATH_CONFIG = $(CONFIG_DIR)/gcp-key.json
GCP_CREDS_PATH_PWD = $(PWD)/gcp-credentials.json
GCP_CREDS_PATH_CONFIG = $(CONFIG_DIR)/gcp-credentials.json

# Detect and configure GCP credentials
# Supports both naming conventions
ifneq ($(wildcard $(GCP_KEY_PATH_PWD)),)
  # gcp-key.json - Local development service account key
  GCP_VOLUME = -v $(GCP_KEY_PATH_PWD):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_PWD))"
else ifneq ($(wildcard $(GCP_KEY_PATH_CONFIG)),)
  GCP_VOLUME = -v $(GCP_KEY_PATH_CONFIG):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_PWD)),)
  # gcp-credentials.json - GitHub Actions Workload Identity token
  GCP_VOLUME = -v $(GCP_CREDS_PATH_PWD):/home/udx/gcp-credentials.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-credentials.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Workload Identity Token ($(GCP_CREDS_PATH_PWD))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_CONFIG)),)
  GCP_VOLUME = -v $(GCP_CREDS_PATH_CONFIG):/home/udx/gcp-credentials.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-credentials.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Workload Identity Token ($(GCP_CREDS_PATH_CONFIG))"
else
  GCP_VOLUME = 
  GCP_ENV = 
  GCP_CRED_INFO = "⚠️  No GCP credentials found. Create gcp-key.json or gcp-credentials.json."
endif
