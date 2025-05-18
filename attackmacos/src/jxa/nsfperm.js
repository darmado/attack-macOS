ObjC.import('Foundation');

function getAccDir() {
    const homeDir = ObjC.unwrap($.NSHomeDirectory());
    const availableDir = [
        'Desktop', 'Documents', 'Downloads', 'Pictures', 'Music', 'Movies', 'Library',
        'Application Support', 'Preferences', 'Caches', 'Calendars', 'Reminders', 'AddressBook',
        'Photos', 'Mail', 'Messages', 'Safari', 'iCloud', 'Keychain', 'Contacts', 'Notes',
        'Health', 'HomeKit', 'Siri', 'Accessibility', 'Location Services', 'Camera', 'Microphone',
        'Screen Recording', 'Automation', 'Full Disk Access', 'System', 'CoreServices',
        'SystemConfiguration', 'Network', 'Security', 'SystemPreferences', 'UserInformation',
        'SystemUIServer', 'LaunchAgents', 'LaunchDaemons'
    ];

    const mainObj = {};

    function processDirectory(dirPath) {
        if ($.NSFileManager.defaultManager.isReadableFileAtPath(dirPath)) {
            const error = Ref();
            const attributes = $.NSFileManager.defaultManager.attributesOfItemAtPathError(dirPath, error);

            if (attributes) {
                const isWritable = $.NSFileManager.defaultManager.isWritableFileAtPath(dirPath);
                const protectionKey = ObjC.unwrap(attributes.objectForKey('NSFileProtectionKey'));
                const stickyBit = (ObjC.unwrap(attributes.objectForKey('NSFilePosixPermissions')) & 0x1000) ? true : false;
                const owner = ObjC.unwrap(attributes.objectForKey('NSFileOwnerAccountName'));
                const group = ObjC.unwrap(attributes.objectForKey('NSFileGroupOwnerAccountName'));
                const permissions = ObjC.unwrap(attributes.objectForKey('NSFilePosixPermissions')).toString(8); // Convert to octal string for readability
                const modificationDate = ObjC.unwrap(attributes.objectForKey('NSFileModificationDate')).toString();
                const isSymbolicLink = ObjC.unwrap(attributes.objectForKey('NSFileType')) === 'NSFileTypeSymbolicLink';
                const isHiddenFile = ObjC.unwrap(attributes.objectForKey('NSFileExtensionHidden')) ? true : false;

                mainObj[dirPath] = {
                    isWritable: isWritable,
                    owner: owner,
                    group: group,
                    permissions: permissions,
                    protectionKey: protectionKey,
                    stickyBit: stickyBit,
                    modificationDate: modificationDate,
                    isSymbolicLink: isSymbolicLink,
                    isHiddenFile: isHiddenFile
                };

                const subDirError = Ref();
                const subDirs = $.NSFileManager.defaultManager.contentsOfDirectoryAtPathError(dirPath, subDirError);
                if (subDirs) {
                    let subDirCount = subDirs.count;
                    for (let i = 0; i < subDirCount; i++) {
                        const file = subDirs.objectAtIndex(i);
                        const subDirPath = `${dirPath}/${file}`;
                        processDirectory(subDirPath);
                    }
                }
            } else {
                console.log(`Error accessing attributes for ${dirPath}: ${error.localizedDescription}`);
            }
        }
    }

    availableDir.forEach(dir => {
        const path = `${homeDir}/${dir}`;
        processDirectory(path);
    });

    console.log("Dirs with attributes:");
    return JSON.stringify(mainObj, null, 2);
}

console.log(getAccDir());
