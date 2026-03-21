# Skill: issue-deploy-test

**Trigger:** Davide autorizza il deploy in test (dopo PR in Test)  
**Agente:** Ciccio  
**Versione:** 2.2.0

---

## Obiettivo

Deployare il branch della issue sull'ambiente test e notificare Davide con il link per testare.

Il deploy test segue **due modalità** in base al tipo di progetto:

| Tipo progetto | Modalità deploy |
|---------------|----------------|
| Web (Next.js, React, Vite) | **CI pipeline** — GitHub Actions builda e deploya via rsync sul VPS |
| Flutter APK | **Diretto** — Ciccio deploya l'APK dal branch |

---

## Step 0 — Pre-deploy check (obbligatorio — Claudio)

Prima di autorizzare il deploy test, Claudio verifica che l'infrastruttura sia pronta.

```bash
REPO="<repo>"

echo "=== CI pipeline ==="
gh api repos/ecologicaleaving/$REPO/contents/.github/workflows/deploy.yml 2>/dev/null \
  | jq -r '.content' | base64 -d | grep -q "rsync\|ssh" && echo "✅ presente" || echo "❌ assente"

echo "=== Secrets configurati ==="
gh secret list --repo ecologicaleaving/$REPO

echo "=== Sottodominio test ==="
curl -s -o /dev/null -w "HTTP %{http_code}" "https://test-$REPO.8020solutions.org"
```

**Controlla anche se la issue tocca il DB:**
- Ci sono migrazioni SQL o modifiche schema? → Verifica che siano incluse nel branch
- La issue menziona nuove tabelle, colonne, RLS, funzioni Supabase? → Segnalalo a Ciccio prima del deploy

**Se tutto ok → procedi. Se qualcosa manca → notifica Davide:**
```
⚠️ [Issue #N/<repo>] Pre-deploy check fallito
📋 Problemi rilevati:
  - <secrets mancanti / sottodominio down / migrazioni mancanti>
❓ Vuoi procedere comunque o risolviamo prima?
```

---

## Procedura — Progetti Web con CI pipeline

### Step 1 — Verifica CI pipeline attiva

```bash
gh api repos/ecologicaleaving/<repo>/contents/.github/workflows/deploy.yml 2>/dev/null \
  | jq -r '.content' | base64 -d | grep -q "rsync\|ssh" && echo "CI pipeline presente" || echo "CI pipeline assente"
```

Se la pipeline è assente → passa alla procedura **Deploy manuale** (sezione sotto).

### Step 2 — Verifica GitHub Secrets configurati

I secrets necessari per la CI variano per progetto. Controlla quali mancano:

```bash
# Lista secrets configurati nel repo
gh secret list --repo ecologicaleaving/<repo>
```

**Secrets infra VPS (comuni a tutti i web project):**
- `VPS_SSH_KEY` — chiave SSH privata per deploy
- `VPS_HOST` — IP VPS (46.225.60.101)
- `VPS_USER` — utente SSH (root)
- `CLOUDFLARE_ZONE_ID` — ID zona Cloudflare
- `CLOUDFLARE_API_TOKEN` — token API Cloudflare

**Secrets specifici per progetto** (recupera da issue o chiedi a Davide):
- Variabili `NEXT_PUBLIC_*`, chiavi API, URL Supabase, ecc.

Se mancano secrets infra VPS → aggiungili con i valori standard (vedi MEMORY.md).
Se mancano secrets specifici progetto → chiedi a Davide prima di procedere:
```
⚠️ [Issue #N] Deploy test bloccato — secrets mancanti
📋 Mancano: NEXT_PUBLIC_SUPABASE_ANON_KEY, NEXT_PUBLIC_SITE_URL
❓ Puoi fornirli per procedere?
```

### Step 3 — Aggiungi secrets mancanti

