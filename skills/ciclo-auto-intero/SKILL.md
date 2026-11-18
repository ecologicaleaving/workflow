---
name: ciclo-auto-intero
description: >
  Catena supervisionata «ciclo auto intero» (auto + prova) (MaestroWeb, dal 18/11/2026): con Davide
  presente prende le card di «Pronte auto» una alla volta e porta ciascuna
  fino in «Revisione» prima di passare alla successiva: sviluppo (dev-loop col
  perimetro del ciclo autonomo), merge in beta, In Test, giro di ciclo-prova
  (browser + codice), Revisione con «Cosa provare, in parole semplici».
  Mai `main`. Trigger: «/ciclo-auto-intero», «ciclo auto intero», «ciclo auto + prova»,
  «lancia il ciclo auto e prova».
version: 1.0.0
---

# Skill: ciclo-auto-intero

> Nata il 18/11/2026 dalla prova di Davide su S388 e S390 («per ogni card fai
> ciclo auto e poi ciclo prova, fino a portarla direttamente in revisione prima
> di passare alla successiva»). Non è un ciclo nuovo: incatena `ciclo-sviluppo`
> e `ciclo-prova` per UNA card alla volta. Le regole dei pezzi restano nelle
> loro skill e nel codice del progetto; qui c'è solo l'ordine e i punti di
> fermata. Se questa skill e FLUSSO.md non sono d'accordo, vince FLUSSO.md.

## Chi la avvia

**Solo Davide, presente.** L'interruttore `sviluppo` di
`~/.claude/ciclo-autonomo.json` resta com'è (di solito spento): la catena non lo
legge e non lo accende. La versione senza persona (lock, comando
`ciclo:<nome>`, interruttore, giro col `/loop`) non esiste ancora: per farla
serve lo schema di FLUSSO.md → «I cicli autonomi», con una issue sua.

## La coda

Le card **aperte in «Pronte auto»** (`pronte_auto`), nell'ordine di `coda_pos`,
poi per numero di scheda (`npm run -s card:stato -- --json`). Una card alla
volta: **la successiva parte solo quando la precedente è in Revisione** o si è
fermata con un motivo scritto.

Prima di prendere una card, `npm run ciclo:log` (sezione «prese»): se il ciclo
autonomo di un altro PC l'ha presa, si salta.

## Il giro (una card)

### 0. Allineamento

```bash
cd ~/Documents/00-Progetti/MaestroWeb
git fetch -q origin && git pull -q --ff-only origin beta   # radice = origin/beta
```

La prova dal vivo pretende la radice su `origin/beta` (memoria «prova: radice
allineata a beta»): si riallinea **a ogni card**, prima dello sviluppo e prima
della prova.

### 1. Sviluppo (come `loop-supervisionato`, perimetro del ciclo autonomo)

```bash
npm run -s card:in-lavorazione -- --card S<n> --issue N
npm run -s issue:precheck N                     # exit 1 → ferma, motivo a Davide
npm run -s ciclo:sviluppo -- --registra '{"issue":N,"esito":"avviata"}'
```

Dev-loop con lo script del ciclo autonomo (perimetro più stretto: niente
migration, Edge Function, vendor):
`Workflow({ scriptPath: "<USERPROFILE>\.claude\workflows\maestro\ciclo-autonomo.js", args: { repo, issueNumber, branch } })`.
Mai `ciclo:card-presa` (è del ciclo autonomo).

### 2. Merge in beta

1. `npm run -s ciclo:sviluppo -- --verifica-pr <PR> --json` → **exit 0**
   («libero»). Exit 3 o 1: la card non è da questa catena → ferma, a Davide.
2. `Closes #N` nel corpo, base `beta`, allineamento PRIMA della CI
   (`git rev-list --count $(git merge-base origin/beta origin/<branch>)..origin/beta`
   = 0, altrimenti `gh pr update-branch`).
