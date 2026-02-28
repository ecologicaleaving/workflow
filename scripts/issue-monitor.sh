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
print(r.get('result', {}).get('sessionKey') or r.get('sessionKey', 'spawn-failed'))
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
  gh issue edit "$number" --repo "$repo" \
    --add-label    "$LABEL_PROCESSING" \
    --remove-label "$agent_label" 2>/dev/null \
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
   gh issue edit $number --repo $repo \\
     --add-label $LABEL_DONE \\
     --remove-label $LABEL_PROCESSING
   $board_cmd

4. Notifica Davide via Telegram (chat $TELEGRAM_CHAT):
   $([ "$is_rework" = "true" ] \
     && echo "\"🔧 Issue #$number ($title) — rework completato. Branch: feature/issue-$number | Repo: $repo\"" \
     || echo "\"✅ Issue #$number ($title) risolta. Branch: feature/issue-$number | Repo: $repo\"")

5. Rimuovi il lock: rm -f $lock_file

VINCOLI ASSOLUTI:
- NO: git merge / git reset / modifica master o main
- Se i test falliscono dopo 5 iterazioni: documenta, stoppa, notifica Davide
- Il lock file DEVE essere rimosso a completamento: $lock_file
TASK_EOF
)

  local session_label
  session_label="$([ "$is_rework" = "true" ] && echo "rework" || echo "issue")-${repo_short}-${number}"

  local session
  session=$(spawn_agent "$task" "$session_label")
  log "Issue #$number → subagente spawned (session: $session). Monitor libero."
}

# ---- Processa tutte le issue di un agente ----
process_agent_issues() {
  local trigger_label="$1" agent_name="$2" agent_identity="$3" is_rework="${4:-false}"

  log "--- Checking label: $trigger_label ---"

  local issues_json
  issues_json=$(gh search issues \
    --label "$trigger_label" \
    --owner "$GITHUB_ORG" \
    --state open \
    --json number,title,body,url,labels,repository \
    --limit 5 2>/dev/null) || { warn "gh search issues fallita per $trigger_label"; return; }

  local count
  count=$(echo "$issues_json" | \
    python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
  log "Trovate $count issue(s) con label '$trigger_label'"
  [ "$count" = "0" ] && return

  while IFS= read -r issue; do
    local number title body repo
    number=$(echo "$issue" | python3 -c "import sys,json; print(json.load(sys.stdin)['number'])")
    title=$(echo  "$issue" | python3 -c "import sys,json; print(json.load(sys.stdin)['title'])")
    body=$(echo   "$issue" | python3 -c "import sys,json; print(json.load(sys.stdin).get('body',''))")
    repo=$(echo   "$issue" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('repository', {}).get('nameWithOwner', '$GITHUB_ORG/unknown'))
")
    process_issue "$repo" "$number" "$title" "$body" \
      "$trigger_label" "$agent_name" "$agent_identity" "$is_rework"

  done < <(echo "$issues_json" | python3 -c "
import sys, json
for i in json.load(sys.stdin): print(json.dumps(i))
")
}

# ============================================================
# MAIN
# ============================================================

log "=== Issue Monitor v1.0 | Cycle Start | Agents: $AGENT_COUNT ==="

command -v gh      >/dev/null 2>&1 || { log "ERROR: gh CLI non trovato"; exit 1; }
command -v curl    >/dev/null 2>&1 || { log "ERROR: curl non trovato"; exit 1; }
command -v python3 >/dev/null 2>&1 || { log "ERROR: python3 non trovato"; exit 1; }

# Processa ogni agente configurato
for i in $(seq 1 "$AGENT_COUNT"); do
  trigger_label="${!( echo "AGENT_${i}_LABEL" ):-}"
  agent_name="${!( echo "AGENT_${i}_NAME" ):-Agent $i}"
  agent_identity="${!( echo "AGENT_${i}_IDENTITY" ):-Sei un agente developer di 8020 Solutions.}"

  # bash indirect expansion
  _lv="AGENT_${i}_LABEL";    trigger_label="${!_lv:-}"
  _nv="AGENT_${i}_NAME";     agent_name="${!_nv:-Agent $i}"
  _iv="AGENT_${i}_IDENTITY"; agent_identity="${!_iv:-Sei un agente developer di 8020 Solutions.}"

  [ -z "$trigger_label" ] && { warn "AGENT_${i}_LABEL non impostato, skip"; continue; }

  process_agent_issues "$trigger_label" "$agent_name" "$agent_identity" "false"
done

# Rework (needs-fix) — usa l'identity del primo agente configurato
_rv="AGENT_1_NAME";     _rework_name="${!_rv:-Agent}"
_ri="AGENT_1_IDENTITY"; _rework_identity="${!_ri:-}"
process_agent_issues "$REWORK_LABEL" "$_rework_name" "$_rework_identity" "true"

log "=== Cycle complete ==="
