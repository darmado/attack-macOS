#!/usr/bin/env python3
"""
Name: github_issues
Author: attack-macOS maintainers
License: See repository LICENSE
Repository: https://github.com/darmado/attack-macOS
Description: Small GitHub Issues CLI helper around `gh issue`; subcommands map to `gh issue <verb>`.

Security and repo rules: docs/Integrations/github_repo_interaction.md and docs/CICD/python_cli_security.md
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

_MAX_ISSUE_BODY_BYTES = 256 * 1024

_CICD_ROOT = Path(__file__).resolve().parent.parent
_REPO_ROOT = Path(__file__).resolve().parents[2]
_KNOWN_ISSUES_PATH = Path(__file__).resolve().with_name("known_issues.yaml")

_EPILOG = """
Mapping to `gh` (see cicd/gh/README.md):
  create <PRESET_ID>     gh issue create --title … --body-file … --label …
  presets                (no gh call; lists known_issues.yaml entries)
"""


def _import_validate_input():
    if str(_CICD_ROOT) not in sys.path:
        sys.path.insert(0, str(_CICD_ROOT))
    import validate_input  # noqa: E402

    return validate_input


def _resolve_body_file(repo: Path, relative: str) -> Path:
    target = (repo / Path(relative)).resolve()
    allowed_root = (repo / ".github" / "issue_bodies").resolve()
    try:
        target.relative_to(allowed_root)
    except ValueError as exc:
        raise ValueError(f"body path must resolve under {allowed_root}") from exc
    if not target.is_file():
        raise ValueError(f"body file missing or not a regular file: {target}")
    return target


def load_known_issues(yaml_path: Path) -> dict[str, dict]:
    vi = _import_validate_input()
    if not yaml_path.is_file():
        raise FileNotFoundError(f"missing known issues catalog: {yaml_path}")
    raw = yaml_path.read_text(encoding="utf-8")
    data = yaml.safe_load(raw)
    if not isinstance(data, dict) or not data:
        raise ValueError("known_issues.yaml must be a non-empty mapping")

    result: dict[str, dict] = {}
    for k, entry in data.items():
        if not isinstance(k, str):
            raise ValueError(f"preset id must be a YAML string key, got {type(k).__name__}")
        try:
            pid = vi.validate_github_issue_preset_id(k)
        except argparse.ArgumentTypeError as e:
            raise ValueError(f"preset id {k!r}: {e}") from e

        if not isinstance(entry, dict):
            raise ValueError(f"preset {pid!r}: entry must be a mapping")

        title_raw = entry.get("title")
        if not isinstance(title_raw, str):
            raise ValueError(f"preset {pid!r}: title must be a string")
        try:
            title = vi.validate_github_issue_title(title_raw)
        except argparse.ArgumentTypeError as e:
            raise ValueError(f"preset {pid!r} title: {e}") from e

        body_raw = entry.get("body")
        if not isinstance(body_raw, str):
            raise ValueError(f"preset {pid!r}: body must be a string")
        try:
            body_rel = vi.validate_github_issue_body_relative(body_raw)
        except argparse.ArgumentTypeError as e:
            raise ValueError(f"preset {pid!r} body: {e}") from e

        labels_raw = entry.get("labels", [])
        if isinstance(labels_raw, str):
            labels_raw = [labels_raw]
        if not isinstance(labels_raw, list) or not labels_raw:
            raise ValueError(f"preset {pid!r}: labels must be a non-empty list")

        labels: list[str] = []
        for i, token in enumerate(labels_raw):
            if not isinstance(token, str):
                raise ValueError(f"preset {pid!r}: label[{i}] must be a string")
            try:
                labels.append(vi.validate_github_issue_label(token))
            except argparse.ArgumentTypeError as e:
                raise ValueError(f"preset {pid!r} label[{i}]: {e}") from e

        body_abs = _resolve_body_file(_REPO_ROOT, body_rel)

        result[pid] = {
            "title": title,
            "body": body_rel,
            "body_path": body_abs,
            "labels": tuple(labels),
        }
    return result


def _gh_binary() -> str | None:
    return shutil.which("gh")


def _gh_available(gh_bin: str) -> bool:
    return (
        subprocess.run(
            [gh_bin, "--version"],
            capture_output=True,
            shell=False,
        ).returncode
        == 0
    )


def _gh_authenticated(gh_bin: str) -> bool:
    r = subprocess.run(
        [gh_bin, "auth", "status"],
        cwd=_REPO_ROOT,
        capture_output=True,
        text=True,
        shell=False,
    )
    if r.returncode == 0:
        return True
    return bool(os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN"))


def cmd_presets(_args: argparse.Namespace, presets: dict[str, dict]) -> int:
    for pid in sorted(presets):
        print(f"{pid}\t{presets[pid]['title']}")
    return 0


def cmd_create(args: argparse.Namespace, presets: dict[str, dict], gh_bin: str) -> int:
    meta = presets[args.preset_id]
    body_path: Path = meta["body_path"]

    body = body_path.read_text(encoding="utf-8")
    body_bytes = len(body.encode("utf-8"))
    if body_bytes > _MAX_ISSUE_BODY_BYTES:
        print(
            f"Body exceeds max size ({body_bytes} > {_MAX_ISSUE_BODY_BYTES} bytes): {body_path}",
            file=sys.stderr,
        )
        return 1

    if args.dry_run:
        print("Dry run: would run equivalent of")
        print("  gh issue create \\")
        print(f"    --title {meta['title']!r} \\")
        print("    --body-file <temporary .md> \\")
        for lab in meta["labels"][:-1]:
            print(f"    --label {lab!r} \\")
        if meta["labels"]:
            print(f"    --label {meta['labels'][-1]!r}")
        print("  (temporary file deleted after gh exits)")
        print("  body source:", body_path)
        print("  body size:", body_bytes, "bytes")
        return 0

    if not _gh_authenticated(gh_bin):
        print(
            "gh is not authenticated. Run: gh auth login\n"
            "Or set GH_TOKEN / GITHUB_TOKEN (CI or automation only; never commit tokens).\n"
            "See: docs/Integrations/github_repo_interaction.md",
            file=sys.stderr,
        )
        return 1

    fd, tmp_path = tempfile.mkstemp(suffix=".md", prefix="github-issues-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as tmp:
            tmp.write(body)
        cmd = [
            gh_bin,
            "issue",
            "create",
            "--title",
            meta["title"],
            "--body-file",
            tmp_path,
        ]
        for lab in meta["labels"]:
            cmd.extend(["--label", lab])
        proc = subprocess.run(cmd, cwd=_REPO_ROOT, shell=False)
        return proc.returncode
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


def _parse_args(presets: dict[str, dict]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "GitHub Issues helper: subcommands mirror `gh issue` verbs "
            "(currently `create` → `gh issue create`)."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=_EPILOG,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    presets_cmd = sub.add_parser(
        "presets",
        help="List preset ids and titles from cicd/gh/known_issues.yaml (no network).",
    )
    presets_cmd.set_defaults(handler="presets")

    create = sub.add_parser(
        "create",
        help="Create an issue (gh issue create).",
        description=(
            "Create a GitHub issue from a preset defined in cicd/gh/known_issues.yaml "
            "(body markdown under .github/issue_bodies/)."
        ),
    )
    create.add_argument(
        "preset_id",
        choices=sorted(presets.keys()),
        metavar="PRESET_ID",
        help="Preset id from cicd/gh/known_issues.yaml",
    )
    create.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what gh issue create would use; do not call gh.",
    )
    create.set_defaults(handler="create")

    return parser.parse_args()


def main() -> int:
    try:
        presets = load_known_issues(_KNOWN_ISSUES_PATH)
    except (OSError, ValueError, yaml.YAMLError) as e:
        print(f"Invalid catalog {_KNOWN_ISSUES_PATH}: {e}", file=sys.stderr)
        return 1

    args = _parse_args(presets)

    if args.handler == "presets":
        return cmd_presets(args, presets)

    gh_bin = _gh_binary()
    if not gh_bin:
        print(
            "The `gh` CLI was not found on PATH. Install: https://cli.github.com/",
            file=sys.stderr,
        )
        return 1

    if args.handler == "create":
        if not args.dry_run and not _gh_available(gh_bin):
            print(
                "The `gh` CLI failed `gh --version`. Check your install.",
                file=sys.stderr,
            )
            return 1
        return cmd_create(args, presets, gh_bin)

    print(f"Unknown handler: {args.handler}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
