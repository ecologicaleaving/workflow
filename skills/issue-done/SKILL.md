---
name: issue-done
version: 1.0.0
description: >
  Procedura di chiusura lavorazione issue da parte dell'agente dev.
  Da leggere quando il codice è pronto e tutti i test sono verdi.
  Copre: verifica finale, aggiornamento PROJECT.md, commit convenzionale,
  push branch, apertura PR, spostamento card Kanban → Test-ready.
triggers:
  - "issue completata"
  - "finito di sviluppare"
  - "pronto per commit"
  - "issue done"
---

# Issue Done — Chiusura Lavorazione

Leggi questa skill **solo quando il codice è pronto e tutti i test sono verdi**.

---

## STEP 1 — Verifica Acceptance Criteria (AC)

**Prima di tutto**: rileggi l'issue.

```bash
gh issue view <N> --repo <owner/repo>
```

Per ogni AC elencato nell'issue, verifica **uno per uno**:

- AC soddisfatto? Hai una prova concreta (test, output, log)?
- Se l'AC richiede verifica manuale, documentala nel commento finale
- **Se anche un solo AC non è soddisfatto → non andare avanti, torna a fixare**

> ⚠️ Non basta che il codice "funzioni" — deve soddisfare esattamente
> i criteri scritti nell'issue. Ogni AC è un contratto con Davide.

---

## STEP 1b — Definition of Done (DoD)

Prima di qualsiasi commit, **tutti** questi punti devono essere veri:

| # | Criterio | ✅ |
|---|----------|----|
| 1 | Tutti gli AC dell'issue sono soddisfatti | |
| 2 | Test scritti che dimostrano il fix/feature | |
| 3 | `flutter analyze` / `npm run lint` → zero errori | |
| 4 | `flutter test` / `npm test` → tutti verdi | |
| 5 | Nessuna regressione sui test esistenti | |
| 6 | Nessun `print()` / `console.log()` di debug lasciato | |
| 7 | Nessun TODO irrisolto nel codice toccato | |
| 8 | Nessun `.env` o credenziale nei file modificati | |

**Se anche un solo punto è ❌ → non commitare. Segui questo processo:**

```
iterazione = 0
while DoD non completo AND iterazione < 3:
    identifica il criterio che fallisce
    analizza root cause (non indovinare)
    applica il fix mirato
    ri-esegui i test
    iterazione++

if iterazione == 3 AND DoD ancora non completo:
    NON committare
    Segnala all'orchestratore (Claudio o Ciccio) con:
      - quale criterio/AC non è soddisfatto
      - cosa hai provato (le 3 iterazioni)
      - ipotesi sul blocco

    L'orchestratore valuta e se necessario scala a Davide per decisione.
```

> ⚠️ Dopo 3 iterazioni fallite, fermarsi è la cosa giusta.
> Pushare codice broken o con AC non soddisfatti è peggio di non pushare.

---

## STEP 1c — Esegui i test

> ⚠️ **Codex: esegui i test FUORI dalla sandbox.**
> I test dentro la sandbox di Codex vanno sistematicamente in timeout.
> Usa `--full-auto` o `--yolo` (che disabilitano la sandbox) oppure
> esegui i comandi di test con `exec` direttamente nel workspace, non nel container sandbox.

```bash
# Flutter
flutter analyze
flutter test

# Node / React
npm run lint
npm run typecheck   # se disponibile
npm test
```

---

## STEP 2 — Aggiorna PROJECT.md

### Version bump
| Tipo di cambiamento | Bump |
|--------------------|------|
| `fix` / bug | PATCH → es. 1.2.3 → 1.2.4 |
| `feat` / nuova funzionalità | MINOR → es. 1.2.3 → 1.3.0 |
| breaking change | MAJOR → es. 1.2.3 → 2.0.0 |

### Cosa aggiornare
- `Version`: bump secondo tabella sopra
- `CI Status`: `passing`
- `Last Updated`: timestamp UTC corrente (ISO 8601)
- `Backlog`: sposta l'issue da `IN PROGRESS` / `TODO` → `DONE`

### Allinea la versione
Dopo aver aggiornato PROJECT.md, allinea:
- Flutter → `pubspec.yaml` campo `version:`
- Node.js → `package.json` campo `"version":`

---

## STEP 3 — Commit convenzionale

```bash
git add <file specifici>    # MAI git add -A senza verificare prima
git status                  # controlla cosa stai committando

git commit -m "<type>(<scope>): <descrizione breve>

- <cosa è cambiato>
- <perché>

Tests: flutter test ✓ | flutter analyze ✓
Closes #<N>"
```

