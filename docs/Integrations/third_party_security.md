# Third-party integrations — security baseline

## Purpose

Set **generic, reusable minimums** for how attack-macOS **maintainer tooling** and **automation** interact with **external products and services** (SaaS APIs, CLIs that authenticate to vendors, hosted CI, and similar). Integration-specific details live in **per-integration** documents linked from this page.

This is **maintainer / automation** guidance, not operator runbooks for executing TTPs on endpoints.

## Audience

People who add scripts under `cicd/`, wire GitHub Actions (or other CI), or connect this repo to another vendor.

## Scope

**In scope:** credentials, subprocess usage, secrets handling, least privilege, documenting trust boundaries, and where to put integration-specific rules.

**Out of scope:** MITRE content, procedure YAML semantics, and runtime behavior of generated TTP scripts (see existing standards under `docs/Standards/` and `docs/CICD/`).

## Baseline requirements (all integrations)

1. **Identity and secrets** — Prefer **short-lived** and **least-privilege** credentials. Never commit secrets or long-lived personal access tokens to git. Store CI secrets in the **platform secret manager**, not in repo files or shell startup scripts by default.
2. **Official or supported clients** — Prefer the **vendor-supported CLI or SDK** over ad hoc `curl` to undocumented endpoints when a maintained client exists and fits the task.
3. **Subprocess and argv** — When invoking external binaries, use **`subprocess` with `shell=False`** and a **fixed argv list**; do not build shell strings from untrusted or broad user input.
4. **Input validation** — Any identifier, path, URL, or token that crosses a trust boundary into a script should be validated with **explicit allow-lists** (length, character set, scheme) in shared helpers (for this repo: `cicd/validate_input.py` where applicable).
5. **Logging** — Do not log secret values, token headers, or full authentication responses. Prefer logging **action + outcome** (success/failure, non-sensitive ids).
6. **Supply chain** — Pin or document versions for installable clients; prefer distribution packages or documented install paths over piping remote shell installers into `sh`.
7. **Documentation** — Each new integration surface gets a **short, linked** document under **`docs/Integrations/`** (or a clearly linked path) describing auth, data flow, and failure modes.

## Integration-specific standards

Add a row here when you introduce a new third-party touchpoint:

| Integration | Maintainer doc | Notes |
|-------------|------------------|--------|
| **GitHub** (`gh`, issue automation) | [github_repo_interaction.md](github_repo_interaction.md) | `cicd/gh/github_issues.py`, `known_issues.yaml`, `.github/issue_bodies/` |
| **Caldera** (plugin / deployment) | [Caldera plugin](../../integrations/CALDERA.md) | Repo-root `integrations/` overview; extend with security addendum here when needed |

## Related

- [Integrations index](README.md)
- [Python CLI safety](../CICD/python_cli_security.md) — `argparse`, URLs, subprocess norms for `cicd/` tools.

---
Last modified: 2026-05-15