```bash
# Aggiungi secret VPS (esempio)
gh secret set VPS_HOST --repo ecologicaleaving/<repo> --body "46.225.60.101"
gh secret set VPS_USER --repo ecologicaleaving/<repo> --body "root"
gh secret set VPS_SSH_KEY --repo ecologicaleaving/<repo> < ~/.ssh/id_rsa

# Secret specifico progetto
gh secret set NEXT_PUBLIC_SUPABASE_ANON_KEY --repo ecologicaleaving/<repo> --body "<valore>"
```

### Step 4 — Triggera la CI sul branch

Se la CI non è partita automaticamente dopo il push del branch:

```bash
# Verifica ultimo run CI
gh run list --repo ecologicaleaving/<repo> --branch feature/issue-N-slug --limit 3

# Se nessun run → triggera manualmente
gh workflow run deploy.yml --repo ecologicaleaving/<repo> --ref feature/issue-N-slug
```

### Step 5 — Monitora il run CI

```bash
# Attendi completamento
gh run watch --repo ecologicaleaving/<repo>

# Oppure controlla stato
gh run list --repo ecologicaleaving/<repo> --branch feature/issue-N-slug --limit 1 \
  --json status,conclusion,url | jq '.[0]'
```

**Se CI fallisce:**
1. Leggi il log: `gh run view <run-id> --repo ecologicaleaving/<repo> --log-failed`
2. Se errore secrets → torna a Step 3
3. Se errore build → notifica Claudio con dettaglio errore
4. Non procedere finché CI non è verde

### Step 6 — Verifica deploy avvenuto

La CI deploya automaticamente su `test-<repo>.8020solutions.org/b/<branch-slug>`.

```bash
# Verifica HTTP
SLUG=$(echo "feature/issue-N-slug" | sed 's|/|-|g' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
curl -s -o /dev/null -w "%{http_code}" "https://test-<repo>.8020solutions.org/b/${SLUG}/"
```

### Step 7 — Aggiorna label e Kanban

```bash
# Label deployed-test (crea se non esiste)
gh label create "deployed-test" --repo ecologicaleaving/<repo> --color "#0075ca" 2>/dev/null || true
gh issue edit <N> --repo ecologicaleaving/<repo> --add-label "deployed-test"

# Kanban → Test (singleSelectOptionId: "9c813e6b")
ITEM_ID=$(gh project item-list 2 --owner ecologicaleaving --format json \
  | jq -r '.items[] | select(.content.number == <N> and (.content.repository.name == "<repo>")) | .id')

gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "9c813e6b" }
  }) { projectV2Item { id } }
}'
```

### Step 8 — Notifica Davide

```
🧪 [Issue #N] Deploy test ok
🔗 https://test-<repo>.8020solutions.org/b/<branch-slug>/
📋 Cosa testare:
  - <AC 1 dalla issue>
  - <AC 2 dalla issue>
  - <AC 3 dalla issue>
```

---

## Procedura — Deploy manuale (no CI pipeline)

Per progetti senza `deploy.yml` (es. Flutter APK, static sites semplici):

### Step 1 — Pull branch e build

```bash
cd /root/<repo>-deploy  # o clona se non esiste
git fetch origin
git checkout feature/issue-N-slug
git pull origin feature/issue-N-slug

# Node/React/Next.js:
npm ci && npm run build
# → output in out/ o build/

# Flutter web:
flutter build web --release
# → output in build/web/
```

### Step 2 — Deploy su test

```bash
# Web app
rsync -avz --delete out/ /var/www/test-<repo>/
nginx -s reload

# APK Flutter
cp build/app/outputs/flutter-apk/app-release.apk /var/www/test-<repo>/download/<repo>.apk
```

### Step 3 — Aggiorna label e notifica Davide

Stesso Step 7 e Step 8 della procedura CI.

---

## Note

- Il deploy test **non modifica mai la produzione**
- Ambiente test può essere sovrascritto da deploy successivi sullo stesso branch
- I secrets infra VPS (`VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`, `CLOUDFLARE_*`) sono identici per tutti i repo — Ciccio li ha disponibili
- Secrets specifici progetto (Supabase, API keys) vanno chiesti a Davide se non disponibili
