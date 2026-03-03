## ⚠️ AVVIO SESSIONE — OBBLIGATORIO

Prima di fare qualsiasi cosa, esegui questi 3 step nell'ordine:

### 1. Sync workflow
```bash
git submodule update --remote .workflow
```
*(Windows PowerShell: `git submodule update --remote .\.workflow`)*

> Se il submodule non è ancora inizializzato:
> ```bash
> git submodule update --init --remote .workflow
> ```

### 2. Leggi il workflow completo
`.workflow/CLAUDE.md`

Contiene tutte le regole operative del team: branch strategy, commit conventions,
kanban workflow, ruoli, procedure. Non improvvisare — tutto è documentato lì.

### 3. Leggi il contesto del progetto
`PROJECT.md`

Contiene stack, URL, stato deploy, backlog attivo.

---

Non procedere con nessuna attività prima di aver completato questi 3 step.
