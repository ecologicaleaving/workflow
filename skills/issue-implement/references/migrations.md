# Migrations — Gestione Migrazioni Supabase

## Struttura

```
supabase/
└── migrations/
    ├── 20260201120000_create_expenses.sql
    ├── 20260210083000_add_category_column.sql
    └── 20260301150000_add_rls_policies.sql
```

Il nome del file è `<timestamp>_<descrizione>.sql`. Il timestamp garantisce l'ordine di esecuzione.

---

## Comandi base

```bash
# Crea nuovo file migration (timestamp automatico)
supabase migration new <nome_descrittivo>

# Applica al DB locale
supabase db push

# Applica al DB remoto (produzione)
supabase db push --db-url <CONNECTION_STRING>

# Verifica stato migration applicate
supabase migration list
```

---

## Regole fondamentali

### 1. Mai modificare una migration già applicata
Supabase traccia ogni migration tramite checksum. Se modifichi un file già eseguito, il sistema va in errore (`checksum mismatch`) al prossimo `db push`.

**Se hai sbagliato:** crea una *nuova* migration che corregge.
```bash
supabase migration new fix_column_type_expenses
```

### 2. Forward-only — niente rollback automatico
Non esiste un meccanismo di rollback nativo. Se devi "tornare indietro", scrivi una migration di undo esplicita.

```sql
-- 20260302_undo_add_notes_column.sql
ALTER TABLE expenses DROP COLUMN IF EXISTS notes;
```

### 3. RLS obbligatoria su ogni nuova tabella
Senza Row Level Security, i dati sono accessibili a **chiunque** tramite l'API pubblica di Supabase.

```sql
-- Subito dopo ogni CREATE TABLE
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users see own data" ON expenses
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "family members see family data" ON expenses
  FOR SELECT USING (
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );
```

### 4. Una migration = una cosa sola
Non mescolare nello stesso file:
- ❌ `CREATE TABLE` + seed data
- ❌ Schema change + business logic
- ✅ Un file per ogni cambiamento strutturale

### 5. Niente dati nelle migration
Le migration modificano la **struttura**, non il contenuto. I seed data vanno in `supabase/seed.sql`.

```sql
-- ❌ Non fare questo in una migration
INSERT INTO categories (name) VALUES ('Alimentari'), ('Trasporti');

-- ✅ Mettilo in supabase/seed.sql
```

---

## Pattern SQL sicuri

### Idempotenza — usa sempre `IF NOT EXISTS / IF EXISTS`

```sql
-- Tabelle
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Colonne
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS notes TEXT;

-- Indici
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);

-- Drop
DROP TABLE IF EXISTS old_table;
ALTER TABLE expenses DROP COLUMN IF EXISTS legacy_field;
```

### Foreign keys con ON DELETE

```sql
-- CASCADE: elimina le righe figlie quando si elimina il padre
user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE

-- SET NULL: mantieni la riga figlia, metti null sul FK
category_id UUID REFERENCES categories(id) ON DELETE SET NULL

-- RESTRICT (default): impedisce l'eliminazione del padre se ha figli
```

### Indici per performance

```sql
-- Crea indice su colonne usate spesso nei WHERE o JOIN
CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_family_id ON expenses(family_id);
```

---

## Errori comuni degli agenti

| Errore | Conseguenza | Fix |
|---|---|---|
| Modifica file migration già applicato | Checksum mismatch → crash | Crea nuova migration correttiva |
| Dimentica `ENABLE ROW LEVEL SECURITY` | Dati esposti pubblicamente | Aggiungi migration con solo RLS |
| SQL non idempotente | Crash se rieseguita | Aggiungi `IF NOT EXISTS` |
| Migration con dati seed | Dati duplicati al re-run | Sposta in `seed.sql` |
| FK senza `ON DELETE` esplicito | Errori FK inaspettati in prod | Specifica sempre la strategia |
| Nessun indice su FK | Query lente su tabelle grandi | Aggiungi `CREATE INDEX` dopo ogni FK |

---

## Checklist migration pre-commit

- [ ] File creato con `supabase migration new` (timestamp corretto)
- [ ] SQL testato in locale con `supabase db push`
- [ ] `IF NOT EXISTS` su tutti i CREATE
- [ ] RLS abilitata se è una nuova tabella
- [ ] Nessun dato seed nel file migration
- [ ] Nessuna modifica a migration già esistenti
- [ ] Indici aggiunti per ogni FK e colonna usata in WHERE frequenti
