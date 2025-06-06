# MITRE ATT&CK Caldera: Attack-macOS Plugin
A Caldera plugin to execute scripts from the attack-macOS library. 


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

## Plugin Repository

**🔗 [caldera-plugin-attack-macos](https://github.com/armadoinc/caldera-plugin-attack-macos)**

## Installation

```bash
cd /path/to/caldera
curl -sSL https://raw.githubusercontent.com/armadoinc/caldera-plugin-attack-macos/main/install.sh | bash
```

### Installation Options

```bash
# Standard installation
curl -sSL https://raw.githubusercontent.com/armadoinc/caldera-plugin-attack-macos/main/install.sh | bash

# Use local attack-macOS directory  
curl -sSL https://raw.githubusercontent.com/armadoinc/caldera-plugin-attack-macos/main/install.sh | bash -s -- --local-path /path/to/attack-macOS

# Use custom repository
curl -sSL https://raw.githubusercontent.com/armadoinc/caldera-plugin-attack-macos/main/install.sh | bash -s -- --remote-repo user/fork-attack-macOS

# Use private repository
curl -sSL https://raw.githubusercontent.com/armadoinc/caldera-plugin-attack-macos/main/install.sh | bash -s -- --auth-token ghp_xxxxx
```

## Syncing the Plugin

The sync script automatically manages dependencies and performs a two-phase sync process: updating plugin infrastructure files and transforming attack-macOS scripts into Caldera abilities with MITRE ATT&CK metadata.

### Automatic Setup

- **Virtual Environment**: Creates isolated Python environment with required dependencies (PyGithub, PyYAML)
- **Path Detection**: Auto-detects Caldera installation from script location
- **Dependency Management**: Installs/updates requirements automatically

### Manual Sync

```bash
cd /path/to/caldera/plugins/attackmacos
python sync_plugin.py
```

### Sync Options

```bash
# Default: Updates plugin files from plugin repo AND syncs abilities from attack-macOS repo
python sync_plugin.py

# Specify custom Caldera path (otherwise auto-detected)
python sync_plugin.py --caldera-path /path/to/caldera

# Use local attack-macOS directory instead of downloading from GitHub
python sync_plugin.py --local-path /path/to/attack-macOS

# Use different GitHub repository (default: darmado/attack-macOS)
python sync_plugin.py --remote-repo user/fork-attack-macOS

# Use authentication token for private repositories
python sync_plugin.py --auth-token ghp_xxxxx

# Sync abilities only (skip plugin infrastructure updates)
python sync_plugin.py --abilities

# Update plugin files only (skip abilities sync)
python sync_plugin.py --plugin

# Show help
python sync_plugin.py --help
```

### What Gets Synced

**Plugin Files (from caldera-plugin-attack-macos repository):**
- `hook.py` - Plugin initialization and registration
- `plugin-init.py` - Plugin configuration
- `sync_plugin.py` - This sync script
- `requirements.txt` - Python dependencies

**Abilities (from attack-macOS repository):**
- **Shell Scripts**: Copied from `attackmacos/` directory to `data/payloads/`
- **YAML Abilities**: Auto-generated from script metadata in `attackmacos/core/config/`
- **MITRE ATT&CK Mapping**: Technique IDs, tactics, and descriptions extracted from YAML configs
- **Fact Dependencies**: All abilities use standardized `user.arg` fact for arguments

### Processing Details

1. **Script Discovery**: Finds all `.sh` files in `attackmacos/` directory
2. **Metadata Extraction**: Reads corresponding YAML configs for MITRE ATT&CK data
3. **Ability Generation**: Creates Caldera abilities with proper platform/executor mapping
4. **Payload Deployment**: Scripts become deployable payloads via Caldera's payload system

### Sync Schedule

- **Installation**: Initial sync during plugin setup
- **Manual**: Run `sync_plugin.py` to update
- **Development**: Sync after modifying attack-macOS scripts or configs

## Plugin Architecture

### Fact System

All abilities use the `user.arg` fact for argument control:

```yaml
command: #{location}/script_name.sh #{user.arg}
requirements:
  - user.arg:
      edge: has_property
```

### Ability Structure

Each attack-macOS script becomes a Caldera ability with:
- **Single fact dependency**: `user.arg`
- **Standardized command format**: `#{location}/script.sh #{user.arg}`
- **Automatic payload deployment** via Caldera's payload system
- **MITRE ATT&CK mapping** preserved from original scripts

## Usage

### Web Interface

1. Create operation in Caldera
2. Set `user.arg` fact with script arguments  
3. Select attack-macOS ability
4. Execute on target

### API Usage

```python
import requests

# Set user.arg fact
fact_data = {
    "trait": "user.arg", 
    "value": "--safari --chrome --verbose"
}

response = requests.post(
    "https://caldera-server:8888/api/v2/facts",
    headers={"KEY": "your-api-key"},
    json=fact_data
)

# Execute ability
ability_data = {
    "paw": "target-agent-paw",
    "ability_id": "browser_history"
}

response = requests.post(
    "https://caldera-server:8888/api/v2/operations/operation-id/potential-links",
    headers={"KEY": "your-api-key"},
    json=ability_data
)
```

## License

[Apache 2.0](LICENSE)