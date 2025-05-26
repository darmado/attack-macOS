#!/bin/bash

# Script Name: network_service.sh
# MITRE ATT&CK Technique: T1046 - Network Service Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.0

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

# Command Variables
CMD_NETSTAT="netstat"
CMD_LSOF="lsof"
CMD_NC="nc"
CMD_LAUNCHCTL="launchctl"
CMD_SCUTIL="scutil"
CMD_NETWORKSETUP="networksetup"
CMD_SYSCTL="sysctl"
CMD_DTRACE="dtrace"
CMD_FS_USAGE="fs_usage"
CMD_PROC_INFO="/usr/sbin/proc_info"
CMD_SYSTEM_PROFILER="system_profiler"
CMD_ROUTE="route"
CMD_ARP="arp"
CMD_NETTOP="nettop"
CMD_HEAP="heap"
CMD_VMMAP="vmmap"
CMD_DTRUSS="dtruss"

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
    --port-scan           Basic port enumeration (netstat)
    --service-enum        Network service enumeration (launchctl)
    --network-socket      Network socket enumeration (lsof)
    --network-state       Network connection state discovery (scutil)
    --kernel-socket       Kernel-level socket enumeration (sysctl)
    --process-network     Process network relationship discovery (proc_info)
    --network-sniff       Network traffic sniffing (dtrace, requires root)

  Filters:
    --protocols=TYPE     Filter by protocol (tcp|udp|all)
    --port=NUMBER        Filter by specific port number
    --process=NAME       Filter by process name

  Output Processing:
    --encode=TYPE        Encode output (b64|hex)
    --encrypt=METHOD     Encrypt output using openssl
    --exfil=URI         Exfiltrate output to URI using HTTP GET
    --exfil=dns=DOMAIN  Exfiltrate output via DNS queries to DOMAIN
    --chunksize=N       Size of exfiltration chunks (default: 1000)

Examples:
  $0 --port-scan                     # Basic port enumeration
  $0 --service-enum                  # Network service enumeration
  $0 --network-socket --process=httpd # Network sockets for specific process
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

discover_network_services() {
    local output=""
    output+="[$(date '+%Y-%m-%d %H:%M:%S')] Discovering network services:\n"
    
    # launchctl - Used to identify running network services
    log_cmd_exec "$CMD_LAUNCHCTL" "Network service discovery"
    output+="[+] Running network services (using $CMD_LAUNCHCTL):\n"
    output+="$($CMD_LAUNCHCTL list | grep -i net)\n"
    
    # scutil - Used to get network service states
    log_cmd_exec "$CMD_SCUTIL" "Network service state discovery"
    output+="[+] Network service states (using $CMD_SCUTIL):\n"
    output+="$($CMD_SCUTIL --nc list)\n"
    
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
    output+="$($CMD_SYSCTL -n net.inet.tcp.pcblist net.inet.udp.pcblist 2>/dev/null)\n"
    
    # fs_usage for network file operations
    log_cmd_exec "$CMD_FS_USAGE" "Network file operation discovery"
    output+="[+] Network file operations (using $CMD_FS_USAGE):\n"
    output+="$($CMD_FS_USAGE -w -f filesystem 2>/dev/null | grep -i "network\|socket" | head -n 10)\n"
    
    # proc_info for process network info
    log_cmd_exec "$CMD_PROC_INFO" "Process network information discovery"
    output+="[+] Process network information (using $CMD_PROC_INFO):\n"
    output+="$($CMD_PROC_INFO -v 2>/dev/null | grep -i "network\|socket")\n"
    
    # vmmap for network memory mappings
    log_cmd_exec "$CMD_VMMAP" "Network memory mapping discovery"
    output+="[+] Network memory mappings (using $CMD_VMMAP):\n"
    local net_pids=$($CMD_LSOF -i -n -P | grep -v "grep" | awk '{print $2}' | sort -u)
    for pid in $net_pids; do
        output+="$($CMD_VMMAP $pid 2>/dev/null | grep -i "network\|socket")\n"
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

# Main function
main() {
    local output=""
    
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
                output+="$(discover_listening_ports)\n"
                output+="$(discover_network_services)\n"
                output+="$(discover_interface_details)\n"
                output+="$(discover_established_connections)\n"
                output+="$(discover_stealthy_network)\n"
                output+="$(discover_kernel_network)\n"
                ;;
            --port-scan)
                output+="$(discover_listening_ports)\n"
                ;;
            --service-enum)
                output+="$(discover_network_services)\n"
                ;;
            --network-socket)
                output+="$(discover_established_connections)\n"
                ;;
            --network-state)
                output+="$(discover_interface_details)\n"
                ;;
            --kernel-socket)
                output+="$(discover_stealthy_network)\n"
                ;;
            --process-network)
                output+="$(discover_kernel_network)\n"
                ;;
            --network-sniff)
                if [ "$(id -u)" != "0" ]; then
                    echo "Error: --network-sniff requires root privileges" >&2
                    exit 1
                fi
                output+="$(discover_kernel_network)\n"
                ;;
            --protocols=*)
                protocol="${1#*=}"
                case "$protocol" in
                    "tcp")
                        output+="$($CMD_NETSTAT -an -p tcp)\n"
                        ;;
                    "udp")
                        output+="$($CMD_NETSTAT -an -p udp)\n"
                        ;;
                    "all")
                        output+="$($CMD_NETSTAT -an)\n"
                        ;;
                    *)
                        echo "Invalid protocol: $protocol" >&2
                        display_help
                        exit 1
                        ;;
                esac
                ;;
            --port=*)
                port="${1#*=}"
                output+="$($CMD_LSOF -i :$port)\n"
                ;;
            --process=*)
                process="${1#*=}"
                output+="$($CMD_LSOF -i -n -P | grep -i "$process")\n"
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

    # If no discovery options were selected
    if [ -z "$output" ] && [ "$LOG_ENABLED" = false ] && [ "$VERBOSE" = false ]; then
        echo "Error: No discovery options selected" >&2
        display_help
        exit 1
    fi

    # Create log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        if [ ! -f "$LOG_FILE" ]; then
            touch "$LOG_FILE"
            chmod 600 "$LOG_FILE"
        fi
        echo -e "$output" >> "$LOG_FILE"
    fi

    # Process output based on encoding/encryption/exfiltration options
    if [ "$ENCODE" != "none" ]; then
        case "$ENCODE" in
            "b64")
                output=$(echo -e "$output" | base64)
                ;;
            "hex")
                output=$(echo -e "$output" | xxd -p)
                ;;
        esac
    fi

    if [ "$ENCRYPT" != "none" ]; then
        output=$(echo -e "$output" | openssl enc -"$ENCRYPT" -k "$ENCRYPT_KEY" | base64)
    fi

    if [ "$EXFIL" = true ]; then
        if [ "$EXFIL_METHOD" = "dns" ]; then
            # Implement DNS exfiltration
            :
        else
            # Implement HTTP exfiltration
            :
        fi
    else
        echo -e "$output"
    fi
}

# Execute main function with all arguments
main "$@" 