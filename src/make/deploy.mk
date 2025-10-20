.PHONY: run run-it

# These variables should be passed from deploy.sh
WORKER_IMAGE ?=
COMMAND ?=
VOLUMES ?=
ENV_VARS ?=
ARGS ?=
DRY_RUN ?= false

# Credential paths for auto-detection
GCP_KEY_PATH = $(PWD)/gcp-key.json
GCP_CREDS_PATH = $(PWD)/gcp-credentials.json
HOME_DIR = $(shell echo $$HOME)
GCP_DEFAULT_PATH = $(HOME_DIR)/.config/gcloud
GCP_ADC_PATH = $(HOME_DIR)/.config/gcloud/application_default_credentials.json

# Add credential volumes and environment variables if they exist
ifneq ($(wildcard $(GCP_KEY_PATH)),)
  GCP_VOLUME = -v $(GCP_KEY_PATH):/tmp/gcp-key.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-key.json
  CRED_INFO = "🔑 GCP Auth: Service Account Key ($(GCP_KEY_PATH))"
else ifneq ($(wildcard $(GCP_CREDS_PATH)),)
  GCP_VOLUME = -v $(GCP_CREDS_PATH):/tmp/gcp-creds.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-creds.json
  CRED_INFO = "🎫 GCP Auth: Token Credentials ($(GCP_CREDS_PATH))"
else ifneq ($(wildcard $(GCP_ADC_PATH)),)
  GCP_VOLUME = -v $(GCP_ADC_PATH):/tmp/application_default_credentials.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/application_default_credentials.json
  CRED_INFO = "👤 GCP Auth: Application Default Credentials (~/.config/gcloud/application_default_credentials.json)"
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
