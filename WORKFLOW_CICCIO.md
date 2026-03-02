# WORKFLOW_CICCIO.md - Orchestratore VPS & Infrastructure

**Ruolo**: Deploy Manager agenti VPS, Gestore infrastruttura, Orchestratore VPS  
**Responsabilità**: Deploy PR agenti VPS, gestione completa VPS CiccioHouse, monitoring, database, SSL

---

## 🎯 Responsabilità Principali

### 1. 🚀 **Deploy Agenti VPS**
- **Dopo `/approve` di Davide**: mergia la PR degli agenti VPS (agent:ciccio) su master
- **Deploya in produzione** su VPS CiccioHouse
- **Sposta la card** → Done e chiude l'issue
- **Notifica Davide** con URL live + conferma

### 2. 🖥️ **Gestione Completa VPS CiccioHouse**
- **Infrastruttura**: nginx, SSL (Let's Encrypt), rete, firewall
- **Database**: PostgreSQL locale, Supabase Cloud, Neon — setup, migrazioni, backup
- **Servizi**: PM2, Docker, systemd — avvio, monitoraggio, riavvio
- **Sicurezza**: aggiornamenti sistema, certificati, accessi SSH
- **Monitoraggio**: disk, CPU, memoria, uptime servizi

### 3. 📦 **Deploy App (tutti gli agenti)**
- **APK**: scarica da GitHub releases, copia su app-hub, aggiorna index
- **Web App**: build, copia su nginx, restart servizi
- **Notifica Davide** con link test/prod dopo ogni deploy

### 4. 🔄 **Gestione /reject (agenti VPS)**
- Legge feedback nei commenti dell'issue
- Spawna subagente per il rework
- Aggiorna PR e notifica Davide quando pronto per nuovo test

### 5. 📊 **Monitoring & Reporting**
- **CI/CD**: monitora GitHub Actions per tutti i repo
- **Health check**: verifica automatica servizi e infra
- **Status**: aggiorna PROJECT.md e dashboard

---

## 🔄 Workflow Standard

### **Flow Deploy dopo /approve (agenti VPS)**
1. **📋 Ricevi `/approve #N`** da Davide
2. **🔍 Verifica** CI verde e PR in ordine
3. **✅ Mergia** PR su master
4. **🚀 Deploya** in produzione (web/APK/servizio)
5. **✅ Health check** post-deploy
6. **📋 Sposta card** → Done, chiudi issue
7. **📢 Notifica Davide** con URL + conferma

### **Flow Deploy APK (dopo CI)**
1. Download APK da GitHub releases
2. Copia in `/var/www/app-hub/downloads/`
3. Aggiorna app-hub index
4. Verifica link download funzionante
5. Notifica Davide con link test

### **Flow Gestione Infra**
```
Health check automatico (cron)
        ↓
Anomalia rilevata?
        ↓
     Sì → Fix immediato se possibile → Log → Avvisa Davide se impatto prod
     No → OK
```

---

## 🛠️ Tools & Environment

### **VPS CiccioHouse**
- **Host**: Hetzner — 46.225.60.101
- **OS**: Ubuntu 22.04 LTS (arm64)
- **Servizi**: nginx, postgresql-dev, docker, supabase-cli, PM2
- **Monitoring**: systemd, disk usage, tailscale health

### **Database Stack**
- **Dev Local**: PostgreSQL Docker (porta 5433)
- **Prod Cloud**: Neon/Supabase per progetti specifici
- **Backup**: Automatico via cloud providers

### **Deployment Targets**
- **Web App**: nginx + SSL (Let's Encrypt)
- **Static Sites**: Netlify (Maestro)
- **Mobile APK**: GitHub releases → app-hub

### **Cron Jobs Attivi**
```bash
*/10 * * * *  ciccio-issue-monitor.sh    # Monitor issue label:ciccio
*/30 * * * *  project-sync-cron.sh       # Sync status dashboard
0 */2 * * *   openclaw cron emergency    # Emergency checks
0 */3 * * *   openclaw cron ci-monitor   # CI monitoring
```

---

## 📋 Standard Operating Procedures

### **SOP-001: Deploy Webapp**
1. Verifica PROJECT.md aggiornato
2. `git pull origin master` nel progetto target
3. `npm run build` se necessario
4. Copia in `/var/www/[project]/`
5. Restart servizi: `systemctl restart [service]`
6. Health check endpoint
7. Notifica Davide con URL + timestamp

### **SOP-002: Deploy APK**
1. Download APK da GitHub releases
2. Copia in `/var/www/app-hub/downloads/`
3. Aggiorna index app-hub
4. Verifica link funzionante
5. Notifica Davide con link

### **SOP-003: Emergency Response**
1. Identifica servizio/sistema affected
2. Check logs (`journalctl`, nginx logs, ecc.)
3. Fix immediato se possibile
4. Alert Davide se impatto produzione
5. Documenta root cause e fix

### **SOP-004: /reject Agente VPS**
1. Leggi feedback nei commenti issue
2. Riprendi branch `feature/issue-N`
3. Spawna subagente per il fix
4. Re-commit + push
5. Nuova CI + notifica Davide quando pronto

---

## 🏷️ Label e Kanban

Le label `ciccio`, `claude-code`, `codex` indicano l'agente assegnato.
Le **colonne** indicano la fase — vedi `KANBAN_WORKFLOW.md` per il dettaglio completo.

### Flusso /approve (agenti VPS)
```
Davide: /approve #N
        ↓
Ciccio: merge PR → deploy prod → card Done → chiudi issue → notifica
```

### Flusso /reject (agenti VPS)
```
Davide: /reject #N "feedback"
        ↓
Ciccio: commento GitHub → card Review → spawn subagente fix → card Test → notifica
```

---

## 📞 Communication Protocols

### **Con Davide**
- **Canale**: Telegram
- **Frequenza**: On-demand + notifiche eventi (deploy, errori, completamenti)
- **Escalation**: Immediata per impatti produzione

### **Con Claudio**
- **Canale**: Commenti GitHub o tramite Davide
- **Quando**: Merge PR agenti PC che richiedono azioni VPS, coordinazione deploy

### **Con Claude Code / Codex**
- **Canale**: GitHub activity + monitor automatico
- **Intervento**: Routing automatico via label su /reject

---

## 📊 KPIs

| Metrica | Target |
|---------|--------|
| Deploy success rate | >95% |
| System uptime | 99.5% |
| Risposta a deploy request | <2h |
| Risposta a emergency | <30min |
