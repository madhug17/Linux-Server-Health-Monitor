#!/usr/bin/env bash
set -e

echo "Running health monitor tests..."

# Test 1: Check that the main script exists
if [[ -f "scripts/health_monitor.sh" ]]; then
    echo "PASS: Health monitor script exists"
else
    echo "FAIL: Health monitor script is missing"
    exit 1
fi

# Test 2: Check that the configuration exists
if [[ -f "config/monitor.conf" ]]; then
    echo "PASS: Configuration file exists"
else
    echo "FAIL: Configuration file is missing"
    exit 1
fi

echo "All tests passed!"
# Test 3: Check Bash syntax
if bash -n scripts/health_monitor.sh; then
    echo "PASS: Health monitor script syntax is valid"
else
    echo "FAIL: Health monitor script contains syntax errors"
    exit 1
fi

check_threshold_test() {
    local usage="$1"
    local warning="$2"
    local critical="$3"
    local expected="$4"
    local actual
    if (( usage >= critical )); then
	actual="Critical"
    elif (( usage >= warning )); then
	actual="Warning"
    else
	actual="Ok"
    fi

    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: Usage ${usage}% -> ${actual}"
    else
        echo "FAIL: Usage ${usage}% expected ${expected}, got ${actual}"
        exit 1
    fi
}

check_threshold_test 50 70 90 "OK"
check_threshold_test 75 70 90 "WARNING"
check_threshold_test 95 70 90 "CRITICAL"
