# Worker Deploy

**Run any Docker container with automatic cloud authentication.**

Simple YAML configuration + automatic GCP credential detection = zero-config deployments.

## Why Use This?

- ✅ **Zero Config** - Automatically detects and uses your existing gcloud credentials
- ✅ **Works Everywhere** - Local dev, CI/CD, production
- ✅ **Any Docker Image** - Python, Terraform, Node.js, your custom images
- ✅ **Secure** - Read-only mounts, no credential copying

## Installation

```bash
npm install -g @udx/worker-deployment
```

## Quick Start

```bash
# Install
npm install -g @udx/worker-deployment

# Generate config
worker-config

# Edit deploy.yml, then run
worker-run
```

**That's it!** The tool automatically detects your GCP credentials.

## GCP Authentication

The tool uses **service account keys** for authentication. This works everywhere: local development, CI/CD, and production.

### For Local Development

Create a service account key and save it as `gcp-key.json`:

```bash
# 1. Create a service account (one-time)
gcloud iam service-accounts create dev-worker \
  --display-name="Local Development Worker"

# 2. Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:dev-worker@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# 3. Create and download key
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=dev-worker@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. Run your container
worker-run
```

**Security tip:** Add `gcp-key.json` to `.gitignore` and delete the key from Google Cloud when done.

### For GitHub Actions (Workload Identity)

Use keyless authentication with Workload Identity Federation:

```yaml
- name: Authenticate to Google Cloud
  id: auth
  uses: google-github-actions/auth@v3
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

- name: Deploy
  run: |
    # Copy the generated credentials to gcp-credentials.json
    cp ${{ steps.auth.outputs.credentials_file_path }} gcp-credentials.json
    worker-run
```

**File naming:**
- `gcp-key.json` → Local development (service account key)
- `gcp-credentials.json` → GitHub Actions (Workload Identity token)

### Why Service Account Keys?

**UID/GID Mismatch Issue:** Mounting local user credentials (`~/.config/gcloud`) doesn't work when the container runs as a non-root user (UID 500) because the host files are owned by a different UID (e.g., 501). This causes permission denied errors.

**Service account keys work because:**
- ✅ File is copied/created with correct ownership
- ✅ Works with both `gcloud` CLI and Terraform
- ✅ Same approach for local dev and CI/CD
- ✅ Can be easily rotated and revoked

## Commands

```bash
worker-config                    # Generate config template
worker-run                       # Run container (auto-detects credentials)
worker-run --dry-run             # Preview without executing
worker-run run-it                # Interactive mode (shell access)
worker-run --config=custom.yml   # Use custom config file
```

## Configuration

Edit the generated `deploy.yml` file:

```yaml
---
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  # Docker image to use
  image: "usabilitydynamics/udx-worker-tooling:latest"

  # Mount your files into the container
  volumes:
    - "./src:/workspace/src" # Mount src folder
    - "./data:/workspace/data" # Mount data folder

  # Set environment variables
  env:
    DEBUG: "true"
    PROJECT_NAME: "my-project"

  # Command to run
  command: "bash /workspace/src/my-script.sh"
```

## Examples

### Run a Python Script with GCP Access

```yaml
config:
  image: "python:3.9"
  volumes:
    - "./my-script.py:/app/script.py"
    - "./requirements.txt:/app/requirements.txt"
  command: "pip install -r /app/requirements.txt && python /app/script.py"
```

### Run Terraform with GCP Credentials

```yaml
config:
  image: "hashicorp/terraform:latest"
  volumes:
    - "./terraform:/workspace"
  env:
    TF_VAR_project_id: "my-gcp-project"
  command: "terraform init && terraform plan"
```

### Run UDX Worker

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./:/workspace"
  env:
    DEBUG: "true"
  command: "worker run my-task"
```

### Test Configuration Before Running

```bash
# Test your configuration without executing
worker-run --dry-run
```

### Interactive Debugging Session

```bash
# Run container with shell access
worker-run run-it
```

## Prerequisites

```bash
# Required
brew install docker yq

# macOS only (GNU Make)
brew install make

# Optional (for GCP auth)
brew install google-cloud-sdk
```

## License

MIT
