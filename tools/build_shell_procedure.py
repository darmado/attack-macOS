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
    print(f"  python3 build_procedure.py --help             Show this help")
    print(f"\n{BOLD}EXAMPLES:{RESET}")
    print(f"  python3 build_procedure.py system_info.yml")
    print(f"  python3 build_procedure.py --force system_info.yml")
    print(f"  python3 build_procedure.py --all --force")
    print(f"  python3 build_procedure.py --validate browser_history.yml")
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


def generate_flag_vars(proc_data):
    """Generate flag variable declarations"""
    vars_list = []
    for arg in proc_data.arguments:
        var_name = option_to_var(arg['option'])
        if arg.get('type') in ['string', 'integer']:
            vars_list.append(f"INPUT_{var_name}=\"\"")
        else:
            vars_list.append(f"{var_name}=false")
    return '\n'.join(vars_list)
    

def generate_global_vars(proc_data):
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


def generate_arg_parser(proc_data):
    """Generate argument parser cases"""
    cases = []
    for arg in proc_data.arguments:
        option = arg['option']
        var_name = option_to_var(option)
        
        if arg.get('type') in ['string', 'integer']:
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
        else:
            case = f"        {option})\n            {var_name}=true\n            ;;"
        
        cases.append(case)
    
    return '\n'.join(cases)


def generate_help_text(proc_data):
    """Generate help text"""
    help_lines = []
    for arg in proc_data.arguments:
        option = arg['option']
        desc = arg['description']
        
        if arg.get('type') in ['string', 'integer']:
            option_display = f"{option} VALUE"
        else:
            option_display = option
            
        help_lines.append(f"  {option_display:<25} {desc}")
    
    return '\n'.join(help_lines)


def generate_functions(proc_data):
    """Generate function code"""
    if not proc_data.functions:
        return ""
    
    code_lines = ["# Functions from YAML procedure", ""]
    
    for func in proc_data.functions:
        name = func['name']
        desc = func.get('description', f'{name} - Generated from YAML')
        code = func['code']
        
        code_lines.append(f"# Function: {name}")
        code_lines.append(f"# Description: {desc}")
        
        if f"{name}()" in code and "{" in code:
            code_lines.append(code)
        else:
            code_lines.append(f"{name}() {{")
            code_lines.append("")
            for line in code.split('\n'):
                if line.strip():
                    code_lines.append(f"    {line}")
                else:
                    code_lines.append("")
            code_lines.append("}")
        
        code_lines.append("")
    
    return '\n'.join(code_lines)


def generate_main_exec(proc_data):
    """Generate main execution logic"""
    exec_lines = ["# Execute main logic", "raw_output=\"\"", ""]
    
    # Create a mapping of function names to their languages for global setting
    func_languages = {}
    all_languages = set()
    for func in proc_data.functions:
        func_name = func['name']
        languages = func.get('language', ['shell'])
        # Convert array to comma-separated string for logging
        lang_string = ','.join(languages)
        func_languages[func_name] = lang_string
        all_languages.update(languages)
    
    # Set FUNCTION_LANG globally once with all languages used in this procedure
    global_lang_string = ','.join(sorted(all_languages))
    exec_lines.append(f"# Set global function language for this procedure")
    exec_lines.append(f"FUNCTION_LANG=\"{global_lang_string}\"")
    exec_lines.append("")
    
    for arg in proc_data.arguments:
        if 'execute_function' not in arg:
            continue
        
        option = arg['option']
        var_name = option_to_var(option)
        
        exec_lines.append(f"# Execute functions for {option}")
        exec_lines.append(f"if [ \"${var_name}\" = true ]; then")
        exec_lines.append(f"    core_debug_print \"Executing functions for {option}\"")
        
        for func_name in arg['execute_function']:
            # No need to set FUNCTION_LANG here since it's set globally above
            exec_lines.append(f"    result=$({func_name})")
            exec_lines.append(f"    raw_output=\"${{raw_output}}${{result}}\\n\"")
            
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
        '# PLACEHOLDER_FLAG_VARIABLES': generate_flag_vars(proc_data),
        '# PLACEHOLDER_GLOBAL_VARIABLES': generate_global_vars(proc_data),
        '# PLACEHOLDER_FUNCTIONS': generate_functions(proc_data),
        '# PLACEHOLDER_ARGUMENT_PARSER_OPTIONS': generate_arg_parser(proc_data),
        '# PLACEHOLDER_HELP_TEXT': generate_help_text(proc_data),
        '# PLACEHOLDER_MAIN_EXECUTION': generate_main_exec(proc_data),
    }
    
    # Apply replacements
    for old, new in replacements.items():
        content = content.replace(old, new)
    
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
            generate_global_vars(proc_data) + auto_variables
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
    if not generate_and_update_guid(yaml_file, output_file, yaml_data):
        print(f"{BOLD}{YELLOW}WARNING:{RESET} GUID update failed, but script is functional")
    
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
    elif len(sys.argv) == 2 and sys.argv[1] not in ["--help", "--all"]:
        # Single YAML file
        yaml_file = sys.argv[1]
        build_script(yaml_file, force=force)
    elif len(sys.argv) == 3 and sys.argv[1] == "--validate":
        yaml_file = sys.argv[2]
        yaml_data = read_yaml(yaml_file)
        if validate_yaml(yaml_data, yaml_file):
            print(f"\n{BOLD}{GREEN}VALIDATION PASSED:{RESET} {Path(yaml_file).name}")
        else:
            print(f"\n{BOLD}{RED}VALIDATION FAILED:{RESET} {Path(yaml_file).name}")
    elif len(sys.argv) == 2 and sys.argv[1] == "--help":
        show_usage()
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


def generate_and_update_guid(yaml_file, script_file, yaml_data):
    """Generate a new GUID and update both YAML and script files"""
    new_guid = str(uuid.uuid4())
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    try:
        # Update YAML file with new GUID and updated date
        yaml_data['guid'] = new_guid
        yaml_data['updated'] = current_date
        
        # Write updated YAML back to file
        with open(yaml_file, 'w') as f:
            yaml.dump(yaml_data, f, default_flow_style=False, sort_keys=False)
        
        # Update script file - replace placeholders in header comments
        with open(script_file, 'r') as f:
            script_content = f.read()
        
        script_content = script_content.replace('[GUID]', new_guid)
        script_content = script_content.replace('[UPDATED]', current_date)
        
        with open(script_file, 'w') as f:
            f.write(script_content)
        
        print(f"{BOLD}GUID generated:{RESET} {new_guid}")
        print(f"{BOLD}Updated date:{RESET} {current_date}")
        return True
        
    except Exception as e:
        print(f"{BOLD}{RED}GUID/Updated update failed:{RESET} {e}")
        return False


if __name__ == "__main__":
    main() 