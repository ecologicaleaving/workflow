#!/bin/bash
# =============================================================
# ciccio-issue-monitor.sh
# VPS-side cron — detecta issue con label "ciccio", le lavora.
# Rework: issue con "needs-fix" + "ciccio" (include feedback).
# Issues con "claude-code" vengono IGNORATE (le gestisce il PC).
#
# Routing simmetrico:
#   ciccio     → VPS (questo monitor)
#   claude-code → PC (claude-monitor.ps1)
#   needs-fix  → stesso agente della label originale (ciccio o claude-code)
#
# Cron: */10 * * * * /root/.openclaw/workspace-ciccio/scripts/ciccio-issue-monitor.sh >> /var/log/ciccio-issue-monitor.log 2>&1
# =============================================================

set -euo pipefail
export PATH=$PATH:/root/go/bin

LOCK_DIR="/tmp/ciccio-issue-locks"
GATEWAY_URL="http://localhost:18789"
GATEWAY_TOKEN="4bc2ca729e6353582546104e147d40ccae24574f98005c66"
MODEL="anthropic/claude-sonnet-4-6"
LABEL_DONE="review-ready"
LABEL_PROCESSING="in-progress"
TELEGRAM_CHAT="1634377998"

mkdir -p "$LOCK_DIR"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

