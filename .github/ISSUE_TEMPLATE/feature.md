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

## 🎭 Playwright Tests (se applicabile)
Il dev deve scrivere/eseguire questi test prima di aprire la PR.

```ts
// Esempio: test login fallito
test('mostra errore con credenziali errate', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name=email]', 'wrong@test.com');
  await page.fill('[name=password]', 'wrong');
  await page.click('button[type=submit]');
  await expect(page.locator('.error-message')).toBeVisible();
});
```

## 🚫 Out of Scope
[Cosa NON deve essere toccato in questa issue]

## 📎 Riferimenti
- Issue correlate: #N
- Design: link figma/screenshot
- Docs: link rilevanti
