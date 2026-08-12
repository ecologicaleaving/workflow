# Skill: issue-approve

**Trigger:** Davide scrive `/approva`
**Agente:** Claude Code
**Versione:** 3.2.0

> Riferimento flusso: vedi `WORKFLOW.md` — Fase 5a

---

## Obiettivo

Mergiare la PR, chiudere la issue, notificare Davide. Gestire eventuali azioni infra necessarie.

---

## Procedura

### ⛔ Step 0 — GUARDIA BETA: determina il branch target (OBBLIGATORIO)

Prima di qualunque merge, verifica se il repo usa il **flusso beta**:

```bash
git ls-remote --heads origin beta
```

**Se il branch `beta` ESISTE** (es. maestroweb):
- `/approva` su una **feature** = la feature è approvata per l'**integrazione in `beta`**, NON per la produzione.
  → Segui la skill `beta-release` (Step 1): merge/cherry-pick della feature in `beta`,
  **issue resta APERTA**, card → Test. STOP: NON toccare `main`.
- Il merge `beta`→`main` (produzione) avviene **SOLO** quando Davide approva la **beta** con
  contesto esplicito: "approva beta", "porta in prod", oppure `/approva` dato **dopo** l'avviso
  "✅ Beta pronta da testare". Solo allora prosegui con gli step sotto (su `beta`→`main`).
- **In dubbio su cosa Davide stia approvando → CHIEDI prima di mergiare.** Un merge in `beta` è
  reversibile a costo zero; un deploy prod sbagliato no.

**Se il branch `beta` NON esiste** → flusso classico: prosegui con Step 1.

> Incidente di riferimento: 21/07/2026, maestroweb #1426/PR #1429 — `/approva` su feature
> interpretato come ok prod → merge in main + deploy da cancellare + revert. Mai più.

> **Aggiornamento 24/07/2026**: quando Davide dà `/approva` per il merge `beta`→`main` (prod),
> se il repo ha `scripts/approva-promote.ts` (oggi solo maestroweb), il merge NON è più "prendi
> tutto `beta`" — usa lo script di promozione selettiva, vedi skill `beta-release` Step 5 per
> la procedura completa (dry-run obbligatorio prima del run reale, `--merge` mai `--squash`).
> Questo perché con merge-diretto-in-beta il branch contiene sempre issue approvate e non
> approvate mescolate.

### ⛔ Step 0b — Se la revisione è avvenuta su un'EPICA: propaga `qa-approved` alle figlie

Quando più issue dello stesso filone vengono revisionate su **una scheda riassuntiva** (epica) invece
che una per una, l'approvazione di Ascanio arriva **solo sull'epica**: la label `qa-approved` viene
applicata lì dall'automatismo di `/qa`, e le figlie restano senza.

`scripts/approva-promote.ts` cerca `qa-approved` sulle issue **collegate ai commit** — e un'epica
non ha commit propri. Risultato: **un lotto regolarmente approvato non viene promosso, e il report
dice «Nessuna issue qa-approved» senza che nulla sia andato storto.** Nessun errore, nessun avviso:
solo un run che non promuove niente.

Prima di lanciare la promozione, quindi:

```bash
# 1. l'epica è qa-approved?
gh issue view <EPICA> --repo ecologicaleaving/<repo> --json labels -q '[.labels[].name]'

# 2. propaga alle figlie elencate nell'epica
for n in <FIGLIA_1> <FIGLIA_2> ...; do
  gh issue edit $n --repo ecologicaleaving/<repo> --add-label qa-approved
done
```

**Su ogni figlia lascia un commento che dice dove l'approvazione è avvenuta davvero** (epica, data,
chi). La label significa letteralmente «criteri approvati da Ascanio su /qa»: senza la nota, fra un
mese la storia dirà che ogni scheda è stata revisionata singolarmente — cosa mai accaduta.

Non propagare mai `qa-approved` a una figlia che l'epica **non** elenca: la promozione è per gruppo
di commit, e una figlia in più porta in produzione codice che nessuno ha approvato.

> Origine: 12/08/2026, maestroweb — epica #1680 con figlie #1676/#1677/#1678/#1679/#1681. Ascanio
> approva tutti gli AC sull'epica, la label arriva lì, e il dry-run di promozione risponde «niente
> da promuovere». Il buco è **strutturale**, non un errore di esecuzione: si ripresenta a ogni
> lotto revisionato su epica finché lo script non saprà risolvere epica→figlie da solo.

### Step 1 — Merge PR

```bash
gh pr merge <PR_N> --repo ecologicaleaving/<repo> --merge --delete-branch
```

La CI deploya automaticamente in produzione.

### Step 1b — Monitora CI deploy produzione

```bash
gh run watch --repo ecologicaleaving/<repo>
```

**Se il deploy fallisce:**
1. Leggi i log: `gh run view <run_id> --repo ecologicaleaving/<repo> --log-failed`
2. Identifica l'errore e fixa (hotfix direttamente su master o nuovo branch)
3. Push → monitora nuovamente
4. Massimo 3 iterazioni — se non si risolve notifica subito Davide con dettaglio errore

**Se il deploy ha successo** → procedi con Step 2.

### Step 2 — Aggiorna label e chiudi issue

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test,needs-fix" \
  --add-label "deployed-prod"
gh issue close <N> --repo ecologicaleaving/<repo>
```

### Step 3 — Sposta card → Done

```bash
./scripts/kanban-move.sh <N> <repo> Done
```

### Step 4 — Conferma a Davide

```
✅ [Issue #N] Live in produzione
📌 PR mergiata, issue chiusa, card → Done
```

### Step 5 — Azioni infra (solo se necessario)

Se servono env vars, migrazioni DB, riavvii servizi → L'agente le esegue direttamente via SSH:

```bash
# Env var
ssh root@46.225.60.101 "cd /opt/<repo> && echo 'VAR=valore' >> .env && docker compose restart <service>"

# Migrazione DB
ssh root@46.225.60.101 "cd /opt/<repo> && docker compose exec app <migration-command>"

# Riavvio
ssh root@46.225.60.101 "cd /opt/<repo> && docker compose pull && docker compose up -d"
```

Dopo ogni azione infra, conferma a Davide:
```
⚙️ Azioni infra completate:
- ✅ <azione 1>
- ✅ <azione 2>
```

Se non servono azioni infra → skip questo step.

### Step 6 — Weekly tracking

Aggiungi riga a `memory/weekly/current.md`:
```
| YYYY-MM-DD | PR | <repo> | #N | <titolo> | ✅ merged |
```

---

## Note

- Mai eseguire senza `/approva` esplicito di Davide
- Se la issue ha avuto reject precedenti, le label `needs-fix` vengono rimosse

## Changelog
- **v3.2.0** (2026-07-24): Nota sul nuovo meccanismo di promozione selettiva `beta`→`main`
  (`scripts/approva-promote.ts`, vedi skill `beta-release` Step 5) — il merge del branch `beta`
  intero non è più sicuro quando esiste questo script.
