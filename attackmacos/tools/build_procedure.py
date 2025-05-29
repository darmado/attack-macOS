#!/usr/bin/env python3
"""
Build Procedure Script for Attack-macOS Framework

Description:
    Generates executable shell scripts from YAML procedure definitions.
    Supports automatic versioning, required option validation, and 
    integration with the base.sh framework.

Author: @darmado | https://x.com/darmad0
Version: 2.0
Date: 2025-05-27

Features:
    - YAML-driven script generation
    - Automatic versioning (never overwrites existing scripts)
    - Required option validation (option_required: true)
    - Function code generation from YAML procedures
    - Global variable injection
    - Argument parser generation
    - Help text generation
    - GUID generation for procedure tracking
    - YAML validation against schema

Usage:
    python3 build_procedure.py <yaml_file>     # Build single YAML file
    python3 build_procedure.py --all           # Build all YAML files in ttp directory
    python3 build_procedure.py --batch <dir>   # Build all YAML files in specified directory
    python3 build_procedure.py --validate <yaml_file>  # Validate YAML only

YAML Structure:
    procedure_name: T1234_technique_name
    tactic: Discovery
    guid: {generate_guid}  # Auto-generated unique identifier
    arguments:
      - option: "--safari"  # Must use --long format
        option_required: true  # Enables validation
        execute_function:
          - function_name
    global_variable:
      - name: VARIABLE_NAME
        type: string
        default_value: "value"
    functions:
      - name: function_name
        code: |
          function_name() {
              # Shell function code
          }
"""

import yaml
import sys
import re
import uuid
from pathlib import Path
import os
import jsonschema
import json

def generate_guid():
    """Generate a UUID4 for procedure tracking"""
    return str(uuid.uuid4())

def validate_yaml_against_schema(yaml_data, yaml_file):
    """Validate YAML data against the procedure schema"""
    # Get the script directory and construct path to schema
    script_dir = Path(__file__).parent
    schema_path = script_dir.parent / "core" / "schemas" / "procedure.schema.json"
    
    if not schema_path.exists():
        print(f"Warning: Schema file not found at {schema_path}")
        return True
    
    try:
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        
        # Validate the YAML data against the schema
        jsonschema.validate(yaml_data, schema)
        print(f"✅ YAML validation passed: {yaml_file}")
        
        # Additional custom validations
        if not validate_function_argument_mapping(yaml_data, yaml_file):
            return False
            
        if not validate_opsec_requirements(yaml_data, yaml_file):
            return False
            
        if not validate_function_output_format(yaml_data, yaml_file):
            return False
        
        return True
        
    except jsonschema.ValidationError as e:
        print(f"❌ YAML validation failed: {yaml_file}")
        print(f"Error: {e.message}")
        if e.absolute_path:
            print(f"Path: {' -> '.join(str(p) for p in e.absolute_path)}")
        return False
    except Exception as e:
        print(f"❌ Schema validation error: {e}")
        return False

def validate_function_argument_mapping(yaml_data, yaml_file):
    """Validate that all main functions have corresponding arguments"""
    # Get all main function names (helper functions don't need argument mapping)
    main_function_names = set()
    helper_function_names = set()
    
    for func in yaml_data['procedure']['functions']:
        func_type = func.get('type', 'main')  # Default to 'main' for backward compatibility
        if func_type == 'main':
            main_function_names.add(func['name'])
        elif func_type == 'helper':
            helper_function_names.add(func['name'])
    
    # Get all functions referenced in arguments
    referenced_functions = set()
    for arg in yaml_data['procedure']['arguments']:
        if 'execute_function' in arg:
            for func_name in arg['execute_function']:
                referenced_functions.add(func_name)
    
    # Check for main functions without arguments
    orphaned_main_functions = main_function_names - referenced_functions
    if orphaned_main_functions:
        print(f"❌ Function-to-argument mapping validation failed: {yaml_file}")
        print(f"Main functions without corresponding arguments: {', '.join(orphaned_main_functions)}")
        print("All main functions must be mapped to at least one argument option")
        print("Set function type to 'helper' if it's called by other functions")
        return False
    
    # Check for referenced functions that don't exist
    all_function_names = main_function_names | helper_function_names
    missing_functions = referenced_functions - all_function_names
    if missing_functions:
        print(f"❌ Function-to-argument mapping validation failed: {yaml_file}")
        print(f"Arguments reference non-existent functions: {', '.join(missing_functions)}")
        return False
    
    helper_count = len(helper_function_names)
    main_count = len(main_function_names)
    print(f"✅ Function-to-argument mapping validation passed: {yaml_file}")
    print(f"   Functions: {main_count} main, {helper_count} helper")
    return True

