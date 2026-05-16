# Standard: JXA (TTP scripts)

## Purpose

Define conventions for JavaScript for Automation under `attackmacos/ttp/<tactic>/jxa/`: imports, forbidden APIs, audit rules, and builder integration.

## Requirements

- Prefer `ObjC.import` of Foundation / AppKit (and peers) over shell-outs; follow `docs/Guides/JXA Style Guide.md` and `docs/Guides/JXA Debug Guide.md`.
- Run `python3 cicd/audit/audit_jxa.py` on changed files; use `--full` when auditing the whole tree. Rules are enforced in `cicd/audit/audit_jxa.py` (e.g. no `doShellScript`, no `includeStandardAdditions=true`, no `NSTask` / obvious shell spawn patterns unless explicitly allowed by project policy).
- Merge and validate via `cicd/build/procedure_jxa.py` per `docs/CICD/build_jxa_procedure.md`.
- See `docs/Functions/Shell/JXA Script Blueprint.md` for structural patterns.

## References

- `docs/Guides/JXA Style Guide.md`
- `docs/Guides/JXA Debug Guide.md`
- `docs/CICD/build_jxa_procedure.md`
- `docs/Functions/Shell/JXA Script Blueprint.md`
- `cicd/audit/audit_jxa.py`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.0.0
