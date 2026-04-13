---
name: pdf-to-md
description: >
  Use BEFORE reading any PDF file. Converts PDF to Markdown companion file for
  token efficiency. If a .md companion already exists, use it directly.
  Trigger: any time the agent is about to read/analyze a .pdf file.
---

# Skill: pdf-to-md

**Trigger:** Prima di leggere qualsiasi file `.pdf`
**Agente:** Tutti (Claude Code, subagent)
**Versione:** 2.0.0

---

## Regola

**Mai leggere un PDF direttamente se esiste (o può essere creato) un `.md` affiancato.**

Un PDF da 1MB può costare migliaia di token in metadati binari. Un `.md` equivalente è leggero, ricercabile con `grep`, versionabile con git.

---

## Flusso

```
Agente sta per leggere file.pdf
    ↓
Esiste file.md nella stessa directory?
├── SÌ → leggi file.md, ignora il PDF
└── NO → converti → crea file.md → leggi file.md
```

---

## Procedura (quando il .md non esiste)

### Step 1 — Converti

Usa il tool `pdf` per estrarre il contenuto:

```
pdf(pdf="<percorso/file.pdf>", prompt="Estrai tutto il contenuto del documento preservando la struttura: titoli, sezioni, tabelle, liste. Restituisci in formato Markdown pulito.")
```

Per PDF grandi, usa il parametro `pages` per processare a blocchi:
```
pdf(pdf="file.pdf", pages="1-30", prompt="...")
pdf(pdf="file.pdf", pages="31-60", prompt="...")
```

### Step 2 — Scrivi il .md

Crea il file nella **stessa directory** del PDF, stesso nome base:

```
<percorso>/documento.pdf → <percorso>/documento.md
```

Formato:

```markdown
# <Titolo del documento>

> Fonte: `<nome-file.pdf>` | Estratto: YYYY-MM-DD

---

<contenuto estratto in Markdown>
```

Regole formattazione:
- `#`, `##`, `###` per la gerarchia sezioni originale
- Tabelle in formato Markdown
- Liste puntate e numerate preservate
- No header/footer ripetitivi delle pagine
- Numeri di pagina solo se utili alla navigazione (`---` + `*Pagina N*`)

### Step 3 — Procedi

Leggi il `.md` appena creato per il task originale. Non toccare più il PDF.

---

## Casi speciali

| Caso | Azione |
|------|--------|
| PDF protetto / illeggibile | Segnala, leggi direttamente col tool `pdf` |
| PDF solo immagini (scansioni) | Usa `pdf` con prompt OCR, avverti che potrebbe essere incompleto |
| `.md` esiste ma Davide chiede di rigenerare | Rigenera sovrascrivendo |
| `.md` esiste → usalo | Non toccare il PDF |

---

## Dove si applica

Questa skill è **obbligatoria** per tutti gli agenti del team:
- Agente (Claude Code / Sonnet)
- Subagent research

Va referenziata nel `CLAUDE.md` di ogni progetto che contiene PDF.
