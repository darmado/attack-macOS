# Exec Cmd Herestring

### Purpose
core_exec_cmd_herestring function implementation from base.sh.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Function | `core_debug_print()` | For debug print |
| Function | `core_exec_cmd_herestring()` | For exec cmd herestring |

<details>

```shell
core_exec_cmd_herestring() {
local cmd_string="$1"
    
    if [ -z "$cmd_string" ]; then
        core_debug_print "No command provided to core_exec_cmd_herestring"
        return 1
    fi
    
    core_debug_print "Executing command via here-string: $cmd_string"
    
    # Execute command using here-string (feeds command as stdin to shell)
    sh <<< "$cmd_string"
    
    return $?
}
```

</details> 
