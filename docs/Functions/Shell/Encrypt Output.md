# Encrypt Output

### Purpose
Converts encryption method to lowercase, then routes to specific encryption functions: `encrypt_with_aes()` for AES-256-CBC, `encrypt_with_gpg()` for GPG symmetric, `encrypt_with_xor()` for XOR, or returns original data for "none" or unknown methods.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `ENCRYPT_KEY` | `""` |
| Command | `tr` | For case conversion |
| Function | `encrypt_with_aes()` | For AES encryption |
| Function | `encrypt_with_gpg()` | For GPG encryption |
| Function | `encrypt_with_xor()` | For XOR encryption |
| Function | `core_debug_print()` | For debug logging |

<details>

```shell
core_encrypt_output() {
local data="$1"
    local method="$2"
    local key="${3:-$ENCRYPT_KEY}"
    
    # Convert to lowercase using tr for sh compatibility
    method=$("$CMD_PRINTF" '%s' "$method" | tr '[:upper:]' '[:lower:]')
    
    case "$method" in
        "none")
            # No encryption, just return the original data
            core_debug_print "No encryption requested, returning raw data"
            "$CMD_PRINTF" '%s' "$data"
            return 0
            ;;
        "aes")
            # Use AES encryption method
            core_debug_print "Using AES encryption method"
            encrypt_with_aes "$data" "$key"
            return $?
            ;;
        "gpg")
            # Use GPG encryption method
            core_debug_print "Using GPG encryption method"
            encrypt_with_gpg "$data" "$key"
            return $?
            ;;
        "xor")
            # Use XOR encryption method
            core_debug_print "Using XOR encryption method"
            encrypt_with_xor "$data" "$key"
            return $?
            ;;
        *)
            # Invalid encryption method
            core_debug_print "Unknown encryption type: $method - using raw"
            "$CMD_PRINTF" '%s' "$data"
            return 0
            ;;
    esac
}
```

</details> 