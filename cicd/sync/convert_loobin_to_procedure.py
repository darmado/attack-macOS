#!/usr/bin/env python3
"""
LOOBins to Procedure Converter

Load procedure template, fill with a per-binary LOOBin YAML (standby/LOOBins/*.yml).
Output draft YAML under attackmacos/standby/LOOBins/staging/ for review before
copying to attackmacos/core/config/ and building.

See docs/CICD/LOOBins_to_Procedure_Mapping.md
"""

import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import yaml


# MITRE tactic → default technique when upstream does not publish a technique ID.
TACTIC_DEFAULT_TTP = {
    "Reconnaissance": "T1595",
    "Resource Development": "T1587",
    "Initial Access": "T1566",
    "Execution": "T1059.004",
    "Persistence": "T1547.011",
    "Privilege Escalation": "T1068",
    "Defense Evasion": "T1562.001",
    "Credential Access": "T1555.001",
    "Discovery": "T1082",
    "Lateral Movement": "T1021",
    "Collection": "T1005",
    "Command and Control": "T1071.001",
    "Exfiltration": "T1041",
    "Impact": "T1486",
}

# Binaries already covered by first-class procedures in core/config (skip promote).
SUPERSEDED_BY_EXISTING = {
    "screencapture": "Use attackmacos/core/config/screen_capture.yml (T1113).",
    "security": "Use attackmacos/core/config/keychains.yml (security / keychain).",
}

# Finer mapping than tactic-default when the binary strongly implies a technique.
BINARY_TTP_OVERRIDE = {
    "pbpaste": ("T1115", "Collection"),
    "dns-sd": ("T1046", "Discovery"),
    "networksetup": ("T1016", "Discovery"),
    "scutil": ("T1016", "Discovery"),
    "nscurl": ("T1071.001", "Command and Control"),
    "mdfind": ("T1083", "Discovery"),
    "mdls": ("T1083", "Discovery"),
    "dscacheutil": ("T1087.002", "Discovery"),
    "dscl": ("T1087.002", "Discovery"),
    "dsconfigad": ("T1087.004", "Discovery"),
    "launchctl": ("T1543.001", "Persistence"),
    "osascript": ("T1059.002", "Execution"),
    "osacompile": ("T1059.002", "Execution"),
    "sqlite3": ("T1213", "Collection"),
    "ssh-keygen": ("T1552.004", "Credential Access"),
    "defaults": ("T1562.001", "Defense Evasion"),
    "csrutil": ("T1562.001", "Defense Evasion"),
    "spctl": ("T1553.004", "Defense Evasion"),
    "profiles": ("T1562.001", "Defense Evasion"),
    "softwareupdate": ("T1072", "Execution"),
    "systemsetup": ("T1562.001", "Defense Evasion"),
    "sysadminctl": ("T1562.001", "Defense Evasion"),
    "nvram": ("T1547.006", "Persistence"),
    "chflags": ("T1564.001", "Defense Evasion"),
    "xattr": ("T1553.004", "Defense Evasion"),
    "hdiutil": ("T1564.004", "Defense Evasion"),
    "ditto": ("T1036.005", "Defense Evasion"),
    "log": ("T1082", "Discovery"),
    "last": ("T1087", "Discovery"),
    "swift": ("T1059", "Execution"),
    "tclsh": ("T1059", "Execution"),
    "safaridriver": ("T1185", "Execution"),
    "sfltool": ("T1005", "Collection"),
    "tmutil": ("T1562.001", "Defense Evasion"),
    "say": ("T1491", "Impact"),
    "kextstat": ("T1082", "Discovery"),
    "codesign": ("T1553", "Defense Evasion"),
    "sw_vers": ("T1082", "Discovery"),
    "sysctl": ("T1082", "Discovery"),
    "ioreg": ("T1082", "Discovery"),
    "system_profiler": ("T1082", "Discovery"),
    "plutil": ("T1082", "Discovery"),
    "open": ("T1204", "Execution"),
    "mktemp": ("T1083", "Discovery"),
    "textutil": ("T1059", "Execution"),
    "streamzip": ("T1560", "Collection"),
    "GetFileInfo": ("T1083", "Discovery"),
    "SetFile": ("T1564.001", "Defense Evasion"),
    "odutil": ("T1082", "Discovery"),
    "dsexport": ("T1087.002", "Discovery"),
    "caffeinate": ("T1499", "Impact"),
    "lsregister": ("T1082", "Discovery"),
}


