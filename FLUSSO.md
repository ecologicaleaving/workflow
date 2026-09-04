# FLUSSO — 80/20 Solutions Workflow v2

Unica fonte di verità del flusso. Deciso da Davide il 04/09/2026. Le skill
rimandano qui invece di ripetere le procedure: se una skill e questo file
sono in disaccordo, vince questo file.

## Ruoli

| Chi | Cosa fa |
|---|---|
| **Davide** | Decide, testa, approva (`/approva`) |
| **Ascanio** | Co-fondatore. Prova sul campo, approva dal suo pannello (`/qa`) |
| **Claudio** | Orchestratore — gira su **Fable 5** (alias `model: 'fable'`). Pianifica, verifica, coordina. Non implementa. |
| **developer** | Subagente **Sonnet 5** (alias `model: 'sonnet'`), in worktree isolato. Implementa. |
| **Gaia** | Business e governance — vive nel repo `ecologicaleaving`. Citata qui solo per completezza dei ruoli. |

## Branch e merge

```
feature/issue-N-slug  →  beta  →  main
     (sviluppo)      (test, dati reali)  (produzione, CI deploya)
```

Merge sempre `--merge`, **mai `--squash`**. Nessun merge in `main` senza
`/approva` di Davide.

---

## 1. Issue con Acceptance Criteria verificabili

Ogni issue ha una sezione `## Acceptance Criteria` con checkbox, AC atomici
(input concreto → esito osservabile), taggati:

| Tag | Significa | Chi verifica |
|---|---|---|
| `[UI]` | Osservabile senza guardare il codice | Claudio, poi Ascanio |
| `[Codice]` | Serve leggere codice/query/stato | Solo Claudio + developer |
| `[Campo]` | Richiede scrivere su un impianto reale | Solo Ascanio, mai un agente |
| `[Azione]` | Richiede che Ascanio faccia qualcosa (non solo confermi) | Solo Ascanio |

Prima del loop di implementazione:

```bash
npm run issue:precheck N
```

Blocca se: la issue è già in main, non ha AC verificabili, il testo dice
«verificare se già presente», o ha dipendenze ancora aperte.

Su MaestroWeb **Ascanio non apre issue**: scrive una card in «Idee ASCANIO».
**Una card = un'epica** — le sotto-issue tecniche non vanno mai nel suo
pannello e non ricevono mai una `qa-approved` propria: la ereditano
dall'epica quando lui approva la scheda. Vedi skill `ascanio`.

---

## 2. Presa in carico

Due card diverse, entrambe da spostare a mano — non c'è automatismo:

**Kanban GitHub** (project `PVT_kwHODSTPQM4BP1Xp`, field
`PVTSSF_lAHODSTPQM4BP1Xpzg-INlw`):

| Colonna | Option ID |
|---|---|
| Backlog | `2ab61313` |
| In Progress | `47fc9ee4` |
| Test | `1d6a37f9` |
| Done | `98236657` |

```bash
gh project item-edit --id "$ITEM_ID" \
  --project-id PVT_kwHODSTPQM4BP1Xp \
  --field-id PVTSSF_lAHODSTPQM4BP1Xpzg-INlw \
  --single-select-option-id 47fc9ee4
```

`$ITEM_ID` si prende via GraphQL (`issue.projectItems`), non enumerando la
lista item — su un board grande l'enumerazione può mancare l'item cercato.

**Card di Ascanio** (`qa_tasks.stage`, solo MaestroWeb): se la card esiste,
va in `lavorazione` appena si prende in carico la segnalazione.

---

## 3. Implementazione col loop

Workflow tool, tre fasi:

```
phase Piano            planner    (model: 'fable')
phase Implementazione   developer  (model: 'sonnet', isolation: 'worktree', base: origin/beta)
phase Verifica AC       verificatore (model: 'fable')
```

- Il **developer** crea il branch dalla base `origin/beta` aggiornata,
  commit convenzionali, apre la PR **verso `beta`** con `Closes #N` nel body.
- Il **verificatore** giudica sul `gh pr diff` reale — non si fida del
  developer — ed esegue lui stesso lint/test/build su un checkout del
  branch.
- Retry con feedback puntuale, **max 4 tentativi**. Se dopo 4 tentativi
  restano AC rossi, ferma e segnala a Davide: di solito è l'AC ad essere
  ambiguo, non il developer a sbagliare.
- Retry **3 volte** su errore API (529) per planner e verificatore — non
  abortire il loop per un errore transitorio.
- Gli AC `[Campo]`/`[Azione]` **non** entrano nel criterio di uscita del
  loop: restano aperti in attesa di Ascanio, la PR è comunque pronta se il
  resto è verde.

