<h1 align="center">
  <br>
  <a href="https://github.com/armadoinc/attack-macos"><img src="https://github.com/user-attachments/assets/03a5c7dc-9dd6-49f9-a58b-2fdcdb6596f6" alt="attack-macOS" ></a>
  <br>
</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Shell-Script-green?style=for-the-badge&logo=gnu-bash" alt="Shell"/>
  <img src="https://img.shields.io/badge/STIX-2.1-blue?style=for-the-badge" alt="STIX"/>
  <img src="https://img.shields.io/badge/MITRE-ATT%26CK-red?style=for-the-badge" alt="MITRE ATT&CK"/>
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge&logo=apache" alt="License"/>
  <img src="https://img.shields.io/badge/macOS-10.15%2B-lightgrey?style=for-the-badge&logo=apple" alt="macOS Compatibility"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Join-Community-blue?style=for-the-badge&logo=discord" alt="Join Community"/>
  <a href="https://x.com/attackmacos">
    <img src="https://img.shields.io/badge/X-Follow-000000?style=for-the-badge&logo=x&logoColor=white" alt="X"/>
  </a>
</p>
<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#dependencies">Dependencies</a> •
  <a href="#compatibility">Compatibility</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#license">License</a>
</p>

##


### Overview
Attack-macOS is a library of scripts mapped to MITRE ATT&CK. Security teams can use Attack-macOS to execute techniques and discover new detection opportunities in macOS environments.

| Problem | Challenge | Solution |
|---------|-----------|----------|
| • Limited macOS-specific security tools<br>• Insufficient testing coverage in existing projects<br>• Compliance tools inadequately address detection requirements | • Insufficient capabilities to evaluate macOS defenses<br>• Inadequate detection exposes systems to potential risks<br>• Limited tooling hinders proactive security measures |Build a library of macOS specific attack scripts dedicated to help <br>2. that identify better detection opportunities and in macOS specific endpoint security solutions. |

##

### Objective

This project aims to simplify the execution of Living Off The Land (LOTL) techniques via standalone, modular, flexible, interaperable, and easy-to-maintain scripts.

##

### Dependencies

All Attack-macOS scripts use native macOS binaries, interpreters, playlists, libraries, tools, and utilities. If third-party tools are installed (```brew```, ```slack```,```jamf```), techniques that leverage third-party apps can be executed.

##

### Key Features

| Feature | Description |
|:--------|:------------|
| **Template** | Includes a YAML template for creating new scripts and dynamically generating scripts. |
| **Modular Design** | Self-contained scripts that can be used independently or combined, easily integrating with existing frameworks. |
| **Customizable** | Easily modifiable and extendable, with centralized execution control via global variables and flags. |
| **macOS Native** | Uses native tools and languages to emulate adversary techniques without external dependencies. |
| **MITRE ATT&CK Mapped** | All scripts and arguments directly mapped to the MITRE ATT&CK framework. |
| **Logging** | Consistent built-in logging capability across all scripts for output analysis. |
| **Encoding and Encryption** | Multiple data encoding options and integrated encryption functions. |
| **Exfiltration** | Simulates data exfiltration via HTTP or DNS protocols. |
| **Integration** | Seamlessly integrates with existing security tools, automation pipelines, and CI/CD workflows. |

##

### Compatibility

![macOS](https://img.shields.io/badge/macOS-Ventura%2013.5-blue)

##

### Quick Start

**Install Options:**

```
git clone https://github.com/armadoinc/attack-macos
```

**Fetch and Execute:**

```
TBD
```

**Remote Execution:**

```
TBD
```

##

### Documentation

- [Documentation](https://github.com/armadocorp/attack-macOS/wiki)
- [Script Blueprint](https://github.com/darmado/attack-macOS/wiki/Script-Blueprint)

##

### License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for more details.

##

## Credits and References

### Credits and References

Refer to the [Tools Index](_DOCS/References/Tools%20Index.md) in the References directory.

