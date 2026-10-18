#!/usr/bin/env bash

check_threshold() {
    local name="$1"
    local value="$2"
    local warning="$3"
    local critical="$4"

    if (( value >= critical )); then
        log "CRITICAL" "$name usage is ${value}% (threshold: ${critical}%)"
    elif (( value >= warning )); then
        log "WARNING" "$name usage is ${value}% (threshold: ${warning}%)"
    else
        log "OK" "$name usage is ${value}%"
    fi
}
