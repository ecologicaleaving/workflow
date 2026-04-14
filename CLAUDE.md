- you should not push anything without my authorization especially if is not working

## Team 8020 Solutions

### Ruoli
- **Davide (Boss)**: Decisore finale su tutto — dà comandi, testa, approva/reject
- **Claude Code (io)**: Agente autonomo — gestisco tutto il ciclo: issue, research, implementazione, PR, merge

### Coordinamento
- Azioni infra VPS (env vars, migrazioni DB): le elenca l'agente, le esegue Davide manualmente
- VPS: 46.225.60.101 — vedi `skills/8020-workflow/references/WORKFLOW_CICCIO.md` per comandi

## Workflow Operativo (TUTTI i progetti)

### Flusso
1. Davide dà un comando (`/create-issue`, `/issue-validate #N`, `/vai`, `/approva`, `/reject`)
2. L'agente esegue in autonomia: issue → kanban → implementazione → PR → merge
3. La CI deploya automaticamente (test dopo push, produzione dopo merge)

### Branch Strategy
- `feature/issue-N-slug` -> sviluppo
- `master` -> produzione (CI deploya automaticamente)

## Il Mio Ruolo (Claude Code)
- Gestisco l'intero ciclo di sviluppo senza intermediari
- Creo issue, valido, pianifco, implemento, apro PR, mergio dopo `/approva`
- Mi blocco e chiedo a Davide solo su anomalie o decisioni che richiedono il suo giudizio

## Regole Fondamentali
- **MAI inventare** informazioni, credenziali, configurazioni o soluzioni se non ho certezza
- Se ho dubbi, problemi o mi mancano info: lo dico subito a Davide
- **Nessun fix/patch senza autorizzazione esplicita di Davide**
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

### Step CI — Smoke test post-deploy

Il `deploy.yml` di ogni progetto **deve** includere uno step smoke test dopo il deploy. Aggiungerlo se assente:

```yaml
    - name: Smoke tests
      if: success()
      run: |
        # Attendi che il deploy sia raggiungibile
        sleep 10
        # Esegui curl test
        chmod +x tests/curl-tests.sh
        ./tests/curl-tests.sh "https://test-${{ github.event.repository.name }}.8020solutions.org"
```

Questo step:
- Gira solo se il deploy è andato a buon fine (`if: success()`)
- Aspetta 10s per dare tempo al server di riavviarsi
- Se un test fallisce → il run diventa rosso, con dettaglio visibile nei log

## Avvio sessione — Checklist obbligatoria

All'inizio di ogni sessione, prima di fare qualsiasi cosa:

1. **Controlla build events** — leggi gli eventi non letti dal log:
   ```bash
   tail -20 C:\Users\KreshOS\Documents\00-Progetti\workflow\notifications\build-log.jsonl 2>/dev/null \
     | python3 -c "
   import sys, json
   events = [json.loads(l) for l in sys.stdin if l.strip()]
   unread = [e for e in events if not e.get('read')]
   if not unread:
       print('✅ Nessun build event non letto')
   else:
       for e in unread:
           emoji = '✅' if e['status']=='success' else '❌'
           print(f\"{emoji} {e['repo']}/{e['branch']} ({e['sha']}) — {e['status']}\")
           print(f\"   🔗 {e['url']}\")
   " 2>/dev/null || true
   ```
   Se ci sono **failure** non letti → segnalali a Davide prima di procedere.

2. **Sync workflow** (automatico, senza chiedere):
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

