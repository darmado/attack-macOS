# Steganography

### Purpose
Hides data in image files using native macOS tools by appending Base64-encoded data with special markers to the end of image files. Image viewers ignore the appended data while preserving file functionality.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_BASE64` | "base64" |
| Global Variable | `CMD_CAT` | "cat" |
| Global Variable | `CMD_CP` | "cp" |
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `CMD_SED` | "sed" |
| Global Variable | `CMD_WC` | "wc" |
| Global Variable | `STEG_CARRIER_IMAGE` | "" |
| Global Variable | `STEG_EXTRACT_FILE` | "" |
| Global Variable | `STEG_OUTPUT_IMAGE` | "" |
| Function | `core_handle_error()` | For handle error |
| Function | `core_steganography()` | For steganography |
| Command | `date` | For date operations |

<details>

```shell
core_steganography() {
# Define local variables
    local message=""
    local carrier_image=""
    local output_image=""
    local input_file=""
    local result=""
    
    # Get values from globals or use defaults
    input_file="$STEG_EXTRACT_FILE"
    message="$STEG_MESSAGE"
    carrier_image="${STEG_CARRIER_IMAGE:-$DEFAULT_STEG_CARRIER}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Verify we have either input file or message
    if [ -z "$input_file" ] && [ -z "$message" ]; then
        message="Hidden data created with ATT&CK macOS T1027.013"
        "$CMD_PRINTF"  "[INFO] [%s] No data specified, using default message
" "$(core_get_timestamp)"
    fi
    
    # Validate carrier image exists
    if [ ! -f "$carrier_image" ]; then
        core_handle_error "Carrier image not found: $carrier_image"
        return 1
    fi
    
    # If using input file, verify it exists
    if [ -n "$input_file" ] && [ ! -f "$input_file" ]; then
        core_handle_error "Input file not found: $input_file"
        return 1
    fi
    
    # Prepare data to hide - either from file or message
    local data_to_hide=""
    if [ -n "$input_file" ]; then
        # Read input file
        data_to_hide=$($CMD_CAT "$input_file" 2>/dev/null)
        if [ $? -ne 0 ]; then
            core_handle_error "Failed to read input file: $input_file"
            return 1
        fi
    else
        # Use message
        data_to_hide="$message"
    fi
    
    # Convert data to base64 to support all characters
    local encoded_data=""
    encoded_data=$("$CMD_PRINTF" '%s' "$data_to_hide" | $CMD_BASE64)
    
    # Use native tools to perform steganography
    # The approach is to append the data to the end of the image file
    # This works because image viewers stop rendering at the image end marker
    if $CMD_CP "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '

[STEG_DATA_START]
%s
[STEG_DATA_END]
' "$encoded_data" >> "$output_image"
        
        # Success message
        local data_size=$("$CMD_PRINTF"  -n "$data_to_hide" | $CMD_WC -c | $CMD_SED 's/^ *//')
        result="Steganography successful\nCarrier: $carrier_image\nOutput: $output_image\nHidden data size: $data_size bytes"
        "$CMD_PRINTF"  "$result"
        
        "$CMD_PRINTF"  "[INFO] [%s] Data hidden successfully in %s
" "$(core_get_timestamp)" "$output_image"
        return 0
    else
        core_handle_error "Failed to create steganography image: $output_image"
        return 1
    fi
}
```

</details> 
