# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Milestone: Create template scripts for each MITRE ATT&CK technique relevant to macOS

## [0.1.0] - 2024-09-01

### Added
- Initial project structure
- README.md with project overview and quick start guide
- utility.sh template for common functions
- security_software.sh script for discovering security software on macOS
- dump_keys.sh script for simulating keychain credential access
- YAML template for creating new scripts

### Changed
- Updated logging mechanism to use centralized log directory

### Fixed
- Corrected path issues in log file creation

[Unreleased]: https://github.com/armadocorp/attack-macOS/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/armadocorp/attack-macOS/releases/tag/v0.1.0
