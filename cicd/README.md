# CI/CD Tools Directory

Automation scripts for attack-macOS maintenance: **build** (artifact generation), **audit** (static checks), **fetch** (source retrieval), **extract** (subset extraction), **convert** (schema transforms), **sync** (metadata/doc sync), and **commit** (optional YAML/script pairing helper).

**Shipped procedures, upstreams, and maintainer scripts:** [`../docs/Shipped_procedures_upstream_sources_and_maintainer_scripts.md`](../docs/Shipped_procedures_upstream_sources_and_maintainer_scripts.md).

**Coding standards (normative index):** [`../docs/Standards/README.md`](../docs/Standards/README.md).

## Layout

| Directory | Scripts |
|-----------|---------|
| **`cicd/build/`** | `procedure_shell.py`, `procedure_jxa.py`, `procedure_metadata.py`, `decrypt.py`, `fixtures/` |
| **`cicd/audit/`** | `audit_jxa.py`, `audit_procedure_inventory.py`, `inventory_allowlist.txt` |
| **`cicd/fetch/`** | `fetch_atomic_red_team.py`, `fetch_loobins.py` |
| **`cicd/extract/`** | `extract_loobin_from_json.py` |
| **`cicd/convert/`** | `convert_loobin_to_procedure.py`, `convert_atomic_to_procedure.py`, `convert_common.py` |
| **`cicd/sync/`** | `sync_function_docs.py` |
| **`cicd/commit/`** | `commit_pairs.py` |
| **`cicd/qa/`** | `run_local_qa.sh` — run before a PR (inventory, YAML validate, JXA audit, optional macOS JXA self-test) |
| **`cicd/gh/`** | `github_issues.py` — `gh issue` helper: `create` → `gh issue create`, `presets` → list `known_issues.yaml` ([`cicd/gh/README.md`](gh/README.md), [`docs/Integrations/github_repo_interaction.md`](../docs/Integrations/github_repo_interaction.md), [third-party baseline](../docs/Integrations/third_party_security.md)) |

Documentation for individual tools lives under **`docs/CICD/`** (not under `cicd/docs/`). **Pre-PR QA checklist:** [local_qa.md](../docs/CICD/local_qa.md). **Python CLI safety (maintainers):** [python_cli_security.md](../docs/CICD/python_cli_security.md).

**Coverage (ATT&CK ↔ scripts):** the maintained badge matrix and script links live in **[macOS Procedure Matrix](../docs/MITRE%20ATT&CK/macOS%20Procedure%20Matrix.md)** under `docs/MITRE ATT&CK/` — link there instead of duplicating coverage tables in this file.

## Tools

### Build (`cicd/build/`)

- **[procedure_shell.py](../docs/CICD/build_shell_procedure.md)** — Merges YAML with `attackmacos/core/base/base.sh`; runs `sh -n` on output.
- **[procedure_jxa.py](../docs/CICD/build_jxa_procedure.md)** — Merges YAML with `attackmacos/core/base/base.js`; `osascript` smoke + `audit/audit_jxa.py`.
- **decrypt.py** — Decrypts data produced by attack-macOS scripts (see project docs if linked).

### Audit (`cicd/audit/`)

- **audit_jxa.py** — Static rules for JXA (default: `attackmacos/ttp/collection/jxa/*.js`). Forbids `doShellScript`, `includeStandardAdditions=true`, `NSTask`, etc.; requires `ObjC.import('Foundation')`. **`python3 cicd/audit/audit_jxa.py --full`** scans all `attackmacos/ttp/**/jxa/*.js`.
- **audit_procedure_inventory.py** — Compares `attackmacos/core/config/*.yml` `procedure_name` + `tactic` to expected `attackmacos/ttp/<tactic>/shell/<procedure_name>.sh`, and lists shell scripts with no matching YAML. **`python3 cicd/audit/audit_procedure_inventory.py --strict`** exits 0 when there are no missing builds and no unlisted orphan scripts; optional stems live in **`inventory_allowlist.txt`**. Use **`--strict --no-inventory-allowlist`** to fail on any orphan (for example before release).

### Fetch (`cicd/fetch/`)

