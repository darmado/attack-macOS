# Format As Json

## Purpose

core_format_as_json function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_format_as_json() {
local output="$1"
    local data_source="${2:-generic}"
    local is_encoded="${3:-false}"
    local encoding="${4:-none}"
    local is_encrypted="${5:-false}"
    local encryption="${6:-none}"
    local is_steganography="${7:-false}"
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
  \"procedure\": \"$PROCEDURE_NAME\","
    
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
  
    # Include steganography status
    json_output="$json_output
  \"steganography\": {"
    json_output="$json_output
    \"enabled\": $is_steganography,"
    if [ "$is_steganography" = true ] && [ -n "$STEG_OUTPUT_IMAGE" ]; then
        json_output="$json_output
    \"output\": \"$STEG_OUTPUT_IMAGE\""
    else
        json_output="$json_output
    \"output\": null"
    fi
    json_output="$json_output
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
        line=$("$CMD_PRINTF"  "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
        
        # Check if line is a number and JSON_DETECT_NUMBERS is true
        if [ "$JSON_DETECT_NUMBERS" = true ] && "$CMD_PRINTF"  "$line" | $CMD_GREP -E '^[0-9]+$' > /dev/null; then
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
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
