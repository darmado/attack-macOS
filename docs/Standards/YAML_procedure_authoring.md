# Standard: YAML procedure authoring

## Purpose

Define requirements for procedure YAML under `attackmacos/core/config/`: schema, platform, metadata, and alignment with builders.

## Requirements

- Conform to `attackmacos/core/schemas/procedure.schema.json` (e.g. `platform` includes `darwin`).
- Use MITRE ATT&CK-aligned `ttp_id`, `tactic`, and intent text; naming and function prefixes per `docs/Guides/Naming Conventions.md`.
- Authoring workflow and field reference: `docs/Guides/How To/Add a New Procedure in YAML.md`, `docs/Guides/How To/Create a New TTP Fast.md`.
- Validate with `python3 cicd/build/procedure_shell.py --validate <file>` before relying on generated shell.

## References

- `attackmacos/core/schemas/procedure.schema.json`
- `attackmacos/core/global/functions.yml`
- `attackmacos/core/global/variables.yml`
- `docs/Indexes/README.md`
- `docs/Guides/Naming Conventions.md`
- `docs/Guides/How To/Add a New Procedure in YAML.md`
- `docs/CICD/build_shell_procedure.md`
- `docs/CICD/build_jxa_procedure.md`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.0.1
