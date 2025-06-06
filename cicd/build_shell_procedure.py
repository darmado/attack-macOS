#!/usr/bin/env python3
"""
Build shell scripts from YAML procedure definitions for macOS ATT&CK techniques.

Author: @darmado | https://x.com/darmad0
Version: 1.0.0
Created: 2025-05-30
Last Modified: 2025-05-30
License: Apache 2.0

Description:
    This script builds executable shell scripts from YAML procedure definitions
    that implement MITRE ATT&CK techniques for macOS. It follows a clean,
    modular implementation using single-responsibility functions.

Dependencies:
    - Python 3.6+
    - PyYAML
    - jsonschema

Usage:
    python3 build_procedure.py <yaml_file>        Build single YAML file
    python3 build_procedure.py --all              Build all YAML files
    python3 build_procedure.py --force <file>     Force overwrite existing file
    python3 build_procedure.py --all --force      Force overwrite all files
    python3 build_procedure.py --validate <file>  Validate YAML only
    python3 build_procedure.py --sync-caldera     Sync built scripts to Caldera plugin
    python3 build_procedure.py --help             Show this help

Example:
    python3 build_procedure.py system_info.yml
"""

import yaml
import sys
import json
import uuid
import subprocess
from pathlib import Path
import jsonschema
from datetime import datetime


# ANSI color codes for better output
BOLD = '\033[1m'
RED = '\033[91m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'


def show_usage():
    """Display usage information"""
    print(f"\n{BOLD}Attack-macOS Build Tool{RESET}")
    print("Build shell scripts from YAML procedure definitions")
    print(f"\n{BOLD}USAGE:{RESET}")
    print(f"  python3 build_procedure.py <yaml_file>        Build single YAML file")
    print(f"  python3 build_procedure.py --all              Build all YAML files")
    print(f"  python3 build_procedure.py --force <file>     Force overwrite existing file")
    print(f"  python3 build_procedure.py --all --force      Force overwrite all files")
    print(f"  python3 build_procedure.py --validate <file>  Validate YAML only")
    print(f"  python3 build_procedure.py --sync-caldera     Sync built scripts to Caldera plugin")
    print(f"  python3 build_procedure.py --help             Show this help")
    print(f"\n{BOLD}EXAMPLES:{RESET}")
    print(f"  python3 build_procedure.py system_info.yml")
    print(f"  python3 build_procedure.py --force system_info.yml")
    print(f"  python3 build_procedure.py --all --force")
    print(f"  python3 build_procedure.py --validate browser_history.yml")
    print(f"  python3 build_procedure.py --sync-caldera")
    print()


class ProcedureData:
    """Container for YAML procedure data"""
    def __init__(self, yaml_data):
        self.data = yaml_data
        self.procedure = yaml_data['procedure']
        self.name = yaml_data['procedure_name']
    
    @property
    def arguments(self):
        return self.procedure['arguments']
    
    @property
    def functions(self):
        return self.procedure.get('functions', [])
    
    @property
    def global_vars(self):
        return self.procedure.get('global_variable', [])


def read_yaml(yaml_file):
    """Read YAML file with better error handling"""
    try:
        with open(yaml_file, 'r') as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        yaml_name = Path(yaml_file).name
        print(f"\n{BOLD}{RED}YAML SYNTAX ERROR: {yaml_name}{RESET}")
        print(f"Error: {e}")
        if hasattr(e, 'problem_mark'):
            mark = e.problem_mark
            print(f"Line {mark.line + 1}, Column {mark.column + 1}")
        sys.exit(1)
    except Exception as e:
        yaml_name = Path(yaml_file).name
        print(f"\n{BOLD}{RED}FILE ERROR: {yaml_name}{RESET}")
        print(f"Error: {e}")
        sys.exit(1)


def validate_yaml(yaml_data, yaml_file):
    """Validate YAML against schema"""
    try:
        script_dir = Path(__file__).parent
        # Go up to project root, then into attackmacos/core/schemas
        schema_path = script_dir.parent / "attackmacos" / "core" / "schemas" / "procedure.schema.json"
        
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        
        # Create a copy of yaml_data for validation with placeholders replaced by valid values
        validation_data = yaml_data.copy()
        
        # Replace placeholders with valid values for validation only
        if validation_data.get('guid') == '$GUID':
            validation_data['guid'] = '00000000-0000-0000-0000-000000000000'  # Valid GUID format
        
        if validation_data.get('updated') == '$UPDATED':
            validation_data['updated'] = '2025-05-30'  # Valid date format
        
        jsonschema.validate(validation_data, schema)
        return True
    except jsonschema.ValidationError as e:
        # Clean, human-readable error messages
        yaml_name = Path(yaml_file).name
        print(f"\n{BOLD}{RED}VALIDATION FAILED: {yaml_name}{RESET}")
        print(f"Error: {e.message}")
        
        if e.absolute_path:
            path_str = ' -> '.join(str(p) for p in e.absolute_path)
            print(f"Location: {path_str}")
        
        # Common fixes for typical errors
        if "'boolean' is not one of" in e.message:
            print(f"{BOLD}Fix:{RESET} Remove 'type: boolean' from boolean arguments (type field is optional for flags)")
        elif "is a required property" in e.message:
            missing_field = e.message.split("'")[1]
            print(f"{BOLD}Fix:{RESET} Add required field '{missing_field}' to your YAML")
        elif "does not match" in e.message and "pattern" in str(e.schema):
            print(f"{BOLD}Fix:{RESET} Check the format/pattern requirements for this field")
        
        return False
    except Exception as e:
        yaml_name = Path(yaml_file).name
        print(f"\n{BOLD}{RED}SCHEMA ERROR: {yaml_name}{RESET}")
        print(f"Error: {e}")
        return False
    

