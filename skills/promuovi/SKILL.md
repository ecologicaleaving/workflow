---
name: promuovi
description: >
  Procedura completa di /promuovi: porta in PRODUZIONE (main) cio che Ascanio ha
  approvato e che vive in beta — label qa-approved, promozione selettiva
  beta→main via approva-promote.ts (o la procedura manuale a gruppi quando
  serve), CI, merge, deploy, smoke test, chiusura issue.
  NON confondere con /approva, che porta una feature in beta e non tocca la
  produzione.
  Trigger: Davide scrive /promuovi.
version: 3.0.0
---

# Skill: promuovi

**Trigger:** Davide scrive `/promuovi`

> Riferimento flusso: `FLUSSO.md` — punto 6

---

## Le due parole, e perche sono due

Dal 06/09/2026, per decisione di Davide:

| Comando | Cosa approva | Dove va il codice |
|---|---|---|
| **`/approva`** | una feature, una PR | in **`beta`** — la produzione non si tocca |
| **`/promuovi`** | cio che e in beta ed e approvato da Ascanio | in **`main`**, deploy, produzione |

Prima era una parola sola per due cose, e la skill doveva indovinare quale.
Indovinare andava male: **21/07/2026, MaestroWeb #1426/PR #1429** — un `/approva`
su una feature letto come ok per la produzione, con merge in `main`, deploy da
cancellare e revert. Da quell'incidente nacque una «guardia beta» come primo
passo obbligatorio, cioe' un controllo che esisteva solo perche' la parola era
ambigua.

Con due parole distinte la guardia diventa piu' semplice, ma **non sparisce**:

- Se Davide scrive **`/approva`**, questa skill **non c'entra**: si porta la
  feature in `beta` (vedi `beta-release`) e ci si ferma li'.
- Se scrive **`/promuovi`**, si procede con gli step qui sotto.
- **Nel dubbio si chiede.** Un merge in `beta` si annulla quasi gratis, un deploy
  sbagliato in produzione no. Il costo di una domanda in piu' e' trenta secondi;
  quello di un deploy da revertare l'abbiamo gia' pagato.

**Nota sui nomi dei file:** lo script si chiama ancora `approva-promote.ts` e la
label ancora `qa-approved`. Non si rinominano: il primo e' referenziato da
documenti e comandi, la seconda vive su decine di issue gia' etichettate. La
terminologia nuova vale per **come parliamo**, non per come si chiamano i file.

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
