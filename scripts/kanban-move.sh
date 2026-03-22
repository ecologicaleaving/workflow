#!/usr/bin/env bash
# kanban-move.sh — Sposta una issue su una colonna del Kanban GitHub Projects v2
# Uso: ./scripts/kanban-move.sh ISSUE_NUMBER REPO COLUMN_NAME
# Esempio: ./scripts/kanban-move.sh 5 BeachCRER InProgress
#
# Richiede: gh (GitHub CLI autenticato), jq
# Legge projectId, fieldId e column IDs da config.json

set -euo pipefail

ISSUE_NUMBER="${1:?Uso: $0 ISSUE_NUMBER REPO COLUMN_NAME}"
REPO="${2:?Uso: $0 ISSUE_NUMBER REPO COLUMN_NAME}"
COLUMN_NAME="${3:?Uso: $0 ISSUE_NUMBER REPO COLUMN_NAME}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../config.json"

if ! command -v jq &>/dev/null; then
  echo "❌ jq non trovato. Installalo: sudo apt install jq" >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "❌ gh CLI non trovato. Installalo: https://cli.github.com/" >&2
  exit 1
fi

# Leggi config
PROJECT_ID=$(jq -r '.github.kanban.projectId' "$CONFIG")
FIELD_ID=$(jq -r '.github.kanban.statusFieldId' "$CONFIG")
COLUMN_ID=$(jq -r --arg col "$COLUMN_NAME" '.github.kanban.columns[$col].id // empty' "$CONFIG")
OWNER=$(jq -r '.github.owner' "$CONFIG")

if [[ -z "$COLUMN_ID" ]]; then
  VALID_COLS=$(jq -r '.github.kanban.columns | keys | join(", ")' "$CONFIG")
  echo "❌ Colonna '$COLUMN_NAME' non trovata. Colonne valide: $VALID_COLS" >&2
  exit 1
fi

# Trova il repo full name — cerca prima nel mapping repos, altrimenti usa owner/REPO
REPO_FULL=$(jq -r --arg repo "$REPO" '
  .github.repos | to_entries[] | select(.value | test($repo; "i")) | .value // empty
' "$CONFIG")
if [[ -z "$REPO_FULL" ]]; then
  REPO_FULL="$OWNER/$REPO"
fi

echo "🔍 Cerco issue #$ISSUE_NUMBER in $REPO_FULL..."

# Trova il node ID della issue
ISSUE_NODE_ID=$(gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      issue(number: $number) { id }
    }
  }
' -f owner="$OWNER" -f repo="$(basename "$REPO_FULL")" -F number="$ISSUE_NUMBER" \
  --jq '.data.repository.issue.id')

if [[ -z "$ISSUE_NODE_ID" || "$ISSUE_NODE_ID" == "null" ]]; then
  echo "❌ Issue #$ISSUE_NUMBER non trovata in $REPO_FULL" >&2
  exit 1
fi

echo "📋 Cerco item nel progetto..."

# Trova l'item ID nel progetto
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
  echo "❌ Issue #$ISSUE_NUMBER non trovata nel progetto Kanban. Aggiungila prima." >&2
  exit 1
fi

echo "🚀 Sposto issue #$ISSUE_NUMBER → $COLUMN_NAME..."

# Esegui la mutation per spostare la card
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

echo "✅ Issue #$ISSUE_NUMBER spostata in $COLUMN_NAME"
