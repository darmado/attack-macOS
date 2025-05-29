#!/bin/bash

# Generic Script Option Tester
# Purpose: Automatically discover and test all options for any script
# Usage: ./test_script_options.sh <script_path>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_PATH=""
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "PASS") echo -e "${GREEN}[PASS]${NC} $message" ;;
        "FAIL") echo -e "${RED}[FAIL]${NC} $message" ;;
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
    esac
}

# Function to extract technique options from YAML file
extract_technique_options() {
    local script="$1"
    local yaml_file="${script%.sh}.yaml"
    
    # Check if YAML file exists
    if [ ! -f "$yaml_file" ]; then
        print_status "WARN" "YAML file not found: $yaml_file"
        return 1
    fi
    
    # Extract options from YAML arguments section and split short/long forms
    grep 'option:' "$yaml_file" | sed 's/.*option: *"//' | sed 's/".*//' | \
    while IFS= read -r option; do
        if [[ "$option" == *"|"* ]]; then
            # Split combined options like "-a|--all" and output each separately
            echo "$option" | sed 's/|/\n/g'
        else
            # Single option
            echo "$option"
        fi
    done | sort -u
}

# Function to extract base.sh output processing options
extract_output_options() {
    local script="$1"
    local help_output=""
    
    # Get help output
    for flag in "--help" "-h" "help"; do
        if help_output=$("$script" "$flag" 2>&1); then
            break
        fi
    done
    
    # Extract only base.sh output processing options
    echo "$help_output" | grep -E '(--format|--encode|--encrypt|--exfil)' | \
        sed -E 's/^\s*(-{1,2}[a-zA-Z0-9_-]+).*/\1/' | \
        sort -u
}

# Function to test a single command
test_command() {
    local cmd="$1"
    local description="$2"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    print_status "INFO" "Testing: $cmd"
    
    # Run the command with timeout
    local output=""
    local exit_code=0
    
    if output=$(timeout 5s $cmd 2>&1); then
        exit_code=$?
    else
        exit_code=$?
    fi
    
    # Check if command succeeded (exit code 0)
    if [ $exit_code -eq 0 ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_status "PASS" "$description"
        if [ -n "$output" ]; then
            echo "    Output: $(echo "$output" | head -1 | cut -c1-60)..."
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        print_status "FAIL" "$description (exit code: $exit_code)"
        if [ -n "$output" ]; then
            echo "    Error: $(echo "$output" | head -1 | cut -c1-60)..."
        fi
    fi
    
    echo ""
}

# Function to test technique options first
test_technique_options() {
    local script="$1"
    
    print_status "INFO" "=== PHASE 1: Testing Technique Options ==="
    echo ""
    
    # Extract technique options
    local options=$(extract_technique_options "$script")
    
    if [ -z "$options" ]; then
        print_status "WARN" "No technique options found"
        return 1
    fi
    
    print_status "INFO" "Found technique options: $(echo $options | tr '\n' ' ')"
    echo ""
    
    # Test each technique option individually
    for option in $options; do
        test_command "$script $option" "Technique: $option"
    done
}

# Function to test output processing with technique options
test_output_processing() {
    local script="$1"
    
    print_status "INFO" "=== PHASE 2: Testing Output Processing ==="
    echo ""
    
    # Get one working technique option for testing output processing
    local technique_options=$(extract_technique_options "$script")
    local test_option=$(echo "$technique_options" | head -1)
    
    if [ -z "$test_option" ]; then
        print_status "WARN" "No technique option available for output testing"
        return 1
    fi
    
    print_status "INFO" "Using technique option '$test_option' for output processing tests"
    echo ""
    
    # Test common output processing combinations
    local output_tests=(
        "--format json"
        "--format csv"
        "--encode base64"
        "--encode hex"
    )
    
    for output_test in "${output_tests[@]}"; do
        test_command "$script $test_option $output_test" "Output: $test_option + $output_test"
    done
}

# Function to print summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "TEST SUMMARY"
    echo "=========================================="
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"
    
    if [ $FAIL_COUNT -eq 0 ]; then
        print_status "PASS" "All tests passed!"
    else
        print_status "FAIL" "$FAIL_COUNT tests failed"
    fi
    echo "=========================================="
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <script_path>"
        echo "Example: $0 ./1087_account_discovery.sh"
        exit 1
    fi
    
    SCRIPT_PATH="$1"
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        print_status "FAIL" "Script not found: $SCRIPT_PATH"
        exit 1
    fi
    
    if [ ! -x "$SCRIPT_PATH" ]; then
        print_status "FAIL" "Script not executable: $SCRIPT_PATH"
        exit 1
    fi
    
    echo "=========================================="
    echo "IMPROVED SCRIPT OPTION TESTER"
    echo "=========================================="
    echo "Script: $SCRIPT_PATH"
    echo "Time: $(date)"
    echo "=========================================="
    echo ""
    
    # Test help first
    test_command "$SCRIPT_PATH --help" "Help output"
    
    # Phase 1: Test all technique options
    test_technique_options "$SCRIPT_PATH"
    
    # Phase 2: Test output processing with technique options
    test_output_processing "$SCRIPT_PATH"
    
    print_summary
}

# Run main function
main "$@" 