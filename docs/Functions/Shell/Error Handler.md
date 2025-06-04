# Handle Error

### Purpose
core_handle_error function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `LOG_ENABLED` | false |
| Function | `core_handle_error()` | For handle error |
| Function | `core_log_output()` | For log output |

<details>

```shell
core_handle_error() {
local error_msg="$1"
    local timestamp=$(core_get_timestamp)
    $CMD_PRINTF "[ERROR] [%s] %s
" "$timestamp" "$error_msg" >&2
    
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "$error_msg" "error" false
    fi
    
    return 1
}
```

</details> 
