# KANBAN.md — Colonne e regole

> Fonte di verità per gli ID: `config.json`

## Colonne

| Colonna | Chi sposta | Quando |
|---------|-----------|--------|
| **Backlog** | Agente | Issue creata |
| **Todo** | Agente | Validata, piano pronto |
| **InProgress** | Agente | Dopo /vai, implementazione avviata |
| **Test** | Agente | PR aperta, CI deploya in test |
| **Review** | Agente | Dopo /reject, rework |
| **Done** | Agente | Dopo /approva, PR mergiata |

## Spostare una card

```bash
./scripts/kanban-move.sh <ISSUE_NUMBER> <REPO> <COLUMN_NAME>
```

## Regole
- La colonna **Deploy** non è più usata — l'agente mergia direttamente dopo /approva
- Lo stato è la colonna Kanban
- Label agente NON si rimuove durante la lavorazione
