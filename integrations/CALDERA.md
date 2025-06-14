# MITRE ATT&CK Caldera: Attack-macOS Plugin

A Caldera plugin to execute scripts from the attack-macOS library.

**Plugin Repository:** [https://github.com/armadoinc/caldera-plugin-attack-macos](https://github.com/armadoinc/caldera-plugin-attack-macos)

<div align="left">

![Caldera Version](https://img.shields.io/badge/Caldera-5.0.0+-blue?style=for-the-badge)
![Python Version](https://img.shields.io/badge/Python-3.9+-blue?style=for-the-badge)
![License](https://img.shields.io/badge/Apache%202.0-grey.svg?style=for-the-badge&logo=apache)

</div>

## Agent Compatibility

| Agent | Platform | Compatibility | Notes |
|-------|----------|---------------|-------|
| Sandcat | macOS | ✅ Supported | Primary agent for macOS operations |
| Manx | macOS | ❌ Not tested | May work but untested |
| Ragdoll | macOS | ❌ Not tested | May work but untested |

## Dependencies

**Plugin Dependencies:** None

**Target System Requirements:**

| Component | Requirement | Notes |
|-----------|-------------|-------|
| Operating System | macOS 13+ (Ventura) | Tested on Darwin 22.6.0 |
| Native Tools | LOLBins only | Uses built-in macOS commands |
| Additional Software | None | Living Off The Land approach |

## License

[Apache 2.0](LICENSE)