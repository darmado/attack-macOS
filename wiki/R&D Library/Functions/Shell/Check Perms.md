# Check Perms

### Purpose
Tests file existence and validates read, write, and execute permissions based on specified requirements. Returns 0 if all required permissions are granted, 1 if any are missing.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Function | `core_debug_print()` | For logging permission check results |

<details>

```shell
core_check_perms() {
    local file="$1"
    local read_required="$2"
    local write_required="$3"
    local execute_required="$4"
    
    # Check if file exists
    if [ ! -e "$file" ]; then
        core_debug_print "File does not exist: $file"
        # Only fail if any permission is required
        [ "$read_required" = "true" ] || [ "$write_required" = "true" ] || [ "$execute_required" = "true" ]
        return $?
    fi
    
    # Check required permissions
    local missing_perms=""
    [ "$read_required" = "true" ] && [ ! -r "$file" ] && missing_perms="${missing_perms}read "
    [ "$write_required" = "true" ] && [ ! -w "$file" ] && missing_perms="${missing_perms}write "
    [ "$execute_required" = "true" ] && [ ! -x "$file" ] && missing_perms="${missing_perms}execute "
    
    if [ -n "$missing_perms" ]; then
        core_debug_print "Missing required permissions for $file: $missing_perms"
        return 1
    fi
    
    core_debug_print "All required permissions granted for $file"
    return 0
}
```

</details> 