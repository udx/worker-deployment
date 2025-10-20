# Worker Deploy

Run any Docker container with simple YAML configuration and automatic GCP credential mounting.

## Features

- 🚀 **Simple Setup** - Generate config template and run
- 🔐 **GCP Authentication** - Automatic credential detection and mounting
- 📁 **File Mounting** - Mount your local files into containers
- 🔧 **Environment Variables** - Pass environment variables to containers
- 💻 **Interactive Mode** - Run containers interactively for debugging

## Installation

```bash
npm install -g @udx/worker-deployment
```

## Quick Start

```bash
# 1. Generate config template
worker-config

# 2. Edit deploy.yml with your settings

# 3. Run your container
worker-run
```

## GCP Authentication

The tool automatically detects and uses your GCP credentials in priority order. All methods set **both** `GOOGLE_APPLICATION_CREDENTIALS` (standard) and `GCP_CREDS` (UDX-specific) environment variables.

### Option 1: Service Account Key

Place a service account JSON key file in your project directory:

```bash
# Name it:
gcp-key.json
```

**What it does:**
- Mounts the file to `/tmp/gcp-key.json` in the container
- Sets `GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-key.json` (for standard Google SDKs, Terraform, gcloud)
- Sets `GCP_CREDS=/tmp/gcp-key.json` (for UDX workers)

**Works with:** ✅ gcloud CLI, ✅ Terraform, ✅ All Google SDKs, ✅ UDX workers

### Option 2: Token Credentials

Place token-based credentials (e.g., Application Default Credentials) in your project directory:

```bash
# Name it:
gcp-credentials.json

# Or copy your local ADC:
cp ~/.config/gcloud/application_default_credentials.json ./gcp-credentials.json
```

**What it does:**
- Mounts the file to `/tmp/gcp-creds.json` in the container
- Sets `GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-creds.json` (for standard Google SDKs, Terraform, gcloud)
- Sets `GCP_CREDS=/tmp/gcp-creds.json` (for UDX workers)

**Works with:** ✅ gcloud CLI, ✅ Terraform, ✅ All Google SDKs, ✅ UDX workers

### Option 3: Local gcloud Config (Development)

If no credential files are found, your local gcloud configuration is mounted:

```bash
# Authenticate with gcloud
gcloud auth login
gcloud auth application-default login
```

**What it does:**
- Mounts `~/.config/gcloud` to `/root/.config/gcloud` (read-only)
- Sets `CLOUDSDK_CONFIG=/root/.config/gcloud` (for gcloud CLI)
- Sets `GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json` (for SDKs/Terraform)

**Works with:** ✅ gcloud CLI, ✅ Terraform, ✅ All Google SDKs

**Note:** This is best for local development. For production or CI/CD, use Option 1 or 2.

## Commands

| Command                           | Description                                 |
| --------------------------------- | ------------------------------------------- |
| `worker-config`                   | Generate config template                    |
| `worker-run`                      | Run container                               |
| `worker-run run-it`               | Run container interactively                 |
| `worker-run --config=my-config.yml` | Use custom config file                      |
| `worker-run --dry-run`            | Show what would be executed without running |

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

- **Docker** - Must be installed and running
- **yq** - Install with `brew install yq` (macOS) or `apt install yq` (Linux)
- **GNU Make** - macOS users: `brew install make` (use `gmake` command)

## License

MIT
