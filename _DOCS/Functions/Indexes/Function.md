# Function Index Grouped by Type
This document provides an index of functions used in our security scripts, organized by their types. It serves as a quick reference for the various functions implemented across different scripts.

### Purpose
- To provide a centralized reference for all functions used in the project
- To categorize functions based on their types and purposes
- To facilitate easier navigation and understanding of the project's capabilities

##

### Assumptions
- The reader has basic knowledge of shell scripting and macOS
- The functions are intended for use on macOS systems
- The listed functions are implemented in the corresponding scripts

##

### Usage
Refer to this document to:
- Quickly find functions related to specific types or purposes
- Understand the range of capabilities implemented in the project
- Locate the source scripts for specific functions

##

### Note
The functions listed here are for reference only. Always refer to the actual script implementations for the most up-to-date and context-specific usage of these functions.

##

### Utility Functions

| Function | Description | Parameters | Returns | Side Effects |
|----------|-------------|------------|---------|--------------|
| `validate_input` | Validate input against a regex pattern | `input`: str, `pattern`: str | bool | None |
| `execute_command` | Execute a shell command | `cmd`: str | str | Executes shell command |
| `encrypt_output` | Encrypt output using specified method | `data`: str | str | None |
| `exfil_http` | Exfiltrate data via HTTP POST | `data`: str, `url`: str | bool | Sends HTTP POST request |
| `exfil_dns` | Exfiltrate data via DNS queries | `data`: str, `domain`: str, `timestamp`: str | bool | Sends DNS queries |
| `display_help` | Display help information | None | None | Prints help message |
| `get_timestamp` | Get current timestamp | None | str | None |
| `log_to_stdout` | Log messages to stdout and file | `msg`: str, `function_name`: str, `command`: str | None | Prints log message |
| `setup_log` | Set up the log file | None | None | Creates/touches log file |
| `log_output` | Log output to file with rotation | `output`: str | None | Writes to log file |
| `chunk_data` | Split data into chunks | `data`: str, `chunk_size`: int | str | None |
| `encode_output` | Encode output | `data`: str | str | Changes global variables |
| `sanitize_input` | Sanitize user input | `input`: str | str | None |

##

### Command Functions

| Function | Description | Usage | Parameters | Returns | Side Effects |
|----------|-------------|-------|------------|---------|--------------|
| `display_help` | Display help information | `help` | None | None | Prints help info |
| `list_techniques` | List techniques for a tactic | `list techniques <tactic>` | `tactic`: str | None | Prints technique list |
| `execute_ttp` | Execute a specific TTP | `execute <ttp_type>` | `ttp_type`: str | str | Executes TTP |
| `encode_output` | Encode output | Internal | `output`: str | str | None |
| `encrypt_output` | Encrypt output | Internal | `data`: str | str | None |

##

### Technique Functions

| Function | Description | Usage | Parameters | Returns | Side Effects |
|----------|-------------|-------|------------|---------|--------------|
| `access_cred_keychain` | Access keychain credentials | Internal | `cmd_key`: str | str | Accesses keychain |
| `discover_network_shares` | Discover network shares | Internal | `cmd_key`: str | str | Scans for shares |
| `exfiltrate_data` | Exfiltrate data | Internal | `data`: str, `method`: str | bool | Attempts exfiltration |
| `persist_launch_agent` | Establish persistence | Internal | `cmd_key`: str | str | Modifies plist files |
| `evade_system_binary_proxy` | Evade detection | Internal | `cmd_key`: str | str | Executes via system binaries |
