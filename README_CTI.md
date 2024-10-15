<p align="center">

``` bash
               ████                                                                                                     
               █████                                                                                                    
      █       ███████      ██                                                                                           
    ███████████████████████                                                                                         
    ██████████████████████                                                                                          
     ███████          ███████                                                                                           
     █████      ████    ██████                                 ███                                                      
    █████        █████   █████                                █████  █████████████████  █████     ██████                
████████           ████   ████████                 ██████     █████  █████████████████  █████    ██████                 
████████   ██      █████  █████████      ███       ██████                  █████        █████   █████                   
███████   ████ ████████  ████████ ████████████ ████████████ █████        █████        ███████████                     
    █████   ████████████   ████    █████████████ ████████████ █████        █████        ███████████                     
    ██████   █████████████   █     ██████          ██████     █████        █████        ███████████                     
     ███████         ███████       █████           ██████     █████        █████        █████ ██████                    
    ████████████████   ███████     █████           ██████     █████        █████        █████  ██████                   
   ███████████████████   ███████   █████          ██████     █████        █████        █████   ██████                  
     ███    ██████████     ██████  █████████████   █████████  █████        █████        █████     █████                 
              ██████        ████     ███████████     ███████  █████        █████        █████     ███████               
               █████                                                                                                    
                                                                         C  T  I    T  O  O  L    K  I  T  

                                                                              v e r s i o n : 0 . 9 . 0 
```
</p> 

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.9%2B-green?style=for-the-badge&logo=python" alt="Python"/>
  <img src="https://img.shields.io/badge/STIX-2.1-blue?style=for-the-badge" alt="STIX"/>
  <img src="https://img.shields.io/badge/MITRE-ATT%26CK-red?style=for-the-badge" alt="MITRE ATT&CK"/>
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/LLM-Powered-purple?style=for-the-badge" alt="LLM"/>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#download">Download</a> •
  <a href="#credits">Credits</a> •
  <a href="#related">Related</a> •
  <a href="#license">License</a>
</p>

##

ctiTK is an open-source, modular command-line toolkit designed to streamline common tasks and workflows related to CTI reports.

> *ℹ️ ctiTK is currently under active development.*

## Project Goals

### 1. Extract and Format CTI
- **Source:** Common Documents formats, HTML
- **Output:** STIX 2.1, JSON, HTML, PDF, and markdown


### 2. Structure and Report
- **MITRE ATT&CK Contribution Reports:** Increase ATT&CK submissions frequency
- **Full Reports:** Based on CTI Blueprints

### 3. Track, Maintain and Share Living Reports
- **Method:** Public GitHub repository, S3 Bucket
- **Sharing:** STIX 2.1, JSON, and Markdown


---

##

### Key Features

| Feature | Description | Sample |
|:--------|:------------|:-------|
| **Command Line Interface** | • Uses Prompt-toolkit for CLI<br>• Built-in wizard and configuration options<br>• Spellcheck | TBD |
| **Report Types** | Based on CTI Blueprints reporting templates. Generates reports for:<br>• MITRE ATT&CK Submissions<br>• CTI Campaigns<br>• CTI Intrusions<br>• CTI Threat Actors | TBD |
| **Enrichment** | • MITRE ATT&CK<br>• CAPEC<br>• D3FEND<br>• NIST | TBD |
| **Format Support** | • STIX 2.1<br>• JSON<br>• HTML<br>• PDF | TBD |

##

## Integrated Projects

ctiTK integrates and builds upon several open-source projects to enhance its capabilities:

1. [aiocrioc](https://github.com/referefref/aiocrioc): An LLM and OCR based Indicator of Compromise Extraction Tool, used for extracting various types of indicators from text and images.

- [MITRE ATT&CK](https://attack.mitre.org/)
- [Blue Prints](https://github.com/center-for-threat-informed-defense/cti-blueprints/wiki)
- [Attack FLow](https://github.com/center-for-threat-informed-defense/attack-flow)
- [STIX 2.0](https://oasis-open.github.io/cti-documentation/stix/intro)
- [APTnotes](https://github.com/kbandla/APTnotes)
- [The DFIR Report](https://thedfirreport.com/)



### Installation
```
git clone https://github.com/yourusername/ctitk.git
cd ctitk
pip install -r requirements.txt
```

##

### Usage
To start ctiTK:
```
python ct
```

##

### Acknowledgements

ctiTK integrates and builds upon several open-source projects and resources:

- [MITRE ATT&CK](https://attack.mitre.org/)
- [Blue Prints](https://github.com/center-for-threat-informed-defense/cti-blueprints/wiki)
- [Attack FLow](https://github.com/center-for-threat-informed-defense/attack-flow)
- [STIX 2.0](https://oasis-open.github.io/cti-documentation/stix/intro)
- [APTnotes](https://github.com/kbandla/APTnotes)
- [The DFIR Report](https://thedfirreport.com/)
- [Awesome Threat Intelligence](https://github.com/hslatman/awesome-threat-intelligence)
- [ControlCompass](https://github.com/ControlCompass)
- [aiocrioc](https://github.com/referefref/aiocrioc)

##

## Disclaimer

This project is not affiliated with or endorsed by MITRE. Use responsibly and only on authorized systems. MITRE ATT&CK® is a registered trademark of The MITRE Corporation.

## New Features
- OTI (Offensive Tool Intel) data support
  - List Commands, Malware, Tools, and Attack Scenarios
  - Data sourced from STIX 2.0 files

## Usage
To list OTI data:
```
list OTI <Commands|Malware|Tools|Attack_Scenarios>
```

## Setup
Ensure the `octi_data_dir` in `config/settings.yaml` points to your OTI data directory.

# ... (rest of the README)