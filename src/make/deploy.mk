.PHONY: run run-it

# These variables should be passed from deploy.sh
WORKER_IMAGE ?=
COMMAND ?=
VOLUMES ?=
ENV_VARS ?=
ARGS ?=
DRY_RUN ?= false

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

# Add credential volumes and environment variables if they exist
# Priority: PWD first, then CONFIG_DIR, then home directory
ifneq ($(wildcard $(GCP_KEY_PATH_PWD)),)
  # Option 1: Service Account Key - for UDX workers (sets GCP_CREDS + GOOGLE_APPLICATION_CREDENTIALS)
  GCP_VOLUME = -v $(GCP_KEY_PATH_PWD):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_PWD))"
else ifneq ($(wildcard $(GCP_KEY_PATH_CONFIG)),)
  GCP_VOLUME = -v $(GCP_KEY_PATH_CONFIG):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-key.json
  CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_PWD)),)
  # Option 2: Token/ADC file - for Terraform/gcloud (sets only GOOGLE_APPLICATION_CREDENTIALS)
  GCP_VOLUME = -v $(GCP_CREDS_PATH_PWD):/home/udx/gcp-credentials.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  CRED_INFO = "🎫 GCP Auth: Token Credentials ($(GCP_CREDS_PATH_PWD))"
else ifneq ($(wildcard $(GCP_CREDS_PATH_CONFIG)),)
  GCP_VOLUME = -v $(GCP_CREDS_PATH_CONFIG):/home/udx/gcp-credentials.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-credentials.json
  CRED_INFO = "🎫 GCP Auth: Token Credentials ($(GCP_CREDS_PATH_CONFIG))"
else ifneq ($(wildcard $(GCP_DEFAULT_PATH)),)
  # Option 3: Local gcloud - mounts full config directory for gcloud CLI + Terraform
  GCP_VOLUME = -v $(GCP_DEFAULT_PATH):/root/.config/gcloud:ro
  GCP_ENV = -e CLOUDSDK_CONFIG=/root/.config/gcloud
  ifneq ($(wildcard $(GCP_ADC_PATH)),)
    GCP_ENV += -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json
  endif
  CRED_INFO = "👤 GCP Auth: Local gcloud config (~/.config/gcloud)"
else
  GCP_VOLUME = 
  GCP_ENV = 
  CRED_INFO = "⚠️  No GCP credentials found"
endif

# Run target (non-interactive)
run:
	@echo "Running worker deployment..."
	@echo $(CRED_INFO)
	@echo "Image: $(WORKER_IMAGE)"
	@echo "Command: $(COMMAND)"
ifeq ($(DRY_RUN),true)
	@echo ""
	@echo "🔍 DRY RUN - Would execute:"
	@echo "docker run --rm \\"
	@echo "    $(VOLUMES) \\"
	@echo "    $(GCP_VOLUME) \\"
	@echo "    $(ENV_VARS) \\"
	@echo "    $(GCP_ENV) \\"
	@echo "    $(WORKER_IMAGE) \\"
	@echo "    $(COMMAND) \\"
	@echo "    $(ARGS)"
	@echo ""
	@echo "✅ Dry run completed. Remove --dry-run to execute."
else
	docker run --rm \
		$(VOLUMES) \
		$(GCP_VOLUME) \
		$(ENV_VARS) \
		$(GCP_ENV) \
		$(WORKER_IMAGE) \
		$(COMMAND) \
		$(ARGS)
endif

# Run interactive target
run-it:
	@echo "Running worker deployment (interactive)..."
	@echo $(CRED_INFO)
	@echo "Image: $(WORKER_IMAGE)"
	@echo "Command: $(COMMAND)"
ifeq ($(DRY_RUN),true)
	@echo ""
	@echo "🔍 DRY RUN - Would execute (interactive):"
	@echo "docker run --rm -it \\"
	@echo "    $(VOLUMES) \\"
	@echo "    $(GCP_VOLUME) \\"
	@echo "    $(ENV_VARS) \\"
	@echo "    $(GCP_ENV) \\"
	@echo "    $(WORKER_IMAGE) \\"
	@echo "    $(COMMAND) \\"
	@echo "    $(ARGS)"
	@echo ""
	@echo "✅ Dry run completed. Remove --dry-run to execute."
else
	docker run --rm -it \
		$(VOLUMES) \
		$(GCP_VOLUME) \
		$(ENV_VARS) \
		$(GCP_ENV) \
		$(WORKER_IMAGE) \
		$(COMMAND) \
		$(ARGS)
endif
