#!/bin/bash

# Array of procedure names
procedures=(
    "browser_history"
    "emails" 
    "hide_artifacts"
    "local_accounts"
    "modify_preferences"
    "screen_capture"
    "search_urls"
    "security_software"
    "system_info"
    "web_session_cookies"
)

# Function to get tactic directory from procedure name
get_tactic() {
    case "$1" in
        "browser_history"|"emails"|"local_accounts"|"search_urls"|"security_software"|"system_info")
            echo "discovery"
            ;;
        "hide_artifacts")
            echo "defense_evasion"
            ;;
        "modify_preferences")
            echo "persistence"
            ;;
        "screen_capture")
            echo "collection"
            ;;
        "web_session_cookies")
            echo "credential_access"
            ;;
        *)
            echo "discovery"
            ;;
    esac
}

for procedure in "${procedures[@]}"; do
    tactic=$(get_tactic "$procedure")
    yaml_file="attackmacos/core/config/${procedure}.yml"
    script_file="attackmacos/ttp/${tactic}/shell/${procedure}.sh"
    
    echo "Committing $procedure pair..."
    echo "  YAML: $yaml_file"
    echo "  Script: $script_file"
    
    git add "$yaml_file" "$script_file"
    git commit -m "Update $procedure: Enhanced YAML structure and shell script

- Updated YAML configuration
- Improved shell script implementation  
- Applied naming conventions and best practices"
    git push
    echo "Completed: $procedure"
    echo "---"
done

echo "All procedure pairs committed successfully!" 