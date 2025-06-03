# Generate Json Payload

## Purpose

core_generate_json_payload function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
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

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