def option_to_var(option):
    """Convert --option-name to OPTION_NAME"""
    if '|' in option:
        option = option.split('|')[1]
    return option.lstrip('-').upper().replace('-', '_')


def use_sudo(code):
    """Transform command executions to include $CMD_SUDO"""
    import re
    
    # Pattern to match command executions like $("$CMD_COMMAND" ...)
    # This matches: $("$CMD_ANYTHING" followed by arguments until closing )
    pattern = r'\$\(\s*"\$CMD_([^"]+)"\s*([^)]*)\)'
    
    def replace_command(match):
        cmd_var = match.group(1)  # The command variable name (e.g., SOCKETFILTERFW)
        cmd_args = match.group(2).strip()  # The arguments
        
        # Reconstruct with $CMD_SUDO prefix
        if cmd_args:
            return f'$("$CMD_SUDO" "$CMD_{cmd_var}" {cmd_args})'
        else:
            return f'$("$CMD_SUDO" "$CMD_{cmd_var}")'
    
    # Apply the transformation
    transformed = re.sub(pattern, replace_command, code)
    
    return transformed


def transform_commands_with_sudo(code):
    """Transform command executions to include $CMD_SUDO"""
    import re
    
    # Pattern to match command executions like $("$CMD_COMMAND" ...)
    # This matches: $( followed by "$CMD_ANYTHING" followed by arguments until closing )
    pattern = r'\$\(\s*"\$CMD_([A-Z_]+)"\s*([^)]*)\)'
    
    def replace_func(match):
        cmd_var = match.group(1)  # The command variable name (e.g., SOCKETFILTERFW)
        args = match.group(2)     # The arguments (e.g., --setglobalstate OFF 2>&1)
        
        # Transform to include $CMD_SUDO
        return f'$("$CMD_SUDO" "$CMD_{cmd_var}"{args})'
    
    # Apply the transformation
    transformed_code = re.sub(pattern, replace_func, code)
    
    return transformed_code


def build_input_handler(proc_data):
    """Generate input processing functions for type conversion and validation"""
    processing_lines = []
    
    # Check if we have any input arguments that need processing
    has_input_args = any(arg.get('type') in ['string', 'integer'] or arg.get('input_required', False) 
                        for arg in proc_data.arguments)
    
    if not has_input_args:
        return ""
    
    processing_lines.append("# Input processing and type conversion")
    processing_lines.append("process_input_arguments() {")
    processing_lines.append("    # Process and validate input arguments based on their types")
    
    for arg in proc_data.arguments:
        if arg.get('type') in ['string', 'integer'] or arg.get('input_required', False):
            option = arg['option']
            var_name = option_to_var(option)
            input_var = f"INPUT_{var_name}"
            arg_type = arg.get('type', 'string')
            
            processing_lines.append(f"    ")
            processing_lines.append(f"    # Process {option} argument")
            processing_lines.append(f"    if [ -n \"${{{input_var}}}\" ]; then")
            
            if arg_type == 'integer':
                processing_lines.append(f"        # Validate integer input")
                processing_lines.append(f"        if ! echo \"${{{input_var}}}\" | grep -qE '^[0-9]+$'; then")
                processing_lines.append(f"            echo \"Error: {option} requires a valid integer, got: ${{{input_var}}}\" >&2")
                processing_lines.append(f"            exit 1")
                processing_lines.append(f"        fi")
                processing_lines.append(f"        {var_name}_ARG=\"${{{input_var}}}\"")
            else:
                # Default to string processing
                processing_lines.append(f"        # Process string input")
                processing_lines.append(f"        {var_name}_ARG=\"${{{input_var}}}\"")
            
            processing_lines.append(f"    fi")
    
    processing_lines.append("}")
    processing_lines.append("")
    
    return '\n'.join(processing_lines)


def build_flag_vars(proc_data):
    """Generate flag variable declarations"""
    vars_list = []
    for arg in proc_data.arguments:
        var_name = option_to_var(arg['option'])
        has_input = arg.get('type') in ['string', 'integer'] or arg.get('input_required', False)
        has_execution = arg.get('execute_function', [])
        
        if has_input and has_execution:
            # Dual-purpose argument: needs both INPUT_ variable and trigger flag
            vars_list.append(f"INPUT_{var_name}=\"\"")
            vars_list.append(f"{var_name}=false")
        elif has_input:
            # Input-only argument: just INPUT_ variable
            vars_list.append(f"INPUT_{var_name}=\"\"")
        elif has_execution:
            # Action-only argument: just trigger flag
            vars_list.append(f"{var_name}=false")
    return '\n'.join(vars_list)
    

