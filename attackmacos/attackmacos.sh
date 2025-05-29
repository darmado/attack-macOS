#!/bin/sh
# Name: attackmacos.sh
# Platform: macOS
# Author: @darmado | x.com/darmad0
# Date: 2023-10-06
# Version: 1.3
# Last Modified: 2024-10-28
# Created: 2023-09-30
# License: Apache 2.0
# Repository: https://github.com/darmado/attack-macOS
# Description: Tool to fetch and execute scripts from the attack-macOS repository
# Dependencies: curl, wget, osascript (optional)

# Exit on error and undefined vars
set -eu

# Ensure cleanup on exit
trap cleanup EXIT INT TERM

cleanup() {
    # Reset terminal
    [ -t 1 ] && tput sgr0
    return 0
}

# Error handler
error() {
    echo "Error on line $1" >&2
    cleanup
    exit 1
}

# Configuration
#------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_URL="https://raw.githubusercontent.com/darmado/attack-macOS/main/attackmacos/ttp/{tactic}/{ttp}/{ttp}.sh"
DEFAULT_METHOD="curl"
VERBOSE="${ATTACKMACOS_VERBOSE:-false}"
LOG_ENABLED="${ATTACKMACOS_LOG:-false}"

# Execution methods
METHOD_LOCAL="local"
METHOD_CURL="curl"
METHOD_WGET="wget"
METHOD_OSASCRIPT="osascript"

# MITRE ATT&CK Tactics
TACTICS="reconnaissance resource_development initial_access execution persistence privilege_escalation defense_evasion credential_access discovery lateral_movement collection command_and_control exfiltration impact"

# Exit codes
E_SUCCESS=0
E_FAILURE=1
E_INVALID_ARGS=2
E_MISSING_DEPS=3
E_INVALID_TACTIC=4
E_INVALID_TTP=5
E_EXECUTION_FAILED=6

# Detect available shell
detect_shell() {
    for shell in bash zsh sh ash dash; do
        if command -v "$shell" >/dev/null 2>&1; then
            echo "$shell"
            return 0
        fi
    done
    echo "sh"  # Fallback to sh if no other shell found
    return 0
}

# Execute script with detected shell
execute_script() {
    script="$1"
    shift
    shell="$(detect_shell)"
    "$shell" "$script" "$@"
}

#------------------------------------------------------------------------------
# Display Functions
#------------------------------------------------------------------------------

# Display help
display_help() {
    cat << EOF
Usage: $(basename "$0") [--method <method>] --tactic <Tactic> --ttp <TTP> [--args <arguments>]

Methods:
  curl                   Use curl to download the script (default)
  wget                   Use wget to download the script
  osascript             Use AppleScript to download the script
  local                 Execute the script locally

Required:
  --tactic <Tactic>     Specify the tactic
  --ttp <TTP>          Specify the TTP

Optional:
  --method <method>     Specify the method (default: curl)
  --args <arguments>    Specify arguments for the TTP script
  --banner             Display the ASCII art banner
  --list               List available TTPs for a tactic (use with --tactic)
  -h, --help           Display this help message

Examples:
  $(basename "$0") --method local --tactic discovery --ttp browser_history --args='-s'
  $(basename "$0") --list --tactic discovery
EOF
}

# Display banner
display_banner() {
    cat << "EOF"

                                  █████████████████
                  ███████████████████████████████████████████████
                 █            █████████████████████████          █
                ██               ███████████████████             ██
                ██                ████████████████              ██
                ██                 █████   ██████                ██
                 █                                               █
                 █                                               █
                ███     █                                 █     ███
                ████   █████                          ██████   ████
               ██████  ████████                    █████████  ██████
               ██████   ███████████            ███████████   ██████
               ██████    ████████████        █████████████    ██████
              ██████      ████████████      █████████████     ██████
               ██████      ██████████        ███████████     ██████
            ██████                                             ███████
              ███  ████                ████               ████   ██
             ███  █████                ██               ██████   ███
          ██  ██ ███ █████                            ██████ █████  █
              ██  ████ ████████                    ████████ ████  ██
              █████ ██ ████████████████████████████████████  ██ █ ███
                ████      ███████████████████████████████      ███
                 █           █████████████████████████          █
                                 ████████████████

                         A  t  t  a  c  k  m  a  c  O  S

EOF
}

#------------------------------------------------------------------------------
# Utility Functions
#------------------------------------------------------------------------------

# Log message with timestamp and level
log_message() {
    [ "$LOG_ENABLED" = "false" ] && return 0
    local level="$1"
    local message="$2"
    printf "[%s] [%s] %s\\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >&2
}

