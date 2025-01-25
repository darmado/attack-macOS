# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Pre-release]

### Core Framework & Scripts
| Component | Type | Description |
|-----------|------|-------------|
| attackmacos.sh | Changed | - Optimized banner display logic<br>- Enhanced argument parsing<br>- Improved script execution methods (curl, wget, osascript, local) |
| build_coverage_map.py | Added | - ATT&CK technique table generation<br>- Color-coded implementation status<br>- Technique/procedure coverage statistics<br>- Procedure counts for implemented techniques |
| Utility Functions | Added | - Initial project structure<br>- Core script templates<br>- Utility script template (`utility_functions.sh`)<br>- Standardized script headers |
| Logging System | Changed | - Deprecated verbose logging<br>- Implemented granular debug logging<br>- Centralized logging architecture<br>- Improved error message formatting |

### Browser & Privacy Analysis
| Component | Type | Description |
|-----------|------|-------------|
| safariJXA2.js | Added | - Browser automation core functions<br>- Hidden window support<br>- TCC permission checks<br>- SIP warning system<br>- URL/tab content extraction<br>- Multi-browser operations (mail, SMS, tel)<br>- Screen dimension detection<br>- Modular export system |
| browser_history.sh | Added | - Multi-browser support (Safari, Chrome, Firefox, Brave)<br>- SQLite query implementation<br>- HTTP POST/DNS exfiltration<br>- Multiple encoding methods<br>- Encryption options (AES, Blowfish, GPG) |
| tiktokprivacy.dev.js | Added | - Development environment testing<br>- User profile data extraction<br>- Privacy configuration analysis<br>- Async data collection methods |
| tiktokprivacy.js | Added | - Production deployment<br>- Network traffic inspection<br>- Security control verification<br>- Error boundary protection |
| ttloaded.js | Added | - Load state detection<br>- DOM manipulation safeguards<br>- Memory leak prevention<br>- Runtime performance optimizations |

### Security Tools & Analysis
| Component | Type | Description |
|-----------|------|-------------|
| security_software.sh | Changed | - Enhanced SecurityToolsCheck function<br>- Improved EDR/AV detection<br>- Additional security tool checks<br>- Enhanced Discover function |
| dump_keys.sh | Added | - Keychain analysis capabilities<br>- Secure data extraction<br>- Code signing verification |
| SecurityToolsCheck | Changed | - Red Canary Mac Monitor detection<br>- Improved detection methods<br>- Additional EDR solution checks |

### Documentation & Infrastructure
| Component | Type | Description |
|-----------|------|-------------|
| ShellCheck | Added | - Repository binary integration<br>- Automated validation script<br>- Code quality checks |
| Project Docs | Changed | - Enhanced README.md with usage instructions<br>- Reorganized _DOCS structure<br>- Updated Procedure Index<br>- Added data source documentation |
| YAML Templates | Added | - Script creation templates<br>- Standardized formatting<br>- Utility schema definitions |
| Build System | Added | - Coverage map generation<br>- Automated validation<br>- Performance benchmarks |

### Bug Fixes & Optimizations
| Component | Issue | Resolution |
|-----------|--------|------------|
| Safari Automation | Permission Issues | - Fixed automation permissions<br>- Resolved window visibility<br>- Addressed SIP restrictions<br>- Improved error handling |
| TikTok Analysis | Performance | - Fixed race conditions<br>- Resolved memory leaks<br>- Corrected DOM timing<br>- Enhanced async operations |
| Core Scripts | General | - Fixed code signing reporting<br>- Improved error messages<br>- Resolved file permissions<br>- Enhanced input validation |
| Data Collection | Reliability | - Fixed selector specificity<br>- Improved retry mechanisms<br>- Enhanced error boundaries<br>- Optimized memory usage |

[Pre-release]: https://github.com/yourusername/yourrepository/tree/main
