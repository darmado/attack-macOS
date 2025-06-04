# CI/CD Tools Directory

Automation scripts for attack-macOS project maintenance and build processes.

## Tools

### Core Build Tools
- **[build_shell_procedure.py](docs/build_shell_procedure.md)** - Builds executable shell scripts from YAML procedure definitions
- **[sync_function_docs.py](docs/sync_function_docs.md)** - Syncs function implementations from base.sh to documentation files

### Environment Setup
- **[setup_venv.sh](docs/setup_venv.md)** - Creates isolated Python virtual environment with dependencies
- **requirements.txt** - Python package dependencies

### Security Tools  
- **[decrypt.py](docs/decrypt.md)** - Decrypts data encrypted by attack-macOS scripts

### Testing Tools
- **[test_script_options.dev.sh](docs/test_script_options.md)** - Tests generated shell scripts for proper option handling

### Development Tools
- **setup_builder.dev.sh** - Compiles build tools into standalone executables
- **build_python_procedure.py.dev** - Development version of Python procedure builder

## Quick Start

```bash
# Setup environment
bash setup_venv.sh

# Activate environment  
source venv/bin/activate

# Build all procedures
python3 build_shell_procedure.py --all

# Test generated scripts
bash test_script_options.dev.sh

# Sync documentation
python3 sync_function_docs.py
```

## CI/CD Integration

Each tool includes comprehensive CI/CD integration examples for:

- **GitHub Actions**
- **GitLab CI**  
- **Jenkins Pipeline**
- **Azure DevOps**
- **Docker Containers**

See individual tool documentation for specific integration patterns.

## Dependencies

- Python 3.6+
- PyYAML
- jsonschema  
- OpenSSL (for decrypt.py)
- GPG (for decrypt.py)

## Directory Structure

```
cicd/
├── docs/                    # Individual tool documentation
│   ├── build_shell_procedure.md
│   ├── sync_function_docs.md
│   ├── decrypt.md
│   ├── setup_venv.md
│   └── test_script_options.md
├── build_shell_procedure.py # Core build tool
├── sync_function_docs.py    # Documentation sync tool
├── decrypt.py               # Decryption tool
├── setup_venv.sh           # Environment setup
├── test_script_options.dev.sh # Script testing
└── requirements.txt        # Dependencies
``` 