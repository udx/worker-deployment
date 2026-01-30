# worker-images

Search for `worker-` projects in GitHub and Docker Hub.

## Usage

```bash
worker images --all
```

## Options

- `--github` search GitHub org `udx`
- `--dockerhub` search Docker Hub org `usabilitydynamics`
- `--all` search both (default)
- `--limit=N` limit results per source (default: 50)
- `--output=FILE` write results to file (prompts unless `--apply`)
- `--apply` or `--yes` write file without prompting

## Auth

- GitHub private repos require `GITHUB_TOKEN` or `gh` login.
- Docker Hub private images require `DOCKERHUB_TOKEN` or `docker login`.

## npx

```bash
npx @udx/worker-deployment worker images --all
```
