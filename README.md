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

The tool automatically detects and uses your GCP credentials in priority order:

### Option 1: Service Account Key

Place a service account JSON key file in your project directory:

```bash
# Name it:
gcp-key.json
```

This mounts as `/home/udx/gcp-key.json` with `GCP_CREDS` environment variable.

### Option 2: Token Credentials

Place token-based credentials in your project directory:

```bash
# Name it:
gcp-credentials.json
```

This mounts as `/home/udx/gcp-creds.json` with `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

### Option 3: Local gcloud Authentication (Fallback)

If no credential files are found, your local gcloud authentication is shared:

```bash
# Your existing gcloud auth is automatically used
# No setup needed if you're already authenticated locally
```

This mounts `~/.config/gcloud` to `/usr/local/configs/gcloud` in the container, sharing your local gcloud session.

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
