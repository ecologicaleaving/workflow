# Changelog — issue-validate

## v2.1.0 (2026-09-10)

Il verificatore del loop Draft↔Critica dello Step 1a passa da Fable 5 a
**Opus 5** (`model: 'opus'`), come tutti gli altri agenti di giudizio del
flusso. Non è una preferenza: la decisione di Davide del 06/09 —
«sostituiamo Fable con Opus dappertutto» — non era mai arrivata nelle skill,
e il 10/09 i loop hanno smesso di partire perché i crediti Fable erano
esauriti: tre tentativi del planner respinti con «out of usage credits»,
nessun piano prodotto. Nessun cambio di meccanica.


## v2.0.0 (2026-09-04)

Skill portata nel workflow v2. Il verificatore del loop Draft↔Critica dello
Step 1a è ora **Fable 5** (`model: 'fable'`) — prima era un altro modello,
citato come "verificatore" nel resto del workflow. Nessun cambio di
meccanica: resta un agente separato dal draft, mai autovalutazione.
Riferimento flusso spostato da `WORKFLOW.md` a `FLUSSO.md`. Changelog
storico precedente al v2.0.0 consultabile via `git log` su questo file.
