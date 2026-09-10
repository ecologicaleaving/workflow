# Retrospettiva delle sessioni

Una voce per sessione, la più recente in cima. La scrive Claudio a fine
sessione con la skill `chiusura-sessione`. Contiene ciò che le issue non
dicono: cosa ha funzionato, cosa no e quale regola ne è nata, le decisioni di
Davide, gli errori. Le regole nuove vivono poi in `FLUSSO.md` o nelle skill;
qui restano la data e il perché.

---

## 2026-09-10 — Cinque strumenti che mentivano, e la formula che li alimentava

**In produzione:** niente. La sessione ha lavorato tutta su `beta`, che è ora **37 commit avanti** su `main`.
**In beta, aspetta:** l'epica **#2051** con cinque figlie — #2036, #2037, #2038, #2053, #2058 — che Ascanio deve provare col suo file (card **S133**, in Revisione con cinque prove scritte). Più #2023 (junction), #2032 (pannello problemi, S122 in Revisione), #2056 (sub-issue), #2060 (potenza vendor nella SSOT), #2062 e #2064 (i tre strumenti diagnostici).
**Aperto:** il backfill `npm run potenza:backfill -- --apply` (1 impianto, Davide) · la decisione su **Butt Abdullah**, 6,11 contro 6 (Davide) · l'`--apply` di `subissue:collega` sulle 48 issue (Davide) · le epiche storiche senza parentela dichiarata nel titolo · la Fase 2 di **#670**, che oggi ha presentato il conto tre volte.

**Ha funzionato:** nove loop, **sei chiusi al primo o secondo tentativo**. Ma il valore non è nei numeri: è che i piani hanno **corretto le mie diagnosi tre volte**. Il piano di #2036 ha scoperto che per Solarman/Sungrow/Huawei `devices.thing_key` non è il seriale ma l'identificativo del portale, quindi l'AC1 come l'avevo scritto avrebbe prodotto dispositivi inerti. Il piano di #2062 ha censito **dieci** consumatori di `weather_forecast_config` dove io ne avevo guardati due, e ne ha trovati altri due sbagliati più **uno che scrive**. Il piano di #2064 ha dimostrato che la strada che preferivo era impossibile: la RPC `plant_technical_upsert_patch` impone `source='manual'` e `inferred=false` come costanti, quindi dirottarci una stima l'avrebbe marcata come inserita a mano. Un verificatore ha **rotto il codice apposta** — due mutazioni, rimesse a posto — per provare che i test mordevano davvero.

