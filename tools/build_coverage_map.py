from mitreattack.stix20 import MitreAttackData
from collections import defaultdict

def main():
    ttp_green = {
        "T1087.001": 12, "T1555.001": 9, "T1217": 4, "T1518.001": 10,
        "T1078": 2, "T1140": 1, "T1027.001": 1, "T1059.006": 1,
        "T1027.003": 1, "T1027": 2, "T1041": 2
    }
    ttp_yellow = [
        "T1007", "T1016", "T1049", "T1053.002", "T1082", "T1083", "T1135",
        "T1204.002", "T1562.001", "T1113", "T1115"
    ]
    ttp_count = {
        "red": '-lightgrey?style=for-the-badge&label=%20-%20',
        "yellow": '-lightgrey?style=for-the-badge&label=%20!%20',
        "green": '-lightgrey?style=for-the-badge&label=%20{count}%20',
    }
    ttp_status = {
        "red": '&labelColor=EB5454&color=494949',
        "yellow": '&labelColor=ffde59&color=494949',
        "green": '&labelColor=3bc05a&color=494949'
    }

    # Mapping of TTP IDs to script files
    ttp_to_script = {
        "T1087.001": "ttp/discovery/accounts.sh",
        "T1555.001": "ttp/credential_access/keychain.sh",
        "T1217": "ttp/discovery/browser_history.sh",
        "T1518.001": "ttp/discovery/security_software.sh",
        "T1078": "ttp/initial_access/guest_account.sh",
        "T1140": "ttp/discovery/browser_history.sh",
        "T1027.001": "ttp/discovery/browser_history.sh",
        "T1059.006": "ttp/discovery/browser_history.sh",
        "T1027.003": "ttp/discovery/browser_history.sh",
        "T1027": "ttp/discovery/browser_history.sh",
        "T1041": "ttp/discovery/browser_history.sh"
    }

    mitre_attack_data = MitreAttackData("enterprise-attack.json")
    techniques = mitre_attack_data.get_techniques_by_platform("macOS", remove_revoked_deprecated=True)

    tactics = defaultdict(list)
    for technique in techniques:
        for kill_chain_phase in technique.kill_chain_phases:
            if kill_chain_phase.kill_chain_name == "mitre-attack":
                tactic = kill_chain_phase.phase_name
                technique_id = next((ref.external_id for ref in technique.external_references if ref.source_name == "mitre-attack"), "N/A")
                tactics[tactic].append((technique_id, technique.name))

    # Calculate statistics
    total_techniques = len(techniques)
    implemented_techniques = len(ttp_green)
    implemented_procedures = sum(ttp_green.values())
    estimated_total_procedures = total_techniques * 20  # Assuming an average of 20 key procedures per technique
    technique_coverage = (implemented_techniques / total_techniques) * 100
    procedure_coverage = (implemented_procedures / estimated_total_procedures) * 100

    # Print statistics with badges
    print("<div align=\"center\">\n")
    print("# **MacOS Attack Procedure Matrix**\n")
    print("<p>The Matrix contains information for the macOS platform</br>The number of possible procedures per technique is vast. These statistics use conservative estimates for coverage calculations.</p>\n")
    print("</div>\n\n")
    print("<div align=\"center\">\n")
    print(f"![Technique Coverage](https://img.shields.io/badge/Technique%20Coverage-{implemented_techniques}%20({technique_coverage:.2f}%25)-grey?style=for-the-badge)")
    print(f"![Known Techniques](https://img.shields.io/badge/Known%20Techniques-{total_techniques}-red?style=for-the-badge)")
    print(f"![Procedure Coverage](https://img.shields.io/badge/Procedure%20Coverage-{implemented_procedures}%20({procedure_coverage:.2f}%25)-grey?style=for-the-badge)")
    print(f"![Estimated Known Procedures](https://img.shields.io/badge/Estimated%20Known%20Procedures-{estimated_total_procedures}-grey?style=for-the-badge)")
    print("\n</div>")
    print("<div align=\"center\">\n")
    print("</div>\n")
    print("##\n")

    # Print table header
    tactics_order = [
        "initial-access", "execution", "persistence", "privilege-escalation", 
        "defense-evasion", "credential-access", "discovery", "lateral-movement", 
        "collection", "command-and-control", "exfiltration", "impact"
    ]
    print("| " + " | ".join(tactic.replace("-", " ").title() for tactic in tactics_order) + " |")
    print("| " + " | ".join("---" for _ in tactics_order) + " |")

    # Find the maximum number of techniques in any tactic
    max_techniques = max(len(tactics[tactic]) for tactic in tactics_order)

    # Print table columns
    for i in range(max_techniques):
        row = []
        for tactic in tactics_order:
            if i < len(tactics[tactic]):
                tech_id, tech_name = tactics[tactic][i]
                if tech_id in ttp_green:
                    count = ttp_green[tech_id]
                    status = ttp_status["green"]
                    count_label = ttp_count["green"].format(count=count)
                elif tech_id in ttp_yellow:
                    status = ttp_status["yellow"]
                    count_label = ttp_count["yellow"]
                else:
                    status = ttp_status["red"]
                    count_label = ttp_count["red"]
                
                # Create GitHub markdown link if script exists for this TTP
                if tech_id in ttp_to_script:
                    script_link = f"[{tech_id}](../../{ttp_to_script[tech_id]})"
                else:
                    script_link = tech_id
                
                row.append(f"![{script_link}](https://img.shields.io/badge/{tech_id}{count_label}{status})</br><sub>{tech_name}</sub>")
            else:
                row.append("")
        print("| " + " | ".join(row) + " |")

    # Print technique counts per tactic
    print("\n## Technique Counts per Tactic")
    for tactic in tactics_order:
        print(f"- {tactic.replace('-', ' ').title()}: {len(tactics[tactic])}")

if __name__ == "__main__":
    main()