def build_global_vars(proc_data):
    """Generate global variable declarations"""
    vars_list = []
    for var in proc_data.global_vars:
        name = var['name']
        var_type = var['type']
        default = var['default_value']
        
        if var_type == 'array':
            if 'array_elements' in var:
                vars_list.append(f"{name}=(")
                for element in var['array_elements']:
                    vars_list.append(f"    \"{element}\"")
                vars_list.append(")")
            else:
                vars_list.append(f"{name}=()")
        elif var_type == 'string':
            vars_list.append(f"{name}=\"{default}\"")
        else:
            vars_list.append(f"{name}={default}")
    
    return '\n'.join(vars_list)


def build_arg_parser(proc_data):
    """Generate argument parser cases"""
    cases = []
    for arg in proc_data.arguments:
        option = arg['option']
        var_name = option_to_var(option)
        has_input = arg.get('type') in ['string', 'integer'] or arg.get('input_required', False)
        has_execution = arg.get('execute_function', [])
        
        if has_input and has_execution:
            # Dual-purpose argument: store input AND set trigger flag
            input_var = f"INPUT_{var_name}"
            case = f"""        {option})
            if [ -n "$2" ] && [ "$2" != "${{2#-}}" ]; then
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                {input_var}="$2"
                {var_name}=true
                    shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;"""
        elif has_input:
            # Input-only argument: just store input
            input_var = f"INPUT_{var_name}"
            case = f"""        {option})
            if [ -n "$2" ] && [ "$2" != "${{2#-}}" ]; then
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                {input_var}="$2"
                    shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
                fi
                ;;"""
        elif has_execution:
            # Action-only argument: just set trigger flag
            case = f"        {option})\n            {var_name}=true\n            ;;"
        
        cases.append(case)
    
    return '\n'.join(cases)


def build_help_text(proc_data):
    """Generate help text with proper input format descriptions"""
    help_lines = []
    for arg in proc_data.arguments:
        option = arg['option']
        desc = arg['description']
        arg_type = arg.get('type', '')
        
        # Determine input format - check type FIRST, then fall back to description analysis
        input_format = ""
        if arg.get('type') in ['string', 'integer'] or arg.get('input_required', False):
            # Check explicit type first
            if arg.get('type') == 'integer':
                input_format = "NUMBER"
            elif arg.get('type') == 'string':
                # For string types, analyze description for more specific format
                desc_lower = desc.lower()
                if any(word in desc_lower for word in ['enable', 'disable', 'on', 'off']):
                    input_format = "ENABLE|DISABLE"
                elif 'application' in desc_lower and any(word in desc_lower for word in ['block', 'unblock', 'remove']):
                    input_format = "APP_PATH"
                elif 'file' in desc_lower or 'path' in desc_lower:
                    input_format = "FILE_PATH"
                elif 'size' in desc_lower:
                    input_format = "SIZE"
                else:
                    input_format = "VALUE"
            else:
                # No explicit type, use description analysis as fallback
                desc_lower = desc.lower()
                if any(word in desc_lower for word in ['enable', 'disable', 'on', 'off']):
                    input_format = "ENABLE|DISABLE"
                elif 'application' in desc_lower and any(word in desc_lower for word in ['block', 'unblock', 'remove']):
                    input_format = "APP_PATH"
                elif 'file' in desc_lower or 'path' in desc_lower:
                    input_format = "FILE_PATH"
                elif 'size' in desc_lower:
                    input_format = "SIZE"
                else:
                    input_format = "VALUE"
        
        # Format option with proper spacing (34 characters total width)
        if input_format:
            option_display = f"{option} {input_format}"
        else:
            option_display = option
            
        # Use proper spacing to match base.sh format (34 character field width)
        help_lines.append(f"  {option_display:<32} {desc}")
    
    return '\n'.join(help_lines)


def build_functions(proc_data):
    """Generate function definitions"""
    function_lines = []
    
    if not proc_data.functions:
        return ""
        
    for func in proc_data.functions:
        function_lines.append(f"# Function: {func['name']}")
        function_lines.append(f"# Type: {func.get('type', 'implementation')}")
        function_lines.append(f"# Languages: {', '.join(func.get('language', ['shell']))}")
        
        # Set function language for logging
        function_lines.append(f"FUNCTION_LANG=\"{','.join(func.get('language', ['shell']))}\"")
        
        # Apply sudo transformation if needed
        code = func['code']
        if func.get('sudo_required', False):
            code = transform_commands_with_sudo(code)
            function_lines.append(f"# Sudo privileges: Required (commands auto-transformed)")
        else:
            function_lines.append(f"# Sudo privileges: Not required")
            
        function_lines.append("")
        function_lines.append(code)
        function_lines.append("")
    
    return '\n'.join(function_lines)


