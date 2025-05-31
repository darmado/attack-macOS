# Process Output

### Purpose
Orchestrates a 5-step transformation pipeline: 1) Format output (JSON/CSV), 2) Apply encoding (base64/hex), 3) Apply encryption (AES/GPG/XOR), 4) Apply steganography if requested, 5) Handle JSON metadata for transformations. Returns the fully processed output string.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `FORMAT` | `"raw"` |
| Global Variable | `ENCODE` | `"none"` |
| Global Variable | `ENCRYPT` | `"none"` |
| Global Variable | `STEG_TRANSFORM` | `false` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Function | `core_format_output()` | For output formatting |
| Function | `core_encode_output()` | For data encoding |
| Function | `core_encrypt_output()` | For data encryption |
| Function | `core_apply_steganography()` | For steganography transformation |
| Function | `core_debug_print()` | For debug logging |

<details>

```shell
core_process_output() {
    local output="$1"
    local data_source="${2:-generic}"
    local processed="$output"
    local is_encoded=false
    local is_encrypted=false
    local is_steganography=false
    
    # 1. Format the output first if requested
    if [ -n "$FORMAT" ]; then
        if [ "$FORMAT" = "json" ] || [ "$FORMAT" = "JSON" ]; then
            # For JSON, only use raw data here - we'll add transformation metadata at the end
            processed=$(core_format_output "$output" "$FORMAT" "$procedure" "false" "none" "false" "none" "false")
        else
            # For other formats, just format the raw output
            processed=$(core_format_output "$output" "$FORMAT" "$procedure")
        fi
        core_debug_print "Output formatted as $FORMAT"
    fi
    
    # 2. Apply encoding if requested (after formatting)
    if [ "$ENCODE" != "none" ]; then
        core_debug_print "Applying encoding: $ENCODE"
        processed=$(core_encode_output "$processed" "$ENCODE")
        is_encoded=true
    fi
    
    # 3. Apply encryption if requested (after encoding)
    if [ "$ENCRYPT" != "none" ]; then
        core_debug_print "Applying encryption: $ENCRYPT"
        processed=$(core_encrypt_output "$processed" "$ENCRYPT")
        is_encrypted=true
    fi
    
    # 4. Apply steganography if requested (after encryption)
    if [ "$STEG_TRANSFORM" = true ]; then
        core_debug_print "Applying steganography transformation"
        # Save the processed data to the steganography image
        local steg_result=$(core_apply_steganography "$processed")
        # Only set the output metadata, the actual file is written directly
        processed="$steg_result"
        is_steganography=true
    fi
    
    # 5. If JSON formatting was requested, add the final metadata about transformations
    if [ -n "$FORMAT" ] && [ "$FORMAT" = "json" ] || [ "$FORMAT" = "JSON" ]; then
        # We already formatted the output, but add the transformation metadata
        if [ "$is_encoded" = true ] || [ "$is_encrypted" = true ] || [ "$is_steganography" = true ]; then
            # Don't double-wrap in JSON, just return the processed data with transformation flags
            # The metadata about transformations is informational only for the user
            core_debug_print "Preserving encoded/encrypted data in output"
        fi
    fi
    
    $CMD_PRINTF "%s" "$processed"
}
```

</details> 