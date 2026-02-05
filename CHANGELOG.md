# Changelog

All notable changes to this project will be documented in this file.

## [3.0.2] - 2026-02-05

### Removed

- Removed `gh_token` from npm release workflow

## [3.0.1] - 2026-02-05

### Fixed

- Bump version to 3.0.1 to resolve immutable tag issue

## [3.0.0] - 2026-02-02

### Breaking Changes

- Replaced `worker-config` and `worker-run` binaries with a single `worker` CLI and subcommands.
- Commands now use `worker <subcommand>` (for example, `worker config`, `worker run`).

### Added

- New CLI subcommands: `config`, `run`, `gen`, and `images`.
- Documentation for config/run/gen/images plus deploy configuration and CLI env docs.
- Worker generation templates and repo scaffolding assets.
- CI build and release scripts plus an npm release workflow.

### Changed

- Package entrypoints and release scripts updated for the unified CLI.
- Test harness reorganized with new command coverage.

## [2.5.0] - 2024-12-02

### 🚀 Added - Network and Container Name Support

### Added

- **Network Configuration** - Containers can now be deployed with custom Docker networks
  - Useful for connecting containers to existing networks or using host networking
  - If not specified, Docker uses default bridge network
- **Container Name Configuration** - Containers can now have custom names
  - Specify custom container names via `container_name` field
  - If not specified, Docker auto-generates a random name
  - Useful for container management and inter-container communication

### Enhanced

- **Comprehensive Config Template** - Updated `deploy.yml` template with:
  - All supported configuration options documented
  - Format specifications for volumes, ports, network, and container names
  - Practical examples for each option
  - Clear comments explaining optional vs required fields

### Technical Details

- Added `NETWORK` parsing and formatting with `--network` flag in `deploy.sh`
- Added `CONTAINER_NAME` parsing and formatting with `--name` flag in `deploy.sh`
- Updated `deploy.mk` to include network and container name in docker run commands
- Both `run` and `run-it` targets display network and container name settings
- Added test coverage for both network and container_name configurations

### Benefits

- **Better Networking** - Connect containers to custom networks or use host networking
- **Easier Management** - Named containers are easier to identify and manage
- **Complete Docker Support** - Now supports all common Docker run options
- **Better Documentation** - Config template serves as comprehensive reference

---

## [2.4.0] - 2025-11-04

### 🎯 Enhanced - Added Ports Support

### Changed

- **Ports Parameter now supported** - Containers can now can be deployed with specified ports
  - If `ports` is not specified in `deploy.yml`, the container's default ports will be used

### Technical Details

- Updated `deploy.mk` with conditional logic to only include ports in docker run when present
- Both `run` and `run-it` targets handle empty ports gracefully

### Benefits

- **More Flexible** - Can deploy containers that have their own default ports
- **Better UX** - Clear indication when using container defaults vs custom ports

## [2.3.0] - 2025-10-31

### 🎯 Enhanced - Optional Command Parameter

### Changed

- **Command Parameter Now Optional** - Containers can now run with their default CMD/ENTRYPOINT
  - If `command` is not specified in `deploy.yml`, the container's default command will be used
  - Useful for containers with well-defined default behavior
  - Display shows `<using container default>` when no command is specified
  - Dry-run output correctly reflects whether command is present or using default

### Added

- **New Example** - Added documentation example showing usage without command parameter
- **Enhanced Guidance** - Updated config template and help text to indicate command is optional

### Technical Details

- Removed validation that required `command` field in `deploy.sh`
- Updated `deploy.mk` with conditional logic to only include command in docker run when present
- Both `run` and `run-it` targets handle empty command gracefully
- Config template includes helpful comment explaining optional nature

### Benefits

- **More Flexible** - Can deploy containers that have their own default commands
- **Cleaner Configs** - No need to specify command when container default is sufficient
- **Better UX** - Clear indication when using container defaults vs custom commands

---

## [2.2.0] - 2025-10-30

### 🎯 Enhanced - Simplified Authentication Architecture

### Changed

- **Unified Authentication Approach** - Simplified GCP credential handling by delegating to worker image
  - All credential types (service account keys, workload identity tokens, impersonation) now use single `GCP_CREDS` environment variable
  - Worker's `gcp.sh` module handles credential type detection, normalization, and `GOOGLE_APPLICATION_CREDENTIALS` setup
  - Removed complex dual-variable approach for impersonation
  - Cleaner, more maintainable implementation

