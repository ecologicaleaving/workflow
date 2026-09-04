#!/usr/bin/env bash
# metrics.sh — Issue metrics: avg time, rework count, Kanban time, fastest/slowest
# Reads repos from config.json. Uses gh CLI + GraphQL for project data.
# Usage: metrics.sh [OPTIONS]

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"
FILTER_REPO=""
JSON_OUTPUT=false
SINCE_DATE=""

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Issue metrics for repos configured in config.json.

Metrics per repo:
  - Average time per issue (creation → close)
  - Rework/reject count per issue (label 'rework' or 🔴 in comments)
  - Kanban column time (from project field changes, if available)
  - Fastest and slowest issue

Options:
  --help            Show this help message
  --repo <name>     Filter to a single repo (key name from config.json repos)
  --json            Output raw JSON
  --since <date>    Only issues created after this date (YYYY-MM-DD)
  --config <path>   Path to config.json (default: ../config.json relative to script)

Examples:
  $(basename "$0")
  $(basename "$0") --repo finn --since 2025-01-01
  $(basename "$0") --json
EOF
  exit 0
}

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)   usage ;;
    --repo)      FILTER_REPO="$2"; shift 2 ;;
    --json)      JSON_OUTPUT=true; shift ;;
    --since)     SINCE_DATE="$2"; shift 2 ;;
    --config)    CONFIG_FILE="$2"; shift 2 ;;
    *)           echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

# ── Validate ─────────────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config.json not found at $CONFIG_FILE" >&2
  exit 1
fi

for cmd in gh jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed or not in PATH" >&2
    exit 1
  fi
done

# ── Read repos ───────────────────────────────────────────────────────────────
REPOS_JSON=$(jq -r '.github.repos' "$CONFIG_FILE")
OWNER=$(jq -r '.github.owner' "$CONFIG_FILE")

if [[ -n "$FILTER_REPO" ]]; then
  REPO_KEYS=("$FILTER_REPO")
  FULL_REPO=$(echo "$REPOS_JSON" | jq -r --arg k "$FILTER_REPO" '.[$k] // empty')
  if [[ -z "$FULL_REPO" ]]; then
    echo "Error: repo '$FILTER_REPO' not found in config.json" >&2
    exit 1
  fi
else
  mapfile -t REPO_KEYS < <(echo "$REPOS_JSON" | jq -r 'keys[]')
fi

# ── Helper: compute metrics for a repo ──────────────────────────────────────
compute_metrics() {
  local FULL_REPO="$1"
  local REPO_NAME
  REPO_NAME=$(echo "$FULL_REPO" | cut -d/ -f2)
  
  # Fetch closed issues (with timing data)
  local SINCE_FILTER=""
  if [[ -n "$SINCE_DATE" ]]; then
    SINCE_FILTER="--search \"created:>=${SINCE_DATE}\""
  fi

  # Get closed issues with created/closed dates
  local ISSUES
  ISSUES=$(eval gh issue list --repo "$FULL_REPO" --state closed \
    --json number,title,createdAt,closedAt,labels \
    --limit 200 "$SINCE_FILTER" 2>/dev/null || echo "[]")
  
  local ISSUE_COUNT
  ISSUE_COUNT=$(echo "$ISSUES" | jq 'length')
  
  if [[ "$ISSUE_COUNT" -eq 0 ]]; then
    echo "{\"repo\": \"$FULL_REPO\", \"closed_issues\": 0, \"avg_hours\": null, \"fastest\": null, \"slowest\": null, \"rework_issues\": [], \"issues\": []}"
    return
  fi

  # Use python for date math and analysis
  echo "$ISSUES" | python3 -c "
import sys, json
from datetime import datetime

data = json.load(sys.stdin)
repo = '$FULL_REPO'

results = []
for issue in data:
    num = issue['number']
    title = issue['title']
    created = issue.get('createdAt', '')
    closed = issue.get('closedAt', '')
    labels = [l.get('name', '') for l in issue.get('labels', [])]
    
    if not created or not closed:
        continue
    
    # Parse dates (handle both Z and +00:00 formats)
    try:
        c = datetime.fromisoformat(created.replace('Z', '+00:00'))
        d = datetime.fromisoformat(closed.replace('Z', '+00:00'))
        hours = (d - c).total_seconds() / 3600
    except:
        hours = None
    
    has_rework = 'rework' in labels
    
    results.append({
        'number': num,
        'title': title,
        'hours': hours,
        'has_rework': has_rework,
        'labels': labels
    })

# Calculate stats
valid = [r for r in results if r['hours'] is not None]
rework_issues = [r for r in results if r['has_rework']]

if valid:
    avg_hours = sum(r['hours'] for r in valid) / len(valid)
    fastest = min(valid, key=lambda r: r['hours'])
    slowest = max(valid, key=lambda r: r['hours'])
else:
    avg_hours = None
    fastest = None
    slowest = None

output = {
    'repo': repo,
    'closed_issues': len(results),
    'avg_hours': round(avg_hours, 1) if avg_hours else None,
    'fastest': {'number': fastest['number'], 'title': fastest['title'], 'hours': round(fastest['hours'], 1)} if fastest else None,
    'slowest': {'number': slowest['number'], 'title': slowest['title'], 'hours': round(slowest['hours'], 1)} if slowest else None,
    'rework_count': len(rework_issues),
    'rework_issues': [{'number': r['number'], 'title': r['title']} for r in rework_issues],
    'issues': [{'number': r['number'], 'hours': round(r['hours'], 1) if r['hours'] else None, 'rework': r['has_rework']} for r in results]
}
print(json.dumps(output))
"
}

