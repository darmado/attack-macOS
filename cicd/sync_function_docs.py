#!/usr/bin/env python3
"""
Sync base.sh functions to their corresponding documentation files.

This script reads functions from base.sh and updates the corresponding
documentation files in docs/R&D Library/Functions/Shell/ directory.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional


def extract_functions_from_base_sh(base_sh_path: str) -> Dict[str, str]:
    """
    Extract all core_ functions from base.sh file.
    
    Returns:
        Dict mapping function name to full function code
    """
    functions = {}
    
    try:
        with open(base_sh_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: base.sh not found at {base_sh_path}")
        return functions
    
    # Pattern to match function definitions with their complete code
    # Matches from function name to the closing brace
    pattern = r'^(core_\w+)\(\)\s*\{(.*?)^}'
    
    matches = re.finditer(pattern, content, re.MULTILINE | re.DOTALL)
    
    for match in matches:
        func_name = match.group(1)
        func_body = match.group(2).strip()
        
        # Reconstruct the complete function
        complete_function = f"{func_name}() {{\n{func_body}\n}}"
        functions[func_name] = complete_function
        
    return functions


def function_name_to_doc_name(func_name: str) -> str:
    """
    Convert function name to corresponding documentation file name.
    
    Examples:
        core_generate_job_id -> Generate Job Id.md
        core_log_output -> Log Output.md
        core_validate_input -> Input Validation.md
    """
    # Remove core_ prefix
    name = func_name.replace('core_', '')
    
    # Special mappings for functions that don't follow standard pattern
    special_mappings = {
        'validate_input': 'Input Validation',
        'log_output': 'Log Output',  
        'generate_job_id': 'Generate Job Id',
        'get_timestamp': 'Get Timestamp',
        'debug_print': 'Debugger',
        'handle_error': 'Error Handler',
        'parse_args': 'Parse Args',
        'validate_command': 'Validate Command',
        'validate_domain': 'Validate Domain',
        'extract_domain_from_url': 'Extract Domain From Url',
        'format_output': 'Format Output',
        'process_output': 'Process Output',
        'encode_output': 'Encode Output',
        'encrypt_output': 'Encrypt Output',
        'exfiltrate_data': 'Exfiltrate Data',
        'transform_output': 'Transform Output',
        'url_safe_encode': 'Url Safe Encode',
        'dns_safe_encode': 'Dns Safe Encode',
        'get_user_agent': 'Get User Agent',
        'prepare_proxy_arg': 'Prepare Proxy Arg',
        'display_help': 'Display Help',
        'check_perms': 'Check Perms',
        'check_fda': 'Check Fda',
        'check_db_lock': 'Check Db Lock',
        'main': 'Main'
    }
    
    if name in special_mappings:
        return f"{special_mappings[name]}.md"
    
    # Default: convert snake_case to Title Case
    words = name.split('_')
    title_case = ' '.join(word.capitalize() for word in words)
    return f"{title_case}.md"


def generate_intelligent_purpose(func_name: str, func_code: str) -> str:
    """
    Analyze function code to generate intelligent purpose descriptions.
    
    Returns:
        Meaningful purpose description based on code analysis
    """
    code_lower = func_code.lower()
    name_lower = func_name.lower()
    
    # Validation functions - analyze validation patterns
    if 'validate' in name_lower:
        methods = []
        if 'dig' in code_lower: methods.append('DNS resolution with dig')
        if 'host' in code_lower: methods.append('host command lookup') 
        if 'nslookup' in code_lower: methods.append('nslookup query')
        if 'grep' in code_lower and 'ip' in code_lower: methods.append('IP address detection')
        if 'empty' in code_lower or '[ -z' in func_code: methods.append('empty input validation')
        
        if methods:
            if len(methods) > 2:
                return f"Validates domain resolution using {len(methods)}-tier fallback: " + \
                       ", ".join(f"{i+1}) {method}" for i, method in enumerate(methods[:3])) + \
                       ". Skips empty domains and IP addresses, returns error if domain doesn't resolve."
            else:
                return f"Validates domains using {' and '.join(methods)}. Handles empty inputs and IP addresses."
        else:
            return f"Validates input data with error handling and type checking."
    
    # Format/transformation functions
    if any(word in name_lower for word in ['format', 'encode', 'encrypt', 'transform']):
        if 'json' in code_lower:
            return "Converts output to structured JSON format with metadata including timestamp, job ID, encoding/encryption status, and data array."
        elif 'csv' in code_lower:
            return "Converts pipe-delimited output to comma-separated values (CSV) format by replacing delimiters."
        elif 'base64' in code_lower:
            return "Performs Base64 encoding of input data using system base64 command for data obfuscation."
        elif 'hex' in code_lower or 'xxd' in code_lower:
            return "Converts data to hexadecimal encoding using xxd command for binary data representation."
        elif 'aes' in code_lower or 'openssl' in code_lower:
            return "Applies AES-256-CBC encryption using OpenSSL with secure key derivation for data protection."
        elif 'gpg' in code_lower:
            return "Uses GPG symmetric encryption with AES-256 cipher for secure data protection."
        elif 'dns' in name_lower and 'safe' in name_lower:
            return "Performs two-step encoding for DNS compatibility: 1) Base64 encodes the input data, 2) Makes it DNS-safe by replacing '+' with '-', '/' with '_', and removing '=' padding characters to ensure valid DNS label format."
        elif 'url' in name_lower and 'safe' in name_lower:
            return "Performs two-step encoding: 1) Base64 encodes the input data, 2) Makes it URL-safe by replacing '+' with '-', '/' with '_', and removing '=' padding characters using `tr` command."
        else:
            return "Transforms data format using specified encoding or encryption methods with error handling."
    
    # Network/exfiltration functions
    if any(word in name_lower for word in ['exfil', 'dns', 'http', 'curl']):
        if 'dns' in name_lower:
            return "Exfiltrates data via DNS queries using dig command with automatic chunking, rate limiting, and DNS-safe encoding. Sends start/end signals and encryption keys via TXT records."
        elif 'http' in name_lower:
            if 'post' in name_lower:
                return "Exfiltrates data via HTTP POST requests using curl with JSON payload, proxy support, and encryption key handling via DNS TXT records."
            elif 'get' in name_lower:
                return "Exfiltrates data via HTTP GET requests using URL parameters with automatic chunking, rate limiting, and proxy support to avoid URL length limits."
            else:
                return "Routes data to appropriate exfiltration method (HTTP POST/GET or DNS) based on configuration, with URI validation and error handling."
        else:
            return "Handles secure data exfiltration with multiple transport methods and encryption support."
    
    # Database/file functions
    if any(word in name_lower for word in ['db', 'database', 'lock', 'file']):
        if 'lock' in name_lower:
            return "Performs 3-method database lock detection: 1) Checks for SQLite lock files (-wal, -shm, -journal), 2) Uses `lsof` to detect processes with file open, 3) Attempts brief database query with timeout. Returns 1 if locked, 0 if available."
        elif 'check' in name_lower:
            return "Tests file existence and validates read, write, and execute permissions based on specified requirements. Returns 0 if all required permissions are granted, 1 if any are missing."
        else:
            return "Manages database or file operations with lock detection and permission validation."
    
    # Security/permission functions  
    if any(word in name_lower for word in ['perms', 'permission', 'fda', 'tcc']):
        if 'fda' in name_lower:
            return "Checks if both system and user TCC databases exist and are readable for Full Disk Access validation."
        elif 'perms' in name_lower:
            return "Tests file existence and validates read, write, and execute permissions based on specified requirements. Returns 0 if all required permissions are granted, 1 if any are missing."
        else:
            return "Validates system permissions and security access requirements."
    
    # Logging functions
    if any(word in name_lower for word in ['log', 'debug', 'verbose']):
        if 'debug' in name_lower:
            return "Outputs debug messages to stderr with timestamp when DEBUG flag is enabled for troubleshooting and development."
        elif 'log' in name_lower:
            return "Creates log directory if needed, rotates log files when they exceed size limits, writes structured log entries with metadata (timestamp, PID, job ID, TTP info), and sends entries to both file and syslog. Also outputs to stdout in debug mode."
        else:
            return "Manages logging and debug output with file rotation and structured metadata."
    
    # Utility functions
    if any(word in name_lower for word in ['generate', 'get', 'extract', 'parse']):
        if 'job' in name_lower and 'id' in name_lower:
            return "Creates a unique 8-character hexadecimal identifier for tracking script execution across logging, exfiltration, and debugging operations."
        elif 'timestamp' in name_lower:
            return "Executes the `date` command with format \"+%Y-%m-%d %H:%M:%S\" to return a standardized timestamp string for consistent logging and output formatting across all framework functions."
        elif 'domain' in name_lower:
            return "Uses `sed` with extended regex to parse a URL string and extract only the domain portion by removing protocol (http/https), path, and port information. Returns the clean domain name for validation purposes."
        elif 'parse' in name_lower and 'args' in name_lower:
            return "Processes command-line arguments using a `while` loop and `case` statement to set global flag variables. Handles argument values, tracks unknown arguments and missing values, but performs no validation. Reports warnings for unknown/missing arguments but continues execution."
        elif 'key' in name_lower:
            return "Checks if encryption is enabled (not \"none\"), then generates a SHA-256 hash from concatenated job ID, timestamp, and random number. Sets the global `ENCRYPT_KEY` variable and optionally prints key in debug mode."
        else:
            return "Utility function for data extraction, parsing, or generation with error handling."
    
    # Processing/orchestration functions
    if any(word in name_lower for word in ['process', 'execute', 'main', 'transform']):
        if 'main' in name_lower:
            return "Orchestrates complete script execution flow: 1) Parse arguments, 2) Display help if requested, 3) Validate arguments, 4) Generate encryption key, 5) Validate commands, 6) Run permission/TCC checks, 7) Initialize logging, 8) Execute technique logic or ls/steganography, 9) Process output, 10) Transform final output."
        elif 'process' in name_lower and 'output' in name_lower:
            return "Orchestrates a 5-step transformation pipeline: 1) Format output (JSON/CSV), 2) Apply encoding (base64/hex), 3) Apply encryption (AES/GPG/XOR), 4) Apply steganography if requested, 5) Handle JSON metadata for transformations. Returns the fully processed output string."
        elif 'transform' in name_lower and 'output' in name_lower:
            return "Manages final output delivery through logging, exfiltration, and display. Always prints output to stdout, conditionally logs to file if enabled, conditionally exfiltrates if enabled, and prints encryption key in debug mode."
        else:
            return "Processes and orchestrates data flow with multiple transformation stages and error handling."
    
    # Steganography functions
    if 'steg' in name_lower:
        if 'extract' in name_lower:
            return "Extracts hidden data from steganography images by searching for STEG_DATA_START/END markers, decoding Base64 content, and returning the original hidden message."
        elif 'apply' in name_lower:
            return "Hides data in image files using native macOS tools by appending Base64-encoded data with special markers to the end of image files. Image viewers ignore the appended data while preserving file functionality."
        else:
            return "Manages steganographic data hiding and extraction using native image manipulation techniques."
    
    # Command execution functions
    if 'exec' in name_lower or 'cmd' in name_lower:
        if 'obfuscated' in name_lower:
            return "Executes security commands with Base64 obfuscation by decoding command fragments and dynamically constructing keychain operations to evade static analysis."
        elif 'construct' in name_lower:
            return "Dynamically constructs and executes shell commands by concatenating provided fragments, useful for bypassing static analysis detection."
        elif 'herestring' in name_lower:
            return "Executes commands by feeding them as input to a shell process using here-string syntax (<<<) for indirect command execution."
        else:
            return "Executes shell commands with various obfuscation and indirection techniques."
    
    # Default fallback - try to extract from comments or give generic description
    if '# Purpose:' in func_code:
        purpose_match = re.search(r'# Purpose:?\s*(.+?)(?:\n|$)', func_code, re.IGNORECASE)
        if purpose_match:
            return purpose_match.group(1).strip()
    
    # Final fallback based on function name
    clean_name = func_name.replace('core_', '').replace('_', ' ')
    return f"Implements {clean_name} functionality with error handling and validation."


def extract_dependencies_from_function(func_code: str) -> str:
    """
    Extract dependencies from function code and return formatted dependency table.
    
    Returns:
        Formatted dependency table as string
    """
    dependencies = []
    
    # Pattern to find global variable references (${VAR} or $VAR)
    var_pattern = r'\$\{?([A-Z_][A-Z0-9_]*)\}?'
    variables = set(re.findall(var_pattern, func_code))
    
    # Common global variables to document
    common_globals = {
        'CMD_PRINTF': '"printf"',
        'CMD_BASE64': '"base64"', 
        'CMD_GREP': '"grep"',
        'CMD_SED': '"sed"',
        'CMD_CUT': '"cut"',
        'CMD_SORT': '"sort"',
        'CMD_WC': '"wc"',
        'CMD_TAIL': '"tail"',
        'CMD_HEAD': '"head"',
        'CMD_TR': '"tr"',
        'CMD_OPENSSL': '"openssl"',
        'CMD_SQLITE3': '"sqlite3"',
        'CMD_LSOF': '"lsof"',
        'CMD_DIG': '"dig"',
        'CMD_CURL': '"curl"',
        'CMD_LOGGER': '"logger"',
        'CMD_HOSTNAME': '"hostname"',
        'CMD_MKDIR': '"mkdir"',
        'CMD_MV': '"mv"',
        'CMD_STAT': '"stat"',
        'CMD_CP': '"cp"',
        'CMD_CAT': '"cat"',
        'CMD_STRINGS': '"strings"',
        'CMD_XXD': '"xxd"',
        'CMD_PERL': '"perl"',
        'CMD_SLEEP': '"sleep"',
        'CMD_HOST': '"host"',
        'CMD_NSLOOKUP': '"nslookup"',
        'DEBUG': 'false',
        'VERBOSE': 'false',
        'LOG_ENABLED': 'false',
        'JOB_ID': '""',
        'TTP_ID': '""',
        'TACTIC': '""',
        'FORMAT': '"raw"',
        'ENCODE': '"none"',
        'ENCRYPT': '"none"',
        'EXFIL_METHOD': '"none"',
        'EXFIL_TYPE': '"none"',
        'EXFIL_URI': '""',
        'CHUNK_SIZE': '50',
        'PROXY_URL': '""',
        'LOG_DIR': '"./logs"',
        'LOG_MAX_SIZE': '5242880',
        'ENCODING_TYPE': '"none"',
        'ENCRYPTION_TYPE': '"none"',
        'ENCRYPT_KEY': '""',
        'PROCEDURE_NAME': '""',
        'OWNER': '"$USER"',
        'PARENT_PROCESS': '""',
        'SCRIPT_CMD': '""',
        'SYSLOG_TAG': '"${NAME}"',
        'SHOW_HELP': 'false',
        'LIST_FILES': 'false',
        'STEG_EXTRACT': 'false',
        'STEG_EXTRACT_FILE': '""',
        'STEG_TRANSFORM': 'false',
        'STEG_CARRIER_IMAGE': '""',
        'STEG_OUTPUT_IMAGE': '""',
        'LOG_FILE_NAME': '"${TTP_ID}_${NAME}.log"',
        'TCC_SYSTEM_DB': '"/Library/Application Support/com.apple.TCC/TCC.db"',
        'TCC_USER_DB': '"$HOME/Library/Application Support/com.apple.TCC/TCC.db"'
    }
    
    # Add global variables found in code
    for var in sorted(variables):
        if var in common_globals:
            dependencies.append(('Global Variable', f'`{var}`', common_globals[var]))
    
    # Pattern to find function calls (core_function_name)
    func_pattern = r'(core_[a-z_]+)\s*(?:\(|\s)'
    functions = set(re.findall(func_pattern, func_code))
    
    # Add function dependencies
    for func in sorted(functions):
        if func != 'core_':  # Avoid partial matches
            dependencies.append(('Function', f'`{func}()`', f'For {func.replace("core_", "").replace("_", " ")}'))
    
    # Pattern to find builtin commands (command -v, [ ], etc.)
    if 'command -v' in func_code:
        dependencies.append(('Builtin', '`command`', 'For checking command availability'))
    
    # Pattern to find external commands not in CMD_ variables
    external_commands = set()
    if 'date ' in func_code or 'date"' in func_code:
        external_commands.add('date')
    if 'timeout ' in func_code:
        external_commands.add('timeout')
    if ' tr ' in func_code and 'CMD_TR' not in func_code:
        external_commands.add('tr')
    if ' cut ' in func_code and 'CMD_CUT' not in func_code:
        external_commands.add('cut')
    
    # Add external commands
    for cmd in sorted(external_commands):
        dependencies.append(('Command', f'`{cmd}`', f'For {cmd} operations'))
    
    if not dependencies:
        return ""
    
    # Generate dependency table
    table = "### Dependencies\n"
    table += "| Type | Name | Value |\n"
    table += "|------|------|-------|\n"
    
    for dep_type, name, value in dependencies:
        table += f"| {dep_type} | {name} | {value} |\n"
    
    return table + "\n"


def create_documentation_file(doc_path: str, func_name: str, func_code: str) -> bool:
    """
    Create new documentation file with template.
    
    Returns:
        True if file was created, False otherwise
    """
    try:
        # Generate clean function name for title
        clean_name = func_name.replace('core_', '').replace('_', ' ').title()
        
        # Extract purpose from function comments if available
        purpose_pattern = r'# Purpose:?\s*(.+?)(?:\n|$)'
        purpose_match = re.search(purpose_pattern, func_code, re.IGNORECASE)
        
        if purpose_match:
            purpose = purpose_match.group(1).strip()
        else:
            # Generate default purpose
            purpose = generate_intelligent_purpose(func_name, func_code)
        
        # Generate dependency table
        dependencies = extract_dependencies_from_function(func_code)
        
        # Create template with or without dependency table
        if dependencies:
            template = f"""# {clean_name}

