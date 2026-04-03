# KANBAN.md — Colonne e regole

> Fonte di verità per gli ID: `config.json`

## Colonne

| Colonna | Chi sposta | Quando |
|---------|-----------|--------|
| **Backlog** | Claudio | Issue creata |
| **Todo** | Claudio | Validata, piano pronto |
| **InProgress** | Claudio | Dopo /vai, agente al lavoro |
| **Test** | Claudio | PR aperta, CI deploya in test |
| **Review** | Claudio | Dopo /reject, rework |
| **Done** | Claudio | Dopo /approva, PR mergiata |

## Spostare una card

```bash
./scripts/kanban-move.sh <ISSUE_NUMBER> <REPO> <COLUMN_NAME>
```

## Regole
- La colonna **Deploy** non è più usata — Claudio mergia direttamente dopo /approva
- Lo stato è la colonna Kanban
- Label agente NON si rimuove durante la lavorazione
