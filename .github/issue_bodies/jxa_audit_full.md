## Bug Description

Local QA runs `python3 cicd/audit/audit_jxa.py --full`, which fails on legacy persistence JXA under `attackmacos/ttp/persistence/jxa/`.

## Steps to Reproduce

1. Clone the repository and install Python dependencies used by QA (`pyyaml`, `jsonschema`, etc.).
2. From the repository root, run either:
   - `sh cicd/qa/run_local_qa.sh`, **or**
   - `python3 cicd/audit/audit_jxa.py --full`
3. Observe a non-zero exit after the JXA audit step.

## Expected Behavior

`python3 cicd/audit/audit_jxa.py --full` exits **0**, or project policy explicitly documents a narrower audit scope for persistence JXA and QA/CI match that policy.

## Technical Error Details

- **Auditor:** `cicd/audit/audit_jxa.py` (`--full` scans all `attackmacos/ttp/**/jxa/*.js`).
- **Rules:** Forbidden patterns include `includeStandardAdditions=true`, `doShellScript`, `NSTask`, `system()`, and related shell-out / task APIs; each file must include `ObjC.import('Foundation')` (see `FORBIDDEN` and `REQUIRE_OBJC` in the script).
- **Scope of this failure:** In the observed run, every violation path is under `attackmacos/ttp/persistence/jxa/`.

## Raw Error Output

Representative output (paths depend on clone location; run `python3 cicd/audit/audit_jxa.py --full` locally for the exact lines from your machine).

```
JXA audit FAILED:

attackmacos/ttp/persistence/jxa/AtomPersist.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/BashProfilePersist.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/CalendarPersist.js: forbidden pattern: doShellScript (StandardAdditions shell-out)
attackmacos/ttp/persistence/jxa/CalendarPersist.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/CalendarPersist.js: missing ObjC.import('Foundation') (required for ttp JXA)
attackmacos/ttp/persistence/jxa/CronJobPersistence.js: forbidden pattern: doShellScript (StandardAdditions shell-out)
attackmacos/ttp/persistence/jxa/CronJobPersistence.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/DockPersist.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/DockPersist.js: forbidden pattern: NSTask
attackmacos/ttp/persistence/jxa/DylibHijackScan.js: forbidden pattern: doShellScript (StandardAdditions shell-out)
attackmacos/ttp/persistence/jxa/DylibHijackScan.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/DylibHijackScan.js: forbidden pattern: NSTask
attackmacos/ttp/persistence/jxa/FinderSyncPlugins.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/FinderSyncPlugins.js: forbidden pattern: NSTask
attackmacos/ttp/persistence/jxa/InjectCheck.js: missing ObjC.import('Foundation') (required for ttp JXA)
attackmacos/ttp/persistence/jxa/JamfInfo.js: missing ObjC.import('Foundation') (required for ttp JXA)
attackmacos/ttp/persistence/jxa/LoginScript.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/OutlookUpdatePrompt.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/PasswordSpray.js: missing ObjC.import('Foundation') (required for ttp JXA)
attackmacos/ttp/persistence/jxa/PeriodicPersist.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/PrivilegedHelperToolSpoof.js: forbidden pattern: doShellScript (StandardAdditions shell-out)
attackmacos/ttp/persistence/jxa/PrivilegedHelperToolSpoof.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/SSHrc.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/ScreenSaverPersist.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/ScreenSaverPersist.js: forbidden pattern: NSTask
attackmacos/ttp/persistence/jxa/SublimeTextAppScriptPersistence.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/SublimeTextAppScriptPersistence.js: forbidden pattern: system()
attackmacos/ttp/persistence/jxa/SublimeTextPluginPersistence.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/TermPref.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/TermPref.js: forbidden pattern: NSTask
attackmacos/ttp/persistence/jxa/VimPluginPersistence.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/iTermAppScript.js: forbidden pattern: includeStandardAdditions=true (enables doShellScript and other non-ObjC bridges)
attackmacos/ttp/persistence/jxa/iTermAppScript.js: forbidden pattern: system()
```

## Short Term Fix / Workaround

- Run `python3 cicd/audit/audit_jxa.py` **without** `--full` (default scope is `attackmacos/ttp/collection/jxa/*.js` only) to get a green static audit for that subset.
- `SKIP_JXA_SELFTEST=1` only skips the **JXA builder self-test** (`procedure_jxa.py --self-test`); it does **not** skip `audit_jxa.py --full`. There is currently no env flag to skip the full static audit in `run_local_qa.sh`.

## Additional Context

- `cicd/audit/audit_jxa.py` documents that `--full` may fail on legacy persistence JXA until refactored.
- Default (non-`--full`) audit keeps CI green for `collection/jxa` while persistence debt remains.
