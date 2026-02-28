# CREDENTIALS_WORKFLOW.md
# Gestione Credenziali Production-Ready — 80/20 Solutions

## Regola d'oro

> **Le credenziali non entrano mai nel repo git.** Mai.
> Né in `.env`, né in commenti, né in script, né in `SETUP_*.md`.

---

## Dove vivono le credenziali

| Dove | Per cosa | Chi gestisce |
|------|----------|--------------|
| **GitHub Secrets** (repo settings) | Credenziali CI/CD (build APK, deploy) | Ciccio / Davide |
| **File `.env` locale** | Dev locale sul PC (gitignored) | Davide / Claudio |
| **VPS `/etc/environment` o `.bashrc`** | Servizi sempre attivi sul VPS | Ciccio |
| **`SETUP_*.md`** | Link al dashboard, mai la chiave | Chiunque |

---

## Workflow per ogni nuovo progetto

### 1. Setup iniziale (Davide / Ciccio)

```bash
# Aggiungi i secrets al repo GitHub
gh secret set SUPABASE_URL        --repo ecologicaleaving/<repo> --body "https://xxx.supabase.co"
gh secret set SUPABASE_ANON_KEY   --repo ecologicaleaving/<repo> --body "eyJ..."

# Per backend Node.js/Express
gh secret set DATABASE_URL        --repo ecologicaleaving/<repo> --body "postgresql://..."
gh secret set JWT_SECRET          --repo ecologicaleaving/<repo> --body "..."
```

### 2. CI/CD — build con credenziali (Flutter APK)

```yaml
# Nel workflow .github/workflows/build-apk.yml
- name: Create .env file
  run: |
    echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
    echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
```

### 3. CI/CD — deploy backend (Node.js/web)

```yaml
- name: Deploy backend
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    JWT_SECRET: ${{ secrets.JWT_SECRET }}
  run: |
    npm run build
    pm2 reload ecosystem.config.cjs
```

### 4. Dev locale — setup PC

```bash
# Lo sviluppatore copia il template e inserisce le credenziali
cp .env.example .env
# Poi edita .env con i valori reali (chiede a Davide se non li ha)
```

---

## Secrets obbligatori per tipo di progetto

### Flutter app (Supabase Cloud)
| Secret | Esempio valore | Note |
|--------|---------------|------|
| `SUPABASE_URL` | `https://xxx.supabase.co` | Dal dashboard Supabase → Settings → API |
| `SUPABASE_ANON_KEY` | `eyJ...` | Chiave pubblica, safe per client |

### Web app (Next.js / Node.js + Supabase)
| Secret | Note |
|--------|------|
| `SUPABASE_URL` | Come sopra |
| `SUPABASE_ANON_KEY` | Frontend |
| `SUPABASE_SERVICE_KEY` | Backend only — mai nel client |
| `JWT_SECRET` | Min 32 chars random |
| `DATABASE_URL` | Se Prisma/direct |

### Web app (Node.js + Neon / Postgres)
| Secret | Note |
|--------|------|
| `DATABASE_URL` | `postgresql://user:pass@host/db` |
| `JWT_SECRET` | Min 32 chars random |
| `ENCRYPTION_KEY` | Per dati cifrati, 32 chars |

---

## Regole per gli agenti (Claudio / Codex / Ciccio)

1. **Mai hardcodare** credenziali nel codice sorgente
2. **Mai committare** file `.env` (verificare `.gitignore` prima di ogni commit)
3. **Mai loggare** credenziali (`console.log`, `print`, Flutter debug)
4. Se manca un secret → **fermarsi e segnalare**, non inventare fallback insicuri
5. Se si scopre una credenziale in git history → **segnalare immediatamente** a Davide

---

## Checklist pre-PR (credenziali)

Prima di aprire ogni PR, l'agente verifica:

- [ ] `.env` non è tra i file committati (`git status`)
- [ ] Nessuna stringa `eyJ`, `sk-`, `postgresql://`, `Bearer ` hardcodata nei sorgenti
- [ ] `.gitignore` include `.env`, `.env.*`, `.env.local`
- [ ] Se il progetto è nuovo: GitHub Secrets sono stati configurati?
- [ ] `SETUP_*.md` non contiene chiavi in chiaro

---

## Dove trovare le credenziali di ogni progetto

| Progetto | DB | Dashboard |
|----------|----|-----------|
| **Finn** | Supabase Cloud `ofsnyaplaowbduujuucb` | [dashboard](https://supabase.com/dashboard/project/ofsnyaplaowbduujuucb) |
| **BeachRef** | Supabase Cloud `peofucnjgcrgswzqslpb` | [dashboard](https://supabase.com/dashboard/project/peofucnjgcrgswzqslpb) |
| **Maestro** | Supabase Cloud `ckzxfvmqmjzrrazkfpnu` | [dashboard](https://supabase.com/dashboard/project/ckzxfvmqmjzrrazkfpnu) |
| **progetto-casa** | Neon Cloud | [dashboard Neon](https://console.neon.tech) |
| **GridConnect** | Postgres VPS (`postgres-dev`) | VPS porta 5433 |

---

## Rotazione credenziali

Se una chiave viene compromessa (es. trovata in git history):

1. **Revocarla immediatamente** dal dashboard del provider
2. **Generare una nuova** chiave
3. **Aggiornare GitHub Secrets** (`gh secret set ...`)
4. **Aggiornare il VPS** se usata in servizi attivi
5. **Notificare Davide** con dettaglio su cosa è stato esposto

---

*Ultima modifica: 2026-02-28*
