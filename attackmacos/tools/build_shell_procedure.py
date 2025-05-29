#!/usr/bin/env python3
"""
Build shell scripts from YAML procedure definitions
Clean, modular implementation using single-responsibility functions
"""

import yaml
import sys
import json
import uuid
import subprocess
from pathlib import Path
import jsonschema


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
    print(f"  python3 build_procedure.py --validate <file>  Validate YAML only")
    print(f"  python3 build_procedure.py --help             Show this help")
    print(f"\n{BOLD}EXAMPLES:{RESET}")
    print(f"  python3 build_procedure.py system_info.yml")
    print(f"  python3 build_procedure.py --all")
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
    """Read YAML file"""
    with open(yaml_file, 'r') as f:
        return yaml.safe_load(f)


def validate_yaml(yaml_data, yaml_file):
    """Validate YAML against schema"""
    try:
        script_dir = Path(__file__).parent
        schema_path = script_dir.parent / "core" / "schemas" / "procedure.schema.json"
        
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        
        jsonschema.validate(yaml_data, schema)
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
    
    for arg in proc_data.arguments:
        if 'execute_function' not in arg:
            continue
        
        option = arg['option']
        var_name = option_to_var(option)
        
        exec_lines.append(f"# Execute functions for {option}")
        exec_lines.append(f"if [ \"${var_name}\" = true ]; then")
        exec_lines.append(f"    core_debug_print \"Executing functions for {option}\"")
        
        for func_name in arg['execute_function']:
            exec_lines.append(f"    result=$({func_name})")
            exec_lines.append(f"    raw_output=\"${{raw_output}}${{result}}\\n\"")
        
        exec_lines.append("fi")
        exec_lines.append("")
    
    exec_lines.append(f"data_source=\"{proc_data.name}\"")
    
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


def build_script(yaml_file):
    """Build script from YAML file"""
    yaml_data = read_yaml(yaml_file)
    
    if not validate_yaml(yaml_data, yaml_file):
        return None
    
    proc_data = ProcedureData(yaml_data)
    
    # Read base script
    script_dir = Path(__file__).parent
    base_script = script_dir.parent / "core" / "base" / "base.sh"
    
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
    
    # OPSEC settings
    opsec_check = any(
        func.get('opsec', {}).get('check_fda', {}).get('enabled', False)
        for func in proc_data.functions
    )
    if opsec_check:
        content = content.replace('CHECK_FDA="false"', 'CHECK_FDA="true"')
    
    # Determine output path
    yaml_path = Path(yaml_file).resolve()
    output_dir = yaml_path.parent
    base_filename = f"{proc_data.name}.sh"
    base_output = output_dir / base_filename
    
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
    
    print(f"{BOLD}{GREEN}BUILD SUCCESS:{RESET} {Path(output_file).name}")
    
    return str(output_file)


def find_yamls_needing_scripts():
    """Find YAML files that need scripts built"""
    script_dir = Path(__file__).parent
    ttp_dir = script_dir.parent / "ttp"
    
    yaml_files = []
    for pattern in ['**/*.yml', '**/*.yaml']:
        yaml_files.extend(ttp_dir.glob(pattern))
    
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


def build_all():
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
            script_path = build_script(str(yaml_file))
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
    
    if sys.argv[1] == "--all":
        build_all()
    elif sys.argv[1] == "--validate" and len(sys.argv) == 3:
        yaml_file = sys.argv[2]
        yaml_data = read_yaml(yaml_file)
        if validate_yaml(yaml_data, yaml_file):
            print(f"\n{BOLD}{GREEN}VALIDATION PASSED:{RESET} {Path(yaml_file).name}")
        else:
            print(f"\n{BOLD}{RED}VALIDATION FAILED:{RESET} {Path(yaml_file).name}")
    elif sys.argv[1] == "--help":
        show_usage()
    else:
        yaml_file = sys.argv[1]
        build_script(yaml_file)


def validate_shell_syntax(script_path):
    """Validate shell script syntax using bash -n"""
    try:
        result = subprocess.run(
            ['bash', '-n', str(script_path)], 
            capture_output=True, 
            text=True, 
            timeout=10
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
        # Exclude warnings we don't care about:
        # SC2034 - unused variables (base.sh has many global vars)
        # SC3043 - POSIX sh warnings (we use bash)
        # SC2155 - declare and assign separately (style preference)
        # SC2046 - quote word splitting (sometimes intentional)
        excludes = "SC2034,SC3043,SC2155,SC2046"
        
        result = subprocess.run(
            ['shellcheck', '-f', 'gcc', '-e', excludes, '-S', 'error', str(script_path)], 
            capture_output=True, 
            text=True, 
            timeout=30
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


if __name__ == "__main__":
    main() 