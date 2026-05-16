"""
Name: validate_input.py
Author: @darmado | https://x.com/darmad0
License: Apache 2.0
Repository: https://github.com/armadoinc/attack-macOS
Description:
  Policy constants and ``validate_*`` callables for maintainer ``cicd/`` CLIs.

Each function returns the accepted string (possibly normalized) or raises
``argparse.ArgumentTypeError`` for ``argparse`` ``type=`` or ``parser.error()``.

Entrypoints under ``cicd/<tool>/`` add this file's parent directory to ``sys.path``
then ``import validate_input``. See ``docs/CICD/python_cli_security.md``.
"""

from __future__ import annotations

import argparse
import re
import urllib.parse
from pathlib import Path

# --- Policy: outbound URL scheme (urllib fetches; blocks file:, gopher:, javascript:, etc.)
ALLOWED_HTTP_HTTPS_SCHEMES: tuple[str, ...] = ("http", "https")

# --- Policy: LOOBin YAML stem / filename segment (``{name}.yml``, raw.githubusercontent path)
_VALIDATE_LOOBIN_STEM_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$")

# --- Policy: git branch or tag fragment for raw GitHub URLs (no spaces; bounded length)
_VALIDATE_GIT_REF_FRAGMENT_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.\/-]{0,254}$")

# --- Policy: Atomic Red Team executor.name token (after lowercasing in our tools)
_VALIDATE_ATOMIC_RED_TEAM_EXECUTOR_NAME_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,127}$")

# --- Policy: ART macos-index top-level tactic key (user input normalized to lowercase)
_VALIDATE_ATOMIC_RED_TEAM_MACOS_INDEX_TACTIC_RE = re.compile(r"^[a-z][a-z0-9_-]{0,126}$")

# --- Policy: GitHub preset id (cicd/gh/known_issues.yaml keys; gh issue create presets)
_VALIDATE_GITHUB_ISSUE_PRESET_ID_RE = re.compile(r"^[a-z][a-z0-9-]{0,127}$")

# --- Policy: GitHub issue label token (conservative ASCII for automation)
_VALIDATE_GITHUB_ISSUE_LABEL_RE = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9._ -]{0,49}$")

# --- Policy: GitHub issue title (plaintext; no control characters)
_GITHUB_ISSUE_TITLE_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")
GITHUB_ISSUE_TITLE_MAX_LEN = 300

# --- Policy: ``--search`` fnmatch pattern length cap
ATOMIC_RED_TEAM_INDEX_SEARCH_PATTERN_MAX_LEN = 512

_FORBIDDEN_ATOMIC_INDEX_SEARCH_CHARS: tuple[str, ...] = ("\x00", "\n", "\r")


def validate_http_https_url_with_host(value: str) -> str:
    """URL must use an allowed scheme and include a host (``netloc``)."""
    raw = value.strip()
    parsed = urllib.parse.urlparse(raw)
    if parsed.scheme not in ALLOWED_HTTP_HTTPS_SCHEMES:
        allowed = ", ".join(ALLOWED_HTTP_HTTPS_SCHEMES)
        raise argparse.ArgumentTypeError(
            f"URL scheme must be one of ({allowed}); got {parsed.scheme!r}",
        )
    if not parsed.netloc:
        raise argparse.ArgumentTypeError("URL must include a host")
    return raw


def validate_github_issue_preset_id(value: str) -> str:
    """Preset id for ``cicd/gh/known_issues.yaml`` keys and CLI (lowercase slug)."""
    raw = value.strip()
    if not raw or not _VALIDATE_GITHUB_ISSUE_PRESET_ID_RE.fullmatch(raw):
        raise argparse.ArgumentTypeError(
            "preset id must start with a-z, then [a-z0-9-], max 128 characters",
        )
    return raw