def validate_opsec_requirements(yaml_data, yaml_file):
    """Validate that all functions have explicit OPSEC requirements"""
    missing_opsec = []
    
    for func in yaml_data['procedure']['functions']:
        func_name = func['name']
        
        # Check if opsec section exists
        if 'opsec' not in func:
            missing_opsec.append(f"{func_name}: missing opsec section")
            continue
            
        opsec = func['opsec']
        
        # Check if check_fda exists and has explicit enabled boolean
        if 'check_fda' not in opsec:
            missing_opsec.append(f"{func_name}: missing opsec.check_fda")
        elif 'enabled' not in opsec['check_fda']:
            missing_opsec.append(f"{func_name}: missing opsec.check_fda.enabled boolean")
        elif not isinstance(opsec['check_fda']['enabled'], bool):
            missing_opsec.append(f"{func_name}: opsec.check_fda.enabled must be boolean (true/false)")
    
    if missing_opsec:
        print(f"❌ OPSEC requirements validation failed: {yaml_file}")
        print("All functions must explicitly define OPSEC requirements:")
        for error in missing_opsec:
            print(f"  - {error}")
        print("\nExample required OPSEC structure:")
        print("  opsec:")
        print("    check_fda:")
        print("      enabled: false  # or true")
        return False
    
    print(f"✅ OPSEC requirements validation passed: {yaml_file}")
    return True

def validate_function_output_format(yaml_data, yaml_file):
    """Validate that functions only output command results, not generic headers"""
    invalid_patterns = []
    
    # Patterns that indicate generic headers or formatting
    forbidden_patterns = [
        r'raw_output\+=".*\[.*\].*"',  # Headers like [EDR Detection Results]
        r'raw_output\+=".*Results.*"',  # Generic "Results" text
        r'raw_output\+=".*Status:.*"',  # Generic "Status:" text
        r'raw_output\+=".*Found.*:"',   # Generic "Found:" text
        r'raw_output\+=".*Detection.*"', # Generic "Detection" text
        r'raw_output\+="No.*detected"', # Generic "No X detected" messages
        r'raw_output\+="Checking.*"',   # Generic "Checking..." messages
    ]
    
    for func in yaml_data['procedure']['functions']:
        func_name = func['name']
        code = func.get('code', '')
        
        for pattern in forbidden_patterns:
            import re
            if re.search(pattern, code):
                invalid_patterns.append(f"{func_name}: contains generic output formatting")
                break
    
    if invalid_patterns:
        print(f"❌ Function output format validation failed: {yaml_file}")
        print("Functions should only output command results, not generic headers:")
        for error in invalid_patterns:
            print(f"  - {error}")
        print("\nFunctions should:")
        print("  - Only output actual command results (ps, ls, defaults, etc.)")
        print("  - Use pipe-delimited format for structured data: 'item|value'")
        print("  - Not include generic headers like '[EDR Detection Results]'")
        print("  - Not include status messages like 'No results found'")
        print("  - Let the framework handle formatting for different output types")
        return False
    
    print(f"✅ Function output format validation passed: {yaml_file}")
    return True