Per fix piccoli (poche righe, non serve il loop completo): Claudio lavora in
un worktree isolato, sempre con PR verso `beta`.

Dettaglio operativo (script Workflow completo, PLAN_SCHEMA/VERDICT_SCHEMA,
regole per scrivere AC verificabili): skill `dev-loop`.

---

## 4. Su beta

CI verde sulla PR → merge `--merge` in `beta`, label `deployed-test`, Kanban
GitHub → Test. **Poi**, non prima:

1. Prova dal vivo su `https://test-<repo>.8020solutions.org` (per MaestroWeb
   `test-maestro`) — login, dati veri, il flusso descritto dagli AC. Mai
   fidarsi del solo diff.
2. Solo dopo aver visto che funziona: card di Ascanio → `revisione`, con
   `review_notes` che dice cosa guardare e dove cliccare, in italiano
   comune — non un changelog.
3. `npm run deps:schede` — calcola gli avvisi di dipendenza tra schede non
   ancora in produzione. Va lanciato **in questo momento**, non prima: è un
   giro notturno più esecuzioni a mano, e dopo 72 ore l'avviso smette da sé
   di mostrarsi.

**Mai in Revisione senza averla provata tu.** Il reject di Ascanio è un
commento sulla card + rientro in `lavorazione`.

Dettaglio: skill `beta-release`.

---

## 5. Ascanio approva dal pannello

«Approva» sposta la card da `revisione` a `backlog` (per lui vuol dire
«approvato e in produzione») e scrive «✅ Approvata da Revisione a BackLog»
nei commenti. Spesso aggiunge lì una richiesta di modifica — va letta e
trasformata in issue, non persa nel commento.

La label `qa-approved` **non** arriva dallo spostamento della card: la mette
Claudio dopo aver letto i commenti, risalendo dalla card alla issue (tabella
`qa_task_issues`, o dal titolo).

Dettaglio, sezioni del pannello, come si crea la issue dalla card: skill
`ascanio`.

---

## 6. `/approva` di Davide

1. Claudio mette la label `qa-approved` sulle issue approvate (e sui fix
   tecnici che Davide include esplicitamente).
2. `npx tsx scripts/approva-promote.ts --dry-run` — sempre prima del run
   reale. Se esclude gruppi «per conflitto»: quasi sempre è
   `package.json`/`PROJECT.md` (versione/changelog), non un conflitto reale.
3. Run reale → PR verso `main` con tutti i `Closes` → CI verde → merge
   `--merge` (**mai `--squash`**, romperebbe l'idempotenza patch-id dello
   script) → deploy → smoke test (`tests/curl-tests.sh`) → chiude le issue,
   label `deployed-prod`, Kanban → Done.

**Procedura manuale** (se lo script non c'è, o va rifatta a mano):
worktree da `origin/main`, cherry-pick in ordine cronologico di `beta`.
Conflitto solo su `PROJECT.md`/`package.json`/`package-lock.json` →
`checkout --theirs`. Conflitto su altri file → l'intera issue esce con tutti
i suoi commit e si riparte (esclusione a gruppi, iterare). Alla fine
`package.json` + lock presi interi da `beta`. PR verso `main` a mano con
tutti i `Closes`. I conflitti veri restanti sono filoni intrecciati: si
promuovono in blocco, non si spezzano.

Un cron nuovo si schedula con il JWT dal Vault, mai con chiavi in chiaro. Una
migration che ri-schedula un cron cambia l'header dello schedule, non decide
da sola cosa gira.

Dettaglio completo: skill `approva`.

---

## 7. Sezioni del pannello di Ascanio

Revisione · To Do ASCANIO · Fatte da Ascanio · Idee ASCANIO · In Lavorazione
· BackLog.

Le card si cercano **nei dati** (`qa_tasks` via REST con service key), non a
schermo — il DOM del pannello ne mostra solo alcune.

**Ogni sessione di Claudio inizia con:**

```bash
# 1. Controllo build sui repo attivi (segnala solo i failure)
for repo in maestroweb finn BeachRef-app StageConnect GridConnect AutoDrum smartscore; do
  gh run list --repo "ecologicaleaving/$repo" --branch "$(gh api repos/ecologicaleaving/$repo --jq '.default_branch')" \
    --limit 1 --json conclusion,displayTitle,url -q \
    '.[] | select(.conclusion=="failure") | "❌ '"$repo"' — \(.displayTitle)\n   🔗 \(.url)"'
done

# 2. Sync del workflow
cd C:\Users\KreshOS\Documents\00-Progetti\workflow
git pull origin master
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1

# 3. Lettura di PROJECT.md del progetto attivo
```

Dettaglio: skill `claudio`.
