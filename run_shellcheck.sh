#!/bin/bash

# Run ShellCheck on all .sh files in the ttp directory
find ttp -name "*.sh" -print0 | xargs -0 tools/shellcheck/shellcheck
