---
layout: default
---

# attack-macOS Documentation

**Library of scripts for macOS security testing with MITRE ATT&CK mapped techniques.**

Attack-macOS is a library of scripts security teams can use to evaluate macOS endpoint detection and response capabilities. This project aims to simplify the execution of Living Off The Land (LOTL) techniques via standalone scripts with built-in encoding, encryption, logging, and exfiltration over DNS and HTTP/S.

---

## Quick Start

Execute techniques directly from GitHub with no local installation:

```bash
# Browser history collection
curl -sSL https://raw.githubusercontent.com/darmado/attack-macOS/main/attackmacos/ttp/discovery/browser_history/browser_history.sh | sh -s -- --safari

# Download attackmacos.sh wrapper for local execution
curl -O https://raw.githubusercontent.com/darmado/attack-macOS/main/attackmacos/attackmacos.sh
chmod +x attackmacos.sh
./attackmacos.sh --list --tactic discovery
```

**Requirements**: macOS 11+ with native tools (no external dependencies)

---

## Core Documentation

### Getting Started
- [Quick Start Guide]({{ site.baseurl }}/docs/ROADMAP.html) - Setup and first technique execution
- [Project Overview]({{ site.baseurl }}/README.html) - Script library architecture and capabilities
- [Compatibility Matrix]({{ site.baseurl }}/docs/Acknowledgements.html) - Supported macOS versions and tools

### Development
- [**Adding New Procedures (YAML)**]({{ site.baseurl }}/docs/R&D%20Library/How%20To/Add%20a%20New%20Procedure%20in%20YAML.html) - Create YAML-driven procedures with built-in capabilities
- [Adding Base Features]({{ site.baseurl }}/docs/R&D%20Library/How%20To/Add%20a%20New%20Base%20Feature.html) - Extend core script functionality
- [Enhancing Features]({{ site.baseurl }}/docs/R&D%20Library/How%20To/Enhance%20a%20Base%20Feature.html) - Modify existing script components
- [Encryption Methods]({{ site.baseurl }}/docs/R&D%20Library/How%20To/Adding%20Encryption%20Methods%20to%20base.sh.html) - Add new encryption capabilities

---

## R&D Library Index

### Implementation Guides
- **[How To]({{ site.baseurl }}/docs/R&D%20Library/How%20To/)** - Step-by-step development procedures
- **[Script Guides]({{ site.baseurl }}/docs/R&D%20Library/Script%20Guides/)** - Language-specific implementation patterns
- **[Functions]({{ site.baseurl }}/docs/R&D%20Library/Functions/)** - Reusable code components by language

### Reference Documentation  
- **[macOS Internals]({{ site.baseurl }}/docs/R&D%20Library/macOS%20Internals/)** - System-level implementation details
- **[Security Vendors]({{ site.baseurl }}/docs/R&D%20Library/Security%20Vendors/)** - EDR/AV specific detection patterns
- **[CTI]({{ site.baseurl }}/docs/R&D%20Library/CTI/)** - Cyber threat intelligence integration

### Technical Resources
- **[Open Source Docs]({{ site.baseurl }}/docs/R&D%20Library/Open%20Source%20Docs/)** - External documentation and references
- **[Index]({{ site.baseurl }}/docs/R&D%20Library/Index/)** - Comprehensive technical references

---

## Script Library Structure

```
attackmacos/
├── attackmacos.sh          # Main execution wrapper
├── core/                   # Shared components
│   ├── base/              # Core functionality (base.sh)
│   ├── schemas/           # YAML validation schemas  
│   └── global/            # Shared variables and functions
├── ttp/                   # MITRE ATT&CK techniques
│   ├── discovery/         # Information gathering scripts
│   ├── credential_access/ # Credential extraction scripts
│   ├── collection/        # Data collection scripts
│   └── [other_tactics]/   # Additional tactic categories
└── tools/                 # Development and build utilities
```

---

## Key Features

| Feature | Description |
|:--------|:------------|
| **Modular Design** | Self-contained scripts that can be used independently or combined |
| **macOS Native** | Uses native tools and languages without external dependencies |
| **MITRE ATT&CK Mapped** | All scripts directly mapped to MITRE ATT&CK techniques |
| **Customizable** | Easily modifiable and extendable with centralized execution control |
| **Logging** | Consistent built-in logging capability across all scripts |
| **Encoding and Encryption** | Multiple data encoding options and integrated encryption |
| **Exfiltration** | Simulates data exfiltration via HTTP/S or DNS protocols |
| **Integration** | Seamlessly integrates with existing security tools and automation |

---

## Development Workflow

1. **Design Technique** - Map to MITRE ATT&CK technique
2. **Create YAML** - Use procedure template for rapid development  
3. **Build Script** - Generate executable with `build_shell_procedure.py`
4. **Test Execution** - Validate against macOS security controls
5. **Document Results** - Record detection capabilities and findings

---

## Dependencies

All scripts use native macOS binaries, interpreters, libraries, tools, and utilities. If third-party tools are installed (`brew`, `slack`, `jamf`), techniques that leverage third-party apps can be executed.

---

## Community Resources

- **GitHub Repository**: [darmado/attack-macOS](https://github.com/darmado/attack-macOS)
- **Issue Tracking**: Report bugs and request features via GitHub Issues
- **Contributing**: See [contribution guidelines]({{ site.baseurl }}/docs/ROADMAP.html#contributing)

---

*This library is designed for authorized security testing and research purposes. Ensure proper authorization before execution in any environment.* 