def option_to_variable_name(option):
    """Convert --option-name to OPTION_NAME for shell variables"""
    # Handle short|long format (-s|--safari) by extracting the long option
    if '|' in option:
        # Split on pipe and take the long option (second part)
        parts = option.split('|')
        if len(parts) == 2:
            option = parts[1]  # Use the long option part
    
    return option.lstrip('-').upper().replace('-', '_')

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
            var_name = f"INPUT_{option_to_variable_name(option)}"
            variables.append(f"{var_name}=\"\"")
        else:
            # Boolean variables
            var_name = option_to_variable_name(option)
            variables.append(f"{var_name}=false")
    
    return '\n'.join(variables)

def generate_global_variables(yaml_data):
    """Generate global variable declarations"""
    variables = []
    
    # Load existing variables from variables.yml to avoid duplicates
    existing_vars = load_existing_global_vars()
    
    for var in yaml_data['procedure']['global_variable']:
        name = var['name']
        var_type = var['type']
        default = var['default_value']
        
        # Skip CMD_* variables that already exist in variables.yml
        if name.startswith('CMD_') and name in existing_vars:
            print(f"⚠️  Skipping {name} - already defined in variables.yml")
            continue
        
        # Handle different variable types properly
        if var_type == 'array':
            # For array types, use the array_elements field to generate shell array
            if 'array_elements' in var:
                elements = var['array_elements']
                # Generate shell array declaration with one element per line
                variables.append(f"{name}=(")
                for element in elements:
                    variables.append(f"    \"{element}\"")
                variables.append(")")
            else:
                variables.append(f"{name}=()")
        elif var_type == 'string':
            # For string types, check if it's a multiline string that needs special handling
            if '\n' in default and default.strip().startswith('"'):
                # Multiline string that starts and should end with quotes - use exactly as provided
                variables.append(f"{name}={default}")
            elif '\n' in default:
                # Other multiline string - wrap in quotes
                variables.append(f"{name}=\"{default}\"")
            else:
                # Single-line string - add double quotes for shell safety
                variables.append(f"{name}=\"{default}\"")
        else:
            # Non-string types (integer, boolean, etc.) - use as-is without quotes
            variables.append(f"{name}={default}")
    
    return '\n'.join(variables)

def load_existing_global_vars():
    """Load existing global variables from variables.yml"""
    try:
        import yaml
        import os
        
        # Get script directory and construct path to variables.yml
        script_dir = os.path.dirname(os.path.abspath(__file__))
        vars_file = os.path.join(script_dir, '..', 'core', 'global', 'variables.yml')
        
        if not os.path.exists(vars_file):
            print(f"Warning: variables.yml not found at {vars_file}")
            return set()
            
        with open(vars_file, 'r') as f:
            data = yaml.safe_load(f)
        
        existing_vars = set()
        if 'core_commands' in data:
            existing_vars.update(data['core_commands'].keys())
        
        print(f"✅ Loaded {len(existing_vars)} existing variables from variables.yml")
        return existing_vars
    except Exception as e:
        print(f"Warning: Could not load variables.yml: {e}")
        return set()

