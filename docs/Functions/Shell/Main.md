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
    
    # Step 6: Optional --sacrificial-pid (child PID + FIFO)
    if [ "$SACRIFICIAL_CHILD" = "true" ]; then
        core_debug_print "Executing script with --sacrificial-pid (child PID + FIFO under /tmp)"
        
        local buffer_name="main_$(date +%s)"
        if fifo_create "$buffer_name"; then
            spawn_sacrificial_pid "$buffer_name" "$(declare -f core_execute_main_logic); core_execute_main_logic"
            sleep 1  # Allow execution time
            
            local child_stdout=$(fifo_read "${buffer_name}_proc")
            
            fifo_cleanup "$buffer_name"
            
            if [ -n "$child_stdout" ]; then
                printf "%s\n" "$child_stdout"
            fi
            
            core_debug_print "Child-PID / FIFO path completed (parent PID unchanged)"
            return 0
        else
            core_handle_error "Failed to create FIFO for sacrificial PID path, falling back to normal execution"
            # Fall through to normal execution
        fi
    fi
    
    # Step 7: Normal execution (or fallback if FIFO/child path failed)
    core_execute_main_logic
}
```

</details> 