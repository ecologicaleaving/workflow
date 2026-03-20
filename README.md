# 80/20 Solutions — Workflow v2.0

**Aggiornato:** 2026-03-20

---

## 🏗️ Architettura Team

```
Davide (Telegram)
    │
    ├──→ Ciccio (VPS) ────── conversazione principale, infra, deploy, /merge
    │
    └──→ Claudio (PC) ────── gestione issue, supervisione agenti, supporto sviluppo
              │
              ├── Claude Code  (dev agent)
              └── Codex        (dev agent alternativo)
```

---

## 🔄 Flusso Issue

```
Davide descrive → Claudio /create-issue → Backlog
                                ↓
                           Claudio avvia piano → Todo
                                ↓
                        Piano approvato → InProgress
                     (agente al lavoro, checkpoint obbligatori)
                                ↓
                          PR pronta → Test
                       (Ciccio deploya in test)
                                ↓
                    Davide testa
                    ├── /approva → Deploy → Ciccio /merge → Done
                    └── /reject  → Review → rework → Test → loop
```

---

## 📋 Comandi

| Comando | Chi | Cosa fa |
|---------|-----|---------|
| `/create-issue` | Davide → Claudio | Avvia raccolta nuova issue |
| `/vai` | Davide → Claudio | Dà il via all'agente |
| `/approva` | Davide → Claudio | Approva PR, card → Deploy |
| `/reject <feedback>` | Davide → Claudio | Rework con feedback |
| `/merge #N` | Davide → Ciccio | Merge + deploy produzione |

---

## 📁 Struttura Repository

```
workflow/
├── config.json                    # Fonte di verità ID Kanban, repos, agenti
├── README.md                      # Questo file
├── WORKFLOW_CLAUDIO.md            # Ruolo e workflow Claudio
├── WORKFLOW_CICCIO.md             # Ruolo e workflow Ciccio
├── KANBAN_WORKFLOW.md             # Flusso Kanban colonne
├── BRANCH_STRATEGY.md             # Convenzioni branch (invariato)
├── COMMIT_CONVENTIONS.md          # Convenzioni commit (invariato)
├── templates/
│   ├── issue-feature.md           # Template issue feature
│   ├── issue-bug.md               # Template issue bug
│   ├── issue-improvement.md       # Template issue improvement
│   ├── pull_request_template.md   # Template PR
│   └── reject.md                  # Template sezione rework
└── skills/
    ├── create-issue/SKILL.md      # Creazione issue strutturata
    ├── issue-start/SKILL.md       # Avvio piano e lavorazione
    ├── issue-implement/SKILL.md   # Supervisione implementazione
    ├── issue-done/SKILL.md        # PR + notifica test
    ├── issue-reject/SKILL.md      # Gestione reject e rework
    ├── issue-deploy-test/SKILL.md # Deploy ambiente test (Ciccio)
    └── issue-deploy-prod/SKILL.md # Merge + deploy produzione (Ciccio)
```

---

## 🏷️ Label Sistema

| Label | Significato |
|-------|-------------|
| `agent:claude-code` | Assegnata a Claude Code |
| `agent:codex` | Assegnata a Codex |
| `agent:ciccio` | Task infra per Ciccio |
| `in-progress` | Agente al lavoro |
| `review-ready` | PR pronta |
| `deployed-test` | Live su test |
| `needs-fix` | Reject, rework in corso |
| `deployed-prod` | Live in produzione |

---

## 📊 Kanban

**Project:** 80/20 Solutions - Development Hub (#2)  
**Owner:** ecologicaleaving  
**IDs:** vedi `config.json`

| Colonna | Significato |
|---------|-------------|
| Backlog | Issue creata |
| Todo | Pronta per piano |
| InProgress | Agente al lavoro |
| Test | PR aperta, in test |
| Review | Rework dopo reject |
| Deploy | Approvata, in deploy |
| Done | Completata |
