# Atomic Red Team → attack-macOS procedures

## Purpose

Describe how Atomic Red Team YAML differs from attack-macOS procedure YAML, which `cicd/` tools fetch or convert ART material, and how maintainers use standby output before authoring in `core/config/`.

Atomic Red Team (ART) stores **technique-level YAML** with many **atomic_tests** per file. attack-macOS stores **procedure-level YAML** merged into shell/JXA by `cicd/build/`. There is **no** automated ART → `procedure.schema.json` converter in-tree; maintainers use sync + extract for **coverage hints**, then author native macOS procedures.

## Upstream shape (summary)

- Top-level: `attack_technique`, `display_name`, `atomic_tests`.
- Each test: `name`, `description`, `supported_platforms`, `input_arguments`, `executor` (`name`, `command`, optional `cleanup_command`, `elevation_required`), dependencies, etc.
- Commands use ART placeholders (`#{output_file}`) and mixed platforms (Windows, Linux, macOS).

## What the repo provides

| Step | Tool |
|------|------|
| Fetch macOS-only `atomics/` | `python3 cicd/fetch/fetch_atomic_red_team.py --all` downloads `atomics/Indexes/macos-index.yaml`, filters `supported_platforms` for `macos`, optionally **`--executor`** by ART `executor.name`, writes `standby/AtomicRedTeam/atomics/<TTP>/<TTP>_<sanitized_mitre_technique_title>.yaml`, and prints the same summary JSON to stdout as `index_summary.json`. This **does not** produce runnable attack-macOS procedures—only upstream-shaped YAML for review. |
| Convert one Atomic test to draft procedure YAML | `python3 cicd/convert/convert_atomic_to_procedure.py standby/AtomicRedTeam/atomics/<TTP>/<file>.yaml` (optional selectors: `--test-guid`, `--test-name`, `--test-index`; output defaults to `standby/AtomicRedTeam/staging/`) |
| Keep a local source snapshot | `--all` writes `standby/AtomicRedTeam/macos-index.yaml` and `index_summary.json` |
| Search / list | `--search`, `--ttp`, `--tactic` (combinable); `--format` table/json/csv; `--local` uses cached index only |

Optional **`--executor`** (repeat or comma-separated) narrows to ART `executor.name` values such as `sh`, `bash`, `powershell`, `manual`, etc. Use **`--list-executors`** to print distinct names seen on macOS tests in the index.

## Porting checklist (human)

1. Pick an ATT&CK ID and confirm intent against [Enterprise / macOS](https://attack.mitre.org/matrices/enterprise/macos/).
2. Rewrite commands using **native macOS** paths and tooling; drop Linux-only branches unless you intentionally document a non-macOS path.
3. Map to **procedure YAML** (`procedure_name`, `tactic`, `ttp_id`, `functions`, …) per existing config examples under `attackmacos/core/config/`.
4. Set **`credit`** / **`resources`** to cite [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) and the specific `auto_generated_guid` when a test was adapted.
5. Run `python3 cicd/build/procedure_shell.py …` and `sh cicd/qa/run_local_qa.sh`.

## License

ART is distributed under the **MIT License**; attribute Red Canary / the ART project when publishing derived procedure text.
