---
name: aggiorna-pc
version: 1.1.0
description: >
  Allinea questo PC in un colpo solo, a ciclo spento: repo `workflow` (master) con
  `sync.ps1`, `claude-config-maestro` con `sync.ps1`, radice MaestroWeb su `beta`
  con `npm run setup` se il lockfile è cambiato; poi verifica con
  `npm run -s ciclo:sviluppo -- --json`. Lo lancia una PERSONA con una frase, mai il
  ciclo. Fail-closed: al primo problema si ferma e lo dice, senza forzare nulla.
  Trigger: «aggiorna il PC», «/aggiorna-pc», «allinea il PC», «aggiorna tutto».
---

# Skill: aggiorna-pc

> MaestroWeb #2858, follow-up di #2848. Richiesta di Davide, 15/10/2026: «gli dico
> una frase e si deve aggiornare da solo».

## Perché

Dopo #2848 il ciclo autonomo, a ogni giro, controlla che radice, repo `workflow` e
skill siano allineati, e **si ferma** se non lo sono: non sincronizza da solo (decisione
di Davide, 14/10/2026). Rimettere in linea un PC richiede tre passi su tre cartelle,
nell'ordine giusto. Questa skill li fa **per conto di una persona che l'ha chiesto**:
non contraddice #2848, perché a lanciarla è una persona, a ciclo spento.

## Prima di toccare qualunque cosa

1. **Il ciclo deve essere spento.** Leggi `~/.claude/ciclo-autonomo.json` (solo le
   chiavi `sviluppo`, `prova`, `triage`: mai altro). Se `sviluppo` o `prova` è `true`,
   **fermati**: «Il ciclo è acceso su questo PC: spegnilo tu (`"sviluppo": false`), poi
   rilancia». Non lo spegni tu, non lo modifichi.
2. **Nessun valore dei secret.** Non leggere, non stampare, non copiare valori di
   `.env.local` o di altri file di credenziali: se ti serve sapere se esiste, elenchi
   solo i nomi.
3. **Mai**: `git checkout` di un ramo diverso da quello previsto (vedi sotto), `reset`,
   `stash`, `merge`, `rebase`, `--force`, `npm ci`, `npm install`.

## I tre passi, in quest'ordine

Ogni passo parte da una cartella sorella dentro `~/Documents/00-Progetti/`. **Al primo
problema ti fermi**: dici in italiano il passo, la cartella e il motivo, e non passi al
successivo.

### Passo 1 — repo `workflow`

```powershell
cd $env:USERPROFILE\Documents\00-Progetti\workflow
git branch --show-current            # deve dire: master
git status --porcelain --untracked-files=no   # deve essere vuoto
git pull --ff-only origin master
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
```

Si ferma se: il ramo non è `master`, HEAD è staccato, ci sono modifiche ai file
tracciati, il pull non è un fast-forward (storia divergente), o `sync.ps1` esce con un
codice diverso da 0. **Non cambi ramo da solo**: dici «il repo workflow è sul ramo X,
non su master» e aspetti una persona.

### Passo 2 — `claude-config-maestro`

```powershell
cd $env:USERPROFILE\Documents\00-Progetti\claude-config-maestro
git branch --show-current            # deve dire: main
git status --porcelain --untracked-files=no   # deve essere vuoto
git pull --ff-only origin main       # PRIMA: lo script che gira deve essere quello nuovo
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
```

Dal 15/10/2026 `sync.ps1` lavora a tre vie e ricorda l'ultimo allineamento di questo PC
(`~/.claude/.sync-config-maestro`): un PC rimasto indietro non può più cancellare né
riportare indietro il lavoro dell'altro (il 15/10 il PC di Ascanio cancellò 11 file di
memoria). Se esce diverso da 0, riporta il suo messaggio com'è (senza valori) e
**fermati**. Casi che conosci:

- **codice 5** («questo PC non ha ancora un punto di allineamento»): è un PC nuovo o mai
  allineato con la versione nuova. Chiedi alla persona se sul PC ci sono modifiche di
  memoria da non perdere; se NON ce ne sono, rilancia con `-SoloDalRepo` (prende tutto dal
  repo, non manda nulla). Se ce ne sono, fermati e dillo a Claudio.
- **codice 6** («cancellerebbe N file dal repo»): quasi sempre un PC rimasto indietro. Non
  usare mai `-ConfermaCancellazioni` da sola: fermati.
- **codice 3** (lo stesso file cambiato sui due PC) o **codice 2** (segreto in chiaro): fermati.

Se la cartella non c'è, fermati e dillo (non la cloni da sola).

