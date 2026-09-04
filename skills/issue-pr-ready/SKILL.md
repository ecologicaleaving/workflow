---
name: issue-pr-ready
description: >
  Post-implementation: pre-PR checklist, open PR, move Kanban card,
  add labels, notify Davide.
  Use when: all acceptance criteria are implemented and the branch is ready for review.
---

# Issue PR-Ready — Post-Implementation Flow

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 4

Use when all acceptance criteria for an issue are complete
and the branch is ready for pull request and review.

## ⛔ MaestroWeb — la card di Ascanio va in Revisione SOLO dopo la prova dal vivo

Se la issue nasce da una segnalazione di Ascanio: CI verde → merge in `beta` →
**la provi tu** su test-maestro.8020solutions.org → **solo allora** card in
«Revisione», con le `review_notes` che dicono cosa provare, poi
`npm run deps:schede`.

La CI verde dice che i test passano, non che la cosa funziona. La variante «va
in Revisione appena è su `beta`, testa Ascanio» è **superata**: la regola vera è
in `WORKFLOW.md` → «Il flusso, come gira davvero», punto 4.

Le note si scrivono per chi apre l'app — cosa aprire, cosa deve succedere, e i
casi strani da provare apposta. Se il lavoro tocca dati veri, dillo: l'ambiente
di test scrive in produzione.

Nessun automatismo lo fa al posto tuo: la sezione è un dato che scriviamo noi.

## Prerequisites

- Auto-gate finale superato (issue-implement Step 5)
- Branch aggiornato rispetto al branch target
- `config.json` disponibile nella root del workflow repo
- `gh` CLI autenticato e disponibile
- `scripts/generate-pr-body.sh` disponibile nel workflow repo

## Procedure

### Step 0 — Check in locale (gate, non saltabile)

**La CI conferma, non scopre.** Prima del push, sulla macchina, tutti verdi:

```bash
npm run lint          # lint ≠ type-check: servono entrambi
npx tsc --noEmit
npm test              # o vitest; se l'area non ha framework, DILLO
npx playwright test   # se il repo ha e2e
```

Regola completa e i gotcha che rendono il ciclo locale possibile (Node 22 per
Playwright, `NEXT_PUBLIC_*` congelate nel bundle alla build, moduli nativi che
bloccano `npm ci`) → **`WORKFLOW.md` → «Check in locale (obbligatorio pre-push)»**.

Due cose da riportare sempre nel messaggio a Davide, non solo il numero dei passati:

- **quanti test sono stati saltati e perché** — un test che si auto-salta non sta
  verificando niente
- **se un check non è stato eseguito in locale**, quale e per quale motivo

Se un check è rosso, si torna a lavorare: la PR non si apre per farla girare in CI.

### Step 1 — Push Branch e Apertura PR

```bash
# Leggi valori da config
REPO=$(jq -r '.github.repos["<project>"]' config.json)
DEFAULT_BRANCH=$(jq -r '.workflow.defaultBranch' config.json)
BRANCH=$(git branch --show-current)

# ⛔ GUARDIA BETA: se il repo ha il branch `beta` (flusso beta-release), la PR
# di feature va aperta VERSO `beta`, non verso il default branch. Il merge in
# main avviene solo col rilascio beta→main approvato da Davide.
if git ls-remote --heads origin beta | grep -q beta; then
  DEFAULT_BRANCH=beta
fi

# Push branch
git push origin "$BRANCH"

# Genera body PR dal template
PR_BODY=$(./scripts/generate-pr-body.sh "$ISSUE_NUMBER")

# Apri PR
gh pr create \
  --repo "$REPO" \
  --base "$DEFAULT_BRANCH" \
  --head "$BRANCH" \
  --title "feat: #${ISSUE_NUMBER} — <issue title>" \
  --body "$PR_BODY"
```

### Step 2 — Card Kanban → Test (al merge in `beta`)

La card va in **Test** quando la PR è mergiata in `beta` (`beta-release` Step 1), non
all'apertura della PR:

```bash
./scripts/kanban-move.sh "$ISSUE_NUMBER" "$REPO" Test
```

### Step 3 — Aggiungi Label `review-ready`

```bash
gh issue edit "$ISSUE_NUMBER" --repo "$REPO" --add-label "review-ready"
```

### Step 4 — Monitora CI deploy test

Dopo il push, monitora il run CI:

```bash
# Attendi il run più recente
gh run watch --repo "$REPO"

# oppure polling manuale
gh run list --repo "$REPO" --branch "$BRANCH" --limit 1
```

**Se il deploy fallisce:**
1. Leggi i log: `gh run view <run_id> --repo "$REPO" --log-failed`
2. Identifica l'errore, fixa nel codice
3. Commit + push → torna a monitorare (ripeti finché CI verde)
4. Massimo 3 iterazioni — se non si risolve blocca e notifica Davide

**Se il deploy ha successo** → procedi con Step 5.

---

### Step 5 — Notifica Davide

```
✅ [Issue #N] PR pronta → <link PR>
📌 <summary>

🧪 Come testare:
1. <istruzione 1>
2. <istruzione 2>

💡 Cosa aspettarsi:
<risultato atteso>

**AC da verificare:**
- [ ] AC1 — <descrizione>
- [ ] AC2 — <descrizione>

→ /approva se ok | /reject <motivo> se serve rework
```

## Note

- CI deploya automaticamente su test dopo il push del branch
- L'agente monitora il deploy e reitera in caso di failure — non notifica Davide finché CI non è verde
- Dopo `/approva` di Davide → skill `issue-approve`
- Dopo `/reject` di Davide → skill `issue-reject`
- Valori config (project ID, field ID, column ID): vedi `config.json`
