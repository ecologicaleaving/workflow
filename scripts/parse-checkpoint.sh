#!/usr/bin/env bash
# parse-checkpoint.sh — Extract structured checkpoint data from GitHub issue comments
# Usage: parse-checkpoint.sh [OPTIONS] ISSUE_NUMBER REPO
# Reads issue comments via gh CLI and extracts CHECKPOINT_DATA JSON blocks.

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
LAST_ONLY=false
STATUS_ONLY=false

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] ISSUE_NUMBER REPO

Extract structured checkpoint data from GitHub issue comments.

Arguments:
  ISSUE_NUMBER   GitHub issue number
  REPO           Repository in owner/repo format (e.g. ecologicaleaving/workflow)

Options:
  --help         Show this help message
  --last         Output only the last (most recent) checkpoint
  --status       Output only a status summary (checkpoint number + status)

Examples:
  $(basename "$0") 27 ecologicaleaving/workflow
  $(basename "$0") --last 27 ecologicaleaving/workflow
  $(basename "$0") --status 27 ecologicaleaving/workflow
EOF
  exit 0
}

# ── Parse arguments ──────────────────────────────────────────────────────────
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage ;;
    --last)    LAST_ONLY=true; shift ;;
    --status)  STATUS_ONLY=true; shift ;;
    -*)        echo "Error: unknown option '$1'" >&2; exit 1 ;;
    *)         POSITIONAL+=("$1"); shift ;;
  esac
done

if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
  echo "Error: ISSUE_NUMBER and REPO are required." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

ISSUE_NUMBER="${POSITIONAL[0]}"
REPO="${POSITIONAL[1]}"

# ── Validate inputs ─────────────────────────────────────────────────────────
if ! [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Error: ISSUE_NUMBER must be a positive integer, got '$ISSUE_NUMBER'" >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is not installed or not in PATH" >&2
  exit 1
fi

# ── Fetch comments ───────────────────────────────────────────────────────────
# Fetch issue body + comments, extract CHECKPOINT_DATA blocks
COMMENTS=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --comments --json body,comments \
  -q '[.body // "", (.comments // [] | .[].body // "")] | .[]' 2>/dev/null) || {
  echo "Error: failed to fetch issue #${ISSUE_NUMBER} from ${REPO}" >&2
  exit 1
}

# ── Extract checkpoint JSON blocks ──────────────────────────────────────────
# Match lines between <!-- CHECKPOINT_DATA and -->
CHECKPOINTS=$(echo "$COMMENTS" | grep -oP '(?<=<!-- CHECKPOINT_DATA\s).*?(?=\s*-->)' 2>/dev/null || true)

if [[ -z "$CHECKPOINTS" ]]; then
  # Try multi-line extraction as fallback
  CHECKPOINTS=$(echo "$COMMENTS" | sed -n '/<!-- CHECKPOINT_DATA/{n;p;}' | sed 's/\s*-->.*//' 2>/dev/null || true)
fi

if [[ -z "$CHECKPOINTS" ]]; then
  echo "[]"
  exit 0
fi

# ── Build JSON array ────────────────────────────────────────────────────────
# Each line of CHECKPOINTS is a JSON object
JSON_ARRAY="["
FIRST=true
while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue
  # Validate it's JSON-ish (starts with {)
  line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [[ "$line" != \{* ]] && continue

  if $FIRST; then
    JSON_ARRAY+="$line"
    FIRST=false
  else
    JSON_ARRAY+=",$line"
  fi
done <<< "$CHECKPOINTS"
JSON_ARRAY+="]"

# ── Output ──────────────────────────────────────────────────────────────────
if $STATUS_ONLY; then
  # Output checkpoint number and status only
  echo "$JSON_ARRAY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = [{'checkpoint': c.get('checkpoint'), 'status': c.get('status')} for c in data]
print(json.dumps(result, indent=2))
" 2>/dev/null || echo "$JSON_ARRAY"
elif $LAST_ONLY; then
  # Output only the last checkpoint
  echo "$JSON_ARRAY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data:
    # Sort by checkpoint number and take last
    data.sort(key=lambda x: x.get('checkpoint', 0))
    print(json.dumps(data[-1], indent=2))
else:
    print('null')
" 2>/dev/null || echo "$JSON_ARRAY"
else
  # Output full array, pretty-printed if possible
  echo "$JSON_ARRAY" | python3 -m json.tool 2>/dev/null || echo "$JSON_ARRAY"
fi
