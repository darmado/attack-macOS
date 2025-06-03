# Encode Output

### Purpose
Converts encoding type to lowercase, then applies the specified encoding method: base64 (using system base64), hex (using xxd), perl_b64 (using Perl MIME::Base64), or perl_utf8 (using Perl hex unpacking). Returns original data for unknown encoding types.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_BASE64` | `"base64"` |
| Global Variable | `CMD_XXD` | `"xxd"` |
| Global Variable | `CMD_PERL` | `"perl"` |
| Command | `tr` | For case conversion and character removal |
| Function | `core_debug_print()` | For debug logging |

<details>

```shell
core_encode_output() {
local output="$1"
    local encode_type="$2"
    # Convert to lowercase using tr for sh compatibility
    encode_type=$("$CMD_PRINTF" '%s' "$encode_type" | tr '[:upper:]' '[:lower:]')
    local encoded=""
    
    case "$encode_type" in
        base64|b64)
            # Debug information
            core_debug_print "Encoding with base64"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_BASE64)
            ;;
        hex)
            core_debug_print "Encoding with hex"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_XXD -p | tr -d '
')
            ;;
        perl_b64)
            core_debug_print "Encoding with perl base64"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_PERL -MMIME::Base64 -e 'print encode_base64(<STDIN>);')
            ;;
        perl_utf8)
            core_debug_print "Encoding with perl utf8"
            encoded=$("$CMD_PRINTF" '%s' "$output" | $CMD_PERL -e 'while (read STDIN, $buf, 1024) { print unpack("H*", $buf); }')
            ;;
        *)
            # Return unmodified if unknown encoding type
            core_debug_print "Unknown encoding type: $encode_type - using raw"
            encoded="$output"
            ;;
    esac
    
    $CMD_PRINTF "%s" "$encoded"
}
```

</details> 