# worker-run

Runs a Docker container using `deploy.yml` and auto-detected credentials.

## Usage

```bash
worker run
```

## Options

- `--config=FILE` use a custom config file
- `--dry-run` print the docker run command without executing
- `run-it` interactive mode (adds `-it`)

## npx

```bash
npx @udx/worker-deployment worker run
```

## Notes

- YAML parsing uses the bundled Node `yaml` package.
- For commands with special characters, prefer `command` + `args` in `deploy.yml`.
