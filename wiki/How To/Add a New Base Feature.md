# Adding a Feature to base.sh

This guide explains how to add new features to the `base.sh` script while maintaining the modular and pipeline-based architecture. We'll use the implementation of steganography as a real-world example.

## Understanding base.sh Pipeline Architecture

The `base.sh` script is designed with a pipeline architecture that processes data through several stages:

```
raw_data → format → encode → encrypt → transform → exfil
```

Each step transforms the data in some way, making it progressively more evasive and harder to detect. This matches how real adversaries operate in the field.

## Key Components to Modify

When adding a new feature to the base.sh pipeline, you need to modify these key components:

1. **Global Configuration Variables** - Define flags and parameters
2. **Argument Parser** - Handle command-line options in `core_parse_args()`
3. **Argument Validation** - Validate inputs in `core_validate_parsed_args()`
4. **Core Processing Function** - Implement the feature's logic
5. **Data Pipeline Integration** - Integrate with the transformation pipeline in `core_process_output()`
6. **Help Text** - Document the new feature in `core_display_help()`
7. **JSON Metadata** - Add feature status to JSON output in `core_format_as_json()`

## Step 1: Add Global Configuration Variables

Define global variables to control your feature's behavior. These should go in the "Default settings" section:

```sh
# Default settings

DEBUG=false
SHOW_HELP=false
LIST_FILES=false
# Add your feature's global variables
FEATURE_ENABLED=false
FEATURE_OPTION=""
```

Example (Steganography):
```sh
STEG_TRANSFORM=false # Enable steganography transformation
STEG_CARRIER_IMAGE="" # Carrier image for steganography
STEG_OUTPUT_IMAGE="" # Output image for steganography
STEG_EXTRACT=false # Extract hidden data from steganography
STEG_EXTRACT_FILE="" # File to extract hidden data from
```

## Step 2: Update Argument Parser

Add your command-line options to the `core_parse_args()` function. Follow the current pattern for handling arguments with and without values:

```sh
# In core_parse_args()
--your-feature)
    FEATURE_ENABLED=true
    ;;
--feature-option)
    if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
        # Next arg starts with -, so no value provided
        MISSING_VALUES="$MISSING_VALUES $1"
    elif [ -n "$2" ]; then
        FEATURE_OPTION="$2"
        shift
    else
        MISSING_VALUES="$MISSING_VALUES $1"
    fi
    ;;
```

Example (Steganography):
```sh
--steganography)
    STEG_TRANSFORM=true
    ;;
--steg-carrier)
    if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
        MISSING_VALUES="$MISSING_VALUES $1"
    elif [ -n "$2" ]; then
        STEG_CARRIER_IMAGE="$2"
        shift
    else
        MISSING_VALUES="$MISSING_VALUES $1"
    fi
    ;;
--steg-output)
    if [ -n "$2" ] && [ "$2" != "${2#-}" ]; then
        MISSING_VALUES="$MISSING_VALUES $1"
    elif [ -n "$2" ]; then
        STEG_OUTPUT_IMAGE="$2"
        shift
    else
        MISSING_VALUES="$MISSING_VALUES $1"
    fi
    ;;
--steg-extract)
    STEG_EXTRACT=true
    if [ -n "$2" ] && [ ! "$2" = "${2#-}" ]; then
        STEG_EXTRACT_FILE="./hidden_data.png"
    elif [ -n "$2" ]; then
        STEG_EXTRACT_FILE="$2"
        shift
    else
        STEG_EXTRACT_FILE="./hidden_data.png"
    fi
    ;;
```

## Step 3: Add Argument Validation

Add validation for your feature's arguments in `core_validate_parsed_args()`:

```sh
# In core_validate_parsed_args()
# Validate your feature's file paths if provided
if [ -n "$FEATURE_OPTION" ]; then
    if ! core_validate_input "$FEATURE_OPTION" "file_path"; then
        validation_errors="${validation_errors}Invalid feature option: $FEATURE_OPTION\n"
    fi
fi
```

