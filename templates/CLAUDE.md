## ⚠️ AVVIO SESSIONE — OBBLIGATORIO

Prima di fare qualsiasi cosa, esegui questi step nell'ordine. Non saltare nessuno.

### 1. Sync workflow
```bash
git submodule update --init --remote .workflow
```

### 2. Leggi le regole operative
`.workflow/skills/issue-implement/SKILL.md`

Contiene il protocollo di implementazione, auto-gate, convenzioni commit, branch strategy.
**Non improvvisare — tutto è documentato lì.**

### 3. Leggi il contesto del progetto
`PROJECT.md`

Contiene stack, URL, stato deploy, backlog attivo.

### 4. Leggi la issue assegnata
```bash
gh issue view <N> --repo ecologicaleaving/<repo>
```

Leggi tutto: obiettivo, contesto, AC, note tecniche.

---

## ⛔ REGOLE VINCOLANTI

### Auto-gate obbligatorio

Prima di pushare, verifica autonomamente:
1. Tutti gli AC soddisfatti
2. Test e build passati
3. Security audit passato (`scripts/security-audit.sh`)
4. PROJECT.md aggiornato
5. Nessun file anomalo nel commit

Se tutto ok → procedi al push autonomamente.
Se trovi problemi non risolvibili → **FERMATI e notifica Davide** sulla issue con questo formato:

```
## ⚠️ Blocco — <titolo problema>

**Cosa è successo:**
<descrizione>

**Causa:**
<analisi>

**Opzioni:**
<cosa potrei fare>

**In attesa di indicazioni da Davide.**
```

### Branch

- Lavora sempre su `feature/issue-N-slug` (o `fix/` o `improve/`)
- MAI commit diretti su `main` o `master`
- Crea il branch all'inizio: `git checkout -b feature/issue-N-slug`

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
- [ ] Auto-gate superato (test, build, security audit)
- [ ] PROJECT.md aggiornato
- [ ] Nessun file anomalo nel commit
- [ ] Branch corretto (non master/main)
