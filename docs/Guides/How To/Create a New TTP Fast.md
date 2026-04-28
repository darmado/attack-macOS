# Create a New TTP Fast

Use this when you want to create a new procedure quickly without reading the full guide.

## 5-Minute Flow

1. Copy the template and rename it:

```bash
cp attackmacos/core/templates/procedure.yml attackmacos/core/config/<procedure_name>.yml
```

2. Fill only these required fields first:
   - `procedure_name` (example: `system_time`)
   - `ttp_id` (example: `T1124`)
   - `tactic` (example: `Discovery`)
   - `guid: $GUID`
   - `intent`
   - `author`
   - `version`
   - `created` (YYYY-MM-DD)
   - `updated: $UPDATED`

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
cicd/venv/bin/python3 cicd/build_shell_procedure.py --validate attackmacos/core/config/<procedure_name>.yml
cicd/venv/bin/python3 cicd/build_shell_procedure.py attackmacos/core/config/<procedure_name>.yml
```

6. Smoke test:

```bash
bash attackmacos/ttp/<tactic_dir>/shell/<procedure_name>.sh --help

## Dependency Model (Project Standard)

- Runtime TTP behavior should use macOS-native tooling (LOLBins) only.
- Do not require extra runtime downloads for procedure execution.
- Python packages (`pyyaml`, `jsonschema`) are build-time dependencies for YAML compilation only.
- Prefer existing `CMD_*` variables from `attackmacos/core/base/base.sh` to keep command usage standardized.
- Builder validation now warns when function code directly invokes commands in `$()` without using `CMD_*` wrappers.
```

## Pick a TTP Quickly

To find uncovered candidates:

- Check `README.md` or `docs/MITRE ATT&CK/macOS Procedure Matrix.md`
- Choose a technique marked with `-` (not implemented)
- Confirm no existing config uses it:

```bash
rg "^ttp_id:\\s*T1124" attackmacos/core/config
```

If no match, it is a valid new candidate.

## Keep It Simple Rule

Start with one useful behavior and one `--all` wrapper option. Add complexity later after the script is built and testable.
