#!/usr/bin/env bash
set -euo pipefail

# Worker Deploy - Generator CLI

WARN='\033[0;33m'
OK='\033[0;32m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
NC='\033[0m'

show_help() {
    echo "Usage: worker-gen <command> [options]"
    echo ""
    echo "Commands:"
    echo "  repo                 Generate a child image repo skeleton"
    echo "  dockerfile           Generate a Dockerfile only"
    echo "  worker.yaml          Generate worker.yaml"
    echo "  services.yaml        Generate services.yaml"
    echo ""
    echo "Common Options:"
    echo "  --output-dir=DIR     Output directory (default: current)"
    echo "  --apply, --yes       Apply changes (default: dry-run with prompt)"
    echo "  --force              Overwrite existing files"
    echo ""
    echo "Dockerfile Options:"
    echo "  --lang=LANG          Language preset: node|php|python|custom"
    echo "  --base=IMAGE         Base worker image (default: usabilitydynamics/udx-worker:latest)"
    echo "  --app-home=PATH      App home directory (default by lang)"
    echo ""
    echo "Repo Options:"
    echo "  --name=NAME          Project name (used in README/Makefile)"
    echo "  --with-worker-config Include .config/worker/worker.yaml (default: yes)"
    echo "  --with-services      Include .config/worker/services.yaml (default: yes)"
    echo "  --dockerfile-only    Skip other repo files (same as dockerfile command)"
    echo ""
    echo "Examples:"
    echo "  worker-gen repo --lang=node"
    echo "  worker-gen dockerfile --lang=php --apply"
    echo "  worker-gen worker.yaml --output-dir=.config/worker"
}

SUBCOMMAND="${1:-}"
if [[ -z "$SUBCOMMAND" || "$SUBCOMMAND" == "--help" || "$SUBCOMMAND" == "-h" ]]; then
    show_help
    exit 0
fi
shift || true

APPLY=false
FORCE=false
OUTPUT_DIR="$(pwd)"
LANG="custom"
BASE_IMAGE="usabilitydynamics/udx-worker:latest"
APP_HOME=""
NAME="child-worker"
WITH_WORKER_CONFIG=true
WITH_SERVICES=true
DOCKERFILE_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir=*) OUTPUT_DIR="${1#*=}" ;;
        --apply|--yes) APPLY=true ;;
        --force) FORCE=true ;;
        --lang=*) LANG="${1#*=}" ;;
        --base=*) BASE_IMAGE="${1#*=}" ;;
        --app-home=*) APP_HOME="${1#*=}" ;;
        --name=*) NAME="${1#*=}" ;;
        --with-worker-config) WITH_WORKER_CONFIG=true ;;
        --with-services) WITH_SERVICES=true ;;
        --no-worker-config) WITH_WORKER_CONFIG=false ;;
        --no-services) WITH_SERVICES=false ;;
        --dockerfile-only) DOCKERFILE_ONLY=true ;;
        --help|-h) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

case "$LANG" in
    node) APP_HOME_DEFAULT="/usr/src/app" ;;
    php) APP_HOME_DEFAULT="/var/www" ;;
    python) APP_HOME_DEFAULT="/usr/src/app" ;;
    custom) APP_HOME_DEFAULT="/usr/src/app" ;;
    *) echo "Unknown lang preset: $LANG"; exit 1 ;;
esac

if [[ -z "$APP_HOME" ]]; then
    APP_HOME="$APP_HOME_DEFAULT"
fi

TMP_DIR="$(mktemp -d)"
PLAN_FILE="$TMP_DIR/plan.txt"
touch "$PLAN_FILE"
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

add_file() {
    local relpath="$1"
    local tmpfile
    tmpfile="$(mktemp "$TMP_DIR/file.XXXXXX")"
    cat > "$tmpfile"
    printf "%s|%s\n" "$relpath" "$tmpfile" >> "$PLAN_FILE"
}

dockerfile_content() {
    cat <<EOF
# Use UDX Worker as the base image
FROM ${BASE_IMAGE}

LABEL maintainer="UDX"

ENV APP_HOME="${APP_HOME}"

USER root
RUN mkdir -p "${APP_HOME}" && \\
    chown -R "\${USER}:\${USER}" "${APP_HOME}" && \\
    chmod -R 755 "${APP_HOME}"

USER "\${USER}"
WORKDIR "${APP_HOME}"

# Use the parent image's entrypoint
ENTRYPOINT ["/usr/local/worker/bin/entrypoint.sh"]

# Default command (override in your runtime)
CMD ["tail", "-f", "/dev/null"]
EOF
}

