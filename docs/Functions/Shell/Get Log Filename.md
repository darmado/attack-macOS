# Get Log Filename

## Purpose

core_get_log_filename function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
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

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
