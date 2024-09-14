![Reconnaissance](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Reconnaissance?label=Reconnaissance&type=file)
![Resource Development](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Resource_Development?label=Resource%20Development&type=file)
![Initial Access](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Initial_Access?label=Initial%20Access&type=file)
![Execution](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Execution?label=Execution&type=file)
![Persistence](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Persistence?label=Persistence&type=file)
![Privilege Escalation](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Privilege_Escalation?label=Privilege%20Escalation&type=file)
![Defense Evasion](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Defense_Evasion?label=Defense%20Evasion&type=file)
![Credential Access](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Credential_Access?label=Credential%20Access&type=file)
![Discovery](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Discovery?label=Discovery&type=file)
![Lateral Movement](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Lateral_Movement?label=Lateral%20Movement&type=file)
![Collection](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Collection?label=Collection&type=file)
![Command and Control](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Command_and_Control?label=Command%20and%20Control&type=file)
![Exfiltration](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Exfiltration?label=Exfiltration&type=file)
![Impact](https://img.shields.io/github/directory-file-count/darmado/attack-macOS/Impact?label=Impact&type=file)


![attack_macos_icon](https://github.com/user-attachments/assets/7f845f94-0809-4ffe-87d8-c0518ac501e1) 

# Attack-macOS

Attack-macOS is a library of scripts mapped to MITRE ATT&CK. Security teams can use attack-macOS to execute techniques and produce telemetry that facilitates detection opportunities in macOS environments.

## Key Features

- **Modular Design**: Each script is self-contained and can be used independently or combined for complex scenarios.
- **Customizable**: Easy to modify and extend for specific testing needs.
- **macOS Native**: All scripts use native tools and languages, including Bash, Swift, and AppleScript.
- **MITRE ATT&CK Mapped**: All scripts are mapped to MITRE ATT&CK.
- **Logging**: Built-in capability to log script output for analysis.
- **Encoding**: Multiple options to encode data (Base64, hex) for various testing scenarios.
- **Encryption**: Integrated functions to encrypt data with AES, Blowfish, and GPG.
- **Exfiltration**: Simulated data exfiltration via HTTP or DNS protocols.

## Get started

You can execute attack-macOS scripts directly from the command line. For example:

```bash
./Collection/keychain_dump.sh
```

For more detailed usage instructions, use ```--help.```

## Learn more

[This section would typically contain links to documentation or additional resources. As we don't have this information, we'll leave it as a placeholder.]

## How to Contribute 

Attack-macOS is built as a community development project. Once we add 200+ TTPs, we'll open it up entirely to the community. For now:

- For bugs, feature requests, or suggestions: 
  [![GitHub issues](https://img.shields.io/github/issues/yourusername/attack-macOS.svg)](https://github.com/darmado/attack-macOS/issues)

- For new or modified features for scripts:
  1. Fork the repository
  2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
  3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
  4. Push to the branch (`git push origin feature/AmazingFeature`)
  5. Open a Pull Request


