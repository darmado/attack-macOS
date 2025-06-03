# Format As Csv

## Purpose

core_format_as_csv function implementation from base.sh.

## Implementation

<details>
<summary>Function Code</summary>

```bash
core_format_as_csv() {
local output="$1"
    local csv_output=""
    
    # Process each line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Replace pipe delimiters with commas
        csv_line=$("$CMD_PRINTF"  "$line" | sed 's/|/,/g')
        
        # Add to CSV output
        if [ -z "$csv_output" ]; then
            csv_output="$csv_line"
        else
            csv_output="${csv_output}\n$csv_line"
        fi
    done <<< "$output"
    
    # Output CSV directly
    $CMD_PRINTF "%s" "$csv_output"
}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
