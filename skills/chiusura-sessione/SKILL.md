---
name: chiusura-sessione
description: >
  Chiusura di una sessione di lavoro di Claudio: raccoglie i fatti della
  giornata dai dati (PR, issue, promozioni, card, incidenti), scrive la voce
  di RETROSPETTIVA.md, aggiorna la memoria (stato, regole nuove, «da dove
  ripartire»), chiude ciò che è rimasto a metà e lascia a Davide cinque righe
  per ripartire. Trigger: /chiusura, «chiudiamo», «chiusura sessione»,
  «aggiorna retrospettiva e memoria».
version: 2.0.0
---

# Skill: chiusura-sessione

> Riferimento flusso: `FLUSSO.md` — punto 7 (ogni sessione finisce così)

## Perché

La memoria scritta a fine giornata è l'unica che sopravvive alla sessione.
Se manca, la sessione dopo riparte da «dov'eravamo?» e ricostruisce dai
commit quello che era già noto: costa mezz'ora e perde le decisioni prese a
voce. La retrospettiva è il posto dove le regole nuove nascono con la data e
l'incidente che le ha generate, non come massime senza contesto.

## Procedura

### 1. Raccogli i fatti dai dati, non a memoria

```bash
OGGI=$(date +%F)
# PR mergiate oggi (beta e main)
gh pr list --repo ecologicaleaving/<repo> --state merged --search "merged:>=$OGGI" \
  --json number,title,baseRefName --jq '.[] | "#\(.number) → \(.baseRefName): \(.title)"'
# Issue chiuse oggi
gh issue list --repo ecologicaleaving/<repo> --state closed --search "closed:>=$OGGI" \
  --json number,title --jq '.[] | "#\(.number) \(.title)"'
# Issue aperte oggi
gh issue list --repo ecologicaleaving/<repo> --state open --search "created:>=$OGGI" \
  --json number,title --jq '.[] | "#\(.number) \(.title)"'
# Card di Ascanio mosse o commentate oggi (MaestroWeb)
curl -s -G "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/qa_task_comments" \
  --data-urlencode "select=created_at,author_name,body,qa_tasks!inner(card_no,title,stage)" \
  --data-urlencode "created_at=gte.${OGGI}T00:00:00" --data-urlencode "order=created_at" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
# Loop lanciati oggi
ls ~/.claude/projects/*/*/subagents/workflows/ 2>/dev/null | tail -20
# Sonda finale del backend
curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' \
  "$NEXT_PUBLIC_SUPABASE_URL/rest/v1/sites?select=id&limit=1" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

Aggiungi quello che sai dalla conversazione: decisioni di Davide, risposte di
Ascanio, incidenti, cose che hai sbagliato.

### 2. Scrivi la voce di retrospettiva

File: `RETROSPETTIVA.md` nel repo `workflow` (voce più recente in cima).
Template, tutto obbligatorio, righe vuote dove non c'è niente:

```markdown
## <YYYY-MM-DD> — <titolo di una riga>

**In produzione:** #… (cosa cambia per chi usa), …
**In beta, aspetta:** #… (chi: Ascanio card S… / Davide /approva / noi)
**Aperto:** #… — e cosa lo sblocca

**Ha funzionato:** 2-4 righe, con i numeri (tentativi del loop, tempi, AC)
**Non ha funzionato → regola nuova:** una riga per ogni regola, con l'incidente
  che l'ha generata e dove è scritta (FLUSSO.md punto N / skill X / memoria Y)
**Decisioni di Davide:** una riga ciascuna, testuali quando possibile
**Errori miei:** cosa ho sbagliato e come si evita (senza autoflagellazione)
**Numeri:** issue in prod / in beta, loop, tentativi medi, incidenti
```

Niente narrativa lunga: se una cosa merita più di quattro righe, va in una
memoria dedicata e qui resta il link.

### 3. Aggiorna la memoria

Directory della memoria del progetto (vedi il system prompt). Regole:

- **Stato** → file `project_*`: aggiorna quelli esistenti che oggi sono
  cambiati (una riga datata in coda, non riscrivere), crea quelli nuovi solo
  per lavoro che continua domani.
- **Regole nuove** → file `feedback_*` con `**Why:**` (l'incidente, con data)
  e `**How to apply:**` (cosa fare la prossima volta). Una regola = un file.
- **«Da dove ripartire»** → un file `project_ripartenza_<data>.md`: 10-15
  righe, ordinate per priorità, con chi aspetta cosa. È il PRIMO link
  dell'indice.
- **MEMORY.md**: una riga per file, hook di una frase. Sposta in «Aperti / da
  fare» ciò che è aperto, togli ciò che è chiuso (o marcalo ✅ se resta utile
  come storia). Cancella le memorie che oggi si sono rivelate false.

Controlla di NON salvare ciò che è già nel repo (CLAUDE.md, docs, git log).

### 4. Chiudi ciò che è rimasto a metà

```bash
git worktree list          # worktree residui → git worktree remove --force
git status --short         # working copy sporca?
git branch --show-current  # torna su beta / master
```

Agenti e workflow in background: fermali se non servono più. Schede Chrome
aperte dalla sessione: chiudile. Card di Ascanio: ogni card toccata oggi è
nella sezione giusta con `review_notes` aggiornate?

### 5. Commit e push della retrospettiva

```bash
cd C:\Users\KreshOS\Documents\00-Progetti\workflow
git add RETROSPETTIVA.md
git commit -m "docs(retrospettiva): <data> — <titolo>"
git push origin <branch>      # master è protetto: se serve, PR
```

### 6. Le cinque righe per Davide

Il messaggio finale ha esattamente questa forma, senza altro:

1. cosa è andato in produzione oggi
2. cosa aspetta lui (con il comando: `/approva #N`, un secret, una decisione)
3. cosa aspetta Ascanio (card S…)
4. cosa riprendo io domani per primo
5. il rischio aperto, se c'è

## Vincoli

- Si esegue **ogni** sessione, anche corta, anche se «non è cambiato niente»:
  in quel caso la voce di retrospettiva è di tre righe.
- Mai inventare numeri: se non li hai misurati, scrivi «non misurato».
- La retrospettiva non sostituisce i commenti sulle issue: quelli restano la
  fonte per chi legge GitHub; qui sta ciò che le issue non dicono.
