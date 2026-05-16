# Agents / AI assistants

Internal hooks for automated assistants working in this repo — **not** part of the human-facing attack-macOS documentation set.

- **Cursor:** Project rules live in **`.cursor/rules/attack-macos-maintainer.mdc`** (`alwaysApply: true`).
- **Humans:** Use **`docs/Guides/README.md`** for procedures and workflows.

Do not move maintainer-only guidance into `docs/Guides/` as if it were contributor onboarding.

## Converter expectations (agent-facing)

- Keep converter URL references in constants (module-level or `cicd/convert/convert_common.py`), never inline in function bodies.
- Reuse shared converter helpers from `cicd/convert/convert_common.py` before adding source-specific utility functions.
- Preserve consistent converter function names when possible: `map_metadata`, `map_arguments`, `map_global_variables`, `map_functions`, `map_optional_sections`, `convert`.
- Add metadata docstring headers on converter scripts (`Name`, `Author`, `License`, `Repository`, `Description`).
- Treat converter work as complete only after generating a draft and passing `python3 cicd/build/procedure_shell.py --validate`.

## Python CLI tools (maintainer)

- Follow **`docs/CICD/python_cli_security.md`** for argparse usage, URL scheme checks, and allow-lists on path segments / ref tokens in new `cicd/` Python entrypoints.
- Prefer **`cicd/validate_input.py`** (``validate_*`` callables as ``type=``, or post-parse checks + **`parser.error`**) instead of duplicating URL/ref/stem policy across scripts.
- **Procedure provenance:** point humans and reviews to **`docs/Shipped_procedures_upstream_sources_and_maintainer_scripts.md`**.

## Tooling discipline (agent-facing)

- **Do not** add `cicd/import/` orchestrators or similar pipeline-only scripts unless the user explicitly asks. Chain `fetch/` → `extract/` → `convert/` with documented commands instead.

## Naming (agent-facing)

- Follow **`docs/Guides/Naming Conventions.md`**. Module constants and globals must be **explicit about scope** (what file/flow they affect)—avoid ambiguous names (`*_EXISTING`, `*_DATA`, metaphors).
- Human-facing **coding standards index:** **`docs/Standards/README.md`**.
