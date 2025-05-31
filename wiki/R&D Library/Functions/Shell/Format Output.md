# Format Output

### Purpose
Converts format string to lowercase using `tr`, then routes to appropriate formatting function based on format type. Supports JSON (calls `core_format_as_json`), CSV (calls `core_format_as_csv`), or returns raw data unchanged for other formats.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Command | `tr` | For case conversion |
| Function | `core_format_as_json()` | For JSON formatting |
| Function | `core_format_as_csv()` | For CSV formatting |

<details>

```shell
core_format_output() {
    local output="$1"
    local format="$2"
    # Convert to lowercase using tr for sh compatibility
    format=$("$CMD_PRINTF" '%s' "$format" | tr '[:upper:]' '[:lower:]')
    local data_source="${3:-generic}"
    local is_encoded="${4:-false}"
    local encoding="${5:-none}"
    local is_encrypted="${6:-false}"
    local encryption="${7:-none}"
    local is_steganography="${8:-false}"
    local formatted="$output"
    
    case "$format" in
        json|json-lines)
            formatted=$(core_format_as_json "$output" "$procedure" "$is_encoded" "$encoding" "$is_encrypted" "$encryption" "$is_steganography")
            ;;
        csv)
            formatted=$(core_format_as_csv "$output")
            ;;
        *)
            # Keep as raw
            ;;
    esac
    
    $CMD_PRINTF "%s" "$formatted"
}
```

</details> 