# Changelog

This file documents all significant changes to the project.

## [Unreleased]

### Added
- Template scripts for MITRE ATT&CK macOS techniques
- CSSM error code reference in swiftbelt.js
- Functions for code signing checks:
  - `checkCodeSigningAPI`
  - `checkAppCodeSigning`
  - `checkAllAppsCodeSigning`
- Debug logging
- ShellCheck for bash script validation
- ShellCheck binary in repository
- run_shellcheck.sh script

### Changed
- Improved `SecurityToolsCheck` function
- Updated `Discover` function with code signing checks
- Modified `parseArguments` function
- Enhanced error handling in code signing checks

### Fixed
- Code signing status reporting
- Error message formatting
- Red Canary Mac Monitor detection in SecurityToolsCheck
- Improved argument parsing to properly handle --help flag

## [0.1.0] - 2024-09-01

### Added
- Project structure
- README.md with overview and guide
- utility.sh template
- security_software.sh script
- dump_keys.sh script
- YAML template for new scripts

### Changed
- Centralized log directory

### Fixed
- Log file creation paths

[Unreleased]: https://github.com/armadocorp/attack-macOS/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/armadocorp/attack-macOS/releases/tag/v0.1.0
