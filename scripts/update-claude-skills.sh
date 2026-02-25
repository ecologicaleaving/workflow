#!/usr/bin/env bash
# update-claude-skills.sh
# Syncs all skills from the workflow repo to ~/.claude/skills/
# Run this after every `git pull` on the workflow repo.
#
# Usage:
#   bash scripts/update-claude-skills.sh

set -e

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="$WORKFLOW_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

echo "Workflow repo: $WORKFLOW_DIR"
echo "Syncing skills → $SKILLS_DST"
echo ""

if [ ! -d "$SKILLS_SRC" ]; then
    echo "ERROR: skills/ directory not found in workflow repo"
    exit 1
fi

mkdir -p "$SKILLS_DST"

for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name=$(basename "$skill_dir")
    dst="$SKILLS_DST/$skill_name"
    mkdir -p "$dst"
    cp -r "$skill_dir"* "$dst/" 2>/dev/null || true
    echo "  ✓ $skill_name"
done

echo ""
echo "Done. Restart Claude Code to load updated skills."
