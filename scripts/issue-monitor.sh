#!/bin/bash
# ============================================================
# issue-monitor.sh — 8020 Solutions Unified Issue Monitor v1.0
# One script, any machine. Config: ~/.openclaw/monitor.conf
#
# VPS cron:   */10 * * * * /path/to/issue-monitor.sh >> /var/log/issue-monitor.log 2>&1
# PC Task Scheduler: ogni 5 min via Git Bash
# ============================================================

set -uo pipefail
export PATH=$PATH:/usr/local/bin:/root/go/bin

# ---- Load config ----
CONF="${HOME}/.openclaw/monitor.conf"
if [ ! -f "$CONF" ]; then
  echo "[ERROR] Config not found: $CONF"
  echo "        Copia scripts/monitor-pc.conf o monitor-vps.conf in $CONF"
  exit 1
fi
# shellcheck source=/dev/null
source "$CONF"

# ---- Required ----
: "${GATEWAY_TOKEN:?'GATEWAY_TOKEN non impostato in monitor.conf'}"
: "${AGENT_COUNT:?'AGENT_COUNT non impostato in monitor.conf'}"

# ---- Defaults ----
GATEWAY_URL="${GATEWAY_URL:-http://localhost:18789}"
WORK_DIR="${WORK_DIR:-/tmp/monitor-work}"
MODEL="${MODEL:-anthropic/claude-sonnet-4-6}"
TELEGRAM_CHAT="${TELEGRAM_CHAT:-1634377998}"
LABEL_DONE="${LABEL_DONE:-review-ready}"
LABEL_PROCESSING="${LABEL_PROCESSING:-in-progress}"
REWORK_LABEL="${REWORK_LABEL:-needs-fix}"
GITHUB_ORG="${GITHUB_ORG:-ecologicaleaving}"
PROJECT_BOARD_SCRIPT="${PROJECT_BOARD_SCRIPT:-}"
LOCK_DIR="${LOCK_DIR:-/tmp/monitor-locks}"

mkdir -p "$LOCK_DIR" "$WORK_DIR"

# ---- Logging ----
log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING: $*"; }

# ---- Project board (opzionale) ----
move_card() {
  local repo="$1" number="$2" status="$3"
  if [ -n "$PROJECT_BOARD_SCRIPT" ] && [ -f "$PROJECT_BOARD_SCRIPT" ]; then
    python3 "$PROJECT_BOARD_SCRIPT" "$repo" "$number" "$status" 2>/dev/null \
      && log "Card #$number → $status" \
      || warn "Card move fallito per #$number"
  fi
}

# ---- Recupera commenti per rework ----
get_feedback() {
  local repo="$1" number="$2"
  local comments_json
  comments_json=$(gh issue view "$number" --repo "$repo" --json comments 2>/dev/null \
    || echo '{"comments":[]}')
  echo "$comments_json" | python3 -c "
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
"
}

