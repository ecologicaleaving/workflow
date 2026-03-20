# Skill: issue-done

**Trigger:** Agente completa implementazione e test (CP4 ok)  
**Agente:** Claudio  
**Versione:** 2.0.0

---

## Obiettivo

Verificare che tutto sia in ordine, aprire la PR, spostare la card in Test, notificare Davide e Ciccio per il deploy test.

---

## Procedura

### Step 1 — Checklist pre-PR

Claudio verifica prima di aprire la PR:

- [ ] Tutti gli AC della issue sono soddisfatti
- [ ] Nessun file anomalo (`.env`, config sensibili, file di debug)
- [ ] Codice consistente con il piano approvato
- [ ] Niente regressioni evidenti nei test
- [ ] `PROJECT.md` aggiornato (versione bumped, data, issue nella lista done)
- [ ] README / docs aggiornati se toccati dalla feature
- [ ] Convenzioni branch e commit rispettate
- [ ] Label issue corrette

Se manca qualcosa → rimanda all'agente con indicazioni precise prima di aprire la PR.

### Step 2 — Apri PR

```bash
gh pr create \
  --repo ecologicaleaving/<repo> \
  --title "feat: <titolo issue>" \
  --body "$(cat templates/pull_request_template.md | sed 's/N/<numero>/g')" \
  --head feature/issue-N-slug \
  --base master
```

Compila il body della PR con:
- Summary delle modifiche
- AC verificati (spuntati)
- File modificati principali
- Risultati test suite

### Step 3 — Aggiorna label issue

```bash
gh issue edit <N> --repo ecologicaleaving/<repo> \
  --remove-label "in-progress" \
  --add-label "review-ready"
```

### Step 4 — Sposta card → Test

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHODSTPQM4BP1Xp"
    itemId: "'$ITEM_ID'"
    fieldId: "PVTSSF_lAHODSTPQM4BP1Xpzg-INlw"
    value: { singleSelectOptionId: "1d6a37f9" }
  }) { projectV2Item { id } }
}'
```

### Step 5 — Notifica Davide

```
🔍 [Issue #N] PR pronta: <url>
📋 <summary di cosa è stato fatto in 2-3 righe>
✅ AC verificati: tutti ok
📌 Dimmi se e quando vuoi il deploy in test
```

### Step 6 — Notifica Ciccio

Claudio avvisa Ciccio via Telegram o commento issue:
```
Ciccio, issue #N pronta per deploy test quando Davide lo autorizza.
PR: <url> | Repo: <repo> | Branch: feature/issue-N-slug
```
