# Changelog

All notable changes to this project will be documented in this file.

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
