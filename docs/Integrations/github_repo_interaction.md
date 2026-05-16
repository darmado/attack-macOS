# GitHub repository interaction — security minimums

This page is part of the **[third-party security baseline](third_party_security.md)** for repository integrations.

## Purpose

Describe **minimum security expectations** when maintainer tooling under `cicd/gh/` (or future scripts) invoke the **GitHub CLI** (`gh`) or otherwise act on behalf of a human or CI job against **github.com** (or GitHub Enterprise).

This document is **maintainer / automation** guidance. It is not end-user procedure documentation.

## Audience

Operators extending `cicd/gh/`, wiring CI, or running issue automation from a laptop.

## Trust boundaries

| Component | Role |
|-----------|------|
| **This repository** | Ships **named issue bundles** (“presets”) in **`cicd/gh/known_issues.yaml`** and **issue bodies** in **`.github/issue_bodies/*.md`**. No tokens, no host-specific URLs in committed data. |
| **`gh` binary** | Official client; performs HTTPS to GitHub using credentials from the OS keychain (interactive login) or from **`GH_TOKEN`** / **`GITHUB_TOKEN`** (automation). |
| **`github_issues.py`** | Builds a **fixed argv** for `gh issue create`; reads only allow-listed body paths; does **not** embed credentials. |

We do **not** implement a custom GitHub REST client in Python for issues in this repo; that keeps the trust surface on `gh` and its documented auth flows.

## Authentication (minimum)

1. **Interactive / developer machines** — Prefer **`gh auth login`** so credentials live in the **platform keychain**, not in shell startup files.
2. **CI / agents** — Use a **fine-scoped** token (least privilege: e.g. `issues: write` only if that is all you need) stored in the **CI secret store**, exposed as **`GH_TOKEN`** or **`GITHUB_TOKEN`** for the job duration only.
3. **Never** commit tokens, `.env` files with secrets, or long-lived PATs into the git tree. **Never** print token values from scripts (including debug logging).

If a token is exposed (paste, log, screenshot), **revoke** it and issue a new one.

## Issue presets and bodies (`github_issues.py`)

A **preset** is a **small named bundle** in `cicd/gh/known_issues.yaml`: a stable id (e.g. `jxa-audit-full`), a **title**, a **body** file path under `.github/issue_bodies/`, and **labels**. Running **`github_issues.py create <preset-id>`** loads that bundle and calls **`gh issue create`** with those fields—so you do not retype the title/body/labels each time. It is the same idea as a “saved reply” or “template instance,” but stored as **data in the repo**, not the word “preset” from GitHub’s product UI.

- **Preset catalog:** `cicd/gh/known_issues.yaml` — serialized configuration (no executable code).
- **Bodies:** paths must be **repo-relative** and resolve under **`.github/issue_bodies/`** only (enforced in `github_issues.py` and `cicd/validate_input.py` via `validate_github_issue_body_relative`).
- **Titles and labels** are validated with **`validate_github_issue_*`** in `cicd/validate_input.py` (length, character set, no control characters in titles).

## Subprocess and command construction

- Use **`subprocess.run(..., shell=False)`** with a **list argv** only. Do not interpolate user or preset-derived fields into a shell string.
- **Do not** add `shell=True` for convenience.

## Input validation (AppSec baseline)

- All preset ids, titles, labels, and body paths pass through **`cicd/validate_input.py`** policies when loaded from YAML.
- **Body size:** `github_issues.py` rejects bodies larger than a fixed cap after read (defense against accidental huge files).
- **No path traversal:** absolute paths and `..` segments are rejected for body paths before resolution.

General CLI norms: **[Python CLI safety](../CICD/python_cli_security.md)**.

## Portability

- Scripts assume **`python3`** and **`gh`** on `PATH`. They do not hardcode home directories or GitHub org names inside Python logic; **`gh`** uses the current repository’s **`git remote`** when run from the repo root.
- Optional **`--repo OWNER/REPO`** for `gh` is **not** wired in `github_issues.py` today; add it only with the same validation and documentation discipline if cross-repo issues become a requirement.

## Extending issue automation

- **Prefer one module with subcommands** (`create`, `presets`, future verbs) for **issue**-shaped operations so flags stay aligned with `gh issue <verb>`.
- Add **new presets** by editing YAML + markdown only; avoid hardcoding titles in Python.
- For **other GitHub surfaces** (pull requests, releases), use a **separate** small helper (e.g. `github_pulls.py`) rather than growing a monolithic “all of GitHub” script.

## Related

- [Third-party security baseline](third_party_security.md)
- `cicd/gh/README.md` — command mapping, usage, and “what is a preset?”
- `cicd/validate_input.py` — `validate_github_issue_*` policies.
- [Python CLI safety](../CICD/python_cli_security.md) — subprocess and argparse norms.

---
Last modified: 2026-05-15
