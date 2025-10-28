# Changelog

All notable changes to this project will be documented in this file.

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
