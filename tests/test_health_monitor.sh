#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/projects/server-health-monitor"
cd "$PROJECT_DIR"

echo "Running health monitor tests..."

# Test 1: Main script exists
if [[ -f "scripts/health_monitor.sh" ]]; then
    echo "PASS: Health monitor script exists"
else
    echo "FAIL: Health monitor script is missing"
    exit 1
fi

# Test 2: Configuration exists
if [[ -f "config/monitor.conf" ]]; then
    echo "PASS: Configuration file exists"
else
    echo "FAIL: Configuration file is missing"
    exit 1
fi

# Test 3: Bash syntax
if bash -n scripts/health_monitor.sh scripts/thresholds.sh; then
    echo "PASS: Bash syntax is valid"
else
    echo "FAIL: Syntax errors found"
    exit 1
fi

# Test logging function for capturing threshold results
log() {
    local level="$1"
    shift
    printf '[%-8s] %s\n' "$level" "$*"
}

# Load the actual production function
source scripts/thresholds.sh

# Test helper: checks the real check_threshold function
check_threshold_test() {
    local usage="$1"
    local warning="$2"
    local critical="$3"
    local expected="$4"
    local output

    output=$(check_threshold "Test" "$usage" "$warning" "$critical")

    if [[ "$output" == *"[$expected"* ]]; then
        echo "PASS: Usage ${usage}% -> ${expected}"
    else
        echo "FAIL: Usage ${usage}% expected ${expected}"
        echo "Actual output: $output"
        exit 1
    fi
}

# Test 4: Threshold behaviour
check_threshold_test 50 70 90 "OK"
check_threshold_test 70 70 90 "WARNING"
check_threshold_test 75 70 90 "WARNING"
check_threshold_test 90 70 90 "CRITICAL"
check_threshold_test 95 70 90 "CRITICAL"

echo "All tests passed!"
