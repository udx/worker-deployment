#!/usr/bin/env bash
set -euo pipefail

# Color constants
WARN='\033[0;33m'
OK='\033[0;32m'
COMMAND='\033[1;36m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
NC='\033[0m'

# prefer gmake on macOS (brew install make), else fallback to make if it's GNU
MAKE_BIN="make"
if command -v gmake >/dev/null 2>&1; then
    MAKE_BIN="gmake"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    if ! make -v 2>/dev/null | head -n1 | grep -qi "gnu"; then
        printf "${ERROR}GNU make is required. Install: brew install make (use 'gmake')${NC}\n" >&2
        exit 1
    fi
fi

# Function to check if yq is available
check_yq() {
    if ! command -v yq >/dev/null 2>&1; then
        printf "${ERROR}Error: yq is required for YAML parsing${NC}\n" >&2
        printf "${INFO}Install with: brew install yq${NC}\n" >&2
        exit 1
    fi
}

# Resolve script directory
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

# Resolve package directory
PKG_DIR="${SCRIPT_DIR}/.."

# Resolve makefile
MK="$PKG_DIR/make/deploy.mk"

# Default configuration file - look in current working directory first
CONFIG_FILE="$(pwd)/deploy.yml"
# Fallback to package template if not found
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="${PKG_DIR}/configs/deploy.yml"
fi

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo ""
    echo "Options:"
    echo "  --config=FILE     Use custom config file (default: ./deploy.yml)"
    echo "  --help           Show this help"
    echo ""
    echo "Targets:"
    echo "  run              Run deployment (default)"
    echo "  run-it           Run deployment interactively"
    echo ""
    echo "Examples:"
    echo "  $0                              # Run deployment with default config"
    echo "  $0 run-it                       # Run deployment interactively"
    echo "  $0 --config=my-config.yml      # Use custom config file"
}

# Parse command line arguments
target="run"
config_file=""
make_args=()

for arg in "$@"; do
    case $arg in
        --config=*) 
            config_file="${arg#*=}"
            # Convert relative path to absolute
            if [[ "$config_file" == ./* ]]; then
                config_file="$(pwd)/${config_file#./}"
            elif [[ "$config_file" != /* ]]; then
                config_file="$(pwd)/$config_file"
            fi
            ;;
        --help)
            show_help
            exit 0
            ;;
        run|run-it)
            target="$arg"
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Use default config file if none specified
if [[ -z "$config_file" ]]; then
    config_file="$CONFIG_FILE"
fi

make_args+=("CONFIG_FILE=$config_file")

# Check dependencies
check_yq

# Verify config file exists
if [[ ! -f "$config_file" ]]; then
    printf "${ERROR}Error: Configuration file not found: $config_file${NC}\n" >&2
    printf "${INFO}Generate a config file with: worker-deploy-config${NC}\n" >&2
    exit 1
fi

printf "${INFO}Using configuration: $config_file${NC}\n"

# Parse YAML configuration
WORKER_IMAGE=$(yq eval '.config.image' "$config_file")
COMMAND=$(yq eval '.config.command' "$config_file")

# Build volumes from config
VOLUMES=""
volume_count=$(yq eval '.config.volumes | length' "$config_file")
for ((i=0; i<volume_count; i++)); do
    volume=$(yq eval ".config.volumes[$i]" "$config_file")
    # Convert relative paths to absolute
    if [[ "$volume" == ./* ]]; then
        src_path="${volume%%:*}"
        dest_path="${volume#*:}"
        volume="$(cd "$PKG_DIR" && pwd)/${src_path#./}:$dest_path"
    fi
    VOLUMES="$VOLUMES -v $volume"
done

# Build environment variables from config
ENV_VARS=""
env_count=$(yq eval '.config.env | length' "$config_file")
if [[ "$env_count" != "0" ]]; then
    env_keys=$(yq eval '.config.env | keys | .[]' "$config_file")
    while IFS= read -r key; do
        if [[ -n "$key" ]]; then
            value=$(yq eval ".config.env.$key" "$config_file")
            ENV_VARS="$ENV_VARS -e $key=$value"
        fi
    done <<< "$env_keys"
fi

# Build arguments from config
ARGS=""
args_count=$(yq eval '.config.args | length' "$config_file")
for ((i=0; i<args_count; i++)); do
    arg=$(yq eval ".config.args[$i]" "$config_file")
    ARGS="$ARGS $arg"
done

# Add parsed values to make_args
make_args+=("WORKER_IMAGE=$WORKER_IMAGE")
make_args+=("COMMAND=$COMMAND")
make_args+=("VOLUMES=$VOLUMES")
make_args+=("ENV_VARS=$ENV_VARS")
make_args+=("ARGS=$ARGS")

# Pass everything through to make
exec "$MAKE_BIN" -f "$MK" "${make_args[@]}" "$target"
