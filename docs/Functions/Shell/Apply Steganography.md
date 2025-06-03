# Apply Steganography

## Purpose

core_apply_steganography function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_apply_steganography() {
local data_to_hide="$1"
    local carrier_image=""
    local output_image=""
    local result=""
    
    # Get values from globals or use defaults
    carrier_image="${STEG_CARRIER_IMAGE:-$DEFAULT_STEG_CARRIER}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Validate carrier image exists
    if [ ! -f "$carrier_image" ]; then
        core_handle_error "Carrier image not found: $carrier_image"
        return 1
    fi
    # Use native tools to perform steganography
    # The approach is to append the data to the end of the image file
    # This works because image viewers stop rendering at the image end marker
    if $CMD_CP "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '\n\n[STEG_DATA_START]\n%s\n[STEG_DATA_END]\n' "$data_to_hide" >> "$output_image"
        
        # Success message
        local data_size=$("$CMD_PRINTF"  -n "$data_to_hide" | $CMD_WC -c | $CMD_SED 's/^ *//')
        result="Steganography applied\\nCarrier: $carrier_image\\nOutput: $output_image\\nHidden data size: $data_size bytes"
        
        "$CMD_PRINTF"  "[INFO] [%s] Data hidden successfully in %s\n" "$(core_get_timestamp)" "$output_image"
        return 0
    else
        core_handle_error "Failed to create steganography image: $output_image"
        return 1
    fi
    
    "$CMD_PRINTF"  "$result"
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
