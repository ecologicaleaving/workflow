#!/usr/bin/env bash
# agent-retry.sh — Wrapper that retries a command on failure with escalation
# Usage: agent-retry.sh [OPTIONS] -- COMMAND [ARGS...]

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
MAX_RETRIES=2
DELAY=10
ON_FAILURE=""

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] -- COMMAND [ARGS...]

Wrapper that launches a command and retries on failure.
After all retries are exhausted, prints an escalation message.

Options:
  --help               Show this help message
  --max-retries N      Maximum number of retries (default: 2, total attempts = N+1)
  --delay N            Delay in seconds between retries (default: 10)
  --on-failure CMD     Command to execute after final failure (optional)

Exit codes:
  0    Command succeeded (on first attempt or after retry)
  1    Command failed after all retry attempts

Examples:
  $(basename "$0") -- ./scripts/run-agent.sh --issue 42
  $(basename "$0") --max-retries 3 --delay 30 -- npm test
  $(basename "$0") --on-failure "notify-slack.sh" -- ./deploy.sh
EOF
  exit 0
}

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)        usage ;;
    --max-retries)    MAX_RETRIES="$2"; shift 2 ;;
    --delay)          DELAY="$2"; shift 2 ;;
    --on-failure)     ON_FAILURE="$2"; shift 2 ;;
    --)               shift; break ;;
    -*)               echo "Error: unknown option '$1'" >&2; exit 1 ;;
    *)                break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  echo "Error: no command specified." >&2
  echo "Usage: $(basename "$0") [OPTIONS] -- COMMAND [ARGS...]" >&2
  exit 1
fi

# Validate numeric inputs
if ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
  echo "Error: --max-retries must be a non-negative integer, got '$MAX_RETRIES'" >&2
  exit 1
fi

if ! [[ "$DELAY" =~ ^[0-9]+$ ]]; then
  echo "Error: --delay must be a non-negative integer, got '$DELAY'" >&2
  exit 1
fi

COMMAND=("$@")
TOTAL_ATTEMPTS=$((MAX_RETRIES + 1))

# ── Logging helper ───────────────────────────────────────────────────────────
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ── Execute with retries ────────────────────────────────────────────────────
ATTEMPT=0
while [[ $ATTEMPT -lt $TOTAL_ATTEMPTS ]]; do
  ATTEMPT=$((ATTEMPT + 1))
  
  log "Attempt $ATTEMPT/$TOTAL_ATTEMPTS: ${COMMAND[*]}"
  
  # Run the command, capture exit code
  set +e
  "${COMMAND[@]}"
  EXIT_CODE=$?
  set -e
  
  if [[ $EXIT_CODE -eq 0 ]]; then
    log "✅ Command succeeded on attempt $ATTEMPT/$TOTAL_ATTEMPTS"
    exit 0
  fi
  
  log "❌ Command failed with exit code $EXIT_CODE (attempt $ATTEMPT/$TOTAL_ATTEMPTS)"
  
  # If not the last attempt, wait before retry
  if [[ $ATTEMPT -lt $TOTAL_ATTEMPTS ]]; then
    log "⏳ Waiting ${DELAY}s before retry..."
    sleep "$DELAY"
  fi
done

# ── All retries exhausted ───────────────────────────────────────────────────
log "🚨 ESCALATION: Command failed after $TOTAL_ATTEMPTS attempts"
log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  ⚠️  AGENT FAILURE — ESCALATION TO DAVIDE                   ║"
log "╠══════════════════════════════════════════════════════════════╣"
log "║  Command: ${COMMAND[*]}"
log "║  Attempts: $TOTAL_ATTEMPTS (all failed)"
log "║  Last exit code: $EXIT_CODE"
log "║  Time: $(date '+%Y-%m-%d %H:%M:%S')"
log "╚══════════════════════════════════════════════════════════════╝"

# Execute on-failure command if specified
if [[ -n "$ON_FAILURE" ]]; then
  log "Running on-failure handler: $ON_FAILURE"
  set +e
  eval "$ON_FAILURE"
  set -e
fi

exit 1
