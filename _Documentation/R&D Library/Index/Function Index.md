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
Always refer to the actual script implementations for the most up-to-date and context-specific usage of these functions.

## Utility Functions

| Function Name | Description | Parameters | Returns | Side Effects |
|---------------|-------------|------------|---------|--------------|
| `check_perms` | Check file permissions | `file`: str, `permission`: str | bool | Logs permission status |
| `check_perms_tcc` | Check if the app has Full Disk Access | None | bool | Logs FDA status |
| `chunk_data` | Split data into chunks | `data`: str, `chunk_size`: int | str | None |
| `cmd_query_browser_db` | Execute an SQLite query | `db`: str, `query`: str | str | Executes SQLite query |
| `create_log_file` | Set up the log file | None | None | Creates/touches log file |
| `debug` | Print debug information if enabled | `message`: str | None | Prints debug info to stderr |
| `display_help` | Display help information | None | None | Prints help message |
| `encode_input` | Encode input for RFC-3996 compliance | `input`: str | str | None |
| `encode_output` | Encode output using various methods | `output`: str | str | None |
| `encrypt_data` | Encrypt data using specified method | `data`: str, `method`: str, `key`: str | str | None |
| `encrypt_output` | Encrypt output using specified method | `data`: str, `method`: str, `key`: str | str | None |
| `execute_command` | Execute a shell command | `cmd`: str | str | Executes shell command |
| `exfiltrate_dns` | Exfiltrate data via DNS queries | `data`: str, `domain`: str, `id`: str | None | Sends DNS queries |
| `exfiltrate_http` | Exfiltrate data via HTTP POST | `data`: str, `uri`: str | None | Sends HTTP POST request |
| `format_output` | Format output based on specified format | `output`: str | str | None |
| `get_timestamp` | Get current timestamp | None | str | None |
| `log` | Log messages with timestamp and user info | `message`: str, `command`: str, `output`: str | None | Logs to file if enabled |
| `log_output` | Log output to file with rotation | `output`: str | None | Writes to log file |
| `sanitize_input` | Sanitize user input | `input`: str | str | None |
| `validate_input` | Validate input against a regex pattern | `input`: str, `pattern`: str | bool | None |
| `verbose` | Print verbose output if enabled | `message`: str | None | Prints to stderr and logs |

## Procedure Functions

| Function Name | Description | Parameters | Returns | Side Effects | Command/Target File |
|---------------|-------------|------------|---------|--------------|---------------------|
| `discover_boot_rom_version` | Discover Boot ROM versions associated with VMs | None | str | Executes `system_profiler SPHardwareDataType` | vmsandbox.sh |
| `discover_cpu_core_count` | Check the number of CPU cores | None | str | Executes `sysctl -n hw.physicalcpu` | vmsandbox.sh |
| `discover_disk_drive_names` | Discover disk drive names associated with VMs | None | str | Executes `diskutil list` | vmsandbox.sh |
| `discover_hardware_model` | Discover hardware models associated with VMs | None | str | Executes `sysctl -n hw.model` | vmsandbox.sh |
| `discover_hyperthreading` | Check if hyperthreading is enabled | None | str | Executes `sysctl -n machdep.cpu.thread_count` | vmsandbox.sh |
| `discover_iokit_registry` | Discover IOKit registry entries associated with VMs | None | str | Executes `ioreg -rd1 -c IOPlatformExpertDevice` | vmsandbox.sh |
| `discover_memory_size` | Check the total memory size | None | str | Executes `sysctl -n hw.memsize` | vmsandbox.sh |
| `discover_network_adapters` | Discover network adapters associated with VMs | None | str | Executes `networksetup -listallhardwareports` | vmsandbox.sh |
| `discover_system_integrity_protection` | Check the status of System Integrity Protection | None | str | Executes `csrutil status` | vmsandbox.sh |
| `discover_usb_vendor_name` | Discover USB vendor names associated with VMs | None | str | Executes `ioreg -rd1 -c IOUSBHostDevice` | vmsandbox.sh |
| `discover_virtualization_files` | Discover device files associated with VMs | None | str | Executes `ls /dev` | vmsandbox.sh |
| `discover_virtualization_processes` | Discover running processes associated with VMs | None | str | Executes `ps aux` | vmsandbox.sh |
| `discover_av` | Discover antivirus software | `av_tool`: str | str | Executes various commands to detect AV | discovery.sh |
| `discover_edr` | Discover EDR software | `edr_tool`: str | str | Executes various commands to detect EDR | discovery.sh |
| `discover_firewall` | Discover firewall status | None | str | Checks firewall configuration | discovery.sh |
| `discover_gatekeeper` | Discover Gatekeeper status | None | str | Checks Gatekeeper configuration | discovery.sh |
| `discover_mrt` | Discover Malware Removal Tool | `mrt_tool`: str | str | Checks for MRT presence and configuration | discovery.sh |
| `discover_ost` | Discover Objective-See tools | `ost_tool`: str | str | Executes various commands to detect OST | discovery.sh |
| `discover_tcc` | Discover TCC status | None | str | Checks TCC configuration | discovery.sh |
| `discover_xprotect` | Discover XProtect status | None | str | Checks XProtect configuration | discovery.sh |
| `extract_passwd_users` | Extract users from passwd file | None | str | Reads `/etc/passwd` | accounts.sh |
| `list_dscacheutil_users` | List users using dscacheutil | None | str | Executes `dscacheutil -q user` | accounts.sh |
| `list_dscl_users` | List users using dscl | None | str | Executes `dscl . -list /Users` | accounts.sh |
| `list_groups_cmd` | List groups using groups command | None | str | Executes `groups` command | groups.sh |
| `list_groups_dscacheutil` | List groups using dscacheutil | None | str | Executes `dscacheutil -q group` | groups.sh |
| `list_groups_dscl` | List groups using dscl | None | str | Executes `dscl . -list /Groups` | groups.sh |
| `list_groups_etc` | List groups from /etc/group | None | str | Reads `/etc/group` file | groups.sh |
| `list_groups_id` | List groups using id command | None | str | Executes `id -G` command | groups.sh |
| `list_logged_users` | List logged-in users | None | str | Executes `who` command | accounts.sh |
| `list_user_dirs` | List user directories | None | str | Executes `ls -la /Users` | accounts.sh |
| `main` | Main function to orchestrate script execution | None | None | Executes main script logic | Various scripts |
| `query_brave_hdb` | Extract Brave browser history | None | str | Queries Brave history database | browser_history.sh |
| `query_chrome_hdb` | Extract Chrome browser history | None | str | Queries Chrome history database | browser_history.sh |
| `query_firefox_hdb` | Extract Firefox browser history | None | str | Queries Firefox history database | browser_history.sh |
| `read_loginwindow_plist` | Read loginwindow plist | None | str | Reads loginwindow plist file | accounts.sh |
| `safari_history` | Extract Safari browser history | None | str | Queries Safari history database | browser_history.sh |
| `show_id_info` | Show current user info | None | str | Executes `id` command | accounts.sh |
