# Skills — 80/20 Solutions Workflow

Le skill estendono il workflow con procedure operative specifiche per ogni fase.
Il flusso completo è in `WORKFLOW.md` nella root del repo.

---

## Skill disponibili

### Flusso issue (in ordine di fase)

| Skill | Fase | Descrizione |
|-------|------|-------------|
| `create-issue` | 1 | Creazione issue leggera da report grezzo → Backlog |
| `issue-validate` | 2 | Validazione interattiva + research + piano → Todo |
| `issue-implement` | 3 | Supervisione implementazione con checkpoint |
| `issue-pr-ready` | 4 | Pre-PR checklist, apertura PR, notifiche → Test |
| `issue-approve` | 5a | Merge PR + chiusura dopo /approva → Done |
| `issue-reject` | 5b | Rework dopo reject semplice |
| `issue-research-rework` | 5b | Research approfondita per reject complessi (≥2) |

### Supporto

| Skill | Descrizione |
|-------|-------------|
| `8020-workflow` | Indice operazioni e regola cardinale |
| `8020-commit-workflow` | Convenzioni commit (Conventional Commits) |
| `security-audit` | Gate sicurezza obbligatorio pre-push |
| `create-prd` | Conversazione guidata per generare un PRD |
| `prd-to-issues` | Breakdown PRD in issue GitHub |
| `preparazione-repo` | Setup iniziale repo per workflow 8020 |
| `repo-maintenance` | Manutenzione file di progetto |
| `pdf-to-md` | Converti PDF in Markdown prima di leggerli — obbligatoria per tutti gli agenti |
| `beachcrer-sync-group` | Verifica corrispondenza gruppo mail "arbitri beach" (Horde) ↔ arbitri attivi BeachCRER |

---

## Installazione

```bash
# Clona e copia le skill
git clone https://github.com/ecologicaleaving/workflow.git /tmp/workflow
cp -r /tmp/workflow/skills/<nome-skill> ~/.claude/skills/

# Oppure usa lo script
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-skills.sh | bash
```
