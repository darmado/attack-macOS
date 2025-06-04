# LOOBins to Procedure YAML Mapping

## Field Mapping Table

| LOOBins Field | Procedure Field | Conversion Logic |
|---------------|-----------------|------------------|
| `name` | `procedure_name` | Direct copy, convert to lowercase |
| `author` | `author` | Direct copy, fallback to default if missing |
| `short_description` | `intent` | Direct copy, truncate to 500 chars max |
| `full_description` | ❌ Not mapped | Skip - too verbose for intent field |
| `created` | ❌ Not mapped | Skip - different concept than procedure creation |
| `example_use_cases[].name` | `procedure.arguments[].option` | Convert to `--kebab-case`, remove filler words |
| `example_use_cases[].description` | `procedure.arguments[].description` | Direct copy, truncate to 100 chars |
| `example_use_cases[].code` | `procedure.functions[].code` | Wrap in function template |
| `example_use_cases[].tactics` | `tactic` | Use first tactic, map to MITRE enum |
| `example_use_cases[].tags` | `procedure.functions[].language` | Map actual tags to language array |
| `name` | `procedure.global_variable[].name` | Convert to `CMD_{NAME.upper()}` |
| `paths[0]` | `procedure.global_variable[].default_value` | Use first path as CMD value |
| `detections[]` | `detection[]` | Map name→ioc, url→analysis (skip if url="N/A") |
| `resources[]` | `resources[]` | Map name→description, url→link |

## Required Fields (Always Set)

| Procedure Field | Value | Logic |
|-----------------|-------|-------|
| `ttp_id` | `"T9999"` | Placeholder - user must update |
| `guid` | `str(uuid.uuid4())` | Generate new UUID |
| `version` | `"1.0.0"` | Default semantic version |
| `created` | `datetime.now().strftime('%Y-%m-%d')` | Current date |
| `updated` | Same as `created` | Same as created date |
| `platform` | `["macOS"]` | Default platform |

## Function Generation Logic

| LOOBins Input | Function Output | Template |
|---------------|-----------------|----------|
| `example_use_cases[].name` | Function name | `execute_{clean_name(name.lower())}` |
| `example_use_cases[].code` | Function body | Wrap one-liner in result capture template |
| `example_use_cases[].description` | Function comment | Add as comment in function |

### Function Name Cleaning (Remove Filler Words)
```python
FILLER_WORDS = {'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}

def clean_function_name(name):
    words = name.lower().split()
    clean_words = [w for w in words if w not in FILLER_WORDS]
    return '_'.join(clean_words)

# Examples:
# "Fork a process" → "fork_process" 
# "Prevent a sleep" → "prevent_sleep"
# "Use the textutil to read files" → "use_textutil_read_files"
```

### Function Template
```bash
{function_name}() {
    # {description}
    local result
    result=$({code} 2>&1)
    $CMD_PRINTF "RESULT|%s\\n" "$result"
    return 0
}
```

## Tactic Mapping

| LOOBins Tactic | MITRE Tactic | Notes |
|----------------|--------------|-------|
| `"Defense Evasion"` | `"Defense Evasion"` | Direct match |
| `"Execution"` | `"Execution"` | Direct match |
| `"Discovery"` | `"Discovery"` | Direct match |
| `"Collection"` | `"Collection"` | Direct match |
| `"Persistence"` | `"Persistence"` | Direct match |
| Other/Missing | `"Execution"` | Default fallback |

## Language Mapping (Respect Actual Tags)

| LOOBins Tag | Procedure Language | Notes |
|-------------|-------------------|-------|
| `"bash"` | `["shell"]` | Map bash to shell |
| `"zsh"` | `["shell"]` | Map zsh to shell |
| `"sh"` | `["shell"]` | Map sh to shell |
| `"python"` | `["python"]` | Direct mapping |
| `"javascript"` | `["javascript"]` | Direct mapping |
| `"swift"` | `["swift"]` | Direct mapping |
| `"applescript"` | `["applescript"]` | Direct mapping |
| Empty/Missing | `["shell"]` | Default to shell |

## Edge Cases & Validation

| Scenario | Handling |
|----------|----------|
| Missing `name` | Error - required field |
| Missing `example_use_cases` | Error - no functions to generate |
| Missing `paths` | Use `/usr/bin/{name}` as default |
| Empty `description` | Use `"Execute {name} commands"` |
| Multiple tactics per example | Use first tactic only |
| `url: "N/A"` in detections | Skip the analysis field |
| Empty tags array | Default to `["shell"]` |

## Implementation Notes

1. **Respect actual LOOBins data** - Use their tags, don't assume shell
2. **Clean function names** - Remove filler words for better naming
3. **Validate required fields** - Error if LOOBins missing critical data  
4. **Handle edge cases** - Graceful fallbacks documented above
5. **Preserve structure** - Use template as base, fill in mapped values
6. **User review required** - Always output placeholder TTP_ID for manual update 