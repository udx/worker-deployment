#!/usr/bin/env bash
set -euo pipefail

# Worker Deploy - Images CLI

WARN='\033[0;33m'
OK='\033[0;32m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
NC='\033[0m'

show_help() {
    echo "Usage: worker-images [options]"
    echo ""
    echo "Options:"
    echo "  --github            Search GitHub org:udx for repos matching worker-"
    echo "  --dockerhub         Search Docker Hub usabilitydynamics for images matching worker-"
    echo "  --all               Search all sources (default)"
    echo "  --limit=N           Max results per source (default: 50)"
    echo "  --output=FILE       Write results to file (default: stdout)"
    echo "  --apply, --yes      Apply file write without prompt"
    echo "  --help              Show this help"
    echo ""
    echo "Notes:"
    echo "  - Private GitHub repos require GITHUB_TOKEN or gh auth."
    echo "  - Private Docker Hub images require DOCKERHUB_TOKEN or docker login credentials."
}

APPLY=false
OUTPUT_FILE=""
LIMIT=50
SRC_GH=false
SRC_DH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --github) SRC_GH=true ;;
        --dockerhub) SRC_DH=true ;;
        --all) SRC_GH=true; SRC_DH=true ;;
        --limit=*) LIMIT="${1#*=}" ;;
        --output=*) OUTPUT_FILE="${1#*=}" ;;
        --apply|--yes) APPLY=true ;;
        --help|-h) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [[ "$SRC_GH" == "false" && "$SRC_DH" == "false" ]]; then
    SRC_GH=true
    SRC_DH=true
fi

PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    printf "${ERROR}python is required for JSON parsing.${NC}\n" >&2
    exit 1
fi

results=""

fetch_github() {
    local gh_json=""
    if command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
        gh_json="$(gh repo list udx --limit "$LIMIT" --json name,visibility,description,url)"
        gh_json="$($PYTHON_BIN - <<'PY' "$gh_json"
import json, sys
data = json.loads(sys.argv[1])
items = [r for r in data if "worker-" in r.get("name","")]
print(json.dumps(items))
PY
)"
    else
        local token="${GITHUB_TOKEN:-}"
        local per_page="$LIMIT"
        if [[ "$per_page" -gt 100 ]]; then per_page=100; fi
        local url="https://api.github.com/search/repositories?q=org:udx+worker-+in:name&per_page=${per_page}"
        if [[ -n "$token" ]]; then
            gh_json="$(curl -sS -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${token}" "$url")"
        else
            gh_json="$(curl -sS -H "Accept: application/vnd.github+json" "$url")"
        fi
    fi

    $PYTHON_BIN - <<'PY' "$gh_json"
import json, sys
raw = sys.argv[1]
if not raw.strip():
    sys.exit(0)
data = json.loads(raw)
if isinstance(data, list):
    items = data
else:
    items = data.get("items", [])
for item in items:
    name = item.get("name","")
    url = item.get("html_url") or item.get("url") or ""
    vis = item.get("visibility") or item.get("private") and "private" or "public"
    if name and "worker-" in name:
        print(f"github: {name} [{vis}] - {url}")
PY
}

decode_docker_auth() {
    local auth="$1"
    if [[ -z "$auth" ]]; then
        return 1
    fi
    printf "%s" "$auth" | base64 -d 2>/dev/null || return 1
}

fetch_dockerhub() {
    local url="https://hub.docker.com/v2/repositories/usabilitydynamics/?page_size=${LIMIT}&name=worker-"
    local dh_json=""
    if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
        dh_json="$(curl -sS -H "Authorization: Bearer ${DOCKERHUB_TOKEN}" "$url")"
    else
        local cfg="${HOME}/.docker/config.json"
        local auth=""
        if [[ -f "$cfg" ]]; then
            auth="$($PYTHON_BIN - <<'PY' "$cfg"
import json, sys
path = sys.argv[1]
with open(path, 'r') as f:
    data = json.load(f)
auths = data.get("auths", {})
for key in ["https://index.docker.io/v1/", "https://registry-1.docker.io/v1/"]:
    if key in auths and "auth" in auths[key]:
        print(auths[key]["auth"])
        break
PY
)"
        fi
        if [[ -n "$auth" ]]; then
            local creds
            creds="$(decode_docker_auth "$auth" || true)"
            if [[ -n "$creds" ]]; then
                dh_json="$(curl -sS -u "$creds" "$url")"
            else
                dh_json="$(curl -sS "$url")"
            fi
        else
            dh_json="$(curl -sS "$url")"
        fi
    fi

    $PYTHON_BIN - <<'PY' "$dh_json"
import json, sys
raw = sys.argv[1]
if not raw.strip():
    sys.exit(0)
data = json.loads(raw)
items = data.get("results", [])
for item in items:
    name = item.get("name","")
    if "worker-" not in name:
        continue
    private = item.get("is_private", False)
    vis = "private" if private else "public"
    url = item.get("repo_url") or item.get("url") or ""
    print(f"dockerhub: {name} [{vis}] - {url}")
PY
}

if [[ "$SRC_GH" == "true" ]]; then
    results+=$(fetch_github || true)
    results+=$'\n'
fi
if [[ "$SRC_DH" == "true" ]]; then
    results+=$(fetch_dockerhub || true)
    results+=$'\n'
fi

results="$(printf "%s" "$results" | sed '/^[[:space:]]*$/d')"

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "$results"
    exit 0
fi

if [[ "$APPLY" != "true" ]]; then
    echo "$results"
    echo ""
    printf "Write results to %s? [y/N]: " "$OUTPUT_FILE"
    read -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

printf "%s\n" "$results" > "$OUTPUT_FILE"
printf "${OK}Wrote results to: %s${NC}\n" "$OUTPUT_FILE"
