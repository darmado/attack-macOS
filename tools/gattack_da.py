from mitreattack.stix20 import MitreAttackData
import re


def main():
    dependency_phrases = [
    r'uses', r'leverages', r'relies on', r'depends on', r'requires', r'involve manipulating', r'and abuse', r'involves abusing',
    r'is facilitated by', r'enables', r'can be used for', r'may use', r'involve using', r'may leverage',
    r'may be used in conjunction with', r'supports', r'often uses', r'frequently leverages', r'additional techniques like',
    r'resources using', r'with administrator-level', r'other attack techniques like'
]
        
    mitre_attack_data = MitreAttackData("enterprise-attack.json")

    # retrieve techniques by the content of their description
    # Test if the function supports regex
    techniques = mitre_attack_data.get_objects_by_content(r'\[Valid Account\])', "attack-pattern", remove_revoked_deprecated=True)
    
    if not techniques:
        # If no results, fall back to the original string search
        techniques = mitre_attack_data.get_objects_by_content('Valid Account', "attack-pattern", remove_revoked_deprecated=True)
    
    print(f"Regex support: {'Yes' if techniques else 'No'}")
    print(f"There are {len(techniques)} techniques where 'Valid Account' appears in the description.")

    for technique in techniques:
        external_id = next((ref.external_id for ref in technique.external_references if ref.source_name == "mitre-attack"), "N/A")
        name = technique.name

        # Find the line containing "Valid Account" with preceding context
        matches = re.finditer(r'.{0,20}Valid Account.*', technique.description, re.IGNORECASE | re.MULTILINE)
        matching_lines = [match.group(0) for match in matches]

        print(f"\nTechnique ID: {external_id}")
        print(f"Name: {name}")
        for i, line in enumerate(matching_lines, 1):
            colored_line = re.sub(r'(Valid Account)', r'\033[1;31m\1\033[0m', line, flags=re.IGNORECASE)
            print(f"\033[1;33mMatching line {i}\033[0m: {colored_line}")

    # retrieve all objects by the content of their description
    objects = mitre_attack_data.get_objects_by_content("Valid Account", None, remove_revoked_deprecated=True)
    print(f"\nThere are a total of {len(objects)} objects where 'Valid Account' appears in the description.")


if __name__ == "__main__":
    main()
