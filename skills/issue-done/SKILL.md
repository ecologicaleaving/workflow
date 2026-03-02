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

## STEP 1 — Verifica finale

Prima di qualsiasi commit:

```bash
# Flutter
flutter analyze
flutter test

# Node / React
npm run lint
npm run typecheck   # se disponibile
npm test
```

**Regola**: se anche un solo test è rosso, non andare avanti — torna a fixare.

Controlla anche:
- Nessun `print()` / `console.log()` di debug lasciato
- Nessun TODO irrisolto nel codice che hai toccato
- Nessun file `.env` o credenziale nei file modificati

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

## STEP 4 — Push branch

```bash
git push -u origin feature/issue-<N>-<slug>
```

---

## STEP 5 — Apri PR

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

## STEP 7 — Aggiorna label

```bash
# Rimuovi in-progress, aggiungi review-ready
gh issue edit <N> --repo <owner/repo> \
  --remove-label "in-progress" \
  --add-label "review-ready"
```

---

## ✅ Checklist pre-consegna

- [ ] Tutti i test verdi (lint + unit)
- [ ] Nessun debug code lasciato
- [ ] PROJECT.md aggiornato (version + CI Status + Backlog + timestamp)
- [ ] Versione allineata in pubspec.yaml / package.json
- [ ] Commit convenzionale con `Closes #N`
- [ ] Branch pushato
- [ ] PR aperta con body descrittivo
- [ ] Commento sull'issue
- [ ] Label aggiornata → `review-ready`

---

## ⏭️ Cosa succede dopo

Claudio o Ciccio leggono la skill **`issue-deploy-test`** per:
- Verificare che la CI sia verde
- Scaricare la build / deployare su test
- Spostare la card → **Test**
- Notificare Davide con il link
