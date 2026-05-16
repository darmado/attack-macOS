# Shipped procedures: upstream sources and maintainer scripts

## Purpose

List where shipped procedure YAML is defined, which upstream catalogs relate to it, why those catalogs exist in the workflow, and which `cicd/` scripts fetch, extract, convert, or build. One index for reviewers and integrators.

## Assumptions

1. Shipped procedures are the YAML files under `attackmacos/core/config/`, reviewed and merged through the same version-control process as the rest of the repository.
2. Content under `attackmacos/standby/` is staging or upstream-shaped data; it is not treated as equivalent to `core/config/` for release or trust decisions unless explicitly promoted after review.
3. Organizations that run `cicd/` fetch or convert tools control the execution environment (access to the working tree, network egress, and operator accounts) according to their own policies.
4. MITRE ATT&CK identifiers in procedures are used for classification and reporting; ATT&CK itself does not supply executable procedure bodies in this repository.

## Audience

Security engineers, detection engineers, auditors, and integrators who need a single reference for provenance and tooling around procedures.

## Scope

- In scope: sources that define or influence procedures, rationale for their use, maintainer Python under `cicd/` that fetches or converts upstream artifacts, and links to deeper technical documents.
- Out of scope: Step-by-step author guides (`docs/Guides/`), full bibliography of every research link (`docs/R&D References.md`), runtime behavior of generated shell or JXA on endpoints.

## Details

### Sources, roles, rationale, and supporting scripts

| Source | Role in this repository | Rationale (source value) | Supporting scripts (maintainer) |
|--------|-------------------------|--------------------------|-----------------------------------|
| MITRE ATT&CK (Enterprise, including macOS matrix) | Technique and tactic vocabulary for procedure metadata | Shared industry taxonomy for reporting, mapping, and purple-team alignment | None; identifiers are chosen during authoring (`docs/Guides/How To/Add a Procedure from MITRE ATT&CK.md`) |
| Human-authored YAML in `attackmacos/core/config/` | Canonical procedure definitions consumed by builders | Full control over schema, native-only execution constraints, and review workflow | `cicd/build/procedure_shell.py`, `cicd/build/procedure_jxa.py` |
| LOOBins ([loobins.io](https://www.loobins.io/), upstream [LOOBins](https://github.com/infosecB/LOOBins)) | Curated native-binary documentation used to draft procedure YAML | macOS-focused LOLBin reference aligned with shell-first procedures | `cicd/fetch/fetch_loobins.py`, `cicd/extract/extract_loobin_from_json.py`, `cicd/convert/convert_loobin_to_procedure.py`, shared `cicd/convert/convert_common.py` |
| Atomic Red Team ([atomic-red-team](https://github.com/redcanaryco/atomic-red-team)) | macOS-relevant atomic tests used as reference and optional draft input | Large public catalog for parity and ideas; drafts still require maintainer review before `core/config/` | `cicd/fetch/fetch_atomic_red_team.py`, `cicd/convert/convert_atomic_to_procedure.py`, shared `cicd/convert/convert_common.py` |
| MITRE Caldera ([Caldera](https://github.com/mitre/caldera)) | Export target for abilities derived from built procedures | Integration with adversary emulation platforms that consume pre-built abilities | `cicd/build/procedure_shell.py` (`--sync-caldera`); not a source of `core/config/` YAML |
| Third-party publications (examples below) | Context and citations in procedure `resources:` and maintainer research | Behavior descriptions, detection notes, and vendor or community analysis | None automated; citations are edited into YAML by maintainers |

Representative publication and framework URLs (not exhaustive; the table above remains authoritative for pipeline behavior):

- MITRE ATT&CK: `https://attack.mitre.org/`
- Apple Platform Security Guide: `https://support.apple.com/guide/security/welcome/web`
- Apple Security framework documentation: `https://developer.apple.com/documentation/security`
- Objective-See: `https://objective-see.com/blog.html`
- NIST macOS security guidance (example): `https://github.com/usnistgov/macos_security`

Additional rows and licenses appear in `docs/R&D References.md`.

### Pipeline by material (fetch through build)

Commands are run from the repository root. Draft outputs require human review before promotion to `attackmacos/core/config/`.

| Material | Fetch | Extract | Convert (draft) | Build |
|----------|-------|---------|-----------------|-------|
| LOOBins | `python3 cicd/fetch/fetch_loobins.py catalog`; optional `binary <name>` | `python3 cicd/extract/extract_loobin_from_json.py <name>` | `python3 cicd/convert/convert_loobin_to_procedure.py` | After promotion to `core/config/`: `python3 cicd/build/procedure_shell.py` / `procedure_jxa.py` |
| Atomic Red Team | `python3 cicd/fetch/fetch_atomic_red_team.py --all` | Selection via converter flags | `python3 cicd/convert/convert_atomic_to_procedure.py` | Same as LOOBins row |
| MITRE-only or custom design | N/A | N/A | N/A | Author in `core/config/` per Guides; then builders |

### Frequently asked questions

- **Where do shipped TTP definitions live?** In `attackmacos/core/config/*.yml`, built to `attackmacos/ttp/` by the builders named above.
- **Are LOOBins or ART authoritative for production YAML?** No. They may feed drafts in `standby/`; production YAML is reviewed project content in `core/config/`.
- **What is `standby/`?** Staging for fetched or draft artifacts; separate trust expectations from `core/config/` by policy.
- **Where are field mappings documented?** LOOBins: `docs/CICD/LOOBins_to_Procedure_Mapping.md`. ART: `docs/CICD/ART_to_Procedure.md`.

## Exceptions

- Some procedures may cite sources that are not listed in this document; the procedure YAML `resources:` section is the per-technique record.
- Caldera sync produces plugin-oriented outputs; it does not rewrite `core/config/`.

## References

- `docs/Standards/README.md` — coding and documentation norms
- `docs/Guides/README.md`
- `docs/CICD/LOOBins_to_Procedure_Mapping.md`
- `docs/CICD/ART_to_Procedure.md`
- `docs/R&D References.md`
- `cicd/README.md`
- `SECURITY.md`

---

Last modified: 2026-05-15  
Last modified by: Documentation maintainers  
Version: 1.2.0
