# PROJECT.md - Single Source of Truth Template

**Questo file deve essere presente in ogni repository e aggiornato ad ogni commit significativo.**

```markdown
# PROJECT.md - Single Source of Truth

## Project Info
- **Name**: [Nome progetto pubblico]
- **Version**: [v1.2.3 - semantic versioning]
- **Status**: [development|staging|production]
- **Platforms**: [web|apk|ios|desktop]
- **Description**: [Descrizione generica, privacy-friendly, professionale ma vaga]

## Database
- **Provider**: [postgresql-local|neon-cloud|supabase-cloud|sqlite-local|none]
- **Environment**: [development|staging|production|device-local]
- **Database ID**: [connection identifier, project ID, database name]
- **Schema**: [prisma|sql-migrations|sqflite|mongoose]
- **Migration Status**: [current|pending|upgrading]
- **Connection**: 
  - DEV: [connection string or method]
  - PROD: [production connection or auto-inject method]
- **Backup**: [auto-managed|manual|cloud-sync|not-required]
- **Seed Data**: [via migrations|app init|manual]
- **Admin URL**: [dashboard URL or N/A]

## Deployment

### 🌐 Frontend
- **URL Produzione**: [https://app.dominio.com o N/A]
- **URL Test/Staging**: [https://test-xxx.dominio.com o N/A]
- **Hosting**: [netlify|vps-nginx|github-pages|vercel|N/A]
- **Deploy Method**: [github-actions|manual|auto-push]

### 📱 App Mobile (se applicabile)
- **APK Produzione**: [https://apps.dominio.com/downloads/app.apk o N/A]
- **APK Test**: [https://apps.dominio.com/downloads/test/ o N/A]
- **Build Method**: [github-actions|manual flutter build]
- **Distribuzione**: [VPS download|Play Store|direct install]

### ⚙️ Backend / API (se applicabile)
- **URL**: [https://api.dominio.com o N/A]
- **Hosting**: [vps-nginx|railway|render|supabase-functions|N/A]
- **Server**: [IP o hostname se VPS]

### 🗄️ Database
- **Provider**: [supabase-cloud|neon-cloud|postgresql-vps|sqlite-local|none]
- **Host**: [URL dashboard o IP server]
- **Database ID / Project**: [identificatore progetto]
- **Admin URL**: [https://supabase.com/dashboard/project/xxx o N/A]
- **Backup**: [auto-managed|manual|not-required]

### 🔄 CI/CD
- **Pipeline**: [github-actions|none]
- **Trigger**: [push to main|manual]
- **CI Status**: [passing|failing|pending]
- **Last Deploy**: [YYYY-MM-DDTHH:MM:SSZ]

### 🔑 Environment Variables
- `VARIABILE_1`: [descrizione — auto-injected via GitHub Secrets]
- `DATABASE_URL`: [fonte della connection string]
- [aggiungere tutte le variabili critiche]

## Repository
- **Main Branch**: [main|master|trunk]
- **Development Branch**: [feature branch name or N/A]
- **GitHub**: [https://github.com/account/repo]

## Tech Stack
- **Frontend**: [framework + major libraries]
- **Backend**: [runtime + framework + key libraries] 
- **Database**: [database type + provider]
- **Auth**: [authentication method]
- **Deployment**: [deployment stack]
- **Mobile**: [platform-specific if applicable]

## Services
- **Service 1**: [description and hosting method]
- **Service 2**: [e.g., frontend: Netlify static hosting]
- **Service 3**: [e.g., database: Supabase Cloud PostgreSQL]
- **Service 4**: [e.g., auth: JWT tokens + custom validation]
- [add all critical services]

## Monitoring
- **Health Check**: [endpoint URL or method]
- **Service Health**: [monitoring method]
- **Database Health**: [dashboard or check method]
- **Alerts**: [enabled|disabled|method]
- **Auto Deploy**: [true|false|method]

## Development
- **Local Setup**: 
  1. [step 1 - e.g., npm install]
  2. [step 2 - e.g., copy .env file]
  3. [step 3 - e.g., run migrations]
  4. [step 4 - e.g., start dev server]
- **Build Process**: 
  1. [step 1 - e.g., npm run build]
  2. [step 2 - e.g., flutter build apk --release]
  3. [step 3 - copy artifacts to releases/]
  4. [step 4 - deployment steps]

## Troubleshooting
- **Issue Type 1**: [diagnostic command or method]
- **Issue Type 2**: [e.g., backend logs: journalctl -u service-name -f]
- **Issue Type 3**: [e.g., database: check connection + dashboard]
- **Issue Type 4**: [e.g., SSL: certbot status]
- [add common troubleshooting scenarios]

## Testing
- **Framework**: [flutter_test|playwright|jest|vitest|none]
- **Unit/Widget Tests**: [flutter test|npm test|none]
- **Integration/E2E Tests**: [integration_test|playwright|cypress|none]
- **Test URL**: [https://test-xxx.dominio.com o APK: https://apps.xxx.org/downloads/test/]
- **Run Tests**: [comando per eseguire i test in locale]
- **Coverage**: [required|optional|none]

## Backlog
- **TODO**: [Task description - generic but informative]
- **TODO**: [Another planned feature]
- **IN PROGRESS**: [Current work items]
- **TODO**: [Future improvements]
- **DONE**: [Completed items for context]
- **DONE**: [Major completed milestones]
- **TODO**: [Additional roadmap items]

---
*Last Updated: YYYY-MM-DDTHH:MM:SSZ*
*Auto-generated from: https://app.8020solutions.org/status.html*
```

