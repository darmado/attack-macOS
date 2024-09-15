
<<<<<<< HEAD

![AttackMacOS_icon](https://github.com/user-attachments/assets/dc7809ab-10bf-46d2-8daf-e706af8ed371)


# Attack-macOS
Attack-macOS is a library of scripts mapped to MITRE ATT&CK. Security teams can use Attack-macOS to execute attack techniques and discover new detection opportunities in macOS environments.
## Objective
This project aims to simplify the execution of Living Off The Land (LOTL) techniques via scripts to validate macOS endpoint security.

## Dependencies

All Attack-macOS scripts use native macOS binaries, interpreters, playlists, libraries, tools, and utilities. If third-party tools are installed (```brew```, ```slack```,```jamf```),  techniques that leverage third-party apps can be executed. 

### Technique Coverage
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




=======
>>>>>>> 5e15b7d191f4490016e3081759bb34b193aa3ff2

![AttackMacOS_icon](https://github.com/user-attachments/assets/dc7809ab-10bf-46d2-8daf-e706af8ed371)

<<<<<<< HEAD
=======

# Attack macOS
Attack macOS is a library of scripts mapped to MITRE ATT&CK. Security teams can use Attack-macOS to execute attack techniques and discover new detection opportunities in macOS environments.
##
### **Objective**
This project aims to simplify the execution of Living Off The Land (LOTL) techniques via scripts to validate macOS endpoint security.
</br>
##
### Dependencies

All Attack macOS scripts use native macOS binaries, interpreters, playlists, libraries, tools, and utilities. If third-party tools are installed (```brew```, ```slack```,```jamf```),  techniques that leverage third-party apps can be executed. 
##

### Technique Coverage
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

##


### Key Features

>>>>>>> 5e15b7d191f4490016e3081759bb34b193aa3ff2
- **Template**: Includes a template for creating new scripts.
- **Modular Design**: Each script is self-contained and can be used independently or combined with other scripts.
- **Customizable**: Easy to modify and extend for specific testing needs.
- **macOS Native**: All scripts use native tools and languages, including Bash, Swift, and AppleScript.
- **MITRE ATT&CK Mapped**: All scripts and corresponding arguments are mapped to MITRE ATT&CK.
- **Logging**: Built-in capability to log script output for analysis.
- **Encoding**: Multiple options to encode data (Base64, hex) for various testing scenarios.
- **Encryption**: Integrated functions to encrypt output with AES, Blowfish, and GPG.
- **Exfiltration**: Simulated data exfiltration via HTTP or DNS protocols.

<<<<<<< HEAD


## Get started

You can execute Attack-macOS scripts from the command line via piped execution or disk. It depends on what telemetry you need to produce. For example:

```sh
curl -sSL https://raw.githubusercontent.com/darmado/attack-macOS/main/Discovery/accounts.sh | sh -s -- --help
```
For more info, check out our wiki. 

=======
##

### Get started

You can execute Attack-macOS scripts from the command line via piped execution or disk. It depends on what telemetry you need to produce. For example:

```sh
curl -sSL https://raw.githubusercontent.com/darmado/attack-macOS/main/Discovery/accounts.sh | sh -s -- --help
```
For more info, check out [Script Execution](https://github.com/darmado/attack-macOS/wiki/Script-Execution.md) 
##

### Learn more
>>>>>>> 5e15b7d191f4490016e3081759bb34b193aa3ff2

Wiki is in the works...

<<<<<<< HEAD
Wiki is in the works...

## How to Contribute 

=======
##
### How to Contribute 

>>>>>>> 5e15b7d191f4490016e3081759bb34b193aa3ff2
Attack-macOS is built as a community development project. Once we add 200+ TTPs, we'll open it up entirely to the community. For now:

- For bugs, feature requests, or suggestions: 
  [![GitHub issues](https://img.shields.io/github/issues/yourusername/attack-macOS.svg)](https://github.com/darmado/attack-macOS/issues)

- For new or modified features for scripts:
  1. Fork the repository
  2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
  3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
  4. Push to the branch (`git push origin feature/AmazingFeature`)
  5. Open a Pull Request

<<<<<<< HEAD
## Acknowledgements
=======
##

### Acknowledgements
>>>>>>> 5e15b7d191f4490016e3081759bb34b193aa3ff2
TTPs, attack scenarios, and code snippets are credited in the script's README.

*Special thanks to:*
- [MITRE ATT&CK ](https://twitter.com/mitreattack)
- [Red Canary ](https://twitter.com/redcanaryco)
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team)
- [The DFIR Report](https://thedfirreport.com/)

<<<<<<< HEAD

## License
=======
##

### License
>>>>>>> 5e15b7d191f4490016e3081759bb34b193aa3ff2

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.

