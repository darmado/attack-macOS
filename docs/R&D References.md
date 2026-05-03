# R&D Sources

Reference material used when designing and validating macOS procedures for attack-macOS (techniques, tooling behavior, and detection context).

## How we use these sources for new TTPs

1. **Map to MITRE ATT&CK** — Pick or confirm a technique ID on [Enterprise ATT&CK / macOS](https://attack.mitre.org/matrices/enterprise/macos/) and write the `intent` so it matches the technique definition.
2. **Prefer native execution** — Procedures should run with macOS-built-in binaries (LOLBins) only at runtime. Python (`pyyaml`, `jsonschema`) and similar dependencies are **build-time** for YAML validation and script generation, not for executing the technique on target hosts.
3. **Trace provenance** — Add links under each procedure’s `resources:` in YAML when possible (MITRE page, LOOBins, vendor blog, Atomic test ID, etc.). This file is the **cross-cutting** bibliography; procedure YAML carries **per-TTP** citations.
4. **Third-party playbooks** — Projects such as [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) and [Caldera](https://github.com/mitre/caldera) are used for **ideas and alignment**, not as runtime dependencies. When an upstream atomic uses a downloaded tool, we **re-express** the behavior with native macOS commands in YAML where feasible.
5. **Community catalogs** — Sites like [LOOBins](https://www.loobins.io/) and curated defaults lists (for example [macos-defaults.com](https://macos-defaults.com/)) inform **command choice** and domains; they are not authoritative for MITRE mapping without cross-checking ATT&CK.

### Trusted / recurring upstreams (summary)

| Kind | Role |
|------|------|
| [MITRE ATT&CK](https://attack.mitre.org/) | Technique IDs, tactics, and procedure descriptions |
| [MITRE Caldera](https://github.com/mitre/caldera) | Adversary emulation; this repo can **sync** built abilities via `python3 cicd/build/build_shell_procedure.py --sync-caldera` |
| [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) | Large catalog of tests; macOS atomics are **reference** for parity checks |
| Independent macOS security blogs (e.g. [Objective-See](https://objective-see.com/blog.html), vendor research) | Real-world behavior and detection notes |
| [LOOBins](https://www.loobins.io/) | Native binary usage and argument patterns |

### Future: upstream change monitoring (idea)

A small **maintainer tool** could periodically fetch release feeds or API data from ATT&CK, Atomic Red Team (macOS paths), and LOOBins, then diff against local technique coverage (for example `attackmacos/core/config/*.yml`). That would flag **new or updated** upstream content for human review—**not** auto-add TTPs without validation.

## Tools and Research by MITRE ATT&CK Tactic

External tools were integrated through porting, modification, referencing, or direct embedding, based on Attack-MacOS objectives and specific use cases.

| Tactic | Tool/Resource | Author | Description | URL | License |
|--------|---------------|--------|-------------|-----|---------|
| Collection | mac-monitor | Red Canary | Monitor macOS systems | [GitHub](https://github.com/redcanaryco/mac-monitor) | [MIT License](https://github.com/redcanaryco/mac-monitor/blob/main/LICENSE) |
| Collection | Red Canary Mac Application Bundles | Red Canary | Application security research | [Blog](https://redcanary.com/blog/threat-detection/mac-application-bundles/) | N/A |
| Credential Access | LockSmith | its-a-feature | Interact with macOS Keychain | [GitHub](https://github.com/its-a-feature/LockSmith/) | [BSD 3-Clause License](https://github.com/its-a-feature/LockSmith/blob/master/LICENSE) |
| Credential Access | macOS ATT&CK Dataset - Keychain Dumping | sbousseaden | Credential access techniques | [GitHub](https://github.com/sbousseaden/macOS-ATTACK-DATASET/blob/main/Credential%20Access/credaccess_keychain_dumping_security.json) | N/A |
| Defense Evasion | Black Hat USA 2018 - macOS Mojave Privacy Protections Bypass | N/A | Bypass macOS Mojave privacy protections | [YouTube](https://www.youtube.com/watch?v=Q0weonGWwKY) | N/A |
| Defense Evasion | How Offensive Actors Use AppleScript for Attacking macOS | SentinelOne | AppleScript attack techniques | [Blog](https://www.sentinelone.com/blog/how-offensive-actors-use-applescript-for-attacking-macos/) | N/A |
| Discovery | Apple EndpointSecurity Documentation | Apple | EndpointSecurity framework docs | [Developer Site](https://developer.apple.com/documentation/endpointsecurity) | N/A |
| Discovery | Built-in macOS Security Tools | Huntress | Native macOS security tools | [Blog](https://www.huntress.com/blog/built-in-macos-security-tools) | N/A |
| Execution | XNU Syscalls | Apple | XNU kernel syscalls list | [Source](https://opensource.apple.com/source/xnu/xnu-1504.3.12/bsd/kern/syscalls.master) | N/A |
| Execution | Security Tool Source | Apple | macOS security tools source code | [Source](https://opensource.apple.com/source/Security/Security-59754.80.3/SecurityTool/macOS/) | N/A |
| Initial Access | Mystikal | D00MFist | Build initial access payloads | [GitHub](https://github.com/D00MFist/Mystikal) | [MIT License](https://github.com/D00MFist/Mystikal/blob/main/LICENSE) |
| Initial Access | macOS Red Teaming Guide | Red Team Guides | Red teaming techniques | [Blog](https://blog.redteamguides.com/p/macos-red-teaming) | N/A |
| Persistence | PersistentJXA | D00MFist | macOS persistence using JXA | [GitHub](https://github.com/D00MFist/PersistentJXA) | [MIT License](https://github.com/D00MFist/PersistentJXA/blob/main/LICENSE) |
| Privilege Escalation | macOS TCC.db Deep Dive | Rainforest QA | Analysis of macOS TCC.db file | [Blog Post](https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive) | N/A |
| Privilege Escalation | A Deep Dive into Penetration Testing of macOS Applications | CyberArk | macOS application pentesting | [Blog](https://www.cyberark.com/resources/threat-research-blog/a-deep-dive-into-penetration-testing-of-macos-applications-part-1) | N/A |
| Reconnaissance | Reverse Engineering Mac OS X | N/A | IEEE paper on macOS reverse engineering | [IEEE](https://ieeexplore.ieee.org/document/8367774/figures#figures) | N/A |
| Resource Development | sql.js | sql.js contributors | SQLite in JavaScript | [GitHub](https://github.com/sql-js/) | [MIT License](https://github.com/sql-js/sql.js/blob/master/LICENSE) |

## General Security Research and Frameworks

| Topic | Tool/Resource | Author | Description | URL | License |
|--------|---------------|--------|-------------|-----|---------|
| Application Security | Abusing Slack for Offensive Operations | SpecterOps | Slack security research | [Blog](https://posts.specterops.io/abusing-slack-for-offensive-operations-2343237b9282) | N/A |
| Application Security | SlackPirate | emtunc | Slack security tool | [GitHub](https://github.com/emtunc/SlackPirate/tree/master) | N/A |
| Application Security | SmartProxy | salarcode | Proxy management tool | [GitHub](https://github.com/salarcode/SmartProxy) | N/A |
| Application Security | Electroniz3r | r3ggi | Electron application security tool | [GitHub](https://github.com/r3ggi/electroniz3r/tree/main) | N/A |
| Endpoint Security | Objective-See Tools | Patrick Wardle | Free macOS security tools | [Website](https://objective-see.com/products.html) | N/A |
| Frameworks | MITRE ATT&CK for macOS | MITRE Corporation | ATT&CK matrix for macOS | [Website](https://attack.mitre.org/matrices/enterprise/macos/) | N/A |
| Frameworks | macOS ATT&CK Navigator | MITRE Corporation | ATT&CK technique navigator | [Website](https://mitre-attack.github.io/attack-navigator/) | N/A |
| Frameworks | NIST macOS Security | NIST | macOS security guidance | [GitHub](https://github.com/usnistgov/macos_security/tree/main) | [Public Domain](https://github.com/usnistgov/macos_security/blob/main/LICENSE.md) |
| Frameworks | OWASP Mobile Security Testing Guide | OWASP | Mobile security testing framework | [GitHub](https://github.com/OWASP/owasp-mstg) | N/A |
| Incident Response | The DFIR Report | The DFIR Report | Incident response case studies | [Website](https://thedfirreport.com/) | N/A |
| Living Off The Land | Loobins.io | N/A | macOS living off the land binaries | [Website](https://www.loobins.io/) | N/A |
| MacOS Internals | MacOSX-SDKs | phracker | Mac OS X SDKs archive | [GitHub](https://github.com/phracker/MacOSX-SDKs/) | [BSD 3-Clause License](https://github.com/phracker/MacOSX-SDKs/blob/master/LICENSE) |
| MacOS Internals | UIKit Documentation | Apple | Documentation for UIKit framework | [Website](https://developer.apple.com/documentation/uikit/app_and_environment) | N/A |
| MacOS Internals | macOS Privacy Preferences | Kevin Conner | macOS privacy preference identifiers | [GitHub Gist](https://gist.github.com/kconner/cff08fe3e0bb857ea33b47d965b3e19f) | N/A |
| Security | cssmerr.h | Apple | Open source security error codes | [Source](https://opensource.apple.com/source/Security/Security-57336.1.9/OSX/libsecurity_cssm/lib/cssmerr.h.auto.html) | N/A |
| Security | Security Framework | Apple | Documentation for Security framework | [Website](https://developer.apple.com/documentation/security) | N/A |
| Security | macOS Security Documentation | Apple | Official macOS security guide | [Website](https://support.apple.com/guide/security/welcome/1/web/1) | N/A |
| Security | macOS Security Updates | Apple | Security update information | [Website](https://support.apple.com/en-us/HT201222) | N/A |
| Threat Intelligence | MacRansom | Check Point Research | MacRansom malware analysis | [Website](https://macos.checkpoint.com/families/MacRansom/) | N/A |
| Threat Intelligence | macOS Malware Analysis | Objective-See | macOS malware research | [Blog](https://objective-see.com/blog.html) | N/A |
| Threat Intelligence | Unit 42 XAgentOSX Analysis | Palo Alto Networks | XAgentOSX malware analysis | [Blog](https://unit42.paloaltonetworks.com/unit42-xagentosx-sofacys-xagent-macos-tool/) | N/A |
| Threat Intelligence | LightSpy Malware Analysis | Huntress | LightSpy malware variant analysis | [Blog](https://www.huntress.com/blog/lightspy-malware-variant-targeting-macos) | N/A |
| Tool | ShellCheck | Vidar Holen | Static analysis for shell scripts | [GitHub](https://github.com/koalaman/shellcheck) | [GNU General Public License v3.0](https://github.com/koalaman/shellcheck/blob/master/LICENSE) |
| Tool | macOS Security Tools | ashishb | Awesome macOS security tools collection | [GitHub](https://github.com/ashishb/osx-and-ios-security-awesome) | N/A |
| Tool | macOS Security Scripts | 0xmachos | macOS security scripts collection | [GitHub](https://github.com/0xmachos/mOSL) | N/A |

