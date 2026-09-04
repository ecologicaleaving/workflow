# Retrospettiva delle sessioni

Una voce per sessione, la più recente in cima. La scrive Claudio a fine
sessione con la skill `chiusura-sessione`. Contiene ciò che le issue non
dicono: cosa ha funzionato, cosa no e quale regola ne è nata, le decisioni di
Davide, gli errori. Le regole nuove vivono poi in `FLUSSO.md` o nelle skill;
qui restano la data e il perché.

---

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
