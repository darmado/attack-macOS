# sync_function_docs.py

Syncs function implementations from base.sh to documentation files in Shell function library.

## Purpose

Maintains documentation consistency by automatically updating function code blocks when base.sh changes. Prevents documentation drift in projects with active development.

## CI/CD Integration

### GitHub Actions

```yaml
name: Sync Function Documentation
on:
  push:
    paths:
      - 'attackmacos/core/base/base.sh'
  pull_request:
    paths:
      - 'attackmacos/core/base/base.sh'

jobs:
  sync-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'
      - name: Sync function documentation
        run: python3 cicd/sync_function_docs.py
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/
          git diff --staged --quiet || git commit -m "Auto-sync function docs"
          git push
```

### GitLab CI

```yaml
sync-docs:
  stage: docs
  script:
    - python3 cicd/sync_function_docs.py
    - git add docs/
    - git diff --staged --quiet || git commit -m "Auto-sync function docs"
    - git push origin $CI_COMMIT_REF_NAME
  only:
    changes:
      - attackmacos/core/base/base.sh
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
if git diff --cached --name-only | grep -q "attackmacos/core/base/base.sh"; then
    python3 cicd/sync_function_docs.py
    git add docs/
fi
```

## Usage

```bash
# Basic execution
python3 cicd/sync_function_docs.py

# In automation
python3 cicd/sync_function_docs.py && git add docs/
```

## Process

1. **Extract Functions**: Parses `core_*()` patterns from base.sh
2. **Map Documentation**: Converts function names to doc filenames
3. **Update Code Blocks**: Replaces implementations in `docs/Functions/Shell/` files
4. **Report Status**: Shows updated, missing, and unchanged files

## Output

- **Files Updated**: Lists successfully synced documentation
- **Files Missing**: Reports docs that need creation
- **No Changes**: Shows files already current

## Requirements

- Python 3.6+
- Write access to docs/ directory
- Valid base.sh with core_* functions

## Automation Patterns

### Post-merge Hook

```bash
#!/bin/bash
# .git/hooks/post-merge
if git diff HEAD@{1} --name-only | grep -q "attackmacos/core/base/base.sh"; then
    python3 cicd/sync_function_docs.py
    if [ $? -eq 0 ]; then
        git add docs/
        git commit -m "Auto-sync function docs after merge"
    fi
fi
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Sync Docs') {
            when {
                changeset "attackmacos/core/base/base.sh"
            }
            steps {
                sh 'python3 cicd/sync_function_docs.py'
                sh 'git add docs/'
                sh 'git commit -m "Auto-sync function docs" || true'
            }
        }
    }
}
```

## Error Handling

Script continues on individual file errors and reports all issues at completion. Non-zero exit code only on critical failures (missing base.sh, permissions).

## Dependencies

None. Uses Python standard library only. 