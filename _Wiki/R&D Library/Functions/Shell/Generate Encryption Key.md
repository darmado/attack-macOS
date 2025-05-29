# Generate Encryption Key

### Purpose
Checks if encryption is enabled (not "none"), then generates a SHA-256 hash from concatenated job ID, timestamp, and random number. Sets the global `ENCRYPT_KEY` variable and optionally prints key in debug mode.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `ENCRYPT` | `"none"` |
| Global Variable | `ENCRYPT_KEY` | `""` |
| Global Variable | `JOB_ID` | `""` |
| Global Variable | `DEBUG` | `false` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Global Variable | `CMD_OPENSSL` | `"openssl"` |
| Command | `date` | For timestamp generation |
| Command | `cut` | For extracting hash value |
| Function | `core_get_timestamp()` | For debug timestamp |
| Function | `core_debug_print()` | For debug logging |

<details>

```shell
core_generate_encryption_key() {
    if [ "$ENCRYPT" != "none" ]; then
        ENCRYPT_KEY=$("$CMD_PRINTF" '%s' "$JOB_ID$(date +%s%N)$RANDOM" | $CMD_OPENSSL dgst -sha256 | cut -d ' ' -f 2)
        if [ "$DEBUG" = true ]; then
            $CMD_PRINTF "[DEBUG] [%s] Using encryption key: %s\n" "$(core_get_timestamp)" "$ENCRYPT_KEY" >&2
        fi
        core_debug_print "Encryption key generated for method: $ENCRYPT"
    fi
}
```

</details> 