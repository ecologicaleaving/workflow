# Skill: prd-to-issues

**Trigger:** `/prd-to-issues` o Davide chiede di creare le issue da un PRD  
**Agente:** Claudio  
**Versione:** 1.0.0  
**Dipendenza:** PRD già creato (skill `create-prd`)

---

## Obiettivo

Leggere un PRD e generare un set completo di issue GitHub strutturate, con dipendenze e ordine di implementazione. Le issue vanno sulla **repo del progetto** (non su workflow).

---

## Procedura

### Step 0 — Carica il PRD

1. Identifica la repo del progetto
2. Leggi il PRD (`docs/PRD.md` o file indicato da Davide)
3. Leggi il PROJECT.md per contesto tecnico
4. Se non trovi il PRD → chiedi a Davide dove sta

### Step 1 — Breakdown in Fasi

Analizza il PRD e proponi un breakdown in **fasi logiche** (macro-aree):

```
📋 Breakdown PRD: {nome progetto}

🔹 Fase 1 — {nome} (setup/fondamenta)
   Descrizione breve di cosa copre

🔹 Fase 2 — {nome} (core feature A)
   Descrizione breve

🔹 Fase 3 — {nome} (core feature B)
   Descrizione breve

🔹 Fase 4 — {nome} (polish/integrazione)
   Descrizione breve

📊 Totale stimato: ~N issue
⏭️ Approvi questa struttura o vuoi modificare?
```

**Criteri per le fasi:**
- Ogni fase è **autonoma e deployabile** dove possibile
- Le fasi seguono un ordine logico (fondamenta → core → polish)
- Fase 1 è sempre setup/scaffolding se progetto nuovo

**Aspetta approvazione** di Davide prima di procedere.

### Step 2 — Dettaglio issue per fase

Per ogni fase approvata, proponi le issue singole:

```
🔹 Fase 1 — {nome}

  📌 Issue 1.1: {titolo}
     Tipo: feature
     Obiettivo: {una riga}
     AC principali: {lista breve}
     Dipende da: nessuna

  📌 Issue 1.2: {titolo}
     Tipo: feature
     Obiettivo: {una riga}
     AC principali: {lista breve}
     Dipende da: #1.1

🔹 Fase 2 — {nome}

  📌 Issue 2.1: {titolo}
     ...
     Dipende da: Fase 1 completata
```

**Per ogni issue proposta include:**
- Titolo chiaro (formato: `feature: titolo descrittivo`)
- Tipo (feature / improvement)
- Obiettivo in una riga
- 2-4 AC principali (non serve il dettaglio completo — lo farà `create-issue`)
- Dipendenze esplicite (da quali issue dipende)

**Aspetta approvazione** di Davide. Può:
- ✅ Approvare tutto
- ✏️ Modificare singole issue
- ➕ Aggiungere issue mancanti
- ❌ Rimuovere issue non necessarie
- 🔄 Cambiare ordine/dipendenze

### Step 3 — Creazione batch su GitHub

Dopo approvazione, crea le issue in ordine (rispettando le dipendenze per avere i numeri giusti):

Per ogni issue:

```bash
# Crea la issue con template feature (corpo completo)
gh issue create \
  --repo ecologicaleaving/{repo} \
  --title "{tipo}: {titolo}" \
  --body "$(cat <<'BODY'
## 🎯 Obiettivo

{obiettivo}

---

## 📋 Contesto

{contesto dal PRD — sezione rilevante}

**Riferimento PRD:** docs/PRD.md — Sezione {N}

---

## ✅ Acceptance Criteria

- [ ] {AC 1}
- [ ] {AC 2}
- [ ] {AC 3}

---

## 🔧 Note Tecniche

{file rilevanti, vincoli, dipendenze tecniche}

---

## 🔗 Dipendenze

{lista issue da cui dipende, es: "Richiede completamento di #1, #2"}
{oppure "Nessuna — può partire subito"}

---

## 📌 Fase

Fase {N} — {nome fase} (da PRD breakdown)

---

## 📌 Checkpoint Obbligatori

- [ ] **CP1 — Piano** → Agente riporta piano + task checklist prima di scrivere codice
- [ ] **CP2 — Implementazione** → Report dopo ogni iterazione
- [ ] **CP3 — Test Suite** → Risultati completi lint / typecheck / unit / e2e
- [ ] **CP4 — Pronto per push** → AC verificati, PROJECT.md aggiornato

---

## 📝 Task Checklist

<!-- Compilata dall'agente nella fase di piano — NON riempire prima -->

---

## 📦 Info Issue

- **Repo:** ecologicaleaving/{repo}
- **Tipo:** {tipo}
- **Agente:** {da assegnare}
- **Branch:** `feature/issue-{N}-{slug}`
BODY
)"
```

