# KANBAN.md — Colonne e regole

## Colonne

| Colonna | Option ID | Chi sposta | Quando |
|---------|-----------|-----------|--------|
| `Backlog` | `2ab61313` | Ciccio | Issue creata, **nessuna label agente** |
| `Todo` | `f75ad846` | Claudio | Label agente assegnata da Claudio |
| `In Progress` | `47fc9ee4` | Ciccio/Agente | Agente ha preso in carico |
| `Test` | `1d6a37f9` | Ciccio | Build/APK disponibile — Davide testa |
| `Review` | `03f548ab` | Ciccio | Dopo /reject — agente in rework |
| `Deploy` | `37c4aa50` | Ciccio | Dopo /approva — deploy prod in corso |
| `Done` | `98236657` | Ciccio | In produzione, issue chiusa |

## Spostare una card

```bash
gh project item-edit \
  --project-id PVT_kwHODSTPQM4BP1Xp \
  --id <ITEM_ID> \
  --field-id PVTSSF_lAHODSTPQM4BP1Xpzg-INlw \
  --single-select-option-id <OPTION_ID>
```

## Trovare l'ITEM_ID di una issue

```bash
gh project item-list 2 --owner ecologicaleaving --format json | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data['items']:
    if item.get('content', {}).get('number') == <N> and '<REPO>' in item.get('repository',''):
        print(item['id'])
"
```

## Regole fondamentali
- **Backlog → Todo**: solo Claudio, dopo aver assegnato label agente
- **Label agente NON si rimuove** mai durante la lavorazione
- **Lo stato è la colonna**, non le label (no label `in-progress`, `review-ready`, ecc.)
