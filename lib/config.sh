#!/usr/bin/env bash

load_cli_config() {
    local pkg_dir="$1"
    if [[ -z "$pkg_dir" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        pkg_dir="$(cd "$script_dir/.." && pwd)"
    fi

    local config_file="$pkg_dir/src/configs/cli.env"
    if [[ -f "$config_file" ]]; then
        # shellcheck disable=SC1090
        source "$config_file"
    fi

    : "${UDX_BASE_IMAGE:=usabilitydynamics/udx-worker:latest}"
    : "${UDX_GITHUB_ORG:=udx}"
    : "${UDX_GITHUB_REPO_PREFIX:=worker-}"
    : "${UDX_GITHUB_API_BASE:=https://api.github.com}"
    : "${UDX_GITHUB_SEARCH_REPOS_ENDPOINT:=/search/repositories}"
    : "${UDX_DOCKERHUB_ORG:=usabilitydynamics}"
    : "${UDX_DOCKERHUB_SEARCH_PREFIX:=worker-}"
    : "${UDX_DOCKERHUB_API_BASE:=https://hub.docker.com/v2/repositories}"
    : "${UDX_DOCKERHUB_WEB_BASE:=https://hub.docker.com/r}"
}
