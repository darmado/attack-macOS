# Mystikal
macOS Initial Access Payload Generator

- Intended to be used with https://github.com/its-a-feature/Mythic

Related Blog Post:
- https://posts.specterops.io/introducing-mystikal-4fbd2f7ae520

## Usage: 
1. Install Xcode on build machine (Required for Installer Package w/ Installer Plugin)
2. Install python requirements
```
sudo pip3 install -r requirements.txt
```
3. Change settings within the `Settings/MythicSettings.py` file to match your Mythic configs
4. Run mystikal
```
python3 mystikal.py
```
5. Select your desired payload from the options
```
 _______               __   __ __           __
|   |   |.--.--.-----.|  |_|__|  |--.---.-.|  |
|       ||  |  |__ --||   _|  |    <|  _  ||  |
|__|_|__||___  |_____||____|__|__|__|___._||__|
         |_____|
         
Mystikal: macOS Payload Generator
Main Choice: Choose 1 of 11 choices
Choose 1 for Installer Packages
Choose 2 for Mobile Configuration: Chrome Extension
Choose 3 for Mobile Configuration: Webloc File
Choose 4 for Office Macros: VBA
Choose 5 for Office Macros: XLM Macros in SYLK Files
Choose 6 for Disk Images
Choose 7 for Armed PDFs
Choose 8 for Armed Python PIP Packages
Choose 9 for Armed Ruby Gems
Choose 10 for Armed NodeJS NPM Packages
Choose 11 to exit
```
### Note: 
Option 1, Option 1.4, Option 4, Option 8, Option 9, and Option 11 have submenus shown below
```
Selected Installer Packages
SubMenu: Choose 1 of 5 choices
Choose 1 for Installer Package w/ only pre/postinstall scripts
Choose 2 for Installer Package w/ Launch Daemon for Persistence
Choose 3 for Installer Package w/ Installer Plugin
Choose 4 for Installer Package w/ JavaScript Functionality
Choose 5 for Installer Package w/ Dylib
Choose 6 to exit

Selected Installer Package w/ JavaScript Functionality
SubMenu Choice: Choose 1 of 3 choices
Choose 1 for Installer Package w/ JavaScript Functionality embedded
Choose 2 for Installer Package w/ JavaScript Functionality in Script
Choose 3 to exit

Selected Office Macros: VBA
SubMenu Choice: Choose 1 of 4 choices
Choose 1 for VBA Macros for Word
Choose 2 for VBA Macros for Excel
Choose 3 for VBA Macros for PowerPoint
Choose 4 to exit

Selected Armed Python PIP Package
SubMenu Choice: Choose 1 of 3 choices
Choose 1 for Armed Python PIP Packages w/ osascript execution
Choose 2 for Armed Python PIP Packages w/ dylib load
Choose 3 to exit

Selected Armed Ruby Gem
SubMenu Choice: Choose 1 of 3 choices
Choose 1 for Armed Ruby Gem w/ osascript execution
Choose 2 for Armed Ruby Gem w/ dylib load
Choose 3 to exit

Selected Tclsh
SubMenu Choice: Choose 1 of 3 choices
Choose 1 for Tclsh w/ local files
Choose 2 for Tclsh w/ hosted dylibs
Choose 3 to exit
```
### Behavior Modifications: 
To change the execution behavior (which binaries are called upon payload execution)
- Modifications will be required in either the specific payload file under the `Modules` folder or the related template file under the `Templates` folder.

### Common Issues
Make sure mythic python package is on the latest version
```
pip3 uninstall -y mythic && pip3 install mythic
```
