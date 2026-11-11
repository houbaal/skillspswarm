#!/bin/bash
# Fetch raw logs for a job by ID, strip ANSI codes.
# Usage: get-job-logs.sh <job-id> [--tail N]
set -euo pipefail

JOB_ID="${1:?Usage: get-job-logs.sh <job-id> [--tail N]}"

if [[ "${2:-}" == "--tail" ]]; then
    TAIL_LINES="${3:-200}"
    glab ci trace "$JOB_ID" | sed 's/\x1b\[[0-9;]*m//g' | tail -n "$TAIL_LINES"
else
    glab ci trace "$JOB_ID" | sed 's/\x1b\[[0-9;]*m//g'
fi
