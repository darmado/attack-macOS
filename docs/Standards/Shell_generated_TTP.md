# Standard: Shell (generated TTP scripts)

## Purpose

Define conventions for shell emitted under `attackmacos/ttp/<tactic>/shell/` and shared runtime in `attackmacos/core/base/base.sh`: naming, POSIX expectations, and alignment with the YAML builder.

## Requirements

- Generated scripts target POSIX-friendly `/bin/sh` usage; follow `docs/Guides/Naming Conventions.md` for tactic prefixes and function names.
- Match spacing and patterns produced by `cicd/build/procedure_shell.py` and `base.sh` (see `docs/CICD/build_shell_procedure.md`).
- Prefer native macOS / LOLBin commands at runtime; no extra downloads on target for technique execution unless the procedure explicitly documents otherwise.
- After YAML changes: `python3 cicd/build/procedure_shell.py --validate` then build; build runs `sh -n` on output.

## References

- `docs/Guides/Naming Conventions.md`
- `docs/Guides/Shell Style Guide(old).md`
- `docs/CICD/build_shell_procedure.md`
- `attackmacos/core/base/base.sh`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.0.0
