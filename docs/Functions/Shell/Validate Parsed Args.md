# Validate Parsed Args

### Purpose
core_validate_parsed_args function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CHUNK_SIZE` | 50 |
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `ENCODE` | "none" |
| Global Variable | `ENCRYPT` | "none" |
| Global Variable | `EXFIL_METHOD` | "none" |
| Global Variable | `EXFIL_URI` | "" |
| Global Variable | `FORMAT` | "raw" |
| Global Variable | `LIST_FILES` | false |
| Global Variable | `PROXY_URL` | "" |
| Global Variable | `SHOW_HELP` | false |
| Global Variable | `STEG_CARRIER_IMAGE` | "" |
| Global Variable | `STEG_EXTRACT` | false |
| Global Variable | `STEG_EXTRACT_FILE` | "" |
| Global Variable | `STEG_OUTPUT_IMAGE` | "" |
| Function | `core_debug_print()` | For debug print |
| Function | `core_extract_domain_from_url()` | For extract domain from url |
| Function | `core_handle_error()` | For handle error |
| Function | `core_validate_domain()` | For validate domain |
| Function | `core_validate_input()` | For validate input |
| Function | `core_validate_parsed_args()` | For validate parsed args |
| Command | `date` | For date operations |
| Command | `tr` | For tr operations |

<details>

```shell
core_validate_parsed_args() {
local validation_errors=""
    local has_valid_actions=false
    
    # Check if we have any valid actions to execute
    if [ "$LIST_FILES" = true ] || [ "$STEG_EXTRACT" = true ] || [ "$SHOW_HELP" = true ]; then
        has_valid_actions=true
    fi
    
    # Validate chunk size if provided
    if [ -n "$CHUNK_SIZE" ]; then
        if ! core_validate_input "$CHUNK_SIZE" "integer"; then
            validation_errors="${validation_errors}Invalid chunk size: $CHUNK_SIZE (must be positive integer)
"
        fi
    fi
    
    # Validate format if provided
    if [ -n "$FORMAT" ]; then
        case "$FORMAT" in
            json|csv|raw) ;;
            *) 
                validation_errors="${validation_errors}Invalid format: $FORMAT (must be json, csv, or raw)
"
                ;;
        esac
    fi
    
    # Validate encoding if provided
    if [ -n "$ENCODE" ] && [ "$ENCODE" != "none" ]; then
        case "$ENCODE" in
            base64|b64|hex|perl_b64|perl_utf8) ;;
            *)
                validation_errors="${validation_errors}Invalid encoding: $ENCODE (must be base64, hex, perl_b64, or perl_utf8)
"
                ;;
        esac
    fi
    
    # Validate encryption if provided
    if [ -n "$ENCRYPT" ] && [ "$ENCRYPT" != "none" ]; then
        case "$ENCRYPT" in
            aes|gpg|xor) ;;
            *)
                validation_errors="${validation_errors}Invalid encryption: $ENCRYPT (must be aes, gpg, or xor)
"
                ;;
        esac
    fi
    
    # Validate exfiltration settings
    if [ "$EXFIL" = true ]; then
        if [ -z "$EXFIL_METHOD" ]; then
            validation_errors="${validation_errors}Exfiltration enabled but no method specified
"
        fi
        
        if [ -z "$EXFIL_URI" ]; then
            validation_errors="${validation_errors}Exfiltration enabled but no URI specified
"
        else
            # Validate the URI based on method
            case "$EXFIL_METHOD" in
                dns)
                    if ! core_validate_input "$EXFIL_URI" "domain"; then
                        validation_errors="${validation_errors}Invalid domain format: $EXFIL_URI
"
                    elif ! core_validate_domain "$EXFIL_URI"; then
                        validation_errors="${validation_errors}Domain does not resolve: $EXFIL_URI
"
                    fi
                    ;;
                http|https)
                    if ! core_validate_input "$EXFIL_URI" "url"; then
                        validation_errors="${validation_errors}Invalid URL format: $EXFIL_URI
"
                    else
                        # Extract and validate domain
                        local domain=$(core_extract_domain_from_url "$EXFIL_URI")
                        if ! core_validate_domain "$domain"; then
                            validation_errors="${validation_errors}Domain does not resolve: $domain (from URL: $EXFIL_URI)
"
                        fi
                    fi
                    ;;
                *)
                    validation_errors="${validation_errors}Invalid exfiltration method: $EXFIL_METHOD
"
                    ;;
            esac
        fi
    fi
    
    # Validate file paths if provided
    if [ -n "$STEG_EXTRACT_FILE" ]; then
        if ! core_validate_input "$STEG_EXTRACT_FILE" "file_path"; then
            validation_errors="${validation_errors}Invalid file path: $STEG_EXTRACT_FILE
"
        fi
    fi
    
    if [ -n "$STEG_CARRIER_IMAGE" ]; then
        if ! core_validate_input "$STEG_CARRIER_IMAGE" "file_path"; then
            validation_errors="${validation_errors}Invalid carrier image path: $STEG_CARRIER_IMAGE
"
        fi
    fi
    
    if [ -n "$STEG_OUTPUT_IMAGE" ]; then
        if ! core_validate_input "$STEG_OUTPUT_IMAGE" "file_path"; then
            validation_errors="${validation_errors}Invalid output image path: $STEG_OUTPUT_IMAGE
"
        fi
    fi
    
    # Validate proxy URL if provided
    if [ -n "$PROXY_URL" ]; then
        if ! core_validate_input "$PROXY_URL" "url"; then
            validation_errors="${validation_errors}Invalid proxy URL: $PROXY_URL
"
        fi
    fi
    
    # Report all validation errors at once
    if [ -n "$validation_errors" ]; then
        # If we have valid actions, continue; otherwise exit
        if [ "$has_valid_actions" = true ]; then
            # Format as single line warning since script continues
            local formatted_errors=$("$CMD_PRINTF"  "%b" "$validation_errors" | tr '
' '; ' | sed 's/; $//')
            "$CMD_PRINTF"  "[WARNING] [%s] Argument validation issues found: %s
" "$(core_get_timestamp)" "$formatted_errors" >&2
            return 0
        else
            core_handle_error "Argument validation errors found:"
            "$CMD_PRINTF"  "%b" "$validation_errors" >&2
            core_handle_error "No valid actions specified - exiting"
            return 1
        fi
    fi
    
    core_debug_print "All parsed arguments validated successfully"
    return 0
}
```

</details> 
