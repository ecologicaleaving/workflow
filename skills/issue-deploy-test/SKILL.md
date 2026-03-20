# Skill: issue-deploy-test

**Trigger:** Davide autorizza il deploy in test (dopo PR in Test)  
**Agente:** Ciccio  
**Versione:** 2.0.0

---

## Obiettivo

Deployare il branch della issue sull'ambiente test e notificare Davide con il link per testare.

---

## Procedura

### Step 1 — Recupera info dalla PR

```bash
# Trova la PR aperta per la issue
gh pr list --repo ecologicaleaving/<repo> --state open \
  --json number,headRefName,url | jq '.[] | select(.headRefName | contains("issue-N"))'
```

### Step 2 — Pull branch e build

```bash
cd /var/www/<repo>
git fetch origin feature/issue-N-slug
git checkout feature/issue-N-slug
git pull origin feature/issue-N-slug

# Build in base al tipo di progetto
# Flutter web:
# flutter build web --release

# Node/React:
# npm install && npm run build

# Copia in webroot test
```

### Step 3 — Deploy su test

Il sottodominio test segue il pattern: `test-<repo>.8020solutions.org`

```bash
# Esempio per app web
cp -r build/ /var/www/test-<repo>/
nginx -s reload
```

### Step 4 — Aggiorna label

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --add-label "deployed-test"
```

### Step 5 — Notifica Davide

```
🧪 [Issue #N] Deploy test ok
🔗 https://test-<repo>.8020solutions.org
📋 Cosa testare:
  - <AC 1>
  - <AC 2>
  - <AC 3>
```

---

## Note

- Il deploy test non modifica mai la produzione
- Se il build fallisce → notifica Claudio che notifica Davide
- Ambiente test può essere sovrascritto da deploy successivi
