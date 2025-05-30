# Variable Naming Conventions and Standards

This document outlines the naming conventions and standards for variables used in our scripts. Consistent naming practices enhance code readability, maintainability, and collaboration among team members.

### Assumptions
- Developers have basic knowledge of Bash scripting
- Scripts are intended for use on MacOS systems
- The project uses MITRE ATT&CK framework for technique classification

##

### Purpose
- Standardize variable naming across the project
- Improve code readability and maintainability
- Facilitate easier collaboration among team members

##

### MITRE ATT&CK Tactic Function Names
- Prefix function names with the corresponding MITRE ATT&CK tactic verb
- Use lowercase and underscores
- Follow the tactic verb with a descriptive function name

### MITRE ATT&CK Tactic to Function Name Prefix Mapping
- Reconnaissance: `recon_`
- Resource Development: `develop_`
- Initial Access: `access_`
- Execution: `execute_`
- Persistence: `persist_`
- Privilege Escalation: `escalate_`
- Defense Evasion: `evade_`
- Credential Access: `credential_access_`
- Discovery: `discover_`
- Lateral Movement: `move_`
- Collection: `collect_`
- Command and Control: `command_`
- Exfiltration: `exfiltrate_`
- Impact: `impact_`

##

### Global Variables
- Use UPPERCASE for all global variables
- Use underscores to separate words in multi-word variable names
- Prefix global variables with appropriate identifiers when necessary
- Examples:
  ```
  MAX_RETRIES=3
  USER_AGENT_STRING="Mozilla/5.0 ..."
  ```

##

### Local Variables
- Use lowercase for local variables
- Use underscores to separate words in multi-word variable names
- Use descriptive nouns or noun phrases
- Examples:
  ```
  local user_input
  local temp_file_path
  ```

##

### Function Names
- Use lowercase for function names
- Use underscores to separate words in multi-word function names
- Use descriptive names that indicate the function's purpose
- For technique functions:
  - Always use the MITRE ATT&CK Tactic to Function Name Prefix Mapping
  - Append a descriptive name after the prefix
- For utility functions:
  - Start with a descriptive verb
  - Follow with nouns or adjectives as needed
- Examples:
  ```
  # Technique function
  credential_access_keychain()
  discover_network_shares()
  
  # Utility function
  validate_input()
  process_user_data()
  ```

##

### Array and Associative Array Names
- Use UPPERCASE for array and associative array names
- Use underscores to separate words in multi-word array names
- Use plural nouns to indicate multiple items
- Examples:
  ```
  declare -a ALLOWED_USERS
  declare -A CONFIG_OPTIONS
  ```

##

### Constants
- Use UPPERCASE for constants
- Use underscores to separate words in multi-word constant names
- Use descriptive nouns or adjectives
- Examples:
  ```
  readonly MAX_CONNECTIONS=30
  readonly DEFAULT_TIMEOUT=60
  ```

##

### Command-line Arguments
- Use lowercase for command-line argument names
- Use hyphens to separate words in multi-word argument names
- Use nouns or verb-noun combinations
- Examples:
  ```
  --verbose
  --output-method
  ```

##

### Function Type and Variable Type Comments
- Use #FunctionType: or #VariableType: comments to indicate the type of function or variable
- Use lowercase for the type
- Use nouns or adjectives to describe the type
- Examples:
  ```
  #FunctionType: utility
  #VariableType: attackScript
  ```

##

### Command Variables
- Use UPPERCASE for command variables
- Use underscores to separate words in multi-word command names
- Use verb-noun combinations or descriptive nouns
- command options must also be declared in varaibles
- Examples:
  ```
  FIND_COMMAND='find / -name "*.log"'
  GREP_PATTERN='grep -E "error|warning"'
  ```

##

### MITRE ATT&CK Mappings
- Use UPPERCASE for MITRE ATT&CK related variables
- Use underscores to separate words in multi-word names
- Use nouns or noun phrases from the MITRE ATT&CK framework
- Examples:
  ```
  TACTIC="Credential Access"
  TTP_ID="T1555.001"
  ```

##

### File and Directory Names
- Use lowercase for file and directory names in variables
- Use underscores to separate words in multi-word names
- Use descriptive nouns or noun phrases
- Examples:
  ```
  log_file="${log_dir}/${ttp_id}_${name}.log"
  config_dir="/etc/myapp"
  ```

##

### Boolean Variables
- Prefix boolean variables with "is_", "has_", or similar adjectives
- Use lowercase for the variable name
- Use adjectives or past participles after the prefix
- Examples:
  ```
  is_valid=true
  has_permission=false
  ```

##

### Loop Variables
- Use short, meaningful names for loop variables
- Stick to conventional names like i, j, k for simple loops
- Use singular nouns for more complex loops
- Examples:
  ```
  for i in "${ARRAY[@]}"; do
    # ...
  done

  for file in *.txt; do
    # ...
  done
  ```

##

### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
2. Bash Manual: https://www.gnu.org/software/bash/manual/
3. Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html

##