process_issues() {
  local TRIGGER_LABEL="$1"
  local IS_REWORK="${2:-false}"  # true se needs-fix

  log "--- Checking label: $TRIGGER_LABEL ---"

  local ISSUES_JSON
  ISSUES_JSON=$(gh search issues \
    --label "$TRIGGER_LABEL" \
    --owner ecologicaleaving \
    --state open \
    --json number,title,body,url,labels,repository \
    --limit 10 2>/dev/null) || { log "ERROR: gh search issues failed for $TRIGGER_LABEL"; return 1; }

  local COUNT
  COUNT=$(echo "$ISSUES_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
  log "Found $COUNT issue(s) with label '$TRIGGER_LABEL'"
  [ "$COUNT" = "0" ] && return 0

  while IFS= read -r ISSUE; do
    local NUMBER TITLE BODY URL REPO LABELS REPO_SHORT LOCK_FILE

    NUMBER=$(echo "$ISSUE"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['number'])")
    TITLE=$(echo "$ISSUE"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['title'])")
    BODY=$(echo "$ISSUE"    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('body',''))")
    URL=$(echo "$ISSUE"     | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('url',''))")
    REPO=$(echo "$ISSUE"    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('repository',{}).get('nameWithOwner','ecologicaleaving/unknown'))")
    LABELS=$(echo "$ISSUE"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(l['name'] for l in d.get('labels',[])))")
    REPO_SHORT="${REPO##*/}"
    LOCK_FILE="$LOCK_DIR/${REPO//\//-}-${NUMBER}.lock"

    # Skip se già in lavorazione
    if [ -f "$LOCK_FILE" ]; then
      log "Issue #$NUMBER: locked, skip"
      continue
    fi
    if echo "$LABELS" | grep -q "$LABEL_PROCESSING"; then
      log "Issue #$NUMBER: già in-progress, skip"
      continue
    fi

    # Routing check: se è un rework (needs-fix), VPS la prende solo se ha label "ciccio"
    # Se ha "claude-code" → di competenza del PC, skip
    if [ "$IS_REWORK" = "true" ]; then
      if echo "$LABELS" | grep -q "claude-code"; then
        log "Issue #$NUMBER: needs-fix + claude-code → skip (gestisce PC)"
        continue
      fi
      if ! echo "$LABELS" | grep -q "ciccio"; then
        log "Issue #$NUMBER: needs-fix senza label agente assegnata → skip"
        continue
      fi
    fi

    # ---- Recupera commenti se è un rework (needs-fix) ----
    local FEEDBACK_SECTION=""
    if [ "$IS_REWORK" = "true" ]; then
      local COMMENTS_JSON
      COMMENTS_JSON=$(gh issue view "$NUMBER" --repo "$REPO" --json comments 2>/dev/null || echo '{"comments":[]}')
      FEEDBACK_SECTION=$(echo "$COMMENTS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
comments = data.get('comments', [])
if not comments:
    print('(nessun commento di feedback trovato)')
else:
    lines = ['=== FEEDBACK DAI TEST ===']
    for c in comments:
        author = c.get('author', {}).get('login', 'unknown')
        body   = c.get('body', '').strip()
        date   = c.get('createdAt', '')[:10]
        lines.append(f'[{date}] @{author}:')
        lines.append(body)
        lines.append('')
    print('\n'.join(lines))
")
      log "Issue #$NUMBER: recuperati commenti di feedback per rework"
    fi

    log "$([ "$IS_REWORK" = "true" ] && echo "REWORK" || echo "NEW") issue #$NUMBER: $TITLE ($REPO)"

    # Lock + label in-progress + sposta card su "In Progress"
    # NOTA: NON rimuoviamo la label agente (ciccio) — serve per routing nei rework.
    # Rimuoviamo solo "needs-fix" se era il trigger (è una label di segnale, non identità).
    echo $$ > "$LOCK_FILE"
    if [ "$IS_REWORK" = "true" ]; then
      gh issue edit "$NUMBER" --repo "$REPO" \
        --add-label "$LABEL_PROCESSING" \
        --remove-label "needs-fix" 2>/dev/null \
        && log "Issue #$NUMBER: label → in-progress (needs-fix rimosso, ciccio mantenuto)" \
        || log "WARNING: impossibile aggiornare label issue #$NUMBER"
    else
      gh issue edit "$NUMBER" --repo "$REPO" \
        --add-label "$LABEL_PROCESSING" 2>/dev/null \
        && log "Issue #$NUMBER: label → in-progress (ciccio mantenuto)" \
        || log "WARNING: impossibile aggiornare label issue #$NUMBER"
    fi
    python3 /root/.openclaw/workspace-ciccio/scripts/project_board.py "$REPO" "$NUMBER" "In Progress" 2>/dev/null \
      && log "Issue #$NUMBER: card → In Progress" \
      || log "WARNING: card move fallito per #$NUMBER"

    # ---- Prompt per subagente ----
    local REWORK_HEADER=""
    if [ "$IS_REWORK" = "true" ]; then
      REWORK_HEADER="⚠️  REWORK RICHIESTO — questa issue è già stata lavorata ma i test hanno rilevato problemi.
Leggi ATTENTAMENTE il feedback qui sotto prima di fare qualsiasi cosa.
NON ripartire da zero: analizza cosa non funzionava e correggi solo quello.

$FEEDBACK_SECTION
=========================="
    fi

    local TASK
    TASK=$(cat <<TASK_EOF
Sei Ciccio, agente DevOps/Developer di 8020 Solutions su VPS Linux (arm64).
$([ "$IS_REWORK" = "true" ] && echo "$REWORK_HEADER" || echo "Risolvi la seguente GitHub issue seguendo la skill issue-resolver.")

REPOSITORY: $REPO
ISSUE #$NUMBER: $TITLE
URL: $URL

DESCRIZIONE ORIGINALE:
$BODY

ISTRUZIONI (segui in ordine, non saltare fasi):

1. Setup repo locale:
   mkdir -p /tmp/ciccio-work && cd /tmp/ciccio-work
   [ -d $REPO_SHORT ] && (cd $REPO_SHORT && git fetch && git pull) \
     || gh repo clone $REPO $REPO_SHORT
   cd $REPO_SHORT
   $([ "$IS_REWORK" = "true" ] \
     && echo "git checkout feature/issue-$NUMBER 2>/dev/null || git checkout -b feature/issue-$NUMBER" \
     && echo "   # Continua dal branch esistente — non ricreare da zero" \
     || echo "git checkout -b feature/issue-$NUMBER 2>/dev/null || git checkout feature/issue-$NUMBER")

2. Segui ESATTAMENTE la skill issue-resolver (fasi 1-6):
   - Fase 1: Research codebase $([ "$IS_REWORK" = "true" ] && echo "(focalizzati sulle aree segnalate nel feedback)" || echo "")
   - Fase 2: Plan $([ "$IS_REWORK" = "true" ] && echo "(piano di fix basato sul feedback)" || echo "")
   - Fase 3: Implementazione iterativa (implement → test → fix, max 5 iter/suite)
   - Fase 4: Verifica finale + Playwright E2E se è web app
   - Fase 5: Aggiorna PROJECT.md (version bump, backlog, timestamp)
   - Fase 6: Commit convenzionale (NO git push manuale)

3. Push, aggiorna label e sposta card su PUSH:
   git push origin feature/issue-$NUMBER
   gh issue edit $NUMBER --repo $REPO \
     --add-label $LABEL_DONE \
     --remove-label $LABEL_PROCESSING
   # NON rimuovere la label "ciccio" — serve per routing in caso di rework
   python3 /root/.openclaw/workspace-ciccio/scripts/project_board.py $REPO $NUMBER "PUSH"

4. Notifica Davide (channel telegram, target $TELEGRAM_CHAT):
$([ "$IS_REWORK" = "true" ] \
  && echo "   \"🔧 Issue #$NUMBER ($TITLE) — rework completato.\"" \
  || echo "   \"✅ Issue #$NUMBER ($TITLE) risolta.\"")
   "Branch: feature/issue-$NUMBER | Repo: $REPO | Pronto per review."

VINCOLI ASSOLUTI:
- NO: git merge / git reset / modifica master
- Se test falliscono dopo 5 iter: documenta, stoppa, notifica Davide
- Playwright obbligatorio per web apps (React/Next.js)
- Lock file da rimuovere a completamento: rm -f $LOCK_FILE
TASK_EOF
)

    # ---- Spawn subagente ----
    local SESSION_LABEL
    SESSION_LABEL="$([ "$IS_REWORK" = "true" ] && echo "rework" || echo "issue")-${REPO_SHORT}-${NUMBER}"

    local PAYLOAD
    PAYLOAD=$(python3 -c "
import json, sys
task = sys.stdin.read()
print(json.dumps({
  'tool': 'sessions_spawn',
  'args': {
    'task': task,
    'model': '$MODEL',
    'mode': 'run',
    'label': '$SESSION_LABEL',
    'cleanup': 'keep'
  }
}))" <<< "$TASK")

    local RESPONSE SESSION
    RESPONSE=$(curl -s -X POST "$GATEWAY_URL/tools/invoke" \
      -H "Authorization: Bearer $GATEWAY_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" 2>/dev/null) || RESPONSE="{}"

    SESSION=$(echo "$RESPONSE" | python3 -c "
import sys,json
r=json.load(sys.stdin)
print(r.get('result',{}).get('sessionKey') or r.get('sessionKey','spawn-failed'))
" 2>/dev/null || echo "unknown")

    log "Issue #$NUMBER → subagente spawned (session: $SESSION, rework: $IS_REWORK). Ciccio libero."

  done < <(echo "$ISSUES_JSON" | python3 -c "
import sys,json
issues=json.load(sys.stdin)
for i in issues: print(json.dumps(i))
")
}

# ---- Run ----
process_issues "ciccio"     "false"
process_issues "needs-fix"  "true"

log "Monitor run complete."
