# Validate Input

### Purpose
core_validate_input function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_GREP` | "grep" |
| Global Variable | `CMD_PRINTF` | "printf" |
| Function | `core_debug_print()` | For debug print |
| Function | `core_handle_error()` | For handle error |
| Function | `core_validate_input()` | For validate input |

<details>

```shell
core_validate_input() {
local input="$1"
    local validation_type="$2"
    
    # Check for empty input
    if [ -z "$input" ]; then
        core_handle_error "Empty input not allowed for type: $validation_type"
        return 1
    fi
    
    case "$validation_type" in
        "string")
            # Allow alphanumeric, spaces, hyphens, underscores, dots
            if "$CMD_PRINTF" "$input" | $CMD_GREP -q '[^a-zA-Z0-9 ._-]'; then
                core_handle_error "Invalid characters in string input: $input"
                return 1
            fi
            ;;
        "string_special")
            # For search terms and special input, just escape for SQL safety
            # Don't block legitimate characters - only handle actual security risks
            
            # Check for null bytes (actual security risk) using a simpler approach
    case "$input" in
                *$' '*)
                    core_handle_error "Null bytes not allowed in input: $input"
                    return 1
                    ;;
            esac
            
            # For SQL contexts, the calling function should handle escaping
            # We don't need to block legitimate characters here
            core_debug_print "Input validation passed for: $input"
            ;;
        "integer")
            # Must be a positive integer
            if ! "$CMD_PRINTF" "$input" | $CMD_GREP -q '^[0-9]\+$'; then
                core_handle_error "Invalid integer input: $input"
                return 1
            fi
            ;;
        "domain")
            # Basic domain format validation
            if ! "$CMD_PRINTF" "$input" | $CMD_GREP -q '^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$'; then
                core_handle_error "Invalid domain format: $input"
                return 1
            fi
            ;;
        "url")
            # Basic URL format validation
            if ! "$CMD_PRINTF" "$input" | $CMD_GREP -q '^https\?://[a-zA-Z0-9][a-zA-Z0-9.-]*'; then
                core_handle_error "Invalid URL format: $input"
                return 1
            fi
            ;;
        "file_path")
            # Basic file path validation - no null bytes, reasonable length
            if "$CMD_PRINTF" "$input" | $CMD_GREP -q $' ' || [ ${#input} -gt 4096 ]; then
                core_handle_error "Invalid file path: $input"
                return 1
            fi
            ;;
        *)
            core_handle_error "Unknown validation type: $validation_type"
            return 1
            ;;
    esac
    
    return 0
}
```

</details> 
