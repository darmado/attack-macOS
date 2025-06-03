# Get Content Type

## Purpose

core_get_content_type function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_get_content_type() {
local content_type="text/plain"
    if [ "$ENCODE" = "base64" ] || [ "$ENCODE" = "b64" ]; then
        content_type="application/base64"
    elif [ "$ENCODE" = "hex" ] || [ "$ENCODE" = "xxd" ]; then
        content_type="application/octet-stream"
    fi
    "$CMD_PRINTF"  "$content_type"
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
