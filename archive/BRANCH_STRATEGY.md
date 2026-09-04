# BRANCH_STRATEGY.md - Git Workflow Strategy

**Strategia di branching standardizzata per 80/20 Solutions**

## 🎯 Overview

Utilizziamo un **simplified Git Flow** ottimizzato per small team con AI-assisted development e deployment automatici.

```mermaid
graph LR
    A[origin/main] --> B[worktree: feature/...]
    B --> C[Develop & Test]
    C --> D[Update PROJECT.md]
    D --> E[Commit & Push]
    E --> F[CI auto-deploy su test]
    F --> G[/approva di Davide → Merge]
```

## 🌿 Branch Types

### **📦 main/master** - Production Branch
- **Purpose**: Codice pronto per production
- **Protection**: Protected branch, require PR per changes
- **Deploy**: Auto-deploy via CI al merge su main/master
- **Naming**: `main` per nuovi progetti, `master` per esistenti

### **⚡ feature/** - Feature Development  
- **Purpose**: Sviluppo new features
- **Lifetime**: Temporary, deleted dopo merge
- **Naming**: `feature/descrizione-breve`
- **Examples**:
  ```bash
  feature/user-authentication
  feature/dark-mode-ui
  feature/ai-integration-phase2
  ```

### **🐛 fix/** - Bug Fixes
- **Purpose**: Correzione bug specifici
- **Lifetime**: Temporary, deleted dopo merge  
- **Naming**: `fix/descrizione-problema`
- **Examples**:
  ```bash
  fix/login-timeout-issue  
  fix/database-connection-error
  fix/ui-responsive-mobile
  ```

### **🚑 hotfix/** - Critical Production Fixes
- **Purpose**: Fix urgenti in production
- **Lifetime**: Very short, immediate merge
- **Naming**: `hotfix/descrizione-critica`
- **Priority**: Highest priority, immediate attention

### **📚 docs/** - Documentation Only
- **Purpose**: Solo modifiche documentazione
- **Lifetime**: Short, quick merge
- **Naming**: `docs/descrizione-update`

## 🔄 Standard Workflow

### **1. 🚀 Start New Feature (worktree isolato)**

