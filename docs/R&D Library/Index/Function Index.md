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
| `query_browser_db` | Execute an SQLite query | `db`: str, `query`: str | str | Executes SQLite query |
| `debug_print` | Print debug information if enabled | `message`: str | None | Prints debug info to stderr |
| `display_help` | Display help information | None | None | Prints help message |
| `encode_input` | Encode input for RFC-3996 compliance | `input`: str | str | None |
| `encode_output` | Encode output using various methods | `output`: str | str | None |
| `encrypt_data` | Encrypt data using specified method | `data`: str, `method`: str, `key`: str | str | None |
| `exfiltrate_dns` | Exfiltrate data via DNS queries | `data`: str, `domain`: str, `id`: str | None | Sends DNS queries |
| `exfiltrate_http` | Exfiltrate data via HTTP POST | `data`: str, `url`: str | None | Sends data to remote server via HTTP POST |
| `format_output` | Format output based on specified format | `output`: str | str | None |
| `generate_job_id` | Generate unique job identifier | None | str | None |
| `generate_random_key` | Generate random encryption key | None | str | None |
| `get_timestamp` | Get current timestamp | None | str | None |
| `get_user` | Get current user information | None | str | None |
| `init_logging` | Initialize logging system | None | int | Creates log directory and file |
| `log_output` | Log output with metadata | `output`: str, `status`: str, `skip_data`: bool | None | Writes to log file and syslog |
| `prepare_encryption` | Setup encryption system | `method`: str | int | Sets encryption key |
| `rate_limit` | Implement rate limiting | None | None | Sleeps for specified duration |
| `sanitize_input` | Sanitize user input | `input`: str | str | None |
| `validate_encryption_method` | Validate encryption method | `method`: str | bool | None |
| `validate_input` | Validate input against pattern | `input`: str, `pattern`: str | bool | None |

## Discovery Functions

### Network Discovery
| Function Name | Description | Parameters | Returns | Command/Target File |
|---------------|-------------|------------|---------|---------------------|
| `discover_arp_cache` | Discover ARP cache entries | None | str | `network_service.sh` |
| `discover_bonjour_services` | Discover Bonjour/mDNS services | None | str | `network_service.sh` |
| `discover_established_connections` | Discover established network connections | None | str | `network_service.sh` |
| `discover_interface_details` | Discover network interface details | None | str | `network_service.sh` |
| `discover_kernel_network` | Discover kernel-level network info | None | str | `network_service.sh` |
| `discover_listening_ports` | Discover listening network ports | None | str | `network_service.sh` |
| `discover_mdfind_shares` | Discover network shares using Spotlight | None | str | `network_service.sh` |
| `discover_network_memory` | Analyze network-related memory mappings | None | str | `network_service.sh` |
| `discover_network_quality` | Test network connection quality | None | str | `network_service.sh` |
| `discover_network_services` | Discover running network services | None | str | `network_service.sh` |
| `discover_network_syscalls` | Trace network-related syscalls | None | str | `network_service.sh` |
| `discover_networksetup_config` | Discover network configuration | None | str | `network_service.sh` |
| `discover_route_info` | Discover network routing information | None | str | `network_service.sh` |
| `discover_sharing_services` | Discover file sharing services | None | str | `network_service.sh` |
| `discover_stealthy_network` | Perform stealthy network discovery | None | str | `network_service.sh` |

### Process Discovery
| Function Name | Description | Parameters | Returns | Command/Target File |
|---------------|-------------|------------|---------|---------------------|
| `discover_basic_processes` | Get basic process listing | None | str | `process_discovery.sh` |
| `discover_file_processes` | List processes with open files | None | str | `process_discovery.sh` |
| `discover_filtered_processes` | Filter processes by pattern | `pattern`: str | str | `process_discovery.sh` |
| `discover_launchd_services` | List launchd services | None | str | `process_discovery.sh` |
| `discover_network_processes` | List processes with network connections | None | str | `process_discovery.sh` |
| `discover_process_tree` | Get process hierarchy tree | None | str | `process_discovery.sh` |
| `discover_processes_activity` | Discover process activity | None | str | `process_discovery.sh` |
| `discover_processes_dtrace` | Discover processes using DTrace | None | str | `process_discovery.sh` |
| `discover_processes_memory` | Discover process memory usage | None | str | `process_discovery.sh` |
| `discover_processes_native` | Native process discovery | None | str | `process_discovery.sh` |
| `discover_processes_power` | Discover power-related processes | None | str | `process_discovery.sh` |
| `discover_processes_procinfo` | Discover process info using procinfo | None | str | `process_discovery.sh` |
| `discover_processes_profiler` | Discover processes using profiler | None | str | `process_discovery.sh` |
| `discover_processes_sample` | Sample process information | None | str | `process_discovery.sh` |
| `discover_resource_usage` | Show process resource usage | None | str | `process_discovery.sh` |
| `discover_sorted_processes` | Sort processes by field | `field`: str | str | `process_discovery.sh` |
| `discover_user_processes` | List processes by user | `user`: str | str | `process_discovery.sh` |

### System Information Discovery
| Function Name | Description | Parameters | Returns | Command/Target File |
|---------------|-------------|------------|---------|---------------------|
| `check_basic_system_info` | Get basic system information | None | str | `system_info.sh` |
| `check_boot_security` | Check boot and security settings | None | str | `system_info.sh` |
| `check_environment_info` | Get environment information | None | str | `system_info.sh` |
| `check_hardware_info` | Get hardware information | None | str | `system_info.sh` |
| `check_network_config` | Get network configuration | None | str | `system_info.sh` |
| `check_power_info` | Get power and battery information | None | str | `system_info.sh` |

### Security Software Discovery
| Function Name | Description | Parameters | Returns | Command/Target File |
|---------------|-------------|------------|---------|---------------------|
| `discover_av` | Discover antivirus software | `check_type`: str | str | `security_software.sh` |
| `discover_edr` | Discover EDR software | `check_type`: str | str | `security_software.sh` |
| `discover_firewall` | Discover firewall status | None | str | `security_software.sh` |
| `discover_gatekeeper` | Discover Gatekeeper status | None | str | `security_software.sh` |
| `discover_mrt` | Discover Malware Removal Tool | None | str | `security_software.sh` |
| `discover_ost` | Discover Objective-See tools | `check_type`: str | str | `security_software.sh` |
| `discover_tcc` | Discover TCC status | None | str | `security_software.sh` |
| `discover_xprotect` | Discover XProtect status | None | str | `security_software.sh` |

### Browser History Discovery
| Function Name | Description | Parameters | Returns | Command/Target File |
|---------------|-------------|------------|---------|---------------------|
| `query_brave_hdb` | Extract Brave browser history | None | str | `browser_history.sh` |
| `query_chrome_hdb` | Extract Chrome browser history | None | str | `browser_history.sh` |
| `query_firefox_hdb` | Extract Firefox browser history | None | str | `browser_history.sh` |
| `safari_history` | Extract Safari browser history | None | str | `browser_history.sh` |
