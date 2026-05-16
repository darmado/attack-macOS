# Standard: Python (maintainer `cicd/`)

## Purpose

Define required practices for maintainer Python under `cicd/`: CLI parsing, input checks, shared modules, and converter layout so scripts stay consistent and safe for pipeline use.

## Requirements

- Parse CLI with `argparse` (or equivalent structured parsing). Do not hand-roll `sys.argv` splitting for subcommands without validating tokens.
- For user-controlled URLs, stems, and refs: use `cicd/validate_input.py` (`validate_*` as `type=`) or equivalent checks; see `docs/CICD/python_cli_security.md` for full rules.
- Subprocess: `subprocess.run(..., shell=False)` with a fixed argv list; never route user strings through `shell=True`.
- Converters: shared URL and YAML helpers belong in `cicd/convert/convert_common.py`; URL constants at module level or in `convert_common`, not buried inside functions (per `AGENTS.md`).
- New converter scripts: metadata docstring header (`Name`, `Author`, `License`, `Repository`, `Description`); complete work only after `python3 cicd/build/procedure_shell.py --validate` on a sample draft.

## References

- `docs/CICD/python_cli_security.md`
- `cicd/validate_input.py`
- `cicd/convert/convert_common.py`
- `AGENTS.md`
- `.cursor/rules/attack-macos-maintainer.mdc`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.0.0
