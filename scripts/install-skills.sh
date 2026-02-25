#!/bin/bash
# install-skills.sh - Install all 80/20 Solutions Claude Code skills
# Usage: curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-skills.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/ecologicaleaving/workflow/master"
SKILLS_DIR="$HOME/.claude/skills"
SKILLS=("8020-commit-workflow" "issue-resolver")

echo "80/20 Solutions - Claude Code Skills Installer"
echo "================================================"

# Check Claude Code skills directory
if [ ! -d "$HOME/.claude" ]; then
    echo "ERROR: ~/.claude not found. Is Claude Code installed?"
    exit 1
fi

mkdir -p "$SKILLS_DIR"

for SKILL in "${SKILLS[@]}"; do
    echo ""
    echo "Installing skill: $SKILL"

    SKILL_DIR="$SKILLS_DIR/$SKILL"
    mkdir -p "$SKILL_DIR/references"

    # Download SKILL.md
    curl -sSL "$REPO_URL/skills/$SKILL/SKILL.md" -o "$SKILL_DIR/SKILL.md"
    echo "  -> SKILL.md downloaded"

    # Download references if they exist
    curl -sSL "$REPO_URL/skills/$SKILL/references/workflow-rules.md" \
        -o "$SKILL_DIR/references/workflow-rules.md" 2>/dev/null && \
        echo "  -> references/workflow-rules.md downloaded" || true

    echo "  -> $SKILL installed successfully"
done

echo ""
echo "================================================"
echo "Skills installed in: $SKILLS_DIR"
echo ""
echo "Skills installed:"
for SKILL in "${SKILLS[@]}"; do
    echo "  - $SKILL"
done
echo ""
echo "Claude Code will auto-load skills on next session."
