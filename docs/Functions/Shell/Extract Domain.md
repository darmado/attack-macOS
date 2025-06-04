# Extract Domain

### Purpose
core_extract_domain function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | "printf" |
| Function | `core_extract_domain()` | For extract domain |

<details>

```shell
core_extract_domain() {
local uri="$1"
    "$CMD_PRINTF" '%s' "$uri" | sed -E 's~^https?://([^/:]+).*~<details>

~'
}
```

</details> 
