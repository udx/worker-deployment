# Worker Deploy

Dynamic Docker deployment tool with YAML configuration support.

- Configurable Docker container deployment
- YAML-based configuration management
- Automatic credential detection and mounting
- Support for Terraform workflows

## Features

- ✅ **YAML Configuration** - Structured configuration with validation
- ✅ **Config Generation** - Built-in template generator
- ✅ **Dynamic Volume Mounting** - Configurable volume mappings
- ✅ **Credential Auto-Detection** - Automatic GCP credential mounting
- ✅ **Environment Variables** - Configurable environment variable injection
- ✅ **Terraform Integration** - Built-in support for terraform plan/apply workflows

## Installation

```bash
npm install -g @udx/worker-deployment
```

## Usage

### Quick Start

```bash
# 1. Generate config template
worker-deploy-config

# 2. Edit deploy.yml with your deployment details

# 3. Run deployment
worker-deploy-run

# 4. Run deployment interactively
worker-deploy-run run-it
```

### Commands

| Command                                        | Description                             |
| ---------------------------------------------- | --------------------------------------- |
| `worker-deploy-config`                         | Generate `deploy.yml` config template   |
| `worker-deploy-config --output=my-config.yml`  | Generate custom config file             |
| `worker-deploy tf-plan`                        | Run terraform plan with default config  |
| `worker-deploy tf-apply`                       | Run terraform apply with default config |
| `worker-deploy --config=my-config.yml tf-plan` | Use custom config file                  |
| `worker-deploy --help`                         | Show help information                   |

### Configuration

The tool uses a YAML configuration file (`deploy.yml`) to define:

- Docker image and workspace settings
- Volume mappings for your project files
- Environment variables
- GCP credential paths
- Command arguments

**Example Configuration:**

```yaml
---
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  # Docker image to use
  image: "usabilitydynamics/udx-worker-tooling:latest"

  # Working directory inside container
  workspace: "/github/workspace"

  # Environment variables to pass to container
  env:
    PLAN_ONLY: "true"
    ARTIFACTS_PATH: "/github/workspace/outputs"

  # Volume mappings (source:destination format)
  volumes:
    - "./src/lib/deploy.sh:/github/workspace/deploy.sh"
    - "./terraform:/github/workspace/terraform"

  # Command to run inside container
  command: 'bash -c "chmod +x /github/workspace/deploy.sh && /github/workspace/deploy.sh"'

  # Additional arguments to pass to the command
  args:
    - "true"
    - "/github/workspace/outputs"
```

## Configuration Schema

| Field              | Required | Description                    | Example                                       |
| ------------------ | -------- | ------------------------------ | --------------------------------------------- |
| `config.image`     | ✅       | Docker image to use            | `usabilitydynamics/udx-worker-tooling:latest` |
| `config.workspace` | ✅       | Working directory in container | `/github/workspace`                           |
| `config.env`       | ❌       | Environment variables          | `{"PLAN_ONLY": "true"}`                       |
| `config.volumes`   | ✅       | Volume mappings                | `["./terraform:/workspace/terraform"]`        |
| `config.command`   | ✅       | Command to run in container    | `bash -c "terraform plan"`                    |
| `config.args`      | ❌       | Additional command arguments   | `["--auto-approve"]`                          |

## Examples

### Basic Terraform Deployment

```bash
# Generate config
worker-deploy-config

# Edit deploy.yml with your project paths

# Deploy the worker container
worker-deploy-run
```

### Custom Configuration

```bash
# Generate custom config
worker-deploy-config --output=production.yml

# Use custom config
worker-deploy-run --config=production.yml
```

## Prerequisites

- **Docker** - Must be installed and running
- **yq** - Required for YAML processing (install with `brew install yq`)

## License

MIT