**Non ha funzionato → regola nuova:**
- **Un AC che si verifica solo dopo una scrittura in produzione va taggato `[Azione]`.** L'AC7 di #2060 diceva «dopo il backfill il totale sale a 268,72 kWp»: il verificatore l'ha marcato `pending-azione` (giustamente), ma `allPassed` è rimasto falso e il loop ha girato **fino al tetto dei 4 tentativi** con l'implementazione già completa dal primo. Tre giri e ~960k token → memoria `feedback_ac_che_richiede_scrittura_in_prod`.
- **Un difetto trovato DOPO l'approvazione di una scheda non si aggancia a quella scheda.** L'approvazione ha una data: S110 è stata approvata alle 15:03 dell'08/09, #2036/#2037/#2038 sono nate dopo. Agganciarle le avrebbe fatte ereditare un'approvazione data su qualcosa che Ascanio non aveva visto, e avrebbe lasciato la scheda con due issue — il segnale che la regola «una scheda = un'epica» è saltata → scheda nuova **S133** + epica **#2051**, memoria `feedback_difetti_dopo_approvazione_scheda_nuova`.
- **Le sub-issue di GitHub non sono mai state usate, e senza di esse la spia di #1755 non poteva accendersi.** `dipendenze-schede.ts` risale da figlia a epica via `gh api .../sub_issues`; **50 epiche, zero sub-issue**. Il commento nel codice lo prevedeva alla lettera: «senza questa risalita la maggior parte dei gruppi non troverebbe nessuna scheda». Agganciate a mano le 4 figlie di #2051, i gruppi orfani sono passati da 5 a 1 → #2056, con `subissue:collega` (dry-run di default) e `audit:subissue` che esce 1, nel giro notturno, senza `continue-on-error`.
- **Un comando disabilitato e muto è indistinguibile da un guasto.** Ascanio non ha annullato il caricamento: **non poteva andare avanti**. `canImport` era una congiunzione di cinque condizioni e nessuna scriveva il proprio motivo; accanto c'era solo «Indietro». Ora è `blockingReason === null`, unica sorgente del motivo: non può più esistere una causa che spegne senza dire perché — e delle cinque, **una era muta da sempre** senza che nessuno l'avesse notata (#2058).
- **Il template di una skill può restare indietro rispetto a una decisione già presa.** «Sostituiamo Fable con Opus dappertutto» è del 06/09 ed è in questa retrospettiva; le skill dicevano ancora Fable. Ha smesso di essere un dettaglio quando i crediti Fable si sono esauriti e il loop su #2058 è morto in 45 secondi. 24 occorrenze allineate su 4 file, `issue-validate` compresa — che avrebbe smesso di funzionare alla prossima `/valida`.

**Decisioni di Davide:** «scheda nuova con sua epica» (per i difetti post-approvazione) · «ascanio ha il file, lo fa lui il test come questa volta» · «vai con la lettura» (registro `0x1024` su un impianto vero) · «in quella fase va spiegato meglio, una frase per riga con indicazioni sempre sintetiche, ma più chiare» · «aggiorna il template» · «procedi» su #2060, #2062, #2064.

**Errori miei:** cinque, tutti dello stesso tipo — **ho riferito conclusioni prima di misurarle**. (1) «Ha annullato, ha fatto la cosa giusta»: non aveva annullato, era bloccato, e l'ho scoperto solo perché Ascanio l'ha detto a Davide. (2) «Il forecast di 11 impianti gira su una potenza sbagliata»: falso, `snapshot-forecast` legge già la SSOT — me ne sono accorto andando a scrivere la issue. (3) «Il 7,4 va chiesto ad Ascanio»: no, è 5701 W × 1,3, lo calcoliamo noi. (4) Le note di prova su S133 non dicevano **su quale sito** provare, e lui ha scritto dati veri di clienti usando codice non promosso. (5) L'AC7 non taggato `[Azione]`. La regola che ne esce: **quando sto per riferire un difetto, la domanda giusta è "l'ho misurato o l'ho dedotto?"** — tre delle cinque volte la misura era a due comandi di distanza.

**Numeri:** 11 PR mergiate in `beta`, 0 in produzione · 9 loop (tentativi: 1, 1, 1, 2, 2, 2, 4, 4, 4) · 1 loop morto per crediti esauriti, ripartito su Opus · 7 issue nuove aperte · 13 impianti verificati uno per uno sulla formula `watt_inverter × 1,3` · backend sano a fine sessione (HTTP 200 in 0,65 s).

---

## 2026-09-08 — L'epica del caricamento in un giorno, e sette spie che non c'erano

**In produzione:** #1996 (epica) con #2015, #2017, #2018, #2022, #2027, #2030 — PR #2034, fast-forward. Da oggi si caricano impianti in blocco col modulo di Ascanio, **proprietario compreso**: 30 colonne prese dal suo file, i dieci campi nuovi che arrivano a destinazione, POD/CENSIMP/CER/catasto/credenziali logger che hanno dove stare, e gli avvisi al posto dei blocchi dove lui li ha chiesti. Una migration additiva.
**In beta, aspetta:** #2032 parte additiva (PR #2033, icona a `config`, `valori`, `telemetria`) — 2 commit avanti su `main`. Aspetta il prossimo giro.
**Aperto:** #2035 (pannello problemi, loop ancora in corso) · #2023 (junction, verde, aspetta ok di Davide) · #2036 (dispositivi solo Zucchetti) · #2037 (nessun controllo di plausibilità) · #2038 (ricaricare aggiorna) · #2012 AC3/AC4 · #2014 · #2019 · #2020 · #2021 · #2026.

**Ha funzionato:** cinque loop, **tutti chiusi al primo tentativo** (#2015 9/9 AC, #2017 10/10, #2018 9/9 al 2°, #2022 11/11, #2027 12/12). I verificatori hanno fatto il lavoro vero: si sono costruiti i piani da soli invece di usare gli helper delle PR, hanno battuto a mano intestazioni a 22 colonne invece di riusare le costanti, hanno cercato la password **per stringa** negli oggetti di errore invece di leggere il codice. Uno ha trovato che **il mio AC6 era sbagliato** (una provincia inventata non invalida la riga, è deliberato dal #1706) e l'ha documentato invece di far quadrare il numero. Due piani hanno **rifiutato di implementare**: #2032 perché togliere la scritta avrebbe nascosto gli «Alert Maestro», #2018 perché la RPC da estendere non era quella. Il precheck ha dato via libera 6 volte su 6.

**Non ha funzionato → regola nuova:**
- **Una junction rende `npm ci` distruttivo per la radice.** Un `npm ci` in un worktree collegato segue il link e svuota il `node_modules` **della radice**. È successo, e la causa scatenante è stata un'istruzione mia agli agenti che citava uno script non ancora in `beta`. La guardia impediva di *collegare* con lockfile diversi, non di *installare* dopo aver collegato → corretto in PR #2023 (marcatore + avviso + due test), scritto in CLAUDE.md e nella skill.
- **`database.types.ts` si rigenera solo da produzione.** Una rigenerazione locale ha tolto in silenzio 167 righe, fra cui `commands.target_soc_pct` — colonna che esiste in prod e che **nessuna migration crea**. Da lì è nata #2026: nessun controllo confronta lo schema delle migration con quello vivo. Per i cron la spia esiste (`audit:cron-drift`), per lo schema no.
- **`continue-on-error` spegne la spia per tutto, non solo per l'eccezione.** Il job «Cron vivi vs dichiarati» è uscito **verde con exit code 1** e sei scarti dentro, uno dei quali — `huawei-session-keepalive` dichiarato acceso e inesistente — non era concordato con nessuno → memoria `feedback_continue_on_error_spegne_la_spia`.
- **Una scritta non è un controllo.** La colonna dice «(kWp)» e l'istruzione «Es. 8,2»: sono entrati sette impianti da 6500 kWp senza che niente fiatasse → #2037.
- **Il caricamento non aggiorna, salta.** Ricaricare un file corretto non ripara niente: le righe già presenti vengono scartate → #2038, con il vincolo che **una cella vuota non deve mai cancellare**.
- **Le prove a schermo non arrivano dove c'è un selettore file di sistema.** Il bottone «Importa da file» apre una finestra di Windows che blocca la scheda: l'anteprima dell'import resta l'unico pezzo che l'automazione non copre.

**Decisioni di Davide:** retrocompatibilità — «entrambi i moduli restano caricabili»; junction adesso, pnpm quando c'è tempo; «promuovi» dato **due volte**, la seconda dopo essere stato informato che nessuna issue aveva `qa-approved`, che la scheda S110 non era passata da Ascanio e che l'anteprima non l'aveva vista nessuno; su S122 «diamogli un loghetto»; sul pannello — «le scritte in un pannello che si apre toccando uno qualsiasi dei loghetti»; su #2038 — «se ci sono già dati, un prompt deve chiedere che fare e se applicare a tutti».

**Risposte di Ascanio (card S129):** «scriviamo monofase 230V e Trifase 400V» · «lo uso così, solo le celle con asterisco fermano il processo, sul singolo impianto non su tutti; se l'ordine delle colonne viene variato si deve fermare e dire quali colonne non vengono riconosciute» · «[password logger] può succedere: salva solo i dati che hai, dai un avviso ma non fermare nessun impianto». Due su tre **hanno rovesciato scelte nostre**: la regola severa sul logger l'avevamo scritta noi immaginando il caso.

**Errori miei:** ho dato per bloccato l'intero browser dopo un solo tentativo — bastava una scheda nuova, come mi ha fatto notare Davide, e infatti funzionava. Ho poi bloccato **due** schede aprendo il selettore file, cosa prevedibile dal nome del bottone. Ho dato agli agenti un comando (`npm run worktree:link`) che su `beta` non esisteva, causando il terzo svuotamento di `node_modules`. Ho scritto un AC contro un comportamento che non avevo verificato (la provincia inventata). Ho consegnato un SQL con il `COMMIT;` commentato «per prudenza»: la transazione è rimasta aperta e la correzione è stata annullata — la prudenza si è mangiata l'operazione, e me ne sono accorto solo perché ho verificato invece di fidarmi del «ho fatto».

**Numeri:** 7 issue in produzione (+26 il giorno prima) · 8 PR mergiate (7 in beta, 1 in main) · 5 loop, **1.2 tentativi medi** · 13 issue nuove · `main` e `beta` allineate a 0 commit dopo la promozione · 6213 test verdi · 4 svuotamenti di `node_modules` · 7 impianti caricati da Ascanio, 2 difetti trovati da lui in 15 minuti · backend 200 in 0.32s.

---

## 2026-09-07 — Sette PR in beta, zero in produzione: la divergenza beta↔main viene al pettine

> **Corretta l'08/09.** Questa voce era stata scritta a metà sessione e il suo
> «In produzione: niente» è diventato falso poche ore dopo: la sessione è
> proseguita e in serata sono andate in produzione **26 issue**. La
> riconciliazione è stata fatta lo stesso giorno (#2010, PR #2011 alle 15:55) e
> la promozione in blocco è seguita alle 18:32 (PR #2013). Il dettaglio è nella
> voce dell'08/09.
>
> Lasciata la formulazione originale invece di riscriverla: una retrospettiva
> che si corregge dichiarandolo è utile, una che si riscrive per sembrare
> esatta è la cosa contro cui esiste la voce del 06/09.

**In produzione:** niente *al momento della scrittura* — poi 26 issue in serata, vedi la nota sopra. Quattro dry-run di promozione, due PR verso `main` aperte e chiuse (#2008, #2009).
**In beta, aspetta:** #1991, #1992, #1997, #1999, #1983, #1982, #1976, #2000 — tutte con `qa-approved`, bloccate dalla divergenza. Aspetta Davide: le 16 migration e la prova dal vivo di #1797 (card S50).
**Aperto:** la riconciliazione `beta`↔`main` — 67 commit di divergenza, 31 file in conflitto. È il prossimo lavoro, deciso da Davide.

**Ha funzionato:** cinque loop, tutti chiusi verdi (#1991 al 4° tentativo, #1997 al 2°, #1992 al 3°, #1999 al 2°, #2000 al 2°). Due si sono fermati da soli PRIMA di scrivere codice perché la root cause non reggeva — #2003 (recharts non esiste in questo progetto) e la diagnosi di #1976: la guardia «se la tua lettura contraddice gli AC, restituisci blocked» ha pagato due volte su cinque. Misure vere: /things da 104 a 37 richieste, `zcs-proxy` da 7 in crescita a 5 stabili, le 4 finestre `historical_readings` a 2.

**Non ha funzionato → regola nuova:**
- Le schede aperte dagli strumenti browser nascono `hidden` e Chrome non vi esegue `ResizeObserver`/`rAF`: ogni misura sul rendering è priva di significato, quelle di rete no → memoria `feedback_misure_browser_scheda_nascosta`. Due giorni di diagnosi su un difetto inesistente, tre issue scritte su numeri falsi.
- La promozione selettiva può portare in `main` una migration senza il codice che la accompagna: #1967 inseriva `MAE-INV-08`/`MAE-BAT-13` nel catalogo DB mentre #1819 (che li definisce in TypeScript) cadeva per conflitto. Intercettata dalla CI, non da noi.
- I cherry-pick delle promozioni selettive fanno divergere `main` da `beta`: 67 commit, e la divergenza si autoalimenta → memoria `project_riconciliazione_beta_main`.

**Decisioni di Davide:** «promuovi comprese le tecniche» (11 issue senza card etichettate da noi); sul nuovo template impianti — password logger **in chiaro**, template adotta il vocabolario di #1916, un file solo per ora, colonnina e altri dispositivi fuori, POD/CENSIMP/CER solo conservati; «il prossimo step è la riconciliazione».

**Errori miei:** ho concluso che un agente non avesse fatto il lavoro guardando un branch non ancora aggiornato, e ho rifatto la riconciliazione in parallelo producendo un commit che **non compilava** (import orfano) e con gli accenti scritti in ASCII; il suo era migliore e l'ho ripreso. Ho scritto #2003 due volte su prove inesistenti — la prima citando `recharts`, che in questo progetto non c'è. Ho dichiarato «la copertura del test è salva» su un test che in realtà era più debole di come l'avevo descritto.

**Numeri:** 0 issue in produzione · 8 in beta pronte · 7 PR mergiate in beta · 5 loop, 2.6 tentativi medi · 6 issue nuove aperte (#1997, #1999, #2000, #2004, #2005, #2006) + 2 il giorno prima · 1 issue chiusa come inesistente (#2003) · backend 200 in 0.55s, connessioni max 33/60, zero episodi MAE-DB-CONN.

## 2026-09-06 — Ventisei ore: sette issue in beta, e cinque documenti che dicevano il falso

**In produzione:** nulla di nuovo dal codice. Applicate a mano due migration di
catalogo allarmi (`MAE-BIZ-07` di #1822 e i sei orfani di #1967): il catalogo passa da
46 a 53 righe e `alert_events` non ha più codici senza descrizione.
**In beta, aspetta:** #1930, #1822, #1978 (Ascanio, card S70 in Revisione · S36/S48 in
Lavorazione) · #1968, #1967, #1964, #1972, #1977, #1799 (nessuna card, lavoro tecnico) ·
#1988 e #1989 pronte ma non mergiate (noi: una misura di connessioni, un ordine da
concordare).
**Aperto:** #1990 (fix dentro migration già applicate — nessuno sa quanti casi ci sono),
#1982/#1983/#1984/#1985 (le quattro figlie di #1976), #1973/#1974/#1975 (le spie),
#1915 (expand/contract, non lanciata: il suo merge accende scritture automatiche in prod).

**Ha funzionato:** nove loop, sette convergono (mediana 2 tentativi, uno al primo giro).
Il reset del worktree introdotto a metà sessione ha fatto centro subito: le tre PR
successive hanno tutte base sulla punta di `beta`, contro i 150 commit di ritardo che
avevano bruciato 811k token. La bonifica e2e di #1972 ha smesso di accumulare da sola:
da ~8 schede l'ora a zero. Il verificatore dei tre diff finali: 29 AC verdi, **zero fail**,
8 in sospeso e tutti `[Campo]`/`[Azione]`, cioè non nostri.

**Non ha funzionato → regola nuova:**
- Un verdetto mal formattato uccideva l'intero workflow (`agent()` lancia, non torna
  `null`): guardia doppia nel template → skill `dev-loop` 2.1.0.
- Il worktree del developer si dà per allineato e non lo è → reset esplicito + verifica
  del merge-base come prima istruzione, skill `dev-loop` 2.2.0.
- `/approva` significava due cose: ora `/approva` = beta, `/promuovi` = produzione →
  `FLUSSO.md` sezione nuova, skill `approva` → `promuovi` (PR #54, da mergiare).
- Le migration di dati legate al codice sono una terza categoria fra espansive e
  distruttive: viaggiano col merge, e il criterio non è il tipo di istruzione ma se il
  codice ancora in produzione regge il nuovo stato → #1915.

**Decisioni di Davide:** «togli continue-on-error quando l'inventario è pulito» ·
«se maestro rule evaluator è monitorato e sicuro, riattiviamolo» (resta acceso) ·
«dividi i difetti» (#1976 → quattro figlie) · «mantieni il periodo fetchato» (#1799) ·
«sostituiamo Fable con Opus dappertutto» · «/approva riguarda ciò che portiamo in beta,
promuovi ciò che promuoviamo a main» · «aspettiamo Ascanio» sul filone Alert.

**Errori miei:** cinque diagnosi sbagliate scritte da me nelle issue e corrette dai piani
— la perdita e2e attribuita ai run cancellati (era un token letto con la chiave di
produzione dal 30/08, quindi **nessuna** pulizia mai), la codifica data per Latin-1 (era
Windows-1252, e il fix ovvio avrebbe prodotto un terzo strato di danno), un codice orfano
dove erano sei, un percorso troncato «qualche volta» che lo è **sempre**, e due AC
irraggiungibili come li avevo scritti. Poi: tre errori in un giorno sullo stesso job di
migration (ref sbagliato, workflow sbagliato, ordine sbagliato) senza mai aprire
`FLUSSO.md`, dove l'ordine giusto era scritto. E un'affermazione inventata in una skill
condivisa — «Opus consuma di più» — smentita dai dati appena Davide l'ha contestata.

**Numeri:** 0 issue in produzione, 7 mergiate in beta, 14 issue nuove aperte, 9+3 loop,
~9,4 milioni di token nei subagenti, 4.400 chiamate a strumenti, limite di sessione
esaurito 3 volte. Backend: 200 in 0,58 s. Connessioni DB nelle 15 ore misurate: mediana
12 su 60, massimo 33, zero avvisi.

**Il filo di tutta la sessione:** quasi tutto il valore è venuto da **documenti che
mentivano**, non da codice scritto bene. Un cron dichiarato in pausa e acceso da quattro
giorni (#1968). Sei sezioni scritte dove ce n'erano cinque (PR #50). Una skill che
consigliava esattamente l'errore poi costato tre ore (PR #51). Un limite di PostgREST
scoperto mesi fa, annotato in un file e mai propagato (#1984). Un aggregato fermo dal 24
marzo con il cron che gira e riesce ogni notte (#1982). Una migration «applicata» il cui
fix non è mai arrivato in produzione (#1990). Il filo comune: **niente diventava rosso**.
La CI verde, il cron riuscito, la pulizia che non lasciava tracce fallite ma assenti, il
grafico che mostrava una curva — falsa, ma una curva.

## 2026-09-03/04 — Audit sicurezza in prod, 28 issue promosse, nasce il workflow v2

**In produzione:** #1937 (edge function e RPC della coda QA chiuse a chiunque), #1938 (CI senza testo iniettabile, host key VPS fissa), #1939 (isolamento fra aziende su note, POD e credenziali; audit RLS con quattro controlli nuovi; CORS allowlist), #1949 (SQL in prod solo con conferma scritta), #1956 (numero corto S123 su ogni card), #1960 (campionatore delle connessioni DB ogni minuto); 15 issue approvate da Ascanio e nostri fix (#1816, #1818, #1817, #1820, #1920, #1934, #1873, #1875, #1877, #1878, #1879, #1889, #1898, #289, #1941) e 7 nel secondo giro (#1917, #1919, #1921, #1928, #1933, #1887, #1888).
**In beta, aspetta:** #1958 Producer (Ascanio, card S77 in Revisione); #1819, #1884, #1916, #1918, #1929 (intrecciate con #1821 e #1797: si promuovono in blocco quando #1821 è approvata e #1797 sistemata).
**Aperto:** #1945 token per dispositivo edge (Backlog); #1940 GDPR (decisioni Gaia/Davide); #1930 algoritmo attivo da riscrivere con la risposta di Ascanio; 8 richieste di modifica di Ascanio nei commenti di approvazione da aprire come issue; PR #49 workflow v2 (aspetta /approva); CLAUDE.md globale da riscrivere; secret Vault Telegram; quale pagina ha fatto cadere il DB alle 11:05.

**Ha funzionato:** il loop planner → developer → verificatore con planner e verificatore sul modello di sessione: #1939 16/16 AC in 2 tentativi, #1949 6/6 in 1, #1958 7/7 in 1, #1956 8/8 in 3, #1960 6/6 in 2. Il verificatore che esegue lui lint/test/build ha trovato cose vere (dipendenze mancanti in una promozione, `model` non esplicito in un template). La promozione selettiva con cherry-pick guidato a gruppi ha portato 22 issue in prod in due giri. Il punto 0 del flusso (dalla card di Ascanio alla issue) provato su #1958: card letta nei dati, codice verificato, issue con AC, link `qa_task_issues`, loop, beta, migration in prod, prova dal vivo, Revisione — in una mattina.
**Non ha funzionato → regola nuova:**
- Migration di ri-schedulazione cron scritta sui nomi delle migration, non su quelli vivi in prod (3 job scoperti, 1 che sarebbe stato acceso) → «la migration cambia l'header, non decide cosa gira» (FLUSSO.md punto 6; memoria `feedback_migration_cambia_header_non_decide_cosa_gira`).
- test-maestro legge i dati di prod, le migration di beta no: badge assenti (#1956), CHECK violato (#1958) → «le migration additive vanno in prod prima della prova» (FLUSSO.md 4b; beta-release Step 3.4).
- Opus 529 per un'ora ha fermato tre loop → orchestratore su Fable, developer Sonnet, retry su `null` e non su eccezione (dev-loop).
- «Conflitto» di promozione = quasi sempre package.json/PROJECT.md → cherry-pick guidato a gruppi (skill `approva`; memoria `feedback_promozione_conflitti_versione_changelog`); i conflitti veri restanti sono filoni intrecciati e si promuovono in blocco.
- La promozione parziale di #1938 lasciava su main la forma vecchia di uno step → il debito si annota sulla issue che lo introduce e si chiude nello stesso giro (fatto su #1898).
- Ascanio approva spostando la card in BackLog e scrive spesso una richiesta nello stesso commento; la label `qa-approved` la mettiamo noi dopo aver letto i commenti (FLUSSO.md punto 5).
- Il DB è caduto con tre sessioni contemporanee e nessuna misura presa durante → monitor #1960; i cron falliti sono il sintomo («job startup timeout» è attesa, non occupazione).
**Decisioni di Davide:** «il flusso resta quello usato per le ultime issue»; workflow v2 da zero, vecchio in archivio; orchestratore «Fable 5», developer Sonnet 5; niente piano Team GitHub (conferma scritta sul dispatch al posto del reviewer); niente taglio Small su Supabase per ora, «ottimizziamo e monitoriamo»; le migration additive vanno in prod prima della prova; ogni sessione finisce con la chiusura (questa skill).
**Errori miei:** una host key trascritta a mano con un carattere sbagliato (secret creato due volte) → i valori lunghi passano solo dai tool, mai riscritti; ho detto che i cron falliti «mangiano connessioni» prima di misurare → misurare prima di spiegare; una junction node_modules dentro un worktree poi rimosso ha svuotato quello del developer → mai junction in un worktree da cancellare; ho lasciato la mia scheda Chrome loggata come Ascanio durante il crollo → le sessioni di prova si chiudono appena finita la prova.
**Numeri:** 28 issue in produzione in due giorni, 5 loop v2 con media 1,8 tentativi, 1 incidente DB di 15 minuti, 0 rollback, 2 giri di promozione automatica + 2 a mano.
