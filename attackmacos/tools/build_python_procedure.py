#!/usr/bin/env python3

"""
Python Procedure Builder
Builds Python executables from YAML procedure definitions
Similar to build_procedure.py but outputs Python instead of bash
"""

import yaml
import sys
import os
from pathlib import Path

def read_yaml(yaml_file):
    """Read and parse YAML procedure file"""
    try:
        with open(yaml_file, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error reading YAML: {e}")
        sys.exit(1)

def generate_python_script(yaml_data, output_file):
    """Generate Python script from YAML data"""
    
    # Extract procedure info
    procedure_name = yaml_data.get('procedure_name', 'unknown')
    ttp_id = yaml_data.get('ttp_id', 'T0000')
    description = yaml_data.get('intent', 'No description')
    author = yaml_data.get('author', 'Unknown')
    version = yaml_data.get('version', '1.0.0')
    
    # Start building Python script
    python_code = f'''#!/usr/bin/env python3

"""
{procedure_name} - {ttp_id}
{description}

Author: {author}
Version: {version}
Generated from YAML procedure definition
"""

import subprocess
import sys
import os
import argparse
from pathlib import Path
import sqlite3
import time
import secrets

# Global variables
'''
    
    # Add global variables
    if 'global_variable' in yaml_data.get('procedure', {}):
        for var in yaml_data['procedure']['global_variable']:
            var_name = var['name']
            default_value = var['default_value']
            if default_value.startswith('$'):
                # Handle environment variables
                default_value = f'os.path.expandvars("{default_value}")'
            elif default_value.startswith('"') and default_value.endswith('"'):
                # Keep as string
                default_value = default_value
            else:
                default_value = f'"{default_value}"'
            python_code += f'{var_name} = {default_value}\n'
    
    python_code += '\n'
    
    # Convert bash functions to Python functions
    if 'functions' in yaml_data.get('procedure', {}):
        for func in yaml_data['procedure']['functions']:
            func_name = func['name']
            func_description = func.get('description', 'No description')
            bash_code = func.get('code', '')
            
            python_code += f'def {func_name}():\n'
            python_code += f'    """{func_description}"""\n'
            
            # Convert bash code to Python equivalent
            python_func_code = convert_bash_to_python(bash_code, func_name)
            python_code += python_func_code + '\n\n'
    
    # Add main argument parsing
    python_code += '''
def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(description="''' + description + '''")
    
'''
    
    # Add arguments from YAML
    if 'arguments' in yaml_data.get('procedure', {}):
        for arg in yaml_data['procedure']['arguments']:
            option = arg['option']
            desc = arg['description']
            
            # Handle different option formats
            if '|' in option:
                short_opt, long_opt = option.split('|')
                python_code += f'    parser.add_argument("{short_opt}", "{long_opt}", action="store_true", help="{desc}")\n'
            else:
                python_code += f'    parser.add_argument("{option}", action="store_true", help="{desc}")\n'
    
    python_code += '''
    args = parser.parse_args()
    
    # Execute based on arguments
'''
    
    # Add argument handling
    if 'arguments' in yaml_data.get('procedure', {}):
        for arg in yaml_data['procedure']['arguments']:
            option = arg['option']
            execute_functions = arg.get('execute_function', [])
            
            # Get the argument name
            if '|' in option:
                arg_name = option.split('|')[1].replace('--', '').replace('-', '_')
            else:
                arg_name = option.replace('--', '').replace('-', '_')
            
            python_code += f'    if args.{arg_name}:\n'
            for func_name in execute_functions:
                python_code += f'        {func_name}()\n'
            python_code += f'        return\n\n'
    
    python_code += '''    
    # If no arguments, show help
    parser.print_help()

if __name__ == "__main__":
    main()
'''
    
    # Write the Python script
    with open(output_file, 'w') as f:
        f.write(python_code)
    
    # Make executable
    os.chmod(output_file, 0o755)
    print(f"✅ Python script created: {output_file}")

def convert_bash_to_python(bash_code, func_name):
    """Convert bash function code to Python equivalent"""
    
    # This is a simplified converter - we'll focus on the key screenshot functions
    if 'capture_python_screenshot' in func_name:
        return '''    
    output_path = f"{os.path.expandvars('$HOME')}/.local/share/python_{secrets.token_hex(4)}.jpg"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    print("PYTHON_SCREENSHOT|capturing|Using Python subprocess (standard library)")
    
    try:
        result = subprocess.run(["/usr/sbin/screencapture", "-x", output_path], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0 and os.path.exists(output_path):
            size = os.path.getsize(output_path)
            print(f"PYTHON_SCREENSHOT|captured|SUCCESS: {output_path} ({size} bytes)")
        else:
            print("PYTHON_SCREENSHOT|failed|capture failed")
            return False
    except Exception as e:
        print(f"PYTHON_SCREENSHOT|failed|{e}")
        return False
    return True'''
    
    elif 'capture_screenshot' in func_name and 'python' not in func_name:
        return '''    
    screenshot_path = "/tmp/ss.jpg"
    print("SCREENSHOT|capturing|Silent screenshot")
    
    try:
        result = subprocess.run(["/usr/sbin/screencapture", "-x", screenshot_path], 
                              capture_output=True, text=True)
        if result.returncode == 0 and os.path.exists(screenshot_path):
            size = os.path.getsize(screenshot_path)
            print(f"SCREENSHOT|captured|{screenshot_path} ({size} bytes)")
        else:
            print("SCREENSHOT|failed|Could not capture screenshot")
            return False
    except Exception as e:
        print(f"SCREENSHOT|failed|{e}")
        return False
    return True'''
    
    elif 'query_tcc_permissions' in func_name:
        return '''    
    print("TCC_QUERY|checking|Screen recording permissions in TCC database")
    
    user_tcc = os.path.expandvars("$HOME/Library/Application Support/com.apple.TCC/TCC.db")
    
    try:
        if os.access(user_tcc, os.R_OK):
            print("TCC_QUERY|user_db|Accessible for reading")
            
            conn = sqlite3.connect(user_tcc)
            cursor = conn.cursor()
            
            # Query for screen-related services
            cursor.execute("SELECT DISTINCT service FROM access WHERE service LIKE '%Screen%' OR service LIKE '%kTCC%'")
            services = cursor.fetchall()
            
            if services:
                for service in services:
                    print(f"TCC_QUERY|services|{service[0]}")
                
                # Get specific permissions
                cursor.execute("SELECT service, client, auth_value FROM access WHERE service LIKE '%Screen%'")
                permissions = cursor.fetchall()
                
                for service, client, auth_value in permissions:
                    print(f"TCC_QUERY|permission|{service}: {client} (auth_value: {auth_value})")
            else:
                print("TCC_QUERY|services|No screen-related services found")
            
            conn.close()
        else:
            print("TCC_QUERY|user_db|Protected (normal behavior)")
    except Exception as e:
        print(f"TCC_QUERY|error|{e}")'''
    
    elif 'scan_privileged_processes' in func_name:
        return '''    
    print("PROCESS_SCAN|scanning|Processes that might have screen recording permissions")
    
    # Look for ScreenTime processes
    try:
        result = subprocess.run(["pgrep", "-f", "ScreenTime"], capture_output=True, text=True)
        if result.stdout.strip():
            pids = result.stdout.strip().split('\\n')
            print(f"PROCESS_SCAN|found|ScreenTime processes: {' '.join(pids)}")
    except:
        pass
    
    # Look for recording apps
    recording_apps = ["QuickTime", "Screenshot", "OBS", "Zoom", "Teams", "Skype", "Discord"]
    try:
        result = subprocess.run(["ps", "aux"], capture_output=True, text=True)
        for line in result.stdout.split('\\n'):
            for app in recording_apps:
                if app.lower() in line.lower() and 'grep' not in line:
                    parts = line.split()
                    if len(parts) >= 11:
                        pid = parts[1]
                        app_name = os.path.basename(parts[10])
                        print(f"PROCESS_SCAN|potential|{app_name} (PID: {pid})")
    except:
        pass
    
    # Check loginwindow
    try:
        result = subprocess.run(["pgrep", "loginwindow"], capture_output=True, text=True)
        if result.stdout.strip():
            pid = result.stdout.strip()
            print(f"PROCESS_SCAN|system|loginwindow (PID: {pid}) - system process with elevated permissions")
    except:
        pass'''
    
    else:
        # Default conversion for other functions
        return f'    print("Function {func_name} not yet implemented in Python converter")\n    pass'

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 build_python_procedure.py <yaml_file> [output_file]")
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        # Generate output filename
        base_name = Path(yaml_file).stem
        output_file = f"{base_name}_python.py"
    
    # Read YAML
    yaml_data = read_yaml(yaml_file)
    
    # Generate Python script
    generate_python_script(yaml_data, output_file)

if __name__ == "__main__":
    main() 