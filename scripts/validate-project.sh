#!/usr/bin/env bash
# validate-project.sh — Pre-flight check prima di lanciare qualsiasi agente
# Uso: bash validate-project.sh [path/to/project]
# Exit 0 = tutto ok | Exit 1 = check fallito

set -euo pipefail

PROJECT_DIR="${1:-.}"
ERRORS=()
WARNINGS=()

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  local label="$1"
  local path="$2"
  if [ -e "$PROJECT_DIR/$path" ]; then
    echo -e "${GREEN}✓${NC} $label"
  else
    echo -e "${RED}✗${NC} $label — MANCANTE: $path"
    ERRORS+=("$label")
  fi
}

warn() {
  local label="$1"
  local path="$2"
  if [ -e "$PROJECT_DIR/$path" ]; then
    echo -e "${GREEN}✓${NC} $label"
  else
    echo -e "${YELLOW}⚠${NC} $label — non trovato: $path (opzionale)"
    WARNINGS+=("$label")
  fi
}

echo ""
echo "🔍 Validazione progetto: $PROJECT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check obbligatori
check "AGENTS.md (Codex)"        "AGENTS.md"
check "CLAUDE.md (Claude Code)"  "CLAUDE.md"
check "PROJECT.md"               "PROJECT.md"
check ".workflow submodule"      ".workflow"
check "CI/CD configurata"        ".github/workflows"
check ".gitignore"               ".gitignore"

# Check opzionali
warn "PR template"               ".github/pull_request_template.md"
warn "Test directory"            "test"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#ERRORS[@]} -eq 0 ]; then
  echo -e "${GREEN}✅ Pre-flight OK — puoi lanciare l'agente${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}❌ Pre-flight FALLITO — ${#ERRORS[@]} check obbligatori mancanti:${NC}"
  for e in "${ERRORS[@]}"; do
    echo -e "   ${RED}→ $e${NC}"
  done
  echo ""
  echo "👉 Esegui scripts/setup-project.sh per correggere, poi riprova."
  echo ""
  exit 1
fi
