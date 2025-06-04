#!/usr/bin/env python3
"""
LOOBins to Procedure Converter

Load procedure template, fill it with LOOBins data.
"""

import yaml
import sys
from pathlib import Path
from datetime import datetime


def load_yaml(path):
    """Load YAML file."""
    with open(path, 'r') as f:
        return yaml.safe_load(f)


def save_yaml(data, path):
    """Save YAML file."""
    with open(path, 'w') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, indent=2)


def map_metadata(template, loobin_data):
    """Map LOOBins metadata to procedure template."""
    template['procedure_name'] = loobin_data['name'].lower()
    template['intent'] = loobin_data.get('short_description', f"Execute {loobin_data['name']} commands")
    template['author'] = loobin_data.get('author', '@darmado | https://x.com/darmad0')
    template['created'] = str(loobin_data.get('created', datetime.now().strftime('%Y-%m-%d')))
    template['updated'] = template['created']


def map_arguments(template, loobin_data):
    """Map LOOBins examples to procedure arguments."""
    template['procedure']['arguments'] = []
    
    for example in loobin_data.get('example_use_cases', []):
        option = f"--{example['name'].lower().replace(' ', '-')}"
        func_name = f"execute_{example['name'].lower().replace(' ', '_')}"
        
        template['procedure']['arguments'].append({
            'option': option,
            'description': example['description'][:100],
            'execute_function': [func_name]
        })


def map_global_variables(template, loobin_data):
    """Map LOOBins paths to global variables."""
    binary_path = loobin_data.get('paths', [f"/usr/bin/{loobin_data['name']}"])[0]
    
    template['procedure']['global_variable'] = [{
        'name': 'BINARY_PATH',
        'type': 'string',
        'default_value': binary_path
    }]


def map_functions(template, loobin_data):
    """Map LOOBins examples to shell functions."""
    template['procedure']['functions'] = []
    
    for example in loobin_data.get('example_use_cases', []):
        func_name = f"execute_{example['name'].lower().replace(' ', '_')}"
        
        code = f"""{func_name}() {{
    local result
    result=$({example['code']} 2>&1)
    $CMD_PRINTF "RESULT|%s\\n" "$result"
    return 0
}}"""
        
        template['procedure']['functions'].append({
            'name': func_name,
            'type': 'main',
            'language': ['shell'],
            'sudo_required': False,
            'opsec': {
                'check_fda': {
                    'enabled': False,
                    'exit_on_failure': True
                }
            },
            'code': code
        })


def map_optional_sections(template, loobin_data):
    """Map optional sections if they exist."""
    if 'resources' in loobin_data:
        template['resources'] = [
            {'link': r['url'], 'description': r['name']} 
            for r in loobin_data['resources']
        ]
    
    if 'detections' in loobin_data:
        template['detection'] = [
            {'ioc': d['name'], 'analysis': d.get('url', '')} 
            for d in loobin_data['detections'] 
            if d.get('url') != 'N/A'
        ]


def convert(loobin_path, template_path):
    """Convert LOOBins to procedure format."""
    # Load files
    template = load_yaml(template_path)
    loobin_data = load_yaml(loobin_path)
    
    # Map data to template
    map_metadata(template, loobin_data)
    map_arguments(template, loobin_data)
    map_global_variables(template, loobin_data)
    map_functions(template, loobin_data)
    map_optional_sections(template, loobin_data)
    
    return template


def main():
    """Main function."""
    if len(sys.argv) != 2:
        print("Usage: python3 convert_loobin_to_procedure.py <loobin.yml>")
        sys.exit(1)
    
    loobin_path = Path(sys.argv[1])
    if not loobin_path.exists():
        print(f"❌ File not found: {loobin_path}")
        sys.exit(1)
    
    # Paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    template_path = project_root / "attackmacos/core/templates/procedure.yml"
    output_path = f"{loobin_path.stem}_procedure.yml"
    
    # Convert
    procedure_data = convert(loobin_path, template_path)
    
    # Save
    save_yaml(procedure_data, output_path)
    
    print(f"✅ Converted: {loobin_path} → {output_path}")
    print(f"📝 Edit {output_path} to update TTP_ID and review functions")


if __name__ == "__main__":
    main() 