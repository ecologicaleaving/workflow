#!/usr/bin/env bash
# ============================================================
# setup-project.sh — Inizializza workflow context in un progetto
#
# Aggiunge il submodule .workflow e crea CLAUDE.md + AGENTS.md
# dal template, in modo che qualsiasi agente possa lavorare
# sul progetto sapendo come sincronizzarsi e cosa leggere.
#
# Uso:
#   curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/setup-project.sh | bash
#   oppure localmente:
#   bash /path/to/workflow/scripts/setup-project.sh
# ============================================================

set -e

WORKFLOW_REPO="https://github.com/ecologicaleaving/workflow.git"
WORKFLOW_DIR=".workflow"
RAW_BASE="https://raw.githubusercontent.com/ecologicaleaving/workflow/master"

echo "🔧 Setup workflow context nel progetto..."

# ── Verifica che siamo in una repo git ──────────────────────
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Errore: questa cartella non è una repository git."
  echo "   Esegui prima: git init"
  exit 1
fi

# ── Aggiungi submodule .workflow ─────────────────────────────
if [ -d "$WORKFLOW_DIR/.git" ] || git submodule status "$WORKFLOW_DIR" &>/dev/null; then
  echo "⚡ Submodule .workflow già presente — aggiorno all'ultima versione..."
  git submodule update --remote "$WORKFLOW_DIR"
else
  echo "📦 Aggiungo submodule .workflow..."
  git submodule add "$WORKFLOW_REPO" "$WORKFLOW_DIR"
  git submodule update --init --remote "$WORKFLOW_DIR"
fi

# ── Crea CLAUDE.md ───────────────────────────────────────────
if [ -f "CLAUDE.md" ]; then
  echo "⚠️  CLAUDE.md già esistente — backup in CLAUDE.md.bak"
  cp CLAUDE.md CLAUDE.md.bak
fi
echo "📝 Creo CLAUDE.md..."
curl -sSL "$RAW_BASE/templates/CLAUDE.md" -o CLAUDE.md

# ── Crea AGENTS.md ──────────────────────────────────────────
if [ -f "AGENTS.md" ]; then
  echo "⚠️  AGENTS.md già esistente — backup in AGENTS.md.bak"
  cp AGENTS.md AGENTS.md.bak
fi
echo "📝 Creo AGENTS.md..."
curl -sSL "$RAW_BASE/templates/AGENTS.md" -o AGENTS.md

# ── Aggiungi .gitmodules al commit ──────────────────────────
echo "✅ Setup completato!"
echo ""
echo "📋 Prossimi step:"
echo "   git add .gitmodules .workflow CLAUDE.md AGENTS.md"
echo "   git commit -m 'chore: aggiungi workflow context (CLAUDE.md, AGENTS.md, .workflow submodule)'"
echo "   git push"
