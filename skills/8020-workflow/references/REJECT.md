# REJECT.md — Procedura /reject

## Trigger
Davide scrive: `/reject #<N> "feedback"`

## Procedura

1. **Aggiungi commento sulla issue GitHub** con il feedback completo
```bash
gh issue comment <N> --repo ecologicaleaving/<REPO> \
  --body "## 🔄 Rework richiesto\n\n**Feedback Davide:** <FEEDBACK>\n\n**Data:** $(date -u '+%Y-%m-%d %H:%M UTC')"
```

2. **Sposta card: `Test` → `Review`** (NON toccare le label)
→ Vedi `KANBAN.md` per il comando

3. **In base alla label agente:**
   - `agent:ciccio` → spawna subagente con feedback come contesto, lavora il fix
   - `agent:claude-code` → notifica Davide: "⚠️ Issue #N richiede fix da Claude Code — riaprire sessione con branch `feature/issue-N`"
   - `agent:codex` → trigger codex-monitor con contesto feedback

4. Quando fix completato → sposta card: `Review` → `Test`
5. Notifica Davide con nuovo APK/link test
