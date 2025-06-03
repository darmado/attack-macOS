# Verbose Print

### Purpose
Checks the global `VERBOSE` flag and if true, prints formatted informational messages to stdout with timestamp prefix. Used for providing detailed execution information to users.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `VERBOSE` | `false` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Function | `core_get_timestamp()` | For timestamp generation |

<details>

```shell
core_verbose_print() {
    if [ "$VERBOSE" = true ]; then
        local timestamp=$(core_get_timestamp)
        $CMD_PRINTF "[INFO] [%s] %s\n" "$timestamp" "$1"
    fi
}
```

</details> 