### Tipi di commit
| Tipo | Quando |
|------|--------|
| `fix` | bug fix |
| `feat` | nuova funzionalità |
| `refactor` | refactoring senza cambi funzionali |
| `test` | solo test aggiunti/modificati |
| `docs` | solo documentazione |
| `chore` | dipendenze, config, CI |

**Esempio corretto:**
```
fix(statistiche): conta tornei per evento fisico invece che per genere

- Aggiunta logica _eventKey() con fallback event_id → no_event → tournament_no
- Aggiornata query designations per includere event_id
- Nuovo test: 2 designazioni M+F stesso evento → count = 1

Tests: flutter test ✓ (42/42) | flutter analyze ✓
Closes #22
```

---

## ⚠️ STEP 4 — Push branch (OBBLIGATORIO)

**Non saltare questo step.** Il push è obbligatorio — senza non puoi aprire la PR.

```bash
git push -u origin feature/issue-<N>-<slug>
```

Verifica che il push sia andato a buon fine prima di procedere.

---

## ⚠️ STEP 5 — Apri PR (OBBLIGATORIO)

**Non saltare questo step.** La PR è la consegna ufficiale del lavoro.  
Senza PR, Davide non può vedere né approvare il lavoro.

```bash
gh pr create \
  --repo <owner/repo> \
  --head feature/issue-<N>-<slug> \
  --base master \
  --title "<type>: <descrizione breve> (#N)" \
  --body "## Fix / Feature

Risolve #<N>

### Cosa è cambiato
- <punto 1>
- <punto 2>

### Test
- ✅ <N> test passati
- ✅ Nessuna regressione"
```

Copia l'URL della PR appena creata — ti serve per il prossimo step.

---

## STEP 6 — Aggiungi commento sull'issue

```bash
gh issue comment <N> --repo <owner/repo> \
  --body "✅ **Implementazione completata — PR #<PR_N> aperta.**

Cosa è stato fatto: <breve descrizione>
Test: <N> test verdi.

In attesa di build CI e deploy su test da parte di Claudio/Ciccio."
```

---

## STEP 7 — Messaggio per Ciccio (deploy test)

Dopo push e PR, **stampa un messaggio pronto da copiare** per Davide, che lo girerà a Ciccio per avviare il deploy su test.

**Formato messaggio:**
```
claudio: deploy su test per <repo> PR #<PR_N> (issue #<N>).
<breve descrizione di cosa è cambiato>.
```

**Esempio:**
```
claudio: deploy su test per finn PR #25 (issue #21).
Fix bilanci — le entrate venivano contate come uscite nella dashboard. Ora corretto.
```

> ⚠️ Questo messaggio è **obbligatorio**. Davide lo copia e lo manda a Ciccio (o a Claudio)
> per triggerare la skill `issue-deploy-test`.

---

## STEP 8 — Label: non toccare

Le label NON vanno modificate al completamento.
Mantieni solo label agente (`codex`, `claude-code`, `ciccio`) + label progetto.
Lo stato è indicato dalla colonna Kanban.

---

## ✅ Checklist pre-consegna

**AC & DoD**
- [ ] Ogni Acceptance Criteria dell'issue è soddisfatto
- [ ] Test scritti che dimostrano ogni AC
- [ ] Tutti i test verdi (lint + unit), zero regressioni
- [ ] DoD completo (Step 1b tutto ✅)

**Codice**
- [ ] Nessun debug code lasciato
- [ ] Nessun TODO irrisolto

**Git & GitHub**
- [ ] PROJECT.md aggiornato (version + CI Status + Backlog + timestamp)
- [ ] Versione allineata in pubspec.yaml / package.json
- [ ] Commit convenzionale con `Closes #N`
- [ ] ⚠️ Branch pushato (`git push -u origin <branch>`) — OBBLIGATORIO
- [ ] ⚠️ PR aperta con `gh pr create` — OBBLIGATORIO — senza PR il lavoro non esiste
- [ ] PR body descrittivo (AC soddisfatti esplicitati)
- [ ] Commento sull'issue
- [ ] ⚠️ Messaggio per Ciccio stampato (Step 7) — Davide lo gira per deploy test
- [ ] Label NON toccate (solo agente + progetto rimangono)

---

## ⏭️ Cosa succede dopo

Claudio o Ciccio leggono la skill **`issue-deploy-test`** per:
- Verificare che la CI sia verde
- Scaricare la build / deployare su test
- Spostare la card → **Test**
- Notificare Davide con il link
