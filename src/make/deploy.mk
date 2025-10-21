.PHONY: run run-it

# These variables should be passed from deploy.sh
WORKER_IMAGE ?=
COMMAND ?=
VOLUMES ?=
ENV_VARS ?=
ARGS ?=
DRY_RUN ?= false

# Include cloud provider modules
CONFIG_DIR ?= $(PWD)
include $(dir $(lastword $(MAKEFILE_LIST)))/../providers/gcp.mk
# include $(dir $(lastword $(MAKEFILE_LIST)))/../providers/aws.mk
# include $(dir $(lastword $(MAKEFILE_LIST)))/../providers/azure.mk

# Combine all provider volumes and env vars
CLOUD_VOLUMES = $(GCP_VOLUME) $(AWS_VOLUME) $(AZURE_VOLUME)
CLOUD_ENV = $(GCP_ENV) $(AWS_ENV) $(AZURE_ENV)

# Build credential info message
CRED_INFO_PARTS = 
ifneq ($(GCP_CRED_INFO),)
  CRED_INFO_PARTS += $(GCP_CRED_INFO)
endif
ifneq ($(AWS_CRED_INFO),)
  CRED_INFO_PARTS += $(AWS_CRED_INFO)
endif
ifneq ($(AZURE_CRED_INFO),)
  CRED_INFO_PARTS += $(AZURE_CRED_INFO)
endif

ifeq ($(CRED_INFO_PARTS),)
  CRED_INFO = "⚠️  No cloud credentials found"
else
  CRED_INFO = $(CRED_INFO_PARTS)
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
	@echo "    $(CLOUD_VOLUMES) \\"
	@echo "    $(ENV_VARS) \\"
	@echo "    $(CLOUD_ENV) \\"
	@echo "    $(WORKER_IMAGE) \\"
	@echo "    $(COMMAND) \\"
	@echo "    $(ARGS)"
	@echo ""
	@echo "✅ Dry run completed. Remove --dry-run to execute."
else
	@docker run --rm \
		$(VOLUMES) \
		$(CLOUD_VOLUMES) \
		$(ENV_VARS) \
		$(CLOUD_ENV) \
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
	@echo "    $(CLOUD_VOLUMES) \\"
	@echo "    $(ENV_VARS) \\"
	@echo "    $(CLOUD_ENV) \\"
	@echo "    $(WORKER_IMAGE) \\"
	@echo "    $(COMMAND) \\"
	@echo "    $(ARGS)"
	@echo ""
	@echo "✅ Dry run completed. Remove --dry-run to execute."
else
	@docker run --rm -it \
		$(VOLUMES) \
		$(CLOUD_VOLUMES) \
		$(ENV_VARS) \
		$(CLOUD_ENV) \
		$(WORKER_IMAGE) \
		$(COMMAND) \
		$(ARGS)
endif
