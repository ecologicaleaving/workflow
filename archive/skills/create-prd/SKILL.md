# Skill: create-prd

**Trigger:** `/create-prd` o Davide descrive un'idea per un progetto/feature grande  
**Agente:** Claude Code  
**Versione:** 1.0.0

---

## Obiettivo

Partire da un'idea o brief di Davide e, attraverso una conversazione strutturata, produrre:
1. **PRD completo** (`docs/PRD.md` nella repo del progetto)
2. **PROJECT.md base** (se progetto nuovo)

Il PRD sarà la fonte di verità per il `prd-to-issues` che genera le issue.

---

## Quando si usa

- **Progetto nuovo** da zero → produce PRD + PROJECT.md + suggerisce `/prepara-repo`
- **Feature grande** su progetto esistente → produce PRD, PROJECT.md già esiste

---

## Procedura

### Step 0 — Capire il contesto

Determina subito:
- **Progetto nuovo o esistente?**
- Se esistente: **quale repo?** Leggi il PROJECT.md per avere contesto
- Se nuovo: serve creare la repo prima (suggerisci `/prepara-repo` dopo il PRD)

### Step 1 — Raccolta rapida

**NON fare 20 domande.** Parti da quello che Davide ha già detto e fai domande solo su ciò che manca.

Informazioni da raccogliere (in ordine, una alla volta, saltando ciò che è già noto):

1. **Nome** → come si chiama il progetto/feature?
2. **Problema** → che problema risolve? per chi?
3. **Obiettivo** → cosa deve fare in una frase
4. **Target users** → chi lo usa, che livello tecnico
5. **Scenari principali** → 2-3 flussi utente chiave
6. **Requisiti must-have** → cosa DEVE fare assolutamente nell'MVP
7. **Out of scope** → cosa NON fa nella prima versione
8. **Tech stack** → (solo se progetto nuovo) preferenze tecnologiche

**Regola d'oro:** Se Davide dà una risposta che copre più punti, non richiederli singolarmente. Adatta.

### Step 2 — Proposta PRD

Quando hai abbastanza informazioni (non serve il 100% — l'80% basta):

1. Compila il template PRD (`templates/prd.md`) con le info raccolte
2. Presenta a Davide una **sintesi** (non il markdown intero — quello va nel file):
   ```
   📋 PRD: {nome}
   
   🎯 Obiettivo: {una riga}
   👥 Target: {chi lo usa}
   
   📌 Requisiti must-have:
   - F1: ...
   - F2: ...
   - F3: ...
   
   ❌ Out of scope:
   - ...
   
   🛠️ Stack: {tech stack}
   
   Approvi o vuoi modificare qualcosa?
   ```
3. Itera finché Davide non approva

### Step 3 — Scrivi i file

**Se progetto nuovo (repo non esiste ancora):**
1. Crea il PRD in locale: `workflow/output/prd-{nome}.md`
2. Crea il PROJECT.md in locale: `workflow/output/project-{nome}.md`
3. Notifica: "PRD e PROJECT.md pronti. Quando crei la repo li committamo."
4. Suggerisci: "Vuoi che prepari la repo con `/prepara-repo`?"

**Se progetto esistente (repo esiste):**
1. Clona/pull la repo se non in locale
2. Crea `docs/PRD.md` (o `docs/prd/{nome-feature}.md` se ci sono già PRD)
3. Commit: `docs: aggiungi PRD per {nome}`
4. Push sul branch principale

### Step 4 — PROJECT.md (solo progetto nuovo)

Compila il PROJECT.md dal template (`PROJECT_MD_TEMPLATE.md`) con:
- **Project Info** → nome, v0.1.0, status: development
- **Tech Stack** → da Step 1
- **Deployment** → placeholder da compilare dopo setup
- **Repository** → placeholder con owner `ecologicaleaving`
- **Backlog** → vuoto, lo popola `prd-to-issues`

**NON inventare** sezioni che non conosci (DB, hosting, secrets). Metti placeholder chiari tipo `[da definire]`.

### Step 5 — Conferma a Davide

```
✅ PRD creato: {percorso o url}
📌 {nome progetto/feature}

📄 File generati:
- PRD: {path}
- PROJECT.md: {path} (se nuovo)

⏭️ Prossimo step: `/prd-to-issues` per generare le issue dal PRD
   {oppure `/prepara-repo` se repo non esiste}
```

---

## Template di riferimento

- **PRD:** `templates/prd.md`
- **PROJECT.md:** `PROJECT_MD_TEMPLATE.md`

---

## Regole

- **Non chiedere ciò che sai già** — se Davide ha detto "app Flutter per gestire tornei di beach volley", hai già nome, stack, target e contesto
- **80/20** — non serve un PRD perfetto, serve un PRD utile. Meglio 80% subito che 100% mai
- **Non committare senza approvazione** — Davide deve vedere la sintesi prima
- **Sezioni opzionali del template** restano vuote se non rilevanti (timeline, metrics, diagrammi) — non forzare
- **Il PRD è un documento vivo** — si aggiorna quando emergono nuove info durante lo sviluppo
- **Non creare issue** — quello lo fa `prd-to-issues`. Qui si produce solo il documento