### Purpose
{purpose}

{dependencies}<details>

```shell
{func_code}
```

</details> 
"""
        else:
            template = f"""# {clean_name}

## Purpose

{purpose}

## Implementation

<details>
<summary>Function Code</summary>

```bash
{func_code}
```

</details>

## Usage

Document usage examples and parameters here.

## Notes

Add any implementation notes or considerations.
"""
        
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(template)
        print(f"  Created: {doc_path}")
        return True
        
    except Exception as e:
        print(f"  Error creating {doc_path}: {e}")
        return False


def update_documentation_file(doc_path: str, func_name: str, func_code: str) -> bool:
    """
    Update the documentation file with the new function code.
    
    Returns:
        True if file was updated, False otherwise
    """
    if not os.path.exists(doc_path):
        print(f"Warning: Documentation file not found: {doc_path}")
        return False
    
    try:
        with open(doc_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {doc_path}: {e}")
        return False
    
    # Check if file is empty or has no content
    if not content.strip():
        print(f"  File is empty, creating template")
        return create_documentation_file(doc_path, func_name, func_code)
    
    # Try multiple patterns for different documentation formats
    patterns = [
        # Pattern 1: ## Implementation with code block
        r'(## Implementation\s*```bash\s*)(.*?)(```)',
        # Pattern 2: Details tag with shell code block  
        r'(<details>\s*)(```shell\s*)(.*?)(```\s*</details>)',
        # Pattern 3: Details tag with bash code block
        r'(<details>\s*)(```bash\s*)(.*?)(```\s*</details>)'
    ]
    
    updated = False
    new_content = content
    
    # First, try to update dependency table if it exists
    dependency_pattern = r'(### Dependencies\n\|[^\n]+\n\|[^\n]+\n(?:\|[^\n]+\n)*)'
    dependencies = extract_dependencies_from_function(func_code)
    
    if dependencies:
        if re.search(dependency_pattern, content):
            # Update existing dependency table
            new_content = re.sub(dependency_pattern, dependencies.rstrip() + '\n', new_content)
            print(f"  Updated dependency table")
        else:
            # Add dependency table after Purpose section
            purpose_pattern = r'(### Purpose\n.*?\n)(\n)'
            if re.search(purpose_pattern, new_content, re.DOTALL):
                new_content = re.sub(purpose_pattern, f'\\1\n{dependencies}\\2', new_content, flags=re.DOTALL)
                print(f"  Added dependency table")
    
    # Try to update purpose section if it's generic
    purpose_pattern = r'(### Purpose\n)(.*?)(\n\n)'
    purpose_match = re.search(purpose_pattern, new_content, re.DOTALL)
    if purpose_match:
        current_purpose = purpose_match.group(2).strip()
        # Check if purpose is generic or needs updating
        if ('function implementation from base.sh' in current_purpose or 
            'Document usage examples' in current_purpose or
            'implementation from base.sh' in current_purpose or
            'function implementation' in current_purpose or
            len(current_purpose) < 100):  # Increased threshold
            
            intelligent_purpose = generate_intelligent_purpose(func_name, func_code)
            new_content = re.sub(purpose_pattern, f'\\1{intelligent_purpose}\\3', new_content, flags=re.DOTALL)
            print(f"  Updated purpose with intelligent analysis")
    
    for i, pattern in enumerate(patterns):
        match = re.search(pattern, content, re.DOTALL)
        if match:
            print(f"  Found pattern {i+1}: {'Implementation' if i == 0 else 'Details tag'}")
            
            if i == 0:  # ## Implementation pattern
                # Extract the function comment if it exists
                comment_pattern = r'^# Purpose:.*?^# .*?'
                comment_match = re.search(comment_pattern, func_code, re.MULTILINE | re.DOTALL)
                
                if comment_match:
                    new_code = func_code
                else:
                    new_code = f"# Purpose: {func_name} function implementation\n{func_code}"
                
                new_content = re.sub(
                    pattern,
                    f"\\g<1>{new_code}\n\\g<3>",
                    content,
                    flags=re.DOTALL
                )
            else:  # Details patterns
                # For details tags, just replace the function code without extra comments
                new_content = re.sub(
                    pattern,
                    f"\\g<1>\\g<2>{func_code}\n\\g<4>",
                    content,
                    flags=re.DOTALL
                )
            
            updated = True
            break
    
    if not updated:
        print(f"  No recognized pattern found, creating template")
        return create_documentation_file(doc_path, func_name, func_code)
    
    # Only write if content actually changed
    if new_content != content:
        try:
            with open(doc_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"  Updated: {doc_path}")
            return True
        except Exception as e:
            print(f"  Error writing {doc_path}: {e}")
            return False
    else:
        print(f"  No changes needed: {doc_path}")
        return False


def main():
    """Main function to sync all functions."""
    # Get script directory and project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Define paths
    base_sh_path = project_root / "attackmacos" / "core" / "base" / "base.sh"
    docs_dir = project_root / "docs" / "Functions" / "Shell"
    
    print(f"Base.sh path: {base_sh_path}")
    print(f"Docs directory: {docs_dir}")
    
    # Check if paths exist
    if not base_sh_path.exists():
        print(f"Error: base.sh not found at {base_sh_path}")
        sys.exit(1)
    
    if not docs_dir.exists():
        print(f"Error: Documentation directory not found at {docs_dir}")
        sys.exit(1)
    
    # Extract functions from base.sh
    print("Extracting functions from base.sh...")
    functions = extract_functions_from_base_sh(str(base_sh_path))
    
    if not functions:
        print("No functions found in base.sh")
        sys.exit(1)
    
    print(f"Found {len(functions)} functions:")
    for func_name in sorted(functions.keys()):
        print(f"  - {func_name}")
    
    # Sync documentation files
    print("\nSyncing documentation files...")
    updated_count = 0
    created_count = 0
    no_change_count = 0
    
    for func_name, func_code in functions.items():
        doc_filename = function_name_to_doc_name(func_name)
        doc_path = docs_dir / doc_filename
        
        print(f"\nProcessing {func_name} -> {doc_filename}")
        
        if doc_path.exists():
            # Update existing file
            if update_documentation_file(str(doc_path), func_name, func_code):
                updated_count += 1
            else:
                no_change_count += 1
        else:
            # Create missing file
            if create_documentation_file(str(doc_path), func_name, func_code):
                created_count += 1
    
    # Summary
    print(f"\n" + "="*50)
    print(f"Sync Summary:")
    print(f"  Total functions: {len(functions)}")
    print(f"  Files created: {created_count}")
    print(f"  Files updated: {updated_count}")
    print(f"  No changes needed: {no_change_count}")
    print(f"  Total documentation files: {created_count + updated_count + no_change_count}")
    
    if created_count + updated_count + no_change_count == len(functions):
        print(f"\n✅ SYNC COMPLETE: All {len(functions)} functions have documentation")
    else:
        print(f"\n❌ SYNC INCOMPLETE: Missing documentation for some functions")


if __name__ == "__main__":
    main() 