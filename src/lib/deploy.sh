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

# Function to check if Docker is available and running
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        printf "${ERROR}Error: Docker is not installed${NC}\n" >&2
        printf "${INFO}Install Docker from: https://docs.docker.com/get-docker/${NC}\n" >&2
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        printf "${ERROR}Error: Docker is not running${NC}\n" >&2
        printf "${INFO}Start Docker Desktop or run: sudo systemctl start docker${NC}\n" >&2
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

# Function to validate if an image is supported
validate_worker_image() {
    local image="$1"
    local image_name="${image%%:*}"  # Remove tag if present
    
    # Read supported images from package.json
    local supported_images=$(node -e "console.log(require('$PKG_DIR/../package.json').config.supportedImages.join('\n'))")
    
    while IFS= read -r supported; do
        if [[ "$image_name" == "$supported" ]]; then
            return 0
        fi
    done <<< "$supported_images"
    
    return 1
}

# Function to list supported images
list_supported_images() {
    echo "Supported worker images:"
    node -e "require('$PKG_DIR/../package.json').config.supportedImages.forEach(img => console.log('  - ' + img))"
}

# Resolve makefile
MK="$PKG_DIR/make/deploy.mk"

# Default configuration file - look in current working directory only
# Check for both .yml and .yaml extensions
if [[ -f "$(pwd)/deploy.yml" ]]; then
    CONFIG_FILE="$(pwd)/deploy.yml"
elif [[ -f "$(pwd)/deploy.yaml" ]]; then
    CONFIG_FILE="$(pwd)/deploy.yaml"
else
    CONFIG_FILE="$(pwd)/deploy.yml"  # Default for error messages
fi

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo ""
    echo "Options:"
    echo "  --config=FILE     Use custom config file (default: ./deploy.yml or ./deploy.yaml)"
    echo "  --dry-run         Show what would be executed without running it"
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
    echo "  $0 --dry-run                    # Show what would be executed"
}

# Parse command line arguments
target="run"
config_file=""
dry_run=false
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
        --dry-run)
            dry_run=true
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

# Add dry-run flag if specified
if [[ "$dry_run" == true ]]; then
    make_args+=("DRY_RUN=true")
fi

# Check dependencies
check_yq
check_docker

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

# Validate required fields
if [[ "$WORKER_IMAGE" == "null" || -z "$WORKER_IMAGE" ]]; then
    printf "${ERROR}Error: 'config.image' is required in configuration file${NC}\n" >&2
    exit 1
fi

# Validate worker image is supported
if ! validate_worker_image "$WORKER_IMAGE"; then
    printf "${ERROR}Error: Unsupported worker image: $WORKER_IMAGE${NC}\n" >&2
    printf "${INFO}This tool only supports UDX worker images.${NC}\n" >&2
    echo ""
    list_supported_images
    exit 1
fi

if [[ "$COMMAND" == "null" || -z "$COMMAND" ]]; then
    printf "${ERROR}Error: 'config.command' is required in configuration file${NC}\n" >&2
    exit 1
fi

# Build volumes from config
VOLUMES=""
volume_count=$(yq eval '.config.volumes | length' "$config_file")
for ((i=0; i<volume_count; i++)); do
    volume=$(yq eval ".config.volumes[$i]" "$config_file")
    
    # Extract source and destination paths
    src_path="${volume%%:*}"
    dest_path="${volume#*:}"
    
    # Expand shell variables like $(PWD)
    src_path=$(eval echo "$src_path")
    
    # Convert relative paths to absolute
    if [[ "$src_path" == ./* ]]; then
        src_path="$(pwd)/${src_path#./}"
    elif [[ "$src_path" != /* ]]; then
        # Handle relative paths that don't start with ./
        src_path="$(pwd)/$src_path"
    fi
    
    # Validate that source path exists
    if [[ ! -e "$src_path" ]]; then
        printf "${ERROR}Error: Volume source path does not exist: $src_path${NC}\n" >&2
        exit 1
    fi
    
    # Reconstruct the volume mapping
    volume="$src_path:$dest_path"
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
