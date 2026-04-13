# Skill: repo-maintenance

**Trigger:** Su richiesta di Davide, dopo ogni issue completata, o quando l'agente rileva che i file sono out-of-sync
**Agente:** Claude Code
**Versione:** 3.0.0

---

## Obiettivo

Mantenere aggiornati i file di configurazione e workflow di ogni repo del team. L'agente lo fa in automatico e riporta a Davide; escala solo se trova anomalie o ha bisogno di input.

---

## File sotto responsabilità dell'agente

### Sempre aggiornati (in qualsiasi momento)

| File | Contenuto | Trigger aggiornamento |
|------|-----------|----------------------|
| `CLAUDE.md` | Hook avvio agente, regole vincolanti | Cambio workflow, nuove regole, su richiesta Davide |
| `AGENTS.md` | Stessa cosa in inglese | Cambio workflow, nuove regole, su richiesta Davide |
| `PROJECT.md` | Stack, URL, stato deploy, backlog | Dopo ogni issue completata, cambio infra, cambio stack |
| `.workflow/` | Submodule regole operative | Sync automatico all'avvio agente |

### Aggiornati alla PR

| File | Contenuto | Chi lo aggiorna |
|------|-----------|----------------|
| `README.md` | Documentazione pubblica progetto | Agente (checklist PR) |
| `CHANGELOG.md` | Storia delle versioni | Agente (checklist PR) |
| `docs/` | Documentazione tecnica | Agente (checklist PR) |

---

## Procedura — Controllo e Aggiornamento

### Step 1 — Verifica stato file

```bash
gh api repos/ecologicaleaving/<repo>/contents/CLAUDE.md --jq '.sha' 2>/dev/null
gh api repos/ecologicaleaving/<repo>/contents/AGENTS.md --jq '.sha' 2>/dev/null
gh api repos/ecologicaleaving/<repo>/contents/PROJECT.md --jq '.sha' 2>/dev/null
```

### Step 2 — Confronta con template

Confronta il contenuto attuale con:
- `templates/CLAUDE.md` (questo repo workflow)
- `templates/AGENTS.md` (questo repo workflow)

Se la versione del template è più recente o le regole sono cambiate → aggiorna.

### Step 3 — Aggiorna file su repo

```bash
SHA=$(gh api repos/ecologicaleaving/<repo>/contents/CLAUDE.md --jq '.sha')
CONTENT=$(base64 -w 0 < templates/CLAUDE.md)
gh api repos/ecologicaleaving/<repo>/contents/CLAUDE.md \
  --method PUT \
  --field message="chore: aggiorna CLAUDE.md a workflow v4.0" \
  --field content="$CONTENT" \
  --field sha="$SHA"
```

Ripeti per `AGENTS.md`.

### Step 4 — Aggiorna PROJECT.md

Aggiorna solo i campi che sono cambiati:
- Versione app (dopo issue completata)
- Data ultimo deploy
- URL test / produzione
- Stack (se aggiunto/rimosso qualcosa)
- Stato issue nel backlog

**Non riscrivere PROJECT.md da zero** — aggiorna chirurgicamente solo i campi cambiati.

### Step 5 — Sync submodule .workflow

```bash
git submodule update --remote .workflow
git add .workflow
git commit -m "chore: sync workflow submodule"
git push
```

---

## Logica Automatica vs Escalation

### L'agente fa in automatico e riporta:

```
✅ [Repo: <repo>] File aggiornati
📄 CLAUDE.md → v4.0 (era v1.x)
📄 AGENTS.md → v4.0 (era v1.x)
📄 PROJECT.md → versione bumped, issue #N segnata done
🔗 .workflow → synced
```

### L'agente escala a Davide se:

- `PROJECT.md` manca e non sa come crearlo (stack sconosciuto)
- C'è un conflitto tra il contenuto attuale e il template (personalizzazioni locali)
- Il submodule `.workflow` non esiste nel repo (repo non ancora integrata)
- L'agente non ha i permessi per fare push (repo protetta)

**Formato escalation:**
```
⚠️ [Repo: <repo>] Problema aggiornamento file
📌 <descrizione problema>
❓ <cosa serve da Davide>
```

---

## Trigger Automatici

| Evento | Azione |
|--------|--------|
| Issue completata (card → Done) | Aggiorna PROJECT.md del repo |
| Nuovo workflow rilasciato | Aggiorna CLAUDE.md + AGENTS.md su tutti i repo attivi |
| Davide cambia stack o URL | Aggiorna PROJECT.md del repo interessato |
| Su richiesta esplicita di Davide | Controlla e allinea tutto |

---

## Repo Attivi (da config.json)

- `ecologicaleaving/StageConnect`
- `ecologicaleaving/BeachRef-app`
- `ecologicaleaving/finn`
- `ecologicaleaving/maestro`
- `ecologicaleaving/AutoDrum`
- altri secondo `config.json`
