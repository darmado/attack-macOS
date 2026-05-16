# Coding and documentation standards

## Purpose

Single entry for **normative** rules (what must be true) versus **guides** (how to do work). Guides live under `docs/Guides/`; this tree holds the standards index and language-specific requirements for attack-macOS.

Project documentation under `docs/` uses **`## Purpose`** immediately after the document title (H1). Older **`### Purpose`** headings in function references were normalized to **`## Purpose`** where they introduced the page.

## Norms

- **`docs/Guides/`** — Workflows, how-tos, examples. Follow them for day-to-day authoring.
- **`docs/Standards/`** (this folder) — Required conventions for code and docs touched by maintainers and automation.

## Index

| Document | Applies to |
|----------|------------|
| [Python — maintainer `cicd/`](Python_maintainer_cicd.md) | `cicd/**/*.py`: argparse, URLs, shared `validate_input`, converters |
| [Shell — generated TTP scripts](Shell_generated_TTP.md) | Output under `attackmacos/ttp/**/shell/`, `base.sh`, POSIX targets |
| [JXA — TTP scripts](JXA_TTP_scripts.md) | `attackmacos/ttp/**/jxa/*.js`, builder, `audit_jxa.py` |
| [YAML — procedure authoring](YAML_procedure_authoring.md) | `attackmacos/core/config/*.yml`, `procedure.schema.json`, builders |

## Source documents (authoritative text)

Standards in this folder **summarize and point**; they do not replace these files:

- `docs/Guides/Naming Conventions.md` — variables, functions, tactics
- `docs/Guides/Shell Style Guide(old).md` — POSIX shell habits for generated scripts
- `docs/Guides/JXA Style Guide.md`, `docs/Guides/JXA Debug Guide.md` — JXA
- `docs/CICD/python_cli_security.md` — maintainer Python CLI safety
- `docs/CICD/build_shell_procedure.md`, `docs/CICD/build_jxa_procedure.md` — builders
- `attackmacos/core/schemas/procedure.schema.json` — procedure YAML schema
- `AGENTS.md`, `.cursor/rules/attack-macos-maintainer.mdc` — automation agents (maintainer-only)

## References

- `docs/Guides/README.md`
- `cicd/README.md`
- `docs/Shipped_procedures_upstream_sources_and_maintainer_scripts.md`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.0.1
