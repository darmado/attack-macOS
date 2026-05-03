# Guides

Authoritative workflow and style documentation for the attack-macOS project. **Read this tree** when authoring YAML procedures, changing `base.sh`, or integrating tooling so runtime behavior and build steps stay consistent.

Maintainers extending CI should follow **`cicd/README.md`**: scripts live under **`cicd/build/`**, **`cicd/audit/`**, **`cicd/sync/`**, and **`cicd/commit/`** (avoid overlapping entrypoints; extend existing builders where possible).

## Read first (workflows)

| Guide | When to use it |
|--------|----------------|
| [How To/Add a Procedure from MITRE ATT&CK.md](How%20To/Add%20a%20Procedure%20from%20MITRE%20ATT&CK.md) | **Start here** when grounding a new procedure in a MITRE technique: intent-first naming, logic map, verify-before-import |
| [How To/Create a New TTP Fast.md](How%20To/Create%20a%20New%20TTP%20Fast.md) | New YAML procedure → generated shell TTP (most common) |
| [How To/Add a New Procedure in YAML.md](How%20To/Add%20a%20New%20Procedure%20in%20YAML.md) | Full field reference, arguments, functions, edge cases |
| [How To/Add a New Base Feature.md](How%20To/Add%20a%20New%20Base%20Feature.md) | Changing shared runtime in `attackmacos/core/base/base.sh` |
| [How To/Enhance a Base Feature.md](How%20To/Enhance%20a%20Base%20Feature.md) | Extending an existing pipeline feature (encode/encrypt/exfil, etc.) |
| [How To/Add Encryption Methods to base.sh.md](How%20To/Add%20Encryption%20Methods%20to%20base.sh.md) | Narrow guide for new `--encrypt` methods |

## Procedure shape (shell vs JXA)

- **Shell procedures** — YAML under `attackmacos/core/config/` with `language: [shell]` functions; **`cicd/build/build_shell_procedure.py`** emits merged **`attackmacos/ttp/<tactic>/shell/<name>.sh`** on top of `base.sh`. This is the default path for LOLBins and terminal-native techniques.
- **JXA procedures** — Same MITRE technique and **same operator intent** as the shell twin: **1:1 objective** (variant execution chain only—like choosing a different encrypt or exfil option). Prefer **Foundation / AppKit (and peers) via `ObjC.import`** over shell-outs. Implement under **`attackmacos/ttp/<tactic>/jxa/<Name>.js`** following [JXA Style Guide.md](JXA%20Style%20Guide.md), [JXA Debug Guide.md](JXA%20Debug%20Guide.md), and [../Functions/Shell/JXA Script Blueprint.md](../Functions/Shell/JXA%20Script%20Blueprint.md). YAML-driven output merges **`attackmacos/core/base/base.js`** with **`python3 cicd/build/build_jxa_procedure.py`** (see [../CICD/build_jxa_procedure.md](../CICD/build_jxa_procedure.md)). Where shell coverage is ahead of JXA, add JXA siblings deliberately rather than one-off scripts with divergent goals. **QA:** run **`python3 cicd/audit/audit_jxa.py`** (and `osascript -l JavaScript …` smoke tests) on new JXA; extend rules in `cicd/audit/audit_jxa.py` as principles harden.

## Cross-cutting rules (non-negotiable for new TTPs)

1. **Runtime is native macOS only** — Procedures execute with built-in / LOLBin commands. No extra downloads on the target for technique execution.
2. **Build-time Python OK** — `cicd/build/build_shell_procedure.py` uses PyYAML + jsonschema; that is developer-side only.
3. **Validate and lint** — After YAML edits: `--validate` → build (build runs **`sh -n`** automatically). Optional: `./attackmacos/attackmacos.sh --lint-local ...` to re-check without rebuilding.
4. **Sourcing and citations** — See [R&D References.md](../R&D%20References.md) for MITRE mapping, blogs, ART/Caldera as reference (not runtime deps).
5. **Schema** — `attackmacos/core/schemas/procedure.schema.json` (e.g. `platform` must include `darwin`).
6. **CI helpers** — New maintenance scripts belong under the appropriate **`cicd/build/`**, **`cicd/audit/`**, **`cicd/sync/`**, or **`cicd/commit/`** folder with a note in `cicd/README.md`. Prefer extending existing builders over one-off scrapers unless documented.

## Style and conventions

| Guide | Topic |
|--------|--------|
| [Naming Conventions.md](Naming%20Conventions.md) | Variables, tactic prefixes (`discover_*`, etc.), builder function names |
| [Shell Style Guide(old).md](Shell%20Style%20Guide(old).md) | POSIX-oriented shell habits (generated scripts target `/bin/sh` compatibility) |
| [JXA Style Guide.md](JXA%20Style%20Guide.md), [JXA Debug Guide.md](JXA%20Debug%20Guide.md) | JavaScript for Automation |
| [Telemetry Management.md](Telemetry%20Management.md), [Offensive_OPSEC_Guide.md](Offensive_OPSEC_Guide.md) | OPSEC / collection considerations |

## Topic references (not step-by-step onboarding)

- [Process Spawning.md](Process%20Spawning.md), [Syscalls vs APIs.md](Syscalls%20vs%20APIs.md), [Managing ObjC objects.md](Managing%20ObjC%20objects.md), [Emulating Trust Boundaries.md](Emulating%20Trust%20Boundaries.md)
- TCC: [TCC Checks.md](TCC%20Checks.md), [TCC_Checks.md](TCC_Checks.md), [TCC_Permission_Checking_Techniques.md](TCC_Permission_Checking_Techniques.md) (overlapping JXA/TCC material — consolidate over time if desired)

## Third-party → TTP pipeline (LOOBins)

1. Sync catalog: `bash cicd/sync/sync_loobins_json.sh` (writes `attackmacos/standby/LOOBins/loobins.json`).
2. Convert per-binary YAML, or batch: `python3 cicd/sync/convert_loobin_to_procedure.py --all-standby` → drafts under `attackmacos/standby/LOOBins/staging/`.
3. Edit **`ttp_id`**, review functions, move YAML to `attackmacos/core/config/`, run **`python3 cicd/build/build_shell_procedure.py`** (includes **`sh -n`**).

Details: [attackmacos/standby/README.md](../../attackmacos/standby/README.md), [LOOBins_to_Procedure_Mapping.md](../CICD/LOOBins_to_Procedure_Mapping.md).

## Related project docs

- [docs/CICD/build_shell_procedure.md](../CICD/build_shell_procedure.md) — Builder behavior
- [cicd/README.md](../../cicd/README.md) — venv, lint-local, Caldera sync, third-party policy
