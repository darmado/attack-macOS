# Prepare Exfil Data

### Purpose
core_prepare_exfil_data function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | "printf" |
| Function | `core_prepare_exfil_data()` | For prepare exfil data |

<details>

```shell
core_prepare_exfil_data() {
local data="$1"
    
            if [ -n "$EXFIL_START" ]; then
        data="${EXFIL_START}${data}"
            fi
    
            if [ -n "$EXFIL_END" ]; then
        data="${EXFIL_END}${data}"
    fi
    "$CMD_PRINTF"  "$data"
}
```

</details> 