def generate_argument_parser(yaml_data):
    """Generate argument parser options matching base.sh pattern"""
    cases = []
    
    for arg in yaml_data['procedure']['arguments']:
        option = arg['option']  # Use the exact string from YAML
        
        if arg.get('type') in ['string', 'integer']:
            # String/integer pattern with missing value handling - match base.sh pattern
            var_name = f"INPUT_{option_to_variable_name(option)}"
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
            var_name = option_to_variable_name(option)
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
    """Generate function definitions from YAML"""
    if 'functions' not in yaml_data['procedure']:
        return ""
    
    functions_code = []
    functions_code.append("# Functions from YAML procedure")
    functions_code.append("")
    
    for func in yaml_data['procedure']['functions']:
        func_name = func['name']
        func_desc = func.get('description', f'{func_name} - Generated from YAML procedure')
        func_code = func['code']
        
        # Check if function code already contains complete function definition
        if f"{func_name}()" in func_code and "{" in func_code:
            # Code already has complete function definition, just add it directly
            functions_code.append(f"# Function: {func_name}")
            functions_code.append(f"# Description: {func_desc}")
            
            # Process and add function code without wrapper
            processed_code = process_function_code(func_code)
            functions_code.append(processed_code)
            functions_code.append("")
        else:
            # Code is just function body, add wrapper
            functions_code.append(f"# Function: {func_name}")
            functions_code.append(f"# Description: {func_desc}")
            functions_code.append(f"{func_name}() {{")
            functions_code.append("")
            
            # Process and add function body with proper indentation
            processed_code = process_function_code(func_code)
            for line in processed_code.split('\n'):
                if line.strip():
                    functions_code.append(f"    {line}")
                else:
                    functions_code.append("")
            
            functions_code.append("}")
            functions_code.append("")
    
    return '\n'.join(functions_code)

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
        'head ': '$CMD_HEAD ',
    }
    
    processed = code
    for old, new in replacements.items():
        processed = processed.replace(old, new)
    
    # Ensure POSIX compatibility - replace [[ ]] with [ ]
    processed = re.sub(r'\[\[\s*([^]]+)\s*\]\]', r'[ \1 ]', processed)
    
    # Replace == with = for POSIX compatibility
    processed = re.sub(r'(\s)==(\s)', r'\1=\2', processed)
    
    # The YAML now has the correct patterns, no need to modify escaping
    
    return processed

def generate_validation_code(yaml_data):
    """Generate validation code for parsed arguments"""
    validation_lines = []
    
    validation_lines.append("# Validate procedure-specific arguments")
    
    # Check for required options first
    required_options = []
    for arg in yaml_data['procedure']['arguments']:
        if arg.get('option_required', False):
            option = arg['option']
            if arg.get('type') in ['string', 'integer']:
                var_name = f"INPUT_{option_to_variable_name(option)}"
                required_options.append((option, var_name, 'value'))
            else:
                var_name = option_to_variable_name(option)
                required_options.append((option, var_name, 'flag'))
    
    if required_options:
        validation_lines.append("")
        validation_lines.append("# Check required options")
        validation_lines.append("missing_required=\"\"")
        
        for option, var_name, option_type in required_options:
            if option_type == 'flag':
                validation_lines.append(f"if [ \"${var_name}\" != true ]; then")
                validation_lines.append(f"    missing_required=\"${{missing_required}} {option}\"")
                validation_lines.append("fi")
            else:
                validation_lines.append(f"if [ -z \"${var_name}\" ]; then")
                validation_lines.append(f"    missing_required=\"${{missing_required}} {option}\"")
                validation_lines.append("fi")
        
        validation_lines.append("")
        validation_lines.append("if [ -n \"$missing_required\" ]; then")
        validation_lines.append("    core_handle_error \"Required options not specified:$missing_required\"")
        validation_lines.append("    exit 1")
        validation_lines.append("fi")
        validation_lines.append("")
    
    # Existing input validation for string/integer types
    for arg in yaml_data['procedure']['arguments']:
        if arg.get('type') in ['string', 'integer']:
            var_name = f"INPUT_{option_to_variable_name(arg['option'])}"
            
            if arg.get('input_required', False):
                # Skip validation for search-related parameters since we handle SQL escaping
                option_name = arg['option'].lower()
                if any(search_term in option_name for search_term in ['search', 'query', 'term', 'filter']):
                    validation_lines.append(f"# Skipping validation for search parameter: {arg['option']}")
                    validation_lines.append("")
                    continue
                
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
    
    # Start main execution logic
    execution.append("# Execute main logic")
    execution.append("raw_output=\"\"")
    execution.append("")
    
    # Generate execution logic for each argument
    for arg in yaml_data['procedure']['arguments']:
        option = arg['option']
        var_name = option_to_variable_name(option)
        
        # Check if this argument has functions to execute
        if 'execute_function' in arg:
            # Add execution block for this argument
            execution.append(f"# Execute functions for {option}")
            execution.append(f"if [ \"${var_name}\" = true ]; then")
            execution.append(f"    core_debug_print \"Executing functions for {option}\"")
            
            # Call each mapped function
            for func_name in arg['execute_function']:
                execution.append(f"    result=$({func_name})")
                execution.append(f"    raw_output=\"${{raw_output}}${{result}}\\n\"")
            
            execution.append("fi")
            execution.append("")
    
    # Set data source
    procedure_name = yaml_data['procedure_name']
    execution.append(f"# Set data source")
    execution.append(f"data_source=\"{procedure_name}\"")
    
    return '\n'.join(execution)

