#!/bin/bash
# sync-build-log.sh — Sincronizza il build log dal repo remoto
# Uso: ./scripts/sync-build-log.sh

set -euo pipefail

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$WORKFLOW_DIR/notifications/build-log.jsonl"

# Pull aggiornamenti
cd "$WORKFLOW_DIR"
git pull --quiet origin master 2>/dev/null || true

# Mostra eventi non letti
if [ ! -f "$LOG_FILE" ]; then
  echo "✅ Nessun build event registrato"
  exit 0
fi

python3 - <<'EOF'
import sys, json, os

log_file = os.environ.get('LOG_FILE', '')
if not log_file:
    import pathlib
    log_file = str(pathlib.Path(__file__).parent.parent / 'notifications' / 'build-log.jsonl')

with open(log_file) as f:
    events = [json.loads(l) for l in f if l.strip()]

unread = [e for e in events if not e.get('read')]

if not unread:
    print("✅ Nessun build event non letto")
    sys.exit(0)

print(f"📬 {len(unread)} build event non letti:\n")
for e in unread:
    emoji = '✅' if e['status'] == 'success' else '❌'
    print(f"  {emoji} {e['repo']}/{e['branch']} ({e.get('sha','?')}) — {e['status']}")
    print(f"     🕐 {e['ts']}")
    print(f"     🔗 {e['url']}")
    print()
EOF