def build_main_logic(proc_data):
    """Generate main execution logic with consolidated function execution"""
    exec_lines = []
    
    exec_lines.append("# Execute main logic")
    exec_lines.append("raw_output=\"\"")
    exec_lines.append("")
    exec_lines.append("# Set global function language for this procedure")
    exec_lines.append("FUNCTION_LANG=\"shell\"")
    exec_lines.append("")
    
    # Add input processing call if we have input arguments
    has_input_args = any(arg.get('type') in ['string', 'integer'] or arg.get('input_required', False) 
                        for arg in proc_data.arguments)
    if has_input_args:
        exec_lines.append("# Process input arguments")
        exec_lines.append("process_input_arguments")
        exec_lines.append("")
    
    # Add helper function for executing functions
    exec_lines.append("# Helper function to execute procedure functions")
    exec_lines.append("execute_function() {")
    exec_lines.append("    local func_name=\"$1\"")
    exec_lines.append("    # Call the function directly - let the function handle its own permissions")
    exec_lines.append("    $func_name")
    exec_lines.append("}")
    exec_lines.append("")
    
    # Generate simple execution for each argument
    for arg in proc_data.arguments:
        flag_var = option_to_var(arg['option'])
        exec_lines.append(f"# Execute functions for {arg['option']}")
        exec_lines.append(f"if [ \"${flag_var}\" = true ]; then")
        exec_lines.append(f"    core_debug_print \"Executing functions for {arg['option']}\"")
        
        for func_name in arg['execute_function']:
            exec_lines.append(f"    result=$(execute_function {func_name})")
            exec_lines.append(f"    raw_output=\"${{raw_output}}${{result}}\"")
            
        exec_lines.append("fi")
        exec_lines.append("")
    
    # Use PROCEDURE_NAME instead of data_source for consistency
    exec_lines.append("# Set procedure name for processing")
    exec_lines.append(f"procedure=\"{proc_data.name}\"")
    
    return '\n'.join(exec_lines)


def find_next_version(output_dir, base_filename):
    """Find next available version"""
    base_name = base_filename.replace('.sh', '')
    version = 1
    
    while True:
        versioned_filename = f"{base_name}_v{version}.sh"
        if not (output_dir / versioned_filename).exists():
            return versioned_filename, version
        version += 1


def get_tactic_directory(tactic):
    """Convert tactic name to directory path"""
    tactic_map = {
        'Discovery': 'discovery',
        'Defense Evasion': 'defense_evasion', 
        'Persistence': 'persistence',
        'Collection': 'collection',
        'Credential Access': 'credential_access',
        'Execution': 'execution',
        'Initial Access': 'initial_access',
        'Lateral Movement': 'lateral_movement',
        'Privilege Escalation': 'privilege_escalation',
        'Command and Control': 'command_and_control',
        'Exfiltration': 'exfiltration',
        'Impact': 'impact'
    }
    return tactic_map.get(tactic, tactic.lower().replace(' ', '_'))


def create_test_file(script_path, proc_data):
    """Generate simple test file with all script options in test_scripts directory"""
    script_file = Path(script_path)
    
    # Create test_scripts directory relative to cicd directory
    cicd_dir = Path(__file__).parent
    test_scripts_dir = cicd_dir / "test_scripts"
    test_scripts_dir.mkdir(exist_ok=True)
    
    test_file = test_scripts_dir / f"test_{script_file.stem}.sh"
    
    # Extract all options from arguments
    options = []
    for arg in proc_data.arguments:
        option = arg['option']
        if arg.get('type') == 'integer':
            options.append(f'{option} 30')  # Use realistic integer values
        elif arg.get('type') in ['string'] or arg.get('input_required', False):
            options.append(f'{option} "test_value"')
        else:
            options.append(option)
    
    # Create test content with proper path to script
    relative_script_path = Path("..") / script_file.relative_to(cicd_dir.parent)
    
    test_content = f"""#!/bin/bash
# Auto-generated test for {script_file.name}

# Test with all options
{relative_script_path} {' '.join(options)}
"""
    
    # Write test file
    with open(test_file, 'w') as f:
        f.write(test_content)
    
    test_file.chmod(0o755)
    print(f"{BOLD}Test created:{RESET} {test_file.name}")


