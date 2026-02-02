#!/usr/bin/env bash
set -euo pipefail

# Color constants
WARN='\033[0;33m'
OK='\033[0;32m'
COMMAND='\033[1;36m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
NC='\033[0m'

# Track temp files for cleanup
IMPERSONATE_CREDS_FILE=""
cleanup() {
    if [[ -n "${IMPERSONATE_CREDS_FILE}" ]] && [[ -f "${IMPERSONATE_CREDS_FILE}" ]]; then
        rm -f "${IMPERSONATE_CREDS_FILE}"
    fi
}
trap cleanup EXIT

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

# Function to check if YAML parser is available
check_yaml_parser() {
    if ! command -v node >/dev/null 2>&1; then
        printf "${ERROR}Error: node is required for YAML parsing${NC}\n" >&2
        exit 1
    fi
    if ! node -e "require('yaml')" >/dev/null 2>&1; then
        printf "${ERROR}Error: npm package 'yaml' is required for YAML parsing${NC}\n" >&2
        printf "${INFO}Install with: npm install -g @udx/worker-deployment${NC}\n" >&2
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

# Shell-quote a string for /bin/sh
shell_quote() {
    local value="$1"
    value="${value//\'/\'\\\'\'}"
    printf "'%s'" "$value"
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
PKG_DIR="${SCRIPT_DIR}/../.."

# Resolve makefile
MK="$PKG_DIR/src/make/deploy.mk"

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

# Pass config directory to make for credential detection
config_dir="$(dirname "$config_file")"
make_args+=("CONFIG_DIR=$config_dir")

# Add dry-run flag if specified
if [[ "$dry_run" == true ]]; then
    make_args+=("DRY_RUN=true")
fi

YAML_CLI="${PKG_DIR}/lib/yaml.js"
export NODE_PATH="${PKG_DIR}/node_modules"

# Check dependencies
check_yaml_parser
check_docker

# Auto-copy ADC to gcp-key.json if no credentials exist
# if [[ ! -f "gcp-key.json" ]] && [[ ! -f "gcp-credentials.json" ]]; then
#     ADC_PATH="$HOME/.config/gcloud/application_default_credentials.json"
#     if [[ -f "$ADC_PATH" ]]; then
#         printf "${INFO}No credential files found. Using local ADC...${NC}\n"
#         cp "$ADC_PATH" "gcp-key.json"
#         printf "${OK}✓ Created gcp-key.json from local credentials${NC}\n"
#     fi
# fi

# Verify config file exists
if [[ ! -f "$config_file" ]]; then
    printf "${ERROR}Error: Configuration file not found: $config_file${NC}\n" >&2
    printf "${INFO}Generate a config file with: worker-config${NC}\n" >&2
    exit 1
fi

printf "${INFO}Using configuration: $config_file${NC}\n"
yaml_get() {
    node "$YAML_CLI" get "$1" "$config_file"
}
yaml_length() {
    node "$YAML_CLI" length "$1" "$config_file"
}
yaml_keys() {
    node "$YAML_CLI" keys "$1" "$config_file"
}

# Parse YAML configuration
WORKER_IMAGE=$(yaml_get '.config.image')
COMMAND=$(yaml_get '.config.command')
NETWORK=$(yaml_get '.config.network')
CONTAINER_NAME=$(yaml_get '.config.container_name')

# Parse service account configuration (optional)
SA_KEY_PATH=$(yaml_get '.config.service_account.key_path')
SA_TOKEN_PATH=$(yaml_get '.config.service_account.token_path')
SA_EMAIL=$(yaml_get '.config.service_account.email')
if [[ "$SA_KEY_PATH" == "null" ]]; then SA_KEY_PATH=""; fi
if [[ "$SA_TOKEN_PATH" == "null" ]]; then SA_TOKEN_PATH=""; fi
if [[ "$SA_EMAIL" == "null" ]]; then SA_EMAIL=""; fi

# Validate required fields
if [[ "$WORKER_IMAGE" == "null" || -z "$WORKER_IMAGE" ]]; then
    printf "${ERROR}Error: 'config.image' is required in configuration file${NC}\n" >&2
    exit 1
fi

# Command is optional - if not specified, container will use its default CMD/ENTRYPOINT
if [[ "$COMMAND" == "null" ]]; then
    COMMAND=""
fi

if [[ -n "$COMMAND" ]] && [[ "$COMMAND" =~ [[:space:]] ]]; then
    printf "${WARN}Warning: 'command' contains spaces. Use 'args' for flags/arguments.${NC}\n" >&2
fi

# Network is optional - if not specified, container will use its default network
if [[ "$NETWORK" == "null" || -z "$NETWORK" ]]; then
    NETWORK=""
else
    # Format network with --network flag
    NETWORK="--network $(shell_quote "$NETWORK")"
fi

# Container name is optional - if not specified, Docker will auto-generate a name
if [[ "$CONTAINER_NAME" == "null" || -z "$CONTAINER_NAME" ]]; then
    CONTAINER_NAME=""
else
    # Format container name with --name flag
    CONTAINER_NAME="--name $(shell_quote "$CONTAINER_NAME")"
fi

# Build volumes from config
VOLUMES=""
volume_count=$(yaml_length '.config.volumes')
PWD_CURRENT="$(pwd)"
for ((i=0; i<volume_count; i++)); do
    volume=$(yaml_get ".config.volumes[$i]")
    if [[ "$volume" == "null" || -z "$volume" ]]; then
        continue
    fi
    
    # Extract source and destination paths
    src_path="${volume%%:*}"
    dest_path="${volume#*:}"
    
    # Expand simple tokens only (avoid eval for safety)
    src_path="${src_path/#\~/$HOME}"
    src_path="${src_path//\$HOME/$HOME}"
    src_path="${src_path//\$\{HOME\}/$HOME}"
    src_path="${src_path//\$PWD/$PWD_CURRENT}"
    src_path="${src_path//\$\{PWD\}/$PWD_CURRENT}"
    
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
    VOLUMES="$VOLUMES -v $(shell_quote "$volume")"
done

# Build environment variables from config
ENV_VARS=""
env_count=$(yaml_length '.config.env')
if [[ "$env_count" != "0" ]]; then
    env_keys=$(yaml_keys '.config.env')
    while IFS= read -r key; do
        if [[ -n "$key" ]]; then
            value=$(yaml_get ".config.env.$key")
            ENV_VARS="$ENV_VARS -e $(shell_quote "$key=$value")"
        fi
    done <<< "$env_keys"
fi

# Parse ports from config
PORTS=""
port_count=$(yaml_length '.config.ports')
for ((i=0; i<port_count; i++)); do
    port=$(yaml_get ".config.ports[$i]")
    PORTS="$PORTS -p $(shell_quote "$port")"
done

# Build arguments from config
ARGS=""
args_count=$(yaml_length '.config.args')
for ((i=0; i<args_count; i++)); do
    arg=$(yaml_get ".config.args[$i]")
    ARGS="$ARGS $(shell_quote "$arg")"
done

# Add parsed values to make_args
make_args+=("WORKER_IMAGE=$WORKER_IMAGE")
make_args+=("COMMAND=$COMMAND")
make_args+=("VOLUMES=$VOLUMES")
make_args+=("ENV_VARS=$ENV_VARS")
make_args+=("PORTS=$PORTS")
make_args+=("NETWORK=$NETWORK")
make_args+=("CONTAINER_NAME=$CONTAINER_NAME")
make_args+=("ARGS=$ARGS")

# Pass service account config to make
if [[ -n "$SA_KEY_PATH" ]]; then
    make_args+=("GCP_SA_KEY_PATH=$SA_KEY_PATH")
fi
if [[ -n "$SA_TOKEN_PATH" ]]; then
    make_args+=("GCP_SA_TOKEN_PATH=$SA_TOKEN_PATH")
fi
if [[ -n "$SA_EMAIL" ]]; then
    # Verify gcloud is available for impersonation
    if ! command -v gcloud >/dev/null 2>&1; then
        printf "${ERROR}Error: gcloud CLI is required for service account impersonation${NC}\n" >&2
        printf "${INFO}Install: brew install google-cloud-sdk${NC}\n" >&2
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
        printf "${ERROR}Error: No active gcloud authentication found${NC}\n" >&2
        printf "${INFO}Run: gcloud auth login${NC}\n" >&2
        exit 1
    fi
    
    printf "${INFO}Generating impersonation credentials for: $SA_EMAIL${NC}\n"
    
    # Generate ADC credentials file via impersonation
    # This creates a proper credential file that works with Terraform, SDKs, and gcloud
    IMPERSONATE_CREDS_FILE="/tmp/worker-gcp-impersonate-$$.json"
    
    # Use gcloud to generate ADC credentials with impersonation
    # This is the official Google-recommended approach for Terraform
    set +e  # Temporarily disable exit on error
    GCLOUD_OUTPUT=$(gcloud auth application-default print-access-token --impersonate-service-account="$SA_EMAIL" 2>&1)
    GCLOUD_EXIT_CODE=$?
    
    # If application-default command fails, fall back to creating ADC file manually
    if [[ $GCLOUD_EXIT_CODE -ne 0 ]]; then
        # Generate access token for fallback
        GCLOUD_OUTPUT=$(gcloud auth print-access-token --impersonate-service-account="$SA_EMAIL" 2>&1)
        GCLOUD_EXIT_CODE=$?
    fi
    set -e  # Re-enable exit on error
    
    # Extract the token (first line that looks like a token - starts with ya29)
    ACCESS_TOKEN=$(echo "$GCLOUD_OUTPUT" | grep -E '^ya29\.' | head -1 || true)
    
    # Check if output contains ERROR
    HAS_ERROR=$(echo "$GCLOUD_OUTPUT" | grep -c "^ERROR:" || true)
    
    if [[ $GCLOUD_EXIT_CODE -ne 0 ]] || [[ -z "$ACCESS_TOKEN" ]] || [[ $HAS_ERROR -gt 0 ]]; then
        printf "${ERROR}Error: Failed to impersonate service account: $SA_EMAIL${NC}\n" >&2
        printf "${ERROR}Exit code: $GCLOUD_EXIT_CODE${NC}\n" >&2
        printf "\n${ERROR}gcloud output:${NC}\n" >&2
        echo "$GCLOUD_OUTPUT" | grep -v "^WARNING:" >&2
        printf "\n${INFO}Possible causes:${NC}\n" >&2
        printf "  1. You don't have roles/iam.serviceAccountTokenCreator permission\n" >&2
        printf "  2. Service account doesn't exist\n" >&2
        printf "  3. Not authenticated with gcloud\n" >&2
        printf "\n${INFO}To fix, run this 
        :${NC}\n" >&2
        SA_PROJECT="${SA_EMAIL#*@}"
        SA_PROJECT="${SA_PROJECT%%.*}"
        printf "  gcloud iam service-accounts add-iam-policy-binding \\\\\n" >&2
        printf "    $SA_EMAIL \\\\\n" >&2
        printf "    --member=\"user:\$(gcloud config get-value account)\" \\\\\n" >&2
        printf "    --role=\"roles/iam.serviceAccountTokenCreator\" \\\\\n" >&2
        printf "    --project=$SA_PROJECT\n" >&2
        exit 1
    fi
    
    # Verify we got a valid token
    if [[ -z "$ACCESS_TOKEN" ]] || [[ "$ACCESS_TOKEN" == ERROR* ]] || [[ "$ACCESS_TOKEN" == *"ERROR"* ]]; then
        printf "${ERROR}Error: Invalid token received from gcloud${NC}\n" >&2
        printf "${ERROR}${ACCESS_TOKEN}${NC}\n" >&2
        exit 1
    fi
    
    printf "${OK}✓ Generated impersonation credentials${NC}\n"
    
    # Get user's ADC file to use as source credentials
    USER_ADC_FILE="$HOME/.config/gcloud/application_default_credentials.json"
    
    if [[ -f "$USER_ADC_FILE" ]]; then
        # Create impersonated service account credentials using user's ADC
        # This is the proper format that Terraform expects
        printf "${INFO}Using ADC from: $USER_ADC_FILE${NC}\n"
        
        # Read the user's ADC credentials
        SOURCE_CREDS=$(cat "$USER_ADC_FILE")
        
        # Create impersonated service account credential file
        cat > "$IMPERSONATE_CREDS_FILE" <<EOF
{
  "delegates": [],
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/$SA_EMAIL:generateAccessToken",
  "source_credentials": $SOURCE_CREDS,
  "type": "impersonated_service_account"
}
EOF
    else
        # Fallback: User doesn't have ADC, just use access token
        printf "${WARN}No ADC file found, using access token only${NC}\n"
        printf "${INFO}For full Terraform compatibility, run: gcloud auth application-default login${NC}\n"
        
        # Create a simple credential file with just the access token
        # This works for some operations but may fail for others
        cat > "$IMPERSONATE_CREDS_FILE" <<EOF
{
  "type": "authorized_user",
  "client_id": "764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com",
  "client_secret": "d-FL95Q19q7MQmFpd7hHD0Ty",
  "refresh_token": "",
  "access_token": "$ACCESS_TOKEN"
}
EOF
    fi
    
    # Pass both the credentials file and access token to make
    make_args+=("GCP_IMPERSONATE_CREDS_FILE=$IMPERSONATE_CREDS_FILE")
    make_args+=("GCP_IMPERSONATE_ACCESS_TOKEN=$ACCESS_TOKEN")
fi

# Pass everything through to make
exec "$MAKE_BIN" -f "$MK" "${make_args[@]}" "$target"
