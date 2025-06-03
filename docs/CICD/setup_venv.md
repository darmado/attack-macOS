# Python Environment Setup

Modern Python environment setup for attack-macOS build tools (2025).

## Recommended: uv

```bash
# Install uv (fastest Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Run tools directly without environment management
uv run cicd/build_shell_procedure.py --all
uv run cicd/sync_function_docs.py
```

## Alternative: pipx

```bash
# Install tools globally with isolated dependencies
pipx install --include-deps pyyaml
pipx install --include-deps jsonschema
python3 cicd/build_shell_procedure.py --all
```

## CI/CD Integration

### GitHub Actions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - run: uv run cicd/build_shell_procedure.py --all
```

### GitLab CI

```yaml
build:
  image: python:3.12
  before_script:
    - pip install uv
  script:
    - uv run cicd/build_shell_procedure.py --all
```

### Docker

```dockerfile
FROM python:3.12-slim
RUN pip install uv
WORKDIR /app
COPY . .
CMD ["uv", "run", "cicd/build_shell_procedure.py", "--help"]
```

## Development Container

```json
{
  "image": "python:3.12",
  "features": {
    "ghcr.io/astral-sh/uv-devcontainer-feature/uv": {}
  },
  "postCreateCommand": "uv sync"
}
```

## Traditional Setup (Legacy)

```bash
python3 -m venv venv
source venv/bin/activate  
pip install pyyaml jsonschema
```

## Requirements

- Python 3.9+
- uv (recommended) or pip
- Internet access for package downloads

## Dependencies

```toml
# pyproject.toml
[project]
dependencies = [
    "pyyaml>=6.0",
    "jsonschema>=4.0"
]
``` 