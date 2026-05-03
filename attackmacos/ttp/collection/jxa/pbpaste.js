/*
 * pbpaste.js — JXA twin for attackmacos/ttp/collection/shell/pbpaste.sh (T1115)
 * Same objective: general pasteboard read for collection emulation; no pbpaste(1) subprocess.
 *
 * Run: osascript -l JavaScript attackmacos/ttp/collection/jxa/pbpaste.js --once
 *      osascript -l JavaScript .../pbpaste.js --monitor --interval 2 --count 3
 *
 * Principles: ObjC bridge only (Foundation + AppKit for NSPasteboard). No doShellScript, NSTask, or shell paths.
 * Output lines match shell script pipe format for shared triage parsers.
 */
(function () {
    ObjC.import('Foundation');
    ObjC.import('AppKit');

    function writeStdout(msg) {
        var h = $.NSFileHandle.fileHandleWithStandardOutput;
        var m = msg === null || msg === undefined ? '' : String(msg);
        var ns = $.NSString.stringWithString(m);
        var d = ns.dataUsingEncoding($.NSUTF8StringEncoding);
        if (d) {
            h.writeData(d);
        }
    }

    function usage() {
        writeStdout(
            'Usage: osascript -l JavaScript pbpaste.js {--once|--monitor} [options]\n' +
                '  --once              One pasteboard read (timestamped line)\n' +
                '  --monitor           Bounded foreground loop\n' +
                '  --interval N        Seconds between reads (default 10)\n' +
                '  --count N           Reads before exit (default 10)\n' +
                '  --path FILE         Append timestamp<TAB>text lines\n' +
                '  -h, --help          This help\n'
        );
    }

    function argvStrings() {
        var pi = $.NSProcessInfo.processInfo;
        var n = pi.arguments.count;
        var out = [];
        var j;
        for (j = 0; j < n; j++) {
            var o = pi.arguments.objectAtIndex(j);
            if (!o) {
                out.push('');
                continue;
            }
            var d = o.description;
            out.push(d && d.js ? d.js : '');
        }
        return out;
    }

    function parseArgv() {
        var raw = argvStrings();
        var i = 0;
        for (; i < raw.length; i++) {
            if (raw[i].indexOf('.js') !== -1) {
                i++;
                break;
            }
        }
        var o = {
            once: false,
            monitor: false,
            interval: 10,
            count: 10,
            path: '',
            help: false,
        };
        for (; i < raw.length; i++) {
            var a = raw[i];
            if (a === '-h' || a === '--help') {
                o.help = true;
            } else if (a === '--once') {
                o.once = true;
            } else if (a === '--monitor') {
                o.monitor = true;
            } else if (a === '--interval' && i + 1 < raw.length) {
                i++;
                o.interval = parseInt(String(raw[i]), 10);
            } else if (a === '--count' && i + 1 < raw.length) {
                i++;
                o.count = parseInt(String(raw[i]), 10);
            } else if (a === '--path' && i + 1 < raw.length) {
                i++;
                o.path = String(raw[i]);
            }
        }
        return o;
    }

    function tsLocal() {
        var df = $.NSDateFormatter.alloc.init;
        df.setLocale($.NSLocale.localeWithLocaleIdentifier('en_US_POSIX'));
        df.setTimeZone($.NSTimeZone.localTimeZone);
        df.setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ");
        var ds = df.stringFromDate($.NSDate.date);
        return ds && ds.js ? ds.js : '';
    }

    function pasteboardText() {
        var pb = $.NSPasteboard.generalPasteboard;
        var s = pb.stringForType('public.utf8-plain-text');
        if (s && s.js) {
            return s.js;
        }
        s = pb.stringForType($.NSPasteboardTypeString);
        if (s && s.js) {
            return s.js;
        }
        return '';
    }

    function utf8ByteLength(text) {
        var t = text === null || text === undefined ? '' : String(text);
        var ns = $.NSString.stringWithString(t);
        return ns.lengthOfBytesUsingEncoding($.NSUTF8StringEncoding);
    }

    function appendLine(path, ts, text) {
        if (!path || path.length === 0) {
            return;
        }
        var p = $(path);
        var fm = $.NSFileManager.defaultManager;
        if (!fm.fileExistsAtPath(p)) {
            fm.createFileAtPathContentsAttributes(p, $.NSData.data, null);
        }
        var h = $.NSFileHandle.fileHandleForWritingAtPath(p);
        if (!h) {
            writeStdout('ERROR|pbpaste|cannot_append|' + path + '\n');
            return;
        }
        h.seekToEndOfFile;
        var tsS = ts === null || ts === undefined ? '' : String(ts);
        var txS = text === null || text === undefined ? '' : String(text);
        var line = $.NSString.stringWithString(tsS + '\t' + txS + '\n');
        h.writeData(line.dataUsingEncoding($.NSUTF8StringEncoding));
        h.closeFile;
    }

    function runOnce(opts) {
        var ts = tsLocal();
        var line = pasteboardText();
        var bytes = utf8ByteLength(line);
        writeStdout('PBPASTE|mode|once|ts|' + ts + '|bytes|' + bytes + '|text|' + line + '\n');
        appendLine(opts.path, ts, line);
    }

    function runMonitor(opts) {
        var iv = opts.interval;
        var cnt = opts.count;
        if (!(iv >= 1) || !(cnt >= 1) || isNaN(iv) || isNaN(cnt)) {
            writeStdout(
                'ERROR|pbpaste|monitor needs positive integers (--interval and --count; default 10 each)\n'
            );
            return 1;
        }
        var pid = $.NSProcessInfo.processInfo.processIdentifier;
        writeStdout(
            'PBPASTE|mode|monitor|pid|' +
                pid +
                '|interval_s|' +
                iv +
                '|count|' +
                cnt +
                '|foreground|true\n'
        );
        var idx;
        for (idx = 1; idx <= cnt; idx += 1) {
            var ts = tsLocal();
            var line = pasteboardText();
            var bytes = utf8ByteLength(line);
            writeStdout(
                'PBPASTE|sample|' + idx + '|' + ts + '|bytes|' + bytes + '|text|' + line + '\n'
            );
            appendLine(opts.path, ts, line);
            if (idx < cnt) {
                $.NSThread.sleepForTimeInterval(iv);
            }
        }
        return 0;
    }

    function main() {
        var opts = parseArgv();
        if (opts.help) {
            usage();
            return 0;
        }
        if (opts.once && opts.monitor) {
            writeStdout('ERROR|pbpaste|choose only one of --once or --monitor\n');
            return 1;
        }
        if (!opts.once && !opts.monitor) {
            usage();
            return 1;
        }
        if (opts.once) {
            runOnce(opts);
            return 0;
        }
        return runMonitor(opts);
    }

    main();
})();
