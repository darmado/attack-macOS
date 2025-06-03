# Shell Script Code Guide for MacOS Security Tools

### Description
This document outlines the coding guide and best practices for developing POSIX-compliant shell scripts for MacOS security tools. It provides guidelines to ensure consistency, readability, and maintainability across the project.




##

### Purpose
The purpose of these guide is to:
1. Standardize coding practices across the project
2. Improve code readability and maintainability
3. Enhance security and reliability of the scripts
4. Facilitate easier collaboration among team members
5. Ensure POSIX compliance and portability

##

### Assumptions
- Developers have basic knowledge of POSIX shell scripting
- Scripts are intended for use on MacOS systems
- Scripts must be compatible with sh shell
- The project uses MITRE ATT&CK framework for technique classification

##

### Guide

1. Use POSIX-compliant syntax only
   Rationale: Ensures scripts work consistently across different shells and systems.

   Instead of:
   ```bash
   # Bash-specific array
   declare -a my_array=("item1" "item2")
   ```
   Use:
   ```sh
   # POSIX-compliant space-separated string
   items="item1 item2"
   for item in $items; do
       process_item "$item"
   done
   ```

2. Use [ ] instead of [[ ]]
   Example:
   ```sh
   # POSIX-compliant test
   if [ "$variable" = "value" ]; then
       # Action
   fi
   ```

3. Avoid Bash-specific features
   Example:
   ```sh
   # Instead of process substitution
   while read -r line; do
       process_line "$line"
   done < "$input_file"
   ```

4. Minimize Dependency on User Input
   Rationale: Excessive reliance on user input can lead to inconsistent behavior, increased error potential, and reduced script reliability. By minimizing user input dependencies, we can create more robust, predictable, and automated scripts.

   Example from browser_history.sh:
   ```bash
   INPUT_DAYS=7  # Default to 7 days if not specified
   ```

5. Use Default Values and Environment Variables
   Example from browser_history.sh:
   ```bash
   LOG_DIR="../../logs"
   LOG_FILE_NAME="${TTP_ID}_${NAME}.log"
   LOG_ENABLED=false
   ```

6. Implement Input Validation for Unavoidable User Inputs
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

7. Implement  Error Handling and Fallback Mechanisms
   Example from browser_history.sh:
   ```bash
   if ! check_perms "$SAFARI_DB" "r"; then
       log "Error: Insufficient file permissions to access Safari history database" "" ""
       return 1
   fi
   ```

8. Write Clean, Modular Code with Dedicated Error Handling
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

9. Use the template for new scripts
   Example: `cp util/_templates/utility_functions.sh new_script.sh`

10. Use descriptive names for variables and functions
    Example: `KEYCHAIN_PATH` instead of `kp`, `validate_keychain_input()` instead of `vki()`

11. Include detailed function comments
    Example:
    ```bash
    #FunctionType: utility
    #VariableType: string
    validate_keychain_input() {
        local keychain_path="$1"
        # Function body
    }
    ```

12. Implement single-responsibility functions
    Example:
    ```bash
    validate_keychain_input() {
        # Only handle keychain input validation
    }
    
    process_keychain_data() {
        # Only handle keychain data processing
    }
    ```

13. Use global variables for script behavior control
    Example: 
    ```bash
    VERBOSE=false
    LOG_ENABLED=true
    ```

14. Handle errors and edge cases
    Example:
    ```bash
    if ! command -v security &> /dev/null; then
        echo "Error: 'security' command not found" >&2
        exit 1
    fi
    ```

15. Prefer native MacOS commands
    Example: `system_info=$(sysctl -a)`

16. Implement logging
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
        echo "Verbose: Accessing keychain at $KEYCHAIN_PATH"
    fi
    ```

17. Follow a consistent function execution order
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

18. Create reusable functions for common tasks
    Example:
    ```bash
    #FunctionType: utility
    log_message() {
        local level="$1"
        local message="$2"
        echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message"
    }
    ```

19. Use consistent indentation (tabs)
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
    	echo "Verbose mode enabled"
    	log_message "INFO" "Starting script execution"
    fi
    ```

20. Run shellcheck before committing
    Example: `shellcheck script.sh`

