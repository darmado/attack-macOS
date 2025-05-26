#!/usr/bin/env python3

import yaml
import sys
import re
from pathlib import Path
import os

def read_yaml(yaml_file):
    """Read YAML file into memory"""
    with open(yaml_file, 'r') as f:
        return yaml.safe_load(f)

def generate_flag_variables(yaml_data):
    """Generate flag variable declarations from arguments"""
    variables = []
    
    for arg in yaml_data['procedure']['arguments']:
        option = arg['option']
        
        if arg.get('type') in ['string', 'integer']:
            # String/integer variables with INPUT_ prefix
            var_name = f"INPUT_{option.lstrip('-').split('|')[-1].lstrip('-').upper()}"
            variables.append(f"{var_name}=\"\"")
        else:
            # Boolean variables
            var_name = option.split('|')[-1].lstrip('-').upper()
            variables.append(f"{var_name}=false")
    
    return '\n'.join(variables)

def generate_global_variables(yaml_data):
    """Generate global variable declarations"""
    variables = []
    
    for var in yaml_data['procedure']['global_variable']:
        name = var['name']
        default = var['default_value']
        if var['type'] == 'string':
            # Handle multi-line strings properly
            if '\n' in str(default):
                # Multi-line string - use here-doc style
                variables.append(f"{name}={default}")
            else:
                variables.append(f"{name}=\"{default}\"")
        else:
            variables.append(f"{name}={default}")
    
    return '\n'.join(variables)

def generate_argument_parser(yaml_data):
    """Generate argument parser options matching base.sh pattern"""
    cases = []
    
    for arg in yaml_data['procedure']['arguments']:
        option = arg['option']  # Use the exact string from YAML
        
        if arg.get('type') in ['string', 'integer']:
            # String/integer pattern with missing value handling - match base.sh pattern
            var_name = f"INPUT_{option.lstrip('-').split('|')[-1].lstrip('-').upper()}"
            case_code = f"""        {option})
            if [ -n "$2" ] && [ "$2" != "${{2#-}}" ]; then
                # Next arg starts with -, so no value provided
                MISSING_VALUES="$MISSING_VALUES $1"
            elif [ -n "$2" ]; then
                {var_name}="$2"
                shift
            else
                MISSING_VALUES="$MISSING_VALUES $1"
            fi
            ;;"""
        else:
            # Boolean pattern  
            var_name = option.split('|')[-1].lstrip('-').upper()
            case_code = f"        {option})\n            {var_name}=true\n            ;;"
        
        cases.append(case_code)
    
    return '\n'.join(cases)

def generate_help_text(yaml_data):
    """Generate help text from arguments"""
    help_lines = []
    
    for arg in yaml_data['procedure']['arguments']:
        option = arg['option']
        desc = arg['description']
        
        # Format option for help display
        if arg.get('type') in ['string', 'integer']:
            option_display = f"{option} VALUE"
        else:
            option_display = option
            
        help_lines.append(f"  {option_display:<25} {desc}")
    
    return '\n'.join(help_lines)

def generate_functions(yaml_data):
    """Generate function definitions from YAML following function blueprint"""
    functions = []
    
    for func in yaml_data['procedure']['functions']:
        name = func['name']
        code = func['code'].strip()
        
        # Add function header comment following blueprint
        functions.append(f"#FunctionType: data")
        functions.append(f"#Description: {name} - Generated from YAML procedure")
        functions.append(f"#Parameters: None")
        functions.append(f"#Returns: Query results on stdout")
        functions.append(f"#Dependencies: Global command variables, core_debug_print")
        
        # Process the function code to use global command variables
        processed_code = process_function_code(code)
        
        for line in processed_code.split('\n'):
            functions.append(line)
        functions.append("")
    
    return '\n'.join(functions)

def process_function_code(code):
    """Process function code to use global command variables and POSIX patterns"""
    # Replace direct command calls with global variables
    replacements = {
        'sqlite3': '$CMD_SQLITE3',
        'echo ': '$CMD_PRINTF "%s\\n" ',
        'printf ': '$CMD_PRINTF ',
        'grep ': '$CMD_GREP ',
        'sed ': '$CMD_SED ',
        'awk ': '$CMD_AWK ',
        'cat ': '$CMD_CAT ',
        'wc ': '$CMD_WC ',
        'tr ': '$CMD_TR ',
        'sort ': '$CMD_SORT ',
        'uniq ': '$CMD_UNIQ ',
        'ls ': '$CMD_LS ',
    }
    
    processed = code
    for old, new in replacements.items():
        processed = processed.replace(old, new)
    
    # Ensure POSIX compatibility - replace [[ ]] with [ ]
    processed = re.sub(r'\[\[\s*([^]]+)\s*\]\]', r'[ \1 ]', processed)
    
    # Replace == with = for POSIX compatibility
    processed = re.sub(r'(\s)==(\s)', r'\1=\2', processed)
    
    # Fix variable substitution patterns in SQL queries
    # Replace \$VARIABLE with $VARIABLE (remove escaping)
    processed = re.sub(r'\\(\$[A-Z_]+)', r'\1', processed)
    
    return processed

