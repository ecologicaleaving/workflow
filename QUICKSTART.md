# QUICKSTART.md - Setup Immediato

**Guida rapida per iniziare con i workflow 80/20 Solutions**

## 🚀 Per Claude Code (Developer)

### **1-Click Installation**
```bash
# Nel tuo progetto (root directory):
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-commit-automation.sh | bash
```

### **Cosa fa l'automation:**
✅ **Auto-update PROJECT.md** con versione e timestamp  
✅ **Auto-build** Flutter APK, web apps, static sites  
✅ **Auto-package** artifacts in releases/ directory  
✅ **Semantic versioning** basato su conventional commits  

### **Uso giornaliero:**
```bash
# Normal commit diventa automatizzato:
git add .
git commit -m "feat: add new user dashboard"

# L'automation automaticamente:
# 1. Aggiorna PROJECT.md (v1.2.0 → v1.3.0)
# 2. Build del progetto (flutter build apk --release)  
# 3. Copia in releases/ (myapp-v1.3.0.apk)
# 4. Stage tutto per il commit
# 5. Push ready per Ciccio deploy
```

## 🧠 Per Ciccio (Orchestrator)

### **Dashboard Monitoring**
- **Status**: https://app.8020solutions.org/status.html
- **Auto-sync**: Ogni 30min da PROJECT.md files
- **Projects**: 5 progetti attivi con modal popup dettagli

### **Workflow Standardizzato:**
1. **Ricevi richiesta** da David via Telegram
2. **Delega sviluppo** a Claudio via sessions_send
3. **Monitor progress** via dashboard e GitHub activity
4. **Deploy su richiesta** da releases/ artifacts  
5. **Report risultati** a David con URL live

## 🎯 Per David (Product Owner)

### **Quick Task Delegation**
```
Messaggio Telegram a Ciccio:
"Nuovo feature: implementa dashboard analytics per Maestro. 
Priority: alta. Timeline: 3 giorni. 
Deploy su test environment per review."
```

### **Monitor Progress:**
- **Dashboard**: Status di tutti i progetti
- **GitHub Issues**: https://github.com/80-20Solutions/team-tasks
- **Direct updates**: Da Ciccio per milestone importanti

## 📋 Conventional Commits (Tutti)

### **Standard Format:**
```bash
<type>: <description>

# Examples:
feat: add user authentication system     # v1.2.0 → v1.3.0
fix: resolve database connection error   # v1.2.0 → v1.2.1  
feat!: redesign API (breaking change)   # v1.2.0 → v2.0.0
docs: update installation guide         # v1.2.0 → v1.2.1
```

### **Auto-versioning:**
| Commit Type | Version Impact |
|-------------|---------------|
| `feat:` | MINOR (+0.1.0) |
| `fix:` | PATCH (+0.0.1) |
| `feat!:` | MAJOR (+1.0.0) |

## 🔄 Git Workflow (Simple)

### **Feature Development:**
```bash
git checkout -b feature/my-new-feature
# ... develop ...
git commit -m "feat: implement my feature"  # Skin auto-handles
git push origin feature/my-new-feature

# Request to Ciccio: "Deploy feature/my-new-feature to test"
# After approval: merge to main
```

### **Production Deploy:**
```bash
git checkout main
git merge feature/my-new-feature
git push origin main

# Notify Ciccio: "Deploy main to production"  
```

## 📖 Full Documentation

Per approfondimenti:

- **[WORKFLOW_CICCIO.md](./WORKFLOW_CICCIO.md)** - Orchestrator procedures
- **[WORKFLOW_CLAUDIO.md](./WORKFLOW_CLAUDIO.md)** - Developer workflow + commit skin
- **[WORKFLOW_DAVID.md](./WORKFLOW_DAVID.md)** - Product Owner strategic workflow
- **[PROJECT_MD_TEMPLATE.md](./PROJECT_MD_TEMPLATE.md)** - Standard documentation
- **[COMMIT_CONVENTIONS.md](./COMMIT_CONVENTIONS.md)** - Commit message standards
- **[BRANCH_STRATEGY.md](./BRANCH_STRATEGY.md)** - Git branching strategy

## 🆘 Quick Help

### **Claudio Issues:**
```bash
# Automation not working?
cat .commit-automation/commit.log

# Reinstall automation:  
rm -rf .commit-automation .git/hooks/pre-commit
curl -sSL https://raw.githubusercontent.com/ecologicaleaving/workflow/master/scripts/install-commit-automation.sh | bash

# Test installation:
git add . && git commit -m "test: automation functionality check"
```

### **Ciccio Issues:**
```bash  
# Project not syncing?
cd /root/scripts && node project-sync.js

# Status dashboard not updating?
systemctl restart openclaw-gateway
curl https://app.8020solutions.org/status.html
```

### **David Issues:**
- **Task not progressing**: Direct message Ciccio su Telegram
- **Deploy request**: "Ciccio, deploy [project] to [environment]"
- **Urgent issues**: Phone call per critical problems

## 🎯 Success Criteria

### **Week 1: Installation & Basic Usage**
- [ ] Claude Code: Commit automation installato su tutti i progetti attivi
- [ ] Ciccio: Dashboard monitoring funzionante  
- [ ] David: Task delegation diretto a Claude Code

### **Week 2: Full Workflow Adoption**
- [ ] Conventional commits utilizzati consistently
- [ ] PROJECT.md aggiornati automaticamente
- [ ] Deploy pipeline main → test → production
- [ ] Team communication via workflow standard

### **Week 3: Optimization & Metrics**
- [ ] Workflow metrics collection
- [ ] Process refinement basato su feedback
- [ ] Documentation updates e improvements
- [ ] Training e onboarding materials

---

**🚀 Start Today**: Segui i 3 step per il tuo ruolo e inizia ad usare i workflow standardizzati!

**❓ Questions**: Aggiungi issue su GitHub o discuti nel team Telegram group.