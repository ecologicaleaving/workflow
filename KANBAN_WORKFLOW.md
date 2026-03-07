# KANBAN_WORKFLOW.md - Flusso di Lavorazione

## 🗂️ Colonne del Board

| Colonna | Significato |
|---------|-------------|
| **Backlog** | Issue create ma non ancora pianificate |
| **Todo** | Pianificate, pronte per essere assegnate a un agente |
| **In Progress** | Agente al lavoro sul branch |
| **Test** | PR aperta + build disponibile — Davide testa sull'APK/app |
| **Rework** | Davide ha dato `/reject` — agente sta applicando il fix |
| **Review** | Fix completato dall'agente — Davide ricontrolla |
| **Deploy** | Davide ha dato `/approve` — Ciccio (VPS) o Claudio (PC) stanno deployando in prod |
| **Done** | Issue chiusa, in produzione |

---

## 🔄 Flusso Standard

```
Backlog → Todo → In Progress → Test
                                 ↓ /approve
                               Deploy → Done
                                 ↓ /reject
                              Rework → Review
                                ↑________|
                           (loop fino ad approvazione)
```

### Dettaglio fasi

**In Progress**
- L'agente crea il branch, sviluppa, fa i test e apre la PR
- La CI deve passare e i test devono essere verdi
- L'agente aggiorna PROJECT.md e fa il commit convenzionale

**→ Test**
- Trigger: PR aperta + build/APK disponibile sull'ambiente test
- Chi sposta: Claudio (agenti PC) o Ciccio (agenti VPS)
- Ciccio notifica Davide con APK + AC da verificare (vedi sezione sotto)
- Davide verifica manualmente sull'app

**→ Rework** (dopo `/reject`)
- Davide scrive `/reject #N "feedback"` — il feedback va nei commenti dell'issue
- Card → **Rework**, label `needs-fix` aggiunta (abbinata alla label agente)
- L'agente originale riprende il branch, applica il fix, aggiorna la PR
- Nuova build → card → **Review**

**→ Review** (agente ha finito il fix)
- Ciccio notifica Davide con APK + AC aggiornati
- Davide controlla: se ok → `/approve` → **Deploy**; se no → nuovo `/reject` → **Rework**
- Il loop Rework ↔ Review si ripete finché Davide non approva

**→ Deploy** (dopo `/approve`)
- Davide scrive `/approve #N`
- Claudio: merge PR degli agenti PC e segnala a Ciccio
- Ciccio: merge PR degli agenti VPS, deploya in prod, chiude l'issue

---

## 📲 Notifica Test Build (obbligatoria)

**SEMPRE**, quando una build di test è pronta (CI verde su PR), Ciccio invia a Davide:

```
✅ CI verde — PR #N: [titolo issue]
📦 APK: https://apps.8020solutions.org/downloads/test/[file].apk

AC da verificare:
- AC1: ...
- AC2: ...
```

**Come trovare APK:**
```bash
ls -t /var/www/app-hub/downloads/test/beachref-*[branch-slug]*.apk | head -1
```

**Come estrarre AC:**
```bash
gh issue view <N> --repo <owner/repo> --json body --jq '.body' | grep -A 20 "✅ Acceptance Criteria" | grep "^\- \["
```

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
| `needs-fix` | Rework richiesto (dopo /reject) — abbinare SEMPRE a label agente |

---

## 📋 Comandi Davide

| Comando | Effetto |
|---------|---------|
| `/approve #N` | Claudio mergia la PR (agenti PC) o Ciccio (agenti VPS) → Deploy → Done |
| `/reject #N "feedback"` | Card → Rework, feedback nei commenti, agente applica fix |

---

## ✅ Regole

1. **Ogni issue creata** va aggiunta al Kanban in colonna **Todo**:
   `gh project item-add 2 --owner ecologicaleaving --url <issue_url>`
2. **Mai pushare direttamente su master** — sempre branch → PR
3. **La card si sposta** insieme alla label — niente disallineamenti
4. **Build deve essere disponibile** prima di spostare in Test
5. **Notifica obbligatoria** a Davide con APK + AC ad ogni build di test pronta
