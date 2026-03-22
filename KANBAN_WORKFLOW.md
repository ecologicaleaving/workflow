# KANBAN_WORKFLOW.md — Flusso Kanban 80/20 Solutions

**Versione:** 2.0.0 | **Aggiornato:** 2026-03-20

---

## 📊 Colonne e Transizioni

```
Backlog → Todo → InProgress → Test → Deploy → Done
                                ↓
                             Review (rework)
                                ↓
                              Test → loop
```

| Colonna | Descrizione | Chi la sposta |
|---------|-------------|---------------|
| **Backlog** | Issue creata, non ancora in lavorazione | Claudio (dopo /create-issue) |
| **Todo** | Assegnata, agente pronto a partire | Claudio (avvio piano) |
| **InProgress** | Agente al lavoro | Claudio (piano approvato) |
| **Test** | PR aperta, Ciccio deploya in test | Claudio (PR pronta) |
| **Review** | /reject di Davide, agente in rework | Claudio (dopo /reject) |
| **Deploy** | /approva di Davide, Ciccio fa merge | Claudio (dopo /approva) |
| **Done** | Deployato in produzione, chiuso | Ciccio (dopo /merge) |

---

## 🔄 Flusso Standard

```
1. Davide descrive → Claudio crea issue → Backlog
2. Claudio avvia piano → Todo
3. Piano approvato, agente lavora → InProgress
4. PR pronta, Claudio notifica Ciccio → Test
5. Ciccio deploya in test, notifica Davide
6. Davide testa:
   → /approva → Deploy → Ciccio /merge → Done
   → /reject  → Review → rework → Test → loop
```

---

## ♻️ Flusso Reject

```
Davide /reject "feedback + risultati test"
    ↓
Claudio aggiorna issue con feedback e risultati
    ↓
Card → Review
    ↓
Agente rilavorazione con feedback come contesto
    ↓
PR aggiornata → Card → Test
    ↓
Ciccio rideploya in test
    ↓
Davide testa di nuovo → /approva o /reject (loop)
```

---

## 🏷️ Label Sistema

| Label | Chi la mette | Significato |
|-------|-------------|-------------|
| `agent:claude-code` | Claudio | Issue assegnata a Claude Code |
| `agent:codex` | Claudio | Issue assegnata a Codex |
| `agent:ciccio` | Claudio | Task infra per Ciccio |
| `in-progress` | Claudio | Agente al lavoro |
| `review-ready` | Claudio | PR pronta per review Davide |
| `deployed-test` | Ciccio | Live su ambiente test |
| `needs-fix` | Claudio | Reject ricevuto, rework in corso |

---

## 📋 Project Kanban

- **Project:** 80/20 Solutions - Development Hub
- **Project Number:** 2
- **Owner:** ecologicaleaving
- **IDs:** vedi `config.json` (fonte di verità)
