---
name: commit
description: >
  Convenzioni di commit e PR per i progetti 8020 Solutions — Conventional
  Commits, versioning semantico, dove va il "Closes #N", trailer di
  attribuzione. Trigger: qualunque commit o push in un progetto 8020.
version: 2.0.0
---

# Skill: commit

Regole di commit e PR valide per tutti i progetti 8020. Il flusso di branch
e merge (`feature/issue-N-slug` → `beta` → `main`) è in `FLUSSO.md`.

---

## Check pre-push (obbligatorio, prima di aprire/aggiornare una PR)

`npm run lint`, `npx tsc --noEmit`, unit test ed e2e devono essere **verdi
in locale**. La CI conferma, non scopre: in CI si legge *quanti* test
cadono, in locale *quale asserto* cade — solo la seconda informazione fa
avanzare il lavoro.

Un test **saltato non è un verde**: riporta anche quanti ne sono stati
saltati. Se un check è impossibile in locale, dillo — quale e perché —
invece di lasciarlo silenziosamente alla CI.

---

## Ogni PR ha una issue collegata — anche un fix di tre righe

**Ogni PR deve avere `Closes #N` nel body o nel titolo.** Se il lavoro non
ha una issue, aprine una *prima* di aprire la PR — breve quanto vuoi, ma
aprila.

Non è forma: `approva-promote.ts` (skill `approva`) attribuisce ogni commit
alla sua issue per decidere cosa promuovere in produzione. Un commit che non
riesce ad attribuire è `NON RISOLVIBILE` → **abort dell'intera promozione**,
incluso il lavoro di altri già approvato.

Il 31/08/2026 una PR di una riga aperta senza issue "perché era solo un fix
di processo" ha bloccato al `--dry-run` la promozione di due bug ad alta
priorità già provati. **Un fix non può creare debito tecnico** — la
scorciatoia si paga al rilascio, e la paga chi sta aspettando che il suo
lavoro esca.

> **Il `Closes` va nel body (o titolo) della PR — non nel messaggio di
> commit.** `approva-promote.ts` interroga la PR via API GitHub, non legge
> il commit. Un `Closes #N` messo solo nel merge commit **non viene visto**
> e il commit resta `NON RISOLVIBILE` (scoperto il 31/08/2026, stesso
> giorno in cui questa regola è stata scritta).

Nel dubbio, prima di dire "pronto":
```bash
npx tsx scripts/approva-promote.ts --dry-run
```
Gira in locale, non pusha nulla, e dice subito se la promozione si
bloccherebbe.

---

## Conventional Commits (formato obbligatorio)

```
<type>[optional scope]: <descrizione breve>

[optional body]

[optional footer]
```

| Type | Impatto versione | Uso |
|---|---|---|
| `feat:` | MINOR (1.2.0 → 1.3.0) | nuova funzionalità user-facing |
| `fix:` | PATCH (1.2.0 → 1.2.1) | correzione bug |
| `feat!:` / `BREAKING CHANGE:` | MAJOR (1.2.0 → 2.0.0) | breaking change |
| `docs:` | PATCH | solo documentazione |
| `style:` | PATCH | formattazione, nessun cambio di logica |
| `refactor:` | PATCH | ristrutturazione senza feature/fix |
| `test:` | PATCH | aggiunta/modifica test |
| `chore:` | PATCH | build, dipendenze, config |

Scope comuni: `ui`, `api`, `auth`, `db`, `config`, `deps`.

**Esempi buoni:**
```
feat(auth): add user login with JWT
fix(db): resolve connection timeout on idle
feat!: redesign REST API endpoints
```

**Da evitare:** `"updated stuff"`, `"fix bug"`, `"wip"`, `"changes"` — non
dicono cosa né perché.

---

## Branch — mai commit diretto

Mai committare direttamente su `beta` o `main`. Verifica sempre:
```bash
git branch --show-current
```
Branch di lavoro: `feature/issue-N-slug`, `fix/nome-issue`,
`hotfix/nome-critica`.

---

## PROJECT.md

Verifica che `PROJECT.md` esista e sia aggiornato: versione coerente col
tipo di commit, backlog corrente. Se manca o è incompleto, segui la
checklist in `~/.claude/CLAUDE.md` → «PROJECT.md — Controllo all'avvio».

---

## Esecuzione

```bash
git add <file specifici>          # mai git add -A alla cieca
git commit -m "type(scope): descrizione"
git push origin <branch>
```

Trailer di attribuzione secondo le istruzioni della sessione attiva (se
presenti).

---

## Dopo il push

CI deploya automaticamente su `test-*.8020solutions.org` (branch `beta`) o
in produzione (branch `main`, solo dopo `/approva`). Non pushare mai codice
rotto o non testato — vedi il check pre-push sopra.
