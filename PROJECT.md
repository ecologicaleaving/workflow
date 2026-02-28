# PROJECT.md - Single Source of Truth

## Project Info
- **Name**: Workflow Hub
- **Version**: v1.1.1
- **Status**: production
- **Platforms**: documentation
- **Description**: Sistema workflow standardizzato per sviluppo collaborativo AI-assisted

## Database
- **Provider**: none
- **Environment**: N/A
- **Database ID**: N/A
- **Schema**: documentation-only
- **Migration Status**: N/A
- **Connection**: 
  - DEV: N/A (static documentation)
  - PROD: GitHub repository hosting
- **Backup**: git version control
- **Seed Data**: N/A
- **Admin URL**: https://github.com/ecologicaleaving/workflow

## Deployment
- **Live URL**: https://github.com/ecologicaleaving/workflow
- **Deploy Method**: github-hosting
- **CI Status**: passing
- **Last Deploy**: 2026-02-26T05:00:00Z

---

## 🚀 CI/CD Workflow — Build & Deploy per Progetto

### Architettura generale

```
Push su GitHub
      ↓
GitHub Actions (ubuntu-latest)
      ↓
   Build app
      ↓ (via SSH)
   VPS CiccioHouse (46.225.60.101)
      ↓
   Webroot / APK destination
      ↓
   Notifica Telegram a Davide
```

### Deploy per Branch

Ogni branch ottiene il **proprio ambiente isolato**:

| Branch | Web URL | APK |
|--------|---------|-----|
| `master` / `main` | `https://REPO.8020solutions.org` | `REPO-vX.Y.Z.apk` (GitHub Release) |
| `fix/nome-fix` | `https://test-REPO.8020solutions.org/branches/fix-nome-fix/` | `REPO-fix-nome-fix-abc1234.apk` |
| `feature/nome-feat` | `https://test-REPO.8020solutions.org/branches/feature-nome-feat/` | `REPO-feature-nome-feat-abc1234.apk` |

> Con 4 branch attivi → 4 ambienti indipendenti, nessuna sovrascrittura.

**Cleanup automatico:** alla chiusura del branch, la Action di cleanup elimina webroot e APK.

### Secrets GitHub richiesti (per repo)

| Secret | Valore | Descrizione |
|--------|--------|-------------|
| `VPS_SSH_KEY` | chiave privata ed25519 | Deploy key (generata 2026-02-26) |
| `VPS_HOST` | `46.225.60.101` | IP VPS CiccioHouse |
| `VPS_USER` | `root` | Utente SSH |
| `CICCIO_GATEWAY_TOKEN` | `4bc2ca7...` | Token OpenClaw per notifiche |

> La deploy key pubblica è in `/root/.ssh/github-actions-deploy.pub` sul VPS.

### Secrets aggiuntivi per web apps (Next.js)

| Secret | Descrizione |
|--------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | URL Supabase Cloud del progetto |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Anon key Supabase |
| `NEXT_PUBLIC_SITE_URL` | URL base del sito |

### Templates disponibili

| File | Tipo app | Comportamento |
|------|----------|---------------|
| `.github/workflows/template-web-deploy.yml` | Next.js / React | Build → rsync → nginx branch path |
| `.github/workflows/template-flutter-deploy.yml` | Flutter | build apk + web → scp APK → GitHub Release |

### Aggiungere CI/CD a un nuovo repo

**Web app (Next.js/React):**
```bash
# 1. Copia workflow
cp workflow/.github/workflows/template-web-deploy.yml \
   mio-repo/.github/workflows/deploy.yml

# 2. Aggiungi secrets su GitHub
gh secret set VPS_SSH_KEY    --repo ecologicaleaving/mio-repo --body "$(cat /root/.ssh/github-actions-deploy)"
gh secret set VPS_HOST       --repo ecologicaleaving/mio-repo --body "46.225.60.101"
gh secret set VPS_USER       --repo ecologicaleaving/mio-repo --body "root"
gh secret set CICCIO_GATEWAY_TOKEN --repo ecologicaleaving/mio-repo --body "4bc2ca7..."

# 3. Crea webroot base sul VPS
mkdir -p /var/www/test-mio-repo/branches

# 4. Push → Actions parte automaticamente
```

**Flutter app:**
```bash
# Stessi secret + scegli BUILD_APK/BUILD_WEB via Variables GitHub
gh variable set BUILD_APK --repo ecologicaleaving/mio-repo --body "true"
gh variable set BUILD_WEB --repo ecologicaleaving/mio-repo --body "false"
```

### Wildcard SSL (TODO — richiede token Cloudflare)

Per URL clean tipo `fix-storico-maestro.8020solutions.org` invece di path-based:

```bash
# Installa plugin certbot-cloudflare
pip3 install certbot-dns-cloudflare

# Crea credenziali Cloudflare
echo "dns_cloudflare_api_token = CF_TOKEN" > /root/.cloudflare-creds
chmod 600 /root/.cloudflare-creds

# Ottieni wildcard cert
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare-creds \
  -d "*.8020solutions.org" \
  -d "8020solutions.org"
```

> **TODO:** Chiedere a Davide il token Cloudflare API per attivare wildcard SSL.
> Finché non è configurato, si usa il path-based deploy.

## Repository
- **Main Branch**: master
- **Development Branch**: N/A (direct commits)
- **GitHub**: https://github.com/ecologicaleaving/workflow

## Tech Stack
- **Frontend**: Markdown documentation
- **Backend**: Git version control
- **Database**: N/A
- **Auth**: GitHub account access
- **Deployment**: GitHub repository + raw file access
- **Automation**: Shell scripts + JSON configuration

## Services
- **Documentation Hosting**: GitHub repository interface
- **Raw File Access**: GitHub raw content serving
- **Version Control**: Git with GitHub remote
- **Issue Tracking**: GitHub Issues (future)
- **Automation Distribution**: curl-based script installation

## Monitoring
- **Health Check**: Repository accessibility
- **Service Health**: GitHub platform status
- **Usage Analytics**: GitHub traffic stats
- **Alerts**: GitHub notifications
- **Auto Deploy**: git push to master

## Development
- **Local Setup**: 
  1. `git clone git@github.com:ecologicaleaving/workflow.git`
  2. Edit markdown files with preferred editor
  3. Test scripts locally if needed
  4. `git commit` and `git push` for updates
- **Build Process**: 
  1. No build required (static documentation)
  2. Scripts are executable shell files
  3. JSON configurations are validated manually
  4. Deploy via git push

## Troubleshooting
- **Repository Access**: Check GitHub SSH keys and permissions
- **Script Installation**: Verify curl access and execution permissions
- **Configuration Issues**: Validate JSON syntax in config files
- **Permission Errors**: Ensure scripts are executable (chmod +x)

## Backlog
- **TODO**: GitHub Pages deployment for better documentation hosting
- **TODO**: Automated testing per script installazione e funzionalità
- **TODO**: Template repository creation per quick project setup
- **TODO**: Integration con GitHub Issues per team task management
- **TODO**: CI/CD pipeline per validation automatica documentation changes
- **DONE**: Core workflow documentation per tutti i ruoli team
- **DONE**: Commit automation (rinominato da claudio-commit-skin)
- **DONE**: Claude Code skill 8020-commit-workflow con guida installazione dev
- **DONE**: Script install-skills.sh per distribuzione skills via curl
- **TODO**: Training materials e video guides per onboarding
- **TODO**: Metrics collection per workflow effectiveness

---
*Last Updated: 2026-02-22T13:00:00Z*
*Auto-generated from: https://app.8020solutions.org/status.html*