def mitre_technique_url(ttp_id: str) -> str:
    if "." in ttp_id:
        base, sub = ttp_id.split(".", 1)
        return f"https://attack.mitre.org/techniques/{base}/{sub}/"
    return f"https://attack.mitre.org/techniques/{ttp_id}/"


def infer_ttp_entry(binary_stem: str, loobin_data: dict) -> dict:
    """Return keys: ttp_id, tactic, skip_promote (bool), note (optional)."""
    key = binary_stem.lower()
    if key in SUPERSEDED_BY_EXISTING:
        return {
            "skip_promote": True,
            "note": SUPERSEDED_BY_EXISTING[key],
            "ttp_id": "",
            "tactic": "",
        }
    if key in BINARY_TTP_OVERRIDE:
        tid, tac = BINARY_TTP_OVERRIDE[key]
        return {"skip_promote": False, "ttp_id": tid, "tactic": tac, "source": "binary_override"}
    examples = loobin_data.get("example_use_cases") or []
    if not examples:
        return {"skip_promote": True, "note": "no example_use_cases", "ttp_id": "", "tactic": ""}
    tactics = examples[0].get("tactics") or ["Discovery"]
    tac = tactics[0]
    tid = TACTIC_DEFAULT_TTP.get(tac, "T1082")
    return {"skip_promote": False, "ttp_id": tid, "tactic": tac, "source": "first_example_tactic"}


def apply_promotion_metadata(procedure_data: dict, entry: dict) -> None:
    procedure_data["ttp_id"] = entry["ttp_id"]
    procedure_data["tactic"] = entry["tactic"]
    url = mitre_technique_url(entry["ttp_id"])
    mitre_entry = {"link": url, "description": f"MITRE ATT&CK — {entry['ttp_id']}"}
    procedure_data.setdefault("resources", [])
    if not any(r.get("link") == url for r in procedure_data["resources"]):
        procedure_data["resources"].insert(1, mitre_entry)
    intent = procedure_data.get("intent", "")
    suffix = " Sourced from LOOBins; confirm MITRE mapping for each enabled option."
    procedure_data["intent"] = (intent[: 500 - len(suffix)] + suffix)[:500]


def write_ttp_overlay(project_root: Path) -> Path:
    """Emit human-editable TTP_OVERLAY.yml next to standby LOOBins for review."""
    standby_dir = project_root / "attackmacos" / "standby" / "LOOBins"
    out_path = standby_dir / "TTP_OVERLAY.yml"
    ymls = sorted(p for p in standby_dir.glob("*.yml") if p.is_file() and p.name != "TTP_OVERLAY.yml")
    entries = {}
    for path in ymls:
        data = load_yaml(path)
        stem = path.stem
        ent = infer_ttp_entry(stem, data)
        entries[stem] = {
            "ttp_id": ent["ttp_id"],
            "tactic": ent["tactic"],
            "skip_promote": ent["skip_promote"],
            "source": ent.get("source", ""),
            "note": ent.get("note", ""),
        }
    payload = {
        "version": 1,
        "description": "Inferred mapping from standby LOOBins YAML (first tactic + overrides). Edit before relying on legal/compliance contexts.",
        "entries": entries,
    }
    save_yaml(payload, out_path)
    return out_path


def validate_config_yaml(project_root: Path, yaml_path: Path) -> bool:
    builder = project_root / "cicd" / "build" / "build_shell_procedure.py"
    r = subprocess.run(
        [sys.executable, str(builder), "--validate", str(yaml_path)],
        cwd=str(project_root),
        capture_output=True,
        text=True,
        timeout=120,
    )
    if r.returncode != 0:
        print(r.stdout + r.stderr, file=sys.stderr)
        return False
    return True


def promote_loobin_file(
    loobin_path: Path,
    template_path: Path,
    project_root: Path,
    force: bool = False,
) -> bool:
    """Convert LOOBin YAML and write attackmacos/core/config/<stem>.yml if valid."""
    stem = loobin_path.stem
    loobin_data = load_yaml(loobin_path)
    entry = infer_ttp_entry(stem, loobin_data)
    if entry["skip_promote"]:
        print(f"SKIP {stem}: {entry.get('note', 'skipped')}")
        return False

    config_path = project_root / "attackmacos" / "core" / "config" / f"{stem}.yml"
    if config_path.exists() and not force:
        print(f"SKIP {stem}: exists {config_path.name}")
        return False

    procedure_data = convert(loobin_path, template_path)
    apply_promotion_metadata(procedure_data, entry)
    save_yaml(procedure_data, config_path)
    if not validate_config_yaml(project_root, config_path):
        config_path.unlink(missing_ok=True)
        print(f"FAIL {stem}: schema validation failed")
        return False
    print(f"PROMOTED {stem} -> {config_path.name} ({entry['ttp_id']})")
    return True