3. `gh pr checks <PR> --watch`: **tutto verde, E2E compresi.**
4. **E2E rosso → ci si ferma e si chiede a Davide.** Si leggono i test falliti
   (`gh run view <id> --log-failed`) e si spiega in due righe se è un difetto
   della PR o un test di guardia che il nuovo disegno ha reso inesatto. **Un test
   di guardia non si cambia senza il suo ok** (S390, 18/11: lo stacco
   quadro-grafico misurato fino al grafico, che ora sta in un riquadro). Mai
   mergiare sopra un rosso, mai ritentare a mano «perché sembra flaky».
5. Merge col lucchetto:
   `npm run -s merge:lucchetto -- prendi --pr <PR> --attendi 10` → ricontrolla
   l'allineamento → `gh pr merge <PR> --merge` → `rilascia --pr <PR>` →
   `--registra '{"issue":N,"esito":"mergiata","pr":P,"motivo":"supervisionato"}'`.
6. CI del push su `beta` (`deploy-test.yml`) verde sul commit di merge, deploy di
   test-maestro compreso.

### 3. In Test

```bash
npm run -s card:in-test -- --pr <PR> --dry-run && npm run -s card:in-test -- --pr <PR>
```

Card a binari: `ciclo:card-prossima-sezione` al posto di `card:in-test` (skill
`ciclo-sviluppo`).

### 4. Prova (un giro di `ciclo-prova`, subito)

Si segue la skill `ciclo-prova` **così com'è**: `ciclo:prova -- --json --lock`,
spec fuori dal repo con un test per punto (`P<n>` nel titolo, un solo test per
punto: più larghezze vanno in un ciclo dentro lo stesso test), `--esegui`,
verificatore Opus distinto sui `[Codice]`, `prova:codice --verifica`,
`--componi`, scrittore con `--dry-run` per primo. Due regole imparate il 18/11:

- **Lo spec aspetta il dato definitivo.** Un'icona o un testo che esistono già
  durante il caricamento (es. il wifi in alto nella pagina impianto: «Non
  connesso» finché il device non è letto) si leggono con `expect.poll` fino al
  valore finale, mai al primo `toBeVisible` (S388: falso ko al primo giro).
- **Un ko si riproduce prima di crederci**: screenshot e `error-context.md`
  dicono se la pagina era carica. Prova malfatta = si corregge lo spec (al
  massimo 2 riesecuzioni), non è un difetto.

Esito **ok** → `card:in-revisione`, `deps:schede`, e subito il commento
«Cosa provare, in parole semplici» (`triage:commenta --task <uuid> --come ciclo`,
regole in `ciclo-prova` 1.4.0). Esito **ko** → issue di fix e
`card:rientro-prova` (skill `ciclo-prova`, punto 5); la catena **si ferma** su
quella card e lo dice a Davide. **Incompleto** → `card:prova-incompleta`, ferma.

Fine giro: `ciclo:prova -- --registra '{"card":N,"esito":"..."}'` e `--unlock`.

### 5. Card successiva

Solo con la card precedente in Revisione. Coda vuota → riepilogo a Davide (una
riga per card: PR, esito CI, punti provati nel browser e sul codice, dove è
finita) e cosa resta per lui.

## Quando ci si ferma e si chiama Davide

- precheck con segnali, planner `blocked`, 4 tentativi senza verde;
- `--verifica-pr` diverso da 0;
- **E2E o CI rossi** (punto 2.4);
- prova con un ko vero, o incompleta;
- una decisione di prodotto non scritta negli AC.

Mentre aspetta, la catena **non** passa alla card successiva: l'ordine «una
card fino in Revisione, poi la prossima» è il senso di questa skill.

## Divieti

Quelli di `ciclo-sviluppo`, `ciclo-prova` e `loop-supervisionato`, in
particolare: mai `main`, mai `qa-approved`, mai card in Approvate o BackLog, mai
migration né Edge Function in questa catena (vanno in «Pronte supervisionate»),
mai `CICLO_PROVA_MODO`, mai scritture verso Supabase dalla prova, mai `npm ci`
nella radice; i worktree si tolgono con `npm run worktree:remove`.
