# Label Standard — Workflow 8020

Lista completa delle label che ogni repo del workflow deve avere.

## Label Agente

| Nome | Colore | Descrizione |
|------|--------|-------------|
| `claude-code` | `#0075ca` | Assegnata a Claude Code |
| `infra` | `#e4e669` | Task infrastrutturale (VPS, DB, domini) |

## Label Stato Workflow

| Nome | Colore | Descrizione |
|------|--------|-------------|
| `in-progress` | `#fbca04` | Lavorazione in corso |
| `deployed-test` | `#0e8a16` | Deployato in ambiente test |
| `needs-fix` | `#ee0701` | Richiede fix dopo review |
| `review-ready` | `#c2e0c6` | Pronto per review di Davide |

## Label Default GitHub (già presenti, non toccare)

- `bug`
- `documentation`
- `duplicate`
- `enhancement`
- `good first issue`
- `help wanted`
- `invalid`
- `question`
- `wontfix`

## Note

- Colori in formato HEX senza `#` quando passati via `gh api`
- Non rimuovere label esistenti anche se non standard
- Se una label esiste ma con colore diverso → non sovrascrivere, solo segnalare
