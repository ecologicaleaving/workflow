# Node.js / API — Regole di Implementazione

## Test

### Jest / Vitest
```ts
describe('ExpenseService', () => {
  it('calcola totale correttamente', () => {
    const total = calculateTotal([{ amount: 10 }, { amount: 20 }]);
    expect(total).toBe(30);
  });

  it('restituisce 0 con lista vuota', () => {
    expect(calculateTotal([])).toBe(0);
  });
});
```

### Comandi test
```bash
npm test              # tutti i test
npm test -- --watch   # watch mode
npm run lint          # ESLint
npm run typecheck     # tsc --noEmit
```

---

## Struttura API route

```ts
// Handler pulito: validazione → logica → risposta
export async function handler(req: Request, res: Response) {
  // 1. Validazione input
  const { amount, description } = req.body;
  if (!amount || typeof amount !== 'number') {
    return res.status(400).json({ error: 'amount is required and must be a number' });
  }

  // 2. Logica business (in service separato)
  try {
    const expense = await ExpenseService.create({ amount, description, userId: req.user.id });
    return res.status(201).json(expense);
  } catch (error) {
    logger.error('Failed to create expense', { error, userId: req.user.id });
    return res.status(500).json({ error: 'Internal server error' });
  }
}
```

---

## Regole generali

### Separazione responsabilità
```
routes/      → solo routing e validazione input
services/    → logica business
repositories/ → accesso DB
utils/       → funzioni pure riutilizzabili
```

### Gestione errori
```ts
// ❌ Silenzio su errori
try {
  await doSomething();
} catch (_) {}

// ✅ Log + risposta appropriata
try {
  await doSomething();
} catch (error) {
  logger.error('Context message', { error, ...relevantData });
  throw error; // o res.status(500)
}
```

### Async/await — evita callback hell
```ts
// ❌
fetchUser(id, (user) => {
  fetchExpenses(user.id, (expenses) => { ... });
});

// ✅
const user = await fetchUser(id);
const expenses = await fetchExpenses(user.id);
```

### Variabili d'ambiente
```ts
// ❌ Hardcoded
const url = 'https://mysupabase.supabase.co';

// ✅ Da env
const url = process.env.SUPABASE_URL;
if (!url) throw new Error('SUPABASE_URL is required');
```

---

## Supabase Edge Functions

```ts
// supabase/functions/my-function/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { data, error } = await supabase.from('expenses').select('*');
  if (error) return new Response(JSON.stringify({ error }), { status: 500 });

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

---

## Checklist Node.js pre-commit

- [ ] `npm test` → tutti verdi, nessuna regressione
- [ ] `npm run lint` → zero errori
- [ ] Nessun `console.log()` — usa logger configurato
- [ ] Tutte le variabili d'ambiente validate all'avvio
- [ ] Input utente validato prima della logica
- [ ] Errori loggati con contesto (mai silenzio)
- [ ] Logica business nei service, non negli handler
