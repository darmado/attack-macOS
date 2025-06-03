# Url Safe Encode

### Purpose
Performs two-step encoding: 1) Base64 encodes the input data, 2) Makes it URL-safe by replacing '+' with '-', '/' with '_', and removing '=' padding characters using `tr` command.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_BASE64` | `"base64"` |
| Command | `tr` | For character replacement and removal |

<details>

```shell
core_url_safe_encode() {
local data="$1"
    local encoded
    
    # First base64 encode
    encoded=$("$CMD_PRINTF" '%s' "$data" | $CMD_BASE64)
    
    # Then make URL-safe by replacing + with - and / with _
    encoded=$("$CMD_PRINTF" '%s' "$encoded" | tr '+/' '-_' | tr -d '=')
    
    $CMD_PRINTF "%s" "$encoded"
}
```

</details> 