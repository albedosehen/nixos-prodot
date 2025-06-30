#!/usr/bin/env bash

#===============================================================================
# Auto-Setup Script Test
#===============================================================================
# This script tests the critical functions and security fixes in auto-setup.sh
# without actually executing the full setup process.

set -euo pipefail

# Source the auto-setup script to access its functions
source scripts/auto-setup.sh

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Color definitions for test output
readonly TEST_GREEN='\033[0;32m'
readonly TEST_RED='\033[0;31m'
readonly TEST_YELLOW='\033[1;33m'
readonly TEST_BLUE='\033[0;34m'
readonly TEST_NC='\033[0m'

#===============================================================================
# TEST UTILITY FUNCTIONS
#===============================================================================

test_header() {
  echo -e "\n${TEST_BLUE}=== $1 ===${TEST_NC}"
}

test_case() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [[ $expected == "$actual" ]]; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: $test_name"
    echo -e "   Expected: $expected"
    echo -e "   Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_function_exists() {
  local func_name="$1"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if declare -f "$func_name" >/dev/null; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Function $func_name exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Function $func_name does not exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

#===============================================================================
# INPUT VALIDATION TESTS
#===============================================================================

test_input_validation() {
  test_header "Input Validation Functions"

  # Test username validation
  test_case "Valid username (alphanumeric)" "0" "$(validate_username "testuser123" && echo 0 || echo 1)"
  test_case "Valid username (with underscore)" "0" "$(validate_username "test_user" && echo 0 || echo 1)"
  test_case "Valid username (with hyphen)" "0" "$(validate_username "test-user" && echo 0 || echo 1)"
  test_case "Invalid username (starts with hyphen)" "1" "$(validate_username "-testuser" && echo 0 || echo 1)"
  test_case "Invalid username (too long)" "1" "$(validate_username "$(printf 'a%.0s' {1..33})" && echo 0 || echo 1)"
  test_case "Invalid username (empty)" "1" "$(validate_username "" && echo 0 || echo 1)"
  test_case "Invalid username (special chars)" "1" "$(validate_username "test@user" && echo 0 || echo 1)"

  # Test hostname validation
  test_case "Valid hostname (alphanumeric)" "0" "$(validate_hostname "testhost123" && echo 0 || echo 1)"
  test_case "Valid hostname (with hyphen)" "0" "$(validate_hostname "test-host" && echo 0 || echo 1)"
  test_case "Invalid hostname (starts with hyphen)" "1" "$(validate_hostname "-testhost" && echo 0 || echo 1)"
  test_case "Invalid hostname (ends with hyphen)" "1" "$(validate_hostname "testhost-" && echo 0 || echo 1)"
  test_case "Invalid hostname (too long)" "1" "$(validate_hostname "$(printf 'a%.0s' {1..64})" && echo 0 || echo 1)"
  test_case "Invalid hostname (special chars)" "1" "$(validate_hostname "test_host" && echo 0 || echo 1)"

  # Test email validation
  test_case "Valid email (basic)" "0" "$(validate_email "test@example.com" && echo 0 || echo 1)"
  test_case "Valid email (with dots)" "0" "$(validate_email "test.user@example.co.uk" && echo 0 || echo 1)"
  test_case "Valid email (with plus)" "0" "$(validate_email "test+tag@example.com" && echo 0 || echo 1)"
  test_case "Invalid email (no @)" "1" "$(validate_email "testexample.com" && echo 0 || echo 1)"
  test_case "Invalid email (no domain)" "1" "$(validate_email "test@" && echo 0 || echo 1)"
  test_case "Invalid email (no TLD)" "1" "$(validate_email "test@example" && echo 0 || echo 1)"

  # Test profile validation
  test_case "Valid profile (wsl)" "0" "$(validate_profile "wsl" && echo 0 || echo 1)"
  test_case "Valid profile (workstation)" "0" "$(validate_profile "workstation" && echo 0 || echo 1)"
  test_case "Valid profile (mobile)" "0" "$(validate_profile "mobile" && echo 0 || echo 1)"
  test_case "Invalid profile (desktop)" "1" "$(validate_profile "desktop" && echo 0 || echo 1)"
  test_case "Invalid profile (empty)" "1" "$(validate_profile "" && echo 0 || echo 1)"

  # Test git provider validation
  test_case "Valid git provider (github)" "0" "$(validate_git_provider "github" && echo 0 || echo 1)"
  test_case "Valid git provider (gitlab)" "0" "$(validate_git_provider "gitlab" && echo 0 || echo 1)"
  test_case "Valid git provider (bitbucket)" "0" "$(validate_git_provider "bitbucket" && echo 0 || echo 1)"
  test_case "Invalid git provider (gitea)" "1" "$(validate_git_provider "gitea" && echo 0 || echo 1)"
  test_case "Invalid git provider (empty)" "1" "$(validate_git_provider "" && echo 0 || echo 1)"
}

#===============================================================================
# ERROR HANDLING TESTS
#===============================================================================

