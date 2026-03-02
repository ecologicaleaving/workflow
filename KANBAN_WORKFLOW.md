# KANBAN_WORKFLOW.md - Flusso di Lavorazione

## 🗂️ Colonne del Board

| Colonna | Significato |
|---------|-------------|
| **Backlog** | Issue create ma non ancora pianificate |
| **Todo** | Pianificate, pronte per essere assegnate a un agente |
| **In Progress** | Agente al lavoro sul branch |
| **Test** | PR aperta + build disponibile — Davide testa sull'APK/app |
| **Review** | Davide ha dato `/reject` — agente sta rilavorando |
| **Deploy** | Davide ha dato `/approve` — Ciccio (VPS) o Claudio (PC) stanno deployando in prod |
| **Done** | Issue chiusa, in produzione |

---

## 🔄 Flusso Standard

```
Backlog → Todo → In Progress → Test
                                 ↓ /approve
                               Deploy → Done
                                 ↓ /reject
                               Review → (agente rilav ora) → Test
```

### Dettaglio fasi

**In Progress**
- L'agente crea il branch, sviluppa, fa i test e apre la PR
- La CI deve passare e i test devono essere verdi
- L'agente aggiorna PROJECT.md e fa il commit convenzionale

**→ Test**
- Trigger: PR aperta + build/APK disponibile sull'ambiente test
- Chi sposta: Claudio (agenti PC) o Ciccio (agenti VPS)
- Davide verifica manualmente sull'app

**→ Review** (dopo `/reject`)
- Davide scrive `/reject #N "feedback"` — il feedback va nei commenti dell'issue
- L'agente originale riprende il branch, applica il fix, aggiorna la PR
- Nuova build → torna in **Test**

**→ Deploy** (dopo `/approve`)
- Davide scrive `/approve #N`
- Claudio: merge PR degli agenti PC e segnala a Ciccio
- Ciccio: merge PR degli agenti VPS, deploya in prod, chiude l'issue

---

## 🏷️ Label

Le label indicano **chi** e **cosa** — non la fase (quella è la colonna).

| Label | Significato |
|-------|-------------|
| `claude-code` | Assegnata a Claude Code (PC) |
| `codex` | Assegnata a Codex (PC) |
| `ciccio` | Assegnata a Ciccio (VPS) |
| `bug` | Bug da correggere |
| `feature` | Nuova funzionalità |
| `review-ready` | PR aperta, pronta per review |
| `needs-fix` | Rework richiesto (dopo /reject) |

---

## 📋 Comandi Davide

| Comando | Effetto |
|---------|---------|
| `/approve #N` | Claudio mergia la PR (agenti PC) o Ciccio (agenti VPS) → Deploy → Done |
| `/reject #N "feedback"` | Card → Review, feedback nei commenti, agente rilav ora |

---

## ✅ Regole

1. **Ogni issue creata** va aggiunta al Kanban in colonna **Todo**:
   `gh project item-add 2 --owner ecologicaleaving --url <issue_url>`
2. **Mai pushare direttamente su master** — sempre branch → PR
3. **La card si sposta** insieme alla label — niente disallineamenti
4. **Build deve essere disponibile** prima di spostare in Test
