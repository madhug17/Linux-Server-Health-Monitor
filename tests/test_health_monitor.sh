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
