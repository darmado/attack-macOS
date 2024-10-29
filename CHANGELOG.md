# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- ATT&CK Coverage Map generation script (`build_coverage_map.py`)
  - Generates a comprehensive markdown table of MITRE ATT&CK techniques for macOS
  - Uses color-coded badges to indicate implementation status (red, yellow, green)
  - Includes procedure counts for implemented techniques
  - Provides statistics on technique and procedure coverage
- Browser history extraction functionality in `browser_history.sh`
  - Added support for Safari, Chrome, Firefox, and Brave browsers
  - Implemented SQLite queries for each browser's history database
- Data exfiltration capabilities in `browser_history.sh`
  - Added HTTP POST exfiltration method
  - Added DNS query exfiltration method
- Encoding and encryption functions in `browser_history.sh`
  - Implemented various encoding methods (base64, hex, uuencode, perl_b64, perl_utf8)
  - Added encryption options (AES, Blowfish, GPG)
- Debug logging functionality across multiple scripts
- ShellCheck integration for bash script validation
  - Added ShellCheck binary to the repository
  - Implemented `run_shellcheck.sh` script for automated validation

### Changed
- Updated `SecurityToolsCheck` function in `security_software.sh`
  - Improved detection methods for various security tools
  - Added checks for additional EDR and antivirus solutions
- Enhanced `Discover` function in multiple scripts with more comprehensive checks
- Improved error handling and input validation across all scripts
- Modified `parseArguments` function for better flexibility and robustness
- Restructured project documentation
  - Updated README.md with more detailed usage instructions
  - Reorganized `_DOCS` folder structure
- Updated Procedure Index (`_DOCS/Procedures/Procedure Index.md`)
  - Added links to actual scripts in the repository
  - Included new columns for Data Source, Data Component, and Detections
- Refactored `browser_history.sh` to use functions for each browser query
- Improved code comments and documentation within scripts

### Fixed
- Corrected code signing status reporting in various scripts
- Improved error message formatting for better readability
- Fixed Red Canary Mac Monitor detection in `SecurityToolsCheck` function
- Resolved issues with argument parsing, particularly for the --help flag
- Addressed potential file permission issues in scripts accessing system files

### Removed
- Deprecated verbose logging in favor of more granular debug logging
- Removed outdated and unused functions from legacy scripts

## [0.1.0] - 2024-03-20

### Added
- Initial project structure and core scripts
- Basic README.md with project overview and usage guide
- Utility script template (`utility_functions.sh`)
- Security software discovery script (`security_software.sh`)
- Keychain dumping script (`dump_keys.sh`)
- YAML template for creating new scripts

### Changed
- Implemented centralized logging system
- Standardized script headers and naming conventions

### Fixed
- Resolved issues with log file creation paths

[Unreleased]: https://github.com/yourusername/yourrepository/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/yourrepository/releases/tag/v0.1.0