> ⚠️ **Mai `checkout -b` nella working dir condivisa.** Più agenti/sessioni possono lavorare in parallelo sulla stessa repo: nella dir condivisa le modifiche non committate vengono "risucchiate" dai commit di altri agenti. Crea sempre il branch in un **worktree isolato** basato su `origin/<default-branch>` aggiornato. I subagenti developer vanno spawnati con `isolation: worktree` (l'harness gestisce creazione e cleanup).

```bash
# Aggiorna i riferimenti remoti (NON serve checkout nella dir condivisa)
git fetch origin

# Crea il branch in un worktree isolato, basato su origin/<default-branch>
git worktree add ../<repo>-wt-<slug> -b feature/my-new-feature origin/main

# Lavora DENTRO il worktree...
# Nota: il worktree non eredita node_modules (gitignored). Per build/typecheck
# crea una junction verso il node_modules del repo principale, e rimuovila con
# `rmdir` (non Remove-Item ricorsivo) PRIMA di `git worktree remove`.
```

### **2. 👨‍💻 Development Process**
```bash
# Regular commits during development
git add .
git commit -m "feat: implement user authentication logic"

# The commit skin automatically:
# - Updates PROJECT.md version
# - Builds project artifacts  
# - Stages release files
# - Enhances commit message
```

### **3. 🔄 Push → deploy automatico su test**
```bash
# Push del branch dal worktree
git push -u origin feature/my-new-feature

# La CI builda e deploya automaticamente su test-*.8020solutions.org
# Poi apri la PR: gh pr create
```

### **4. ✅ Testing & Approval**
- La CI deploya su test automaticamente dopo il push
- Davide testa su test e approva con `/approva` (o `/reject` con feedback)
- Eventuali fix: commit aggiuntivi sul branch feature (nel worktree)

### **5. 🎯 Merge to Production**
```bash
# Solo dopo /approva di Davide. Merge via GitHub:
gh pr merge <PR_N> --merge   # oppure --squash secondo convenzione del repo

# La CI deploya automaticamente in produzione al merge su main/master.

# Pulizia worktree + branch
git worktree remove ../<repo>-wt-<slug>
git push origin --delete feature/my-new-feature
```

## 🚀 Deploy Workflow Integration

### **🧪 Test Deployments**
- **Trigger**: Push del branch feature → CI automatica
- **Environment**: test-*.8020solutions.org subdomain  
- **Purpose**: Validation before production
- **Lifetime**: Temporary, cleaned up after merge

### **🌐 Production Deployments**  
- **Trigger**: Merge su main/master (dopo `/approva`) → CI automatica
- **Environment**: Production URLs (live domains)
- **Approval**: Richiede `/approva` esplicito di Davide
- **Process**: 
  1. La CI parte sul push a main/master
  2. Build e deploy automatici
  3. Smoke test post-deploy (`tests/curl-tests.sh`)
  4. Notifica esito (build-log)

## 📋 Branch Protection Rules

### **Main/Master Branch**
- ✅ **Require pull request reviews**: approvazione di Davide (`/approva`)
- ✅ **Dismiss stale reviews**: When new commits pushed
- ✅ **Require status checks**: CI must pass
- ✅ **Require up-to-date branches**: Must be current with main
- ✅ **Include administrators**: Rules apply to everyone

### **Feature Branches**  
- ✅ **No protection**: Freedom for rapid development
- ✅ **CI checks**: Optional but recommended
- ✅ **Merge**: solo l'Agente mergia, e solo dopo `/approva` di Davide

## 🎭 Role-Specific Workflows

### **🤖 Agente / Claudio (orchestratore)**
1. **Crea il branch feature** da `origin/<default>` in un **worktree isolato**
2. **Delega l'implementazione** a un subagente developer (`isolation: worktree`)
3. **Spinge il branch** → la CI deploya su test in automatico
4. **Apre la PR** e monitora la CI; itera sui feedback di Davide
5. **Mergia in main** solo dopo `/approva`, poi pulisce worktree e branch

### **🎯 Davide (Product Owner)**
1. **Testa i deploy su test** e approva con `/approva` (o `/reject` con motivo)
2. **Approva i deploy in produzione** (il merge avviene solo col suo ok)
3. **Crea GitHub Issues** per nuovi requisiti
4. **Decisioni strategiche** su branch (release, hotfix) ed esegue le azioni infra VPS elencate dall'Agente

## 📊 Branch Naming Conventions

### **✅ Good Branch Names**
```bash
feature/user-authentication
feature/ai-integration-phase3
feature/mobile-responsive-ui

fix/login-timeout-error  
fix/database-connection-retry
fix/payment-gateway-validation

hotfix/critical-security-patch
hotfix/production-database-error

docs/api-documentation-update
docs/deployment-guide-revision
```

### **❌ Avoid These Names**
```bash
❌ dev, development, test
❌ claudio-work, temp-branch  
❌ feature-1, fix-bug
❌ working-branch, latest-changes
```

## 🔧 Git Configuration

### **Recommended Git Config**
```bash
# Set up conventional commit template
git config commit.template ~/.gitmessage

# Auto-setup tracking for new branches
git config push.autoSetupRemote true

# Use rebase for cleaner history
git config pull.rebase true

# Better merge conflict markers
git config merge.conflictstyle diff3
```

### **Commit Message Template** (~/.gitmessage)
```
# <type>[optional scope]: <description>
#
# [optional body]
#
# [optional footer(s)]
#
# Types: feat, fix, docs, style, refactor, test, chore
# Breaking changes: add ! after type or BREAKING CHANGE: in footer
```

## 🚨 Emergency Procedures

### **🚑 Hotfix Process**
1. **Create hotfix branch** from main immediately
2. **Implement critical fix** with minimal changes
3. **Test thoroughly** but quickly
4. **Deploy immediately** to production (bypass normal review)
5. **Notify stakeholders** of emergency deployment
6. **Document incident** and post-mortem

### **🔄 Rollback Process**  
1. **Identify problematic commit** in main
2. **Create revert commit**:
   ```bash
   git revert <commit-hash>
   git push origin main
   ```
3. **Emergency deploy** reverted state
4. **Investigate root cause** in separate branch
5. **Fix and re-deploy** when ready

## 📈 Metrics & KPIs

### **Branch Health Metrics**
- **Feature branch lifetime**: Target <1 week
- **Time to merge**: Target <24h after completion  
- **Failed merges**: Target <5% merge conflicts
- **Hotfix frequency**: Target <1 per month

### **Deploy Success Rate**
- **Test deployments**: Target >95% success  
- **Production deployments**: Target >99% success
- **Rollback rate**: Target <2% of deployments
- **Deploy time**: Target <10min for standard deploys

---

**Best Practices**:
- ✅ **Lavora sempre in worktree isolato** da `origin/<default>` (mai `checkout -b` nella working dir condivisa)
- ✅ Keep feature branches **small and focused**
- ✅ **Update PROJECT.md** before every significant commit
- ✅ **Test locally** before pushing
- ✅ **Clean up branches** after successful merge (incluso `git worktree remove`)