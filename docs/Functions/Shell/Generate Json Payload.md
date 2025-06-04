# Generate Json Payload

### Purpose
core_generate_json_payload function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_HOSTNAME` | "hostname" |
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `ENCODING_TYPE` | "none" |
| Global Variable | `ENCRYPTION_TYPE` | "none" |
| Global Variable | `JOB_ID` | "" |
| Global Variable | `TACTIC` | "" |
| Global Variable | `TTP_ID` | "" |
| Function | `core_generate_json_payload()` | For generate json payload |

<details>

```shell
core_generate_json_payload() {
local encoded_data="$1"
    local encrypted_key="$2"
    local hostname
    hostname=$($CMD_HOSTNAME 2>/dev/null || "$CMD_PRINTF"  "unknown")
    
    if [ -n "$encrypted_key" ]; then
        cat << EOF
{
  "encrypted_data": "$encoded_data",
  "metadata": {
    "hostname": "$hostname",
    "jobId": "$JOB_ID",
    "timestamp": "$(core_get_timestamp)",
    "ttpId": "$TTP_ID",
    "tactic": "$TACTIC",
    "encoding": "$ENCODING_TYPE",
    "encryption": "$ENCRYPTION_TYPE",
    "key": "$encrypted_key"
  }
}
```

</details> 
