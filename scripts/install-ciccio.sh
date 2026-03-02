#!/bin/bash
# ================================================================
# install-ciccio.sh — Setup Ciccio (OpenClaw VPS)
# Installa script e skill per l'agente orchestratore.
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
command -v gh      &>/dev/null || err "gh CLI non trovato (installa: https://cli.github.com)"
command -v python3 &>/dev/null || err "python3 non trovato"
command -v curl    &>/dev/null || err "curl non trovato"

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
  "scripts/triage_command.py"
  "scripts/auto_issue_parser.py"
)

for FILE in "${SCRIPTS[@]}"; do
  DEST="$SCRIPTS_DIR/$(basename $FILE)"
  curl -sSL "$REPO_RAW/$FILE" -o "$DEST"
  chmod +x "$DEST" 2>/dev/null || true
  ok "$(basename $FILE)"
done

# ── Skill 8020-workflow ───────────────────────────────────────
h "Installazione skill 8020-workflow"

SKILL_DIR="$SKILLS_DIR/8020-workflow"
SKILL_REFS="$SKILL_DIR/references"
mkdir -p "$SKILL_REFS"

curl -sSL "$REPO_RAW/skills/8020-workflow/SKILL.md" -o "$SKILL_DIR/SKILL.md"
ok "8020-workflow/SKILL.md"

for REF in WORKFLOW_CICCIO.md WORKFLOW_CLAUDE_CODE.md WORKFLOW_DAVID.md BRANCH_STRATEGY.md COMMIT_CONVENTIONS.md; do
  curl -sSL "$REPO_RAW/skills/8020-workflow/references/$REF" -o "$SKILL_REFS/$REF"
  ok "  references/$REF"
done

# ── Skill workflow modulari ───────────────────────────────────
h "Installazione skill workflow modulari"

SIMPLE_SKILLS=(
  "issue-start"
  "issue-done"
  "issue-deploy-test"
  "issue-deploy-prod"
  "issue-reject"
  "issue-review"
  "create-issue"
)

for SKILL in "${SIMPLE_SKILLS[@]}"; do
  mkdir -p "$SKILLS_DIR/$SKILL"
  curl -sSL "$REPO_RAW/skills/$SKILL/SKILL.md" -o "$SKILLS_DIR/$SKILL/SKILL.md"
  ok "$SKILL"
done

# create-issue ha assets
mkdir -p "$SKILLS_DIR/create-issue/assets"
curl -sSL "$REPO_RAW/skills/create-issue/assets/issue-template.md" \
  -o "$SKILLS_DIR/create-issue/assets/issue-template.md"
ok "  create-issue/assets/issue-template.md"

# ── Skill 8020-commit-workflow ────────────────────────────────
h "Installazione skill 8020-commit-workflow"

mkdir -p "$SKILLS_DIR/8020-commit-workflow/references"
curl -sSL "$REPO_RAW/skills/8020-commit-workflow/SKILL.md" \
  -o "$SKILLS_DIR/8020-commit-workflow/SKILL.md"
ok "8020-commit-workflow/SKILL.md"
curl -sSL "$REPO_RAW/skills/8020-commit-workflow/references/workflow-rules.md" \
  -o "$SKILLS_DIR/8020-commit-workflow/references/workflow-rules.md"
ok "  references/workflow-rules.md"

# ── ciccio-notify ─────────────────────────────────────────────
h "Installazione ciccio-notify"

curl -sSL "$REPO_RAW/scripts/ciccio-notify.sh" -o /usr/local/bin/ciccio-notify
chmod +x /usr/local/bin/ciccio-notify
ok "ciccio-notify → /usr/local/bin/"

# ── Rimuovi cron obsoleto ─────────────────────────────────────
h "Pulizia cron obsoleti"

if crontab -l 2>/dev/null | grep -q "issue-monitor"; then
  crontab -l 2>/dev/null | grep -v "issue-monitor" | crontab -
  ok "Cron issue-monitor rimosso (monitor deprecato)"
else
  ok "Nessun cron obsoleto da rimuovere"
fi

# ── Riepilogo ─────────────────────────────────────────────────
echo ""
echo -e "\033[1m✅ Ciccio setup completato!\033[0m"
echo ""
echo "Installato in:"
echo "  Scripts : $SCRIPTS_DIR"
echo "  Skills  : $SKILLS_DIR"
echo "    - 8020-workflow (+ references)"
echo "    - 8020-commit-workflow (+ references)"
echo "    - issue-start / issue-done / issue-deploy-test"
echo "    - issue-deploy-prod / issue-reject / issue-review"
echo "    - create-issue (+ assets)"
echo "  Notify  : /usr/local/bin/ciccio-notify"
echo ""
echo "Per aggiornare: ri-esegui questo script"
