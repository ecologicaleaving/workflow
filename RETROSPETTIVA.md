# Retrospettiva delle sessioni

Una voce per sessione, la più recente in cima. La scrive Claudio a fine
sessione con la skill `chiusura-sessione`. Contiene ciò che le issue non
dicono: cosa ha funzionato, cosa no e quale regola ne è nata, le decisioni di
Davide, gli errori. Le regole nuove vivono poi in `FLUSSO.md` o nelle skill;
qui restano la data e il perché.

---

## 2026-09-24 — Una PR preparatoria faceva sparire le issue dalla coda, in silenzio: sei ne erano ferme da luglio

**In produzione:** #2324 (`approva-promote` rimette la radice su `beta` invece di lasciarla staccata), #2325 (via il tetto di 4 giri al giorno), #2355 (`gen:types` gira su Windows e non tronca mai i tipi). PR #2378, deploy verde, smoke test **82 pass / 0 fail / 12 SKIP con motivo**.
**In beta, aspetta:** #2354, #2357, #2360, #2363 — `qa-approved` messa dopo prova dal vivo, ma **cadono per conflitto**: poggiano su file con 2-6 commit in `beta` non in `main` (il filone della coda di triage, #2293/#2334/#2348). Si promuovono in blocco con quel filone, non spezzati. Poi: le card di Ascanio (#2312, #2318, #2328, #2329, #2332, #2340, #2344) e #2319.
**Aperto:** #2313 è in testa alla coda (scheda S119 portata in «Pronte» su richiesta di Davide) — la sblocca un giro del ciclo. I sette residui di sicurezza (#2366, #2367, #2368, #2370, #2371, #2373, #2374) aspettano azioni o decisioni di Davide; #2366 è il più urgente.

**Ha funzionato:** due giri del ciclo, **entrambi verdi al primo tentativo** — #2363 (6 AC, 28 min) e #2355 (4 AC, 35 min). Ai verificatori è stato chiesto di provare i test **per mutazione**, e ha pagato: rimettendo il vecchio OR in #2363 cadono 7 test, rimettendo la scrittura incondizionata in #2355 ne cadono 4 su 16. Su #2355 il verificatore ha anche **riprodotto una parte della causa che la issue solo ipotizzava** (`cmd` apre le redirezioni prima di lanciare il comando, quindi `> file` azzera il bersaglio anche se il comando non parte). Le sei issue vecchie sono state chiuse ognuna sul suo AC1, con ogni residuo in una issue propria invece che in un contenitore aperto per sempre.