def find_next_version(output_dir, base_filename):
    """Find the next available version number for a script"""
    base_name = base_filename.replace('.sh', '')
    version = 1
    
    while True:
        versioned_filename = f"{base_name}_v{version}.sh"
        versioned_path = output_dir / versioned_filename
        if not versioned_path.exists():
            return versioned_filename, version
        version += 1

def build_script(yaml_file, base_script=None):
    """Main build function"""
    print(f"Reading YAML: {yaml_file}")
    yaml_data = read_yaml(yaml_file)
    
    # Validate YAML against schema by default
    print(f"Validating YAML against schema...")
    if not validate_yaml_against_schema(yaml_data, yaml_file):
        print(f"❌ Build failed: YAML validation errors must be fixed first")
        return None
    
    # Determine the correct base script path
    if base_script is None:
        # Get the script directory and construct path to base.sh
        script_dir = Path(__file__).parent
        # Go up to attackmacos/ then to core/base/base.sh
        base_script = script_dir.parent / "core" / "base" / "base.sh"
    
    print(f"Reading base script: {base_script}")
    with open(base_script, 'r') as f:
        script_content = f.read()
    
    # Generate sections
    flag_vars = generate_flag_variables(yaml_data)
    global_vars = generate_global_variables(yaml_data)
    functions_code = generate_functions(yaml_data)
    arg_parser = generate_argument_parser(yaml_data)
    help_text = generate_help_text(yaml_data)
    main_exec = generate_main_execution(yaml_data)
    opsec_replacements = generate_opsec_settings(yaml_data)
    
    # Replace markers
    script_content = script_content.replace('# PLACEHOLDER_FLAG_VARIABLES', flag_vars)
    script_content = script_content.replace('# PLACEHOLDER_GLOBAL_VARIABLES', global_vars)
    script_content = script_content.replace('# PLACEHOLDER_FUNCTIONS', functions_code)
    script_content = script_content.replace('# PLACEHOLDER_ARGUMENT_PARSER_OPTIONS', arg_parser)
    script_content = script_content.replace('# PLACEHOLDER_HELP_TEXT', help_text)
    script_content = script_content.replace('# PLACEHOLDER_MAIN_EXECUTION', main_exec)
    
    # Apply OPSEC settings replacements
    for old_value, new_value in opsec_replacements.items():
        script_content = script_content.replace(old_value, new_value)
        print(f"🔒 OPSEC: {old_value} → {new_value}")
    
    # Update script metadata from YAML
    procedure_name = yaml_data['procedure_name']
    ttp_id = procedure_name.split('_')[0] if '_' in procedure_name else 'T0000'
    tactic = yaml_data.get('tactic', 'Unknown').lower()
    
    # Replace metadata placeholders if they exist
    script_content = script_content.replace('TTP_ID="T0000"', f'TTP_ID="{ttp_id}"')
    script_content = script_content.replace('NAME="base"', f'NAME="{procedure_name}"')
    
    # Update script header with YAML information
    yaml_tactic = yaml_data.get('tactic', 'Unknown')
    yaml_author = yaml_data.get('author', '@darmado | https://x.com/darmad0')
    yaml_version = yaml_data.get('version', '1.0')
    yaml_created = yaml_data.get('created', '2025-05-27')
    yaml_intent = yaml_data.get('intent', 'ATT&CK technique implementation')
    yaml_guid = yaml_data.get('guid', 'No GUID specified')
    
    # Replace script header information
    script_content = script_content.replace('# Script Name: base.sh', f'# Script Name: {procedure_name}.sh')
    script_content = script_content.replace('# MITRE ATT&CK Technique: [TECHNIQUE_ID]', f'# MITRE ATT&CK Technique: {ttp_id}')
    script_content = script_content.replace('# Author: @darmado | https://x.com/darmad0', f'# Author: {yaml_author}')
    script_content = script_content.replace('# Date: $(date \'+%Y-%m-%d\')', f'# Date: {yaml_created}')
    script_content = script_content.replace('# Version: 1.0', f'# Version: {yaml_version}')
    
    # Replace description section
    description_replacement = f"""# Description:
# {yaml_intent}
# MITRE ATT&CK Tactic: {yaml_tactic}
# Procedure GUID: {yaml_guid}
# Generated from YAML procedure definition using build_procedure.py
# The script uses native macOS commands and APIs for maximum compatibility."""
    
    script_content = script_content.replace(
        '# Description:\n# This is a standalone base script template that can be used to build any technique.\n# Replace this description with the actual technique description.\n# The script uses native macOS commands and APIs for maximum compatibility.',
        description_replacement
    )
    
    # Determine output path - place script in same directory as YAML file
    # Convert to absolute path to avoid relative path issues
    yaml_path = Path(yaml_file).resolve()
    output_dir = yaml_path.parent
    
    # Generate script filename by removing 'T' prefix from procedure name
    if procedure_name.startswith('T'):
        script_name = procedure_name[1:]  # Remove the 'T' prefix
    else:
        script_name = procedure_name
    
    base_filename = f"{script_name}.sh"
    
    print(f"YAML Directory: {output_dir}")
    print(f"Resolved YAML path: {yaml_path}")
    print(f"Output directory: {output_dir}")
    
    # Check if base filename exists and find next version if needed
    base_output_file = output_dir / base_filename
    if base_output_file.exists():
        # Find next available version
        versioned_filename, version_num = find_next_version(output_dir, base_filename)
        output_file = output_dir / versioned_filename
        print(f"📝 Base script exists, creating version {version_num}: {output_file}")
        
        # Show existing file info
        import time
        existing_mtime = base_output_file.stat().st_mtime
        existing_time = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(existing_mtime))
        print(f"   Existing file: {base_output_file}")
        print(f"   Existing timestamp: {existing_time}")
    else:
        output_file = base_output_file
        print(f"✅ Creating new script: {output_file}")
    
    print(f"Writing output: {output_file}")
    
    with open(output_file, 'w') as f:
        f.write(script_content)
    
    # Make the script executable
    output_file.chmod(0o755)
    
    # Show new timestamp
    import time
    new_mtime = output_file.stat().st_mtime
    new_time = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(new_mtime))
    print(f"✅ Build complete: {output_file}")
    print(f"   New timestamp: {new_time}")
    print(f"   Script is executable and ready to use")
    print(f"\nScript created at: {output_file}")
    
    return str(output_file)