21. Use uppercase for global variables and constants
    Example:
    ```bash
    readonly MAX_RETRIES=3
    VERBOSE=false
    ```

22. Use lowercase with underscores for local variables and functions
    Example:
    ```bash
    local user_input
    validate_input() {
        # Function body
    }
    ```

23. Begin function names with MITRE ATT&CK tactic verbs
    Example:
    ```bash
    credential_access_keychain() {
        # Function to access keychain credentials
    }
    ```

24. Avoid code duplication through function creation
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

25. Validate and sanitize all input
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

26. Use $() for command substitution
    Example: `current_date=$(date '+%Y-%m-%d')`

27. Enclose variables in double quotes
    Example: `echo "Current user: $USER"`

28. Use Global Booleans as Control Levers
    Rationale: Global boolean variables should act as simple control levers for script behavior, eliminating the need for complex conditional logic.

    Example:
    ```sh
    # BAD: Complex nested conditionals
    if [ "$output_enabled" = true ]; then
        if [ "$log_mode" = "file" ]; then
            write_to_log "$message"
        else
            if [ "$format" = "json" ]; then
                format_and_print_json "$message"
            else
                echo "$message"
            fi
        fi
    fi

    # GOOD: Boolean levers with clear defaults
    LOG_ENABLED=false     # Controls output destination
    FORMAT=""           # Controls output format

    # Let the boolean do the work
    if [ "$LOG_ENABLED" = true ]; then
        log_output "$message"
    else
        echo "$message"
    fi

    # Format if needed (separate concern)
    if [ -n "$FORMAT" ]; then
        message=$(format_output "$message")
    fi
    ```

    Key principles:
    1. One boolean = one responsibility
    2. Set meaningful defaults
    3. Let the boolean control the flow
    4. Avoid complex conditional logic
    5. Keep format/encoding separate from destination

29. Ensure shell compatibility across `Zsh`, `Bash`, and `Sh`

## Encryption Functions

### Standards

1. Always validate encryption methods before use
2. Generate new keys for each encryption session
3. Use industry-standard encryption tools (OpenSSL, GPG)
4. Implement proper error handling
5. Clear sensitive data from memory when possible

### Function Structure

```sh
# Define supported methods as space-separated string (POSIX-compliant)
ENCRYPT_METHODS="none gpg aes"

# Validation function
validate_encryption_method() {
    method="$1"
    for valid_method in $ENCRYPT_METHODS; do
        if [ "$method" = "$valid_method" ]; then
            return 0
        fi
    done
    printf "Invalid encryption method. Valid methods are: %s\\n" "$ENCRYPT_METHODS" >&2
    return 1
}

# Key generation function
generate_encryption_key() {
    openssl rand -base64 32
}

# Setup function
setup_encryption() {
    method="$1"
    if validate_encryption_method "$method"; then
        ENCRYPT_KEY=$(generate_encryption_key)
        return 0
    fi
    return 1
}

# Encryption function
encrypt_output() {
    data="$1"
    method="$2"
    key="$3"
    
    case "$method" in
        "gpg") 
            printf '%s' "$data" | gpg --batch --yes --passphrase "$key" --symmetric --cipher-algo AES256
            ;;
        "aes")
            printf '%s' "$data" | openssl enc -e -aes-256-cbc -base64 -k "$key"
            ;;
    esac
}
```

### Usage Guidelines

1. Always check return values:
```sh
if ! setup_encryption "$method"; then
    printf "Failed to setup encryption\\n" >&2
    return 1
fi
```

2. Handle errors gracefully:
```sh
encrypted_data=$(encrypt_output "$data" "$method" "$key")
if [ $? -ne 0 ]; then
    printf "Encryption failed\\n" >&2
    return 1
fi
```

3. Clear sensitive data:
```sh
# After using the key
ENCRYPT_KEY=""
unset ENCRYPT_KEY
```

4. Use secure temporary files:
```sh
temp_file=$(mktemp)
chmod 600 "$temp_file"
encrypt_output "$data" "$method" "$key" > "$temp_file"
# ... use temp_file ...
rm -P "$temp_file"
```
##

### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
2. POSIX Shell Standard: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
3. Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
4. ShellCheck: https://www.shellcheck.net/