- **fetch_loobins.py** — LOOBins fetch (one tool, two subcommands): **`catalog`** → `loobins.json`; **`binary <name>`** → one canonical YAML from GitHub raw. See [python_cli_security.md](../docs/CICD/python_cli_security.md) for CLI input validation expectations.
- **fetch_atomic_red_team.py** — Fetches ART `macos-index.yaml` and writes trimmed ART-shaped YAML to standby (not procedure templates, not built scripts). **`--all`**, queries **`--search` / `--ttp` / `--tactic`**, **`--list-executors`**, optional **`--executor`** filter, **`--format`**, **`-l`**. Log: `logs/cicd/fetch_atomic_red_team_<timestamp>.log`. **`python3 cicd/fetch/fetch_atomic_red_team.py`**. See `docs/CICD/ART_to_Procedure.md` and `attackmacos/standby/AtomicRedTeam/README.md`.

### Extract (`cicd/extract/`)

- **extract_loobin_from_json.py** — Writes one `standby/LOOBins/<name>.yml` from a catalog entry in `loobins.json`.

### Convert (`cicd/convert/`)

- **convert_loobin_to_procedure.py** — LOOBin YAML → draft procedure YAML; see `docs/CICD/LOOBins_to_Procedure_Mapping.md` and `attackmacos/standby/README.md`.
- **convert_atomic_to_procedure.py** — Atomic Red Team standby YAML → draft procedure YAML (select by `--test-guid`, `--test-name`, or `--test-index`) with tactic inference from `standby/AtomicRedTeam/macos-index.yaml`.
- **convert_common.py** — Shared helpers/constants for converters (YAML I/O, URLs, tactic normalization, `$CMD_*` wrapping).

### Sync (`cicd/sync/`)

- **sync_function_docs.py** — Syncs `base.sh` function bodies into `docs/` (see [sync_function_docs.md](../docs/CICD/sync_function_docs.md)).

### Commit (`cicd/commit/`)

- **commit_pairs.py** — Helper for YAML + generated script commit flows (optional).

### Testing / lint

- **`sh cicd/qa/run_local_qa.sh`** — Pre-PR checklist: strict procedure inventory, `procedure_shell.py --validate` on every `attackmacos/core/config/*.yml`, full JXA audit, and (on macOS only) `procedure_jxa.py --self-test`. Set `SKIP_JXA_SELFTEST=1` to skip the osascript step. Uses `PYTHON` if set (default `python3`).
- **`python3 cicd/gh/github_issues.py`** — GitHub Issues via `gh`: **`create <preset>`** (→ `gh issue create`), **`presets`** (list `cicd/gh/known_issues.yaml`). Example: **`create jxa-audit-full`** for the JXA `--full` audit preset. Requires `gh` + auth except `--dry-run` / `presets`. See [`cicd/gh/README.md`](gh/README.md), [`docs/Integrations/github_repo_interaction.md`](../docs/Integrations/github_repo_interaction.md), and [`docs/Integrations/third_party_security.md`](../docs/Integrations/third_party_security.md).
- **`./attackmacos/attackmacos.sh --lint-local`** — Resolve one built TTP and run `sh -n` (syntax only).
- **test_script_options.dev.sh** — Optional deeper option checks (see [test_script_options.md](../docs/CICD/test_script_options.md)) if present in your checkout.

### Third-party content

- **Caldera:** `python3 cicd/build/procedure_shell.py --sync-caldera` (output under `integrations/caldera/plugins/attackmacos/`).
- **Atomic Red Team:** Optional fetch into standby via `python3 cicd/fetch/fetch_atomic_red_team.py`; still **human** port into `core/config/` (see `docs/CICD/ART_to_Procedure.md`).

## Quick start (from repo root)

```bash
# Python deps: pip install pyyaml jsonschema  (or use cicd/venv if you maintain one)

python3 cicd/build/procedure_shell.py --all
python3 cicd/build/procedure_jxa.py --self-test
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
│   ├── procedure_shell.py
│   ├── procedure_jxa.py
│   ├── procedure_metadata.py
│   ├── decrypt.py
│   └── fixtures/
│       └── jxa_procedure_minimal.yml
├── qa/
│   └── run_local_qa.sh
├── audit/
│   ├── audit_jxa.py
│   ├── audit_procedure_inventory.py
│   └── inventory_allowlist.txt
├── fetch/
│   ├── fetch_atomic_red_team.py
│   └── fetch_loobins.py
├── extract/
│   └── extract_loobin_from_json.py
├── convert/
│   ├── convert_loobin_to_procedure.py
│   ├── convert_atomic_to_procedure.py
│   └── convert_common.py
├── sync/
│   └── sync_function_docs.py
├── commit/
│   └── commit_pairs.py
└── venv/                    # optional local venv
```
