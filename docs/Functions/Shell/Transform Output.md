# Transform Output

### Purpose
Manages final output delivery through logging, exfiltration, and display. Always prints output to stdout, conditionally logs to file if enabled, conditionally exfiltrates if enabled, and prints encryption key in debug mode.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `LOG_ENABLED` | `false` |
| Global Variable | `EXFIL` | `false` |
| Global Variable | `DEBUG` | `false` |
| Global Variable | `ENCRYPT` | `"none"` |
| Global Variable | `ENCRYPT_KEY` | `""` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Function | `core_log_output()` | For logging output |
| Function | `core_exfiltrate_data()` | For data exfiltration |
| Function | `core_get_timestamp()` | For debug timestamp |

<details>

```shell
core_transform_output() {
local output="$1"
    
    # Log the output if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        core_log_output "$output" "output" false
    fi
    
    # Exfiltrate the output if exfiltration is enabled
    if [ "$EXFIL" = true ]; then
        core_exfiltrate_data "$output"
    fi
    
    # Always print data to ensure it's visible
    # Important to display encrypted/encoded data even when logging
    $CMD_PRINTF "%s
" "$output"
    
    # When encrypting, also print the key in debug mode
    if [ "$DEBUG" = true ] && [ "$ENCRYPT" != "none" ]; then
        $CMD_PRINTF "[DEBUG] [%s] Encryption key: %s
" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
    fi
}
```

</details> 