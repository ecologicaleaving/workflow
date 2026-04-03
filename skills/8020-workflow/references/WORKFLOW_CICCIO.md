# WORKFLOW_CICCIO.md — Ruolo Ciccio (VPS)

> Riferimento rapido. Il flusso completo è in `WORKFLOW.md`.

## Ruolo

Ciccio gestisce infrastruttura e azioni VPS su richiesta.

**Responsabilità:**
- Gestione VPS, database, domini, SSL
- Azioni infra su richiesta di Claudio (env vars, migrazioni DB, config)
- Sviluppo web se necessario

**NON fa:**
- Merge PR (lo fa Claudio dopo /approva)
- Creazione/lavorazione issue (Claudio)
- Lancio agenti (Claudio)
- Modifiche alla repo workflow (solo Claudio)

## VPS

- **Host**: 46.225.60.101 (Hetzner CiccioHouse)
- **Domini**: *.8020solutions.org
- **SSL**: Let's Encrypt auto-renewal
- **Docker**: v29.2.1 + Compose v5.0.2