readme_content() {
    cat <<EOF
# ${NAME}

Child image built on UDX Worker.

## Build

\`\`\`bash
make build
\`\`\`

## Run

\`\`\`bash
make run
\`\`\`

## Notes

- App home: ${APP_HOME}
- Base image: ${BASE_IMAGE}
EOF
}

makefile_content() {
    cat <<'EOF'
IMAGE_NAME ?= usabilitydynamics/udx-worker-child:latest

.PHONY: build run shell

build:
	docker build -t $(IMAGE_NAME) .

run:
	docker run --rm -it $(IMAGE_NAME)

shell:
	docker run --rm -it $(IMAGE_NAME) /bin/bash
EOF
}

dockerignore_content() {
    cat <<'EOF'
.git
.DS_Store
node_modules
dist
build
EOF
}

worker_yaml_content() {
    cat <<'EOF'
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    LOG_LEVEL: "info"
  secrets:
    # Example secret reference
    # DB_PASSWORD: "gcp/my-project/db-password"
EOF
}

services_yaml_content() {
    cat <<'EOF'
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "example"
    command: "bash -lc 'echo hello from worker service'"
    autostart: true
    autorestart: false
    envs:
      - "LOG_LEVEL=info"
EOF
}

case "$SUBCOMMAND" in
    dockerfile)
        add_file "Dockerfile" < <(dockerfile_content)
        ;;
    worker.yaml)
        add_file "worker.yaml" < <(worker_yaml_content)
        ;;
    services.yaml)
        add_file "services.yaml" < <(services_yaml_content)
        ;;
    repo)
        if [[ "$DOCKERFILE_ONLY" == "true" ]]; then
            add_file "Dockerfile" < <(dockerfile_content)
        else
            add_file "Dockerfile" < <(dockerfile_content)
            add_file "README.md" < <(readme_content)
            add_file "Makefile" < <(makefile_content)
            add_file ".dockerignore" < <(dockerignore_content)
            if [[ "$WITH_WORKER_CONFIG" == "true" ]]; then
                add_file ".config/worker/worker.yaml" < <(worker_yaml_content)
            fi
            if [[ "$WITH_SERVICES" == "true" ]]; then
                add_file ".config/worker/services.yaml" < <(services_yaml_content)
            fi
        fi
        ;;
    *)
        echo "Unknown command: $SUBCOMMAND"
        exit 1
        ;;
esac

if [[ ! -s "$PLAN_FILE" ]]; then
    printf "${ERROR}No files generated.${NC}\n" >&2
    exit 1
fi

echo "Planned files:" 
while IFS='|' read -r relpath tmpfile; do
    echo "- ${OUTPUT_DIR}/${relpath}"
done < "$PLAN_FILE"

conflicts=0
while IFS='|' read -r relpath tmpfile; do
    outpath="${OUTPUT_DIR}/${relpath}"
    if [[ -f "$outpath" ]]; then
        conflicts=1
    fi
done < "$PLAN_FILE"

if [[ "$conflicts" -eq 1 && "$FORCE" != "true" ]]; then
    printf "${WARN}One or more files already exist. Use --force to overwrite.${NC}\n" >&2
    exit 1
fi

if [[ "$APPLY" != "true" ]]; then
    echo ""
    echo "Dry run. Files would be written with the following contents:"
    echo ""
    while IFS='|' read -r relpath tmpfile; do
        echo "--- ${relpath} ---"
        cat "$tmpfile"
        echo ""
    done < "$PLAN_FILE"

    printf "Apply these changes? [y/N]: "
    read -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

while IFS='|' read -r relpath tmpfile; do
    outpath="${OUTPUT_DIR}/${relpath}"
    outdir="$(dirname "$outpath")"
    mkdir -p "$outdir"
    cp "$tmpfile" "$outpath"
done < "$PLAN_FILE"

printf "${OK}Generated files in: ${OUTPUT_DIR}${NC}\n"
