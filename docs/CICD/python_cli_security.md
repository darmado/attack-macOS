# Python CI tools — CLI and input safety

## Purpose

Norms for maintainer Python under `cicd/` when parsing CLI arguments, handling URLs, and avoiding unsafe subprocess patterns.

## Assumptions

1. Maintainer scripts are run from a controlled checkout by operators who follow `cicd/README.md` and repository guides.
2. Input validation in `cicd/validate_input.py` (where imported) reduces accidental misuse; it does not replace host-level controls described in `SECURITY.md`.
3. Third-party Python packages beyond PyYAML and jsonschema follow whatever versions the project documents for builders and converters.

## Audience

Maintainers and CI authors extending `cicd/` entrypoints.

## Scope

In scope: `argparse`, URL scheme checks, allow-lists for stems and refs, subprocess usage, references to `validate_input.py`.

Out of scope: Procedure provenance (see `docs/Shipped_procedures_upstream_sources_and_maintainer_scripts.md`), runtime execution of generated TTPs on endpoints.

For **`gh` / GitHub** (issue creation, tokens, path allowlists), see **`docs/Integrations/github_repo_interaction.md`**, the **[third-party baseline](../Integrations/third_party_security.md)**, and `cicd/validate_input.py` (`validate_github_issue_*`).

## Details

### Principles

1. **Subprocess** — Use `subprocess.run([...], shell=False)` with a fixed argv list. Do not pass user-controlled strings to `shell=True` or `os.system()`.
2. **Parsing** — Use `argparse` (or equivalent structured parsing). Avoid ad hoc `sys.argv` splitting for subcommands without validating each token.
3. **HTTP clients** — For user-supplied or composed URLs, require `http` or `https` with a non-empty host via `urllib.parse.urlparse`. Reject other schemes unless the tool explicitly documents them.
4. **Path and filename tokens** — When user input becomes a URL path segment or local filename stem, use a conservative allow-list (length and character set). Reject path traversal and unexpected Unicode unless documented.
5. **Default output paths** — Prefer defaults under `attackmacos/standby/` or another fixed tree. Document behavior when operators pass absolute paths.
6. **Secrets** — Avoid passing credentials on the CLI where they appear in shell history; prefer environment variables or platform keychain patterns if authentication is added.
7. **Dependencies** — Document Python package expectations in `cicd/README.md` or venv docs; prefer stdlib plus PyYAML for small fetch and convert tools.

### Reference usage

- Policy constants and `validate_*` callables: `cicd/validate_input.py` (use as `argparse` `type=` or validate after `parse_args()` and call `parser.error()` when defaults bypass `type=`).
- Examples: `cicd/fetch/fetch_loobins.py`, `cicd/fetch/fetch_atomic_red_team.py`, `cicd/gh/github_issues.py` (GitHub issue presets: `validate_github_issue_*`).

## Exceptions

- A tool may document a deliberate exception (for example, a local file path scheme) when required by its contract.

## References

- `docs/Standards/README.md`
- `cicd/validate_input.py`
- `cicd/README.md`
- `SECURITY.md`
- `docs/Shipped_procedures_upstream_sources_and_maintainer_scripts.md`
- `docs/Integrations/github_repo_interaction.md`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.2.0
