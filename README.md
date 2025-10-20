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

## GCP Authentication (Automatic)

The tool automatically finds and uses your GCP credentials. **No manual setup required!**

### For Local Development

**Already using gcloud?** You're done! The tool automatically uses your existing credentials.

If you haven't authenticated yet, run these once:

```bash
gcloud auth login                        # Authenticate your user
gcloud auth application-default login    # Create ADC for Terraform/SDKs
```

Then `worker-run` automatically mounts your `~/.config/gcloud` directory.

### For Production/CI/CD

Drop a credential file in your project directory:

```bash
# Service account key (recommended)
gcp-key.json

# OR token/ADC file
gcp-credentials.json
```

The tool automatically detects and mounts it.

### Detection Priority

1. `gcp-key.json` in current or config directory
2. `gcp-credentials.json` in current or config directory  
3. `~/.config/gcloud` (local gcloud auth)

**All standard GCP tools work:** gcloud CLI, Terraform, Python/Node.js/Go SDKs, etc.

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
