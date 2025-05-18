# SafariJXA

<p align="center">
  <img src="https://img.shields.io/badge/JXA-F7DF1E?style=for-the-badge&logo=apple&logoColor=black" alt="JavaScript for Automation"/>
  <img src="https://img.shields.io/badge/Safari-000000?style=for-the-badge&logo=Safari&logoColor=white" alt="Safari"/>
  <img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS"/>
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge&logo=apache" alt="License"/></br>
  <img src="https://img.shields.io/badge/Under%20Development-FF0000?style=for-the-badge" alt="Under Development"/>
</p>

### Overview

A JavaScript for Automation (JXA) library and CLI tool that controls and extends Safari browser capabilities on macOS while operating within the constraints of default Transparency, Consent, and Control (TCC) permissions.

##


### Purpose

To provide a JXA tool for controlling, automating, and extending Safari browser functionality on macOS within the boundaries of TCC. 

##

### Extensibility

Built with modular functions to allow users to expand and customize its capabilities. Each function is self-contained, making adding new features or integrating with other tools is straightforward.

##

### Features

| Category | Features |
|----------|----------|
| Window and Tab Management | • List, open, close, and navigate Safari tabs and windows<br>• Reload tabs and manage multiple Safari windows |
| Protocol Handling | • Manage mailto, sms, and tel protocols to interact with default macOS applications |
| Information Retrieval | • Get URLs and titles of active tabs<br>• Access the Reading List, browsing history, and list installed extensions |
| Utility Functions | • Launch Safari and open new windows with specified dimensions<br>• Validate and format URLs |
| Script Execution | • Dual-mode functionality: Operates as both a command-line tool and an importable module for broader programmatic use |

##

### TCC Permissions
SafariJXA uses several functions that require specific TCC (Transparency, Consent, and Control) permissions to operate. This section maps the tool's functions to their required TCC permissions:

| Function | TCC Permission | Description |
|----------|----------------|-------------|
| `listDownloads` | kTCCServiceSystemPolicyDownloadsFolder | Allows SafariJXA to access files in the Downloads folder. |
| `listHistory`,<br>`listExtensions` | kTCCServiceSystemPolicyAllFiles | Allows SafariJXA to access and read data stored on the local file system, such as Safari's browsing history and extension data. |
| `listReadingList` | kTCCServiceUbiquity | Accesses iCloud-synced data like bookmarks and Reading Lists. This utilizes Safari's iCloud permission to interact with synced data. |
| `execJS`,<br>`searchGoogle`,<br>`searchDDG`,<br>`disableImages` | kTCCServiceAppleEvents | Allows SafariJXA to control Safari, execute JavaScript in the current tab, perform searches in new tabs, and modify Safari's settings. |
| `listTabs`,<br>`listWindows`,<br>`listURLs`,<br>`listPageTitles`,<br>`navigateToURL`,<br>`closeTab`,<br>`reloadTab`,<br>`openTab`,<br>`closeWindow`,<br>`closeSafari`,<br>`openNewWindow` | No Specific TCC Permission | These operations interact directly with Safari's internal objects (windows, tabs, etc.), leveraging Safari's default permissions without requiring specific TCC access. |
| `launch`,<br>`handleMailto`,<br>`handleSms`,<br>`handleTel` | No Specific TCC Permission | These functions use system-level commands that don't require specific TCC permissions. |

##


### Libraries Used

- AppKit: Provides the foundation for building graphical user interfaces and interacting with macOS applications.
- SafariServices: Integrates Safari-like features into applications, such as managing Safari extensions.
- JavaScriptCore: Allows execution of JavaScript code within applications, useful for scripting and automation.


##

### Usage

To use SafariJXA, run the script with the desired command-line arguments. The available commands are:

### Usage

To use SafariJXA, run the script with the desired command-line arguments. The available commands are:

| Category | Command | Description | TCC Safe |
|----------|---------|-------------|----------|
| **Discover** ||||
|| `-listTabs` | List all open tabs in Safari | ✅ |
|| `-listURLs` | List the URLs of the current active tabs in all windows | ✅ |
|| `-listWindows` | List all open Safari windows | ✅ |
|| `-listPageTitles` | List the titles of the current active tabs in all windows | ✅ |
|| `-listReadingList` | List Safari's reading list | ✅ |
|| `-listDownloads` | List files in the Downloads directory | ✅ |
|| `-listExtensions` | List installed Safari extensions | ✅ |
|| `-listHistory` | List Safari's browsing history | ✅ |
| **Open** ||||
|| `-launch` | Launch Safari with a 1x1 window | ✅ |
|| `-newWindow` | Open a new Safari window with a 1x1 size | ✅ |
|| `-mailto <email>` | Open the default email client with the specified email | ❌ |
|| `-sms <number>` | Open the default SMS app with the specified number | ❌ |
|| `-tel <number>` | Open the default phone app with the specified number | ❌ |
|| `-openTab <url1> [url2] ...` | Open one or more new tabs with the specified URLs (max 25) | ✅ |
| **Manage** ||||
|| `-closeTab <index>` | Close a tab by its index or URL | ✅ |
|| `-reloadTab` | Reload the current active tab | ✅ |
|| `-navigateToURL <url>` | Navigate the current tab to a specified URL | ✅ |
|| `-closeWindow <index>` | Close a Safari window by its index | ✅ |
|| `-closeSafari` | Quit Safari | ✅ |
| **Execute** ||||
|| `-execJS <script>` | Execute JavaScript in the current tab | ✅ |
| **Search** ||||
|| `-searchGoogle <query>` | Search Google in a new tab | ✅ |
|| `-searchDDG <query>` | Search DuckDuckGo in a new tab | ✅ |
| **Settings** ||||
|| `-disableImages` | Disable image loading in Safari | ✅ |
| **Help** ||||
|| `-help` | Display the help message | ✅ |

##

### Contribution

Contributions are welcome! Feel free to submit issues, feature requests, or pull requests to help improve SafariJXA.

##

### Resources

- [AppKit](https://developer.apple.com/documentation/appkit)
- [SafariServices](https://developer.apple.com/documentation/safariservices)
- [JavaScriptCore](https://developer.apple.com/documentation/javascriptcore)
- [JXA: Automating Safari](https://bru6.de/jxa/automating-applications/safari/)
- 


### License

SafariJXA is licensed under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

