---
name: approva
description: >
  Procedura completa di /approva di Davide — label qa-approved, promozione
  selettiva beta→main via approva-promote.ts (o la procedura manuale a
  gruppi quando serve), CI, merge, deploy, smoke test, chiusura issue.
  Assorbe la guardia beta: un /approva su una feature significa beta, non
  produzione, finché Davide non approva esplicitamente la beta.
  Trigger: Davide scrive /approva.
version: 2.0.0
---

# Skill: approva

**Trigger:** Davide scrive `/approva`

> Riferimento flusso: `FLUSSO.md` — punto 6

---

## ⛔ Step 0 — Guardia beta (obbligatoria, sempre per prima)

Un `/approva` su una **feature** significa che è approvata per andare in
`beta`, **non** in produzione. La produzione si tocca solo quando Davide
approva **la beta stessa**, con contesto esplicito: "approva beta", "porta
in prod", oppure `/approva` dato **dopo** l'avviso "✅ Beta pronta da
testare" della skill `beta-release`.

**In dubbio su cosa Davide stia approvando → chiedi prima di mergiare.** Un
merge in `beta` è reversibile a costo quasi zero; un deploy prod sbagliato
no.

> Incidente di riferimento: 21/07/2026, MaestroWeb #1426/PR #1429 —
> `/approva` su una feature interpretato come ok prod → merge in `main` +
> deploy da cancellare + revert. Da allora questo step è il primo, sempre.

Se il repo **non** ha branch `beta` → flusso diretto, salta al resto di
questa skill trattando `beta` come "la PR aperta" e `main` come target
diretto. Se **ha** `beta` (es. MaestroWeb) → procedi con gli step sotto,
che presuppongono `beta` già pronta (skill `beta-release` completata).

---

## Step 1 — Label `qa-approved`

Metti la label sulle issue che Ascanio ha approvato dal pannello (card
`revisione` → `backlog`, vedi `FLUSSO.md` punto 5) e su eventuali fix
tecnici che Davide include esplicitamente in questo giro:

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> --add-label qa-approved
```

Risali dalla card alla issue via `qa_task_issues`, o dal titolo se manca il
collegamento in tabella.

---

## Step 2 — Promozione selettiva (se il repo ha `scripts/approva-promote.ts`)

Verifica prima: `ls scripts/approva-promote.ts` (oggi solo MaestroWeb).

```bash
# 1. Sempre un dry-run PRIMA del run reale
npx tsx scripts/approva-promote.ts --dry-run
```

Leggi il report: quali issue **PROMOSSE**, quali **ESCLUSE** (non
approvate), quali **NON RISOLVIBILI** (nessuna PR/issue collegata — di
solito un commit senza `Closes #N`).

- Se ci sono commit **NON RISOLVIBILI**: lo script si rifiuta di procedere
  (fail-safe intenzionale). Serve intervento umano — di solito basta
  collegare il commit a una issue: crea una issue leggera di tracciamento,
  aggiungi `Closes #N` al body della PR originale, applica `qa-approved`
  alla issue di tracciamento (il lavoro è già mergiato e verificato, non
  serve rivalidare gli AC), poi ripeti dal dry-run. **Non bypassare il
  fail-safe in altro modo.**
- Se il dry-run esclude gruppi «per conflitto»: **quasi sempre** è
  `package.json`/`PROJECT.md` (versione/changelog), non un conflitto reale
  di logica — verificalo prima di trattarlo come blocco serio.

```bash
# 2. Solo se il dry-run è pulito
npx tsx scripts/approva-promote.ts
# Apre una PR verso main con SOLO i commit delle issue approvate.

# 3. CI verde, poi merge — SEMPRE --merge, MAI --squash
#    (uno squash-merge riscrive gli hash: al giro successivo git cherry
#    non li riconosce più come "già in main" e li ripropone, duplicando
#    la history e rompendo l'idempotenza patch-id dello script)
gh pr merge <PR> --repo ecologicaleaving/<repo> --merge
```

---

## Step 2b — Procedura manuale (se lo script non c'è, o va rifatta a mano)

1. Worktree isolato da `origin/main` aggiornato.
2. `git log origin/main..origin/beta` per l'elenco cronologico dei commit
   da promuovere.
3. Cherry-pick **in ordine cronologico**, un'issue alla volta.
4. Conflitto solo su `PROJECT.md` / `package.json` / `package-lock.json` →
   `git checkout --theirs <file>` e prosegui.
5. Conflitto su **qualunque altro file** → l'intera issue esce dal giro con
   **tutti** i suoi commit (non solo quello in conflitto) e si riparte da
   dove si era arrivati — è un'esclusione a gruppi, non un file alla volta.
   Itera finché non resta nulla di irrisolvibile.
6. Alla fine, `package.json` + `package-lock.json` presi **interi** da
   `beta` (non merge riga per riga).
7. PR verso `main` **a mano**, con tutti i `Closes #N` delle issue
   effettivamente incluse nel body.
8. I conflitti veri che restano dopo aver isolato tutto il resto sono
   filoni intrecciati — si promuovono **in blocco**, non si spezzano più a
   fondo: un'unità di lavoro va approvata come unità (vedi CLAUDE.md di
   MaestroWeb → «una scheda = un'epica»).

---

## Step 3 — CI e merge

```bash
gh run watch --repo ecologicaleaving/<repo>
```

Se il deploy fallisce: leggi i log (`gh run view <run_id> --log-failed`),
fixa, ripush, ri-monitora. Massimo 3 iterazioni — oltre, notifica subito
Davide con il dettaglio dell'errore invece di continuare a tentare.

---

## Step 4 — Smoke test post-deploy

```bash
chmod +x tests/curl-tests.sh
./tests/curl-tests.sh
```

Se il repo non ha ancora `tests/curl-tests.sh`, crealo dal template
`templates/curl-tests.sh` — vedi skill `dev-loop` per quando aggiungerci
nuovi test.

---

## Step 5 — Chiudi le issue, label, Kanban

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "review-ready,deployed-test,needs-fix" \
  --add-label "deployed-prod"
gh issue close <N> --repo ecologicaleaving/<repo>
```

Sposta la card Kanban GitHub → **Done** (`98236657`, vedi `FLUSSO.md` punto
2 per l'ID di project/field).

---

## Step 6 — Conferma a Davide

```
✅ Live in produzione — #N1, #N2, …
📌 PR mergiata, smoke test verdi, issue chiuse, card → Done
```

---

## Step 7 — Azioni infra (solo se necessario)

Se servono env vars, migrazioni DB, riavvii servizi: **le elenca Claudio,
le esegue Davide manualmente** (regola del team, non delega via SSH senza
conferma). Se il flusso di questo progetto prevede l'esecuzione diretta via
SSH, seguila solo con autorizzazione esplicita già data per questo tipo di
azione.

---

## Note

- Mai eseguire nessuno step senza `/approva` esplicito di Davide.
- Un cron nuovo si schedula con il JWT dal Vault, mai con chiavi in chiaro.
  Una migration che ri-schedula un cron cambia l'header dello schedule, non
  decide da sola cosa gira.
