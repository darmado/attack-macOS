# Bash Script Code Guide for MacOS Security Tools

### Description
This document outlines the coding guide and best practices for developing Bash scripts for MacOS security tools. It provides guidelines to ensure consistency, readability, and maintainability across the project.

> **Note:** The code in `util/_templates/utility.sh` serves as a template and should not be modified. The guide below apply to new scripts created from this template.

##

### Purpose
The purpose of these guide is to:
1. Standardize coding practices across the project
2. Improve code readability and maintainability
3. Enhance security and reliability of the scripts
4. Facilitate easier collaboration among team members

##

### Assumptions
- Developers have basic knowledge of Bash scripting
- Scripts are intended for use on MacOS systems
- The project uses MITRE ATT&CK framework for technique classification

##

### Guide

1. Minimize Dependency on User Input
   Rationale: Excessive reliance on user input can lead to inconsistent behavior, increased error potential, and reduced script reliability. By minimizing user input dependencies, we can create more robust, predictable, and automated scripts.

   Example from browser_history.sh:
   ```bash
   INPUT_DAYS=7  # Default to 7 days if not specified
   ```

2. Use Default Values and Environment Variables
   Example from browser_history.sh:
   ```bash
   LOG_DIR="../../logs"
   LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
   LOG_ENABLED=false
   ```

3. Implement Input Validation for Unavoidable User Inputs
   Example from browser_history.sh:
   ```bash
   validate_input() {
       local input="$1"
       local pattern="$2"
       if [[ ! $input =~ $pattern ]]; then
           echo "Invalid input: $input" >&2
           return 1
       fi
       return 0
   }
   ```

4. Implement Robust Error Handling and Fallback Mechanisms
   Example from browser_history.sh:
   ```bash
   if ! check_perms "$SAFARI_DB" "r"; then
       log "Error: Insufficient file permissions to access Safari history database" "" ""
       return 1
   fi
   ```

5. Write Clean, Modular Code with Dedicated Error Handling
   Example from browser_history.sh:
   ```bash
   safari_history() {
       if ! check_perms_tcc; then
           log "Error: Insufficient TCC permissions to access Safari history" "" ""
           return 1
       fi

       if ! check_perms "$SAFARI_DB" "r"; then
           log "Error: Insufficient file permissions to access Safari history database" "" ""
           return 1
       fi

       # ... (rest of the function)
   }
   ```

6. Use the template for new scripts
   Example: `cp util/_templates/utility.sh new_script.sh`

7. Use descriptive names for variables and functions
   Example: `KEYCHAIN_PATH` instead of `kp`, `validate_keychain_input()` instead of `vki()`

8. Include detailed function comments
   Example:
   ```bash
   #FunctionType: utility
   #VariableType: string
   validate_keychain_input() {
       local keychain_path="$1"
       # Function body
   }
   ```

9.  Implement single-responsibility functions
    Example:
    ```bash
    validate_keychain_input() {
        # Only handle keychain input validation
    }
    
    process_keychain_data() {
        # Only handle keychain data processing
    }
    ```

10. Use global variables for script behavior control
    Example: 
    ```bash
    VERBOSE=false
    LOG_ENABLED=true
    ```

11. Handle errors and edge cases
    Example:
    ```bash
    if ! command -v security &> /dev/null; then
        echo "Error: 'security' command not found" >&2
        exit 1
    fi
    ```

12. Prefer native MacOS commands
    Example: `system_info=$(sysctl -a)`

13. Implement comprehensive logging
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
        echo "Verbose: Accessing keychain at $KEYCHAIN_PATH"
    fi
    ```

14. Follow a consistent function execution order
    Example:
    ```bash
    main() {
        validate_input "$@"
        execute_technique
        process_output
        log_results
        exfiltrate_data
    }
    ```

15. Create reusable functions for common tasks
    Example:
    ```bash
    #FunctionType: utility
    log_message() {
        local level="$1"
        local message="$2"
        echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message"
    }
    ```

16. Use consistent indentation (tabs)
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
    	echo "Verbose mode enabled"
    	log_message "INFO" "Starting script execution"
    fi
    ```

17. Run shellcheck before committing
    Example: `shellcheck script.sh`

18. Use uppercase for global variables and constants
    Example:
    ```bash
    readonly MAX_RETRIES=3
    VERBOSE=false
    ```

19. Use lowercase with underscores for local variables and functions
    Example:
    ```bash
    local user_input
    validate_input() {
        # Function body
    }
    ```

20. Begin function names with MITRE ATT&CK tactic verbs
    Example:
    ```bash
    credential_access_keychain() {
        # Function to access keychain credentials
    }
    ```

21. Avoid code duplication through function creation
    Example:
    ```bash
    encode_data() {
        local data="$1"
        local encoding="$2"
        case "$encoding" in
            base64) echo "$data" | base64 ;;
            hex) echo "$data" | xxd -p ;;
            *) echo "Invalid encoding" >&2; return 1 ;;
        esac
    }
    ```

22. Validate and sanitize all input
    Example:
    ```bash
    validate_and_sanitize() {
        local input="$1"
        if [[ ! "$input" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "Invalid input" >&2
            return 1
        fi
        echo "$input"
    }
    ```

23. Use $() for command substitution
    Example: `current_date=$(date '+%Y-%m-%d')`

24. Enclose variables in double quotes
    Example: `echo "Current user: $USER"`

25. Ensure shell compatibility across `Zsh`, `Bash`, and `Sh`. This principle ensures that scripts remain portable across different shell environments, maximizing compatibility and reducing potential issues when scripts are executed in varied macOS configurations.

    Example:
    ```bash
    # Use POSIX-compliant syntax
    for item in $list; do
        printf '%s\n' "$item"
    done

    # Avoid Bash-specific features like arrays
    # Instead, use space-separated strings
    items="item1 item2 item3"
    for item in $items; do
        process_item "$item"
    done

    # Use [ ] instead of [[ ]] for conditionals
    if [ "$variable" = "value" ]; then
        # Action
    fi

    # Use portable command substitution
    result=$(command)

    # Avoid Zsh-specific globbing
    # Use explicit globbing patterns
    for file in ./*; do
        [ -e "$file" ] || continue
        # Process file
    done

    # Use simple arrays instead of 'declare'
    my_array="element1 element2 element3"
    for element in $my_array; do
        echo "$element"
    done

    # Use 'set' for positional parameters instead of arrays
    set -- item1 item2 item3
    for item in "$@"; do
        echo "$item"
    done
    ```

##




### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
2. Bash Manual: https://www.gnu.org/software/bash/manual/
3. Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
4. ShellCheck: https://www.shellcheck.net/
