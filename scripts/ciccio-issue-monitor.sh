#!/bin/bash
# =============================================================
# ciccio-issue-monitor.sh
# VPS-side cron — detecta issue con label "ciccio", spawna
# un subagente OpenClaw con sonnet per risolverle.
# Ciccio rimane libero per Davide durante l'elaborazione.
#
# Cron: */10 * * * * /root/.openclaw/workspace-ciccio/scripts/ciccio-issue-monitor.sh >> /var/log/ciccio-issue-monitor.log 2>&1
# =============================================================

set -euo pipefail
export PATH=$PATH:/root/go/bin

LOCK_DIR="/tmp/ciccio-issue-locks"
GATEWAY_URL="http://localhost:18789"
GATEWAY_TOKEN="4bc2ca729e6353582546104e147d40ccae24574f98005c66"
MODEL="anthropic/claude-sonnet-4-6"
LABEL_TRIGGER="ciccio"
LABEL_PROCESSING="in-progress"
LABEL_DONE="review-ready"
TELEGRAM_CHAT="1634377998"

mkdir -p "$LOCK_DIR"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

# ---- Fetch open issues con label "ciccio" (non in-progress) ----
log "Checking issues with label: $LABEL_TRIGGER"

ISSUES_JSON=$(gh issue list \
  --label "$LABEL_TRIGGER" \
  --state open \
  --json number,title,body,url,labels,repository \
  --limit 10 2>/dev/null) || { log "ERROR: gh issue list failed"; exit 1; }

COUNT=$(echo "$ISSUES_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
log "Found $COUNT issue(s)"
[ "$COUNT" = "0" ] && exit 0

# ---- Per ogni issue, controlla lock e spawna subagente ----
while IFS= read -r ISSUE; do
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

  log "Prendo in carico issue #$NUMBER: $TITLE ($REPO)"

  # Lock + etichetta
  echo $$ > "$LOCK_FILE"
  gh issue edit "$NUMBER" --repo "$REPO" --add-label "$LABEL_PROCESSING" 2>/dev/null \
    && log "Issue #$NUMBER: etichetta '$LABEL_PROCESSING' aggiunta" \
    || log "WARNING: impossibile etichettare issue #$NUMBER"

  # ---- Prompt per subagente ----
  TASK=$(cat <<TASK_EOF
Sei Ciccio, agente DevOps/Developer di 8020 Solutions su VPS Linux (arm64).
Risolvi la seguente GitHub issue seguendo la skill issue-resolver.

REPOSITORY: $REPO
ISSUE #$NUMBER: $TITLE
URL: $URL

DESCRIZIONE:
$BODY

ISTRUZIONI (segui in ordine, non saltare fasi):

1. Setup repo locale:
   mkdir -p /tmp/ciccio-work && cd /tmp/ciccio-work
   [ -d $REPO_SHORT ] && (cd $REPO_SHORT && git fetch && git checkout master && git pull) \
     || gh repo clone $REPO $REPO_SHORT
   cd $REPO_SHORT
   git checkout -b feature/issue-$NUMBER 2>/dev/null || git checkout feature/issue-$NUMBER

2. Segui ESATTAMENTE la skill issue-resolver (fasi 1-6):
   - Fase 1: Research codebase
   - Fase 2: Plan
   - Fase 3: Implementazione iterativa (implement → test → fix, max 5 iter/suite)
   - Fase 4: Verifica finale + Playwright E2E se è web app
   - Fase 5: Aggiorna PROJECT.md (version bump, backlog DONE, timestamp)
   - Fase 6: Commit convenzionale (NO git push manuale)

3. Push e cleanup label:
   git push origin feature/issue-$NUMBER
   gh issue edit $NUMBER --repo $REPO \
     --add-label $LABEL_DONE \
     --remove-label $LABEL_PROCESSING \
     --remove-label $LABEL_TRIGGER

4. Notifica Davide via messaggio (channel telegram, target $TELEGRAM_CHAT):
   "✅ Issue #$NUMBER ($TITLE) risolta.
    Branch: feature/issue-$NUMBER
    Repo: $REPO
    Pronto per review e deploy."

VINCOLI ASSOLUTI:
- NO: git merge / git reset / modifica branch master
- Se test falliscono dopo 5 iterazioni: documenta e stoppa, notifica Davide
- Playwright obbligatorio per web apps (React/Next.js)
- Lock file da rimuovere SOLO a completamento: rm -f $LOCK_FILE
TASK_EOF
)

  # ---- Spawna subagente via OpenClaw API ----
  PAYLOAD=$(python3 -c "
import json, sys
task = sys.stdin.read()
print(json.dumps({
  'tool': 'sessions_spawn',
  'args': {
    'task': task,
    'model': '$MODEL',
    'mode': 'run',
    'label': 'issue-${REPO_SHORT}-${NUMBER}',
    'cleanup': 'keep'
  }
}))" <<< "$TASK")

  RESPONSE=$(curl -s -X POST "$GATEWAY_URL/tools/invoke" \
    -H "Authorization: Bearer $GATEWAY_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" 2>/dev/null) || RESPONSE="{}"

  SESSION=$(echo "$RESPONSE" | python3 -c "
import sys,json
r=json.load(sys.stdin)
print(r.get('result',{}).get('sessionKey') or r.get('sessionKey','spawn-failed'))
" 2>/dev/null || echo "unknown")

  log "Issue #$NUMBER → subagente spawned (session: $SESSION). Ciccio libero."

done < <(echo "$ISSUES_JSON" | python3 -c "
import sys,json
issues=json.load(sys.stdin)
for i in issues: print(json.dumps(i))
")

log "Monitor run complete."
