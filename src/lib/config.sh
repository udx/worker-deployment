#!/bin/bash

# Worker Deploy - Config Generator
# Generates YAML configuration templates

set -e

# Color constants
WARN='\033[0;33m'
OK='\033[0;32m'
COMMAND='\033[1;36m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
NC='\033[0m'

# Default values
OUTPUT_FILE="deploy.yml"

# Process command line arguments
for arg in "$@"; do
    case $arg in
        --output=*) OUTPUT_FILE="${arg#*=}" ;;
        --help)
            echo "Usage: $0 [--output=filename]"
            echo ""
            echo "Options:"
            echo "  --output=FILE     Output config file (default: deploy.yml)"
            echo "  --help           Show this help"
            echo ""
            echo "Generates a YAML configuration template for worker deployment."
            exit 0
        ;;
        *)
            echo "Unknown argument: $arg"
            echo "Use --help for usage information"
            exit 1
        ;;
    esac
done

printf "${INFO}Generating config template: $OUTPUT_FILE${NC}\n"

if [ -f "$OUTPUT_FILE" ]; then
    printf "${WARN}Config file already exists: $OUTPUT_FILE${NC}\n"
    read -p "Overwrite existing file? [yN]: " REPLY
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Try to use the bundled template first
# Resolve symlinks to get the actual script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../configs/deploy.yml"

if [ -f "$TEMPLATE_FILE" ]; then
    cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
else
    printf "${ERROR}Error: Bundled template not found at $TEMPLATE_FILE${NC}\n"
    printf "${ERROR}This indicates a packaging issue. Please report this bug.${NC}\n"
    exit 1
fi

printf "${OK}Config template created: $OUTPUT_FILE${NC}\n"
printf "${INFO}Next steps:${NC}\n"
printf "1. Edit $OUTPUT_FILE with your deployment details:\n"
printf "   - Update the 'image' field with your Docker image\n"
printf "   - Configure 'volumes' to mount your files\n"
printf "   - Set your 'command' to run in the container\n"
printf "   - Add any needed environment variables\n"
printf "2. Test your configuration: worker-deploy-run --dry-run\n"
printf "3. Run your deployment: worker-deploy-run\n"
printf "\n"
printf "${INFO}💡 Tip: Use 'worker-deploy-run run-it' for interactive debugging${NC}\n"