**Esclusioni per PC (15/10/2026 → 25/10/2026).** `sync.ps1` allinea anche
`~/.claude/CLAUDE.md` (le istruzioni globali di Davide) e `~/.claude/agents`. Su un PC di
un'altra persona (es. quello di Ascanio, col suo account) il suo `CLAUDE.md` **non si
tocca**: né si sovrascrive né si manda al repo. La voce da lasciare fuori sta nel file
locale `~/.claude/.sync-config-maestro-esclusi` (un nome per riga: `CLAUDE.md`, `agents`,
`maestro` o `memory`; `#` per i commenti). **Prima di lanciare `sync.ps1`:**

```powershell
$esclusi = "$env:USERPROFILE\.claude\.sync-config-maestro-esclusi"
if (Test-Path $esclusi) { Get-Content $esclusi } else { "(nessuna esclusione)" }
```

- Se il file c'è, `sync.ps1` lo rispetta da solo e lo scrive nell'output
  («escluse su questo PC: …»): riportalo nella riga finale. **Non lo modifichi e non lo
  cancelli mai.**
- Se il file **non c'è**, il PC è di Davide: nessuna esclusione, si procede.
- Se `sync.ps1` stampa «ATTENZIONE: '…' non corrisponde a nessuna voce», riportalo com'è:
  il nome nel file è sbagliato, lo corregge una persona.
- Non sei tu a decidere che un PC è «di un'altra persona»: lo ha detto Davide creando il
  file (comando nella sezione «La prima volta»). Nel dubbio non indovinare, fermati.

### Passo 3 — radice MaestroWeb

```powershell
cd $env:USERPROFILE\Documents\00-Progetti\MaestroWeb
git branch --show-current            # deve dire: beta
git status --porcelain --untracked-files=no   # deve essere vuoto
$prima = (Get-FileHash package-lock.json).Hash
git pull --ff-only origin beta
$dopo  = (Get-FileHash package-lock.json).Hash
if ($prima -ne $dopo) { npm run setup }   # mai `npm ci`
```

Stesse regole di arresto del passo 1 (ramo non `beta`, HEAD staccato, file tracciati
modificati, pull non fast-forward). `npm run setup` solo se il lockfile è cambiato; se
esce con un errore, riporta le ultime righe e fermati. I file **non tracciati** non
bloccano.

## Verifica finale

```powershell
cd $env:USERPROFILE\Documents\00-Progetti\MaestroWeb
npm run -s ciclo:sviluppo -- --json
```

- `{"ciclo":"spento"}` o una coda JSON senza `errore` → «PC allineato».
- `{"errore":"allineamento: …"}` → riporta quella riga così com'è e dì cosa manca; non
  provare a correggere oltre i tre passi.

Chiudi con **una riga** sul risultato (allineato, oppure fermato al passo N per il
motivo M). Non accendi nessun interruttore: `{"sviluppo": true}` e `{"prova": true}`
restano di una persona.

## La prima volta (bootstrap)

La skill arriva sul PC con `sync.ps1`, quindi **la prima volta non c'è ancora**. Si
fanno a mano, una volta sola, i passi 1 e 2:

```powershell
cd $env:USERPROFILE\Documents\00-Progetti\workflow
git checkout master; git pull origin master
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
cd $env:USERPROFILE\Documents\00-Progetti\claude-config-maestro
git pull --ff-only origin main
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1 -SoloDalRepo   # solo la prima volta, se il PC non ha mai fatto il sync nuovo
```

**PC di un'altra persona (es. quello di Ascanio): una volta sola, PRIMA di ogni
sync**, per non toccare il suo `CLAUDE.md`:

```powershell
Set-Content "$env:USERPROFILE\.claude\.sync-config-maestro-esclusi" "CLAUDE.md" -Encoding ascii
```

Poi si può fare il bootstrap sopra. Senza quel file la versione vecchia della skill (che
gira finché `sync.ps1` non l'ha aggiornata) sincronizzerebbe anche il suo `CLAUDE.md`.

Da quel momento basta la frase «aggiorna il PC» in una sessione Claude Code; le
versioni future della skill si aggiornano con lo stesso `sync.ps1`.

## Cosa questa skill NON fa

- Non accende, non spegne e non modifica i cicli.
- Non sincronizza il `CLAUDE.md` (né le altre voci) di un PC che ha il file
  `.sync-config-maestro-esclusi`: lì si lascia com'è.
- Non applica migration, non deploya, non tocca Supabase, la VPS o i secret.
- Non risolve conflitti, non cambia ramo, non butta via modifiche locali: se serve, lo
  fa una persona.
- Non confronta il contenuto delle skill, solo ciò che fa già il controllo di
  allineamento (#2848).
