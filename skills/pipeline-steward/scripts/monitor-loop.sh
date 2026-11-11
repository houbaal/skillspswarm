#!/bin/bash
# Poll pipeline status every N seconds, write atomic status file.
# Usage: monitor-loop.sh [pipeline-id] [interval_seconds]
#   If pipeline-id is omitted, auto-detects the latest pipeline for the current branch.
# Output: ./tmp/pipeline-status.txt (one line: STATUS:PID:#IID)
#         + stdout echo on each poll for background task visibility
#
# IMPORTANT — parent-child pipelines:
#   This script polls the parent pipeline. With `strategy: depend`, the parent
#   status correctly aggregates downstream child status -- no manual walk needed
#   for the steady-state running/success/failed signal.
#   The "all non-manual done" override (used to stop waiting on a manual deploy
#   job that blocks the pipeline forever) explicitly accounts for BRIDGES too,
#   otherwise we would prematurely mark a pipeline done while a child is still
#   running.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERVAL="${2:-30}"
TIMEOUT="${MONITOR_TIMEOUT:-1800}"  # 30 min max by default
STATUS_FILE="./tmp/pipeline-status.txt"

mkdir -p ./tmp

# --- Auto-detect pipeline ID if not provided ---
if [ -n "${1:-}" ]; then
    PIPELINE_ID="$1"
else
    echo "[$(date +%H:%M:%S)] No pipeline ID provided, auto-detecting..."
    # --no-children for the auto-detect: we only need the latest pipeline ID.
    PIPELINE_JSON=$("$SCRIPT_DIR/get-pipeline-details.py" --history 1 --no-children 2>/dev/null || echo "[]")
    PIPELINE_ID=$(echo "$PIPELINE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data[0]['id'] if data else '')
" 2>/dev/null || echo "")

    if [ -z "$PIPELINE_ID" ]; then
        echo "[$(date +%H:%M:%S)] ERROR: No pipeline found for current branch"
        echo "ERROR:no-pipeline-found" > "$STATUS_FILE"
        exit 1
    fi
    echo "[$(date +%H:%M:%S)] Detected pipeline ID: $PIPELINE_ID"
fi

TERMINAL_STATES="success failed canceled skipped"
START_TIME=$(date +%s)

while true; do
    ELAPSED=$(( $(date +%s) - START_TIME ))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "[$(date +%H:%M:%S)] TIMEOUT after ${ELAPSED}s — exiting"
        echo "TIMEOUT:${PIPELINE_ID}" > "$STATUS_FILE"
        exit 1
    fi

    # Fetch the SAME pipeline ID we are tracking (do not let a newer push redirect us
    # mid-monitoring -- if we want to follow the latest, the caller can re-launch).
    # Children are included so that the manual-job override below can also account
    # for bridge / downstream state.
    PIPELINE_JSON=$("$SCRIPT_DIR/get-pipeline-details.py" --pipeline-id "$PIPELINE_ID" 2>/dev/null || echo "[]")

    STATUS=$(echo "$PIPELINE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data[0]['status'] if data else 'UNKNOWN')
" 2>/dev/null || echo "UNKNOWN")

    IID=$(echo "$PIPELINE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data[0].get('iid', '') if data else '')
" 2>/dev/null || echo "")

    # Bridge-aware "all non-manual done" override.
    # Reason for the override: deploy_production is often `manual`, so the parent
    # pipeline stays `running` until someone clicks the deploy button. We want to
    # exit the loop once everything else is settled.
    # CRITICAL: include bridges, otherwise we'd declare done while a child is still
    # running.
    ALL_NON_MANUAL_DONE=$(echo "$PIPELINE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data:
    print('false'); sys.exit(0)
node = data[0]
units = list(node.get('jobs', [])) + list(node.get('bridges', []))
if not units:
    print('false'); sys.exit(0)
non_manual = [u for u in units if u.get('status') not in ('manual', 'created')]
if not non_manual:
    print('false'); sys.exit(0)
terminal = {'success', 'failed', 'canceled', 'skipped'}
all_done = all(u.get('status') in terminal for u in non_manual)
any_failed = any(u.get('status') == 'failed' for u in non_manual)
if all_done:
    print('failed' if any_failed else 'success')
else:
    print('false')
" 2>/dev/null || echo "false")

    EFFECTIVE_STATUS="$STATUS"
    if [ "$STATUS" = "running" ] && [ "$ALL_NON_MANUAL_DONE" != "false" ]; then
        EFFECTIVE_STATUS="$ALL_NON_MANUAL_DONE"
        echo "[$(date +%H:%M:%S)] Pipeline #${IID}: parent=${STATUS} but all non-manual jobs+bridges done (${EFFECTIVE_STATUS})"
    fi

    case "$EFFECTIVE_STATUS" in
        success) echo "GREEN:${PIPELINE_ID}:#${IID}" > "$STATUS_FILE" ;;
        failed)  echo "RED:${PIPELINE_ID}:#${IID}" > "$STATUS_FILE" ;;
        *)       echo "RUNNING:${PIPELINE_ID}:#${IID}" > "$STATUS_FILE" ;;
    esac

    echo "[$(date +%H:%M:%S)] Pipeline #${IID}: ${EFFECTIVE_STATUS} (elapsed: ${ELAPSED}s)"

    for ts in $TERMINAL_STATES; do
        if [ "$EFFECTIVE_STATUS" = "$ts" ]; then
            exit 0
        fi
    done

    sleep "$INTERVAL"
done
