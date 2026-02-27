#!/bin/bash
# ================================================================
# install.sh — 80/20 Solutions Workflow — Master Installer
# Detecta l'ambiente e installa il modulo corretto.
#
# Uso:
#   curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/install.sh | bash
#
# Override manuale:
#   COMPONENT=ciccio bash install.sh
#   COMPONENT=claude-code bash install.sh
# ================================================================

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ecologicaleaving/workflow/master"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
h()    { echo -e "\n${BOLD}▸ $1${NC}"; }

echo ""
echo -e "${BOLD}80/20 Solutions — Workflow Installer${NC}"
echo "======================================"

# ── Rilevamento ambiente ──────────────────────────────────────
h "Rilevamento ambiente"

COMPONENT="${COMPONENT:-auto}"

if [ "$COMPONENT" = "auto" ]; then
  if [ -d "/root/.openclaw" ] && [ -f "/etc/debian_version" ]; then
    COMPONENT="ciccio"
    ok "Rilevato: VPS Ciccio (OpenClaw)"
  elif command -v claude &>/dev/null && [ ! -d "/root/.openclaw" ]; then
    COMPONENT="claude-code"
    ok "Rilevato: Claude Code (PC/Linux)"
  else
    echo ""
    echo "Non riesco a rilevare l'ambiente automaticamente."
    echo "Scegli il componente da installare:"
    echo "  1) ciccio      — VPS con OpenClaw"
    echo "  2) claude-code — PC con Claude Code (Linux/WSL)"
    echo ""
    read -rp "Scelta [1/2]: " CHOICE
    case "$CHOICE" in
      1) COMPONENT="ciccio" ;;
      2) COMPONENT="claude-code" ;;
      *) echo "Scelta non valida."; exit 1 ;;
    esac
  fi
fi

# ── Esecuzione installer ──────────────────────────────────────
h "Installazione: $COMPONENT"

SCRIPT_URL="$REPO_RAW/scripts/install-${COMPONENT}.sh"

TMP=$(mktemp)
curl -sSL "$SCRIPT_URL" -o "$TMP" || {
  echo "❌ Impossibile scaricare $SCRIPT_URL"
  exit 1
}
chmod +x "$TMP"
bash "$TMP"
rm -f "$TMP"

echo ""
echo -e "${BOLD}✅ Setup completato per: $COMPONENT${NC}"
echo ""
echo "Per aggiornare in futuro:"
echo "  curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/install.sh | bash"
