# Extract Domain From Url

### Purpose
Uses `sed` with extended regex to parse a URL string and extract only the domain portion by removing protocol (http/https), path, and port information. Returns the clean domain name for validation purposes.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Command | `sed` | For regex pattern matching and extraction |

<details>

```shell
core_extract_domain_from_url() {
local url="$1"
    "$CMD_PRINTF"  "$url" | sed -E 's~^https?://([^/:]+).*~<details>

~'
}
```

</details> 