def find_yaml_files(directory):
    """Find all YAML files (.yml and .yaml) in directory tree"""
    yaml_files = []
    directory = Path(directory)
    
    # Search for both .yml and .yaml files
    for pattern in ['**/*.yml', '**/*.yaml']:
        yaml_files.extend(directory.glob(pattern))
    
    return sorted(yaml_files)

def build_all_procedures(ttp_directory=None):
    """Build all YAML procedures found in the ttp directory tree"""
    if ttp_directory is None:
        # Default to ttp directory relative to this script
        script_dir = Path(__file__).parent
        ttp_directory = script_dir.parent / "ttp"
    
    ttp_directory = Path(ttp_directory)
    
    if not ttp_directory.exists():
        print(f"Error: TTP directory not found: {ttp_directory}")
        return []
    
    print(f"Searching for YAML files in: {ttp_directory}")
    yaml_files = find_yaml_files(ttp_directory)
    
    if not yaml_files:
        print("No YAML files found in ttp directory tree")
        return []
    
    print(f"Found {len(yaml_files)} YAML files:")
    for yaml_file in yaml_files:
        print(f"  - {yaml_file}")
    
    built_scripts = []
    failed_builds = []
    
    for yaml_file in yaml_files:
        try:
            print(f"\n{'='*60}")
            print(f"Building: {yaml_file}")
            print(f"{'='*60}")
            
            output_script = build_script(str(yaml_file))
            built_scripts.append(output_script)
            print(f"✅ Success: {output_script}")
            
        except Exception as e:
            print(f"❌ Failed to build {yaml_file}: {e}")
            failed_builds.append((str(yaml_file), str(e)))
    
    print(f"\n{'='*60}")
    print(f"BATCH BUILD SUMMARY")
    print(f"{'='*60}")
    print(f"Successfully built: {len(built_scripts)} scripts")
    print(f"Failed builds: {len(failed_builds)}")
    
    if failed_builds:
        print(f"\nFailed builds:")
        for yaml_file, error in failed_builds:
            print(f"  ❌ {yaml_file}: {error}")
    
    if built_scripts:
        print(f"\nSuccessfully built scripts:")
        for script in built_scripts:
            print(f"  ✅ {script}")
    
    return built_scripts

