# test_script_options.dev.sh

Tests generated shell scripts for proper argument parsing and option handling.

## Purpose

Validates that generated shell scripts correctly implement command-line options, argument parsing, and help functionality. Ensures scripts meet quality standards before deployment.

## CI/CD Integration

### GitHub Actions - Script Testing

```yaml
name: Test Generated Scripts
on:
  push:
    paths:
      - 'attackmacos/**/*.sh'
  pull_request:
    paths:
      - 'attackmacos/**/*.sh'

jobs:
  test-scripts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test script options
        run: bash cicd/test_script_options.dev.sh
      - name: Validate specific script
        run: bash cicd/test_script_options.dev.sh attackmacos/discovery/technique_T1082/system_info_v1.0.sh
```

### GitLab CI - Quality Gate

```yaml
test-script-quality:
  stage: test
  script:
    - bash cicd/test_script_options.dev.sh
  only:
    changes:
      - attackmacos/**/*.sh
  allow_failure: false

validate-individual-scripts:
  stage: test
  script:
    - |
      for script in $(find attackmacos -name "*.sh" -type f); do
        echo "Testing $script..."
        bash cicd/test_script_options.dev.sh "$script"
      done
  only:
    changes:
      - attackmacos/**/*.sh
```

### Jenkins Pipeline - Script Validation

```groovy
pipeline {
    agent any
    stages {
        stage('Test Scripts') {
            when {
                changeset "attackmacos/**/*.sh"
            }
            steps {
                script {
                    def scripts = sh(
                        script: 'find attackmacos -name "*.sh" -type f',
                        returnStdout: true
                    ).trim().split('\n')
                    
                    sh 'bash cicd/test_script_options.dev.sh'
                    
                    for (script in scripts) {
                        sh "bash cicd/test_script_options.dev.sh ${script}"
                    }
                }
            }
        }
    }
}
```

## Usage

```bash
# Test all scripts
bash cicd/test_script_options.dev.sh

# Test specific script
bash cicd/test_script_options.dev.sh attackmacos/discovery/system_info_v1.0.sh

# Verbose testing
VERBOSE=1 bash cicd/test_script_options.dev.sh

# Test with custom timeout
TIMEOUT=30 bash cicd/test_script_options.dev.sh
```

## Test Coverage

### Help Functionality
- Validates `--help` option exists
- Checks help text formatting
- Ensures usage examples present

### Argument Parsing
- Tests valid option combinations
- Validates input requirements
- Checks error handling

### Output Formats
- Tests `--format json` option
- Validates JSON structure
- Checks encoding options

### Error Conditions
- Invalid arguments
- Missing required inputs
- Permission failures

## Automation Patterns

### Pre-commit Hook - Script Validation

```bash
#!/bin/bash
# .git/hooks/pre-commit
for file in $(git diff --cached --name-only | grep '\.sh$'); do
    if [[ "$file" == attackmacos/* ]]; then
        echo "Testing $file..."
        if ! bash cicd/test_script_options.dev.sh "$file"; then
            echo "Script test failed for $file"
            exit 1
        fi
    fi
done
```

### Azure DevOps - Parallel Testing

```yaml
trigger:
  paths:
    include:
      - attackmacos/*.sh

strategy:
  matrix:
    discovery:
      SCRIPT_PATH: 'attackmacos/discovery'
    credential_access:
      SCRIPT_PATH: 'attackmacos/credential_access'
    collection:
      SCRIPT_PATH: 'attackmacos/collection'

pool:
  vmImage: 'ubuntu-latest'

steps:
- script: |
    for script in $(find $(SCRIPT_PATH) -name "*.sh" 2>/dev/null || true); do
      echo "Testing $script"
      bash cicd/test_script_options.dev.sh "$script"
    done
  displayName: 'Test scripts in $(SCRIPT_PATH)'
```

### Docker Testing Environment

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y bash shellcheck
COPY cicd/test_script_options.dev.sh /test/
COPY attackmacos/ /scripts/
WORKDIR /test
CMD ["bash", "test_script_options.dev.sh"]
```

```bash
# Run tests in container
docker build -t script-tester .
docker run --rm script-tester
```

## Integration Examples

### Quality Gate Script

```bash
#!/bin/bash
# quality_gate.sh
set -e

echo "Running script quality checks..."

# Test all generated scripts
bash cicd/test_script_options.dev.sh

# Run shellcheck if available
if command -v shellcheck >/dev/null 2>&1; then
    echo "Running shellcheck..."
    find attackmacos -name "*.sh" -exec shellcheck {} \;
fi

# Check script permissions
echo "Checking permissions..."
find attackmacos -name "*.sh" ! -perm 755 -exec chmod 755 {} \;

echo "✅ All quality checks passed"
```

### Continuous Integration Chain

```yaml
# GitHub Actions - Complete CI chain
name: CI Pipeline
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup environment
        run: bash cicd/setup_venv.sh
      - name: Build procedures
        run: |
          source cicd/venv/bin/activate
          python3 cicd/build_shell_procedure.py --all --force
      - name: Test generated scripts
        run: bash cicd/test_script_options.dev.sh
      - name: Sync documentation
        run: |
          source cicd/venv/bin/activate
          python3 cicd/sync_function_docs.py
```

### Performance Testing

```bash
#!/bin/bash
# performance_test.sh
SCRIPT="$1"
ITERATIONS=10

echo "Performance testing $SCRIPT..."

for i in $(seq 1 $ITERATIONS); do
    start_time=$(date +%s.%N)
    bash cicd/test_script_options.dev.sh "$SCRIPT" >/dev/null 2>&1
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    echo "Iteration $i: ${duration}s"
done
```

## Configuration

### Environment Variables

```bash
# Test timeout (default: 10 seconds)
export TEST_TIMEOUT=30

# Verbose output
export VERBOSE=1

# Skip certain tests
export SKIP_HELP_TEST=1
export SKIP_JSON_TEST=1

# Custom test patterns
export TEST_PATTERN="--help|--format|--output"
```

### Test Configuration File

```bash
# test_config.sh
TEST_TIMEOUT=30
VERBOSE=1
REQUIRED_OPTIONS="--help --format json --output"
SKIP_SCRIPTS="legacy_* test_*"
```

## Error Handling

- **Script Not Found**: Provides clear error message
- **Permission Denied**: Suggests chmod fixes
- **Timeout**: Reports slow-running tests
- **Parse Errors**: Shows specific argument issues

## Requirements

- Bash 4.0+
- Standard Unix utilities (grep, awk, timeout)
- Execute permissions on test scripts

## Dependencies

None. Uses bash built-ins and standard Unix tools. 