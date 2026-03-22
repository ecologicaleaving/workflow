#!/usr/bin/env bash
# status.sh — Dashboard showing issue status, Kanban columns, CI and deploy info
# Reads repos from config.json. Uses gh CLI for GitHub data.
# Usage: status.sh [OPTIONS]

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"
FILTER_REPO=""
JSON_OUTPUT=false
COMPACT=false

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Dashboard showing issue status, Kanban columns, CI runs, and deploy info
for all repos configured in config.json.

Options:
  --help            Show this help message
  --repo <name>     Filter to a single repo (key name from config.json repos)
  --json            Output raw JSON instead of formatted table
  --compact         One line per issue (compact view)
  --config <path>   Path to config.json (default: ../config.json relative to script)

Examples:
  $(basename "$0")
  $(basename "$0") --repo finn
  $(basename "$0") --json
  $(basename "$0") --compact --repo workflow
EOF
  exit 0
}

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)   usage ;;
    --repo)      FILTER_REPO="$2"; shift 2 ;;
    --json)      JSON_OUTPUT=true; shift ;;
    --compact)   COMPACT=true; shift ;;
    --config)    CONFIG_FILE="$2"; shift 2 ;;
    *)           echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

# ── Validate ─────────────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config.json not found at $CONFIG_FILE" >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is not installed or not in PATH" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed or not in PATH" >&2
  exit 1
fi

# ── Read repos from config ──────────────────────────────────────────────────
# config.json has repos as object: { "workflow": "owner/repo", ... }
REPOS_JSON=$(jq -r '.github.repos' "$CONFIG_FILE")
PROJECT_NUMBER=$(jq -r '.github.kanban.projectNumber' "$CONFIG_FILE")
OWNER=$(jq -r '.github.owner' "$CONFIG_FILE")

# Build list of repo keys
if [[ -n "$FILTER_REPO" ]]; then
  REPO_KEYS=("$FILTER_REPO")
  # Validate the repo exists in config
  FULL_REPO=$(echo "$REPOS_JSON" | jq -r --arg k "$FILTER_REPO" '.[$k] // empty')
  if [[ -z "$FULL_REPO" ]]; then
    echo "Error: repo '$FILTER_REPO' not found in config.json" >&2
    echo "Available repos: $(echo "$REPOS_JSON" | jq -r 'keys | join(", ")')" >&2
    exit 1
  fi
else
  mapfile -t REPO_KEYS < <(echo "$REPOS_JSON" | jq -r 'keys[]')
fi

# ── Collect data ─────────────────────────────────────────────────────────────
ALL_DATA="[]"

for KEY in "${REPO_KEYS[@]}"; do
  FULL_REPO=$(echo "$REPOS_JSON" | jq -r --arg k "$KEY" '.[$k]')
  
  # Fetch open issues
  ISSUES=$(gh issue list --repo "$FULL_REPO" --state open --json number,title,labels \
    --limit 50 2>/dev/null || echo "[]")
  ISSUE_COUNT=$(echo "$ISSUES" | jq 'length')

  # Fetch last CI run on default branch
  LAST_RUN=$(gh run list --repo "$FULL_REPO" --limit 1 \
    --json status,conclusion,createdAt,name 2>/dev/null || echo "[]")
  
  CI_STATUS="unknown"
  CI_DATE=""
  if [[ $(echo "$LAST_RUN" | jq 'length') -gt 0 ]]; then
    CONCLUSION=$(echo "$LAST_RUN" | jq -r '.[0].conclusion // "pending"')
    CI_DATE=$(echo "$LAST_RUN" | jq -r '.[0].createdAt // ""')
    case "$CONCLUSION" in
      success)  CI_STATUS="green" ;;
      failure)  CI_STATUS="red" ;;
      pending|""|null) CI_STATUS="yellow" ;;
      *)        CI_STATUS="yellow" ;;
    esac
  fi

  # Try to get last deploy date (look for deployed-prod label on recent closed issues)
  LAST_DEPLOY=$(gh issue list --repo "$FULL_REPO" --state closed --label "deployed-prod" \
    --json closedAt --limit 1 2>/dev/null | jq -r '.[0].closedAt // "N/A"' 2>/dev/null || echo "N/A")

  # Build issue details with Kanban column (if project board available)
  ISSUE_DETAILS="[]"
  while IFS= read -r ISSUE_LINE; do
    [[ -z "$ISSUE_LINE" ]] && continue
    NUM=$(echo "$ISSUE_LINE" | jq -r '.number')
    TITLE=$(echo "$ISSUE_LINE" | jq -r '.title')
    
    # Try to get Kanban column via project field
    KANBAN_COL="N/A"
    ITEM_STATUS=$(gh api graphql -f query="
      query {
        repository(owner: \"$OWNER\", name: \"$(echo "$FULL_REPO" | cut -d/ -f2)\") {
          issue(number: $NUM) {
            projectItems(first: 5) {
              nodes {
                fieldValueByName(name: \"Status\") {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                  }
                }
              }
            }
          }
        }
      }" --jq '.data.repository.issue.projectItems.nodes[0].fieldValueByName.name // "N/A"' 2>/dev/null || echo "N/A")
    
    if [[ -n "$ITEM_STATUS" && "$ITEM_STATUS" != "null" ]]; then
      KANBAN_COL="$ITEM_STATUS"
    fi

    ISSUE_DETAILS=$(echo "$ISSUE_DETAILS" | jq --argjson num "$NUM" \
      --arg title "$TITLE" --arg col "$KANBAN_COL" \
      '. + [{"number": $num, "title": $title, "kanban": $col}]')
  done < <(echo "$ISSUES" | jq -c '.[]')

  # Add to all data
  ALL_DATA=$(echo "$ALL_DATA" | jq \
    --arg key "$KEY" \
    --arg repo "$FULL_REPO" \
    --argjson count "$ISSUE_COUNT" \
    --arg ci "$CI_STATUS" \
    --arg ciDate "$CI_DATE" \
    --arg deploy "$LAST_DEPLOY" \
    --argjson issues "$ISSUE_DETAILS" \
    '. + [{
      "name": $key,
      "repo": $repo,
      "open_issues": $count,
      "ci_status": $ci,
      "ci_date": $ciDate,
      "last_deploy": $deploy,
      "issues": $issues
    }]')