## 📋 Sezioni Obbligatorie

### **✅ MUST HAVE**
- **Project Info**: Nome, versione, status, descrizione
- **Deployment**: URL frontend, URL test, dove vive il DB, CI status
- **Repository**: Link GitHub, branch strategy  
- **Backlog**: TODO/IN PROGRESS/DONE items

### **✅ RECOMMENDED**  
- **Database**: Se il progetto usa persistence
- **Tech Stack**: Per development e maintenance context
- **Services**: Per understanding architettura
- **Monitoring**: Per operational readiness

### **⚡ OPTIONAL**
- **Development**: Se setup complesso
- **Troubleshooting**: Per progetti production-critical

## 🎯 Best Practices

### **🔒 Privacy & Security**
- ✅ **Descrizioni vaghe** ma professionali
- ✅ **No client names** o location specifiche  
- ✅ **No credenziali** o info sensibili
- ✅ **Generic business terms** invece di dettagli specifici

### **📊 Version Management**
- ✅ **Semantic versioning**: v1.2.3 format
- ✅ **Update ad ogni release**: Automated via commit skin
- ✅ **Timestamp consistency**: ISO format UTC
- ✅ **Status alignment**: Dev → staging → production

### **📝 Documentation Quality**
- ✅ **Clear e concisa**: Informative ma non verbose
- ✅ **Actionable info**: Commands e link funzionanti
- ✅ **Consistent format**: Seguire template esatto
- ✅ **Regular updates**: Ad ogni commit significativo

## 🤖 Automation Integration

### **Commit Skin Automation**
Il commit skin aggiorna automaticamente:
- **Version**: Auto-increment basato su commit type
- **Last Deploy**: Timestamp quando build completato
- **Status**: Update basato su branch (dev/prod)
- **Backlog**: Move items tra TODO/IN PROGRESS/DONE

### **Status Dashboard Sync**  
Il system legge PROJECT.md ogni 30min e genera:
- **Tabella status**: Con tutti i progetti
- **Modal popup**: Con dettagli completi per ogni progetto
- **Health indicators**: Basato su CI status e deploy info
- **Navigation**: Link diretti a repo e live URLs

### **Validation Hooks**
Pre-commit checks:
- ✅ **PROJECT.md exists**: Must be present
- ✅ **Required fields**: Nome, versione, description
- ✅ **Valid format**: Markdown structure correct  
- ✅ **Version consistency**: Align con package.json/pubspec.yaml
- ✅ **Links working**: GitHub URL reachable

## 📖 Examples

### **Web App Example**
```yaml
Name: Dashboard Analytics  
Platforms: web
Tech Stack: React + Vite + TypeScript
Database: PostgreSQL via Neon Cloud
Deploy: VPS nginx + SSL
```

### **Mobile App Example**
```yaml
Name: Assistant Mobile
Platforms: apk, ios  
Tech Stack: Flutter + Dart + SQLite
Database: sqlite-local + cloud sync
Deploy: GitHub releases APK
```

### **Static Site Example**
```yaml
Name: Marketing Site
Platforms: web
Tech Stack: HTML + CSS + JS
Database: none
Deploy: Netlify static hosting
```

---

**Remember**: PROJECT.md è il **Single Source of Truth** per ogni progetto.  
Deve essere **sempre aggiornato** e **accurato** per il corretto funzionamento dell'intero workflow di team.