def promote_all_standby(template_path: Path, project_root: Path, force: bool = False) -> None:
    standby_dir = project_root / "attackmacos" / "standby" / "LOOBins"
    ymls = sorted(p for p in standby_dir.glob("*.yml") if p.is_file() and p.name != "TTP_OVERLAY.yml")
    ok = 0
    for path in ymls:
        if promote_loobin_file(path, template_path, project_root, force=force):
            ok += 1
    print(f"Promoted {ok}/{len(ymls)} procedure(s). Next: cicd/build/build_shell_procedure.py --all --force")


FILLER_WORDS = frozenset(
    {
        "a",
        "an",
        "the",
        "and",
        "or",
        "but",
        "in",
        "on",
        "at",
        "to",
        "for",
        "of",
        "with",
        "by",
    }
)


def load_yaml(path):
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def save_yaml(data, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, indent=2)


def slug_option(name):
    """Create --kebab-case option from LOOBins example title."""
    t = name.lower()
    t = re.sub(r"[^a-z0-9]+", "-", t)
    t = re.sub(r"-+", "-", t).strip("-")
    if len(t) > 70:
        t = t[:70].rstrip("-")
    return f"--{t}" if t else "--example"


def clean_function_name(name):
    words = name.lower().split()
    clean_words = [w for w in words if w not in FILLER_WORDS]
    base = "_".join(clean_words) if clean_words else "example"
    base = re.sub(r"[^a-z0-9_]", "_", base)
    base = re.sub(r"_+", "_", base).strip("_")
    return base[:80] if base else "example"


def cmd_var_for_binary(bin_name):
    return "CMD_" + bin_name.upper().replace("-", "_")


def map_metadata(template, loobin_data):
    ex = loobin_data.get("example_use_cases") or []
    if ex and ex[0].get("tactics"):
        template["tactic"] = ex[0]["tactics"][0]
    else:
        template["tactic"] = "Discovery"
    template["procedure_name"] = loobin_data["name"].lower()
    template["intent"] = (loobin_data.get("short_description") or f"Execute {loobin_data['name']} commands")[:500]
    template["author"] = loobin_data.get("author", "@darmado | https://x.com/darmad0")
    template["created"] = str(loobin_data.get("created", datetime.now().strftime("%Y-%m-%d")))
    template["updated"] = "$UPDATED"
    template["version"] = "1.0.0"
    template["ttp_id"] = "T9999"
    template["guid"] = "$GUID"
    template["platform"] = ["darwin"]
    resources_link = {
        "link": "https://www.loobins.io/",
        "description": "LOOBins — Living Off The Orchard macOS binaries",
    }
    template.setdefault("resources", [])
    if not any(r.get("link") == resources_link["link"] for r in template["resources"]):
        template["resources"].insert(0, resources_link)


def map_arguments(template, loobin_data):
    template["procedure"]["arguments"] = []
    for example in loobin_data.get("example_use_cases", []):
        opt = slug_option(example["name"])
        fname = "execute_" + clean_function_name(example["name"])
        desc = (example.get("description") or example["name"])[:100]
        template["procedure"]["arguments"].append(
            {"option": opt, "description": desc, "execute_function": [fname]}
        )


def map_global_variables(template, loobin_data):
    bin_name = loobin_data["name"]
    binary_path = loobin_data.get("paths", [f"/usr/bin/{bin_name}"])[0]
    template["procedure"]["global_variable"] = [
        {
            "name": cmd_var_for_binary(bin_name),
            "type": "string",
            "default_value": binary_path,
        }
    ]


def language_from_tags(tags):
    if not tags:
        return ["shell"]
    tag = tags[0].lower()
    if tag in ("bash", "zsh", "sh", "oneliner"):
        return ["shell"]
    mapping = {
        "python": ["python"],
        "javascript": ["javascript"],
        "swift": ["swift"],
        "applescript": ["applescript"],
    }
    return mapping.get(tag, ["shell"])


