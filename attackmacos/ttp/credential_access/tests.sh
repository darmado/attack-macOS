
# Script Name: keychain_access_test
# Description: This script sequentially runs all credential access commands from the keychain_credential_dump script to automate testing and debugging.

# Author: Daniel A. | github.com/darmado | x.com/darmad0
# Date: 2024-10-12
# Version: 1.0

# MITRE ATT&CK Technique: T1003.002

# Define all checks to be tested
declare -a CHECKS=(
  "keychain_dump"
  "find_generic_password"
  "find_internet_password"
  "find_certificate"
  "unlock_keychain"
  "export_items"
  "find_identity"
)

# Function to execute each check sequentially
run_checks() {
  for check in "${CHECKS[@]}"; do
    echo "\nRunning check: $check\n"
    sh keychain_credential_dump.sh --check=$check
    echo "\nCompleted check: $check\n"
  done
}

# Main function
main() {
  echo "Starting keychain access test script..."
  run_checks
  echo "All checks completed."
}

# Execute main function
main
