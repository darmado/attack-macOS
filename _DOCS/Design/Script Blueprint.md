### Overview
A blueprint framework facilitates security teams' execution of techniques often attributed to threat actor activity in MacOS environments without dependencies. The blueprint maintains 100% stand-alone, modular, interoperable scripts that are easy to maintain, deploy, and execute using native MacOS tools.

The design employs strict execution flow and global controls to ensure consistency and adaptability. Every script component serves a specific purpose.

##

### Objective
Provide a scripting framework that executes MacOS-specific techniques, tools, and tradecraft attributed to threat actors.

##

### Assumptions
- Global variables act as switches for `main()` to control function call sequence and frequency.
- Utility functions serve as gatekeepers and data handlers for `main()` to manage interoperability and maintain data integrity.

##

### Purpose
Orchestrate technique execution, process output, and exfiltrate data based on user-defined flags.

### Requirements
- Implement `main()` as a high-level orchestrator.
- Use global variables as execution switches.
- Centralize logging and exfiltration logic in `main()`.
- Execute utility functions within `main()` based on global variables and logic flow.
- Follow the specified execution priority order.

##

### Utility Functions
Utility functions support the execution of Tactics, Techniques, and Procedures (TTPs) attributed to threat actor activity on macOS systems. These modular, reusable functions enable the primary objective of simulating adversarial behavior.

##

### Key Utility Functions and Their Purposes
1. **display_help()**: Provides user-friendly script usage interface.
2. **get_timestamp()**: Generates consistent timestamps for logging and tracking.
3. **log_to_stdout()**: Implements standardized logging mechanism.
4. **setup_log()**: Initializes and manages log files.
5. **chunk_data()**: Breaks down large datasets into manageable chunks.
6. **encode_output()**: Implements various encoding schemes.
7. **encrypt_output()**: Provides encryption capabilities.
8. **validate_input() and sanitize_input()**: Ensure input integrity and safety.
9. **execute_command()**: Centralizes command execution logic.
10. **exfil_http() and exfil_dns()**: Implement different exfiltration methods.


##

These utility functions provide essential services such as input handling, output processing, logging, data manipulation, command execution, and simulated data exfiltration.

### Execution Control
- Global variables act as switches for function execution.
- `main()` determines execution order based on set flags.
- Default settings ensure consistent behavior if user input is missing.

##

### Function Execution Priority
To avoid unexpected behavior, invoke in the following sequence:
1. Validation
2. Technique Function Execution
3. Output Processing
4. Logging
5. Exfiltration

##

### Function Execution Logic Flow Example for `security_software.sh`

### 1. Validation
Required logic flow:
- `if (EXFIL && EXFIL_METHOD == "dns")`: `validate_dns()`
- `if (ENCODE)`: `validate_encoding()`
- `if (ENCRYPT)`: `validate_encryption()`
- `if (CHUNK_SIZE)`: `validate_chunk_size()`
- `if (SUDO_MODE)`: `validate_sudo_mode()`
- `if (VERBOSE)`: `validate_verbose_mode()`
- `validate_security_checks()`
- `if (LOG_ENABLED)`: `validate_log_enabled()`

##

### 2. Technique Function Execution
- `if (EDR)`: `discover_edr()`
- `if (AV)`: `discover_av()`
- `if (FIREWALL)`: `discover_firewall()`
- `if (MRT)`: `discover_mrt()`
- `if (GATEKEEPER)`: `discover_gatekeeper()`
- `if (XPROTECT)`: `discover_xprotect()`
- `if (TCC)`: `discover_tcc()`
- `if (OST)`: `discover_ost()`
- `if (HIDS)`: `discover_hids()`

##

### 3. Output Processing
Required logic flow:
- `if (LOG_ENABLED || EXFIL)`: 
  - `if (LOG_ENABLED)`: write output to log
  - `if (EXFIL)`: exfiltrate data
- `else`: print output to stdout

### Function Variable Map

### Function Execution Dependency Map
This map outlines conditional function execution based on global variables.

##

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

##

### 3. Output Processing Functions
- Encode output: **depends_on**: `ENCODE`
- Encrypt output: **depends_on**: `ENCRYPT`

##

### 4. Logging and Exfiltration Functions
- Log processed output: **depends_on**: `LOG_ENABLED`, `EXFIL`
- Exfiltrate data: **depends_on**: `EXFIL`, `EXFIL_METHOD`

### Function Hierarchy and Interoperability Example for **security_software.sh**
