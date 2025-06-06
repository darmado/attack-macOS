# Variable Naming Conventions and Standards

This document outlines the naming conventions and standards for variables used in our scripts. Consistent naming practices enhance code readability, maintainability, and collaboration among team members.

### Core Principles
- **Clear**: Names immediately communicate purpose
- **Direct**: No ambiguity about function or variable use
- **Short**: Concise without being cryptic
- **Consistent**: Follow established patterns

### Assumptions
- Developers have basic knowledge of Bash scripting
- Scripts are intended for use on MacOS systems
- The project uses MITRE ATT&CK framework for technique classification

##

### Purpose
- Standardize variable naming across the project
- Improve code readability and maintainability
- Facilitate easier collaboration among team members
- Ensure immediate clarity of code intent

##

### Function Names

#### Build Script Functions
Use clear action verbs that immediately describe what the function does:
- `build_*` - Functions that construct/generate code sections
- `create_*` - Functions that create files or resources
- `validate_*` - Functions that check or verify something
- `parse_*` - Functions that parse or process input
- `transform_*` - Functions that modify or convert data

Examples:
```bash
build_flag_vars()       # Builds flag variable declarations
build_arg_parser()      # Builds argument parser cases  
create_test_file()      # Creates test script file
validate_yaml()         # Validates YAML file structure
parse_arguments()       # Parses command line arguments
transform_sudo()        # Transforms commands with sudo
```

#### MITRE ATT&CK Technique Functions
- Prefix function names with the corresponding MITRE ATT&CK tactic verb
- Use lowercase and underscores
- Follow the tactic verb with a descriptive function name
- Keep descriptions direct and action-oriented

### MITRE ATT&CK Tactic to Function Name Prefix Mapping
- Reconnaissance: `recon_`
- Resource Development: `develop_`
- Initial Access: `access_`
- Execution: `execute_`
- Persistence: `persist_`
- Privilege Escalation: `escalate_`
- Defense Evasion: `evade_`
- Credential Access: `access_creds_`
- Discovery: `discover_`
- Lateral Movement: `move_`
- Collection: `collect_`
- Command and Control: `command_`
- Exfiltration: `exfiltrate_`
- Impact: `impact_`

Examples:
```bash
# Technique functions - clear and direct
access_creds_keychain()     # Access keychain credentials
discover_network_shares()   # Discover network shares
collect_clipboard_data()    # Collect clipboard data
evade_file_quarantine()     # Evade file quarantine
```

#### Utility Functions
- Start with a descriptive action verb
- Use present tense, active voice
- Keep names short but clear
- Avoid unnecessary words

Examples:
```bash
# Good - clear and direct
validate_input()
check_permissions()
get_user_data()
set_config()
log_error()

# Avoid - too verbose or unclear
validate_user.arg_for_security_compliance()
perform_permission_verification_check()
retrieve_and_process_user_data_information()
```

##

### Global Variables
- Use UPPERCASE for all global variables
- Use underscores to separate words
- Use descriptive but concise names
- Prefix with context when needed

Examples:
```bash
# Configuration
MAX_RETRIES=3
DEFAULT_TIMEOUT=60
LOG_ENABLED=false

# Commands (with options as separate variables)
CMD_FIND="find"
CMD_FIND_OPTS="-type f -name"
CMD_GREP="grep"
CMD_GREP_OPTS="-E"

# MITRE ATT&CK
TTP_ID="T1555.001"
TACTIC="Credential Access"
PROCEDURE_NAME="keychain_access"
```

##

### Local Variables
- Use lowercase for local variables
- Use underscores to separate words
- Use descriptive nouns or noun phrases
- Keep scope-appropriate names

Examples:
```bash
# Function-scoped variables
local user.arg
local temp_file
local error_count
local validation_result

# Loop variables
for file_path in "${FILE_PATHS[@]}"; do
for user_name in "${USERS[@]}"; do
```

##

### Input Processing Variables
Follow a consistent pattern for argument processing:

```bash
# Raw input from command line (always strings)
INPUT_DURATION=""           # Raw string input
INPUT_INTERVAL=""           # Raw string input
INPUT_TARGET=""             # Raw string input

# Processed and validated variables  
DURATION_ARG=""             # Validated integer
INTERVAL_ARG=""             # Validated integer  
TARGET_ARG=""               # Validated string

# Flag variables (boolean)
DURATION=false              # True when --duration is used
INTERVAL=false              # True when --interval is used
TARGET=false                # True when --target is used
```

##

### Array and Associative Array Names
- Use UPPERCASE for array names
- Use plural nouns
- Keep names clear and direct

Examples:
```bash
declare -a ALLOWED_USERS
declare -a FILE_PATHS
declare -A CONFIG_OPTIONS
declare -A COMMAND_MAPPINGS
```

##

### Constants
- Use UPPERCASE with underscores
- Use `readonly` declaration
- Make purpose immediately clear

Examples:
```bash
readonly MAX_CONNECTIONS=30
readonly DEFAULT_CHUNK_SIZE=50
readonly CONFIG_FILE="/etc/app/config.yml"
readonly VERSION="1.0.0"
```

##

### Command-line Arguments
- Use lowercase with hyphens
- Use nouns or verb-noun combinations
- Keep clear and direct

Examples:
```bash
--duration          # Clear noun
--output-format     # Clear compound noun
--enable-logging    # Clear verb-noun
--chunk-size        # Clear compound noun
```

##

### Function and Variable Type Comments
Use clear, direct type indicators:

```bash
#FunctionType: utility
#FunctionType: technique
#FunctionType: validation
#FunctionType: build

#VariableType: string
#VariableType: integer
#VariableType: boolean
#VariableType: array
```

##

### Command Variables Pattern
Use consistent pattern for command definitions:

```bash
# Base commands
CMD_SECURITY="security"
CMD_DEFAULTS="defaults" 
CMD_FIND="find"

# Command options (separate variables)
CMD_SECURITY_OPTS="dump-keychain"
CMD_FIND_OPTS="-type f -name"

# Combined usage in functions
result=$("$CMD_SECURITY" $CMD_SECURITY_OPTS "$keychain_path")
```

##

### Boolean Variables
- Use clear, direct names
- Prefer simple adjectives over prefixes when clear

Examples:
```bash
# Good - clear and direct
DEBUG=false
VERBOSE=false
LOG_ENABLED=false
FORCE_MODE=false

# Also acceptable when needed for clarity  
is_valid=true
has_permission=false
```

##

### Loop Variables
- Use meaningful names, not just i, j, k
- Use singular form of collection being iterated

Examples:
```bash
# Good - clear purpose
for file in "${FILES[@]}"; do
for user in "${USERS[@]}"; do  
for arg in "$@"; do

# Acceptable for simple counters
for i in {1..10}; do
```

##

### File and Directory Variables
- Use lowercase with underscores
- Use descriptive but concise names
- Include context when needed

Examples:
```bash
# Path variables
log_dir="/var/log/security"
config_file="/etc/app/config.yml"
temp_dir="/tmp/procedure_$$"

# File name variables  
log_file="${ttp_id}_${procedure_name}.log"
output_file="results_$(date +%Y%m%d).txt"
```

##

### Anti-Patterns to Avoid

#### Overly Verbose Names
```bash
# Bad - too verbose
validate_user.arg_for_security_compliance()
retrieve_and_process_user_configuration_data()

# Good - clear and direct  
validate_input()
get_user_config()
```

#### Unclear Abbreviations
```bash
# Bad - unclear abbreviations
proc_usr_cfg()
val_inp()

# Good - clear full words
process_user_config()
validate_input()
```

#### Inconsistent Patterns
```bash
# Bad - inconsistent patterns
generateHelp()           # camelCase mixed with others
create_test_files()      # different verb pattern
makeArgParser()          # inconsistent style

# Good - consistent patterns
build_help_text()
create_test_file()  
build_arg_parser()
```

##

### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
2. Bash Manual: https://www.gnu.org/software/bash/manual/
3. Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
4. Clean Code Principles: Robert C. Martin

##

