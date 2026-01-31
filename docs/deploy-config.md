# Deploy Config (deploy.yml)

Minimal example:

```yaml
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./:/workspace"
  env:
    DEBUG: "true"
  command: "worker run my-task"
```

Using container default command:

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./:/workspace"
  # No command specified - uses container's default CMD/ENTRYPOINT
```

Command + args (recommended for special characters):

```yaml
config:
  image: "usabilitydynamics/udx-worker-nodejs:latest"
  command: "node"
  args:
    - "-e"
    - "console.log('hello_world')"
```

Service account impersonation:

```yaml
config:
  image: "usabilitydynamics/udx-worker:latest"
  service_account:
    email: "worker-sa@my-project.iam.gserviceaccount.com"
  volumes:
    - "./:/workspace"
  command: "worker deploy --env=staging"
```
