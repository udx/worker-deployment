# Worker Deploy

**Run any Docker container with automatic cloud authentication.**

Simple YAML configuration + automatic GCP credential detection = zero-config deployments.

## Why Use This?

- ✅ **Zero Config** - Automatically detects and uses your existing gcloud credentials
- ✅ **Works Everywhere** - Local dev, CI/CD, production
- ✅ **Secure** - Read-only mounts, no credential copying

## Installation

```bash
npm install -g @udx/worker-deployment
```

## Quick Start

```bash
# 1. Install
npm install -g @udx/worker-deployment

# 2. Generate default config template
worker-config

# 3. Edit deploy.yml with your settings

# 4. Run your container
worker-run
```

**That's it!** The tool automatically detects your GCP credentials.

## GCP Authentication

The tool supports **three authentication methods**:

### 🎯 Recommended: Service Account Impersonation (Local Dev)

Use your gcloud credentials - no key files needed!

```yaml
# In deploy.yml
config:
  service_account:
    email: "my-sa@my-project.iam.gserviceaccount.com"
```

**One-time setup:**
```bash
# 1. Authenticate with gcloud
gcloud auth login

# 2. Set up Application Default Credentials (required for Terraform)
gcloud auth application-default login

# 3. Grant yourself impersonation permission
gcloud iam service-accounts add-iam-policy-binding \
  my-sa@my-project.iam.gserviceaccount.com \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=MY_PROJECT

# 4. Run
worker-run
```

**Why use this?** ✅ No key files ✅ Temporary tokens ✅ Easy permission management ✅ Works with Terraform/SDKs

---

### 📁 Service Account Key (Alternative)

If you already have a service account key:

```bash
# Save as gcp-key.json in your project directory
worker-run
```

Or specify custom path in `deploy.yml`:
```yaml
config:
  service_account:
    key_path: "./secrets/my-key.json"
```

---

### 🔐 Workload Identity Federation (GitHub Actions)

Keyless authentication for CI/CD:

```yaml
- uses: google-github-actions/auth@v3
  id: auth
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

- run: |
    cp ${{ steps.auth.outputs.credentials_file_path }} gcp-credentials.json
    worker-run
```

Or specify custom path:
```yaml
config:
  service_account:
    token_path: "./credentials/gcp-token.json"
```

---

### Authentication Priority

The tool checks credentials in this order:
1. **Config-specified** (`service_account.email`, `key_path`, or `token_path`)
2. **Default files** (`gcp-key.json` or `gcp-credentials.json` in current/config directory)

**Default file locations work automatically** - no config needed!

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

  # Command to run (optional - if not specified, uses container's default CMD/ENTRYPOINT)
  command: "bash /workspace/src/my-script.sh"
```

## Examples

### Basic UDX Worker

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./:/workspace"
  env:
    DEBUG: "true"
    GCP_PROJECT: "my-project"
  command: "worker run my-task"
```

### UDX Worker with Custom Script

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./scripts:/workspace/scripts"
    - "./data:/workspace/data"
  env:
    ENVIRONMENT: "production"
  command: "bash /workspace/scripts/deploy.sh"
```

### UDX Worker with Service Account Impersonation

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  service_account:
    email: "worker-sa@my-project.iam.gserviceaccount.com"
  volumes:
    - "./:/workspace"
  command: "worker deploy --env=staging"
```

### Using Container's Default Command

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./:/workspace"
  env:
    GCP_PROJECT: "my-project"
  # No command specified - uses container's default CMD/ENTRYPOINT
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
