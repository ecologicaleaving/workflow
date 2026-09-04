# REJECT.md — Procedura /reject

> Riferimento rapido. La procedura completa è nella skill `issue-reject`.

## Trigger
Davide scrive: `/reject <feedback>`

## Procedura

1. Registra feedback come commento sulla issue
2. Label: rimuovi `review-ready`, aggiungi `needs-fix`
3. Sposta card: `Test` → `Review` (`./scripts/kanban-move.sh`)
4. Rilancia agente con feedback come contesto
5. Dopo rework: stesso flusso Fase 3 → Fase 4
6. Loop fino a `/approva`

Per reject complessi (≥2 reject) → usa skill `issue-research-rework`
