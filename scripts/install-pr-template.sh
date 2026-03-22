#!/usr/bin/env bash
# install-pr-template.sh — Install PR template and generate-pr-body script into a target repo
# Usage: ./scripts/install-pr-template.sh /path/to/target-repo

set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") TARGET_REPO_PATH

Install the PR template and generate-pr-body.sh script into a target repository.

Arguments:
  TARGET_REPO_PATH    Path to the target repository root

Options:
  --help, -h          Show this help message

What it does:
  1. Copies templates/pull_request_template.md → TARGET/.github/pull_request_template.md
  2. Copies scripts/generate-pr-body.sh → TARGET/scripts/generate-pr-body.sh
EOF
  exit 0
}

# --- Parse args ---
case "${1:-}" in
  --help|-h) show_help ;;
  "") echo "❌ Usage: $(basename "$0") TARGET_REPO_PATH" >&2; exit 1 ;;
esac

TARGET="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -d "$TARGET" ]]; then
  echo "❌ Target directory not found: $TARGET" >&2
  exit 1
fi

# Copy PR template
mkdir -p "$TARGET/.github"
cp "$SOURCE_DIR/templates/pull_request_template.md" "$TARGET/.github/pull_request_template.md"
echo "✅ PR template installed at $TARGET/.github/pull_request_template.md"

# Copy generate script
mkdir -p "$TARGET/scripts"
cp "$SOURCE_DIR/scripts/generate-pr-body.sh" "$TARGET/scripts/generate-pr-body.sh"
chmod +x "$TARGET/scripts/generate-pr-body.sh"
echo "✅ generate-pr-body.sh installed at $TARGET/scripts/generate-pr-body.sh"

# Also copy the template to scripts dir for the script to find
mkdir -p "$TARGET/templates"
cp "$SOURCE_DIR/templates/pull_request_template.md" "$TARGET/templates/pull_request_template.md"
echo "✅ Template also copied to $TARGET/templates/pull_request_template.md"

echo ""
echo "📝 Usage: scripts/generate-pr-body.sh ISSUE_NUMBER REPO [BRANCH]"
