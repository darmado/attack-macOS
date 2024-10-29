

















// Use NSFileManager permissions and return a list of accessible directories
function getAccessibleDirectories() {
    const homeDir = ObjC.unwrap($.NSHomeDirectory());
    const potentialDirs = ['Desktop', 'Documents', 'Downloads', 'Pictures', 'Music', 'Movies', 'Library', 'Application Support', 'Preferences', 'Caches',
        'Calendars', 'Reminders', 'AddressBook', 'Photos', 'Mail', 'Messages', 'Safari', 'iCloud', 'Keychain', 'Contacts', 'Notes', 'Health', 'HomeKit',
        'Siri', 'Accessibility', 'Location Services', 'Camera', 'Microphone', 'Screen Recording', 'Automation', 'Full Disk Access'
    ];
    const directories = [];

    potentialDirs.forEach(dir => {
        const path = `${homeDir}/${dir}`;
        if ($.NSFileManager.defaultManager.isReadableFileAtPath(path)) {
            directories.push(path);
        }
    });

    console.log("Accessible directories:");
    return JSON.stringify(directories, null, 2);
}

// Execute the function and print the result
getAccessibleDirectories()