# ---- Spawn subagente via OpenClaw gateway ----
spawn_agent() {
  local task="$1" session_label="$2"
  local payload
  payload=$(python3 -c "
import json, sys
task = sys.stdin.read()
print(json.dumps({
  'tool': 'sessions_spawn',
  'args': {
    'task': task,
    'model': '$MODEL',
    'mode': 'run',
    'label': '$session_label',
    'cleanup': 'keep'
  }
}))" <<< "$task")

  local response session
  response=$(curl -s -X POST "$GATEWAY_URL/tools/invoke" \
    -H "Authorization: Bearer $GATEWAY_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null) || response="{}"

  session=$(echo "$response" | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r.get('result', {}).get('details', {}).get('childSessionKey') or r.get('result', {}).get('sessionKey') or r.get('sessionKey', 'spawn-failed'))
" 2>/dev/null || echo "unknown")

  echo "$session"
}

# ---- Processa una singola issue ----
process_issue() {
  local repo="$1" number="$2" title="$3" body="$4"
  local agent_label="$5" agent_name="$6" agent_identity="$7"
  local is_rework="${8:-false}"

  local repo_short="${repo##*/}"
  local lock_file="$LOCK_DIR/${repo//\//-}-${number}.lock"
  local labels
  labels=$(gh issue view "$number" --repo "$repo" \
    --json labels --jq '[.labels[].name] | join(",")' 2>/dev/null || echo "")

  # Skip se locked
  if [ -f "$lock_file" ]; then
    log "Issue #$number: locked, skip"
    return
  fi
  # Skip se già in-progress
  if echo "$labels" | grep -q "$LABEL_PROCESSING"; then
    log "Issue #$number: già in-progress, skip"
    return
  fi
  # Skip se già completata
  if echo "$labels" | grep -q "$LABEL_DONE"; then
    log "Issue #$number: già review-ready, skip"
    return
  fi

  # Acquisisci lock
  echo $$ > "$lock_file"

  # Prepara contesto rework se necessario
  local rework_header=""
  if [ "$is_rework" = "true" ]; then
    local feedback_section
    feedback_section=$(get_feedback "$repo" "$number")
    rework_header="⚠️  REWORK RICHIESTO — questa issue è già stata lavorata ma i test hanno rilevato problemi.
Leggi ATTENTAMENTE il feedback qui sotto prima di fare qualsiasi cosa.
NON ripartire da zero: analizza cosa non funzionava e correggi solo quello.

$feedback_section
=========================="
    log "REWORK issue #$number: $title ($repo) → $agent_name"
  else
    log "NEW issue #$number: $title ($repo) → $agent_name"
  fi

  # Label → in-progress + sposta card
  gh issue edit "$number" --repo "$repo" --add-label "$LABEL_PROCESSING" 2>/dev/null \
    && log "Issue #$number: label → in-progress" \
    || warn "Impossibile aggiornare label per #$number"
  move_card "$repo" "$number" "In Progress"

  # ---- Costruisci il task prompt ----
  local board_cmd=""
  if [ -n "$PROJECT_BOARD_SCRIPT" ]; then
    board_cmd="python3 $PROJECT_BOARD_SCRIPT $repo $number PUSH"
  fi

  local task
  task=$(cat <<TASK_EOF
$agent_identity
$([ "$is_rework" = "true" ] && echo "$rework_header" || echo "Risolvi la seguente GitHub issue seguendo la skill issue-resolver.")

REPOSITORY: $repo
ISSUE #$number: $title
URL: https://github.com/$repo/issues/$number

DESCRIZIONE ORIGINALE:
$body

ISTRUZIONI (segui in ordine, non saltare fasi):

1. Setup repo locale:
   mkdir -p $WORK_DIR && cd $WORK_DIR
   [ -d $repo_short ] && (cd $repo_short && git fetch && git pull) \\
     || gh repo clone $repo $repo_short
   cd $repo_short
   $([ "$is_rework" = "true" ] \
     && echo "git checkout feature/issue-$number 2>/dev/null || git checkout -b feature/issue-$number" \
     || echo "git checkout -b feature/issue-$number 2>/dev/null || git checkout feature/issue-$number")

2. Segui ESATTAMENTE la skill issue-resolver (fasi 1-6):
   - Fase 1: Research codebase $([ "$is_rework" = "true" ] && echo "(focalizzati sulle aree segnalate nel feedback)" || echo "")
   - Fase 2: Plan $([ "$is_rework" = "true" ] && echo "(piano di fix basato sul feedback)" || echo "")
   - Fase 3: Implementazione iterativa (implement → test → fix, max 5 iter/suite)
   - Fase 4: Verifica finale
   - Fase 5: Aggiorna PROJECT.md (version bump, backlog, timestamp)
   - Fase 6: Commit convenzionale (NO git push manuale)

3. Push, aggiorna label e sposta card:
   git push origin feature/issue-$number
  gh issue edit "$number" --repo "$repo" --add-label "$LABEL_PROCESSING" 2>/dev/null \
    && log "Issue #$number: label → in-progress" \
    || warn "Impossibile aggiornare label per #$number"