done

# ── Output ───────────────────────────────────────────────────────────────────
if $JSON_OUTPUT; then
  echo "$ALL_DATA" | jq '.'
  exit 0
fi

# ── Formatted output ────────────────────────────────────────────────────────
CI_EMOJI() {
  case "$1" in
    green)  echo "🟢" ;;
    red)    echo "🔴" ;;
    yellow) echo "🟡" ;;
    *)      echo "⚪" ;;
  esac
}

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  📊 8020 Solutions — Status Dashboard"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "$ALL_DATA" | jq -c '.[]' | while IFS= read -r REPO_DATA; do
  NAME=$(echo "$REPO_DATA" | jq -r '.name')
  FULL=$(echo "$REPO_DATA" | jq -r '.repo')
  COUNT=$(echo "$REPO_DATA" | jq -r '.open_issues')
  CI=$(echo "$REPO_DATA" | jq -r '.ci_status')
  CI_D=$(echo "$REPO_DATA" | jq -r '.ci_date')
  DEPLOY=$(echo "$REPO_DATA" | jq -r '.last_deploy')

  CI_E=$(CI_EMOJI "$CI")
  
  # Format deploy date
  if [[ "$DEPLOY" != "N/A" && "$DEPLOY" != "null" ]]; then
    DEPLOY_FMT=$(date -d "$DEPLOY" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$DEPLOY")
  else
    DEPLOY_FMT="—"
  fi

  # Format CI date
  if [[ -n "$CI_D" && "$CI_D" != "null" ]]; then
    CI_FMT=$(date -d "$CI_D" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$CI_D")
  else
    CI_FMT="—"
  fi

  echo "┌─ 📦 $NAME ($FULL)"
  echo "│  Issues: $COUNT open  │  CI: $CI_E $CI ($CI_FMT)  │  Deploy: $DEPLOY_FMT"
  
  if $COMPACT; then
    # One line per issue
    echo "$REPO_DATA" | jq -r '.issues[] | "│  #\(.number) [\(.kanban)] \(.title)"'
  else
    # Detailed list
    ISSUE_LIST=$(echo "$REPO_DATA" | jq -c '.issues[]')
    if [[ -n "$ISSUE_LIST" ]]; then
      echo "│"
      echo "$ISSUE_LIST" | while IFS= read -r ISS; do
        INUM=$(echo "$ISS" | jq -r '.number')
        ITITLE=$(echo "$ISS" | jq -r '.title')
        ICOL=$(echo "$ISS" | jq -r '.kanban')
        echo "│  📌 #${INUM} — ${ITITLE}"
        echo "│     └─ Kanban: ${ICOL}"
      done
    fi
  fi

  echo "└───────────────────────────────────────────────────────────"
  echo ""
done

echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
