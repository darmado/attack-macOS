#!/usr/bin/env python3
"""
Name: convert_common.py
Author: @darmado | https://x.com/darmad0
License: Apache 2.0
Repository: https://github.com/armadoinc/attack-macOS
Description: Shared helper functions/constants for cicd converter tools.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import yaml


MITRE_TECHNIQUE_URL_FMT = "https://attack.mitre.org/techniques/{base}/{sub}/"
MITRE_TECHNIQUE_URL_BASE_FMT = "https://attack.mitre.org/techniques/{ttp_id}/"
LOOBINS_PROJECT_URL = "https://www.loobins.io/"
ART_PROJECT_URL = "https://github.com/redcanaryco/atomic-red-team"
ART_TECHNIQUE_DOC_URL_FMT = "https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/{ttp_id}/{ttp_id}.md"


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def save_yaml(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        yaml.dump(data, handle, default_flow_style=False, sort_keys=False, allow_unicode=True, width=120, indent=2)


def clean_slug(value: str, max_len: int = 80) -> str:
    text = re.sub(r"[^a-z0-9]+", "_", value.lower())
    text = re.sub(r"_+", "_", text).strip("_")
    if not text:
        text = "procedure"
    return text[:max_len].rstrip("_")


def option_name(arg_key: str) -> str:
    return "--" + re.sub(r"[^a-z0-9-]", "-", arg_key.lower().replace("_", "-"))


def input_var_name(arg_key: str) -> str:
    stem = re.sub(r"[^A-Z0-9_]", "_", arg_key.upper())
    stem = re.sub(r"_+", "_", stem).strip("_")
    return f"INPUT_{stem}" if stem else "INPUT_VALUE"


def cmd_var_name(bin_name: str) -> str:
    stem = re.sub(r"[^A-Z0-9_]", "_", bin_name.upper())
    stem = re.sub(r"_+", "_", stem).strip("_")
    return f"CMD_{stem}" if stem else "CMD_TOOL"


def wrap_command_with_cmd_var(command: str) -> tuple[str, dict[str, Any] | None]:
    m = re.match(r"^\s*([A-Za-z0-9_.-]+)(\s+.*)?$", command, flags=re.DOTALL)
    if not m:
        return command, None
    token = m.group(1)
    rest = m.group(2) or ""
    if token.startswith("$CMD_"):
        return command, None
    var = cmd_var_name(token)
    wrapped = f'"${var}"{rest}'
    gv = {"name": var, "type": "string", "default_value": token}
    return wrapped, gv


def compact_template_sections(template: dict[str, Any]) -> None:
    resources = template.get("resources")
    if isinstance(resources, list):
        template["resources"] = [
            r
            for r in resources
            if isinstance(r, dict)
            and (str(r.get("link", "")).strip() or str(r.get("description", "")).strip())
        ]
    ack = template.get("acknowledgement")
    if isinstance(ack, list):
        template["acknowledgement"] = [
            a
            for a in ack
            if isinstance(a, dict)
            and (str(a.get("person", "")).strip() or str(a.get("handle", "")).strip())
        ]
    det = template.get("detection")
    if isinstance(det, list):
        cleaned_det = []
        for d in det:
            if not isinstance(d, dict):
                continue
            if any(
                str(d.get(k, "")).strip()
                for k in ("ioc", "analysis", "rule_sigma", "rule_elastic", "rule_splunk", "rule_block")
            ):
                cleaned_det.append(d)
        template["detection"] = cleaned_det


def normalize_tactic(raw: str) -> str:
    mapping = {
        "reconnaissance": "Reconnaissance",
        "resource development": "Resource Development",
        "initial access": "Initial Access",
        "execution": "Execution",
        "persistence": "Persistence",
        "privilege escalation": "Privilege Escalation",
        "defense evasion": "Defense Evasion",
        "credential access": "Credential Access",
        "discovery": "Discovery",
        "lateral movement": "Lateral Movement",
        "collection": "Collection",
        "command and control": "Command and Control",
        "exfiltration": "Exfiltration",
        "impact": "Impact",
    }
    return mapping.get(raw.strip().lower(), "Discovery")


def mitre_technique_url(ttp_id: str) -> str:
    if "." in ttp_id:
        base, sub = ttp_id.split(".", 1)
        return MITRE_TECHNIQUE_URL_FMT.format(base=base, sub=sub)
    return MITRE_TECHNIQUE_URL_BASE_FMT.format(ttp_id=ttp_id)
