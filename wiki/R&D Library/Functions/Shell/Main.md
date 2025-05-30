# Main

### Purpose
Orchestrates complete script execution flow: 1) Parse arguments, 2) Display help if requested, 3) Validate arguments, 4) Generate encryption key, 5) Validate commands, 6) Run permission/TCC checks, 7) Initialize logging, 8) Execute technique logic or ls/steganography, 9) Process output, 10) Transform final output.

### Dependencies
| Type | Name | Value |
|------|------|-------|
| Global Variable | `SHOW_HELP` | `false` |
| Global Variable | `LOG_ENABLED` | `false` |
| Global Variable | `LIST_FILES` | `false` |
| Global Variable | `STEG_EXTRACT` | `false` |
| Global Variable | `STEG_EXTRACT_FILE` | `""` |
| Global Variable | `PERMISSION_CHECKS` | `""` |
| Global Variable | `TCC_CHECKS` | `""` |
| Global Variable | `NAME` | `""` |
| Global Variable | `CMD_PRINTF` | `"printf"` |
| Function | `core_parse_args()` | For argument parsing |
| Function | `core_display_help()` | For help display |
| Function | `core_validate_parsed_args()` | For argument validation |
| Function | `core_generate_encryption_key()` | For encryption key generation |
| Function | `core_validate_command()` | For command validation |
| Function | `core_run_permission_checks()` | For permission validation |
| Function | `core_run_tcc_checks()` | For TCC permission validation |
| Function | `core_log_output()` | For logging |
| Function | `core_ls()` | For file listing |
| Function | `core_extract_steganography()` | For steganography extraction |
| Function | `core_process_output()` | For output processing |
| Function | `core_transform_output()` | For final output handling |
| Function | `core_debug_print()` | For debug logging |
| Function | `core_handle_error()` | For error handling |
| Function | `core_get_timestamp()` | For timestamp generation |

<details>

```shell
core_main() {
    local raw_output=""
    local processed_output=""
    
    # Step 1: Parse command line arguments (no validation)
    core_parse_args "$@"
    
    # Step 2: Display help if requested (early exit)
    if [ "$SHOW_HELP" = true ]; then
        core_display_help
        return 0
    fi
    
    # Step 3: Validate parsed arguments
    core_validate_parsed_args || exit 1
    
    # Step 4: Generate encryption key if needed
    core_generate_encryption_key
    
    # Step 5: Validate required commands
    core_validate_command || exit 1
    
    # Process permission checks from configuration
    if [ -n "$PERMISSION_CHECKS" ]; then
        core_debug_print "Processing permission checks from configuration"
        # Instead of eval, call the permission check function directly
        core_run_permission_checks
        permission_check_result=$?
        if [ $permission_check_result -ne 0 ]; then
            core_handle_error "Permission checks failed - script cannot continue without required permissions"
            exit 1
        fi
    fi
    
    # Process TCC permission checks from configuration
    if [ -n "$TCC_CHECKS" ]; then
        core_debug_print "Processing TCC permission checks from configuration"
        # Instead of eval, call the TCC check function directly
        core_run_tcc_checks
        tcc_check_result=$?
        if [ $tcc_check_result -ne 0 ]; then
            "$CMD_PRINTF"  "[INFO] [%s] TCC permission checks failed - some functionality may be limited\n" "$(core_get_timestamp)"
            # We continue execution as TCC checks are often informational
        fi
    fi
    
    # Initialize the log file if logging is enabled
    if [ "$LOG_ENABLED" = true ]; then
        # Initialize logging at start
        core_log_output "Starting ${NAME}" "started" true
    fi
    
    # Default data source identifier
    local data_source="generic"
    
    # Check if we should run the ls function
    if [ "$LIST_FILES" = true ]; then
        # Get raw output from ls command
        raw_output=$(core_ls)
        data_source="file_listing"
    # Check if we should extract steganography data
    elif [ "$STEG_EXTRACT" = true ]; then
        # Execute steganography extraction
        raw_output=$(core_extract_steganography "$STEG_EXTRACT_FILE")
        data_source="steg_extracted"
    else
        # Execute script-specific logic here
# PLACEHOLDER_MAIN_EXECUTION
        # This section is intentionally left empty as it will be filled by
        # technique-specific implementations when sourcing this base script
        # If no raw_output is set by the script, exit gracefully
        if [ -z "$raw_output" ]; then
            return 0
        fi
    fi
    
    # Process the output (format, encode, encrypt)
    processed_output=$(core_process_output "$raw_output" "$data_source")
    
    # Handle the final output (log, exfil, or display)
    core_transform_output "$processed_output"
}
```

</details> 