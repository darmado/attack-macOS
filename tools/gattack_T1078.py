import json
import re

def extract_technique_relationships(description, technique_id):
    technique_pattern = r'T\d+(?:\.\d+)?'
    
    dependency_phrases = [
        r'uses', r'leverages', r'relies on', r'depends on', r'requires', r'involve manipulating', r'and abuse', r'involves abusing',
        r'is facilitated by', r'enables', r'can be used for', r'may use', r'involve using', r'may leverage',
        r'may be used in conjunction with', r'supports', r'often uses', r'frequently leverages', r'additional techniques like',
        r'resources using', r'with administrator-level', r'other attack techniques like'
    ]
    
    relationships = []
    
    for phrase in dependency_phrases:
        pattern = rf'({technique_pattern}).*?{phrase}.*?\[Valid Accounts\]'
        matches = re.finditer(pattern, description, re.IGNORECASE | re.DOTALL)
        for match in matches:
            related_technique = match.group(1)
            if related_technique != technique_id:  # Avoid self-reference
                relationships.append((related_technique, phrase))
    
    return relationships

def analyze_technique_dependencies(data):
    related_techniques = []
    technique_map = {}
    unknown_techniques = set()

    for obj in data['objects']:
        if obj['type'] == 'attack-pattern':
            technique_id = obj['external_references'][0]['external_id']
            name = obj['name']
            description = obj.get('description', '')
            
            technique_map[technique_id] = {'name': name, 'description': description}
            
            relationships = extract_technique_relationships(description, technique_id)
            for related_technique, relationship in relationships:
                if related_technique in technique_map:
                    related_techniques.append((technique_id, related_technique, relationship))
                else:
                    unknown_techniques.add(related_technique)

    return related_techniques, technique_map, unknown_techniques

# Load the MITRE ATT&CK data
with open('enterprise-attack.json', 'r') as file:
    data = json.load(file)

# Analyze the techniques that relate to T1078
related_techniques, technique_map, unknown_techniques = analyze_technique_dependencies(data)

# Print the results
print("Techniques related to T1078 (Valid Accounts):")
for technique, related_technique, relationship in related_techniques:
    if related_technique == 'T1078':
        print(f"- {technique} ({technique_map[technique]['name']}) {relationship} T1078")

if unknown_techniques:
    print("\nUnknown technique IDs found in descriptions:")
    for technique in unknown_techniques:
        print(f"- {technique}")

print(f"\nTotal techniques related to T1078: {len(set(t[0] for t in related_techniques))}")