def generate_validation_code(yaml_data):
    """Generate validation code for parsed arguments"""
    validation_lines = []
    
    validation_lines.append("# Validate procedure-specific arguments")
    
    for arg in yaml_data['procedure']['arguments']:
        if arg.get('type') in ['string', 'integer']:
            var_name = f"INPUT_{arg['option'].lstrip('-').split('|')[-1].lstrip('-').upper()}"
            
            if arg.get('input_required', False):
                validation_lines.append(f"if [ -n \"${var_name}\" ]; then")
                if arg.get('type') == 'string':
                    validation_lines.append(f"    if ! core_validate_input \"${var_name}\" \"string\"; then")
                    validation_lines.append(f"        validation_errors=\"${{validation_errors}}Invalid {arg['option']}: ${var_name}\\n\"")
                    validation_lines.append("    fi")
                elif arg.get('type') == 'integer':
                    validation_lines.append(f"    if ! core_validate_input \"${var_name}\" \"integer\"; then")
                    validation_lines.append(f"        validation_errors=\"${{validation_errors}}Invalid {arg['option']}: ${var_name}\\n\"")
                    validation_lines.append("    fi")
                validation_lines.append("fi")
                validation_lines.append("")
    
    return '\n'.join(validation_lines)

def generate_main_execution(yaml_data):
    """Generate main execution logic following base.sh patterns"""
    execution = []
    
    # Add global variables
    global_vars = generate_global_variables(yaml_data)
    execution.append("# Global variables from YAML")
    for line in global_vars.split('\n'):
        if line.strip():
            execution.append(f"{line}")
    execution.append("")
    
    # Add functions
    functions_code = generate_functions(yaml_data)
    execution.append("# Functions from YAML procedure")
    execution.extend(functions_code.split('\n'))
    execution.append("")
    
    # Add validation code
    validation_code = generate_validation_code(yaml_data)
    execution.append("# Validate procedure arguments")
    execution.extend(validation_code.split('\n'))
    execution.append("")
    
    # Generate execution logic
    execution.append("# Execute main logic")
    execution.append("raw_output=\"\"")
    execution.append("")
    
    # Generate conditional execution for each argument
    for arg in yaml_data['procedure']['arguments']:
        if 'execute_function' in arg:
            option = arg['option']
            
            # Generate variable name using same logic
            if arg.get('type') in ['string', 'integer']:
                var_name = f"INPUT_{option.lstrip('-').split('|')[-1].lstrip('-').upper()}"
                condition = f"[ -n \"${var_name}\" ]"
            else:
                var_name = option.split('|')[-1].lstrip('-').upper()
                condition = f"[ \"${var_name}\" = true ]"
            
            execution.append(f"# Execute functions for {option}")
            execution.append(f"if {condition}; then")
            execution.append(f"    core_debug_print \"Executing functions for {option}\"")
            
            for func_name in arg['execute_function']:
                execution.append(f"    local {func_name}_output")
                execution.append(f"    {func_name}_output=$({func_name}) || {{")
                execution.append(f"        core_debug_print \"Function {func_name} failed\"")
                execution.append(f"        continue")
                execution.append(f"    }}")
                execution.append(f"    if [ -n \"${{{func_name}_output}}\" ]; then")
                execution.append(f"        raw_output=\"${{raw_output}}${{{func_name}_output}}\\n\"")
                execution.append(f"    fi")
            
            execution.append("fi")
            execution.append("")
    
    # Set data source based on procedure name
    procedure_name = yaml_data.get('procedure_name', 'unknown_procedure')
    execution.append(f"# Set data source")
    execution.append(f"data_source=\"{procedure_name}\"")
    
    return '\n'.join(execution)

def build_script(yaml_file, base_script="attackmacos/core/base/base.sh"):
    """Main build function"""
    print(f"Reading YAML: {yaml_file}")
    yaml_data = read_yaml(yaml_file)
    
    print(f"Reading base script: {base_script}")
    with open(base_script, 'r') as f:
        script_content = f.read()
    
    # Generate sections
    flag_vars = generate_flag_variables(yaml_data)
    arg_parser = generate_argument_parser(yaml_data)
    help_text = generate_help_text(yaml_data)
    main_exec = generate_main_execution(yaml_data)
    
    # Replace markers
    script_content = script_content.replace('# PLACEHOLDER_FLAG_VARIABLES', flag_vars)
    script_content = script_content.replace('# PLACEHOLDER_ARGUMENT_PARSER_OPTIONS', arg_parser)
    script_content = script_content.replace('# PLACEHOLDER_HELP_TEXT', help_text)
    script_content = script_content.replace('# PLACEHOLDER_MAIN_EXECUTION', main_exec)
    
    # Update script metadata from YAML
    procedure_name = yaml_data['procedure_name']
    ttp_id = procedure_name.split('_')[0] if '_' in procedure_name else 'T0000'
    
    # Replace metadata placeholders if they exist
    script_content = script_content.replace('TTP_ID="T0000"', f'TTP_ID="{ttp_id}"')
    script_content = script_content.replace('NAME="base"', f'NAME="{procedure_name}"')
    
    # Generate output filename with versioning in current working directory
    base_filename = f"{procedure_name}.sh"
    current_dir = os.getcwd()
    output_file = os.path.join(current_dir, base_filename)
    
    # Check if file exists and add version number
    version = 0.01
    while os.path.exists(output_file):
        name_parts = base_filename.rsplit('.', 1)
        if len(name_parts) > 1:
            base_name, extension = name_parts
            versioned_filename = f"{base_name}_v{version:.2f}.{extension}"
        else:
            versioned_filename = f"{base_filename}_v{version:.2f}"
        output_file = os.path.join(current_dir, versioned_filename)
        version += 0.01
    
    print(f"Current working directory: {current_dir}")
    print(f"Writing output: {output_file}")
    with open(output_file, 'w') as f:
        f.write(script_content)
    
    # Make the script executable
    os.chmod(output_file, 0o755)
    
    print(f"Build complete: {output_file}")
    print(f"Script is executable and ready to use")
    return output_file

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 build_procedure.py <yaml_file>")
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    build_script(yaml_file) 