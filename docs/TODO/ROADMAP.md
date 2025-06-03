# attack-macOS Project Roadmap

This document outlines the planned features and improvements for the attack-macOS project.



## Core Built-in Shell Script Functions

| Function | Status | Description | Documentation |
|----------|--------|-------------|---------------|
| core_get_timestamp | ✅ | Generate consistent timestamp strings | [Get Timestamp.md](R&D%20Library/Functions/Shell/Get%20Timestamp.md) |
| core_generate_job_id | ✅ | Create unique 8-character hex job tracking IDs | [Generate Job Id.md](R&D%20Library/Functions/Shell/Generate%20Job%20Id.md) |
| core_parse_args | ✅ | Parse command-line arguments with validation | [Parse Args.md](R&D%20Library/Functions/Shell/Parse%20Args.md) |
| core_validate_input | ✅ | Input validation for strings, domains, URLs, file paths | [Input Validation.md](R&D%20Library/Functions/Shell/Input%20Validation.md) |
| core_log_output | ✅ | File logging with rotation and syslog integration | [Log Output.md](R&D%20Library/Functions/Shell/Log%20Output.md) |
| core_format_output | ✅ | Output formatting (JSON, CSV, raw) | [Format Output.md](R&D%20Library/Functions/Shell/Format%20Output.md) |
| core_encode_output | ✅ | Data encoding (base64, hex, perl_b64, perl_utf8) | [Encode Output.md](R&D%20Library/Functions/Shell/Encode%20Output.md) |
| core_encrypt_output | ✅ | Data encryption (AES-256-CBC, GPG symmetric, XOR) | [Encrypt Output.md](R&D%20Library/Functions/Shell/Encrypt%20Output.md) |
| core_exfiltrate_data | ✅ | Data exfiltration (HTTP POST/GET, DNS queries) | [Exfiltrate Data.md](R&D%20Library/Functions/Shell/Exfiltrate%20Data.md) |
| core_process_output | ✅ | Pipeline processing (format → encode → encrypt → steganography) | [Process Output.md](R&D%20Library/Functions/Shell/Process%20Output.md) |
| core_transform_output | ✅ | Final output delivery (logging, exfiltration, display) | [Transform Output.md](R&D%20Library/Functions/Shell/Transform%20Output.md) |
| core_apply_steganography | ✅ | Hide data in PNG images using native macOS tools | [Steganography.md](R&D%20Library/Functions/Shell/Steganography.md) |
| core_check_fda | ✅ | Full Disk Access permission verification | [Check Fda.md](R&D%20Library/Functions/Shell/Check%20Fda.md) |
| core_check_db_lock | ✅ | SQLite database lock detection | [Check Db Lock.md](R&D%20Library/Functions/Shell/Check%20Db%20Lock.md) |
| core_check_perms | ✅ | File permission validation (read/write/execute) | [Check Perms.md](R&D%20Library/Functions/Shell/Check%20Perms.md) |

## Other tasks

| Feature | Status | Priority | Description |
|---------|--------|----------|-------------|
| Community Contribution Workflow | Planned | High | Streamlined community contribution worflow |
| Additional Techniques | Planned | Medium | Implement more MITRE ATT&CK techniques |
| Testing Framework | Planned | Medium | Basic testing for scripts |



#TODO: ADD TO SCRIPTS


### Discovery

| TTP ID | Description | Command |
|--------|-------------|---------|
| [T1007](https://attack.mitre.org/techniques/T1007/) | List launchd services | `launchctl list` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | Show network capabilities | `system_profiler SPNetworkDataType` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | Display known networks | `system_profiler SPNetworkLocationDataType` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | Display Ethernet information | `system_profiler SPEthernetDataType` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | Display Airport information | `system_profiler SPAirPortDataType` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | View ARP table | `arp -i en0 -l -a` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | List network services | `networksetup -listallnetworkservices` |
| [T1016](https://attack.mitre.org/techniques/T1016/) | List network hardware ports | `networksetup -listallhardwareports` |
| [T1049](https://attack.mitre.org/techniques/T1049/) | Monitor network usage | `nettop` |
| [T1049](https://attack.mitre.org/techniques/T1049/) | List listening ports | `lsof -i -P -n | grep LISTEN` |
| [T1053.002](https://attack.mitre.org/techniques/T1053/002/) | List scheduled "at" tasks | `atq` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Display kernel configuration | `sysctl -a` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | List connected hard drives | `diskutil list` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Display system information | `system_profiler SPSoftwareDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Display printer information | `system_profiler SPPrintersDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | List installed frameworks | `system_profiler SPFrameworksDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Display developer tools info | `system_profiler SPDeveloperToolsDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Display startup items | `system_profiler SPStartupItemDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Check firewall status | `system_profiler SPFirewallDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Show Bluetooth information | `system_profiler SPBluetoothDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | Show USB device information | `system_profiler SPUSBDataType` |
| [T1082](https://attack.mitre.org/techniques/T1082/) | List system_profiler data types | `system_profiler -listDataTypes` |
| [T1083](https://attack.mitre.org/techniques/T1083/) | Find TCC database files | `find /Users/darmado/Library/ -name "tcc.db"` |
| [T1083](https://attack.mitre.org/techniques/T1083/) | Search for TCC.db files | `mdfind 'kMDItemFSName == "TCC.db"' -onlyin /` |
| [T1083](https://attack.mitre.org/techniques/T1083/) | Search for files containing "password" | `mdfind password` |
| [T1083](https://attack.mitre.org/techniques/T1083/) | Search for files with "password" in name | `mdfind -name password` |
| [T1083](https://attack.mitre.org/techniques/T1083/) | Search for cookie databases | `mdfind 'kMDItemFSName == "cookies.sqlite"' -onlyin /` |
| [T1135](https://attack.mitre.org/techniques/T1135/) | View mounted SMB shares | `smbutil statshares -a` |


### Credential Access

| TTP ID | Description | Command |
|--------|-------------|---------|
| [T1555.001](https://attack.mitre.org/techniques/T1555/001/) | List keychains | `security list-keychains` |
| [T1555.001](https://attack.mitre.org/techniques/T1555/001/) | Dump keychain contents | `security dump-keychain -a -d` |

### Execution

| TTP ID | Description | Command |
|--------|-------------|---------|
| [T1204.002](https://attack.mitre.org/techniques/T1204/002/) | Open application hidden | `open -a <Application Name> --hide` |
| [T1204.002](https://attack.mitre.org/techniques/T1204/002/) | Open file with specific application | `open some.doc -a TextEdit` |

### Defense Evasion

| TTP ID | Description | Command |
|--------|-------------|---------|
| [T1562.001](https://attack.mitre.org/techniques/T1562/001/) | Prevent system sleep | `caffeinate &` |

### Collection

| TTP ID | Description | Command |
|--------|-------------|---------|
| [T1113](https://attack.mitre.org/techniques/T1113/) | Capture screenshot | `screencapture -x /tmp/ss.jpg` |
| [T1115](https://attack.mitre.org/techniques/T1115/) | Get clipboard contents | `pbpaste` |






# ALSO ADD
https://github.com/kandji-inc/support
https://github.com/kandji-inc/support/blob/main/Scripts/macOS/get_user_list.sh


Decoy script

Add Proxy function to @safarijxa.js 
https://github.com/salarcode/SmartProxy/tree/master


