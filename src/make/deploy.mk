.PHONY: run run-it

# These variables should be passed from deploy.sh
WORKER_IMAGE ?=
COMMAND ?=
VOLUMES ?=
ENV_VARS ?=
ARGS ?=

# Credential paths for auto-detection
GCP_KEY_PATH = $(PWD)/gcp-key.json
GCP_CREDS_PATH = $(PWD)/gcp-credentials.json
GCP_DEFAULT_PATH = ~/.config/gcloud

# Add credential volumes and environment variables if they exist
ifneq ($(wildcard $(GCP_KEY_PATH)),)
  GCP_VOLUME = -v $(GCP_KEY_PATH):/home/udx/gcp-key.json
  GCP_ENV = -e GCP_CREDS=/home/udx/gcp-key.json
  CRED_INFO = "Using GCP key file: $(GCP_KEY_PATH)"
else ifneq ($(wildcard $(GCP_CREDS_PATH)),)
  GCP_VOLUME = -v $(GCP_CREDS_PATH):/home/udx/gcp-creds.json
  GCP_ENV = -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/gcp-creds.json
  CRED_INFO = "Using GCP credentials file: $(GCP_CREDS_PATH)"
else
  GCP_VOLUME = -v $(GCP_DEFAULT_PATH):/root/.config/gcloud
  GCP_ENV = 
  CRED_INFO = "Using GCP credentials from default location"
endif

# Run target (non-interactive)
run:
	@echo "Running worker deployment..."
	@echo $(CRED_INFO)
	@echo "Image: $(WORKER_IMAGE)"
	@echo "Command: $(COMMAND)"
	docker run --rm \
		$(VOLUMES) \
		$(GCP_VOLUME) \
		$(ENV_VARS) \
		$(GCP_ENV) \
		$(WORKER_IMAGE) \
		$(COMMAND) \
		$(ARGS)

# Run interactive target
run-it:
	@echo "Running worker deployment (interactive)..."
	@echo $(CRED_INFO)
	@echo "Image: $(WORKER_IMAGE)"
	@echo "Command: $(COMMAND)"
	docker run --rm -it \
		$(VOLUMES) \
		$(GCP_VOLUME) \
		$(ENV_VARS) \
		$(GCP_ENV) \
		$(WORKER_IMAGE) \
		$(COMMAND) \
		$(ARGS)
