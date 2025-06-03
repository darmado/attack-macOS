# Normalize Uri

## Purpose

core_normalize_uri function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_normalize_uri() {
local uri="$1"
    
    if ! "$CMD_PRINTF"  "$uri" | $CMD_GREP -q "^http" ; then
        uri="http://$uri"
    fi
    $CMD_PRINTF "%s" "$uri"
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
