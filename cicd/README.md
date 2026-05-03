# CI/CD Tools Directory

Automation scripts for attack-macOS maintenance: **build** (shell/JXA from YAML), **audit** (static JXA checks), **sync** (docs + LOOBins + converters), **commit** (optional YAML/script pairing helper).

## Layout

| Directory | Scripts |
|-----------|---------|
| **`cicd/build/`** | `build_shell_procedure.py`, `build_jxa_procedure.py`, `decrypt.py`, `fixtures/` (JXA self-test YAML) |
| **`cicd/audit/`** | `audit_jxa.py`, `audit_procedure_inventory.py`, `inventory_allowlist.txt` |
| **`cicd/sync/`** | `sync_function_docs.py`, `sync_loobins_json.sh`, `convert_loobin_to_procedure.py`, `extract_loobin_from_json.py`, `fetch_loobin_yaml_upstream.sh` |
| **`cicd/commit/`** | `commit_pairs.py` |
| **`cicd/qa/`** | `run_local_qa.sh` — run before a PR (inventory, YAML validate, JXA audit, optional macOS JXA self-test) |

Documentation for individual tools lives under **`docs/CICD/`** (not under `cicd/docs/`).

**Coverage (ATT&CK ↔ scripts):** the maintained badge matrix and script links live in **[macOS Procedure Matrix](../docs/MITRE%20ATT&CK/macOS%20Procedure%20Matrix.md)** under `docs/MITRE ATT&CK/` — link there instead of duplicating coverage tables in this file.

## Tools

### Build (`cicd/build/`)

- **[build_shell_procedure.py](../docs/CICD/build_shell_procedure.md)** — Merges YAML with `attackmacos/core/base/base.sh`; runs `sh -n` on output.
- **[build_jxa_procedure.py](../docs/CICD/build_jxa_procedure.md)** — Merges YAML with `attackmacos/core/base/base.js`; `osascript` smoke + `audit/audit_jxa.py`.
- **decrypt.py** — Decrypts data produced by attack-macOS scripts (see project docs if linked).

### Audit (`cicd/audit/`)

- **audit_jxa.py** — Static rules for JXA (default: `attackmacos/ttp/collection/jxa/*.js`). Forbids `doShellScript`, `includeStandardAdditions=true`, `NSTask`, etc.; requires `ObjC.import('Foundation')`. **`python3 cicd/audit/audit_jxa.py --full`** scans all `attackmacos/ttp/**/jxa/*.js`.
- **audit_procedure_inventory.py** — Compares `attackmacos/core/config/*.yml` `procedure_name` + `tactic` to expected `attackmacos/ttp/<tactic>/shell/<procedure_name>.sh`, and lists shell scripts with no matching YAML. **`python3 cicd/audit/audit_procedure_inventory.py --strict`** exits 0 when there are no missing builds and no unlisted orphan scripts; optional stems live in **`inventory_allowlist.txt`**. Use **`--strict --no-inventory-allowlist`** to fail on any orphan (for example before release).

### Sync (`cicd/sync/`)

- **sync_function_docs.py** — Syncs `base.sh` function bodies into `docs/` (see [sync_function_docs.md](../docs/CICD/sync_function_docs.md)).
- **sync_loobins_json.sh** — Downloads the published LOOBins catalog JSON into `attackmacos/standby/LOOBins/loobins.json` (default `https://www.loobins.io/loobins.json`, same project as [infosecB/LOOBins](https://github.com/infosecB/LOOBins)).
- **fetch_loobin_yaml_upstream.sh** — Downloads one upstream YAML from `LOOBins/<name>.yml` on GitHub (raw) into `attackmacos/standby/LOOBins/<name>.yml` when you want the canonical file instead of extracting from JSON.
- **extract_loobin_from_json.py** — Writes one `standby/LOOBins/<name>.yml` from a catalog entry in `loobins.json` (after sync). Names must match the `name` field in JSON (e.g. `dns-sd`, `log`).
- **convert_loobin_to_procedure.py** — LOOBin YAML → draft procedure YAML; see `docs/CICD/LOOBins_to_Procedure_Mapping.md` and `attackmacos/standby/README.md`.

### Commit (`cicd/commit/`)

- **commit_pairs.py** — Helper for YAML + generated script commit flows (optional).

### Testing / lint

- **`sh cicd/qa/run_local_qa.sh`** — Pre-PR checklist: strict procedure inventory, `build_shell_procedure.py --validate` on every `attackmacos/core/config/*.yml`, full JXA audit, and (on macOS only) `build_jxa_procedure.py --self-test`. Set `SKIP_JXA_SELFTEST=1` to skip the osascript step. Uses `PYTHON` if set (default `python3`).
- **`./attackmacos/attackmacos.sh --lint-local`** — Resolve one built TTP and run `sh -n` (syntax only).
- **test_script_options.dev.sh** — Optional deeper option checks (see [test_script_options.md](../docs/CICD/test_script_options.md)) if present in your checkout.

### Third-party content

- **Caldera:** `python3 cicd/build/build_shell_procedure.py --sync-caldera` (output under `integrations/caldera/plugins/attackmacos/`).
- **Atomic Red Team:** No automatic pull; use as reference only.

## Quick start (from repo root)

```bash
# Python deps: pip install pyyaml jsonschema  (or use cicd/venv if you maintain one)

python3 cicd/build/build_shell_procedure.py --all
python3 cicd/build/build_jxa_procedure.py --self-test
python3 cicd/audit/audit_jxa.py
python3 cicd/audit/audit_procedure_inventory.py --strict
sh cicd/qa/run_local_qa.sh
python3 cicd/sync/sync_function_docs.py
```

## Dependencies

- Python 3.6+
- PyYAML, jsonschema (builders + schema validation)
- OpenSSL / GPG for `decrypt.py`

## Directory tree (abbreviated)

```
cicd/
├── README.md
├── build/
│   ├── build_shell_procedure.py
│   ├── build_jxa_procedure.py
│   ├── decrypt.py
│   └── fixtures/
│       └── jxa_procedure_minimal.yml
├── qa/
│   └── run_local_qa.sh
├── audit/
│   ├── audit_jxa.py
│   ├── audit_procedure_inventory.py
│   └── inventory_allowlist.txt
├── sync/
│   ├── sync_function_docs.py
│   ├── sync_loobins_json.sh
│   ├── convert_loobin_to_procedure.py
│   ├── extract_loobin_from_json.py
│   └── fetch_loobin_yaml_upstream.sh
├── commit/
│   └── commit_pairs.py
└── venv/                    # optional local venv
```