# ── Count rework comments (🔴) for a repo ───────────────────────────────────
count_rework_comments() {
  local FULL_REPO="$1"
  # Search for comments containing 🔴 in the repo issues
  local COUNT
  COUNT=$(gh api "search/issues?q=repo:${FULL_REPO}+type:issue+🔴+in:comments&per_page=1" \
    --jq '.total_count' 2>/dev/null || echo "0")
  echo "$COUNT"
}

# ── Collect all metrics ─────────────────────────────────────────────────────
ALL_METRICS="[]"

for KEY in "${REPO_KEYS[@]}"; do
  FULL_REPO=$(echo "$REPOS_JSON" | jq -r --arg k "$KEY" '.[$k]')
  
  METRICS=$(compute_metrics "$FULL_REPO")
  
  # Also count 🔴 comments
  REWORK_COMMENTS=$(count_rework_comments "$FULL_REPO")
  METRICS=$(echo "$METRICS" | jq --argjson rc "$REWORK_COMMENTS" '. + {"rework_comments": $rc}')
  
  ALL_METRICS=$(echo "$ALL_METRICS" | jq --argjson m "$METRICS" '. + [$m]')
done

# ── Output ───────────────────────────────────────────────────────────────────
if $JSON_OUTPUT; then
  echo "$ALL_METRICS" | jq '.'
  exit 0
fi

# ── Formatted output ────────────────────────────────────────────────────────
format_hours() {
  local HOURS="$1"
  if [[ "$HOURS" == "null" ]]; then
    echo "—"
    return
  fi
  
  python3 -c "
h = float('$HOURS')
if h < 1:
    print(f'{h*60:.0f}m')
elif h < 24:
    print(f'{h:.1f}h')
else:
    days = h / 24
    print(f'{days:.1f}d')
"
}

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  📈 8020 Solutions — Issue Metrics"
if [[ -n "$SINCE_DATE" ]]; then
  echo "  📅 Since: $SINCE_DATE"
fi
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "$ALL_METRICS" | jq -c '.[]' | while IFS= read -r M; do
  REPO=$(echo "$M" | jq -r '.repo')
  CLOSED=$(echo "$M" | jq -r '.closed_issues')
  AVG=$(echo "$M" | jq -r '.avg_hours // "null"')
  REWORK_N=$(echo "$M" | jq -r '.rework_count')
  REWORK_C=$(echo "$M" | jq -r '.rework_comments')
  
  FASTEST_N=$(echo "$M" | jq -r '.fastest.number // "—"')
  FASTEST_T=$(echo "$M" | jq -r '.fastest.title // "—"')
  FASTEST_H=$(echo "$M" | jq -r '.fastest.hours // "null"')
  
  SLOWEST_N=$(echo "$M" | jq -r '.slowest.number // "—"')
  SLOWEST_T=$(echo "$M" | jq -r '.slowest.title // "—"')
  SLOWEST_H=$(echo "$M" | jq -r '.slowest.hours // "null"')

  AVG_FMT=$(format_hours "$AVG")
  FASTEST_FMT=$(format_hours "$FASTEST_H")
  SLOWEST_FMT=$(format_hours "$SLOWEST_H")

  echo "┌─ 📦 $REPO"
  echo "│  Closed issues: $CLOSED"
  echo "│  Avg time to close: $AVG_FMT"
  echo "│  Rework (label): $REWORK_N  │  Rework (🔴 comments): $REWORK_C"
  echo "│"
  
  if [[ "$FASTEST_N" != "—" ]]; then
    echo "│  🏎️  Fastest: #$FASTEST_N — $FASTEST_T ($FASTEST_FMT)"
  fi
  if [[ "$SLOWEST_N" != "—" ]]; then
    echo "│  🐢 Slowest: #$SLOWEST_N — $SLOWEST_T ($SLOWEST_FMT)"
  fi
  
  echo "└───────────────────────────────────────────────────────────"
  echo ""
done

echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
