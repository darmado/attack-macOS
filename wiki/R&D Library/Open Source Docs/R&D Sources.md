# R& D Sources

This document provides a list of R&D sources used for macOS security research required to build the Attack MacOS project.

##  Tools
External tools were integrated through porting, modification, referencing, or direct embedding, based on the Attack-MacOS objctives and specific use cases.

| Tactic | Tool/Resource | Author | Description | URL | License |
|--------|---------------|--------|-------------|-----|---------|
| Collection | mac-monitor | Red Canary | Monitor macOS systems | [GitHub](https://github.com/redcanaryco/mac-monitor) | [MIT License](https://github.com/redcanaryco/mac-monitor/blob/main/LICENSE) |
| Credential Access | LockSmith | its-a-feature | Interact with macOS Keychain | [GitHub](https://github.com/its-a-feature/LockSmith/) | [BSD 3-Clause License](https://github.com/its-a-feature/LockSmith/blob/master/LICENSE) |
| Defense Evasion | Black Hat USA 2018 - macOS Mojave Privacy Protections Bypass | N/A | Bypass macOS Mojave privacy protections | [YouTube](https://www.youtube.com/watch?v=Q0weonGWwKY) | N/A |
| Discovery | Apple EndpointSecurity Documentation | Apple | EndpointSecurity framework docs | [Developer Site](https://developer.apple.com/documentation/endpointsecurity) | N/A |
| Execution | XNU Syscalls | Apple | XNU kernel syscalls list | [Source](https://opensource.apple.com/source/xnu/xnu-1504.3.12/bsd/kern/syscalls.master) | N/A |
| Execution | Security Tool Source | Apple | macOS security tools source code | [Source](https://opensource.apple.com/source/Security/Security-59754.80.3/SecurityTool/macOS/) | N/A |
| Initial Access | Mystikal | D00MFist | Build initial access payloads | [GitHub](https://github.com/D00MFist/Mystikal) | [MIT License](https://github.com/D00MFist/Mystikal/blob/main/LICENSE) |
| Persistence | PersistentJXA | D00MFist | macOS persistence using JXA | [GitHub](https://github.com/D00MFist/PersistentJXA) | [MIT License](https://github.com/D00MFist/PersistentJXA/blob/main/LICENSE) |
| Privilege Escalation | macOS TCC.db Deep Dive | Rainforest QA | Analysis of macOS TCC.db file | [Blog Post](https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive) | N/A |
| Reconnaissance | Reverse Engineering Mac OS X | N/A | IEEE paper on macOS reverse engineering | [IEEE](https://ieeexplore.ieee.org/document/8367774/figures#figures) | N/A |
| Resource Development | sql.js | sql.js contributors | SQLite in JavaScript | [GitHub](https://github.com/sql-js/) | [MIT License](https://github.com/sql-js/sql.js/blob/master/LICENSE) |
| Tool | ShellCheck | Vidar Holen | Static analysis for shell scripts | [GitHub](https://github.com/koalaman/shellcheck) | [GNU General Public License v3.0](https://github.com/koalaman/shellcheck/blob/master/LICENSE) |
| Tool | macOS Security Compliance Project | NIST | DISA macOS security guidance | [GitHub](https://github.com/usnistgov/macos_security) | [Public Domain](https://github.com/usnistgov/macos_security/blob/main/LICENSE.md) |


##

## R&D Security
This table lists key tools and resources for macOS security research and development.

| Topic | Tool/Resource | Author | Description | URL | License |
|--------|---------------|--------|-------------|-----|---------|
| Endpoint Security | Objective-See Tools | Patrick Wardle | Free macOS security tools | [Website](https://objective-see.com/products.html) | N/A |
| MacOS Internals | MacOSX-SDKs | phracker | Mac OS X SDKs archive | [GitHub](https://github.com/phracker/MacOSX-SDKs/) | [BSD 3-Clause License](https://github.com/phracker/MacOSX-SDKs/blob/master/LICENSE) |
| App and Environment | UIKit Documentation | Apple | Documentation for UIKit framework | [Website](https://developer.apple.com/documentation/uikit/app_and_environment) | N/A |
| Security | cssmerr.h | Apple | Open source security error codes | [Source](https://opensource.apple.com/source/Security/Security-57336.1.9/OSX/libsecurity_cssm/lib/cssmerr.h.auto.html) | N/A |
| Security | Security Framework | Apple | Documentation for Security framework | [Website](https://developer.apple.com/documentation/security) | N/A |
| Securiry | macOS TCC.db Deep Dive | Rainforest QA | Analysis of macOS TCC.db file | [Blog Post](https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive) | N/A |
| MacOS Internals | macOS Privacy Preferences | Kevin Conner | List of macOS privacy preference identifiers | [GitHub Gist](https://gist.github.com/kconner/cff08fe3e0bb857ea33b47d965b3e19f) | N/A |

