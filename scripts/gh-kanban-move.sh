#!/usr/bin/env bash
# gh-kanban-move.sh — Move an issue to a Kanban column in GitHub Projects v2
# Usage: ./scripts/gh-kanban-move.sh ISSUE_NUMBER REPO COLUMN_NAME [OPTIONS]
# Example: ./scripts/gh-kanban-move.sh 5 BeachCRER InProgress
#
# Options:
#   --dry-run       Show what would happen without making changes
#   --debug         Enable verbose debug output
#   --config-url    URL to fetch config.json from (overrides local config)
#   --help          Show this help message
#
# Requires: gh (GitHub CLI authenticated), jq
# Reads projectId, fieldId and column IDs from config.json

set -euo pipefail

# --- Defaults ---
DRY_RUN=false
DEBUG=false
CONFIG_URL=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../config.json"

# --- Help ---
show_help() {
  cat <<EOF
Usage: $(basename "$0") ISSUE_NUMBER REPO COLUMN_NAME [OPTIONS]

Move a GitHub issue to a specific Kanban column in GitHub Projects v2.

Arguments:
  ISSUE_NUMBER    The issue number to move
  REPO            Repository name (short or full, e.g. "BeachCRER" or "owner/repo")
  COLUMN_NAME     Target column name (e.g. "InProgress", "Test", "Done")

Options:
  --dry-run       Show what would happen without making changes
  --debug         Enable verbose debug output
  --config-url    URL to fetch config.json from (overrides local config)
  --help          Show this help message

Examples:
  $(basename "$0") 5 BeachCRER InProgress
  $(basename "$0") 12 finn Test --dry-run
  $(basename "$0") 3 workflow Done --config-url https://raw.githubusercontent.com/ecologicaleaving/workflow/master/config.json
EOF
  exit 0
}

# --- Parse arguments ---
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --debug)    DEBUG=true; shift ;;
    --config-url)
      CONFIG_URL="${2:?--config-url requires a URL argument}"
      shift 2
      ;;
    --help|-h)  show_help ;;
    -*)         echo "❌ Unknown option: $1" >&2; exit 1 ;;
    *)          POSITIONAL+=("$1"); shift ;;
  esac
done

# --- Validate positional args ---
if [[ ${#POSITIONAL[@]} -lt 3 ]]; then
  echo "❌ Usage: $(basename "$0") ISSUE_NUMBER REPO COLUMN_NAME [OPTIONS]" >&2
  echo "   Run with --help for details." >&2
  exit 1
fi

ISSUE_NUMBER="${POSITIONAL[0]}"
REPO="${POSITIONAL[1]}"
COLUMN_NAME="${POSITIONAL[2]}"

# --- Debug helper ---
debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

# --- Dependency checks ---
if ! command -v jq &>/dev/null; then
  echo "❌ jq not found. Install it: sudo apt install jq" >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "❌ gh CLI not found. Install it: https://cli.github.com/" >&2
  exit 1
fi

# --- Fetch config if remote URL provided ---
if [[ -n "$CONFIG_URL" ]]; then
  debug "Fetching config from: $CONFIG_URL"
  CONFIG_DATA=$(curl -fsSL "$CONFIG_URL") || {
    echo "❌ Failed to fetch config from $CONFIG_URL" >&2
    exit 1
  }
else
  if [[ ! -f "$CONFIG" ]]; then
    echo "❌ Config file not found: $CONFIG" >&2
    exit 1
  fi
  CONFIG_DATA=$(cat "$CONFIG")
fi

# --- Read config values ---
PROJECT_ID=$(echo "$CONFIG_DATA" | jq -r '.github.kanban.projectId')
FIELD_ID=$(echo "$CONFIG_DATA" | jq -r '.github.kanban.statusFieldId')
COLUMN_ID=$(echo "$CONFIG_DATA" | jq -r --arg col "$COLUMN_NAME" '.github.kanban.columns[$col].id // empty')
OWNER=$(echo "$CONFIG_DATA" | jq -r '.github.owner')

debug "PROJECT_ID=$PROJECT_ID"
debug "FIELD_ID=$FIELD_ID"
debug "COLUMN_ID=$COLUMN_ID"
debug "OWNER=$OWNER"

if [[ -z "$COLUMN_ID" ]]; then
  VALID_COLS=$(echo "$CONFIG_DATA" | jq -r '.github.kanban.columns | keys | join(", ")')
  echo "❌ Column '$COLUMN_NAME' not found. Valid columns: $VALID_COLS" >&2
  exit 1
fi

# --- Resolve repo full name ---
REPO_FULL=$(echo "$CONFIG_DATA" | jq -r --arg repo "$REPO" '
  .github.repos | to_entries[] | select(.value | test($repo; "i")) | .value // empty
')
if [[ -z "$REPO_FULL" ]]; then
  REPO_FULL="$OWNER/$REPO"
fi

debug "REPO_FULL=$REPO_FULL"

echo "🔍 Looking up issue #$ISSUE_NUMBER in $REPO_FULL..."

# --- Find issue node ID ---
ISSUE_NODE_ID=$(gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      issue(number: $number) { id }
    }
  }
' -f owner="$OWNER" -f repo="$(basename "$REPO_FULL")" -F number="$ISSUE_NUMBER" \
  --jq '.data.repository.issue.id')

if [[ -z "$ISSUE_NODE_ID" || "$ISSUE_NODE_ID" == "null" ]]; then
  echo "❌ Issue #$ISSUE_NUMBER not found in $REPO_FULL" >&2
  exit 1
fi

debug "ISSUE_NODE_ID=$ISSUE_NODE_ID"

echo "📋 Looking for item in project..."

# --- Find item ID in project ---
ITEM_ID=$(gh api graphql -f query='
  query($projectId: ID!, $cursor: String) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100, after: $cursor) {
          nodes {
            id
            content { ... on Issue { id } }
          }
        }
      }
    }
  }
' -f projectId="$PROJECT_ID" \
  --jq ".data.node.items.nodes[] | select(.content.id == \"$ISSUE_NODE_ID\") | .id")

if [[ -z "$ITEM_ID" ]]; then
  echo "❌ Issue #$ISSUE_NUMBER not found in the Kanban project. Add it first." >&2
  exit 1
fi

debug "ITEM_ID=$ITEM_ID"

# --- Dry run check ---
if [[ "$DRY_RUN" == "true" ]]; then
  echo "🔸 [DRY RUN] Would move issue #$ISSUE_NUMBER → $COLUMN_NAME (column ID: $COLUMN_ID)"
  echo "   Project: $PROJECT_ID"
  echo "   Item: $ITEM_ID"
  echo "   Field: $FIELD_ID"
  exit 0
fi

echo "🚀 Moving issue #$ISSUE_NUMBER → $COLUMN_NAME..."

# --- Execute mutation ---
gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $columnId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { singleSelectOptionId: $columnId }
    }) {
      projectV2Item { id }
    }
  }
' -f projectId="$PROJECT_ID" \
  -f itemId="$ITEM_ID" \
  -f fieldId="$FIELD_ID" \
  -f columnId="$COLUMN_ID" \
  --silent

echo "✅ Issue #$ISSUE_NUMBER moved to $COLUMN_NAME"
