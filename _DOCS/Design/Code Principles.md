# Bash Script Code Principles for MacOS Security Tools

### Description
This document outlines the coding principles and best practices for developing Bash scripts for MacOS security tools. It provides guidelines to ensure consistency, readability, and maintainability across the project.

> **Note:** The code in `util/_templates/utility.sh` serves as a template and should not be modified. The principles below apply to new scripts created from this template.

##

### Purpose
The purpose of these principles is to:
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

### Principles

1. Minimize Dependency on User Input
   Rationale: Excessive reliance on user input can lead to inconsistent behavior, increased error potential, and reduced script reliability. By minimizing user input dependencies, we can create more robust, predictable, and automated scripts.

   Example:
   Instead of:
   ```bash
   read -p "Enter keychain path: " KEYCHAIN_PATH
   ```
   Use:
   ```bash
   KEYCHAIN_PATH="${KEYCHAIN_PATH:-/Users/$USER/Library/Keychains/login.keychain-db}"
   ```

2. Use Default Values and Environment Variables
   Example:
   ```bash
   LOG_DIR="${LOG_DIR:-/var/log/security_scripts}"
   ```

3. Implement Input Validation for Unavoidable User Inputs
   Example:
   ```bash
   validate_keychain_path() {
       local path="$1"
       if [[ ! -f "$path" ]]; then
           echo "Error: Keychain file not found at $path" >&2
           return 1
       fi
   }
   ```

4. Use Configuration Files for Customization
   Example:
   ```bash
   source /etc/security_scripts/config.sh
   ```

5. Implement Robust Error Handling and Fallback Mechanisms
   Example:
   ```bash
   get_keychain_path() {
       if [[ -n "$KEYCHAIN_PATH" ]]; then
           echo "$KEYCHAIN_PATH"
       elif [[ -f "/Users/$USER/Library/Keychains/login.keychain-db" ]]; then
           echo "/Users/$USER/Library/Keychains/login.keychain-db"
       else
           echo "Error: Unable to determine keychain path" >&2
           return 1
       fi
   }
   ```

1. Use the template for new scripts
   Example: `cp util/_templates/utility.sh new_script.sh`

2. Use descriptive names for variables and functions
   Example: `KEYCHAIN_PATH` instead of `kp`, `validate_keychain_input()` instead of `vki()`

3. Include detailed function comments
   Example:
   ```bash
   #FunctionType: utility
   #VariableType: string
   validate_keychain_input() {
       local keychain_path="$1"
       # Function body
   }
   ```

4. Implement single-responsibility functions
   Example:
   ```bash
   validate_keychain_input() {
       # Only handle keychain input validation
   }
   
   process_keychain_data() {
       # Only handle keychain data processing
   }
   ```

5. Use global variables for script behavior control
   Example: 
   ```bash
   VERBOSE=false
   LOG_ENABLED=true
   ```

6. Handle errors and edge cases
   Example:
   ```bash
   if ! command -v security &> /dev/null; then
       echo "Error: 'security' command not found" >&2
       exit 1
   fi
   ```

7. Prefer native MacOS commands
   Example: `system_info=$(sysctl -a)`

8. Implement comprehensive logging
   Example:
   ```bash
   if [ "$VERBOSE" = true ]; then
       echo "Verbose: Accessing keychain at $KEYCHAIN_PATH"
   fi
   ```

9. Follow a consistent function execution order
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

10. Create reusable functions for common tasks
    Example:
    ```bash
    #FunctionType: utility
    log_message() {
        local level="$1"
        local message="$2"
        echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message"
    }
    ```

11. Use consistent indentation (tabs)
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
    	echo "Verbose mode enabled"
    	log_message "INFO" "Starting script execution"
    fi
    ```

12. Run shellcheck before committing
    Example: `shellcheck script.sh`

13. Use uppercase for global variables and constants
    Example:
    ```bash
    readonly MAX_RETRIES=3
    VERBOSE=false
    ```

14. Use lowercase with underscores for local variables and functions
    Example:
    ```bash
    local user_input
    validate_input() {
        # Function body
    }
    ```

15. Begin function names with MITRE ATT&CK tactic verbs
    Example:
    ```bash
    access_cred_keychain() {
        # Function to access keychain credentials
    }
    ```

16. Avoid code duplication through function creation
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

17. Validate and sanitize all input
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

18. Use $() for command substitution
    Example: `current_date=$(date '+%Y-%m-%d')`

19. Enclose variables in double quotes
    Example: `echo "Current user: $USER"`

##

### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
2. Bash Manual: https://www.gnu.org/software/bash/manual/
3. Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
4. ShellCheck: https://www.shellcheck.net/