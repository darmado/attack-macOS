### Objective
Develop scripts executing macOS-specific techniques attributed to threat actors. Key principles:

1. Minimize user input dependency using defaults and environment variables.
2. Implement robust error handling and fallbacks.
3. Use config files for customization.
4. Follow consistent naming conventions.
5. Create single-responsibility functions.
6. Implement comprehensive logging.
7. Prefer native macOS commands.
8. Adhere to MITRE ATT&CK framework.

##

### Assumptions
- Global variables control `main()` function execution.
- Utility functions manage data integrity and interoperability.

##

### Purpose
Create consistent, modular, interoperable scripts for macOS-specific attack techniques. This blueprint guides development, ensuring uniform design, implementation, and documentation across all project scripts. The primary focus is on building a comprehensive library of macOS-specific attack scripts to help security teams execute techniques and discover new detection opportunities in macOS environments.

##

### Requirements
- Implement `main()` as a high-level orchestrator.
- Use global variables as execution switches.
- Centralize logging and exfiltration logic in `main()`.
- Execute utility functions within `main()` based on global variables and logic flow.
- Follow the specified execution priority order.

##

### Execution Control
- Global variables act as switches for function execution.
- `main()` determines execution order based on set flags.
- Default settings ensure consistent behavior if user input is missing.

##

### Input Handling Strategy

Our input handling strategy focuses on centralization, separation of concerns, flexibility, consistent sanitization, and easier pattern management. This approach provides a maintainable and secure method for handling inputs across all scripts in the project.
 Key aspects include:

1. **Centralized Input Handling**: 
   - Use a centralized `input_handler` function for all input strings
   - Ensures consistency and easier maintenance across multiple scripts

2. **Separation of Concerns**: 
   - Input handling logic is separated from main TTP procedure functions
   - Improves readability and maintainability of individual functions

3. **Flexibility**: 
   - `input_handler` can be easily extended for new input types or validation requirements
   - Modifications don't require changes to individual TTP functions

4. **Consistent Sanitization**: 
   - `sanitize_input` is consistently applied to all inputs
   - Exceptions only for whitelisted cases
   - Improves overall security of the scripts

5. **Centralized Pattern Management**: 
   - Create a map of patterns required by different functions
   - Keeps all input validation rules in one place
   - Easier to update and maintain validation rules

##

### Utility Functions
Utility functions support core script operations. These functions handle various aspects of the script's functionality:

The utility functions table provides a clear overview of the script's functionality. It includes columns for:

1. High-level category: Groups related functions
2. Corresponding functions: Specific function names
3. Function description: Brief explanation of each function's purpose
4. Execution priority: Indicates when each function should be called (1️⃣ to 5️⃣, or ❓ for variable timing)
5. Variable control switch: Global variables that act as control switches to enable specific utilities
6. Type: Return type of the function

This structure enables developers to quickly understand the script's components, their roles, and how they are controlled by global variables.

