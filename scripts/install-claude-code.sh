#!/bin/bash
# ================================================================
# install-claude-code.sh — Setup Claude Code (PC / Linux / WSL)
# Installa skills e monitor per l'agente developer.
#
# Uso:
#   curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-claude-code.sh | bash
#   oppure: bash install-claude-code.sh
# ================================================================

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ecologicaleaving/workflow/master"
SKILLS_DIR="${HOME}/.claude/skills"
MONITOR_DIR="${HOME}/.claude/monitor"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
h()    { echo -e "\n\033[1m▸ $1\033[0m"; }

# ── Prerequisiti ──────────────────────────────────────────────
h "Verifica prerequisiti"

command -v claude &>/dev/null || warn "claude CLI non trovato — skills installate ma monitor non attivo"
command -v gh    &>/dev/null || err "gh CLI non trovato (installa: https://cli.github.com)"
command -v curl  &>/dev/null || err "curl non trovato"

ok "Prerequisiti OK"

# ── Directories ───────────────────────────────────────────────
h "Creazione directory"
mkdir -p "$SKILLS_DIR"
mkdir -p "$MONITOR_DIR"
ok "Directory pronte"

# ── Skills Claude Code ────────────────────────────────────────
h "Installazione skills"

SKILLS=("8020-commit-workflow" "issue-resolver")

for SKILL in "${SKILLS[@]}"; do
  SKILL_DIR="$SKILLS_DIR/$SKILL"
  mkdir -p "$SKILL_DIR/references"

  # SKILL.md
  curl -sSL "$REPO_RAW/skills/$SKILL/SKILL.md" -o "$SKILL_DIR/SKILL.md"

  # References (scarica tutti i .md presenti)
  for REF in workflow-rules.md WORKFLOW_CLAUDE_CODE.md BRANCH_STRATEGY.md COMMIT_CONVENTIONS.md; do
    curl -sSLf "$REPO_RAW/skills/$SKILL/references/$REF" \
      -o "$SKILL_DIR/references/$REF" 2>/dev/null || true
  done

  ok "Skill: $SKILL"
done

# ── Monitor script ────────────────────────────────────────────
h "Download monitor"

curl -sSL "$REPO_RAW/scripts/claude-code-issue-monitor.sh" \
  -o "$MONITOR_DIR/claude-code-issue-monitor.sh"
chmod +x "$MONITOR_DIR/claude-code-issue-monitor.sh"
ok "claude-code-issue-monitor.sh"

# ── Cron (Linux/WSL) ──────────────────────────────────────────
h "Configurazione cron"

CRON_CMD="*/5 * * * * $MONITOR_DIR/claude-code-issue-monitor.sh >> $HOME/.claude/monitor/monitor.log 2>&1"

if crontab -l 2>/dev/null | grep -q "claude-code-issue-monitor"; then
  ok "Cron già configurato"
else
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
  ok "Cron aggiunto: ogni 5 minuti"
fi

# ── Riepilogo ─────────────────────────────────────────────────
echo ""
echo -e "\033[1m✅ Claude Code setup completato!\033[0m"
echo ""
echo "Installato in:"
echo "  Skills  : $SKILLS_DIR"
echo "  Monitor : $MONITOR_DIR"
echo "  Cron    : ogni 5 min (claude-code-issue-monitor)"
echo ""
echo "Per aggiornare: ri-esegui questo script"
echo ""
echo "Su Windows usa invece:"
echo "  install-claude-code.ps1"
