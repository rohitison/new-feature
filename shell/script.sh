#!/usr/bin/env bash

set -euo pipefail

log_message() {
    local message="$1"

    printf '[%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$message"
}

log_message "Deployment started"
