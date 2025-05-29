# Get User Agent

### Purpose
Returns a hardcoded Safari user agent string for macOS Monterey to mimic legitimate browser traffic in HTTP requests and avoid detection by web application firewalls.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |

<details>

```shell
core_get_user_agent() {
    $CMD_PRINTF "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
}
```

</details> 