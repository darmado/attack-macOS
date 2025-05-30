# Get Timestamp

### Purpose
Executes the `date` command with format "+%Y-%m-%d %H:%M:%S" to return a standardized timestamp string for consistent logging and output formatting across all framework functions.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Command | `date` | System date utility |

<details>

```shell
core_get_timestamp() {
    # Use direct command to avoid variable expansion issues
    date "+%Y-%m-%d %H:%M:%S"
}
```

</details> 