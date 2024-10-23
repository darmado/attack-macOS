# Changelog

This file documents all significant changes to the project.

## [Unreleased]

### Added
- ATT&CK Coverage Map generation script (`build_coverage_map.py`)
- Mapping of MITRE ATT&CK techniques for macOS
- Browser history extraction for Safari, Chrome, Firefox, and Brave
- Data exfiltration via HTTP and DNS
- Encoding and encryption functions for output
- Debug logging
- ShellCheck for bash script validation
- ShellCheck binary
- run_shellcheck.sh script

### Changed
- Updated `SecurityToolsCheck` function in security_software.sh
- Enhanced `Discover` function with additional checks
- Improved error handling in scripts
- Modified `parseArguments` function
- Restructured project documentation
- Updated Procedure Index with script links and new columns

### Fixed
- Code signing status reporting
- Error message formatting
- Red Canary Mac Monitor detection in SecurityToolsCheck
- Argument parsing for --help flag

### Removed
- Verbose logging, replaced with debug logging

## [0.1.0] - 2024-09-01

### Added
- Initial project structure
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
