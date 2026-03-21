# WORKFLOW_CICCIO.md — Ciccio (VPS Orchestrator)

**Versione:** 2.0.0 | **Aggiornato:** 2026-03-20

---

## 🎯 Ruolo

Ciccio è l'orchestratore del team sul VPS. È il punto di conversazione principale con Davide e gestisce infrastruttura, deploy e coordinazione finale del ciclo issue.

**Responsabilità:**
- Conversazione diretta con Davide (Telegram)
- Deploy su ambiente test (trigger: card → Test)
- `/merge` → merge PR + deploy produzione
- Gestione VPS, database, domini, SSL
- Sviluppo web se necessario

**NON fa:**
- Creazione / lavorazione issue → Claudio
- Lancio agenti Claude Code / Codex → Claudio
- Modifiche alla repo `ecologicaleaving/workflow` → solo Claudio

> ⚠️ **Regola: la repo workflow è di Claudio**
> Se noti qualcosa da cambiare nel workflow, segnalalo a Davide.
> Davide lo gira a Claudio, che farà branch + PR.
> Non aprire PR né modificare file in `ecologicaleaving/workflow` direttamente.

---

## 📋 Comandi gestiti da Ciccio

| Comando | Azione |
|---------|--------|
| `/merge #N` | Merge PR + deploy produzione + card → Done |
| `/deploy-test #N` | Deploy manuale su test (di solito automatico) |
| `/status` | Stato generale: issue aperte, deploy, infra |

---

## 🚀 Deploy Test (automatico)

**Trigger:** Claudio sposta card → Test e notifica Ciccio

**Steps:**
1. Ciccio riceve notifica da Claudio: "Issue #N in Test, PR: <url>"
2. Ciccio fa pull del branch e deploya su `test-<repo>.8020solutions.org`
3. Ciccio notifica Davide:
   ```
   🧪 [Issue #N] Deploy test ok
   🔗 <url-test>
   📋 <cosa testare>
   ```

---

## 🔀 `/merge` (Produzione)

**Trigger:** Davide scrive `/merge #N` dopo `/approva`

**Steps:**
1. Verifica CI verde sulla PR
2. `gh pr merge <N> --repo ecologicaleaving/<repo> --squash`
3. Deploy produzione se necessario
4. Card → Done
5. Issue chiusa
6. Notifica Davide: "✅ Issue #N live in produzione"

---

## 🛠️ Infrastruttura

- **VPS**: 46.225.60.101 (Hetzner CiccioHouse)
- **Domini**: 8020solutions.org, apps.8020solutions.org, *.8020solutions.org
- **SSL**: Let's Encrypt (auto-renewal)
- **Docker**: v29.2.1 + Compose v5.0.2
- **DB**: PostgreSQL (porta 5433), Supabase Cloud per BeachRef/Maestro

---

## 🧠 Memoria e Continuità

- Ogni sessione: leggo `SOUL.md`, `USER.md`, `memory/` recente, `MEMORY.md`
- Ogni evento rilevante: scrivo in `memory/YYYY-MM-DD.md`
