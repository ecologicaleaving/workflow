# Changelog — beta-release

## v2.0.0 (2026-09-04)

Portata nel workflow v2 — aggiornati i riferimenti (`issue-run`→`dev-loop`, `WORKFLOW.md`→`FLUSSO.md`), aggiunto lo Step 3.5 esplicito (prova dal vivo + card Ascanio + `deps:schede`), prima implicito nella skill `dev-loop-opus-sonnet` di MaestroWeb.

- **v1.1.0** (2026-07-24): Step 5 riscritto per il flusso di promozione selettiva
  (`scripts/approva-promote.ts`, maestroweb issue #1478) — con merge-diretto-in-beta, l'intero
  `beta` non è più sicuro da mergiare in blocco perché contiene sempre un mix di issue
  approvate/non approvate. Documentato anche il fail-safe su commit orfani e il vincolo
  `--merge` mai `--squash`.
- **v1.0.0** (2026-07-14): Prima versione — integrazione beta + re-test + deploy test su dati reali + avviso + gate prod. Estratta dal ciclo collaudato sulle 9 issue Ascanio.