Example (Steganography):
```sh
# Validate file paths if provided
if [ -n "$STEG_EXTRACT_FILE" ]; then
    if ! core_validate_input "$STEG_EXTRACT_FILE" "file_path"; then
        validation_errors="${validation_errors}Invalid file path: $STEG_EXTRACT_FILE\n"
    fi
fi

if [ -n "$STEG_CARRIER_IMAGE" ]; then
    if ! core_validate_input "$STEG_CARRIER_IMAGE" "file_path"; then
        validation_errors="${validation_errors}Invalid carrier image path: $STEG_CARRIER_IMAGE\n"
    fi
fi

if [ -n "$STEG_OUTPUT_IMAGE" ]; then
    if ! core_validate_input "$STEG_OUTPUT_IMAGE" "file_path"; then
        validation_errors="${validation_errors}Invalid output image path: $STEG_OUTPUT_IMAGE\n"
    fi
fi
```

## Step 4: Implement Core Processing Function

Create a function that implements your feature's logic. Name it with the `core_` prefix and use global command variables:

```sh
# Purpose: Implement your feature's logic
# Inputs: $1 - Data to process
# Outputs: Processed data
# Side Effects: [Document any side effects]
core_your_feature() {
    local input_data="$1"
    
    # Use global command variables
    local processed_data=$("$CMD_PRINTF" '%s' "$input_data" | your_processing_command)
    
    "$CMD_PRINTF" '%s' "$processed_data"
    return 0
}
```

Example (Steganography):
```sh
# Purpose: Apply steganography to data in the processing pipeline
# Inputs: $1 - Data to hide in steganography
# Outputs: Status message (actual data is written to file)
# Side Effects: Creates output image file
core_apply_steganography() {
    local data_to_hide="$1"
    local carrier_image=""
    local output_image=""
    local result=""
    
    # Get values from globals or use defaults
    carrier_image="${STEG_CARRIER_IMAGE:-$DEFAULT_STEG_CARRIER}"
    output_image="${STEG_OUTPUT_IMAGE:-./hidden_data.png}"
    
    # Validate carrier image exists
    if [ ! -f "$carrier_image" ]; then
        core_handle_error "Carrier image not found: $carrier_image"
        return 1
    fi
    
    # Use native tools to perform steganography
    if $CMD_CP "$carrier_image" "$output_image" 2>/dev/null; then
        "$CMD_PRINTF" '\n\n[STEG_DATA_START]\n%s\n[STEG_DATA_END]\n' "$data_to_hide" >> "$output_image"
        
        # Success message
        local data_size=$("$CMD_PRINTF" -n "$data_to_hide" | $CMD_WC -c | $CMD_SED 's/^ *//')
        result="Steganography applied\\nCarrier: $carrier_image\\nOutput: $output_image\\nHidden data size: $data_size bytes"
        
        "$CMD_PRINTF" "[INFO] [%s] Data hidden successfully in %s\n" "$(core_get_timestamp)" "$output_image"
        return 0
    else
        core_handle_error "Failed to create steganography image: $output_image"
        return 1
    fi
    
    "$CMD_PRINTF" "$result"
}
```

## Step 5: Integrate with the Data Pipeline

Modify the `core_process_output()` function to include your feature in the pipeline:

```sh
# In core_process_output()
# 4. Apply your feature if requested (after encryption)
if [ "$FEATURE_ENABLED" = true ]; then
    core_debug_print "Applying your feature transformation"
    processed=$(core_your_feature "$processed")
    is_feature_applied=true
fi
```

Example (Steganography):
```sh
# 4. Apply steganography if requested (after encryption)
if [ "$STEG_TRANSFORM" = true ]; then
    core_debug_print "Applying steganography transformation"
    # Save the processed data to the steganography image
    local steg_result=$(core_apply_steganography "$processed")
    # Only set the output metadata, the actual file is written directly
    processed="$steg_result"
    is_steganography=true
fi
```

## Step 6: Update JSON Output Metadata

Modify the `core_format_as_json()` function to include your feature's status:

```sh
# In core_format_as_json()
# Include your feature's status
json_output="$json_output
  \"your_feature\": {"
json_output="$json_output
    \"enabled\": $is_feature_applied,"
json_output="$json_output
    \"options\": \"$FEATURE_OPTION\""
json_output="$json_output
  },"
```

