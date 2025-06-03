# Prepare Proxy Arg

### Purpose
Checks if `PROXY_URL` is set, validates it has a protocol prefix (adds "http://" if missing), then formats it as a curl-compatible proxy argument string ("--proxy URL") or returns empty string if no proxy configured.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `PROXY_URL` | `""` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_GREP` | `"grep"` |

<details>

```shell
core_prepare_proxy_arg() {
local proxy_arg=""
    
    if [ -n "$PROXY_URL" ]; then
        # Check if proxy has protocol prefix, add http:// if missing
        if ! "$CMD_PRINTF"  "$PROXY_URL" | $CMD_GREP -q "^http" ; then
            PROXY_URL="http://$PROXY_URL"
        fi
        proxy_arg="--proxy $PROXY_URL"
    fi
    $CMD_PRINTF "%s" "$proxy_arg"
}
```

</details> 