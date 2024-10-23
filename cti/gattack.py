import json
import networkx as nx
import matplotlib.pyplot as plt
import re

def extract_technique_relationships(description):
    technique_pattern = r'T\d+(?:\.\d+)?'
    
    dependency_phrases = [
        r'depends on', r'relies on', r'requires', r'is a prerequisite for'
    ]
    
    techniques = re.findall(technique_pattern, description)
    relationships = []
    
    for technique in techniques:
        for phrase in dependency_phrases:
            match = re.search(f'{technique}.*{phrase}.*({technique_pattern})', description, re.IGNORECASE)
            if match:
                related_technique = match.group(1)
                relationships.append(('depends_on', technique, related_technique))
                break  # Only capture the first relationship for each technique
    
    return relationships

def analyze_techniques(data):
    G = nx.DiGraph()
    technique_map = {}

    for obj in data['objects']:
        if obj['type'] == 'attack-pattern':
            technique_id = obj['external_references'][0]['external_id']
            name = obj['name']
            description = obj.get('description', '')

            G.add_node(technique_id, name=name, description=description)
            technique_map[technique_id] = obj

            relationships = extract_technique_relationships(description)
            for rel_type, source, target in relationships:
                G.add_edge(source, target, relationship=rel_type)

    return G, technique_map

# Load the MITRE ATT&CK data
with open('enterprise-attack.json', 'r') as file:
    data = json.load(file)

# Analyze techniques and build the graph
G, technique_map = analyze_techniques(data)

# Find techniques with dependencies
techniques_with_dependencies = [node for node in G.nodes() if G.in_degree(node) > 0]

# Sort techniques by the number of dependencies (in-degree)
techniques_with_dependencies.sort(key=lambda x: G.in_degree(x), reverse=True)

# Print dependency relationships for the first 5 techniques
print("Dependency relationships for the first 5 techniques with dependencies:")
for i, technique in enumerate(techniques_with_dependencies[:5], 1):
    print(f"\n{i}. {technique} ({technique_map[technique]['name']}):")
    for predecessor in G.predecessors(technique):
        print(f"   - Depends on: {predecessor} ({technique_map[predecessor]['name']})")

# Visualize the subgraph of these 5 techniques and their dependencies
subgraph_nodes = set(techniques_with_dependencies[:5])
for technique in techniques_with_dependencies[:5]:
    subgraph_nodes.update(G.predecessors(technique))

subgraph = G.subgraph(subgraph_nodes)

plt.figure(figsize=(12, 8))
pos = nx.spring_layout(subgraph, k=0.5, iterations=50)
nx.draw(subgraph, pos, with_labels=True, node_size=3000, node_color='lightblue', 
        font_size=8, font_weight='bold', arrows=True)

# Add node labels
node_labels = {node: f"{node}\n{technique_map[node]['name']}" for node in subgraph.nodes()}
nx.draw_networkx_labels(subgraph, pos, labels=node_labels, font_size=6)

plt.title("Top 5 Techniques with Dependencies")
plt.axis('off')
plt.tight_layout()
plt.show()
