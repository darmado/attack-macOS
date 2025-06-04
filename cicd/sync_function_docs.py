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


def create_documentation_file(doc_path: str, func_name: str, func_code: str) -> bool:
    """
    Create new documentation file with template.
    
    Returns:
        True if file was created, False otherwise
    """
    try:
        # Generate clean function name for title
        clean_name = func_name.replace('core_', '').replace('_', ' ').title()
        
        template = f"""# {clean_name}

## Purpose

{func_name} function implementation from base.sh.

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
        print(f"  Warning: No recognized code pattern found")
        return False
    
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