test_error_handling() {
  test_header "Error Handling Functions"

  # Test that error handling functions exist
  test_function_exists "handle_error"
  test_function_exists "safe_exit"

  # Test error handling with debug output
  echo -e "${TEST_YELLOW}Testing error handling (expect debug output):${TEST_NC}"

  # Test handle_error function (capture output)
  local error_output
  error_output=$(DEBUG=1 handle_error 42 "Test error message" "123" 2>&1 || true)

  if [[ $error_output =~ "Test error message" && $error_output =~ "line: 123" ]]; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Error handling produces correct output"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Error handling output incorrect"
    echo "Output: $error_output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

#===============================================================================
# DEBUG LOGGING TESTS
#===============================================================================

test_debug_logging() {
  test_header "Debug Logging Functions"

  # Test debug logging when DEBUG=0
  local debug_output_off
  debug_output_off=$(DEBUG=0 print_debug "Test debug message" 2>&1 || true)
  test_case "Debug logging OFF (DEBUG=0)" "" "$debug_output_off"

  # Test debug logging when DEBUG=1
  local debug_output_on
  debug_output_on=$(DEBUG=1 print_debug "Test debug message" 2>&1 || true)
  if [[ $debug_output_on =~ "Test debug message" ]]; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Debug logging ON (DEBUG=1)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Debug logging ON (DEBUG=1)"
    echo "Output: $debug_output_on"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

#===============================================================================
# SECURITY TESTS
#===============================================================================

test_security_features() {
  test_header "Security Features"

  # Test that script uses secure file creation
  echo -e "${TEST_YELLOW}Testing secure temporary file creation:${TEST_NC}"

  # Check if mktemp is used for temporary files (grep the script)
  if grep -q "mktemp" scripts/auto-setup.sh; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Script uses mktemp for secure temporary files"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Script does not use mktemp for temporary files"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # Test hostname sanitization in sed commands
  if grep -q "sed.*s/\[" scripts/auto-setup.sh; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Script sanitizes hostname for sed commands"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Script may not sanitize hostname properly"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # Test backup file creation with timestamps
  if grep -q "backup.*date.*%Y%m%d_%H%M%S" scripts/auto-setup.sh; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Script creates timestamped backup files"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Script may not create proper backup files"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # Test atomic file operations
  if grep -q "mv.*temp.*vars.nix" scripts/auto-setup.sh; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Script uses atomic file operations"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Script may not use atomic file operations"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

#===============================================================================
# CONFIGURATION TESTS
#===============================================================================

test_configuration_options() {
  test_header "Configuration Options"

  # Test environment variable defaults
  local test_vars=(
    "NIXOS_PRODOT_REPO_URL"
    "NIXOS_PRODOT_CONFIG_DIR"
    "NIXOS_PRODOT_SSH_DIR"
    "NIXOS_PRODOT_SKIP_APPLY"
    "DEBUG"
  )

  for var in "${test_vars[@]}"; do
    if grep -q "$var" scripts/auto-setup.sh; then
      echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Environment variable $var is configurable"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Environment variable $var not found"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
  done
}

#===============================================================================
# STRUCTURE AND ORGANIZATION TESTS
#===============================================================================

test_script_structure() {
  test_header "Script Structure and Organization"

  # Test that script has proper sections
  local sections=(
    "GLOBAL CONFIGURATION AND CONSTANTS"
    "UTILITY FUNCTIONS - OUTPUT AND FORMATTING"
    "ERROR HANDLING FUNCTIONS"
    "INPUT VALIDATION FUNCTIONS"
    "USER INTERACTION FUNCTIONS"
    "SYSTEM VERIFICATION FUNCTIONS"
    "SETUP AND CONFIGURATION FUNCTIONS"
    "MAIN EXECUTION FUNCTION"
  )

  for section in "${sections[@]}"; do
    if grep -q "$section" scripts/auto-setup.sh; then
      echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Section '$section' exists"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Section '$section' missing"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
  done

  # Test that script has proper documentation
  if grep -q "^##$" scripts/auto-setup.sh; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Script has function documentation"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Script lacks proper function documentation"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  # Test that script has proper error handling setup
  if grep -q "set -euo pipefail" scripts/auto-setup.sh; then
    echo -e "${TEST_GREEN}✅ PASS${TEST_NC}: Script uses strict error handling (set -euo pipefail)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${TEST_RED}❌ FAIL${TEST_NC}: Script missing strict error handling"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

#===============================================================================
# MAIN TEST EXECUTION
#===============================================================================

main() {
  echo -e "${TEST_BLUE}===============================================================================${TEST_NC}"
  echo -e "${TEST_BLUE}                    Auto-Setup Script Validation Test Suite${TEST_NC}"
  echo -e "${TEST_BLUE}===============================================================================${TEST_NC}"

  # Run all test suites
  test_input_validation
  test_error_handling
  test_debug_logging
  test_security_features
  test_configuration_options
  test_script_structure

  # Print final results
  echo -e "\n${TEST_BLUE}===============================================================================${TEST_NC}"
  echo -e "${TEST_BLUE}                              TEST RESULTS${TEST_NC}"
  echo -e "${TEST_BLUE}===============================================================================${TEST_NC}"

  echo -e "Total Tests: $TOTAL_TESTS"
  echo -e "${TEST_GREEN}Passed: $TESTS_PASSED${TEST_NC}"
  echo -e "${TEST_RED}Failed: $TESTS_FAILED${TEST_NC}"

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${TEST_GREEN}🎉 ALL TESTS PASSED! The auto-setup script validation is complete.${TEST_NC}"
    exit 0
  else
    echo -e "\n${TEST_RED}❌ Some tests failed. Please review the issues above.${TEST_NC}"
    exit 1
  fi
}

# Run the test suite
main "$@"
