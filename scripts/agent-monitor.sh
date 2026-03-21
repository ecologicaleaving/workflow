#!/bin/bash
# ============================================================
# Agent Monitor — WSL / Linux / macOS
# ============================================================
# Monitora un agente in background (exec session o subagent)
# e notifica Claudio/Davide via system event quando:
# - Un checkpoint viene postato sulla issue
# - Un errore viene rilevato
# - L'agente è silenzioso da troppo tempo
# - L'agente termina
#
# Usage:
#   ./agent-monitor.sh <issue_n> <repo> [session_id]
#
#   issue_n:    Numero issue GitHub (es. 1)
#   repo:       Nome repo senza owner (es. BeachCRER)
#   session_id: (opzionale) ID sessione exec per process log monitoring
#               Se omesso, monitora solo i commenti sulla issue
#
# Il monitor si auto-termina quando:
# - Il processo exec termina (se session_id fornito)
# - Viene rilevato un commento con "Aspetto conferma" (checkpoint finale)
# - Viene killato manualmente (Ctrl+C o kill)
#
# Dipendenze: gh (GitHub CLI), curl (opzionale per system events)
# ============================================================

set -euo pipefail

ISSUE_N="${1:?Usage: $0 <issue_n> <repo> [session_id]}"
REPO="${2:?Usage: $0 <issue_n> <repo> [session_id]}"
SESSION_ID="${3:-}"

SILENT_MINUTES=0
SILENT_THRESHOLD=10
POLL_INTERVAL=60
LAST_COMMENT_COUNT=0
OWNER="ecologicaleaving"
KEYWORDS="error|failed|fail|exception|bloccato|blocked|done|completed|finished|push|checkpoint|CP[0-9]"

# ---- Helpers ----

log() {
  echo "[Monitor $(date +%H:%M:%S)] $*"
}

# Invia system event a OpenClaw (se gateway raggiungibile)
notify() {
  local text="$1"
  log "📣 $text"

  # Prova a inviare via openclaw CLI
  if command -v openclaw &>/dev/null; then
    openclaw system event --text "$text" --mode now 2>/dev/null || true
  fi
}

# ---- Init ----

log "Avviato per Issue #$ISSUE_N/$REPO"
[ -n "$SESSION_ID" ] && log "Monitora exec session: $SESSION_ID"

# Conta commenti iniziali
LAST_COMMENT_COUNT=$(gh issue view "$ISSUE_N" --repo "$OWNER/$REPO" --json comments --jq '.comments | length' 2>/dev/null || echo 0)
log "Commenti iniziali: $LAST_COMMENT_COUNT"

# ---- Main Loop ----

while true; do
  sleep "$POLL_INTERVAL"
  SILENT_MINUTES=$((SILENT_MINUTES + 1))

  # --- Check exec session (se fornito) ---
  if [ -n "$SESSION_ID" ]; then
    # Controlla se il processo è ancora vivo
    PROC_STATUS=$(openclaw process poll --session "$SESSION_ID" 2>&1 || true)
    if echo "$PROC_STATUS" | grep -qiE "exited|not found|No session"; then
      notify "🏁 [Issue #$ISSUE_N/$REPO] Agente terminato. Controlla output e commenti sulla issue."
      break
    fi

    # Leggi nuovo output e cerca keyword
    LOG_OUTPUT=$(openclaw process log --session "$SESSION_ID" --tail 50 2>&1 || true)
    if [ -n "$LOG_OUTPUT" ]; then
      if echo "$LOG_OUTPUT" | grep -qiE "$KEYWORDS"; then
        SNIPPET=$(echo "$LOG_OUTPUT" | grep -iE "$KEYWORDS" | tail -3)
        log "🔍 Keyword nell'output: $SNIPPET"
        SILENT_MINUTES=0
      fi
    fi
  fi

  # --- Check commenti issue (sempre) ---
  CURRENT_COUNT=$(gh issue view "$ISSUE_N" --repo "$OWNER/$REPO" --json comments --jq '.comments | length' 2>/dev/null || echo 0)

  if [ "$CURRENT_COUNT" -gt "$LAST_COMMENT_COUNT" ]; then
    # Nuovi commenti rilevati
    NEW_COMMENTS=$((CURRENT_COUNT - LAST_COMMENT_COUNT))
    LAST_COMMENT=$(gh issue view "$ISSUE_N" --repo "$OWNER/$REPO" --json comments --jq '.comments[-1].body' 2>/dev/null || echo "")
    LAST_COMMENT_COUNT=$CURRENT_COUNT
    SILENT_MINUTES=0

    # Classifica il commento
    if echo "$LAST_COMMENT" | grep -qiE "checkpoint|CP[0-9]"; then
      TITLE=$(echo "$LAST_COMMENT" | grep -iE "checkpoint|CP[0-9]" | head -1 | sed 's/^#* //')
      notify "✅ [Issue #$ISSUE_N/$REPO] $TITLE"
    elif echo "$LAST_COMMENT" | grep -qiE "error|failed|fail|exception|bloccato|blocked"; then
      SNIPPET=$(echo "$LAST_COMMENT" | head -3)
      notify "⚠️ [Issue #$ISSUE_N/$REPO] Possibile errore: $SNIPPET"
    else
      log "📝 Nuovo commento (#$CURRENT_COUNT) — non è un checkpoint"
    fi

    # Auto-stop se checkpoint finale
    if echo "$LAST_COMMENT" | grep -qiE "Aspetto conferma|pronto per push|CP4"; then
      log "🏁 Checkpoint finale rilevato. Monitor terminato."
      notify "🏁 [Issue #$ISSUE_N/$REPO] Agente ha raggiunto il checkpoint finale."
      break
    fi
  fi

  # --- Silenzio prolungato ---
  if [ "$SILENT_MINUTES" -ge "$SILENT_THRESHOLD" ]; then
    notify "⚠️ [Issue #$ISSUE_N/$REPO] Agente silenzioso da ${SILENT_MINUTES}+ minuti. Verificare."
    SILENT_MINUTES=0
  fi

  log "Tick ${SILENT_MINUTES}m — commenti: $CURRENT_COUNT"
done

log "Monitor terminato."
