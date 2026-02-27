#!/bin/bash
# ================================================================
# install-ciccio.sh — Setup Ciccio (OpenClaw VPS)
# Installa script, skill e cron per l'agente orchestratore.
#
# Uso:
#   curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-ciccio.sh | bash
#   oppure: bash install-ciccio.sh
# ================================================================

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ecologicaleaving/workflow/master"
WORKSPACE="${OPENCLAW_WORKSPACE:-/root/.openclaw/workspace-ciccio}"
SCRIPTS_DIR="$WORKSPACE/scripts"
SKILLS_DIR="$WORKSPACE/skills"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
h()    { echo -e "\n\033[1m▸ $1\033[0m"; }

# ── Prerequisiti ──────────────────────────────────────────────
h "Verifica prerequisiti"

[ -d "/root/.openclaw" ] || err "OpenClaw non trovato. Questo script è per il VPS Ciccio."
command -v gh   &>/dev/null || err "gh CLI non trovato (installa: https://cli.github.com)"
command -v python3 &>/dev/null || err "python3 non trovato"
command -v curl &>/dev/null || err "curl non trovato"

ok "Prerequisiti OK"

# ── Directories ───────────────────────────────────────────────
h "Creazione directory"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$SKILLS_DIR"
ok "Directory pronte: $SCRIPTS_DIR / $SKILLS_DIR"

# ── Script VPS ────────────────────────────────────────────────
h "Download script"

SCRIPTS=(
  "scripts/project_board.py"
  "scripts/issue_slash_command.py"
  "scripts/ciccio-issue-monitor.sh"
  "scripts/triage_command.py"
  "scripts/auto_issue_parser.py"
)

for FILE in "${SCRIPTS[@]}"; do
  DEST="$SCRIPTS_DIR/$(basename $FILE)"
  curl -sSL "$REPO_RAW/$FILE" -o "$DEST"
  chmod +x "$DEST" 2>/dev/null || true
  ok "$(basename $FILE)"
done

# ── Skill 8020-workflow (OpenClaw) ────────────────────────────
h "Installazione skill 8020-workflow"

SKILL_DIR="$SKILLS_DIR/8020-workflow"
SKILL_REFS="$SKILL_DIR/references"
mkdir -p "$SKILL_REFS"

curl -sSL "$REPO_RAW/skills/8020-workflow/SKILL.md" -o "$SKILL_DIR/SKILL.md"
ok "SKILL.md"

REFS=(
  "WORKFLOW_CICCIO.md"
  "WORKFLOW_CLAUDE_CODE.md"
  "WORKFLOW_DAVID.md"
  "BRANCH_STRATEGY.md"
  "COMMIT_CONVENTIONS.md"
)
for REF in "${REFS[@]}"; do
  curl -sSL "$REPO_RAW/skills/8020-workflow/references/$REF" -o "$SKILL_REFS/$REF"
  ok "references/$REF"
done

# ── ciccio-notify ─────────────────────────────────────────────
h "Installazione ciccio-notify"

if [ ! -f "/usr/local/bin/ciccio-notify" ]; then
  curl -sSL "$REPO_RAW/scripts/ciccio-notify.sh" -o /usr/local/bin/ciccio-notify
  chmod +x /usr/local/bin/ciccio-notify
  ok "ciccio-notify installato in /usr/local/bin/"
else
  ok "ciccio-notify già presente"
fi

# ── Cron job ──────────────────────────────────────────────────
h "Configurazione cron"

CRON_CMD="*/10 * * * * $SCRIPTS_DIR/ciccio-issue-monitor.sh >> /var/log/ciccio-issue-monitor.log 2>&1"

if crontab -l 2>/dev/null | grep -q "ciccio-issue-monitor"; then
  ok "Cron già configurato"
else
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
  ok "Cron aggiunto: ogni 10 minuti"
fi

# ── Riepilogo ─────────────────────────────────────────────────
echo ""
echo -e "\033[1m✅ Ciccio setup completato!\033[0m"
echo ""
echo "Installato in:"
echo "  Scripts : $SCRIPTS_DIR"
echo "  Skill   : $SKILLS_DIR/8020-workflow"
echo "  Notify  : /usr/local/bin/ciccio-notify"
echo "  Cron    : ogni 10 min (ciccio-issue-monitor)"
echo ""
echo "Per aggiornare: ri-esegui questo script"
