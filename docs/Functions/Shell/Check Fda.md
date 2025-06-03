# Check Fda

### Purpose
Checks if both system and user TCC databases exist and are readable for Full Disk Access validation.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `TCC_SYSTEM_DB` | `"/Library/Application Support/com.apple.TCC/TCC.db"` |
| Global Variable | `TCC_USER_DB` | `"$HOME/Library/Application Support/com.apple.TCC/TCC.db"` |

<details>

```shell
core_check_fda() {
[ -f "$TCC_SYSTEM_DB" ] && [ -r "$TCC_SYSTEM_DB" ] && [ -f "$TCC_USER_DB" ] && [ -r "$TCC_USER_DB" ]
}
```

</details> 