# Get Content Type

### Purpose
core_get_content_type function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | "printf" |
| Global Variable | `ENCODE` | "none" |
| Function | `core_get_content_type()` | For get content type |

<details>

```shell
core_get_content_type() {
local content_type="text/plain"
    if [ "$ENCODE" = "base64" ] || [ "$ENCODE" = "b64" ]; then
        content_type="application/base64"
    elif [ "$ENCODE" = "hex" ] || [ "$ENCODE" = "xxd" ]; then
        content_type="application/octet-stream"
    fi
    "$CMD_PRINTF"  "$content_type"
}
```

</details> 