def build_script(yaml_file, force=False):
    """Build script from YAML file"""
    yaml_data = read_yaml(yaml_file)
    
    if not validate_yaml(yaml_data, yaml_file):
        return None
    
    proc_data = ProcedureData(yaml_data)
    
    # Read base script
    script_dir = Path(__file__).parent
    base_script = script_dir.parent / "attackmacos" / "core" / "base" / "base.sh"
    
    with open(base_script, 'r') as f:
        content = f.read()
    
    # Generate all sections
    replacements = {
        '# PLACEHOLDER_FLAG_VARIABLES': build_flag_vars(proc_data),
        '# PLACEHOLDER_GLOBAL_VARIABLES': build_global_vars(proc_data),
        '# PLACEHOLDER_INPUT_PROCESSING': build_input_handler(proc_data),
        '# PLACEHOLDER_FUNCTIONS': build_functions(proc_data),
        '# PLACEHOLDER_ARGUMENT_PARSER_OPTIONS': build_arg_parser(proc_data),
        '# PLACEHOLDER_HELP_TEXT': build_help_text(proc_data),
        '# PLACEHOLDER_MAIN_EXECUTION': build_main_logic(proc_data),
    }
    
    # Apply replacements
    for old, new in replacements.items():
        content = content.replace(old, new)
    
    # Set project root path (absolute path to project root)
    project_root = str(script_dir.parent.resolve())
    content = content.replace('PROJECT_ROOT=""', f'PROJECT_ROOT="{project_root}"')
    
    # Set procedure-specific variables
    content = content.replace('PROCEDURE_NAME=""', f'PROCEDURE_NAME="{proc_data.name}"')
    
    # Update TTP_ID and TACTIC in the configuration section automatically
    content = content.replace('TTP_ID=""', f'TTP_ID="{yaml_data.get("ttp_id", "T1082")}"')
    content = content.replace('TACTIC=""', f'TACTIC="{yaml_data.get("tactic", "Discovery")}"')
    
    # Auto-inject NAME variable only (TTP_ID and TACTIC already exist in config section)
    auto_variables = f"""
# Auto-injected variables from YAML (do not define these in global_variable section)
NAME="{proc_data.name}"
"""
    
    # Add auto-variables right after the user's global variables
    if '# PLACEHOLDER_GLOBAL_VARIABLES' in content:
        content = content.replace(
            '# PLACEHOLDER_GLOBAL_VARIABLES', 
            build_global_vars(proc_data) + auto_variables
        )
    else:
        # Fallback if placeholder is missing
        content = content.replace(
            'PROCEDURE_NAME=""',
            f'PROCEDURE_NAME="{proc_data.name}"{auto_variables}'
        )
    
    # Update header comment section with actual YAML data
    content = content.replace('[PROCEDURE_NAME]', proc_data.name)
    content = content.replace('[TACTIC]', yaml_data.get('tactic', 'Discovery'))
    content = content.replace('[TTP_ID]', yaml_data.get('ttp_id', 'T1082'))
    
    # Handle GUID - if it's $GUID placeholder, leave as [GUID] for later replacement
    guid_value = yaml_data.get('guid', 'PLACEHOLDER_GUID')
    if guid_value == '$GUID':
        content = content.replace('[GUID]', '[GUID]')  # Keep placeholder for later
    else:
        content = content.replace('[GUID]', guid_value)
    
    content = content.replace('[INTENT]', yaml_data.get('intent', 'Security technique implementation'))
    content = content.replace('[AUTHOR]', yaml_data.get('author', '@darmado'))
    content = content.replace('[CREATED]', yaml_data.get('created', '2025-05-30'))
    
    # Handle UPDATED - if it's $UPDATED placeholder, leave as [UPDATED] for later replacement
    updated_value = yaml_data.get('updated', yaml_data.get('created', '2025-05-30'))
    if updated_value == '$UPDATED':
        content = content.replace('[UPDATED]', '[UPDATED]')  # Keep placeholder for later
    else:
        content = content.replace('[UPDATED]', updated_value)
    
    content = content.replace('[VERSION]', yaml_data.get('version', '1.0.0'))
    
    # OPSEC settings
    opsec_check = any(
        func.get('opsec', {}).get('check_fda', {}).get('enabled', False)
        for func in proc_data.functions
    )
    if opsec_check:
        content = content.replace('CHECK_FDA="false"', 'CHECK_FDA="true"')
    
    # Determine output directory based on tactic
    tactic = yaml_data.get('tactic', 'discovery')
    tactic_dir = get_tactic_directory(tactic)
    
    output_dir = script_dir.parent / "attackmacos" / "ttp" / tactic_dir / "shell"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    base_filename = f"{proc_data.name}.sh"
    base_output = output_dir / base_filename
    
    if force:
        # Force mode: overwrite existing file without versioning
        output_file = base_output
        if base_output.exists():
            print(f"{BOLD}Force overwriting:{RESET} {output_file}")
        else:
            print(f"{BOLD}Creating new script:{RESET} {output_file}")
    else:
        # Normal mode: use versioning if file exists
        if base_output.exists():
            versioned_filename, version = find_next_version(output_dir, base_filename)
            output_file = output_dir / versioned_filename
            print(f"{BOLD}Creating version {version}:{RESET} {output_file}")
        else:
            output_file = base_output
            print(f"{BOLD}Creating new script:{RESET} {output_file}")
    
    # Write script
    with open(output_file, 'w') as f:
        f.write(content)
    
    output_file.chmod(0o755)
    
    # Validate generated script syntax
    if not validate_generated_script(output_file):
        print(f"{BOLD}{RED}BUILD FAILED:{RESET} {Path(output_file).name} - syntax errors")
        # Remove the broken script
        output_file.unlink()
        return None
    
    # Generate and update GUID after successful validation
    if not generate_and_update_guid(yaml_file, output_file, yaml_data, force):
        print(f"{BOLD}{YELLOW}WARNING:{RESET} GUID update failed, but script is functional")
    
    # Generate test file after successful build
    create_test_file(output_file, proc_data)
    
    print(f"{BOLD}{GREEN}BUILD SUCCESS:{RESET} {Path(output_file).name}")
    print(f"{BOLD}Location:{RESET} {output_file}")
    
    return str(output_file)


