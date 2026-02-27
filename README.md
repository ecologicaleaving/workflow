# 80/20 Solutions — Workflow Hub

Repository centralizzato per workflow, script e skills del team AI di 80/20 Solutions.

---

## 🚀 Installazione rapida

```bash
# Auto-detect ambiente e installa il modulo giusto
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/install.sh | bash
```

Oppure installa direttamente il modulo che ti serve:

| Componente | Comando |
|------------|---------|
| **Ciccio** (VPS OpenClaw) | `curl -sSL .../scripts/install-ciccio.sh \| bash` |
| **Claude Code** (PC Linux/WSL) | `curl -sSL .../scripts/install-claude-code.sh \| bash` |
| **Claude Code** (PC Windows) | `iwr .../scripts/install-claude-code.ps1 \| iex` |
| **Telegram Bot** | `curl -sSL .../scripts/install-telegram-bot.sh \| bash` |

---

## 🏗️ Struttura

```
workflow/
├── install.sh                          # Master installer (auto-detect)
│
├── scripts/
│   ├── install-ciccio.sh               # Installa modulo Ciccio (VPS)
│   ├── install-claude-code.sh          # Installa modulo Claude Code (Linux/WSL)
│   ├── install-claude-code.ps1         # Installa modulo Claude Code (Windows)
│   ├── install-telegram-bot.sh         # Installa bot Telegram
│   │
│   ├── project_board.py                # Helper: muove card GitHub Project board
│   ├── issue_slash_command.py          # Handler /issue e /reject (Telegram → GitHub)
│   ├── triage_command.py               # Handler /triage (assegnazione issue)
│   ├── auto_issue_parser.py            # Parser automatico issue
│   ├── ciccio-issue-monitor.sh         # Cron VPS: monitora issue label ciccio/needs-fix
│   ├── claude-code-issue-monitor.sh    # Cron PC: monitora issue label claude-code
│   ├── claude-monitor.ps1              # Monitor Windows (PowerShell)
│   └── ciccio-notify.sh                # Helper notifiche Telegram da CI/CD
│
└── skills/
    ├── SKILLS.md                       # Indice di tutte le skills
    ├── 8020-workflow/                  # Skill OpenClaw (Ciccio VPS)
    │   ├── SKILL.md
    │   └── references/
    │       ├── WORKFLOW_CICCIO.md
    │       ├── WORKFLOW_CLAUDE_CODE.md
    │       ├── WORKFLOW_DAVID.md
    │       ├── BRANCH_STRATEGY.md
    │       └── COMMIT_CONVENTIONS.md
    ├── 8020-commit-workflow/           # Skill Claude Code — commit corretto
    │   └── SKILL.md
    └── issue-resolver/                 # Skill Claude Code — risoluzione issue
        └── SKILL.md
```

---

## 📦 Moduli

### 🖥️ Ciccio (VPS OpenClaw)

**Cosa installa `install-ciccio.sh`:**
- Script Python e bash in `workspace-ciccio/scripts/`
- Skill `8020-workflow` in `workspace-ciccio/skills/` (trigger automatico su task di workflow)
- `/usr/local/bin/ciccio-notify` per notifiche Telegram da GitHub Actions
- Cron ogni 10 min per `ciccio-issue-monitor.sh`

**Responsabilità:**
- Gestisce `/issue`, `/reject`, `/triage` da Telegram
- Muove card sul GitHub Project board automaticamente
- Spawna subagenti per issue con label `ciccio` o `needs-fix`
- Deploy su ambienti test

---

### 💻 Claude Code (PC)

**Cosa installa `install-claude-code.sh` / `.ps1`:**
- Skills `8020-commit-workflow` e `issue-resolver` in `~/.claude/skills/`
- Script monitor in `~/.claude/monitor/`
- Cron/Task Scheduler ogni 5 min per issue monitoring

**Responsabilità:**
- Processa issue con label `claude-code` autonomamente
- Commit convenzionali + push + PR
- Aggiorna `PROJECT.md` a ogni issue completata

---

## 🔄 Workflow completo

```
Davide: /issue - "descrizione"
        ↓
Ciccio: crea GitHub issue → card su 📋 Todo

Davide: assegna label (claude-code / ciccio)
        ↓
Monitor rileva → card su 🔄 In Progress
        ↓
Agente lavora → commit → push → review-ready
        ↓
Card su 🚀 PUSH → Ciccio deploya su test
        ↓
Card su 🧪 Test → Davide testa APK/URL

Davide: /approve → card ✔️ Done → deploy produzione
Davide: /reject "feedback" → card 🔄 In Progress → rework automatico
```

---

## 📋 GitHub Project Board

**Project**: [80/20 Solutions - Development Hub](https://github.com/users/ecologicaleaving/projects/2)

| Colonna | Chi sposta | Quando |
|---------|-----------|--------|
| `📋 Todo` | Ciccio | Issue creata |
| `🔄 In Progress` | Monitor | Inizio lavorazione / dopo /reject |
| `🚀 PUSH` | Agente | Commit completato (review-ready) |
| `🧪 Test` | Ciccio | Deploy test eseguito |
| `✔️ Done` | Ciccio | /approve + deploy prod |

**Helper**: `scripts/project_board.py` — importabile da qualsiasi script Python.

```bash
# Uso diretto
python3 project_board.py ecologicaleaving/finn 6 "In Progress"
```

---

## 🔧 Workflow files

| File | Ruolo |
|------|-------|
| `WORKFLOW_CICCIO.md` | Responsabilità e procedure Ciccio |
| `WORKFLOW_CLAUDE_CODE.md` | Workflow agente developer PC |
| `WORKFLOW_DAVID.md` | Flusso dal punto di vista di Davide |
| `BRANCH_STRATEGY.md` | Strategia branch Git |
| `COMMIT_CONVENTIONS.md` | Formato commit (Conventional Commits) |

---

## 🔄 Aggiornamento

Per aggiornare un modulo già installato, ri-esegui il suo installer:

```bash
# Ciccio
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-ciccio.sh | bash

# Claude Code
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-claude-code.sh | bash
```

---

*80/20 Solutions — AI-powered development workflows*
