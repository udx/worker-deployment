# Worker Deploy

Run any Docker container with automatic cloud authentication.

## Installation

```bash
npm install -g @udx/worker-deployment
```

## Quick Start

```bash
# Generate default config template
worker-config

# Edit deploy.yml with your settings

# Run your container
worker-run
```

## Commands

```bash
worker-config                    # Generate config template
worker-run                       # Run container (auto-detects credentials)
worker-run --dry-run             # Preview without executing
worker-run run-it                # Interactive mode (shell access)
worker-run --config=custom.yml   # Use custom config file
worker-gen repo                  # Generate child image repo (dry-run + prompt)
worker-gen dockerfile            # Generate Dockerfile only (dry-run + prompt)
worker-images --all              # List worker images from GitHub/Docker Hub
```

## Docs

- docs/index.md

## License

MIT