def find_yamls_needing_scripts():
    """Find YAML files that need scripts built"""
    script_dir = Path(__file__).parent
    config_dir = script_dir.parent / "attackmacos" / "core" / "config"
    
    yaml_files = []
    for pattern in ['*.yml', '*.yaml']:
        yaml_files.extend(config_dir.glob(pattern))
    
    need_scripts = []
    for yaml_file in yaml_files:
        try:
            yaml_data = read_yaml(yaml_file)
            if 'procedure_name' not in yaml_data:
                continue
            
            procedure_name = yaml_data['procedure_name']
            script_path = yaml_file.parent / f"{procedure_name}.sh"
            
            if not script_path.exists():
                need_scripts.append(yaml_file)
        except:
            continue
            
    return need_scripts


def build_all(force=False):
    """Build all YAML files that need scripts"""
    yaml_files = find_yamls_needing_scripts()
    print(f"\n{BOLD}Found {len(yaml_files)} YAML files to build{RESET}")
    
    if len(yaml_files) == 0:
        print("All YAML files already have corresponding scripts.")
        return []
    
    built = []
    failed = []
    
    for yaml_file in yaml_files:
        try:
            script_path = build_script(str(yaml_file), force=force)
            if script_path:
                built.append(script_path)
        except Exception as e:
            failed.append(yaml_file)
            print(f"\n{BOLD}{RED}BUILD FAILED: {Path(yaml_file).name}{RESET}")
            print(f"Error: {e}")
    
    print(f"\n{BOLD}BUILD SUMMARY:{RESET}")
    print(f"  Built: {len(built)} scripts")
    if failed:
        print(f"  Failed: {len(failed)} scripts")
    
    return built


def main():
    """CLI interface"""
    if len(sys.argv) == 1:
        show_usage()
        sys.exit(1)
    
    # Parse arguments to handle --force flag
    force = False
    if "--force" in sys.argv:
        force = True
        # Remove --force from argv for cleaner processing
        sys.argv = [arg for arg in sys.argv if arg != "--force"]
    
    if len(sys.argv) == 2 and sys.argv[1] == "--all":
        build_all(force=force)
    elif len(sys.argv) == 2 and sys.argv[1] == "--help":
        show_usage()
    elif len(sys.argv) == 2 and sys.argv[1] == "--sync-caldera":
        sync_to_caldera()
    elif len(sys.argv) == 3 and sys.argv[1] == "--validate":
        yaml_file = sys.argv[2]
        yaml_data = read_yaml(yaml_file)
        if validate_yaml(yaml_data, yaml_file):
            print(f"\n{BOLD}{GREEN}VALIDATION PASSED:{RESET} {Path(yaml_file).name}")
        else:
            print(f"\n{BOLD}{RED}VALIDATION FAILED:{RESET} {Path(yaml_file).name}")
    elif len(sys.argv) == 2 and sys.argv[1] not in ["--help", "--all", "--sync-caldera"]:
        # Check if it's an unknown option
        if sys.argv[1].startswith('--'):
            print(f"{BOLD}{RED}ERROR:{RESET} Unknown option: {sys.argv[1]}")
            show_usage()
            sys.exit(1)
        # Single YAML file
        yaml_file = sys.argv[1]
        build_script(yaml_file, force=force)
    else:
        show_usage()
        sys.exit(1)


def validate_shell_syntax(script_path):
    """Validate shell script syntax using sh -n"""
    try:
        # Change to the script's directory for validation context
        script_dir = Path(script_path).parent
        script_name = Path(script_path).name
        
        result = subprocess.run(
            ['sh', '-n', script_name], 
            capture_output=True, 
            text=True, 
            timeout=10,
            cwd=script_dir
        )
        if result.returncode == 0:
            return True, ""
        else:
            return False, result.stderr
    except Exception as e:
        return False, f"Syntax check failed: {e}"


def validate_with_shellcheck(script_path):
    """Validate shell script with shellcheck if available"""
    try:
        # Change to the script's directory for validation context
        script_dir = Path(script_path).parent
        script_name = Path(script_path).name
        
        # Exclude warnings we don't care about:
        # SC2034 - unused variables (base.sh has many global vars)
        # SC3043 - POSIX sh warnings (we use bash)
        # SC2155 - declare and assign separately (style preference)
        # SC2046 - quote word splitting (sometimes intentional)
        excludes = "SC2034,SC3043,SC2155,SC2046"
        
        result = subprocess.run(
            ['shellcheck', '-f', 'gcc', '-e', excludes, '-S', 'error', script_name], 
            capture_output=True, 
            text=True, 
            timeout=30,
            cwd=script_dir
        )
        if result.returncode == 0:
            return True, ""
        else:
            return False, result.stdout
    except FileNotFoundError:
        return None, "shellcheck not installed"
    except Exception as e:
        return None, f"shellcheck failed: {e}"


def validate_generated_script(script_path):
    """Run all validation checks on generated script"""
    script_name = Path(script_path).name
    
    # Basic syntax check with bash -n
    syntax_ok, syntax_error = validate_shell_syntax(script_path)
    if not syntax_ok:
        print(f"\n{BOLD}{RED}SYNTAX ERROR: {script_name}{RESET}")
        print(f"Error: {syntax_error}")
        return False
    
    # Optional shellcheck validation (errors only)
    shellcheck_ok, shellcheck_output = validate_with_shellcheck(script_path)
    if shellcheck_ok is None:
        # shellcheck not available, that's ok
        print(f"{BOLD}Syntax check:{RESET} PASSED (bash -n)")
    elif shellcheck_ok:
        print(f"{BOLD}Syntax check:{RESET} PASSED (bash -n + shellcheck)")
    else:
        print(f"\n{BOLD}{RED}SHELLCHECK ERRORS: {script_name}{RESET}")
        print(shellcheck_output)
        print(f"{BOLD}Note:{RESET} These are functional errors that will break the script")
        return False
    
    return True