| High-Level Category | Corresponding Functions | Function Description | Execution Priority | Variable Control Switch | Type | Logic |
|---------------------|--------------------------|----------------------|---------------------|------------|------|-------|
| Input Validation    | `validate_input`         | Validates input against regex patterns | 1️⃣ | - | string | Always executed |
|                     | `sanitize_input`         | Cleanses user input for safety | 1️⃣ | - | string | Always executed |
|                     | `validate_dns`           | Validates DNS exfiltration settings | 1️⃣ | EXFIL && EXFIL_METHOD == "dns" | boolean | `if (EXFIL && EXFIL_METHOD == "dns")` |
|                     | `validate_encoding`      | Validates encoding settings | 1️⃣ | ENCODE | boolean | `if (ENCODE)` |
|                     | `validate_encryption`    | Validates encryption settings | 1️⃣ | ENCRYPT | boolean | `if (ENCRYPT)` |
|                     | `validate_chunk_size`    | Validates chunk size for data processing | 1️⃣ | CHUNK_SIZE | boolean | `if (CHUNK_SIZE)` |
|                     | `validate_sudo_mode`     | Validates sudo mode settings | 1️⃣ | SUDO_MODE | boolean | `if (SUDO_MODE)` |
|                     | `validate_verbose_mode`  | Validates verbose mode settings | 1️⃣ | VERBOSE | boolean | `if (VERBOSE)` |
|                     | `validate_security_checks` | Validates security check settings | 1️⃣ | - | boolean | Always executed |
|                     | `validate_log_enabled`   | Validates logging settings | 1️⃣ | LOG_ENABLED | boolean | `if (LOG_ENABLED)` |
| Command Execution   | `execute_command`        | Executes shell commands safely | 2️⃣ | - | string | As needed |
| Data Processing     | `encrypt_output`         | Encrypts data using specified methods | 3️⃣ | ENCRYPT | boolean | `if (ENCRYPT)` |
|                     | `chunk_data`             | Splits data into manageable chunks | 3️⃣ | CHUNK_SIZE | boolean | `if (CHUNK_SIZE)` |
|                     | `encode_output`          | Implements various encoding schemes | 3️⃣ | ENCODE | boolean | `if (ENCODE)` |
|                     | `output_json`                | Converts output to JSON format | 3️⃣ | OUTPUT_JSON | string | `if (OUTPUT_JSON)` |
| Logging             | `log_to_stdout`</br>`create_log`</br> `log_output`</br>`get_timestamp`           | Implements standardized logging</br>Initializes log files</br>Manages log rotation</br>Generates consistent timestamps | 4️⃣ | LOG_ENABLED, VERBOSE | boolean | `if [ "$LOG_ENABLED" = true ]; then log_output "$message"; fi; if [ "$VERBOSE" = true ]; then echo "$message"; fi` |
| Data Exfiltration   | `exfil_http`             | Simulates data exfiltration via HTTP | 5️⃣ | EXFIL && EXFIL_METHOD == "http" | boolean | `if (EXFIL && EXFIL_METHOD == "http")` |
|                     | `exfil_dns`              | Simulates data exfiltration via DNS | 5️⃣ | EXFIL && EXFIL_METHOD == "dns" | boolean | `if (EXFIL && EXFIL_METHOD == "dns")` |
| Miscellaneous       | `display_help`           | Shows usage information | ❓ | - | ? | When help is requested |
| Security Checks     | `check_perms_tcc` | Checks if the app has Full Disk Access (FDA) | 1️⃣ | - | boolean | Always executed |


Each function performs its specific task based on the script's requirements and global variable settings.

For a detailed list of utility functions, see [Utility Functions](link-to-utility-functions-page).


### Function Variable Map

### Function Execution Dependency Map Example
This map outlines conditional function execution based on global variables.

##

> **WARNING**: This section is outdated and requires updating

### 1. Validation Functions
- `validate_dns()`: **depends_on**: `EXFIL`, `EXFIL_METHOD`
- `validate_encoding()`: **depends_on**: `ENCODE`
- `validate_encryption()`: **depends_on**: `ENCRYPT`, `ENCRYPT_KEY`
- `validate_chunk_size()`: **depends_on**: `CHUNK_SIZE`
- `validate_sudo_mode()`: **depends_on**: `SUDO_MODE`
- `validate_verbose_mode()`: **depends_on**: `VERBOSE`
- `validate_security_checks()`: **depends_on**: `EDR`, `FIREWALL`, `HIDS`, `AV`, `GATEKEEPER`, `XPROTECT`, `MRT`, `TCC`, `OST`
- `validate_log_enabled()`: **depends_on**: `LOG_ENABLED`

##

### 2. Technique Functions
- `discover_edr()`: **depends_on**: `EDR`
- `discover_av()`: **depends_on**: `AV`
- `discover_firewall()`: **depends_on**: `FIREWALL`
- `discover_mrt()`: **depends_on**: `MRT`
- `discover_gatekeeper()`: **depends_on**: `GATEKEEPER`
- `discover_xprotect()`: **depends_on**: `XPROTECT`
- `discover_tcc()`: **depends_on**: `TCC`
- `discover_ost()`: **depends_on**: `OST`
- `discover_hids()`: **depends_on**: `HIDS`



GENERIC NOTES

### Logging Logic
The logging system in our scripts follows these rules:
1. If LOG_ENABLED is true, all log messages are written to the log file.
2. If VERBOSE is true, all log messages are also printed to stdout.
3. Log messages include a timestamp, user, TTP ID, tactic, message content, function name, and command (if applicable).
4. Log files are automatically rotated when they reach 5MB in size.
5. Logging can occur at various points in the script execution, not just in the main function.

The general structure of a log entry is:
[TIMESTAMP]: user: USER; ttp_id: TTP_ID; tactic: TACTIC; msg: MESSAGE; function: FUNCTION_NAME; command: "COMMAND"

This logging system ensures comprehensive tracking of script activities while providing flexibility in output verbosity and log management.

### Output Handling

1. Raw Output: By default, all command output must be presented in its raw form, directly from the executed command.

2. Formatted Output: When formatting is required, utilize a dedicated utility function. This ensures consistency and modularity in output processing.

3. Format Selection: Implement a `--format` option that accepts arguments similar to the `--encode` option. This allows for flexible output formatting based on user needs.

Example implementation:
