# Create a New TTP Fast

Short path for a new procedure. When you are driving from a **MITRE ATT&CK technique** (naming, intent, verification order), read [Add a Procedure from MITRE ATT&CK.md](Add%20a%20Procedure%20from%20MITRE%20ATT&CK.md) first. For field-by-field detail, use [Add a New Procedure in YAML.md](Add%20a%20New%20Procedure%20in%20YAML.md).

## 5-Minute Flow

1. Copy the template and rename it:

```bash
cp attackmacos/core/templates/procedure.yml attackmacos/core/config/<procedure_name>.yml
```

2. Fill only these required fields first:
   - `procedure_name` (example: `system_time`)
   - `ttp_id` (example: `T1124`)
   - `tactic` (example: `Discovery` — MITRE display name; must match schema enum)
   - `platform: [darwin]` (required by schema; do not use `macOS`)
   - `guid` — replace placeholder with a real UUID4 (for example `uuidgen` on macOS, or `python3 -c "import uuid; print(uuid.uuid4())"`)
   - `intent`
   - `author`
   - `version`
   - `created` (YYYY-MM-DD)
   - `updated` (YYYY-MM-DD; builder may refresh when you compile)

Schema reference: `attackmacos/core/schemas/procedure.schema.json`. For technique intent and citations, align with [R&D References.md](../../R&D%20References.md) and MITRE pages.

3. Add 1-3 arguments in `procedure.arguments`:
   - Each argument must use `--long-option` format
   - Each argument should call at least one function via `execute_function`

4. Add function code in `procedure.functions`:
   - Use `printf` output in pipe format: `TYPE|PATTERN|RESULT`
   - End each function with `return 0`
   - Set `language: ["shell"]`
   - Set `opsec.check_fda.enabled` (`true` only if protected locations are needed)

5. Validate and build:

```bash
python3 -m venv cicd/venv
cicd/venv/bin/pip install pyyaml jsonschema
cicd/venv/bin/python3 cicd/build/build_shell_procedure.py --validate attackmacos/core/config/<procedure_name>.yml
cicd/venv/bin/python3 cicd/build/build_shell_procedure.py attackmacos/core/config/<procedure_name>.yml
# Overwrite an existing generated script: add --force before the YAML path
```

6. **Syntax / lint:** The build step above already runs **`sh -n`** on the generated script (same check as `--lint-local`). You do **not** need a separate lint command unless you want to re-verify without rebuilding.

Optional re-check only:

```bash
./attackmacos/attackmacos.sh --lint-local --tactic <tactic_slug> --ttp <procedure_name>
```

Use the tactic **slug** from `./attackmacos/attackmacos.sh --help` (for example `discovery`). Generated scripts live under `attackmacos/ttp/<tactic_slug>/shell/`.

Optional: print script help:

```bash
bash attackmacos/ttp/<tactic_slug>/shell/<procedure_name>.sh --help
```

## Dependency Model (Project Standard)

- Runtime TTP behavior should use macOS-native tooling (LOLBins) only.
- Do not require extra runtime downloads for procedure execution.
- Python packages (`pyyaml`, `jsonschema`) are build-time dependencies for YAML compilation only.
- Prefer existing `CMD_*` variables from `attackmacos/core/base/base.sh` to keep command usage standardized.
- Builder validation warns when function code directly invokes commands in `$()` without using `CMD_*` wrappers.

## Pick a TTP Quickly

To find uncovered candidates:

- Check `README.md` or [`docs/MITRE ATT&CK/macOS Procedure Matrix.md`](../MITRE%20ATT&CK/macOS%20Procedure%20Matrix.md)
- Choose a technique marked with `-` (not implemented)
- Confirm no existing config uses it:

```bash
rg "^ttp_id:\\s*T1124" attackmacos/core/config
```

If no match, it is a valid new candidate.

## Keep It Simple Rule

Start with one useful behavior and one `--all` wrapper option. Add complexity later after the script is built and testable.
