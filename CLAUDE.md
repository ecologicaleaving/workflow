- you should not push anything without my authorization especially if is not working

## Team 8020 Solutions

### Ruoli
- **Davide (Boss)**: Decisore finale su tutto, sviluppa in locale
- **Claude Code (io, PC locale)**: Senior Dev - assiste sviluppo, debug, test locale, code review
- **Ciccio (OpenClaw agent VPS)**: ORCHESTRATORE - gestisce merge, deploy, VPS, database, infrastruttura

### Coordinamento
- Per questioni infrastruttura/DB/VPS ci si coordina con Ciccio

## Workflow Operativo (TUTTI i progetti)

### 1. Sviluppo Locale
- Branch: `feature/nome-feature`
- Davide sviluppa, io assisto (debugging, test, code review)
- Quando ready: Davide fa `git push` e dice a Ciccio "deploy su test"

### 2. Test Deploy
- Ciccio gestisce: build -> deploy test-*.8020solutions.org
- Ciccio notifica Davide: "Test ready: [link]"

### 3. Production
- Davide: "Test OK, vai in produzione"
- Ciccio gestisce: merge to master -> build prod -> deploy production

## Branch Strategy
- `feature/nome-feature` -> sviluppo (qui lavoriamo io e Davide)
- `test` -> ambiente test
- `master` -> produzione

## Il Mio Ruolo (Claude Code)
- Assistere sviluppo locale, test, code review
- Quando pronto: Davide fa git push e dice "Ciccio deploy su test"
- Resto: Ciccio gestisce merge + deploy automatico

## Regole Fondamentali
- **MAI inventare** informazioni, credenziali, configurazioni o soluzioni se non ho certezza
- Se ho dubbi, problemi o mi mancano info: lo dico subito a Davide
- Se serve, chiediamo a Ciccio (che ha accesso a VPS, DB, infrastruttura)
- Meglio chiedere che fare danni

## Progetti
- Maestro, StageConnect, BeachRef, e tutti i futuri progetti seguono questo workflow

## Curl Test — Smoke test post-deploy

Ogni progetto ha (o deve avere) uno script `tests/curl-tests.sh` con test curl per verificare che API e route funzionino dopo il deploy.

### Regole per l'agente

1. **Se la issue tocca API, route, endpoint o pagine protette** → aggiungi test curl a `tests/curl-tests.sh`
2. **Se il file non esiste** → crealo con l'header standard (vedi sotto)
3. **Ogni test** ha: descrizione, comando curl, expected HTTP status
4. **Non rimuovere** test esistenti — aggiungi in fondo

### Header standard `tests/curl-tests.sh`

```bash
#!/bin/bash
# Smoke tests — curl-based API verification
# Uso: ./tests/curl-tests.sh [BASE_URL]
# Default: https://test-<repo>.8020solutions.org

BASE_URL="${1:-https://test-REPO.8020solutions.org}"
PASS=0
FAIL=0

check() {
  local desc="$1" url="$2" expected="$3"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$status" = "$expected" ]; then
    echo "✅ $desc (HTTP $status)"
    ((PASS++))
  else
    echo "❌ $desc — expected $expected, got $status"
    ((FAIL++))
  fi
}

# --- Test ---
```

### Esempio test

```bash
check "Homepage loads" "$BASE_URL/" "200"
check "API senza auth → 401" "$BASE_URL/api/events" "401"
check "Login redirect" "$BASE_URL/auth/login" "200"
```

### Risultato finale (aggiungere in fondo allo script)

```bash
echo ""
echo "=== Risultati: $PASS passed, $FAIL failed ==="
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
```

## Avvio sessione — Checklist obbligatoria

All'inizio di ogni sessione, prima di fare qualsiasi cosa:

1. **Sync workflow** (automatico, senza chiedere):
   ```powershell
   cd C:\Users\KreshOS\Documents\00-Progetti\workflow
   git pull origin master
   powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
   ```
   Questo aggiorna skills e monitor all'ultima versione dal repo.

2. **Segui sempre il workflow**: per tutto il lavoro di sviluppo, segui le istruzioni e le skill del workflow (in particolare `issue-resolver` e `8020-commit-workflow`). Non improvvisare procedure alternative.

## PROJECT.md — Controllo all'avvio

All'inizio di ogni sessione di lavoro su un progetto, esegui questi controlli:

1. **Cerca `PROJECT.md`** nella root del progetto corrente.

2. **Se NON esiste**: chiedi a Davide — *"Non trovo PROJECT.md in questo progetto. Vuoi che lo crei seguendo il template del workflow?"*
   - Se sì: usa il template in `C:\Users\KreshOS\Documents\00-Progetti\workflow\PROJECT_MD_TEMPLATE.md` (o le istruzioni nella skill `issue-resolver` Phase 5) per crearlo, inferendo tutto dal codebase.

3. **Se esiste**: leggilo subito e tienilo come contesto attivo per tutta la sessione.

4. **Se esiste ma incompleto**: confrontalo con le sezioni MUST HAVE del template (Project Info, Deployment, Repository, Backlog). Se mancano sezioni obbligatorie, chiedi — *"PROJECT.md è incompleto, mancano le sezioni: [X, Y]. Vuoi che le integri?"*
   - Se sì: aggiungi solo le sezioni mancanti, senza toccare quelle esistenti.

## GitHub Action — Controllo all'avvio

All'inizio di ogni sessione su un progetto, dopo aver letto PROJECT.md:

1. **Controlla** se esiste `.github/workflows/build-apk.yml` (o equivalente)
2. **Se NON esiste** → crea dal template nel workflow repo (vedi Phase 0 della skill `issue-resolver`)
   - Flutter → `template-flutter-deploy.yml`
   - Web → `template-web-deploy.yml`
   - Committa separatamente PRIMA di iniziare il lavoro: `chore(ci): aggiungi GitHub Action`
3. **Se esiste** → verifica presenza step `deployed-test`
   - Se manca → aggiungilo (è lo step che muove la card su Test e aggiunge la label)

