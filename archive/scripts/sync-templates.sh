#!/bin/bash
# sync-templates.sh — Propagazione LOCALE dei template ai progetti
# ============================================================
# Sostituisce il workflow Actions sync-templates.yml (rimosso): quello
# richiedeva un PAT cross-repo (secret GH_PAT) mai configurato e falliva
# in silenzio. Il sync ora si lancia a mano dal PC, dove gh è già
# autenticato con accesso a tutti i repo.
#
# USO (dal PC, con gh autenticato):
#   scripts/sync-templates.sh            # apre le PR
#   scripts/sync-templates.sh --dry-run  # mostra solo cosa farebbe
#
# Apre una PR su ogni repo target (mai commit diretto su main/master).
# Repo archiviati o non accessibili vengono saltati automaticamente.
#
# Mappatura template → target:
#   build-apk.yml → app Flutter attive
# (deploy-unified.yml NON è propagato: nessun progetto lo usa oggi —
#  resta come template disponibile, da propagare a mano se servirà.)
# ============================================================

set -euo pipefail
cd "$(dirname "$0")/.."

DRY=""
[ "${1:-}" = "--dry-run" ] && DRY="--dry-run"

# App Flutter attive. maestro è archiviato → escluso qui (e comunque
# safe-github.sh skippa in automatico ogni repo archiviato).
FLUTTER_REPOS="ecologicaleaving/finn,ecologicaleaving/StageConnect,ecologicaleaving/BeachRef-app,ecologicaleaving/GridConnect,ecologicaleaving/AutoDrum,ecologicaleaving/smartscore"

echo "🔄 Sync build-apk.yml → app Flutter"
scripts/safe-github.sh sync-template \
    --template templates/build-apk.yml \
    --repos "$FLUTTER_REPOS" $DRY

echo "✅ Sync template completato — controlla le PR aperte sui repo target"