def validate_github_issue_label(value: str) -> str:
    """Single GitHub label string for ``gh issue create --label`` (conservative)."""
    raw = value.strip()
    if not raw or len(raw) > 50:
        raise argparse.ArgumentTypeError("label must be 1–50 characters")
    if not _VALIDATE_GITHUB_ISSUE_LABEL_RE.fullmatch(raw):
        raise argparse.ArgumentTypeError(
            "label must be ASCII letters, digits, space, dot, underscore, hyphen",
        )
    return raw


def validate_github_issue_title(value: str) -> str:
    """Issue title for ``gh issue create --title`` (no control characters)."""
    raw = value.strip()
    if not raw or len(raw) > GITHUB_ISSUE_TITLE_MAX_LEN:
        raise argparse.ArgumentTypeError(
            f"title must be non-empty and at most {GITHUB_ISSUE_TITLE_MAX_LEN} characters",
        )
    if _GITHUB_ISSUE_TITLE_CONTROL.search(raw):
        raise argparse.ArgumentTypeError("title must not contain control characters")
    return raw


def validate_github_issue_body_relative(value: str) -> str:
    """Repo-relative path; must live under ``.github/issue_bodies/`` (no traversal)."""
    raw = value.strip().replace("\\", "/")
    parts = Path(raw).parts
    if Path(raw).is_absolute() or ".." in parts:
        raise argparse.ArgumentTypeError("body must be a repo-relative path without '..'")
    if len(parts) < 3 or parts[0:2] != (".github", "issue_bodies"):
        raise argparse.ArgumentTypeError("body must start with .github/issue_bodies/")
    return raw


def validate_loobin_binary_stem(value: str) -> str:
    """LOOBin binary name safe for ``{{name}}.yml`` and URL path segments."""
    raw = value.strip()
    if not raw or not _VALIDATE_LOOBIN_STEM_RE.fullmatch(raw):
        raise argparse.ArgumentTypeError(
            "must start with alphanumeric, then letters, digits, ._- only (max 128 chars)",
        )
    return raw


def validate_git_ref_fragment(value: str) -> str:
    """Conservative git branch/tag fragment (no shell metacharacters; bounded length)."""
    raw = value.strip()
    if not raw or not _VALIDATE_GIT_REF_FRAGMENT_RE.fullmatch(raw):
        raise argparse.ArgumentTypeError(
            "must be a conservative git ref (alphanumeric, . _ / -; no spaces)",
        )
    return raw


def validate_atomic_red_team_executor_name_token(raw: str) -> str:
    """Single ART ``executor.name`` token (trimmed and lowercased)."""
    token = raw.strip().lower()
    if not token or not _VALIDATE_ATOMIC_RED_TEAM_EXECUTOR_NAME_RE.fullmatch(token):
        raise argparse.ArgumentTypeError(f"invalid executor name fragment: {raw!r}")
    return token


def validate_atomic_red_team_macos_index_tactic_key(value: str) -> str:
    """ART macOS index YAML tactic key (compared after lowercasing user input)."""
    raw = value.strip().lower()
    if not raw or not _VALIDATE_ATOMIC_RED_TEAM_MACOS_INDEX_TACTIC_RE.fullmatch(raw):
        raise argparse.ArgumentTypeError(
            "invalid tactic key (lowercase letters, digits, hyphen, underscore only)",
        )
    return raw


def validate_atomic_red_team_index_search_fnmatch_pattern(raw: str) -> str:
    """Non-empty fnmatch pattern for ART index query; no NUL/newline; length cap."""
    pat = raw.strip()
    if not pat:
        raise argparse.ArgumentTypeError("pattern must be non-empty")
    for ch in _FORBIDDEN_ATOMIC_INDEX_SEARCH_CHARS:
        if ch in pat:
            raise argparse.ArgumentTypeError("pattern must not contain NUL or newline")
    if len(pat) > ATOMIC_RED_TEAM_INDEX_SEARCH_PATTERN_MAX_LEN:
        raise argparse.ArgumentTypeError(
            f"pattern exceeds {ATOMIC_RED_TEAM_INDEX_SEARCH_PATTERN_MAX_LEN} chars",
        )
    return pat