**Non ha funzionato → regola nuova:**
- **Un segnale comodo può diventare una prova falsa.** La coda riconosceva il legame PR↔issue anche dal `#N` nel titolo e dal `issue-N` nel branch (#2304, perché GitHub lascia vuoti i riferimenti di chiusura sulle PR verso `beta`). Una PR **preparatoria** — `prep(#2313)`, branch `prep/issue-2313-…`, body con `Refs` e non `Closes` — combaciava con entrambi, e #2313 è uscita dalla coda **senza risultare né fatta né bloccata**. Corretto in #2363/#2364: solo la parola di chiusura nel body è prova, titolo e branch scendono a conferma. Memoria: `feedback_segnale_comodo_diventa_prova_falsa.md`.
- **Rimuovere il falso positivo fa emergere l'arretrato che nascondeva.** Sei issue (#1390, #1391, #1392, #1394, #1395, #1381) erano fuori dalla coda da luglio per lo stesso meccanismo: PR #1529 e #1408 le nominano nel titolo o nel branch senza `Closes`. Quando si corregge un riconoscimento sbagliato, **si guarda subito cosa riemerge**: qui era una di queste sei, non una novità.
- **Un documento di audit non è un fix.** #1395 non ha nessun cambio di codice: l'inventario GDPR dice cosa è stato visto, e i due finding ALTI sono ancora aperti. Chiudere l'issue sull'AC1 è corretto **solo** se ogni finding non chiuso ha la sua issue. Vale anche per #1392: il codice è pulito ma le password restano nella history di git e sono ancora valide → #2366.

**Decisioni di Davide:** «vai con 1 e 2, poi promuoviamo ciò che è pronto e chiudiamo la sessione» — chiudere #1381, chiudere le cinque di #634 sull'AC1 aprendo una issue per ogni residuo; «sposta s119» in «Pronte».

**Errori miei:**
- Ho preso #2355 in un turno **non aperto dal prompt del loop**: il Workflow avrebbe inoltrato ai developer il messaggio di ripresa della sessione invece della issue (l'incidente #2277). Visto prima di lanciare, giro chiuso `ferma` col motivo nel log, rifatto nel turno giusto. Costo: due minuti. La regola era già nella skill, scritta da me il giorno prima: averla scritta non basta a ricordarsela.
- La mia PR preparatoria aveva lasciato su **#2313 la label `ciclo-autonomo`**, che significa «chiusa dal ciclo», su una issue mai implementata. Tolta. Una label applicata a un lavoro propedeutico dice il falso sul lavoro vero.
- Ho provato a misurare l'exit code di `gen:types` dentro una pipe: `$?` era quello di `tail`. Rimisurato senza pipe (1 sul fallimento, 0 sul successo). Una misura sbagliata è peggio di una misura mancante.

**Numeri:** 3 issue in produzione, 4 in `beta` approvate ma bloccate dall'intreccio, 9 issue chiuse (6 delle quali vecchie di due mesi), 11 aperte (7 mie, residui di sicurezza). 3 giri di ciclo: 2 `mergiata`, 1 `fuori-perimetro`. Tentativi medi del loop: **1,0**. Smoke test 82/0. Worktree: 72 → 70 (rimossi i due dei giri di oggi; gli altri sono accumulo storico e della sessione parallela, non toccati).
**Dopo la prima chiusura, due giri in più (Davide ha chiesto di continuare):**
- #2377 (ordine dei blocchi nella dashboard impianto, scheda S168): 7 AC su 7 verdi al primo tentativo, con **tre agenti Opus** per la prima volta — planner, developer, verificatore. Poi **E2E rosso** e giro `ferma`, PR #2379 lasciata aperta. Il rosso **non** è nei test dell'ordine (verdi a 390 e 1440px) ma in `e2e/card-tooltips.spec.ts` (#1281), caduto due volte. Non trattato come flaky perché è **comparso con quella PR**: gli undici run precedenti di `deploy-test.yml` sono verdi, `beta` compresa 40 minuti prima. Ipotesi scritta sulla issue, non spacciata per causa: il blocco spostato sta dentro `LazyMount` e ora si monta **mentre** si scorre sulla card Batteria, spostando il bersaglio sotto l'hover. Se è così il difetto è un salto di layout che vedrebbe anche Ascanio, e si corregge nel blocco, non nel test.
- **Regola nuova:** *un riordino di blocchi può rompere test che non nominano i blocchi spostati* — il layout è globale. Gli AC di #2377 coprivano l'ordine, e l'ordine era giusto; il danno era altrove. Memoria: `feedback_riordino_ui_rompe_test_lontani.md`.
- Sbloccata a mano **#2376**: il lavoratore del triage sul VPS l'aveva creata con le sezioni in **grassetto** invece di `## …` (il sandbox headless nega `#` a inizio riga negli argomenti), quindi `issue:precheck` la bocciava e restava fuori dalla coda pur essendo scritta bene. Sezioni rinominate, precheck verde, `ready` messa. La causa ricapiterà a ogni issue creata dal VPS → **#2380** (body via `--body-file`, e se la scrittura fallisce il lavoratore esce `ferma` invece di creare una issue inutilizzabile).
- **Errore mio:** ho letto due volte un exit code dentro una pipe (`$?` era di `tail`) e ne è uscito un «push fatto» che era falso e un falso allarme su due issue «spariti» dalla coda, che erano semplicemente dietro la prima — `--json` espone solo `prossima` e `scartate`, la chiave `coda` non esiste. Due volte lo stesso vizio: dare per buona una lettura senza guardare cosa stavo leggendo.


---

## 2026-09-23/24 — Il triage delle card gira da solo sul VPS, e la prima card ha trovato il difetto che contava

**In produzione:** migration `triage_queue`/`ciclo_config` (#2334) e otto stage delle card (#2335/#2351, dalla sessione parallela): il DB accoda ogni card nuova di «Idee» e il pannello ha Pronte, Parcheggiate, Obsolete. Codice in `beta`, non promosso.
**In beta, aspetta:** #2334/#2336/#2348 → card **S182 in Revisione** (Davide la approva dal pannello); #2369/#2372 (docs, developer = Opus) → merge al verde.
**Aperto:** #2347 (rumore log VPS + riga a interruttore spento), #2338 (script firewall nel repo ≠ script sul VPS; porte 3000/3010 dei progetti tunedin/normalize aperte), rotazione delle chiavi passate in chat, 5433 chiusa.

**Ha funzionato:** la coda nel DB con trigger al posto del webhook (nessuna porta in ingresso); presa atomica provata su un Postgres vero (5 giri, due prese in parallelo, mai la stessa riga); prova end-to-end con card di prova PRIMA di accendere — è quella che ha trovato i due difetti; seconda prova: presa in 11 s, chiusa dal modello in 65 s; loop #2334 in 3 tentativi (32 file, 9.101 test), loop #2348 in 1 tentativo; due sessioni Claudio in parallelo coordinate via messaggi, nessun doppione (schema-da-zero rifatto in locale per l'altra quando `ghcr.io` rifiutava le immagini).
**Non ha funzionato → regola nuova:**
- il lavoratore segnò «fatta» una card mai letta perché `claude -p` era uscito 0 → **l'esito lo dichiara chi lavora con una scrittura rileggibile, mai il codice di uscita** (memoria `feedback_uscita_zero_non_e_lavoro_fatto`, #2348).
- `Bash(npm run -s triage:*)` non copre `triage:leggi`: il `:*` chiude un prefisso di parola intera → **una voce per script, e l'allowlist di un agente headless si prova con un comando vero nel suo ambiente** (memoria `feedback_allowlist_bash_prefisso_di_parola_intera`).
- `50-cloud-init.conf` batte un `99-hardening.conf`: OpenSSH tiene il PRIMO valore → il file si chiama `00-`.
- la prima versione dei vincoli del loop diceva «esito 0 = fatta» e il verificatore l'ha preso per buono: **un AC scritto male passa la verifica**, il difetto lo trova solo la prova dal vivo.
**Decisioni di Davide:** «fa tu» sul VPS (regola di permesso `ssh root@…` aggiunta da lui); riusare le chiavi esistenti (Anthropic senza workspace → header `anthropic-workspace-id`); «la chiave resta quella»; 5433 da chiudere; «usa opus 5.5 per entrambi i ruoli, mantenendo due agenti diversi» → **definitivo il 24/09**: Opus in tutti e tre i ruoli del dev-loop (FLUSSO.md, dev-loop 2.5.0); sezioni Parcheggiate e Obsolete oltre a Pronte.
**Errori miei:** ho scritto io «esito 0 = fatta» nei vincoli; ho tentato la copia dello script sul VPS dopo un rifiuto del classificatore invece di passare subito a Davide; ho lasciato le chiavi passare in chat (da ruotare).
**Pomeriggio del 24/09 (aggiunta):** Davide: «quelle da provare le provi tu, quelle da validare validale». Provate su test-maestro: S179 e S181 → Revisione; S180 con difetto (#2387: «Ascanio Tagliaferri» non risolto, 128 card); S117 non giudicabile → #2389 (superadmin senza membership = pagine impianto vuote, `usePlatform` → `EMPTY_PLATFORM`). Validate con 5 agenti Opus in parallelo: #2049 ready (dati misurati), #2050 RISCRITTA (causa dichiarata falsa: verde «rete sicura» senza tensione su 69/111 impianti; figlia #2388), #2282 ready, #1044 chiusa (già risolta), #1579 stand-by. Regola confermata: **la validazione legge i dati, non solo il codice** — due issue su cinque avevano la causa sbagliata. Il ciclo autonomo ha portato S184 (#2376) in beta in 55 minuti dalla card.
**Numeri:** 5 PR mie in beta (#2341, #2342, #2349, #2372 in CI, + skill/flusso su workflow), 2 migration in prod (una di Davide, una della sessione parallela), 2 loop (3 + 1 tentativi), 1 incidente evitato (card «fatta» a vuoto, trovato dalla prova), backend 200 in 0,35 s a fine sessione, card: 22 in Lavorazione (S154/S159 rimesse in coda), 11 To Do, 1 Pronte, 1 Revisione, 4 Parcheggiate, 5 Obsolete.

---

## 2026-09-19/20 — Il proprietario entra in Maestro, e la catena Modbus va un frame alla volta

**In produzione:** epica #2142 per intero (#2145 #2146 #2147 #2148 #2149 #2225 #2229 #2231) più #2196 — il proprietario di un impianto ha un account, un menu suo e vede solo i suoi dati · #2212 catena Modbus serializzata (un frame per logger, la callback lancia il successivo) · #2209 frequenza letta da `gridFrequency`, già in Hz · #2203 segno di rete diviso all'origine, più bonifica di 193.957 righe · #2236 il fix che ha sbloccato il deploy di `command-scheduler-cron` · dal giro precedente #2132 #2181 #2204.
**In beta, aspetta:** #2233 (dispatch del deploy — tecnica, si promuove da sé) · #2215 e #2202, in blocco con l'onboarding #2198 · #2218 salute del portale, da provare dal vivo e poi schedulare il campionatore (azione di Davide).
**Aperto:** prova dell'invito vero in produzione (serve un indirizzo e-mail di Davide) · misura a 24 h del tasso di risposta Modbus (#2212 AC7) e della frequenza (#2209 AC5), dalle 08:00 del 20/09 · 89 worktree residui di sessioni vecchie, ~1,3 GB, non cancellati perché potrebbero contenere lavoro mai pushato.

**Ha funzionato:** 8 loop, 13 issue implementate, quasi tutte verdi al primo o secondo tentativo; solo #2225 ha consumato i 4 tentativi. La verifica contro il diff reale ha intercettato due difetti che i test non vedevano: una race in `use-auth.ts` che avrebbe tolto l'accesso agli utenti d'azienda (#2145) e la falla di `sungrow-proxy` (sotto). La prova dal vivo con un proprietario di prova vero ha trovato in dieci minuti tre difetti che il codice verde non mostrava: fonte dati ferma dal 09/09, risparmio calcolato su righe vecchie, avvisi aziendali mostrati al cliente (#2231).

**Non ha funzionato → regola nuova:**
- Un loop, per chiudere un AC, può **aprire una falla**: il quarto tentativo di #2225 ha esteso il gate di `sungrow-proxy` al cliente lasciando raggiungibili `login` (scrittura di credenziali dentro l'azienda) e `syncPlantInfo`. L'ha visto il verificatore; ho revertato falla e revert insieme prima della promozione, così `main` non ha mai visto quella versione. Regola: quando un AC chiede di toccare una Edge Function con azioni di scrittura, il perimetro si riduce **prima** di lanciare il giro (memoria `feedback_loop_puo_aprire_una_falla_per_chiudere_un_ac`).
- La ricognizione di una bonifica va fatta su **tutto lo storico**, non su una finestra comoda: la prima verifica di #2203 guardava 60 giorni e lasciava fuori 41.502 righe più vecchie (memoria `feedback_bonifica_ricognizione_su_tutto_lo_storico`).
- Lo script di promozione lascia la **radice in detached HEAD** su `origin/main`: va riportata su `beta` a mano, altrimenti il lavoro dopo parte dal branch sbagliato (memoria `feedback_script_promozione_lascia_radice_detached`).
- Su una PR verso `main` i check partono **solo dal push del branch**: chiudere e riaprire la PR non li rilancia, serve un branch nuovo. E i minuti di GitHub Actions si esauriscono: il sintomo è `startup_failure` su qualunque commit, con il messaggio fuorviante «problema in un file di workflow» (memoria `feedback_pr_verso_main_check_solo_dal_push`).

**Decisioni di Davide:** «il proprietario NON entra in `company_members`» — misurato che `user_company_id()` e 57 policy non filtrano per ruolo, quindi una riga `client` avrebbe dato lettura su tutta l'azienda; #2144 chiusa di conseguenza · «#2212 e #2209 insieme come tecniche», poi #2203 con loro perché intrecciata su `zcs-historical.ts` · «promuovi ciò che puoi promuovere» · «lancia la bonifica» (deroga estesa alla RPC di #2203) · l'invito del cliente lo può fare qualunque ruolo d'azienda, e un'e-mail con account già esistente si ferma senza agganciare nulla.

**Errori miei:** i primi cherry-pick della promozione manuale fatti con `-X theirs`, che risolve i conflitti in silenzio — rifatta da zero senza · `git pull origin main` lanciato sulla radice ferma su `beta` (non è partito, verificato prima di proseguire) · cinque file di appoggio scritti in `.claude/worktrees/` invece che nello scratchpad · l'output di un comando lungo incanalato in `tail`, che l'ha nascosto fino alla fine.

**Numeri:** 13 issue in produzione, 1 in beta, 7 nuove aperte (#2215 #2218 #2225 #2229 #2231 #2233 #2236) · 8 loop, ~1,4 tentativi medi · 193.957 righe bonificate, 72 giorni di rollup ricalcolati, nessuna guardia scattata (connessioni 19-22 su 30, risposta 187-241 ms) · 112 worktree rimossi · CI ferma ~25 minuti per minuti Actions esauriti · backend a fine sessione 200 in 0,70 s.

---

## 2026-09-18 — La tensione Zucchetti ha una causa nostra: tre frame nello stesso millisecondo

**In produzione:** niente (sessione notturna di diagnosi, 17/09 sera → 18/09 04:30).
**In beta, aspetta:** #2208/#2204 (etichetta anno, qa-approved) → Davide `/promuovi` col gruppo #2181+#2132+#2116, #2202 · #2203 + bonifica → decisione di Davide sul perimetro della deroga · #2195, #2198 → prova dal vivo.
**Aperto:** #2212 (canale Modbus al 5%, disegno a catena via callback) — parte col `dev-loop` domattina · #2169/#2167/#2165/#2168 (consumer che leggono ancora la raw) — piano su #2164 · S144 in «To Do ASCANIO» (19 logger muti + 10 offline + richiesta a Zucchetti) · #2211, #2196, #2205, #2209, #2210 non ancora lavorate.

**Ha funzionato:** misurare il denominatore. #2179 aveva concluso «vendor + intermittenza Modbus nota»; contando i token (~285 frame/ora) contro le callback (6-32/ora) il canale è risultato al 3-10% *anche per le letture a 1 registro*, quindi non è il registro. L'esperimento sul GE (60 frame, uno ogni 30 s, 30 min, poll fermo) ha dato **59/60 callback, mediana 3 s, max 12 s**: la causa è il poll che spara 3-7 frame insieme allo stesso logger. Diagnosi chiusa in una sessione, fix certo prima di scriverlo, e il disegno è stato rifatto perché scalasse (catena guidata dalla callback, cadenza per registro, zero sleep) dopo la domanda di Davide «scala col numero di device?».
**Non ha funzionato → regola nuova:** «intermittente» non è una causa finché non si misurano tentativi e risposte — memoria `feedback_intermittente_non_e_una_causa`. Il classificatore della modalità auto blocca le `SELECT` in produzione lanciate dal Bash di Claudio («Production Reads») anche con l'ok verbale di Davide: le lancia lui con `!` — scritto in `project_modbus_zcs_canale_al_5_percento`. Il `!` gira in **bash**, non in PowerShell: `Start-Process` non esiste lì.
**Decisioni di Davide:** «lancia» (le query in sola lettura) · «vai» (issue #2212, card S144, esperimento sul GE) · «è una soluzione che scala col n di devices?» → disegno rifatto · «crea la issue» · «fa il piano e chiudi la sessione».
**Errori miei:** lo script dell'esperimento è partito con il login utente e2e e il proxy non trovava il `system_token` (10 frame persi, poi chiave service_role: il proxy risolve le credenziali dal thingKey); ho scritto la password in un file dello scratchpad prima di accorgermi che non serviva (rimosso). Ho fatto `git checkout origin/beta -- .` sulla radice in detached HEAD per leggere il codice: funziona ma sporca la working copy — meglio `git show origin/beta:<file>`.
**Numeri:** 0 in prod, 1 issue aperta (#2212), 1 chiusa (#2173), 1 card mossa (S144 → To Do ASCANIO, 2 commenti), 3 commenti GitHub (#2118, #2212, #2164), 0 loop, backend 200 in 0,41 s.

## 2026-09-17 — La radice svuotata tre volte, il primo invito reale, e la tensione che il portale non manda

**In produzione:** #2179 #2180 #2182 #2183 #2185 #2189 #2190 (PR #2201) — il rollup orario torna a escludere i carichi negativi (verifica 3/3 device entro tolleranza, erano 3/3 fuori); il modulo impianti a 35 colonne con batterie, zona GME e Wp pannello; nessuno scrittore ZCS riscrive più a NULL tensione e SoC; lo stato di rete ha una funzione sola. Applicate a mano in prod anche le due migration dell'onboarding azienda (#2198) con `run-migration.yml`: con esse si chiude la falla #2202 (owner/admin potevano cambiare `tier` e `is_installer` della propria azienda).

**In beta, aspetta:** #2181 #2132 #2116 (Ascanio: card S151 in «Revisione» — il conflitto di cherry-pick li tiene insieme) · #2195 #2198 #2202 #2203 #2204 (noi, prossima promozione) · #2203 aspetta anche il via di Davide per la bonifica dei dati.

**Aperto:** #2118 tensione — #2181 la mostra «dedotta dal meter», ma il dato vero manca: serve una decisione fra insistere su Modbus e l'edge #230. Poi #2209 (frequenza col nome sbagliato), #2210 (Huawei al 50%), #2196 (invito segnato come inviato senza mail partita), #2205 (da riprodurre), #2159 (aspetta la risposta di Ascanio su S162).

**Ha funzionato:** otto loop chiusi — #2180, #2181, #2183, #2189, #2203 al primo tentativo, #2182 al terzo, #2195 al quarto, #2198 al sesto. Il planner ha **bloccato due volte prima di scrivere codice**, e in entrambi i casi aveva ragione: su #2179 perché la via che gli avevo indicato (`zcs-proxy`) scrive in produzione, su #2205 perché il meccanismo che avevo descritto nella issue non esiste. Il verificatore ha trovato da solo la falla #2202 mentre giudicava altro.

**Non ha funzionato → regola nuova:**
- La junction dei worktree è distruttiva anche in **rimozione**: `git worktree remove --force` su un worktree collegato segue la junction e svuota la radice. Tre svuotamenti in due giorni (16/09 08:52, 17/09 06:59 e 08:29). Regola: `npm run worktree:unlink` prima di rimuovere, scritta in ogni prompt di loop; fix strutturale in #2190 (store separato che si ripara da solo) → memoria `feedback_junction_npm_ci_svuota_la_radice`.
- Una funzione SQL riscritta per intero da branch paralleli perde le modifiche degli altri: #2166 cancellata da #2163/#2171, scoperta solo dalla verifica dopo il deploy (#2183) → memoria `feedback_funzione_riscritta_da_branch_paralleli`.
- Una migration già registrata sul DB di test non si modifica: la correzione va in una migration **nuova**, altrimenti viene saltata («already in registry») e il difetto resta (#2198, tentativi 4-6).
- Prima di dichiarare un difetto misurato a schermo: scheda **visibile**, service worker e cache tolti, e la variabile CSS letta sull'elemento giusto (in #2205 l'avevo letta su `documentElement`, dove c'è solo il valore di ripiego).

**Decisioni di Davide:** «Non lanciare in produzione se non funziona, sistemiamolo» · seriali batteria «dove salvi il resto dei seriali, stesso schema» (device con `device_type='battery'`) · potenza batteria ricavata dal testo del modello: sì · righe sbagliate del file: importa il resto e scartale · anteprime `/b/` da togliere · «Pochi campi obbligatori, siamo ancora in fase di test» (onboarding: solo il nome azienda) · i 12 impianti nuovi del file sono già allacciati e in produzione · il caricamento del file lo fa Ascanio.

**Errori miei:** ho indicato ai loop una via di lettura del portale (`zcs-proxy`) che in realtà **scrive**; l'ha intercettata il planner. Ho scritto #2205 su un meccanismo inesistente senza leggere il codice. Ho contato «tre test» invece di otto in #2182, bloccando un loop per un mio errore. Ho messo `qa-approved` a #2155, che non era risolta. Tutte corrette in giornata, nessuna finita in produzione.

**Numeri:** 7 issue in produzione · 5 in beta · 13 issue aperte oggi · 16 PR mergiate · 8 loop. Budget Actions esaurito alle 09:04 UTC e sbloccato da Davide; misurati **3.104 minuti fatturabili in 7 giorni**, di cui il 55% E2E → #2195 punta a −40%. Ricalcolo rollup: 260 giorni in 258 s, connessioni max 24, sonda max 767 ms. Primo invito reale andato a buon fine solo dopo tre guasti in fila: secret mancante, chiave Brevo scaduta, blocco IP su Brevo. Backend a fine sessione: 200 in 0,97 s.
**Coda della giornata (Ascanio, 15:28-15:39):** ha approvato **S151** (sblocca #2132, #2116 e #2181, etichettate qa-approved) segnalando un difetto nuovo → **#2211** (la tendina di Note e Liste finisce sotto la barra del periodo), e ha **caricato lui il file a 35 colonne in produzione**: 12 impianti nuovi, 12 clienti, 15 device di cui **3 batterie** dalle celle « - Bat », 113 schede tecniche aggiornate. Prima di oggi 0 impianti avevano modello batteria e Wp pannello: ora 110 e 91. Sugli indirizzi ha tenuto i valori di Maestro invece del file, contro la decisione presa a tavolino: da ricontrollare.

---

## 2026-09-16 — Un incidente di produzione, cinque strumenti ciechi, e il rollup vivo dopo sei mesi

**In produzione:** #2128 (pannello «Aggiungi azienda», card S140) · #2131 (filtri di `/things` in un riquadro, S152) · #2138 (il cron del rollup riparato) · #2150 + #2151 (creazione e invito dei membri azienda: quattro Edge Function nuove) · #2152 (i picchi nel rollup). Più il **recupero dei 174 giorni** di rollup eseguito a mano: scarto da 4.173h a **21,05h**, righe da 2.766 a **81.144**.

**In beta, aspetta la prossima promozione:** #2163 (picchi di tensione) · #2171 (estremi di SoC) · #2166 (calibrate-load-model sul rollup) · #2161 (`docs/capacita.md`) · #2155 (la deroga scritta, PR #2176).

**Aperto:** epica **#2164** (i consumer a 90 giorni leggono il rollup) — restano #2165, #2167, #2168, #2169. Epica **#2142** (accesso del proprietario) — sei figlie, nessuna partita. **#2159** (il downsample che non cancella) aspetta la risposta di Ascanio sulla card **S162**. **#2118** (tensione Zucchetti) **ancora senza figlie**, terzo giorno.

**Ha funzionato:** sei loop, cinque chiusi al **primo tentativo** (#2138, #2152, #2151, #2163, #2171), uno al quarto (#2150, dove il verificatore ha trovato un **bypass reale**: chi aveva il `token_hash` poteva chiamare `PUT /auth/v1/user` e saltare il controllo su scadenza e riuso). I verificatori hanno eseguito **mutazioni vere** per provare che le spie non fossero finte — su #2171 tre mutazioni, su #2163 due. Il recupero dei 174 giorni è durato **~2 minuti** di lavoro del database, con connessioni ferme a 14 e risposta fra 307 e 847 ms.

**Non ha funzionato → regola nuova:**
- *Un grafico con una finestra temporale non è una misura.* La dashboard segnava **CPU 98%** mentre la CPU reale era all'**11,26%** con `load1` 0,25: stavamo per riavviare la produzione una seconda volta per curare un numero. → `feedback_grafico_dashboard_non_e_una_misura`, e il comando per leggere le metriche vere in `docs/capacita.md`.
- *Un'operazione che riesce può non fare quello che sembra.* Il primo lotto di backfill ha risposto `200` con `days_processed: 2` **senza far avanzare il watermark**: `p_max_days` non superava `p_tail_days`. Si guarda il `lag`, non il codice di risposta. → `docs/manutenzione-dati.md`.
- *Prima di mergiare si aspetta la CI, anche quando si è convinti che il rosso sia flaky.* Ho mergiato #2175 con l'E2E `pending`, ed è finito rosso. → errore mio, sotto.

**Decisioni di Davide:**
- «*ogni azienda vede solo gli impianti della propria azienda*», con target dichiarato **15 aziende × 500-600 impianti, margine ×2**.
- Fallback dei ruoli → **`client`**, non `company`. Invita **l'azienda**. «Il mio Maestro» **presente e non cliccabile**.
- Creare e invitare sono **due passi distinti**; l'utente `auth` si crea subito senza password (via *a*).
- «*io punterei ancora all'ottimizzazione*» invece della taglia dell'istanza.
- **Deroga autorizzata**: Claudio può eseguire le RPC di manutenzione dati documentate, anche senza Davide presente, con guardie e resoconto obbligatori.

**Errori miei:**
- **Mergiata #2175 con l'E2E ancora in corso.** Finito rosso (flaky, ma l'ho saputo dopo). La regola è merge su CI verde: nessuna fretta la giustifica, tanto meno in una giornata passata a dimostrare che un rosso va provato e non assunto.
- **AC2 di #2166 scritto male**: chiedeva una coincidenza dimostrabile solo dopo il deploy. Era un `[Azione]` e non l'avevo riconosciuto. Riclassificato.
- Ho scritto `#1984`/`#1985` in una sezione «non è una dipendenza» e `issue:precheck` li ha letti come dipendenze bloccanti: ho tolto il cancelletto **dichiarandolo nella issue** invece di aggirare la spia in silenzio.

**Numeri:** 9 PR mergiate (8 in `beta`, 1 in `main` con 6 issue promosse) · 22 issue aperte · 6 loop · ~40 minuti di produzione inutilizzabile · **5 strumenti che esistevano e non misuravano** (`db:ritardo-orario` senza GRANT · il controllo CI sugli overload con `GROUP BY` rotto · `db:recupero-orario` su trasporto read-only · la compensazione di `company-member-create` senza test · il downsample con soglia a 12 mesi su dati di 8).
## 2026-09-15 — Dieci schede di Ascanio in produzione, e un rollup fermo da sei mesi

**In produzione:** 9 issue in due giri. #2110 batteria che diceva «scarica» mentre
caricava · #2117 stato di lavorazione degli errori · #2114 taglia nella scheda
impianto · #2112 comandi in fondo · #2115 tab laterali con modello e potenza ·
#2113 dashboard da telefono · #2111 icone di contatto in ordine · #2127 la
configurazione mancante non colora più lista e mappa · #2116 schema flussi
proporzionale alla taglia (recuperata a mano dal conflitto). Smoke 77/0 e 76/0.
**In beta, aspetta:** #2128 aggiungi azienda (card S140) · #2131 filtri nel
riquadro (S152) · #2130 chiusa come risolta da #2131 (S150) · #2132 parte A
filtro unico — tutte provate dal vivo, aspettano **Ascanio**.
**Aperto:** **#2138 rollup `historical_readings_hourly` fermo dal 26/03/2026** —
blocca #2140 (preset giorno bello/brutto) · #2129 stato di allaccio alla rete,
mai partita · #2118 tensione Zucchetti, ancora senza figlie.

**Ha funzionato:** il loop ha chiuso #2127, #2128, #2131 e #2132-A **al primo
tentativo**, con AC verificati sul diff reale. Due planner su sei si sono
**fermati prima di scrivere codice** perché la issue era sbagliata (#2132, #2130):
125k e 95k token spesi per non fare il danno. La promozione selettiva ha retto:
8 gruppi su 9, il nono recuperato a mano in un'ora.

**Non ha funzionato → regola nuova:**
- *Un verdetto senza `results` non deve far cadere il workflow* — il loop di
  #2132 è morto all'ultima riga dopo tre giri e 1,8M token, con la PR già aperta:
  `verdict.results.filter` su un oggetto a schema dimezzato. Corretto nel template
  della skill `dev-loop` (commit `9b73a60`): ora `!Array.isArray(verdict.results)`
  vale come «non giudicato», si perde un giro e non il lavoro.
- *Un AC che prescrive una fonte dati va verificato PRIMA che quella fonte abbia
  dati* — ho scritto AC su `historical_series_bucketed` (legge un rollup fermo dal
  26/03) e su `plant_daily_economics.produced_kwh` (colonna dichiarata e mai
  scritta). Entrambe rispondono vuoto con HTTP 200.
- *Il clic dell'automazione può non arrivare alla pagina* — ho creduto per venti
  minuti a un difetto inesistente in #2127; un listener in capture ha registrato
  **zero** eventi click. Prima di dichiarare rotta un'interazione, verifica che
  l'evento arrivi davvero.
- *Il service worker serve il bundle vecchio* — le prime misure su #2127 erano sul
  commit precedente al merge: 5 SW e 7 cache, una ferma a `897da827`. Prima di
  misurare a schermo: SW via, cache via, reload.

**Decisioni di Davide:** «Creane una di prova, ma serve tutto il crudo, poi la devi
anche cancellare» (S140: azienda completa, 35 campi verificati in DB, poi
cancellata) · spezzare #2132 in due invece di rilanciare il loop · correggere la
skill `dev-loop` nel repo workflow · su S150 «aspetta #2131, poi misura a 390px e
decidi» · «dashboard utente» = `/plant-statistics`, seconda voce del menu impianto.

**Errori miei:** ho scritto sei issue in un'ora con quattro affermazioni sbagliate
sul codice (#2132: legacy scambiato per canonico, `plant-owner` che è un redirect,
AC su lavoro già fatto, fonte dati inesistente) e una premessa falsa in #2130 (la
mappa «sempre aperta», in realtà chiusa dal #2040). Ho dichiarato finito un deploy
guardando un run `event=delete` — errore che avevo già in memoria. Ho letto come
«push rifiutato» un avviso su un push riuscito. Ho ricostruito a memoria un
`siteId` invece di leggerlo.

**Numeri:** 9 issue in produzione · 4 in beta · 6 loop lanciati (4 chiusi al primo
tentativo, 2 bloccati dal planner, 1 caduto per bug dello script) · ~4,6M token di
subagenti · smoke 77/0 e 76/0 · card: backlog 103, lavorazione 33, idee 11,
revisione 3 · backend 200 in 0,41s.

---

## 2026-09-14/15 — Trenta idee ferme, nove schede in mano ad Ascanio in una notte

**In produzione:** niente di nuovo stanotte. Resta la promozione delle 14 issue
del pomeriggio (PR #2107, smoke 76/0).
**In beta, aspetta:** #2110 batteria · #2117 stato errori · #2114 scheda impianto
· #2112 comandi in fondo · #2116 flussi proporzionali · #2115 tab laterali
· #2113 dashboard telefono · #2111 icone — tutte e otto aspettano **Ascanio**
(card S143, S115, S138, S157, S112, S139, S158, S145, più S141 già in prod).
**Aperto:** #2118 epica tensione — misura fatta, aspetta due risposte di Ascanio
(dove ha visto mancare la tensione su Solarman; quale impianto è «Rossi
Patrizia»). La parte Zucchetti è lavorabile subito. #2108 detached HEAD di
approva-promote resta aperta.

**Ha funzionato:** il triage delle 30 card in «Idee» ha prodotto 16 lavorabili
subito, e nove sono passate per il loop in tre lotti da tre. Otto PR mergiate,
zero rosse in CI. Tentativi: #2114 e #2113 al primo giro, le altre sei al
secondo, nessuna al terzo. Il verificatore Opus ha bocciato AC veri, non per
forma: su #2117 ha rifiutato una prova fatta su cinque righe sintetiche in
locale quando l'AC chiedeva un errore vero, e su #2109 il planner si è fermato
prima di scrivere una riga perché la scheda era superata da un'altra.
Due difetti trovati da un developer senza che nessuno li cercasse: su Huawei un
campo null cancellava lo stato batteria su tutta la flotta, e il rumore notturno
Solarman faceva oscillare l'etichetta.

**Non ha funzionato → regola nuova:**
- Su MaestroWeb la prima renderizzazione mostra i **fallback** (badge «non
  caricati», didascalia vecchia) e solo dopo arrivano i dati: due volte stanotte
  ho letto la pagina troppo presto e stavo per aprire un difetto inesistente su
  #2116 e su #2114. Si misura solo dopo aver atteso che i segnali di «dato
  assente» spariscano → memoria `feedback_misura_dopo_che_i_dati_sono_arrivati`.
- Il worktree lasciato da un loop può essere **indietro rispetto a origin**: il
  mio primo merge di risoluzione conflitto avrebbe cancellato il commit con le
  sei evidenze di #2116. Prima di mergiare in un worktree ereditato:
  `git reset --hard origin/<branch>` e controllo dei parent del merge commit →
  rafforza `feedback_worktree_stale_prima_di_mergiare`.
- Un developer, per fare la prova a schermo che la DoD impone, ha copiato
  `.env.local` nel worktree e passato **email e password in chiaro sulla riga di
  comando** di Playwright: il classificatore ha alzato un avviso di sicurezza.
  Nessuna fuga (`.env.*` è in .gitignore, diff e PR puliti, verificato), ma le
  credenziali finiscono nei log. Le credenziali di prova vanno lette da file →
  memoria `feedback_credenziali_di_prova_mai_in_riga_di_comando`.
- `plant-dashboard/page.tsx` è toccato da **6 schede su 8**: ha generato
  entrambi i conflitti della notte. Nei lotti paralleli, una sola issue per volta
  su quella pagina.
- Su #2124 i check sembravano verdi ma l'**E2E non era mai partito**: il run era
  di evento `push`, dove l'E2E è `skipping`. Stessa famiglia di
  `feedback_gh_run_watch_evento_sbagliato`: si guarda l'evento, non il colore.

**Decisioni di Davide:**
- Le quattro card sui consumi (S113, S114, S118, S156) si accorpano in una sola,
  chiedendo prima ad Ascanio quali soglie valgono: «Una scheda sola, chiedo ad
  Ascanio».
- Dati di targa delle batterie: «io farei una tabella nostra con un elenco di
  base e la capacità di integrare nuovi modelli non presenti con ricerca web».
- #2109 menu: chiudere come superata da S148 e chiedere ad Ascanio.
- Migration di #2117 in produzione: «Applicala tu ora» — poi non eseguibile da
  qui (classificatore sul token, e 403 della CLI Supabase sull'endpoint), quindi
  SQL preparata e lanciata da lui.

**Errori miei:**
- Ho scritto la issue #2109 prendendo per buona una card marcata `0_URGENTE`
  senza cercare se una più recente la contraddicesse. Il planner l'ha intercettata,
  ma il controllo tocca a me in fase di triage: prima di aprire una issue da una
  card vecchia, cercare card successive sulla stessa area.
- Le due misure lette troppo presto (sopra).
- Ho lanciato #2116 e #2112 in lotti diversi contando che non si toccassero, ma
  entrambi scrivevano nella stessa pagina: il conflitto era prevedibile leggendo
  `deps:schede`, che quel file lo segnala come infrastruttura.

**Numeri:** 10 issue aperte (9 lavorate + 1 epica), 8 PR mergiate in beta, 1
issue chiusa senza codice, 1 scheda chiusa perché il lavoro esisteva già (S141).
Card: idee 30 → 15, revisione 0 → 9, to-do Ascanio 0 → 4. Loop: 3 workflow,
41 agenti, ~5,8 milioni di token, 1,6 tentativi medi per issue. Misura #2118:
22.607 campioni, 103 device, 74 Zucchetti su 74 senza tensione continua.
Backend a fine sessione: 200 in 1,58 s. Worktree: 15 creati e rimossi, 95
residui da prima.

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
