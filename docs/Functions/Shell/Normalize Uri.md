# Normalize Uri

### Purpose
core_normalize_uri function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_GREP` | "grep" |
| Global Variable | `CMD_PRINTF` | "printf" |
| Function | `core_normalize_uri()` | For normalize uri |

<details>

```shell
core_normalize_uri() {
local uri="$1"
    
    if ! "$CMD_PRINTF"  "$uri" | $CMD_GREP -q "^http" ; then
        uri="http://$uri"
    fi
    $CMD_PRINTF "%s" "$uri"
}
```

</details> 
