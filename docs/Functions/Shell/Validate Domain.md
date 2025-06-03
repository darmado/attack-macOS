# Validate Domain

### Purpose
Validates domain resolution using three-tier fallback: 1) Uses `dig` with options for A record lookup, 2) Falls back to `host` command for address resolution, 3) Falls back to `nslookup` for address lookup. Skips empty domains and IP addresses, returns error if domain doesn't resolve.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_GREP` | `"grep"` |
| Global Variable | `CMD_DIG` | `"dig"` |
| Global Variable | `CMD_DIG_OPTS` | `"+short"` |
| Global Variable | `CMD_HOST` | `"host"` |
| Global Variable | `CMD_NSLOOKUP` | `"nslookup"` |
| Global Variable | `CMD_HEAD` | `"head"` |
| Function | `core_handle_error()` | For error reporting when domain doesn't resolve |

<details>

```shell
core_validate_domain() {
local domain="$1"
    
    # Skip empty domains
    [ -z "$domain" ] && return 0
    
    # Skip IP addresses
    if "$CMD_PRINTF"  "$domain" | $CMD_GREP -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        return 0
    fi
    
    # Try DNS resolution with fallback tools - assume commands exist
    local resolved=""
    
        resolved=$($CMD_DIG $CMD_DIG_OPTS "$domain" A 2>/dev/null)
        if [ -n "$resolved" ]; then
            return 0
        fi
    
        resolved=$($CMD_HOST "$domain" 2>/dev/null | $CMD_GREP "has address" | $CMD_HEAD -1)
        if [ -n "$resolved" ]; then
            return 0
        fi
    
        resolved=$($CMD_NSLOOKUP "$domain" 2>/dev/null | $CMD_GREP "Address:" | $CMD_GREP -v "#53" | $CMD_HEAD -1)
        if [ -n "$resolved" ]; then
            return 0
        fi
    
    core_handle_error "Domain does not resolve: $domain"
    return 1
}
```

</details> 