# `cicd/gh/` — GitHub CLI helpers

Maintainer-only helpers around the official **[GitHub CLI](https://cli.github.com/)** (`gh`). **Security:** [Third-party baseline](../../docs/Integrations/third_party_security.md) and [GitHub interaction](../../docs/Integrations/github_repo_interaction.md).

## What is a “preset”?

A **preset** is a **named row** in `cicd/gh/known_issues.yaml`: a short id (e.g. `jxa-audit-full`), the **issue title**, the path to a **markdown body** under `.github/issue_bodies/`, and **labels**. The CLI loads that bundle and runs **`gh issue create`** with those values so you do not retype the same bug report for recurring failures. It is **repository data**, not a GitHub product feature named “preset.”

## Scripts

| Script | Maps to | Purpose |
|--------|---------|---------|
| **`github_issues.py`** | `gh issue …` | Subcommands mirror `gh` issue verbs (see below). |

## `github_issues.py` ↔ `gh issue` mapping

| This tool | GitHub CLI (equivalent) |
|-----------|-------------------------|
| `python3 cicd/gh/github_issues.py create <PRESET_ID>` | `gh issue create --title … --body-file … --label …` (title, body path, and labels come from `cicd/gh/known_issues.yaml` + `.github/issue_bodies/`) |
| `python3 cicd/gh/github_issues.py presets` | *(no `gh` call)* — lists preset ids and titles from `known_issues.yaml` |

Flags:

| Our flag | `gh` meaning |
|----------|----------------|
| `--dry-run` (on `create`) | Do not run `gh`; print the same title/labels and that a temp body file would be used. |

## Commands

```bash
# List configured presets (no auth required)
python3 cicd/gh/github_issues.py presets

# Preview create (no auth required)
python3 cicd/gh/github_issues.py create jxa-audit-full --dry-run

# Create issue (requires `gh` + auth or GH_TOKEN / GITHUB_TOKEN)
python3 cicd/gh/github_issues.py create jxa-audit-full
```

## Adding a preset

1. Add a markdown body under **`.github/issue_bodies/`** (align sections with `.github/ISSUE_TEMPLATE/bug_report.md` when the issue is a bug report).
2. Append an entry to **`cicd/gh/known_issues.yaml`** (`title`, `body`, `labels`).
3. Run `python3 cicd/gh/github_issues.py presets` and `create … --dry-run` to verify.

## Design note: one module vs many scripts

Related issue operations should stay in **`github_issues.py`** as **subcommands** (`create`, `presets`, future `close`, …). Unrelated GitHub surfaces (e.g. PRs) deserve a **separate** small module if they appear later, to keep responsibilities clear.
