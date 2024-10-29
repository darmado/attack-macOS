#!/bin/bash

# Script Name: guest_account.sh
# MITRE ATT&CK Technique: T1078
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Version: 1.0

# Description:
# This script enables or disables the guest account on macOS using the sysadminctl utility.

# Global Variables
NAME=guest_account
TTP_ID=T1078
LOG_FILE="${TTP_ID}_${NAME}.log"

# Parse command-line arguments
VERBOSE=false
ALL=false
ENABLE_GUEST=false
DISABLE_GUEST=false
LOG_ENABLED=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""

# Logging function with log rotation (macOS simple tools)
log() {
    local level="$1"
    shift
    local message="$@"
    
    # Check if log file exists and is non-empty before checking its size
    if [ -f "$LOG_FILE" ]; then
        local filesize=$(ls -l "$LOG_FILE" | awk '{print $5}')
        # Ensure filesize is numeric and rotate log if it exceeds 5MB
        if [ "$filesize" -ge 5242880 ]; then
            mv "$LOG_FILE" "1${LOG_FILE}"
        fi
    fi

    # Log the message
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}


# Function to display help message
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  General:"
    echo "    -h, --help              Display this help message"
    echo "    -v, --verbose           Enable verbose output"
    echo "    -a, --all               Run all techniques"
    echo "    -e, --enable            Enable the guest account"
    echo "    -d, --disable           Disable the guest account"
    echo
    echo "  Output Manipulation:"
    echo "    --log                   Enable logging of output to a file"
    echo "    --encode=TYPE           Encode output (b64|hex|uuencode|perl_b64|perl_utf8)"
    echo "    --exfil=URI             Exfiltrate output to URI using HTTP GET"
    echo "    --exfil=dns=DOMAIN      Exfiltrate output via DNS queries to DOMAIN (Base64 encoded)"
    echo "    --encrypt=METHOD        Encrypt output (aes|blowfish|gpg). Generates a random key."
    echo
    echo "Description:"
    echo "  This script enables or disables the guest account on macOS using the sysadminctl utility."
}

# Function to enable guest account
enable_guest_account() {
    log INFO "Attempting to enable the guest account."
    if sudo sysadminctl -guestAccount on; then
        log INFO "Guest account enabled successfully."
    else
        log ERROR "Failed to enable the guest account."
    fi
}

# Function to disable guest account
disable_guest_account() {
    log INFO "Attempting to disable the guest account."
    if sudo sysadminctl -guestAccount off; then
        log INFO "Guest account disabled successfully."
    else
        log ERROR "Failed to disable the guest account."
    fi
}

# Main function that runs the desired actions based on options
main() {
    if [ "$ENABLE_GUEST" = true ]; then
        enable_guest_account
    elif [ "$DISABLE_GUEST" = true ]; then
        disable_guest_account
    fi

    # If logging is enabled, suppress STDOUT
    if [ "$LOG_ENABLED" = true ]; then
        exec > /dev/null
    fi
}



while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) display_help; exit 0 ;;
        -v|--verbose) VERBOSE=true ;;
        -a|--all) ALL=true ;;
        -e|--enable) ENABLE_GUEST=true ;;
        -d|--disable) DISABLE_GUEST=true ;;
        --log) LOG_ENABLED=true ;;
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
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

# Run the main function only if --enable or --disable is specified
if [ "$ENABLE_GUEST" = true ] || [ "$DISABLE_GUEST" = true ]; then
    main
else
    echo "Use -e or --enable to enable the guest account, or -d or --disable to disable it."
    exit 1
fi
