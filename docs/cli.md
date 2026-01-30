# CLI Reference (Worker Deployment)

This document describes the additional helper commands provided by `@udx/worker-deployment`.

## worker-gen

Generate child-image scaffolding or config files. Dry-run by default and will prompt before writing.

### Commands

- `worker-gen repo`
  - Generates a child image repo skeleton (Dockerfile + README + Makefile + .dockerignore).
  - Includes `.config/worker/worker.yaml` and `services.yaml` by default.

- `worker-gen dockerfile`
  - Generates a Dockerfile only.

- `worker-gen worker.yaml`
  - Generates a `worker.yaml` template.

- `worker-gen services.yaml`
  - Generates a `services.yaml` template.

### Options

- `--output-dir=DIR` output directory (default: current)
- `--apply` or `--yes` write files without prompting
- `--force` overwrite existing files
- `--lang=node|php|python|custom` language preset for Dockerfile
- `--base=IMAGE` base image (default: usabilitydynamics/udx-worker:latest)
- `--app-home=PATH` app home path (default depends on lang)
- `--name=NAME` used in README/Makefile when generating a repo

## worker-images

Search for `worker-` repositories and images. Outputs to stdout by default.

### Options

- `--github` search GitHub org `udx`
- `--dockerhub` search Docker Hub org `usabilitydynamics`
- `--all` search both (default)
- `--limit=N` limit results per source (default: 50)
- `--output=FILE` write results to file (prompts unless `--apply`)
- `--apply` or `--yes` write file without prompting

### Auth Notes

- GitHub private repos require `GITHUB_TOKEN` or `gh` login.
- Docker Hub private images require `DOCKERHUB_TOKEN` or `docker login`.

## YAML Parsing

`worker-run` parses `deploy.yml` using the Node `yaml` package bundled with this CLI.
