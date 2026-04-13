# 80/20 Solutions — Workflow v4.0

**Aggiornato:** 2026-04-13

---

## 🏗️ Team

```
Davide (Product Owner)
    │
    └──→ Agente (Claude Code) — gestisce tutto il ciclo
              └── research → piano → implementazione → PR → merge
```

---

## 🆕 Flusso PRD → Issue (progetti/feature grandi)

```
Davide ha un'idea
    ↓
/create-prd → Conversazione strutturata → PRD.md + PROJECT.md
    ↓
(se repo nuova) /prepara-repo → Setup repo + labels + templates
    ↓
/prd-to-issues → Breakdown fasi → Issue batch su GitHub
    ↓
Workflow normale per ogni issue (vedi sotto)
```

---

## 🔄 Flusso Issue (singola)

```
Davide descrive → /create-issue → Backlog
                        ↓
               /issue-validate → research + piano → Todo
                        ↓
                    /vai → InProgress
              (agente implementa autonomamente)
                        ↓
                 Auto-gate → push → PR → Test
               (CI deploya su test-<repo>.8020solutions.org)
                        ↓
                  Davide testa
                  ├── /approva → Agente mergia → CI deploya prod → Done
                  └── /reject  → Review → rework → Test → loop
```

---

## 📋 Comandi

| Comando | Chi risponde | Cosa fa |
|---------|-------------|---------|
| `/create-prd` | Agente | Crea PRD da idea/brief |
| `/prd-to-issues` | Agente | Genera issue batch da PRD |
| `/create-issue` | Agente | Crea issue leggera in Backlog |
| `/issue-validate #N` | Agente | Research + piano → Todo |
| `/vai` | Agente | Avvia implementazione |
| `/approva` | Agente | Mergia PR, deploya prod, chiude issue |
| `/reject <feedback>` | Agente | Registra feedback, avvia rework |

---

## 📁 Struttura Repository

```
workflow/
├── config.json                       # Fonte di verità ID Kanban, repos
├── README.md                         # Questo file
├── WORKFLOW.md                       # Flusso completo, ruoli, fasi
├── CLAUDE.md                         # Istruzioni agente
├── templates/
│   ├── CLAUDE.md                     # Template regole agente (da copiare nei repo)
│   ├── AGENTS.md                     # Stessa cosa in inglese
│   ├── issue-feature.md              # Template issue feature
│   ├── issue-bug.md                  # Template issue bug
│   ├── issue-improvement.md          # Template issue improvement
│   └── pull_request_template.md      # Template PR
└── skills/
    ├── create-issue/SKILL.md         # Fase 1 — creazione issue
    ├── issue-validate/SKILL.md       # Fase 2 — validazione + piano
    ├── issue-implement/SKILL.md      # Fase 3 — implementazione
    ├── issue-pr-ready/SKILL.md       # Fase 4 — PR + notifica
    ├── issue-approve/SKILL.md        # Fase 5a — merge dopo /approva
    ├── issue-reject/SKILL.md         # Fase 5b — rework dopo /reject
    ├── issue-research-rework/SKILL.md # Fase 5b — rework complesso
    ├── create-prd/SKILL.md           # Creazione PRD
    ├── prd-to-issues/SKILL.md        # PRD → issue batch
    ├── security-audit/SKILL.md       # Gate sicurezza pre-push
    └── preparazione-repo/SKILL.md    # Setup iniziale repo
```

---

## 🏷️ Label Sistema

| Label | Significato |
|-------|-------------|
| `agent:claude-code` | Assegnata a Claude Code |
| `in-progress` | Agente al lavoro |
| `review-ready` | PR pronta per test Davide |
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
| Todo | Pronta per lavorazione |
| InProgress | Agente al lavoro |
| Test | PR aperta, in test |
| Review | Rework dopo reject |
| Done | Completata, in produzione |