def generate_and_update_guid(yaml_file, script_file, yaml_data, force=False):
    """Generate a new GUID and update both YAML and script files"""
    new_guid = str(uuid.uuid4())
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    try:
        # Read the original YAML file as text to preserve formatting
        with open(yaml_file, 'r') as f:
            yaml_content = f.read()
        
        # Always replace GUID and UPDATED fields using string replacement
        # This preserves all original formatting including pipe blocks
        yaml_content = yaml_content.replace('guid: $GUID', f'guid: {new_guid}')
        yaml_content = yaml_content.replace('updated: $UPDATED', f'updated: \'{current_date}\'')
        
        # When using --force, always update the 'updated' field and increment version
        if force:
            # Update the 'updated' field regardless of current value
            import re
            yaml_content = re.sub(r'updated:\s*[\'"]?[0-9]{4}-[0-9]{2}-[0-9]{2}[\'"]?', 
                                f'updated: \'{current_date}\'', yaml_content)
            
            # Increment the version field (patch version bump)
            current_version = yaml_data.get('version', '1.0.0')
            new_version = increment_version(current_version)
            yaml_content = re.sub(r'version:\s*[\'"]?[0-9]+\.[0-9]+\.[0-9]+[\'"]?', 
                                f'version: {new_version}', yaml_content)
            
            print(f"{BOLD}Force mode:{RESET} Updated version {current_version} → {new_version}")
            print(f"{BOLD}Force mode:{RESET} Updated date → {current_date}")
        
        # Write the minimally modified YAML back to file
        with open(yaml_file, 'w') as f:
            f.write(yaml_content)
        
        # Update script file - replace placeholders in header comments
        with open(script_file, 'r') as f:
            script_content = f.read()
        
        script_content = script_content.replace('[GUID]', new_guid)
        script_content = script_content.replace('[UPDATED]', current_date)
        
        # When using --force, also update version in script header
        if force:
            new_version = increment_version(yaml_data.get('version', '1.0.0'))
            script_content = script_content.replace('[VERSION]', new_version)
        
        with open(script_file, 'w') as f:
            f.write(script_content)
        
        print(f"{BOLD}GUID generated:{RESET} {new_guid}")
        print(f"{BOLD}Updated date:{RESET} {current_date}")
        return True
        
    except Exception as e:
        print(f"{BOLD}{RED}GUID/Updated update failed:{RESET} {e}")
        return False


def increment_version(version_str):
    """Increment patch version (e.g., 1.0.0 → 1.0.1)"""
    try:
        # Split version into parts
        parts = version_str.split('.')
        if len(parts) != 3:
            return '1.0.1'  # Default if invalid format
        
        major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])
        
        # Increment patch version
        patch += 1
        
        return f"{major}.{minor}.{patch}"
    except:
        return '1.0.1'  # Fallback if parsing fails


def sync_to_caldera():
    """Sync all built scripts to Caldera plugin with one ability per script"""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Define paths
    ttp_dir = project_root / "attackmacos" / "ttp"
    config_dir = project_root / "attackmacos" / "core" / "config"
    caldera_plugin_dir = project_root / "integrations" / "caldera" / "plugins" / "attackmacos"
    
    # Create Caldera plugin directories
    payloads_dir = caldera_plugin_dir / "data" / "payloads"
    abilities_dir = caldera_plugin_dir / "data" / "abilities"
    
    payloads_dir.mkdir(parents=True, exist_ok=True)
    abilities_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n{BOLD}Syncing attack-macOS to Caldera plugin (one ability per script){RESET}")
    
    script_count = 0
    ability_count = 0
    
    for yaml_file in config_dir.glob("*.yml"):
        try:
            yaml_data = read_yaml(yaml_file)
            if 'procedure_name' not in yaml_data:
                continue
            
            procedure_name = yaml_data['procedure_name']
            tactic = yaml_data.get('tactic', 'Discovery')
            tactic_dir = get_tactic_directory(tactic)
            
            # Find the corresponding built script
            script_path = ttp_dir / tactic_dir / "shell" / f"{procedure_name}.sh"
            if not script_path.exists():
                print(f"{BOLD}{YELLOW}SKIP:{RESET} {procedure_name}.sh not found, run build first")
                continue
            
            # Copy script to payloads (once per script)
            payload_dest = payloads_dir / f"{procedure_name}.sh"
            import shutil
            shutil.copy2(script_path, payload_dest)
            script_count += 1
            
            # Generate single ability for this script
            ability_data = generate_comprehensive_ability(yaml_data)
            
            # Create tactic-specific ability directory
            tactic_abilities_dir = abilities_dir / tactic_dir
            tactic_abilities_dir.mkdir(exist_ok=True)
            
            # Write the ability
            ability_uuid = ability_data['id']
            ability_yaml = ability_data['yaml']
            ability_name = ability_data['name']
            
            ability_file = tactic_abilities_dir / f"{ability_uuid}.yml"
            with open(ability_file, 'w') as f:
                f.write(ability_yaml)
            ability_count += 1
            
            print(f"{BOLD}Created:{RESET} {ability_name} → {ability_uuid}.yml")
            
        except Exception as e:
            print(f"{BOLD}{RED}ERROR:{RESET} Failed to sync {yaml_file.name}: {e}")
    
    # Sync documentation
    sync_documentation(config_dir, caldera_plugin_dir)
    
    print(f"\n{BOLD}SYNC COMPLETE:{RESET}")
    print(f"  Payloads copied: {script_count}")
    print(f"  Abilities generated: {ability_count}")
    print(f"  Documentation synced")
    print(f"  Location: {caldera_plugin_dir}")
    
    if ability_count > 0:
        print(f"\n{BOLD}Next steps:{RESET}")
        print(f"  1. Copy plugin to your Caldera instance")
        print(f"  2. Add 'attackmacos' to your Caldera config")
        print(f"  3. Rebuild Caldera Docker container")
    else:
        print(f"\n{BOLD}{RED}No abilities generated due to errors.{RESET}")
        print(f"Check the error messages above and fix the YAML files.")


