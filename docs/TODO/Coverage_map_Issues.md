# TODO: Coverage Map Script Fixes

## Priority 1: Path Mismatch Issues

### Problem
The `ttp_to_script` dictionary in `build_coverage_map.py` contains incorrect paths that don't match the actual file structure:

**Mapped Paths (incorrect):**
```python
"T1087.001": "ttp/discovery/accounts.sh",
"T1555.001": "ttp/credential_access/keychain.sh",
"T1217": "ttp/discovery/browser_history.sh",
```

**Actual File Structure:**
```
attackmacos/ttp/discovery/shell/local_accounts.sh
attackmacos/ttp/credential_access/shell/keychain.sh
attackmacos/ttp/discovery/shell/ (no browser_history.sh found)
```

### Impact
- Broken links in the generated macOS Procedure Matrix
- Users clicking badges get 404 errors
- Inaccurate representation of actual script availability

### Solution Requirements
1. **Audit all script mappings** against actual filesystem
2. **Update paths** to match real file locations
3. **Handle multiple scripts per TTP** (e.g., local_accounts.sh vs find_account_defaults.sh for T1087.001)
4. **Remove mappings** for non-existent scripts

---

## Priority 2: Data Management Issues

### Problem
TTP classifications are hardcoded and manually maintained:
- `ttp_green` dictionary (completed techniques)
- `ttp_yellow` list (work in progress)
- `ttp_to_script` dictionary (script mappings)

### Impact
- Manual updates required for every new script
- Risk of outdated/incorrect classifications
- No single source of truth

### Solution Options
1. **Filesystem Discovery**: Automatically detect scripts and classify based on presence/testing status
2. **Metadata Files**: YAML/JSON files in each TTP directory with classification info
3. **Script Headers**: Embed classification metadata in script comments

---

## Priority 3: Statistics Accuracy

### Current Issues
1. **Incomplete counting**: Only green TTPs count toward "implemented techniques"
2. **Arbitrary estimates**: 20 procedures per technique assumption
3. **Missing yellow metrics**: No separate tracking of work-in-progress

### Proposed Metrics
- **Total Techniques**: All macOS techniques from MITRE
- **Implemented Techniques**: Green + Yellow TTPs
- **Completed Techniques**: Only Green TTPs  
- **Actual Procedures**: Count from filesystem, not estimates
- **Coverage Percentage**: Based on real implementation status

---

## Priority 4: Link Management

### Problem
- Green TTPs have script links, Yellow TTPs don't
- Some TTPs map to same script (multiple procedures in one file)
- Links point to non-existent files

### Solution
1. **Consistent linking**: All implemented TTPs should have links
2. **Multiple procedures**: Support linking to specific procedures within scripts
3. **Link validation**: Verify all links work before generation

---

## Implementation Approach

### Phase 1: Quick Fix
- [ ] Audit existing 11 green TTPs
- [ ] Fix paths for confirmed working scripts
- [ ] Remove mappings for non-existent scripts
- [ ] Update matrix generation

### Phase 2: Automation
- [ ] Create filesystem discovery logic
- [ ] Implement automatic TTP classification
- [ ] Add link validation
- [ ] Update statistics calculations

### Phase 3: Maintenance
- [ ] CI/CD integration for automatic updates
- [ ] Documentation for TTP classification process
- [ ] Regular audit procedures

---

## Files to Investigate

1. **Script Structure Audit:**
   ```bash
   find attackmacos/ttp -name "*.sh" -type f | sort
   ```

2. **Current Green TTPs:**
   - T1087.001: Local Account Discovery
   - T1555.001: Keychain Access
   - T1217: Browser Information Discovery
   - T1518.001: Security Software Discovery
   - T1078: Valid Accounts
   - T1140: Deobfuscate/Decode Files
   - T1027.001: Binary Padding
   - T1059.006: Python Execution
   - T1027.003: Steganography
   - T1027: Obfuscated Files
   - T1041: Exfiltration Over C2

3. **Files to Check:**
   - `cicd/build_coverage_map.py` (main script)
   - `docs/MITRE ATT&CK/macOS Procedure Matrix.md` (output)
   - `attackmacos/ttp/*/shell/*.sh` (actual scripts)

---

## Estimated Effort
- **Phase 1**: 4-6 hours (path fixing and validation)
- **Phase 2**: 8-12 hours (automation and discovery logic)  
- **Phase 3**: 2-4 hours (CI/CD integration and docs)

**Total**: 14-22 hours for complete solution 