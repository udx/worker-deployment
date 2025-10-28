# GCP Provider - Credential Detection and Mounting
# This module handles GCP authentication for containers
#
# Authentication Strategy:
# - Service Account Key: Works for both local dev and CI/CD
#   Sets both GCP_CREDS (for UDX workers) and GOOGLE_APPLICATION_CREDENTIALS (standard)
#
# Note: Local user credentials (ADC) are not supported due to UID/GID mismatch issues
# when the container runs as a non-root user. Use service account keys instead.

# Credential paths - config-specified or defaults
CONFIG_DIR ?= $(PWD)
GCP_SA_KEY_PATH ?=
GCP_SA_TOKEN_PATH ?=
GCP_IMPERSONATE_CREDS_FILE ?=
GCP_IMPERSONATE_ACCESS_TOKEN ?=

# Default file paths
GCP_KEY_PATH_PWD = $(PWD)/gcp-key.json
GCP_KEY_PATH_CONFIG = $(CONFIG_DIR)/gcp-key.json
GCP_CREDS_PATH_PWD = $(PWD)/gcp-credentials.json
GCP_CREDS_PATH_CONFIG = $(CONFIG_DIR)/gcp-credentials.json

# Container paths
GCP_KEY_PATH_CONTAINER = /home/udx/gcp-key.json
GCP_CREDS_PATH_CONTAINER = /home/udx/gcp-credentials.json
GCP_IMPERSONATE_CREDS_FILE_CONTAINER = /home/udx/gcp-impersonate.json

# Detect and configure GCP credentials
# Priority: 1) Config-specified paths, 2) Default files, 3) Impersonation
ifneq ($(GCP_SA_KEY_PATH),)
  # Config-specified key path
  GCP_VOLUME = -v $(GCP_SA_KEY_PATH):$(GCP_KEY_PATH_CONTAINER)
  GCP_ENV = -e GCP_CREDS=$(GCP_KEY_PATH_CONTAINER)
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key (config: $(GCP_SA_KEY_PATH))"
else ifneq ($(GCP_SA_TOKEN_PATH),)
  # Config-specified token path
  GCP_VOLUME = -v $(GCP_SA_TOKEN_PATH):$(GCP_CREDS_PATH_CONTAINER)
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=$(GCP_CREDS_PATH_CONTAINER)
  GCP_CRED_INFO = "🎫 GCP Auth: Token (config: $(GCP_SA_TOKEN_PATH))"
else ifneq ($(wildcard $(GCP_KEY_PATH_PWD)),)
  # Default: gcp-key.json in PWD
  GCP_VOLUME = -v $(GCP_KEY_PATH_PWD):$(GCP_KEY_PATH_CONTAINER)
  GCP_ENV = -e GCP_CREDS=$(GCP_KEY_PATH_CONTAINER)
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_PWD))"
else ifneq ($(wildcard $(GCP_KEY_PATH_CONFIG)),)
  # Default: gcp-key.json in config dir
  GCP_VOLUME = -v $(GCP_KEY_PATH_CONFIG):$(GCP_KEY_PATH_CONTAINER)
  GCP_ENV = -e GCP_CREDS=$(GCP_KEY_PATH_CONTAINER)
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_PWD)),)
  # Default: gcp-credentials.json in PWD
  GCP_VOLUME = -v $(GCP_CREDS_PATH_PWD):$(GCP_CREDS_PATH_CONTAINER)
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=$(GCP_CREDS_PATH_CONTAINER)
  GCP_CRED_INFO = "🎫 GCP Auth: Workload Identity Token ($(GCP_CREDS_PATH_PWD))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_CONFIG)),)
  # Default: gcp-credentials.json in config dir
  GCP_VOLUME = -v $(GCP_CREDS_PATH_CONFIG):$(GCP_CREDS_PATH_CONTAINER)
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=$(GCP_CREDS_PATH_CONTAINER)
  GCP_CRED_INFO = "🎫 GCP Auth: Workload Identity Token ($(GCP_CREDS_PATH_CONFIG))"
else ifneq ($(GCP_IMPERSONATE_CREDS_FILE),)
  # Impersonation: ADC credentials file + access token
  # Credentials file works with Terraform/SDKs, access token works with gcloud
  GCP_VOLUME = -v $(GCP_IMPERSONATE_CREDS_FILE):$(GCP_IMPERSONATE_CREDS_FILE_CONTAINER):ro
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=$(GCP_IMPERSONATE_CREDS_FILE_CONTAINER) -e CLOUDSDK_AUTH_ACCESS_TOKEN=$(GCP_IMPERSONATE_ACCESS_TOKEN)
  GCP_CRED_INFO = "👤 GCP Auth: Impersonated Service Account (Terraform/SDK/gcloud compatible)"
else
  GCP_VOLUME = 
  GCP_ENV = 
  GCP_CRED_INFO = "⚠️  No GCP credentials found"
endif