Example (Steganography):
```sh
# Include steganography status
json_output="$json_output
  \"steganography\": {"
json_output="$json_output
    \"enabled\": $is_steganography,"
if [ "$is_steganography" = true ] && [ -n "$STEG_OUTPUT_IMAGE" ]; then
    json_output="$json_output
    \"output\": \"$STEG_OUTPUT_IMAGE\""
else
    json_output="$json_output
    \"output\": null"
fi
json_output="$json_output
  },"
```

## Step 7: Update Help Text

Add documentation for your feature in the `core_display_help()` function:

```sh
# In core_display_help()
  --your-feature         Description of your feature
  --feature-option VAL   Description of the option
```

Example (Steganography):
```sh
  --steganography        Transform output using steganography (hide in image file)
  --steg-message TEXT    Text message to hide (used when --steg-input not specified)
  --steg-input FILE      File containing data to hide
  --steg-carrier FILE    Carrier image file (default: system desktop picture)
  --steg-output FILE     Output image file (default: ./hidden_data.png)
  --steg-extract [FILE]  Extract hidden data from steganography image (default: ./hidden_data.png)
```

## Step 8: Add Main Function Integration (if needed)

If your feature can be used as a standalone action (like `--ls`), add it to `core_main()`:

```sh
# In core_main()
# Check if we should run your feature
elif [ "$FEATURE_ENABLED" = true ]; then
    # Execute your feature logic
    raw_output=$(core_your_feature_standalone)
    data_source="your_feature"
```

Example (Steganography extraction):
```sh
# Check if we should extract steganography data
elif [ "$STEG_EXTRACT" = true ]; then
    # Execute steganography extraction
    raw_output=$(core_extract_steganography "$STEG_EXTRACT_FILE")
    data_source="steg_extracted"
```

## Testing Your Feature

Test your feature with the full pipeline to ensure it integrates properly:

```sh
# Test basic functionality
./base.sh --ls --your-feature

# Test with encoding and encryption
./base.sh --ls --encode base64 --encrypt aes --your-feature --format json

# Test with debug output
./base.sh --ls --your-feature --debug
```

Example (Steganography):
```sh
# Test basic steganography
./base.sh --ls --steganography

# Test with full pipeline
./base.sh --ls --encode base64 --encrypt aes --steganography --steg-output ./hidden.png --format json

# Test extraction
./base.sh --steg-extract ./hidden.png --debug
```

## Best Practices for Adding Features

1. **Use Global Command Variables**: Always use `$CMD_PRINTF`, `$CMD_CP`, etc. instead of direct commands

2. **Follow Function Naming**: Use the `core_` prefix for base functions and descriptive verb names

3. **Proper Error Handling**: Use `core_handle_error()` and `core_debug_print()` for consistent messaging

4. **Input Validation**: Use `core_validate_input()` for all user inputs

5. **POSIX Compatibility**: Ensure shell compatibility across Zsh, Bash, and Sh

6. **Pipeline Integration**: Design your feature to work as a transformation step in the pipeline

7. **Maintain Data Flow**: Each transformation should take input data, process it, and return output data

8. **Comprehensive Documentation**: Update help text with all new options and examples

9. **Consistent Argument Parsing**: Follow the established pattern for handling missing values and validation

10. **JSON Metadata**: Always include your feature's status in JSON output for automation

## Critical Principles

1. **Pipeline Integration**: Ensure your feature works as a transformation step in the pipeline, not just as a standalone command.

2. **Maintain Data Flow**: Each transformation should take input data, process it, and return output data.

3. **Use Consistent Patterns**: Follow the existing code patterns for argument parsing, error handling, etc.

4. **Use Global Variables**: Define clear global variables for your feature's options.

5. **Comprehensive Documentation**: Update the help text with all new options.

6. **Avoid Side Effects**: Document any side effects your feature introduces.

7. **Use POSIX Compatibility**: Ensure your code works with POSIX-compliant shells.

By following these steps, your new feature will integrate seamlessly with the base.sh pipeline architecture while maintaining code quality and consistency.
