---
name: beachcrer-sync-group
description: >
  Verifica la corrispondenza tra il gruppo mail "arbitri beach" in Horde
  e l'elenco degli arbitri attivi in BeachCRER. Riporta discrepanze e
  offre di correggerle. Trigger: quando si vuole sincronizzare il gruppo
  mail con l'anagrafica BeachCRER.
---

# Skill: beachcrer-sync-group

**Trigger:** Quando vuoi verificare/sincronizzare il gruppo "arbitri beach" di Horde con BeachCRER
**Agente:** Claude Code (con accesso Chrome DevTools MCP)
**Progetto:** BeachCRER

---

## Obiettivo

Confrontare due sorgenti:
1. **BeachCRER** (source of truth) — arbitri con `stato = 'attivo'`
2. **Horde Rubrica** — gruppo `arbitri beach`

Riportare:
- Arbitri in BeachCRER ma **non nel gruppo** → da aggiungere
- Email nel gruppo ma **non in BeachCRER** (o stato inattivo) → da rimuovere
- Arbitri presenti in entrambi ma con **email diversa** → da aggiornare

---

## Step 1 — Recupera arbitri attivi da BeachCRER

```
GET https://beachcrer.8020solutions.org/api/supabase/rest/v1/referees?stato=eq.attivo&select=id,nome,cognome,email&order=cognome.asc
Headers:
  apikey: <SUPABASE_SERVICE_ROLE_KEY>
  Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
```

Leggi `SUPABASE_SERVICE_ROLE_KEY` da `.env.local` nella root del progetto BeachCRER.

Filtra: escludi email che contengono `@placeholder` o `@example`.

Costruisci un dizionario `{ email_normalizzata → {id, nome, cognome} }` (email in lowercase).

---

## Step 2 — Recupera membri gruppo Horde

Apri il browser (Chrome DevTools MCP) e naviga alla rubrica Horde:

```
https://webmail.fipavcrer.it/turba/
```

Cerca il gruppo "arbitri beach" → apri → leggi la lista dei contatti.

Alternativa via composizione: apri una nuova mail, digita "arbitri beach" nel campo CCN, aspetta l'autocomplete, leggi le email espanse dalla suggestion dropdown.

**Via JavaScript** (più affidabile se la composizione è già aperta):
```javascript
// Nel campo CCN della composizione Horde, dopo aver digitato "arbitri beach":
// Le email espanse appaiono nel suggestion dropdown come testo separato da virgole
document.querySelector('.hordeACResults li')?.textContent
```

Costruisci un set `horde_emails` (email in lowercase).

---

## Step 3 — Confronto

```
beachcrer_emails = set(email.lower() for email in arbitri_attivi if email is valid)
horde_emails = set(email.lower() for email in gruppo_horde)

da_aggiungere = beachcrer_emails - horde_emails      # in BeachCRER, non in Horde
da_rimuovere  = horde_emails - beachcrer_emails      # in Horde, non in BeachCRER
```

---

## Step 4 — Report

Stampa il risultato in questo formato:

```
=== SYNC: arbitri beach (Horde) ↔ BeachCRER ===

✅ In sincronia: N arbitri

➕ DA AGGIUNGERE al gruppo (N):
  - Nome Cognome <email@example.com>

➖ DA RIMUOVERE dal gruppo (N):
  - email@example.com  [motivo: non in BeachCRER / stato inattivo]

⚠️  EMAIL DISCORDANTI (N):
  - Nome Cognome: BeachCRER=nuova@email.com | Horde=vecchia@email.com
```

---

## Step 5 — Correzioni (solo su richiesta esplicita di Davide)

### Aggiungere al gruppo
Apri Horde Rubrica → gruppo "arbitri beach" → "Aggiungi contatto" → inserisci nome + email.

### Rimuovere dal gruppo
Apri il gruppo → seleziona il contatto → "Elimina da questa lista".

### Aggiornare email in BeachCRER
```
PATCH https://beachcrer.8020solutions.org/api/supabase/rest/v1/referees?id=eq.<UUID>
Body: {"email": "nuova@email.com"}
```

### Aggiornare email nel gruppo Horde
Apri il contatto nel gruppo → modifica campo email → salva.

---

## Note operative

- **Source of truth**: BeachCRER è autoritativo. Se c'è discrepanza, la BeachCRER va bene e Horde va allineato.
- **Eccezione**: se Davide dice che l'email di BeachCRER è vecchia, aggiorna prima BeachCRER poi Horde.
- Dopo ogni modifica al gruppo, aggiorna la bozza CCN della mail (rimuovi vecchio chip, reinserisci gruppo fresco).
- Le email `@placeholder.local` o `@example.com` in BeachCRER indicano dati mancanti — chiedi a Davide l'email reale prima di aggiungere al gruppo.
