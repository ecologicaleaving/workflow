---
name: aggiorna-pc
version: 1.0.0
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
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
```

Lo script si ferma da solo su un segreto o su un conflitto: se esce con codice diverso
da 0, riporta il suo messaggio com'è (senza valori) e **fermati**. Se la cartella non
c'è, fermati e dillo (non la cloni da sola).

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
powershell -ExecutionPolicy Bypass -File scripts\sync.ps1
```

Da quel momento basta la frase «aggiorna il PC» in una sessione Claude Code; le
versioni future della skill si aggiornano con lo stesso `sync.ps1`.

## Cosa questa skill NON fa

- Non accende, non spegne e non modifica i cicli.
- Non applica migration, non deploya, non tocca Supabase, la VPS o i secret.
- Non risolve conflitti, non cambia ramo, non butta via modifiche locali: se serve, lo
  fa una persona.
- Non confronta il contenuto delle skill, solo ciò che fa già il controllo di
  allineamento (#2848).
