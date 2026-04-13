# WORKFLOW_CICCIO.md — Infra VPS (senza Ciccio)

> Riferimento rapido per azioni infra che prima gestiva Ciccio.
> Ora vengono elencate dall'agente e eseguite manualmente da Davide.

## VPS

- **Host**: 46.225.60.101 (Hetzner CiccioHouse)
- **Domini**: *.8020solutions.org
- **SSL**: Let's Encrypt auto-renewal
- **Docker**: v29.2.1 + Compose v5.0.2

## Azioni infra comuni

Quando l'agente segnala azioni infra necessarie (Step 5 di `issue-approve`), Davide le esegue direttamente sul VPS:

### Env vars

```bash
ssh root@46.225.60.101
cd /opt/<repo>
nano .env  # aggiungi la variabile
docker compose restart <service>
```

### Migrazioni DB

```bash
ssh root@46.225.60.101
cd /opt/<repo>
docker compose exec app <migration-command>
```

### Riavvio servizio

```bash
ssh root@46.225.60.101
cd /opt/<repo>
docker compose pull && docker compose up -d
```

## Note

- L'agente non ha accesso SSH al VPS — elenca le azioni, Davide le esegue
- Per deploy: la CI gestisce tutto automaticamente (push → build → deploy)
- Azioni infra manuali sono l'eccezione, non la regola
