# Extract Steganography

### Purpose
core_extract_steganography function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_BASE64` | "base64" |
| Global Variable | `CMD_GREP` | "grep" |
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `CMD_STRINGS` | "strings" |
| Global Variable | `CMD_TAIL` | "tail" |
| Function | `core_extract_steganography()` | For extract steganography |
| Function | `core_handle_error()` | For handle error |

<details>

```shell
core_extract_steganography() {
local steg_file="$1"
    
    # Verify file exists
    if [ ! -f "$steg_file" ]; then
        core_handle_error "Steganography file not found: $steg_file"
        return 1
    fi
    
    # Extract the hidden data
    local encoded_data=""
    encoded_data=$($CMD_STRINGS "$steg_file" | $CMD_GREP -A1 'STEG_DATA_START' | $CMD_TAIL -1)
    
    if [ -z "$encoded_data" ]; then
        core_handle_error "No hidden data found in file: $steg_file"
        return 1
    fi
    
    # Decode the base64 data
    local decoded_data=""
    decoded_data=$("$CMD_PRINTF" '%s' "$encoded_data" | $CMD_BASE64 -d 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        core_handle_error "Failed to decode hidden data"
        return 1
    fi
    
    # Return the decoded data
    "$CMD_PRINTF" '%s' "$decoded_data"
    return 0
}
```

</details> 