# Silent output handler with logging
output() {
    local level="$1"
    local message="$2"
    local return_code="${3:-0}"
    
    log_message "$level" "$message"
    [ "$level" = "error" ] && printf "Error: %s\\n" "$message" >&2 && return "${return_code:-$E_FAILURE}"
    [ "$VERBOSE" = "true" ] && printf "%s\\n" "$message"
    return 0
}

# Check required dependencies
check_dependencies() {
    local missing=false
    local deps=()
    
    case "$1" in
        "$METHOD_CURL") deps+=("curl") ;;
        "$METHOD_WGET") deps+=("wget") ;;
        "$METHOD_OSASCRIPT") deps+=("osascript") ;;
    esac
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            output "error" "Missing required dependency: $dep" "$E_MISSING_DEPS"
            missing=true
        fi
    done
    
    [ "$missing" = "true" ] && return "$E_MISSING_DEPS"
    return 0
}

# Validate input string is not empty and contains no dangerous characters
validate_input() {
    input="$1"
    name="$2"
    
    [ -z "$input" ] && {
        echo "Error: $name cannot be empty" >&2
        return 1
    }
    
    case "$input" in
        *[\;\|\&\$\(\)\{\}\[\]\<\>\`]*)
            echo "Error: Invalid characters in $name" >&2
            return 1
            ;;
    esac
    return 0
}

# Check if tactic exists
validate_tactic() {
    tactic="$1"
    echo "$TACTICS" | grep -q -w "$tactic" || {
        echo "Invalid tactic: $tactic" >&2
        return 1
    }
    return 0
}

# Validate TTP exists
validate_ttp() {
    local tactic="$1"
    local ttp="$2"
    local base_path="$SCRIPT_DIR/ttp/$tactic"
    
    [ -f "$base_path/$ttp.sh" ] && return 0
    [ -f "$base_path/$ttp/$ttp.sh" ] && return 0
    
    output "error" "Invalid TTP: $ttp for tactic: $tactic" "$E_INVALID_TTP"
    return "$E_INVALID_TTP"
}

# Get available TTPs for a tactic
get_ttps() {
    tactic="$1"
    base_dir="$SCRIPT_DIR/ttp/$tactic"
    ttps=""
    
    [ ! -d "$base_dir" ] && return 1

    for dir in "$base_dir"/*; do
        [ "$dir" = "$base_dir/*" ] && continue
        [ -d "$dir" ] && [ -n "$(find "$dir" -maxdepth 1 -name "*.sh" 2>/dev/null)" ] && {
            ttps="$ttps$(basename "$dir")\n"
        }
    done

    [ -z "$ttps" ] && return 1
    printf "%b" "$ttps" | sort -u
}

#------------------------------------------------------------------------------
# Core Functions
#------------------------------------------------------------------------------

# Execute local TTP
execute_local() {
    tactic="$1"
    ttp="$2"
    args="$3"
    base_path="$SCRIPT_DIR/ttp/$tactic"
    script_path=""

    validate_input "$tactic" "tactic" || return 1
    validate_input "$ttp" "TTP" || return 1
    [ -n "$args" ] && validate_input "$args" "arguments" || return 1

    # Find script path - try multiple patterns
    [ -f "$base_path/$ttp.sh" ] && script_path="$base_path/$ttp.sh"
    [ -f "$base_path/$ttp/$ttp.sh" ] && script_path="$base_path/$ttp/$ttp.sh"
    
    # If not found, look for any .sh file in the TTP directory
    if [ -z "$script_path" ] && [ -d "$base_path/$ttp" ]; then
        script_path=$(find "$base_path/$ttp" -maxdepth 1 -name "*.sh" -type f | head -1)
    fi

    [ -z "$script_path" ] && {
        echo "Script not found: $ttp" >&2
        return 1
    }
    
    cd "$(dirname "$script_path")" 2>/dev/null || {
        echo "Failed to change directory" >&2
        return 1
    }
    
    execute_script "$(basename "$script_path")" "$args"
}

# Execute remote TTP via curl
execute_curl() {
    tactic="$1"
    ttp="$2"
    args="$3"
    url="$GIT_URL"
    url="$(echo "$url" | sed "s/{tactic}/$tactic/;s/{ttp}/$ttp/")"
    
    validate_input "$tactic" "tactic" || return 1
    validate_input "$ttp" "TTP" || return 1
    [ -n "$args" ] && validate_input "$args" "arguments" || return 1
    
    command -v curl >/dev/null 2>&1 || {
        echo "curl is required but not installed" >&2
        return 1
    }
    
    execute_script curl "$url" "$args"
}

# Execute remote TTP via wget
execute_wget() {
    tactic="$1"
    ttp="$2"
    args="$3"
    url="$GIT_URL"
    url="$(echo "$url" | sed "s/{tactic}/$tactic/;s/{ttp}/$ttp/")"
    
    validate_input "$tactic" "tactic" || return 1
    validate_input "$ttp" "TTP" || return 1
    [ -n "$args" ] && validate_input "$args" "arguments" || return 1
    
    command -v wget >/dev/null 2>&1 || {
        echo "wget is required but not installed" >&2
        return 1
    }
    
    execute_script wget "$url" "$args"
}

# Execute remote TTP via osascript
execute_osascript() {
    tactic="$1"
    ttp="$2"
    args="$3"
    url="$GIT_URL"
    url="$(echo "$url" | sed "s/{tactic}/$tactic/;s/{ttp}/$ttp/")"
    
    validate_input "$tactic" "tactic" || return 1
    validate_input "$ttp" "TTP" || return 1
    [ -n "$args" ] && validate_input "$args" "arguments" || return 1
    
    command -v osascript >/dev/null 2>&1 || {
        echo "osascript is required but not installed" >&2
        return 1
    }
    
    execute_script osascript "$url" "$args"
}

# Execute TTP with specified method
execute_ttp() {
    method="$1"
    tactic="$2"
    ttp="$3"
    args="$4"
    
    validate_tactic "$tactic" || return 1
    
    case "$method" in
        "$METHOD_LOCAL"|"local")     execute_local "$tactic" "$ttp" "$args" ;;
        "$METHOD_CURL"|"curl")      execute_curl "$tactic" "$ttp" "$args" ;;
        "$METHOD_WGET"|"wget")      execute_wget "$tactic" "$ttp" "$args" ;;
        "$METHOD_OSASCRIPT"|"osascript") execute_osascript "$tactic" "$ttp" "$args" ;;
        *)
            echo "Invalid method: $method" >&2
            echo "Valid methods: local, curl, wget, osascript" >&2
            return 1
            ;;
    esac
    
    return "$?"
}

# List available TTPs
list_ttps() {
    local tactic="$1"
    local ttps=""
    
    if [ -n "$tactic" ]; then
        validate_tactic "$tactic" || {
            echo "Invalid tactic: $tactic" >&2
            echo "Available tactics: ${TACTICS[*]}" >&2
            return 1
        }
        
        ttps=$(get_ttps "$tactic") || {
            echo "No TTPs found for $tactic" >&2
            return 1
        }
        
        echo "Available TTPs for $tactic:"
        printf "%s\n" "$ttps" | sed 's/^/- /'
    else
        echo "Available TTPs by tactic:"
        for t in "${TACTICS[@]}"; do
            ttps=$(get_ttps "$t") || continue
            echo
            echo "$t:"
            printf "%s\n" "$ttps" | sed 's/^/  /'
        done
    fi
}

#------------------------------------------------------------------------------
# Main Execution
#------------------------------------------------------------------------------

main() {
    local method="$DEFAULT_METHOD"
    local tactic=""
    local ttp=""
    local args=""
    local show_banner=false
    local list_mode=false

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --method=*)
                method="${1#*=}"
                shift
                ;;
            --method)
                [ -z "$2" ] && {
                    echo "Missing method argument" >&2
                    return 1
                }
                method="$2"
                shift 2
                ;;
            --tactic=*)
                tactic="${1#*=}"
                shift
                ;;
            --tactic)
                [ -z "$2" ] && {
                    echo "Missing tactic argument" >&2
                    return 1
                }
                tactic="$2"
                shift 2
                ;;
            --ttp=*)
                ttp="${1#*=}"
                shift
                ;;
            --ttp)
                [ -z "$2" ] && {
                    echo "Missing TTP argument" >&2
                    return 1
                }
                ttp="$2"
                shift 2
                ;;
            --args=*)
                args="${1#*=}"
                shift
                ;;
            --args)
                [ -z "$2" ] && {
                    echo "Missing args argument" >&2
                    return 1
                }
                args="$2"
                shift 2
                ;;
            --banner)
                show_banner=true
                shift
                ;;
            --list)
                list_mode=true
                shift
                ;;
            -h|--help)
                display_help
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                display_help
                return 1
                ;;
        esac
    done

    # Validate method
    case "$method" in
        "$METHOD_LOCAL"|"local"|"$METHOD_CURL"|"curl"|"$METHOD_WGET"|"wget"|"$METHOD_OSASCRIPT"|"osascript") 
            ;;
        *)
            echo "Invalid method: $method" >&2
            echo "Valid methods: local, curl, wget, osascript" >&2
            return 1
            ;;
    esac

    # Show banner if requested
    [ "$show_banner" = true ] && display_banner

    # Handle list mode
    [ "$list_mode" = true ] && { list_ttps "$tactic"; return $?; }

    # Validate required arguments
    [ -z "$tactic" ] || [ -z "$ttp" ] && {
        echo "Both --tactic and --ttp are required" >&2
        return 1
    }

    # Execute TTP
    execute_ttp "$method" "$tactic" "$ttp" "$args"
}

# Execute main function with all arguments
main "$@"
