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

The tool supports **three authentication methods** to work seamlessly in any environment:

1. **Service Account Key** - Manual key file (local dev)
2. **Workload Identity Federation** - Keyless auth (GitHub Actions)
3. **Service Account Impersonation** - Use your user credentials (local dev)

### Method 1: Service Account Key (Local Development)

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

### Method 2: Workload Identity Federation (GitHub Actions)

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

### Method 3: Service Account Impersonation (Local Development)

Use your own gcloud credentials to impersonate a service account:

```yaml
# In deploy.yml
config:
  service_account:
    email: "my-sa@my-project.iam.gserviceaccount.com"
```

**Setup (one-time):**
```bash
# 1. Authenticate with your user account
gcloud auth login

# 2. Grant yourself impersonation permission
gcloud iam service-accounts add-iam-policy-binding \
  my-sa@my-project.iam.gserviceaccount.com \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=MY_PROJECT

# 3. Run deployment
worker-run
```

**Benefits:**
- ✅ No key files to manage
- ✅ Uses your existing gcloud auth
- ✅ Temporary tokens (1 hour)
- ✅ Easy permission management

**Note:** Impersonation only works with `gcloud` CLI commands. For Terraform/SDKs, use Method 1 or 2.

---

### Authentication Priority

The tool checks for credentials in this order:

1. Config-specified paths (`service_account.key_path` or `service_account.token_path`)
2. `gcp-key.json` in current or config directory
3. `gcp-credentials.json` in current or config directory
4. Service account impersonation (`service_account.email`)

### Advanced: Config-Based Authentication

Override default paths or use impersonation in your `deploy.yml`:

```yaml
config:
  # Option 1: Custom key file path
  service_account:
    key_path: "./secrets/my-service-account.json"

  # Option 2: Custom token file path
  service_account:
    token_path: "./credentials/gcp-token.json"

  # Option 3: Impersonate a service account (requires gcloud auth on host)
  service_account:
    email: "my-sa@my-project.iam.gserviceaccount.com"
```

**Use cases:**
- Custom credential file locations
- Multiple deployment configs with different credentials
- Shared team configurations

## How It Works

### Credential Detection

The tool automatically:
1. Detects available credentials (files or config)
2. Mounts credential files into the container
3. Sets appropriate environment variables (`GOOGLE_APPLICATION_CREDENTIALS`, `CLOUDSDK_AUTH_ACCESS_TOKEN`)
4. Container has full GCP access

### Why Not Mount `~/.config/gcloud`?

**UID/GID Mismatch:** When containers run as non-root users (e.g., UID 500), they can't read host files owned by your user (e.g., UID 501). This causes permission errors.

**Our solution:** Generate or copy credential files with correct ownership, avoiding permission issues entirely.

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
