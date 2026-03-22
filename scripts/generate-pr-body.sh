#!/usr/bin/env bash
# generate-pr-body.sh — Generate a PR body from issue data and a template
# Usage: ./scripts/generate-pr-body.sh ISSUE_NUMBER REPO [BRANCH]
#
# Fetches issue details via gh CLI, extracts acceptance criteria,
# calculates changed files, and populates the PR template.
# Output goes to stdout.
#
# Requires: gh (GitHub CLI authenticated), git

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"
TEMPLATE_FILE="$TEMPLATE_DIR/pull_request_template.md"

# --- Help ---
show_help() {
  cat <<EOF
Usage: $(basename "$0") ISSUE_NUMBER REPO [BRANCH]

Generate a PR body by populating the PR template with issue data.

Arguments:
  ISSUE_NUMBER    The GitHub issue number
  REPO            Repository (full name, e.g. "ecologicaleaving/finn")
  BRANCH          Branch to diff against master (default: current branch)

Options:
  --help, -h      Show this help message

Placeholders replaced in template:
  {{ISSUE_TITLE}}    Issue title
  {{ISSUE_NUMBER}}   Issue number
  {{AC_LIST}}        Acceptance criteria extracted from issue body
  {{FILES_CHANGED}}  List of files changed vs master

Output: Populated PR body on stdout

Examples:
  $(basename "$0") 27 ecologicaleaving/workflow
  $(basename "$0") 12 ecologicaleaving/finn feature/issue-12-fix
EOF
  exit 0
}

# --- Parse args ---
case "${1:-}" in
  --help|-h) show_help ;;
esac

ISSUE_NUMBER="${1:?Usage: $(basename "$0") ISSUE_NUMBER REPO [BRANCH]}"
REPO="${2:?Usage: $(basename "$0") ISSUE_NUMBER REPO [BRANCH]}"
BRANCH="${3:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")}"

# --- Dependency checks ---
if ! command -v gh &>/dev/null; then
  echo "❌ gh CLI not found. Install it: https://cli.github.com/" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "❌ Template not found: $TEMPLATE_FILE" >&2
  exit 1
fi

# --- Fetch issue data ---
ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json title -q '.title' 2>/dev/null) || {
  echo "❌ Failed to fetch issue #$ISSUE_NUMBER from $REPO" >&2
  exit 1
}

ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json body -q '.body' 2>/dev/null) || {
  echo "❌ Failed to fetch issue body for #$ISSUE_NUMBER" >&2
  exit 1
}

# --- Extract acceptance criteria (lines with "- [ ]") ---
AC_LIST=$(echo "$ISSUE_BODY" | grep -E '^\s*-\s*\[[ x]\]' || echo "- [ ] (no acceptance criteria found)")

# --- Calculate changed files ---
# Try diff against master; fall back to main; fall back to empty
DEFAULT_BRANCH="master"
if ! git rev-parse --verify "$DEFAULT_BRANCH" &>/dev/null 2>&1; then
  DEFAULT_BRANCH="main"
fi

FILES_CHANGED_RAW=$(git diff --name-only "$DEFAULT_BRANCH".."$BRANCH" 2>/dev/null || echo "")

if [[ -n "$FILES_CHANGED_RAW" ]]; then
  # Format as markdown table
  FILES_CHANGED="| File | Modifica |
|------|---------|"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    FILES_CHANGED="$FILES_CHANGED
| \`$file\` | modified |"
  done <<< "$FILES_CHANGED_RAW"
else
  FILES_CHANGED="| File | Modifica |
|------|---------|
| (no changes detected) | — |"
fi

# --- Populate template ---
TEMPLATE=$(cat "$TEMPLATE_FILE")

# Replace placeholders
OUTPUT="${TEMPLATE//\{\{ISSUE_TITLE\}\}/$ISSUE_TITLE}"
OUTPUT="${OUTPUT//\{\{ISSUE_NUMBER\}\}/$ISSUE_NUMBER}"

# For multi-line replacements, use a temp file approach
TMPFILE=$(mktemp)
echo "$OUTPUT" > "$TMPFILE"

# Replace AC_LIST (multi-line)
AC_ESCAPED=$(echo "$AC_LIST" | sed 's/[&/\]/\\&/g')
sed -i "s|{{AC_LIST}}|${AC_ESCAPED}|g" "$TMPFILE" 2>/dev/null || {
  # Fallback: use awk for multi-line replacement
  awk -v replacement="$AC_LIST" '{gsub(/\{\{AC_LIST\}\}/, replacement); print}' "$TMPFILE" > "${TMPFILE}.2"
  mv "${TMPFILE}.2" "$TMPFILE"
}

# Replace FILES_CHANGED (multi-line)
FILES_ESCAPED=$(echo "$FILES_CHANGED" | sed 's/[&/\]/\\&/g')
sed -i "s|{{FILES_CHANGED}}|${FILES_ESCAPED}|g" "$TMPFILE" 2>/dev/null || {
  awk -v replacement="$FILES_CHANGED" '{gsub(/\{\{FILES_CHANGED\}\}/, replacement); print}' "$TMPFILE" > "${TMPFILE}.2"
  mv "${TMPFILE}.2" "$TMPFILE"
}

cat "$TMPFILE"
rm -f "$TMPFILE"
