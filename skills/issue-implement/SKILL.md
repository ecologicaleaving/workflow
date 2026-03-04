---
name: issue-implement
version: 1.0.0
description: >
  Guida all'implementazione del codice per una issue assegnata.
  Da leggere dopo issue-start, prima di issue-done.
  Copre: ciclo TDD, scrittura codice pulito, gestione migrazioni DB,
  commit atomici, regole generali per tutti gli stack del team.
  Usa quando: stai per scrivere codice per una issue, hai dubbi su
  come strutturare test o migrazioni, vuoi le convenzioni di scrittura.
triggers:
  - "implementa issue"
  - "scrivi codice"
  - "inizio implementazione"
  - "come gestisco le migrazioni"
  - "come scrivo i test"
---

# Issue Implement — Guida all'Implementazione

Leggi questa skill **dopo `issue-start`, prima di scrivere codice**.

---

## STEP 1 — Rileva lo stack e carica il riferimento

Identifica lo stack dal `PROJECT.md` o dai file del repo:

| Stack | File spia | Riferimento |
|---|---|---|
| Flutter / Dart | `pubspec.yaml` | [references/flutter.md](references/flutter.md) |
| React Native / Expo | `app.json` o `expo` in `package.json` | [references/react-native.md](references/react-native.md) |
| Node.js / API | `package.json` senza Expo | [references/node.md](references/node.md) |

Carica il file di riferimento appropriato **prima** di scrivere codice.

Se il progetto usa Supabase (campo `supabase` in PROJECT.md o directory `supabase/`):
→ carica anche [references/migrations.md](references/migrations.md)

---

## STEP 2 — Test-first dagli Acceptance Criteria

**Regola**: scrivi i test *prima* del codice di produzione. Gli AC dell'issue sono i tuoi test case.

```
Per ogni AC nell'issue:
  1. Scrivi un test che fallisce (RED)
  2. Scrivi il codice minimo per farlo passare (GREEN)
  3. Refactora senza rompere il test (REFACTOR)
```

### Come leggere gli AC

```bash
gh issue view <N> --repo <owner/repo>
```

Ogni AC deve diventare uno o più test. Esempio:

> AC: "La schermata non mostra overflow su nessun device size"
> → `testWidgets('no overflow on small screen', ...)`
> → `testWidgets('no overflow on large screen', ...)`

**Non andare avanti finché il test non è scritto.**

---

## STEP 3 — Regole generali di scrittura

### Naming
- Nomi descrittivi, senza abbreviazioni (`userExpenseList` non `uel`)
- Funzioni: verbo + oggetto (`calculateTotal`, `fetchUserExpenses`)
- Booleani: prefisso `is/has/can` (`isLoading`, `hasError`)

### Funzioni
- Una funzione = una responsabilità
- Max ~30 righe; se supera, spezza in funzioni più piccole
- Niente magic numbers: usa costanti con nome

```dart
// ❌
if (attempts > 3) { ... }

// ✅
const int maxLoginAttempts = 3;
if (attempts > maxLoginAttempts) { ... }
```

### Gestione errori
- Non silenziare mai gli errori (no `catch (_) {}` vuoto)
- Loga sempre l'errore con contesto (`debugPrint` / `logger.error`)
- Mostra feedback utente per errori visibili (snackbar, dialog)

### Sicurezza
- **Zero credenziali nel codice** — usa variabili d'ambiente o `--dart-define`
- **Zero `print()` / `console.log()` in produzione** — usa `debugPrint` (Flutter) o logger configurabile
- Input utente: valida sempre lato server, non solo client

### Scope
- Implementa **solo** ciò che gli AC richiedono
- Se scopri un bug correlato ma fuori scope → apri issue separata, non fixarlo ora
- Niente "mentre ci sono, miglioro anche X"

---

## STEP 4 — Commit atomici

Un commit = un'unità logica coerente. Non aspettare la fine.

```
✅ "feat: aggiungi widget LiveTournamentBanner"
✅ "test: aggiungi widget test per LiveTournamentBanner"
✅ "fix: correggi overflow layout schermata Spese"

❌ "vari fix e aggiornamenti"
❌ maxi-commit con 20 file cambiati
```

Formato commit (convenzionale):
```
<type>(<scope>): <descrizione breve>

- dettaglio 1
- dettaglio 2
```

Tipi: `feat` · `fix` · `test` · `refactor` · `docs` · `chore`

---

## STEP 5 — Quando fermarsi

**Stop quando:**
- Tutti gli AC sono verdi nei test
- Nessuna regressione
- Zero warning dal linter

**Non aggiungere scope** oltre gli AC anche se "è facile".  
Quando hai finito → leggi la skill **`issue-done`**.

---

## ⚠️ Migrazioni DB

Se l'issue tocca il database → **leggi [references/migrations.md](references/migrations.md) prima di scrivere SQL**.  
Errori nelle migration sono difficili da correggere in produzione.
