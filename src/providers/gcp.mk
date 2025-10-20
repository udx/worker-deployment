# GCP Provider - Credential Detection and Mounting
# This module handles GCP authentication for containers

# Credential paths for auto-detection
# Check both current directory and config file directory
CONFIG_DIR ?= $(PWD)
GCP_KEY_PATH_PWD = $(PWD)/gcp-key.json
GCP_KEY_PATH_CONFIG = $(CONFIG_DIR)/gcp-key.json
GCP_CREDS_PATH_PWD = $(PWD)/gcp-credentials.json
GCP_CREDS_PATH_CONFIG = $(CONFIG_DIR)/gcp-credentials.json
HOME_DIR = $(shell echo $$HOME)
GCP_DEFAULT_PATH = $(HOME_DIR)/.config/gcloud
GCP_ADC_PATH = $(HOME_DIR)/.config/gcloud/application_default_credentials.json

# Detect and configure GCP credentials
# Priority: PWD first, then CONFIG_DIR, then home directory
ifneq ($(wildcard $(GCP_KEY_PATH_PWD)),)
  # Option 1: Service Account Key - for UDX workers (sets GCP_CREDS + GOOGLE_APPLICATION_CREDENTIALS)
  GCP_VOLUME = -v $(GCP_KEY_PATH_PWD):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_PWD))"
else ifneq ($(wildcard $(GCP_KEY_PATH_CONFIG)),)
  GCP_VOLUME = -v $(GCP_KEY_PATH_CONFIG):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  GCP_CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_PWD)),)
  # Option 2: Token/ADC file - for Terraform/gcloud (sets only GOOGLE_APPLICATION_CREDENTIALS)
  GCP_VOLUME = -v $(GCP_CREDS_PATH_PWD):/home/udx/gcp-credentials.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Token Credentials ($(GCP_CREDS_PATH_PWD))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_CONFIG)),)
  GCP_VOLUME = -v $(GCP_CREDS_PATH_CONFIG):/home/udx/gcp-credentials.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  GCP_CRED_INFO = "🎫 GCP Auth: Token Credentials ($(GCP_CREDS_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_DEFAULT_PATH)),)
  # Option 3: Local gcloud - mounts full config directory for gcloud CLI + Terraform
  GCP_VOLUME = -v $(GCP_DEFAULT_PATH):/root/.config/gcloud:ro
  GCP_ENV = -e CLOUDSDK_CONFIG=/root/.config/gcloud
  ifneq ($(wildcard $(GCP_ADC_PATH)),)
    GCP_ENV += -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json
  endif
  GCP_CRED_INFO = "👤 GCP Auth: Local gcloud config (~/.config/gcloud)"
else
  GCP_VOLUME = 
  GCP_ENV = 
  GCP_CRED_INFO = "⚠️  No GCP credentials found"
endif