def map_functions(template, loobin_data):
    template["procedure"]["functions"] = []
    for i, example in enumerate(loobin_data.get("example_use_cases", [])):
        fname = "execute_" + clean_function_name(example["name"])
        code = example.get("code", "true")
        block = f"""{fname}() {{
    local result
    result=$({code} 2>&1)
    $CMD_PRINTF "RESULT|%s\\n" "$result"
    return 0
}}"""
        template["procedure"]["functions"].append(
            {
                "name": fname,
                "type": "main",
                "language": language_from_tags(example.get("tags") or []),
                "opsec": {
                    "check_fda": {
                        "enabled": False,
                        "exit_on_failure": True,
                    }
                },
                "code": block,
            }
        )


def map_optional_sections(template, loobin_data):
    if "resources" in loobin_data and loobin_data["resources"]:
        for r in loobin_data["resources"]:
            url = (r.get("url") or "").strip()
            if not url or url == "N/A":
                continue
            entry = {"link": url, "description": r.get("name", "")}
            if not any(x.get("link") == entry["link"] for x in template.get("resources", [])):
                template.setdefault("resources", []).append(entry)
    if "detections" in loobin_data:
        template["detection"] = [
            {"ioc": d["name"], "analysis": d.get("url", "")}
            for d in loobin_data["detections"]
            if d.get("url") not in ("N/A", "", None)
        ]


def convert(loobin_path, template_path):
    template = load_yaml(template_path)
    loobin_data = load_yaml(loobin_path)
    if not loobin_data.get("example_use_cases"):
        raise ValueError("LOOBin YAML must contain at least one example_use_cases entry")
    map_metadata(template, loobin_data)
    map_arguments(template, loobin_data)
    map_global_variables(template, loobin_data)
    map_functions(template, loobin_data)
    map_optional_sections(template, loobin_data)
    return template


def write_procedure_yaml(loobin_path: Path, template_path: Path, project_root: Path) -> Path:
    """Convert one standby LOOBin YAML and write staging procedure YAML. Returns output path."""
    procedure_data = convert(loobin_path, template_path)
    staging_dir = project_root / "attackmacos" / "standby" / "LOOBins" / "staging"
    output_path = staging_dir / f"{loobin_path.stem}.yml"
    save_yaml(procedure_data, output_path)
    return output_path


def main():
    argv = sys.argv[1:]
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent.parent
    template_path = project_root / "attackmacos" / "core" / "templates" / "procedure.yml"

    force_promote = "--force" in argv
    if force_promote:
        argv = [a for a in argv if a != "--force"]

    if len(argv) == 1 and argv[0] == "--write-ttp-overlay":
        out = write_ttp_overlay(project_root)
        print(f"Wrote {out}")
        sys.exit(0)

    if len(argv) == 1 and argv[0] in ("--promote-all", "--promote-standby"):
        promote_all_standby(template_path, project_root, force=force_promote)
        sys.exit(0)

    if len(argv) == 1 and argv[0] in ("--all-standby", "--all"):
        standby_dir = project_root / "attackmacos" / "standby" / "LOOBins"
        ymls = sorted(p for p in standby_dir.glob("*.yml") if p.is_file())
        if not ymls:
            print(f"No *.yml files under {standby_dir}")
            sys.exit(1)
        ok = 0
        for loobin_path in ymls:
            try:
                out = write_procedure_yaml(loobin_path, template_path, project_root)
                print(f"OK {loobin_path.name} -> {out}")
                ok += 1
            except (ValueError, OSError, yaml.YAMLError) as exc:
                print(f"SKIP {loobin_path.name}: {exc}", file=sys.stderr)
        print(f"Converted {ok}/{len(ymls)} file(s). Next: replace T9999, review, copy to attackmacos/core/config/, build.")
        sys.exit(0 if ok else 1)

    if len(argv) != 1:
        print(
            "Usage: python3 cicd/sync/convert_loobin_to_procedure.py <attackmacos/standby/LOOBins/<binary>.yml>\n"
            "   or: python3 cicd/sync/convert_loobin_to_procedure.py --all-standby\n"
            "   or: python3 cicd/sync/convert_loobin_to_procedure.py --write-ttp-overlay\n"
            "   or: python3 cicd/sync/convert_loobin_to_procedure.py [--force] --promote-all"
        )
        sys.exit(1)

    loobin_path = Path(argv[0]).resolve()
    if not loobin_path.is_file():
        print(f"File not found: {loobin_path}")
        sys.exit(1)

    output_path = write_procedure_yaml(loobin_path, template_path, project_root)
    print(f"Wrote draft procedure YAML: {output_path}")
    print("Next: set ttp_id (replace T9999), review functions, copy to attackmacos/core/config/, run cicd/build/build_shell_procedure.py")


if __name__ == "__main__":
    main()
