# build_shell_procedure.py

Builds executable shell scripts from YAML procedure definitions implementing MITRE ATT&CK techniques.

## Purpose

Converts YAML procedure files into production-ready shell scripts with logging, encoding, encryption, and exfiltration capabilities. Automates script generation for security testing frameworks.

## CI/CD Integration

### GitHub Actions - Build on YAML Changes

```yaml
name: Build Procedures
on:
  push:
    paths:
      - 'procedures/**/*.yml'
  pull_request:
    paths:
      - 'procedures/**/*.yml'

jobs:
  build-procedures:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'
      - name: Install dependencies
        run: pip install pyyaml jsonschema
      - name: Validate procedures
        run: |
          for file in procedures/**/*.yml; do
            python3 cicd/build_shell_procedure.py --validate "$file"
          done
      - name: Build all procedures
        run: python3 cicd/build_shell_procedure.py --all --force
      - name: Commit generated scripts
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add attackmacos/
          git diff --staged --quiet || git commit -m "Auto-build procedures"
          git push
```

### GitLab CI - Validation and Build

```yaml
validate-procedures:
  stage: validate
  script:
    - pip install pyyaml jsonschema
    - find procedures -name "*.yml" -exec python3 cicd/build_shell_procedure.py --validate {} \;
  only:
    changes:
      - procedures/**/*.yml

build-procedures:
  stage: build
  script:
    - pip install pyyaml jsonschema
    - python3 cicd/build_shell_procedure.py --all --force
    - git add attackmacos/
    - git diff --staged --quiet || git commit -m "Auto-build procedures"
    - git push origin $CI_COMMIT_REF_NAME
  only:
    changes:
      - procedures/**/*.yml
  dependencies:
    - validate-procedures
```

### Pre-commit Hook - Validation Only

```bash
#!/bin/bash
# .git/hooks/pre-commit
pip install pyyaml jsonschema > /dev/null 2>&1

for file in $(git diff --cached --name-only | grep '\.yml$'); do
    if [ -f "$file" ]; then
        echo "Validating $file..."
        if ! python3 cicd/build_shell_procedure.py --validate "$file"; then
            echo "Validation failed for $file"
            exit 1
        fi
    fi
done
```

## Usage

```bash
# Build single procedure
python3 cicd/build_shell_procedure.py system_info.yml

# Build all procedures
python3 cicd/build_shell_procedure.py --all

# Force overwrite existing scripts
python3 cicd/build_shell_procedure.py --all --force

# Validate YAML only
python3 cicd/build_shell_procedure.py --validate browser_history.yml
```

## Process

1. **Read YAML**: Loads procedure definition file
2. **Validate Schema**: Checks against JSON schema
3. **Generate Code**: Creates shell script components
4. **Write Script**: Outputs executable shell script
5. **Update GUID**: Generates unique identifier for tracking

## Output Structure

```
attackmacos/
└── ttp/
    ├── discovery/
    │   └── shell/
    │       ├── system_info.sh
    │       ├── system_info_v1.sh
    │       ├── test_system_info.sh
    │       └── browser_history.sh
    ├── credential_access/
    │   └── shell/
    │       └── keychain_dump.sh
    ├── collection/
    │   └── shell/
    │       └── clipboard_monitor.sh
    └── [other_tactics]/
        └── shell/
            └── [technique_scripts].sh
```

**File Naming**:
- Base script: `procedure_name.sh`
- Versioned: `procedure_name_v1.sh`, `procedure_name_v2.sh`
- Test files: `test_procedure_name.sh`

## Requirements

- Python 3.6+
- PyYAML
- jsonschema
- Valid YAML procedure files
- Write access to attackmacos/ directory

## Automation Patterns

### Jenkins Pipeline - Full Build

```groovy
pipeline {
    agent any
    stages {
        stage('Install Dependencies') {
            steps {
                sh 'pip install pyyaml jsonschema'
            }
        }
        stage('Validate') {
            steps {
                script {
                    def yamls = sh(
                        script: 'find procedures -name "*.yml"',
                        returnStdout: true
                    ).trim().split('\n')
                    
                    for (yaml in yamls) {
                        sh "python3 cicd/build_shell_procedure.py --validate ${yaml}"
                    }
                }
            }
        }
        stage('Build') {
            when {
                changeset "procedures/**/*.yml"
            }
            steps {
                sh 'python3 cicd/build_shell_procedure.py --all --force'
                sh 'git add attackmacos/'
                sh 'git commit -m "Auto-build procedures" || true'
            }
        }
    }
}
```

### Azure DevOps Pipeline

```yaml
trigger:
  paths:
    include:
      - procedures/*.yml

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.x'

- script: pip install pyyaml jsonschema
  displayName: 'Install dependencies'

- script: |
    for file in procedures/*.yml; do
      python3 cicd/build_shell_procedure.py --validate "$file"
    done
  displayName: 'Validate procedures'

- script: python3 cicd/build_shell_procedure.py --all --force
  displayName: 'Build procedures'

- script: |
    git config user.email "azure@devops.com"
    git config user.name "Azure DevOps"
    git add attackmacos/
    git diff --staged --quiet || git commit -m "Auto-build procedures"
    git push
  displayName: 'Commit generated scripts'
```

## Error Handling

- **YAML Syntax Errors**: Reports line and column of syntax issues
- **Schema Validation**: Shows specific validation failures with fix suggestions
- **File Permissions**: Handles write access errors gracefully
- **Missing Dependencies**: Validates required Python packages

## Integration Notes

- **Version Control**: Generated scripts include auto-versioning
- **Directory Structure**: Organizes by MITRE ATT&CK tactic and implementation language
- **Overwrite Protection**: Requires --force flag to overwrite existing scripts
- **Schema Validation**: Enforces consistent YAML structure across procedures

## Dependencies

- pyyaml: YAML parsing
- jsonschema: Schema validation 