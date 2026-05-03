"""
Shared procedure YAML metadata for generated script headers (shell + JXA).

author  — procedure maintainer in this repo (shown as # Author: / * Author:).
credit  — optional free-text upstream attribution (LOOBins, research, etc.).
acknowledgement — structured credits (person + handle); emitted as Credit lines.
"""

from __future__ import annotations

from typing import Any, Dict, List


def _collect_credit_chunks(yaml_data: Dict[str, Any]) -> List[str]:
    chunks: List[str] = []
    raw = yaml_data.get("credit")
    if isinstance(raw, str) and raw.strip():
        chunks.append(raw.strip())
    if isinstance(raw, list):
        for item in raw:
            s = str(item).strip()
            if s:
                chunks.append(s)
    for row in yaml_data.get("acknowledgement") or []:
        if not isinstance(row, dict):
            continue
        person = (row.get("person") or "").strip()
        handle = (row.get("handle") or "").strip()
        if person and handle:
            chunks.append(f"{person} ({handle})")
        elif person:
            chunks.append(person)
        elif handle:
            chunks.append(handle)
    return chunks


def shell_credit_header_lines(yaml_data: Dict[str, Any]) -> str:
    """Return POSIX shell comment lines (each starts with '# Credit:')."""
    parts = _collect_credit_chunks(yaml_data)
    if not parts:
        return "# Credit: (none listed)"
    out_lines = []
    for p in parts:
        one = " ".join(p.splitlines())
        out_lines.append(f"# Credit: {one}")
    return "\n".join(out_lines)


def jxa_credit_header_line(yaml_data: Dict[str, Any]) -> str:
    """Return one block-comment line for JXA header (* Credit: ...)."""
    parts = _collect_credit_chunks(yaml_data)
    if not parts:
        return " * Credit: (none listed)"
    joined = " | ".join(" ".join(p.splitlines()) for p in parts)
    return f" * Credit: {joined}"


DEFAULT_PROCEDURE_AUTHOR = "@darmado | https://x.com/darmad0"
