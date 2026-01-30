# worker-gen

Generates child image scaffolding or config templates. Dry-run by default.

## Commands

- `worker gen repo` generate a child image repo skeleton
- `worker gen dockerfile` generate Dockerfile only
- `worker gen worker.yaml` generate `worker.yaml`
- `worker gen services.yaml` generate `services.yaml`

## Options

- `--output-dir=DIR` output directory (default: current)
- `--apply` or `--yes` write files without prompting
- `--force` overwrite existing files
- `--lang=node|php|python|custom` Dockerfile preset
- `--base=IMAGE` base image (default: usabilitydynamics/udx-worker:latest)
- `--app-home=PATH` app home path (default depends on preset)
- `--name=NAME` used in README/Makefile when generating a repo

## npx

```bash
npx @udx/worker-deployment worker gen repo
```
