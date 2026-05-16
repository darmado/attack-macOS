# Atomic Red Team — standby queue

Upstream publishes **`atomics/Indexes/macos-index.yaml`** ([raw link](https://raw.githubusercontent.com/redcanaryco/atomic-red-team/refs/heads/master/atomics/Indexes/macos-index.yaml)). **Attack-macOS** **fetches** that index, keeps entries whose atomic tests list **macOS**, and writes per-technique YAML under `atomics/`. This is **not** a procedure build: output stays ART-shaped and is **not** merged with `base.sh`, `procedure.schema.json`, or builders.

**Human gate:** ART executors, `#{input_arguments}`, and mixed-platform bodies still need maintainer review before promotion into `attackmacos/core/config/`.

## License / credit

Upstream is **MIT** — see [atomic-red-team LICENSE](https://github.com/redcanaryco/atomic-red-team/blob/master/LICENSE).

## Layout

| Path | Role |
|------|------|
| `macos-index.yaml` | Cached upstream index snapshot (written on `--all`). |
| `index_summary.json` | Counts from the last **`--all`** run (`executors_filter`, tactic counts, plus **`kept_tests_heuristic_remote_or_prereq_signals`** and **`heuristic_remote_signal_counts`** — substring scan for `curl`/`wget`/URLs/ART `dependencies`; see **`heuristic_note`** inside the JSON). |
| `atomics/` | Normalized per-technique YAML; gitignored. Each file is **`atomics/<TTP>/<TTP>_<mitre_technique_title>.yaml`** — the suffix is the MITRE technique **display name** from the index (spaces and unsafe characters become **`_`**). Example: `atomics/T1049/T1049_System_Network_Connections_Discovery.yaml`. |
| `snippets/` | **Legacy:** older tooling wrote flat `*_macos.yml` copies here; that step was removed. Nothing writes here anymore; folder is gitignored. Safe to delete locally. |

## CLI (`cicd/fetch/fetch_atomic_red_team.py`)

Running **with no arguments** prints **help** (same as `-h` / `--help`).

| Mode | Purpose |
|------|---------|
| **`--all`** | Download index, filter macOS tests, write `atomics/`, `macos-index.yaml`, `index_summary.json`. Prints the summary JSON to stdout after counts (same payload as `index_summary.json`). |
| **`--list-executors`** | Print distinct ART `executor.name` values seen on macOS-listed tests (uses cached index when **`--local`**). Cannot combine with **`--all`**, **`--search`**, **`--ttp`**, or **`--tactic`**. |
| **`--search PATTERN`** | Table (or json/csv) of matching TTPs: fnmatch-style **`*`** / **`?`** against id, technique name, tactic, atomic test name. |
| **`--ttp ID`** | One technique (e.g. `T1049`). |
| **`--tactic NAME`** | Filter by index tactic key (**lowercase**, e.g. `discovery`). Combines with `--search` / `--ttp`. |

Shared flags (aligned with TTP scripts):

| Flag | Purpose |
|------|---------|
| **`--format` / `--output-format`** | Query output: `table` (default), `json`, `csv`. |
| **`-l` / `--log`** | Audit log under `logs/cicd/fetch_atomic_red_team_<UTC timestamp>.log` (mirrors stdout). |
| **`--executor NAME`** | Keep only tests whose ART `executor.name` matches (repeat or comma-list), e.g. **`--executor sh,bash`**. Use **`--list-executors`** to discover values. Applies to **`--all`** and to queries. |
| **`--dry-run`** | With **`--all`**: counts + summary preview only; no `atomics/` writes. |
| **`--local`** | Use cached **`--index-file`** only (no HTTP); file must exist. |

### Examples

```sh
# help (default when run with no args)
python3 cicd/fetch/fetch_atomic_red_team.py

# full fetch + print summary JSON to terminal
python3 cicd/fetch/fetch_atomic_red_team.py --all

# shell-family tests only (repeat or comma-list)
python3 cicd/fetch/fetch_atomic_red_team.py --all --executor sh,bash

# queries (fresh download unless --local)
python3 cicd/fetch/fetch_atomic_red_team.py --tactic discovery
python3 cicd/fetch/fetch_atomic_red_team.py --ttp T1049 --format json
python3 cicd/fetch/fetch_atomic_red_team.py --search '*DNS*'
python3 cicd/fetch/fetch_atomic_red_team.py --tactic discovery --search '*network*' --format csv

# offline: list executor names from cached index
python3 cicd/fetch/fetch_atomic_red_team.py --list-executors --local

python3 cicd/fetch/fetch_atomic_red_team.py --local --tactic stealth --format table

# audit trail
python3 cicd/fetch/fetch_atomic_red_team.py --all -l
```

Use **`python3`** only (no shell wrapper); dependencies are **stdlib + PyYAML** (same as the rest of `cicd/`).

Field mapping: [docs/CICD/ART_to_Procedure.md](../../../docs/CICD/ART_to_Procedure.md).