def sync_documentation(config_dir, caldera_plugin_dir):
    """Generate abilities.md from actual YAML data"""
    docs_dir = caldera_plugin_dir / "docs"
    docs_dir.mkdir(exist_ok=True)
    
    abilities_content = ["# Abilities Reference", ""]
    
    # Group by tactic
    tactics = {}
    
    for yaml_file in config_dir.glob("*.yml"):
        try:
            yaml_data = read_yaml(yaml_file)
            if 'procedure_name' not in yaml_data:
                continue
                
            procedure_name = yaml_data['procedure_name']
            tactic = yaml_data.get('tactic', 'Discovery')
            ttp_id = yaml_data.get('ttp_id', 'T1082')
            intent = yaml_data.get('intent', f'{procedure_name} implementation')
            
            if tactic not in tactics:
                tactics[tactic] = []
            
            # Build ability entry
            ability_entry = [
                f"### {procedure_name}",
                intent,
                "",
                "| Property | Value |",
                "|----------|-------|",
                f"| Technique | {ttp_id} |",
                f"| Platform | darwin |",
                f"| Executor | sh |",
                "",
                "| Argument | Description |",
                "|----------|-------------|"
            ]
            
            # Extract arguments directly from YAML
            arguments = yaml_data.get('procedure', {}).get('arguments', [])
            for arg in arguments:
                option = arg.get('option', '')
                description = arg.get('description', '')
                if option:
                    # Clean option to show only long form
                    if '|' in option:
                        clean_option = option.split('|')[1]
                    else:
                        clean_option = option
                    ability_entry.append(f"| `{clean_option}` | {description} |")
            
            ability_entry.append("")  # Empty line after each ability
            tactics[tactic].append('\n'.join(ability_entry))
            
        except Exception as e:
            print(f"{BOLD}{YELLOW}WARNING:{RESET} Failed to process {yaml_file.name} for docs: {e}")
    
    # Write tactics in order
    for tactic in sorted(tactics.keys()):
        abilities_content.append(f"## {tactic}")
        abilities_content.append("")
        for ability in tactics[tactic]:
            abilities_content.append(ability)
    
    # Write abilities.md
    abilities_file = docs_dir / "abilities.md"
    with open(abilities_file, 'w') as f:
        f.write('\n'.join(abilities_content))
    
    print(f"{BOLD}Updated:{RESET} abilities.md with actual YAML data")


def generate_comprehensive_ability(yaml_data):
    """Generate single Caldera ability per script with user.arg fact"""
    procedure_name = yaml_data['procedure_name']
    base_guid = yaml_data.get('guid', '00000000-0000-0000-0000-000000000000')
    
    # Simple command with user.arg fact
    command = f"#{{location}}/{procedure_name}.sh #{{user.arg}}"
    
    # Generate YAML with user.arg fact
    ability_yaml = f"""---
- id: {base_guid}
  name: {procedure_name}
  description: {yaml_data.get('description', f'Execute {procedure_name} with user-defined arguments')}
  tactic: {yaml_data.get('tactic', 'discovery').lower()}
  technique:
    attack_id: {yaml_data.get('ttp_id', 'T1082')}
    name: {yaml_data.get('technique_name', 'System Information Discovery')}
  platforms:
    darwin:
      sh:
        command: {command}
        payloads:
          - {procedure_name}.sh
        cleanup:
          - rm -f #{{location}}/{procedure_name}.sh
        timeout: 300
        parsers:
          - module: base64
            property: attackmacos.{procedure_name}.output
        delete_payload: true
  singleton: true
  requirements:
    - user.arg:
        edge: has_property"""
    
    return {
        'id': base_guid,
        'name': procedure_name,
        'yaml': ability_yaml
    }


if __name__ == "__main__":
    main() 