Dopo ogni issue creata, aggiungi al Kanban:
```bash
gh project item-add 2 --owner ecologicaleaving --url {issue_url}
```

### Step 4 — Cross-reference dipendenze

Dopo aver creato tutte le issue (ora hai i numeri reali), aggiorna i campi "Dipendenze" con i numeri issue corretti:

```bash
# Per ogni issue che ha dipendenze, aggiorna il body
# Sostituisci i riferimenti placeholder con i numeri reali
gh issue edit {N} --repo ecologicaleaving/{repo} --body "{body aggiornato}"
```

### Step 5 — Report finale a Davide

```
✅ Issue create dal PRD: {nome progetto}

📊 Riepilogo:
- Totale issue: {N}
- Fasi: {N}

🔹 Fase 1 — {nome}
   #1 {titolo} 
   #2 {titolo} → dipende da #1
   
🔹 Fase 2 — {nome}
   #3 {titolo} → dipende da Fase 1
   #4 {titolo} → dipende da #3

📋 Tutte in Backlog sul Kanban

⏭️ Ordine consigliato di implementazione:
1. #1 → #2 (Fase 1 — possono partire subito)
2. #3 → #4 (Fase 2 — dopo Fase 1)
...

Dimmi quale issue vuoi avviare per prima!
```

---

## Regole

- **Issue sulla repo del progetto** — mai su `ecologicaleaving/workflow`
- **Non creare issue prima dell'approvazione** del breakdown E del dettaglio
- **Ogni issue deve essere autosufficiente** — un agente deve poterla lavorare leggendo solo quella + il codebase
- **Referenzia il PRD** nel corpo dell'issue — l'agente deve sapere dove trovare il contesto ampio
- **Rispetta le dipendenze** — non mettere come "pronta" un'issue che richiede lavoro precedente
- **Non assegnare label agente** di default — lo decide Davide issue per issue (o in blocco)
- **Granularità giusta** — ogni issue = 1 branch = 1 PR. Se una issue richiederebbe 3 PR, spezzala
- **La sezione Task Checklist resta vuota** — la compila l'agente nella fase di piano
- **Max ~15 issue per PRD** — se ne servono di più, probabilmente il PRD copre troppo. Suggerisci di spezzare in più PRD

---

## Gestione casi particolari

### Issue infra/VPS
Se dal PRD emergono task infrastrutturali (setup DB, DNS, certificati SSL, nginx config):
- Creale come issue separate con label `agent:ciccio`
- Mettile in Fase 1 (setup) con priorità alta
- Nota: queste le lavora Ciccio, non Claude Code

### Progetto nuovo senza repo
Se la repo non esiste ancora:
1. Avvisa Davide: "La repo non esiste. Creiamola prima."
2. Suggerisci: `/prepara-repo {nome}` 
3. Solo dopo: procedi con la creazione issue

### Modifiche al PRD durante il breakdown
Se durante la discussione emergono cambiamenti al PRD:
1. Annota le modifiche
2. Dopo approvazione issue, aggiorna anche `docs/PRD.md` con le decisioni prese
3. Commit: `docs: aggiorna PRD con decisioni dal breakdown`
