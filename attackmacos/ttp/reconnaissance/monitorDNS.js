#!/usr/bin/env osascript -l JavaScript

ObjC.import('Cocoa');

function run(args) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;

    const recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS"];
    const domains = args.slice(0, 10); // Accept up to 10 domain arguments

    if (domains.length === 0) {
        console.log("Please provide at least one domain as an argument.");
        return;
    }

    const windows = {};

    // ANSI color codes
    const colors = {
        reset: "\x1b[0m",
        bright: "\x1b[1m",
        dim: "\x1b[2m",
        underscore: "\x1b[4m",
        blink: "\x1b[5m",
        reverse: "\x1b[7m",
        hidden: "\x1b[8m",
        fg: {
            black: "\x1b[30m",
            red: "\x1b[31m",
            green: "\x1b[32m",
            yellow: "\x1b[33m",
            blue: "\x1b[34m",
            magenta: "\x1b[35m",
            cyan: "\x1b[36m",
            white: "\x1b[37m"
        },
        bg: {
            black: "\x1b[40m",
            red: "\x1b[41m",
            green: "\x1b[42m",
            yellow: "\x1b[43m",
            blue: "\x1b[44m",
            magenta: "\x1b[45m",
            cyan: "\x1b[46m",
            white: "\x1b[47m"
        }
    };

    function createWindowForDomain(domain) {
        const window = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer(
            $.NSMakeRect(100, 100, 800, 400),  // Increased width from 600 to 800
            $.NSWindowStyleMaskTitled | $.NSWindowStyleMaskClosable | $.NSWindowStyleMaskMiniaturizable | $.NSWindowStyleMaskResizable,
            $.NSBackingStoreBuffered,
            false
        );

        window.title = `DNS Record Monitor - ${domain}`;
        window.makeKeyAndOrderFront(null);

        const scrollView = $.NSScrollView.alloc.initWithFrame(window.contentView.bounds);
        const contentSize = scrollView.contentSize;
        const textView = $.NSTextView.alloc.initWithFrame($.NSMakeRect(0, 0, contentSize.width, contentSize.height));

        textView.autoresizingMask = $.NSViewWidthSizable | $.NSViewHeightSizable;
        textView.editable = false;
        textView.font = $.NSFont.fontWithNameSize('Menlo', 12);

        scrollView.documentView = textView;
        scrollView.hasVerticalScroller = true;
        scrollView.autoresizingMask = $.NSViewWidthSizable | $.NSViewHeightSizable;

        window.contentView.addSubview(scrollView);

        return { window, textView };
    }

    // Create windows for each domain
    domains.forEach((domain, index) => {
        const { window, textView } = createWindowForDomain(domain);
        windows[domain] = { window, textView };
        window.setFrameOrigin($.NSMakePoint(100 + index * 50, 100 + index * 50));
    });

    function checkDNSRecords() {
        domains.forEach(domain => {
            let output = '';

            // Header
            output += '╔══════════════════════════════════════════════════════════════════════════════════════════════╗\n';
            output += `║                          DNS Record Monitor for ${domain}                       ║\n`;
            output += '╠══════════════════════════════════════════════════════════════════════════════════════════════╣\n';

            // Timestamp
            output += `Timestamp: ${new Date().toLocaleString().padEnd(74)} ║\n`;

            // DNS Records
            output += getDNSRecord(domain) + '\n';

            // Footer
            output += '╠════════════════════════════════════════════════════════════════════════════════════════════╣\n';
            output += '║                            Next check in 5 seconds...                 ║\n';
            output += '╚════════════════════════════════════════════════════════════════════════════════════════════╝\n';

            // Update the text view content for this domain's window
            windows[domain].textView.string = output;
        });
    }

    function getDNSRecord(domain) {
        const task = $.NSTask.alloc.init;
        task.launchPath = "/bin/bash";
        task.arguments = ["-c", `
            (
                printf "%-6s %-70s\\n" "Type" "Value";
                printf "%-6s %-70s\\n" "----" "-----";
                for type in A AAAA CNAME MX TXT NS; do
                    result=$(dig +short +time=2 +tries=1 $type ${domain})
                    if [ -z "$result" ]; then
                        printf "%-6s %-70s\\n" "$type" "No record"
                    else
                        echo "$result" | while read -r line; do
                            printf "%-6s %-70s\\n" "$type" "$line"
                        done
                    fi
                done
            ) | sed 's/^/│ /' | sed 's/$/ │/'
        `];

        const pipe = $.NSPipe.pipe;
        task.standardOutput = pipe;
        task.launch;

        const data = pipe.fileHandleForReading.readDataToEndOfFile;
        return $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js.trim();
    }

    // Initial run
    checkDNSRecords();

    // Set up timer to run every 5 seconds
    while (true) {
        $.NSRunLoop.currentRunLoop.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(5));
        checkDNSRecords();
    }
}

function appendStyledText(attrString, text, color) {
    const attributes = $.NSMutableDictionary.alloc.init;
    attributes.setObject_forKey(color, 'NSForegroundColorAttributeName');
    const newString = $.NSAttributedString.alloc.initWithString_attributes(text, attributes);
    attrString.appendAttributedString(newString);
}
