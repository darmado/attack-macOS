# Get Log Filename

### Purpose
core_get_log_filename function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `LOG_FILE_NAME` | "${TTP_ID}_${NAME}.log" |
| Global Variable | `PROCEDURE_NAME` | "" |
| Global Variable | `TTP_ID` | "" |
| Function | `core_get_log_filename()` | For get log filename |

<details>

```shell
core_get_log_filename() {
if [ -z "$LOG_FILE_NAME" ]; then
        if [ -n "$PROCEDURE_NAME" ]; then
            LOG_FILE_NAME="${TTP_ID}_${PROCEDURE_NAME}.log"
            SYSLOG_TAG="${TTP_ID}_${PROCEDURE_NAME}"
        else
            LOG_FILE_NAME="${TTP_ID}.log"
            SYSLOG_TAG="${TTP_ID}"
        fi
    fi
    echo "$LOG_FILE_NAME"
}
```

</details> 