### Technical Details

- Simplified `src/providers/gcp.mk` to use unified `GCP_CREDS` variable for all authentication methods
- Worker image now handles all credential normalization (private_key escaping, type detection, etc.)
- Reduced complexity in deployment tool by centralizing auth logic in worker
- Maintains full backward compatibility with all three authentication methods

### Benefits

- **Simpler codebase** - Less authentication logic in deployment tool
- **Single source of truth** - Worker image controls authentication behavior
- **Better maintainability** - Authentication changes only need to happen in worker image
- **Consistent behavior** - All tools using worker get same authentication handling

---

## [2.1.1] - 2025-10-28

### Fixed

- Adjusted environment variable settings and volume mounts for GCP authentication

## [2.1.0] - 2025-10-21

### 🎯 Enhanced - Full Terraform/SDK Support for Impersonation

### Changed

- **Service Account Impersonation** - Now fully compatible with Terraform, SDKs, gcloud CLI, and all Google Cloud client libraries
  - Uses user's Application Default Credentials (ADC) as source for impersonation
  - Generates proper `impersonated_service_account` credential file (official Google format)
  - Sets both `GOOGLE_APPLICATION_CREDENTIALS` (for Terraform/SDKs) and `CLOUDSDK_AUTH_ACCESS_TOKEN` (for gcloud)
  - Dual authentication ensures all tools work seamlessly
  - Eliminates the need for service account key files even when using Terraform

### Added

- **ADC Integration** - Automatically uses `~/.config/gcloud/application_default_credentials.json`
- **Fallback Support** - Falls back to access token if ADC not configured
- **Setup Guidance** - Clear instructions for `gcloud auth application-default login`

### Technical Details

- Creates `impersonated_service_account` type credential file using user's ADC as source
- Mounts credential file as read-only in container
- Passes access token as environment variable for gcloud CLI compatibility
- Follows official Google Cloud authentication best practices
- Token remains valid for 1 hour

---

## [2.0.2] - 2025-10-21

### Fixed

- **Impersonation Error Handling** - Improved error detection and display for gcloud impersonation failures
- Better filtering of WARNING messages from gcloud output

---

## [2.0.1] - 2025-10-21

### Changed

- **README Simplification** - Prioritized impersonation method, merged auth sections, focused on worker examples

---

## [2.0.0] - 2025-10-21

### 🎉 Major Release - Complete Authentication Overhaul

### Added

- **Service Account Impersonation** - Use your gcloud credentials to impersonate service accounts
  - Automatic token generation on host
  - No key files needed
  - Temporary tokens (1 hour validity)
  - Works with gcloud CLI commands
- **Modular Provider System** - Extensible architecture for multiple cloud providers
  - GCP provider with full authentication support
  - Ready for AWS, Azure providers
- **Config-Based Authentication** - Specify custom credential paths in deploy.yml
  - `service_account.key_path` - Custom key file location
  - `service_account.token_path` - Custom token file location
  - `service_account.email` - Service account impersonation
- **Enhanced Error Messages** - Clear, actionable error messages with fix suggestions
- **Improved Security** - Docker commands no longer echo sensitive tokens to terminal

### Changed

- **Authentication Priority** - Clearer credential detection order
  1. Config-specified paths
  2. Default file paths (gcp-key.json, gcp-credentials.json)
  3. Service account impersonation
- **Simplified CLI** - Only 2 commands: `worker-config` and `worker-run`
- **Better Documentation** - Comprehensive README with all authentication methods

### Fixed

- **UID/GID Mismatch** - Resolved permission issues with credential files
- **Token Filtering** - Properly filters gcloud WARNING messages from tokens
- **Error Handling** - Improved error detection and reporting for impersonation

### Technical Improvements

- Modular makefile architecture (src/providers/gcp.mk)
- Automatic credential detection and validation
- Secure token handling (no hardcoded OAuth credentials)
- Read-only credential mounts where appropriate

---

## [1.3.0] - 2025-10-20

### Added

- Dry-run capability with `--dry-run` flag
- Docker and yq availability checking
- Configuration validation for required fields

### Improved

- Enhanced error messages with colors
- Better volume path resolution
- Comprehensive test coverage

---

## [1.0.0] - Initial Release

### Features

- YAML-based configuration
- Docker container execution
- Basic GCP credential mounting
- Volume and environment variable management
