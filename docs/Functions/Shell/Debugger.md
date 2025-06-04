# Debug Print

### Purpose
Outputs debug messages to stderr with timestamp when DEBUG flag is enabled for troubleshooting and development.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `DEBUG` | false |
| Function | `core_debug_print()` | For debug print |

<details>

```shell
core_debug_print() {
if [ "$DEBUG" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[DEBUG] [%s] %s
" "$timestamp" "$1" >&2
    fi
}
```

</details> 
