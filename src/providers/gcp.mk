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
GCP_SA_EMAIL ?=

# Default file paths
GCP_KEY_PATH_PWD = $(PWD)/gcp-key.json
GCP_KEY_PATH_CONFIG = $(CONFIG_DIR)/gcp-key.json
GCP_CREDS_PATH_PWD = $(PWD)/gcp-credentials.json
GCP_CREDS_PATH_CONFIG = $(CONFIG_DIR)/gcp-credentials.json

# Detect and configure GCP credentials
# Priority: 1) Config-specified paths, 2) Default files, 3) Impersonation
ifneq ($(GCP_SA_KEY_PATH),)
  # Config-specified key path
  GCP_VOLUME = -v $(GCP_SA_KEY_PATH):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key (config: $(GCP_SA_KEY_PATH))"
else ifneq ($(GCP_SA_TOKEN_PATH),)
  # Config-specified token path
  GCP_VOLUME = -v $(GCP_SA_TOKEN_PATH):/home/udx/gcp-credentials.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-credentials.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Token (config: $(GCP_SA_TOKEN_PATH))"
else ifneq ($(wildcard $(GCP_KEY_PATH_PWD)),)
  # Default: gcp-key.json in PWD
  GCP_VOLUME = -v $(GCP_KEY_PATH_PWD):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_PWD))"
else ifneq ($(wildcard $(GCP_KEY_PATH_CONFIG)),)
  # Default: gcp-key.json in config dir
  GCP_VOLUME = -v $(GCP_KEY_PATH_CONFIG):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_PWD)),)
  # Default: gcp-credentials.json in PWD
  GCP_VOLUME = -v $(GCP_CREDS_PATH_PWD):/home/udx/gcp-credentials.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-credentials.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Workload Identity Token ($(GCP_CREDS_PATH_PWD))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_CONFIG)),)
  # Default: gcp-credentials.json in config dir
  GCP_VOLUME = -v $(GCP_CREDS_PATH_CONFIG):/home/udx/gcp-credentials.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-credentials.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Workload Identity Token ($(GCP_CREDS_PATH_CONFIG))"
else ifneq ($(GCP_SA_EMAIL),)
  # Impersonation: use host gcloud with impersonation
  HOME_DIR = $(shell echo $$HOME)
  GCP_VOLUME = -v $(HOME_DIR)/.config/gcloud:/root/.config/gcloud:ro
  GCP_ENV = -e CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT=$(GCP_SA_EMAIL)
  GCP_ENV += -e CLOUDSDK_CONFIG=/root/.config/gcloud
  GCP_CRED_INFO = "👤 GCP Auth: Impersonating $(GCP_SA_EMAIL)"
else
  GCP_VOLUME = 
  GCP_ENV = 
  GCP_CRED_INFO = "⚠️  No GCP credentials found"
endif
