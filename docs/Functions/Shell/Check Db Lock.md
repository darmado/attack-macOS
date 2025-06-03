# Check Db Lock

### Purpose
Performs 3-method database lock detection: 1) Checks for SQLite lock files (-wal, -shm, -journal), 2) Uses `lsof` to detect processes with file open, 3) Attempts brief database query with timeout. Returns 1 if locked, 0 if available.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_LSOF` | `"lsof"` |
| Global Variable | `CMD_SQLITE3` | `"sqlite3"` |
| Builtin | `command` | For checking lsof availability |
| Command | `timeout` | For query timeout (if available) |
| Function | `core_debug_print()` | For debug logging |

<details>

```shell
core_check_db_lock() {
local db_path="$1"
    
    # Check if database file exists
    if [ ! -f "$db_path" ]; then
        return 1
    fi
    
    # Method 1: Check for SQLite lock files
    if [ -f "${db_path}-wal" ] || [ -f "${db_path}-shm" ] || [ -f "${db_path}-journal" ]; then
        core_debug_print "Database lock files detected for $db_path"
        return 1
    fi
    
    # Method 2: Check if any process has the database file open (macOS specific)
    if command -v "$CMD_LSOF" > /dev/null 2>&1; then
        if $CMD_LSOF "$db_path" > /dev/null 2>&1; then
            core_debug_print "Process has database file open: $db_path"
            return 1
        fi
    fi
    
    # Method 3: Try to open database briefly to check if it's locked (fallback)
    if ! timeout 1 $CMD_SQLITE3 "$db_path" "SELECT 1;" > /dev/null 2>&1; then
        core_debug_print "Database query test failed for $db_path"
        return 1
    fi
    
    core_debug_print "Database appears to be unlocked: $db_path"
    return 0
}
```

</details> 