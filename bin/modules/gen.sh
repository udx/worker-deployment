#!/usr/bin/env bash
set -euo pipefail

# Worker Deploy - Generator CLI

WARN='\033[0;33m'
OK='\033[0;32m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_ROOT="$PKG_DIR/src/templates/worker-gen"

show_help() {
    echo "Usage: worker gen <command> [options]"
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
    echo "  worker gen repo --lang=node"
    echo "  worker gen dockerfile --lang=php --apply"
    echo "  worker gen worker.yaml --output-dir=.config/worker"
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

escape_sed() {
    printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

render_template() {
    local template="$1"
    local name_esc base_esc app_esc
    name_esc="$(escape_sed "$NAME")"
    base_esc="$(escape_sed "$BASE_IMAGE")"
    app_esc="$(escape_sed "$APP_HOME")"
    sed -e "s/{{NAME}}/${name_esc}/g" \
        -e "s/{{BASE_IMAGE}}/${base_esc}/g" \
        -e "s/{{APP_HOME}}/${app_esc}/g" \
        "$template"
}

add_template() {
    local relpath="$1"
    local template="$2"
    local tmpfile
    if [[ ! -f "$template" ]]; then
        printf "${ERROR}Template not found: %s${NC}\n" "$template" >&2
        exit 1
    fi
    tmpfile="$(mktemp "$TMP_DIR/file.XXXXXX")"
    render_template "$template" > "$tmpfile"
    printf "%s|%s\n" "$relpath" "$tmpfile" >> "$PLAN_FILE"
}

case "$SUBCOMMAND" in
    dockerfile)
        add_template "Dockerfile" "$TEMPLATE_ROOT/Dockerfile"
        ;;
    worker.yaml)
        add_template "worker.yaml" "$TEMPLATE_ROOT/.config/worker/worker.yaml"
        ;;
    services.yaml)
        add_template "services.yaml" "$TEMPLATE_ROOT/.config/worker/services.yaml"
        ;;
    repo)
        if [[ "$DOCKERFILE_ONLY" == "true" ]]; then
            add_template "Dockerfile" "$TEMPLATE_ROOT/Dockerfile"
        else
            add_template "Dockerfile" "$TEMPLATE_ROOT/Dockerfile"
            add_template "README.md" "$TEMPLATE_ROOT/README.md"
            add_template "Makefile" "$TEMPLATE_ROOT/Makefile"
            add_template ".dockerignore" "$TEMPLATE_ROOT/.dockerignore"
            if [[ "$WITH_WORKER_CONFIG" == "true" ]]; then
                add_template ".config/worker/worker.yaml" "$TEMPLATE_ROOT/.config/worker/worker.yaml"
            fi
            if [[ "$WITH_SERVICES" == "true" ]]; then
                add_template ".config/worker/services.yaml" "$TEMPLATE_ROOT/.config/worker/services.yaml"
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
