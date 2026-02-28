---
name: Feature / Fix
about: Template standard per issue assegnate agli agenti
title: "[TIPO] Descrizione breve"
labels: ""
assignees: ""
---

## 🎯 Obiettivo
[Cosa deve fare questa feature/fix, in 2-3 righe. Niente ambiguità.]

## 📦 Contesto
- **Repo:** `nome-repo`
- **Branch:** `feature/issue-N-descrizione`
- **Progetto/App:** link o path rilevante
- **Stack:** (es. Next.js, Prisma, PostgreSQL)
- **Ambiente test:** https://test-xxx.dominio.com

## 🔧 Task
- [ ] Task 1
- [ ] Task 2
- [ ] Task N

## ✅ Acceptance Criteria
Ogni criterio deve essere verificabile autonomamente dal dev.

- [ ] AC1: [Comportamento atteso — es. "Il form mostra errore se email non valida"]
- [ ] AC2: ...
- [ ] AC3: ...

## 🧪 Testing
**Strumenti:** {tool_principale} · {tool_e2e}
**Ambiente:** {test_url}
**Comando:** `{run_command}`

Il dev deve scrivere ed eseguire i test prima di aprire la PR. Tutti i test devono essere verdi.

### Test da implementare / verificare

#### Unit / Widget test
```
{unit_test_example}
```

#### Integration / E2E test (se applicabile)
```
{e2e_test_example}
```

### Checklist test pre-PR
- [ ] `{run_command}` → tutti verdi
- [ ] Nessuna regressione su test esistenti
- [ ] Coverage mantenuta (se richiesta dal progetto)

## 🚫 Out of Scope
[Cosa NON deve essere toccato in questa issue]

## 📎 Riferimenti
- Issue correlate: #N
- Design: link figma/screenshot
- Docs: link rilevanti
