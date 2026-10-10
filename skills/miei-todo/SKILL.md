---
name: miei-todo
description: Rassegna guidata dei To Do di Davide sul pannello di MaestroWeb — UNA card alla volta: cosa chiede, perché aspetta lui, le opzioni verificate con pro e contro e la raccomandazione; Davide sceglie, Claudio registra la decisione (commento, issue, label, spostamento della card) e passa alla successiva. Trigger: «/miei-todo», «passiamo i miei todo», «rassegna dei todo», «spiegami i miei todo».
---

# Skill: miei-todo

Davide ha nei suoi «I miei To Do» card che aspettano **una sua decisione o una
sua azione**. Lette tutte insieme sono un muro; questa skill le passa **una alla
volta**, spiegate in italiano semplice, con le opzioni fra cui scegliere.

Nata il 04/10/2026 su richiesta di Davide («passare in rassegna i miei todo,
spiegarmeli e darmi le opzioni tra cui scegliere, un todo alla volta»).

## 0. L'elenco

```bash
cd ~/Documents/00-Progetti/MaestroWeb
npm run -s card:stato -- --json
```

Prendi la sezione `stage: "todo"` e tieni solo le card con `owner: "davide"`
(le altre sono di Ascanio: non si toccano). Ordine: priorità (alta → bassa),
poi numero di card.

Apri con **una riga**: «Hai N card nei To Do: S…, S…, S…. Partiamo dalla
prima.» Niente altro elenco.

## 1. Prepara UNA card (prima di scriverle una parola)

Leggi tutto, in sola lettura:

- la card: descrizione, **tutto** il thread dei commenti, gli allegati elencati
  (`qa_tasks`, `qa_task_comments`, `qa_task_issues` via REST con la chiave da
  `.env.local`, mai stampata — oppure `npm run -s triage:leggi -- --task <uuid>`);
- ogni issue collegata, **con i commenti** (`gh issue view N --comments`);
- i fatti nel codice e nei dati che servono a costruire le opzioni.

⛔ **Ogni fatto su cui poggia un'opzione va verificato, non riportato.** Il
04/10/2026 un'opzione («leggere `plant_daily_economics`, consolidata ogni
notte») è stata presentata a Davide sulla parola di un'analisi precedente: la
tabella era ferma da un mese con le colonne vuote, e Davide ha scelto
un'opzione che non esisteva. Se un fatto costa troppo da verificare, l'opzione
lo dice («da verificare: …»), non lo dà per buono.

Se la ricerca è lunga (più file, query in produzione), mandala a un agente in
background e intanto di' a Davide su quale card stai lavorando.

## 2. Presenta la card

Formato fisso, breve, in italiano semplice, senza nomi di file se non servono:

```
## S<n> — <titolo>   (chiesta da <chi>, <data>)

**Cosa chiede:** 2-3 frasi, con le parole di chi l'ha chiesta.
**Perché aspetta te:** la decisione o l'azione che serve, in una frase.
**Cosa sappiamo già:** solo fatti verificati, 2-4 punti.

**Opzioni**
- **A — <nome>:** cosa succede, quanto lavoro, rischio, chi fa cosa.
- **B — <nome>:** …
- **C — <nome>:** …   (massimo 4)

**Consiglio:** A, perché … (una frase, onesta: se due sono equivalenti dillo)
```

Poi la domanda con `AskUserQuestion`: una sola domanda, le opzioni con la
consigliata **per prima** e «(Consigliata)» nell'etichetta, una descrizione di
una riga ciascuna. Davide può sempre scrivere altro («spiegamela meglio»,
«rimandala», una variante): se chiede di rispiegare, rispiega più semplice,
non ripetere uguale.

Se la card **non chiede una decisione** ma un'azione sua (una chiave, un
secret, un comando sul VPS, un grafico da guardare), le opzioni diventano: «la
faccio ora» (e gli dai i comandi **uno alla volta**, mai un segreto in chat),
«dopo», «non serve più».

## 3. Registra la decisione (subito, prima della card successiva)

1. **Commento sulla card**, firma Claudio, per chi l'ha chiesta (di solito
   Ascanio): cosa ha deciso Davide e cosa succede adesso.
   `printf '%s' "<testo>" | npm run -s triage:commenta -- --task <uuid>`
2. **Commento sulla issue** collegata con la decisione («Decisione di Davide
   (gg/mm/aaaa): …») e, se cambia il lavoro, gli AC aggiornati nel corpo.
   Label: `needs-decision` tolta; `ready` solo se gli AC sono completi e il
   precheck (`npm run issue:precheck N`) è verde.
3. **Sposta la card** con lo script della skill (rifiuta Revisione, Approvate,
   BackLog, e «todo» senza assegnatario):
   ```bash
   node %USERPROFILE%\.claude\skills\miei-todo\sposta-card.mjs <n> todo <destinazione> [assigned_to|-] ["nota"]
   ```
   Dove, secondo le regole ferree (#2471, CLAUDE.md di MaestroWeb):

   | Esito della decisione | Card in |
   |---|---|
   | Lavoro sbloccato, issue `ready` che passa il perimetro del ciclo autonomo | `pronte_auto` (la prende il ciclo autonomo) |
   | Lavoro sbloccato, issue `ready` che tocca migration, Edge Function, cron o vendor — o nel dubbio | `pronte_sup` (la lavora il loop supervisionato, con Davide presente) |
   | Lo iniziamo adesso, in questa sessione | `lavorazione` |
   | Serve una risposta di Ascanio | `todo` + `ascanio` |
   | Serve ancora un'azione di Davide (fatta dopo) | resta in `todo` + `davide`, con l'azione scritta |
   | Valida ma non ora | `parcheggiate`, con il motivo nella nota |
   | Superata o non più valida | `obsolete` |

4. Una riga di conferma a Davide («S234 → Parcheggiate, commento ad Ascanio
   scritto») e **passa alla card successiva** (punto 1).

## 4. Fine

Quando le card sono finite, o Davide dice basta: una tabella breve

| Card | Decisione | Dove è ora | Cosa succede dopo |
|---|---|---|---|

e le azioni che restano a lui (chiavi, VPS, grafici), una per riga.
Se ci sono issue `needs-decision` **senza card**, nominale in una riga alla
fine («ci sono anche N issue che aspettano una tua decisione senza card: …»),
senza aprirle se lui non lo chiede.

## Divieti

- Una card alla volta: mai presentare la successiva prima di aver registrato la
  decisione sulla precedente.
- Mai inventare un fatto, un costo o un'opzione; mai presentare come scelta una
  strada non verificata senza dirlo.
- Mai scrivere codice, fare merge, applicare migration, toccare secret o VPS
  dentro questa skill: la decisione si registra, il lavoro parte col flusso
  normale (ciclo autonomo, loop supervisionato, dev-loop).
- Mai spostare card di Ascanio né card in Revisione/Approvate/BackLog.
- Mai segreti in chat: se un'opzione richiede una chiave, si dice **dove** va
  messa, non la si chiede.
