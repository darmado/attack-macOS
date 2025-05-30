# Log Output

### Purpose
Creates log directory if needed, rotates log files when they exceed size limits, writes structured log entries with metadata (timestamp, PID, job ID, TTP info), and sends entries to both file and syslog. Also outputs to stdout in debug mode.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `LOG_ENABLED` | `false` |
| Global Variable | `LOG_DIR` | `"./logs"` |
| Global Variable | `LOG_FILE_NAME` | `"${TTP_ID}_${NAME}.log"` |
| Global Variable | `LOG_MAX_SIZE` | `5242880` |
| Global Variable | `JOB_ID` | `""` |
| Global Variable | `OWNER` | `"$USER"` |
| Global Variable | `PARENT_PROCESS` | `""` |
| Global Variable | `TTP_ID` | `""` |
| Global Variable | `TACTIC` | `""` |
| Global Variable | `FORMAT` | `"raw"` |
| Global Variable | `ENCODING_TYPE` | `"none"` |
| Global Variable | `ENCRYPTION_TYPE` | `"none"` |
| Global Variable | `EXFIL_TYPE` | `"none"` |
| Global Variable | `SCRIPT_CMD` | `""` |
| Global Variable | `SYSLOG_TAG` | `"${NAME}"` |
| Global Variable | `DEBUG` | `false` |
| Global Variable | `CMD_MKDIR` | `"mkdir"` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_STAT` | `"stat"` |
| Global Variable | `CMD_MV` | `"mv"` |
| Global Variable | `CMD_LOGGER` | `"logger"` |
| Function | `core_get_timestamp()` | For timestamp generation |
| Function | `core_debug_print()` | For debug logging |

<details>

```shell
core_log_output() {
    local output="$1"
    local status="${2:-info}"
    local skip_data="${3:-false}"
    
    if [ "$LOG_ENABLED" = true ]; then
        # Ensure log directory exists
        if [ ! -d "$LOG_DIR" ]; then
            $CMD_MKDIR -p "$LOG_DIR" 2>/dev/null || {
                $CMD_PRINTF "Warning: Failed to create log directory.\n" >&2
                return 1
            }
        fi
        
        # Check log size and rotate if needed
        if [ -f "$LOG_DIR/$LOG_FILE_NAME" ] && [ "$($CMD_STAT -f%z "$LOG_DIR/$LOG_FILE_NAME" 2>/dev/null || "$CMD_PRINTF" 0)" -gt "$LOG_MAX_SIZE" ]; then
            $CMD_MV "$LOG_DIR/$LOG_FILE_NAME" "$LOG_DIR/${LOG_FILE_NAME}.$(date +%Y%m%d%H%M%S)" 2>/dev/null
            core_debug_print "Log file rotated due to size limit"
        fi
        
        # Log detailed entry
        "$CMD_PRINTF" "[%s] [%s] [PID:%d] [job:%s] owner=%s parent=%s ttp_id=%s tactic=%s format=%s encoding=%s encryption=%s exfil=%s status=%s\\n" \
            "$(core_get_timestamp)" \
            "$status" \
            "$$" \
            "${JOB_ID:-NOJOB}" \
            "$OWNER" \
            "$PARENT_PROCESS" \
            "$TTP_ID" \
            "$TACTIC" \
            "${FORMAT:-raw}" \
            "$ENCODING_TYPE" \
            "${ENCRYPTION_TYPE:-none}" \
            "${EXFIL_TYPE:-none}" >> "$LOG_DIR/$LOG_FILE_NAME"
            
        if [ "$skip_data" = "false" ] && [ -n "$output" ]; then
            "$CMD_PRINTF" "command: %s\\ndata:\\n%s\\n---\\n" \
                "$SCRIPT_CMD" \
                "$output" >> "$LOG_DIR/$LOG_FILE_NAME"
        else
            "$CMD_PRINTF" "command: %s\\n---\\n" \
                "$SCRIPT_CMD" >> "$LOG_DIR/$LOG_FILE_NAME"
        fi

        # Also log to syslog
        $CMD_LOGGER -t "$SYSLOG_TAG" "job=${JOB_ID:-NOJOB} status=$status ttp_id=$TTP_ID tactic=$TACTIC exfil=${EXFIL_TYPE:-none} encoding=$ENCODING_TYPE encryption=${ENCRYPTION_TYPE:-none} cmd=\"$SCRIPT_CMD\""
    fi
    
    # Output to stdout if in debug mode only
    if [ "$DEBUG" = true ]; then
        $CMD_PRINTF "[%s] [%s] %s\\n" "$(core_get_timestamp)" "$status" "$output"
    fi
}
```

</details> 