def generate_opsec_settings(yaml_data):
    """Generate OPSEC check settings from YAML function configurations"""
    opsec_replacements = {}
    
    # Check all functions for OPSEC requirements
    if 'functions' not in yaml_data['procedure']:
        return opsec_replacements
    
    check_fda_needed = False
    check_perms_needed = False
    check_db_lock_needed = False
    
    for func in yaml_data['procedure']['functions']:
        if 'opsec' not in func:
            continue
            
        opsec = func['opsec']
        
        # Check for FDA requirements
        if 'check_fda' in opsec and opsec['check_fda'].get('enabled', False):
            check_fda_needed = True
            
        # Check for permission requirements  
        if 'check_permission' in opsec:
            check_perms_needed = True
            
        # Check for database lock requirements
        if 'check_db_lock' in opsec and opsec['check_db_lock'].get('enabled', False):
            check_db_lock_needed = True
    
    # Generate replacements for the variables that need to be enabled
    if check_fda_needed:
        opsec_replacements['CHECK_FDA="false"'] = 'CHECK_FDA="true"'
        
    if check_perms_needed:
        opsec_replacements['CHECK_PERMS="false"'] = 'CHECK_PERMS="true"'
        
    if check_db_lock_needed:
        opsec_replacements['CHECK_DB_LOCK="false"'] = 'CHECK_DB_LOCK="true"'
    
    return opsec_replacements

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Usage:")
        print("  python3 build_procedure.py <yaml_file>     # Build single YAML file")
        print("  python3 build_procedure.py --all           # Build all YAML files in ttp directory")
        print("  python3 build_procedure.py --batch <dir>   # Build all YAML files in specified directory")
        print("  python3 build_procedure.py --validate <yaml_file>  # Validate YAML only")
        print("")
        print("Note: Scripts are automatically versioned (e.g., script_v2.sh) if base name exists")
        sys.exit(1)
    
    if sys.argv[1] == "--all":
        build_all_procedures()
    elif sys.argv[1] == "--batch" and len(sys.argv) == 3:
        build_all_procedures(sys.argv[2])
    elif sys.argv[1] == "--validate" and len(sys.argv) == 3:
        yaml_file = sys.argv[2]
        print(f"Validating YAML: {yaml_file}")
        yaml_data = read_yaml(yaml_file)
        if validate_yaml_against_schema(yaml_data, yaml_file):
            print(f"✅ YAML validation passed: {yaml_file}")
        else:
            print(f"❌ YAML validation failed: {yaml_file}")
    else:
        yaml_file = sys.argv[1]
        build_script(yaml_file) 