## ⚠️ AVVIO SESSIONE — OBBLIGATORIO

Prima di fare qualsiasi cosa, esegui questi step nell'ordine. Non saltare nessuno.

### 1. Sync workflow
```bash
git submodule update --init --remote .workflow
```

### 2. Leggi le regole operative
`.workflow/skills/issue-implement/SKILL.md`

Contiene il protocollo checkpoint obbligatori, convenzioni commit, branch strategy.
**Non improvvisare — tutto è documentato lì.**

### 3. Leggi il contesto del progetto
`PROJECT.md`

Contiene stack, URL, stato deploy, backlog attivo.

### 4. Leggi la issue assegnata
```bash
gh issue view <N> --repo ecologicaleaving/<repo>
```

Leggi tutto: obiettivo, contesto, AC, note tecniche, checkpoint obbligatori.

---

## ⛔ REGOLE VINCOLANTI

### Checkpoint obbligatori

Ad ogni checkpoint definito nella issue, devi:

1. **Postare un commento sulla issue** con questo formato esatto:

```
## ✅ Checkpoint N — <titolo>

**Stato:** completato

**Cosa è stato fatto:**
<descrizione>

**Risultati test (se applicabile):**
<risultati>

**Prossimo step pianificato:**
<cosa farei dopo>

**Aspetto conferma di Claudio prima di procedere.**
```

2. **Fermarti e aspettare** la risposta di Claudio sulla issue
3. Procedere **solo** quando Claudio scrive "procedi" o "✅ procedi"
4. Se Claudio scrive "bloccato" o chiede chiarimenti → aspetta istruzioni

### Branch

- Lavora sempre su `feature/issue-N-slug` (o `fix/` o `improve/`)
- MAI commit diretti su `main` o `master`
- Branch già creato da Claudio all'avvio — usa quello

### Commit

- Formato convenzionale: `feat:`, `fix:`, `improve:`, `docs:`, `chore:`
- Commit atomici per ogni step logico
- Niente file `.env`, config sensibili, file di debug

### PROJECT.md

- Aggiorna versione, data e issue nella lista done **prima del push finale**

---

## 📋 Checklist pre-push

Prima di fare push, verifica:
- [ ] Tutti gli AC della issue soddisfatti
- [ ] Tutti i checkpoint completati e confermati da Claudio
- [ ] Test suite passata (lint, typecheck, unit, e2e)
- [ ] PROJECT.md aggiornato
- [ ] Nessun file anomalo nel commit
- [ ] Branch corretto (non master/main)
