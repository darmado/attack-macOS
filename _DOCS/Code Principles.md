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

6. Write Clean, Modular Code with Dedicated Error Handling
   Rationale: Clean, modular code with dedicated error handling improves readability, maintainability, and troubleshooting. By separating error handling from the main logic, we can more easily identify and resolve issues.

   Example:
   ```bash
   process_keychain() {
       local keychain_path="$1"
       
       # Error handling block
       if [ ! -f "$keychain_path" ]; then
           echo "Error: Keychain file not found" >&2
           return 1
       fi
       if ! command -v security &> /dev/null; then
           echo "Error: 'security' command not found" >&2
           return 1
       fi
       
       # Main logic (only executed if no errors)
       local keychain_contents
       keychain_contents=$(security dump-keychain "$keychain_path")
       if [ $? -eq 0 ]; then
           process_keychain_contents "$keychain_contents"
       else
           echo "Error: Failed to dump keychain contents" >&2
           return 1
       fi
   }
   ```

7. Use the template for new scripts
   Example: `cp util/_templates/utility.sh new_script.sh`

8. Use descriptive names for variables and functions
   Example: `KEYCHAIN_PATH` instead of `kp`, `validate_keychain_input()` instead of `vki()`

9. Include detailed function comments
   Example:
   ```bash
   #FunctionType: utility
   #VariableType: string
   validate_keychain_input() {
       local keychain_path="$1"
       # Function body
   }
   ```

10. Implement single-responsibility functions
    Example:
    ```bash
    validate_keychain_input() {
        # Only handle keychain input validation
    }
    
    process_keychain_data() {
        # Only handle keychain data processing
    }
    ```

11. Use global variables for script behavior control
    Example: 
    ```bash
    VERBOSE=false
    LOG_ENABLED=true
    ```

12. Handle errors and edge cases
    Example:
    ```bash
    if ! command -v security &> /dev/null; then
        echo "Error: 'security' command not found" >&2
        exit 1
    fi
    ```

13. Prefer native MacOS commands
    Example: `system_info=$(sysctl -a)`

14. Implement comprehensive logging
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
        echo "Verbose: Accessing keychain at $KEYCHAIN_PATH"
    fi
    ```

15. Follow a consistent function execution order
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

16. Create reusable functions for common tasks
    Example:
    ```bash
    #FunctionType: utility
    log_message() {
        local level="$1"
        local message="$2"
        echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message"
    }
    ```

17. Use consistent indentation (tabs)
    Example:
    ```bash
    if [ "$VERBOSE" = true ]; then
    	echo "Verbose mode enabled"
    	log_message "INFO" "Starting script execution"
    fi
    ```

18. Run shellcheck before committing
    Example: `shellcheck script.sh`

19. Use uppercase for global variables and constants
    Example:
    ```bash
    readonly MAX_RETRIES=3
    VERBOSE=false
    ```

20. Use lowercase with underscores for local variables and functions
    Example:
    ```bash
    local user_input
    validate_input() {
        # Function body
    }
    ```

21. Begin function names with MITRE ATT&CK tactic verbs
    Example:
    ```bash
    access_cred_keychain() {
        # Function to access keychain credentials
    }
    ```

22. Avoid code duplication through function creation
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

23. Validate and sanitize all input
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

24. Use $() for command substitution
    Example: `current_date=$(date '+%Y-%m-%d')`

25. Enclose variables in double quotes
    Example: `echo "Current user: $USER"`

26. Ensure shell compatibility across `Zsh`, `Bash`, and `Sh`. This principle ensures that scripts remain portable across different shell environments, maximizing compatibility and reducing potential issues when scripts are executed in varied macOS configurations.

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



### JXA and Swift Code Principles

1. Prioritize API Usage:
   Always use the native macOS APIs as the first choice, followed by POSIX-compliant methods. Avoid command-line tools whenever possible.

   Rationale: Native APIs provide better performance, reliability, and integration with the macOS ecosystem. They also reduce the risk of detection by security software that may monitor command-line activities.

   Example (JXA):
   ```javascript
   // Preferred: Using NSFileManager API
   var fileManager = $.NSFileManager.defaultManager;
   var homeDirectory = fileManager.homeDirectoryForCurrentUser.path.js;

   // Avoid: Using shell command
   // var homeDirectory = $.NSString.stringWithString('echo $HOME').js;
   ```

   Example (Swift):
   ```swift
   // Preferred: Using FileManager API
   let fileManager = FileManager.default
   let homeDirectory = fileManager.homeDirectoryForCurrentUser.path

   // Avoid: Using shell command
   // let homeDirectory = shell("echo $HOME")
   ```

2. Leverage Objective-C Bridge:
   In JXA, make extensive use of the Objective-C bridge to access powerful macOS frameworks.

   Example:
   ```javascript
   ObjC.import('Foundation')
   
   // Using NSProcessInfo to get system information
   var processInfo = $.NSProcessInfo.processInfo;
   var osVersion = processInfo.operatingSystemVersionString.js;
   var processorCount = processInfo.processorCount;
   ```

3. Use Swift for Performance-Critical Tasks:
   When performance is crucial, consider implementing those parts in Swift and bridging them to JXA.

   Example:
   ```swift
   // Swift function for intensive computation
   @objc class Compute: NSObject {
       @objc func intensiveTask(_ input: String) -> String {
           // Perform intensive computation
           return result
       }
   }
   ```

   JXA:
   ```javascript
   ObjC.import('Compute')
   var compute = $.Compute.alloc.init
   var result = compute.intensiveTaskWithString('input')
   ```

4. Prefer Asynchronous Operations:
   Use asynchronous operations when dealing with I/O or network operations to keep the script responsive.

   Example (JXA):
   ```javascript
   function fetchDataAsync(url, callback) {
       var request = $.NSURLRequest.requestWithURL($.NSURL.URLWithString(url));
       var queue = $.NSOperationQueue.mainQueue;
       $.NSURLConnection.sendAsynchronousRequestQueueCompletionHandler(request, queue, function(response, data, error) {
           if (error) {
               callback(null, error);
           } else {
               var result = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
               callback(result, null);
           }
       });
   }
   ```

5. Handle Errors Gracefully:
   Implement robust error handling to gracefully manage unexpected situations and provide meaningful feedback.

   Example (Swift):
   ```swift
   do {
       let data = try Data(contentsOf: fileURL)
       // Process data
   } catch let error as NSError {
       print("Error reading file: \(error.localizedDescription)")
   }
   ```

These principles aim to leverage the full power of macOS while maintaining efficiency, reliability, and stealth in your JXA and Swift code for security tools.





### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
2. Bash Manual: https://www.gnu.org/software/bash/manual/
3. Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
4. ShellCheck: https://www.shellcheck.net/