# attack-macOS Development Roadmap

This document outlines the planned features and improvements for the attack-macOS project, targeting the 0.9 release and beyond.

## Status and Priority Keys
| Status | Description |  |   | Priority | Description 
|--------|-------------|-----|-----|--------|-------------|
| 🚀 Planned | Feature is planned but not yet started | ________________| |🔥 High | Critical for 0.9 release |
| 🔧 In Development | Feature is currently being developed | | | 🔶 Medium | Important but not critical |
| ✅ Implemented | Feature is implemented and available | | | 🔷 Low | Nice to have, can be postponed |

## 0.9 Release Roadmap

| Feature | Status | Priority | Description | Technical Details |
|---------|--------|----------|-------------|-------------------|
| MITRE ATT&CK Mapping | 🔧 | 🔥 | Map all scripts to MITRE ATT&CK techniques | Throughout all script files |
| Modular Script Design | 🔧 | 🔥 | Create self-contained, modular scripts | All scripts in `ttp/` directory |
| Utility Functions | 🔧 | 🔥 | Implement common utility functions | `util/_templates/utility_functions.sh` |
| Logging Capability | 🔧 | 🔥 | Consistent logging across all scripts | Implemented in each script |
| Data Encoding Options | 🔧 | 🔥 | Multiple data encoding options | `encode_output()` function |
| Data Encryption | 🔧 | 🔥 | Integrated encryption functions | `encrypt_output()` function |
| Exfiltration | 🔧 | 🔥 | HTTP and DNS exfiltration options | `exfil_http()` and `exfil_dns()` functions |
| Command-line Interface | 🔧 | 🔥 | Consistent CLI across all scripts | Argument parsing in each script |
| Error Handling | 🔧 | 🔥 | Robust error handling and reporting | Throughout all script files |
| Documentation | 🔧 | 🔥 | Comprehensive documentation for all scripts | README.md, inline comments |
| STIX File Generation | 🚀 | 🔥 | Generate basic STIX 2.1 files for each script | New module for STIX 2.1 JSON creation |
| Community Contribution Workflow | 🚀 | 🔥 | Streamline process for community contributions | GitHub templates, contribution guidelines |

## Post 0.9 Release Plans

| Feature | Status | Priority | Description | Technical Details |
|---------|--------|----------|-------------|-------------------|
| Additional Techniques | 🚀 | 🔶 | Implement more MITRE ATT&CK techniques | New scripts in `ttp/` directory |
| macOS Version Compatibility | 🚀 | 🔶 | Ensure compatibility with multiple macOS versions | Version checks in scripts |
| Testing Framework | 🚀 | 🔶 | Implement basic testing for scripts | Planned `tests/` directory |
| Technique Chaining | 🚀 | 🔷 | Allow execution of multiple techniques in sequence | New chaining module |
| STIX File Improvements | 🚀 | 🔶 | Enhance STIX files with more detailed technique information | Update STIX generation module |
| Contribution Validation | 🚀 | 🔶 | Automated checks for contributed scripts | CI/CD pipeline for contributions |

## Contribution Guidelines

To suggest new features or modifications to existing ones:
1. Open an issue on the GitHub repository with the label 'enhancement'
2. Provide a clear description of the feature and its potential benefits
3. If possible, include examples or use cases for the proposed feature

The project maintainers will review suggestions and update this roadmap accordingly.
