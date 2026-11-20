# Changelog — beta-release

## v2.2.0 (2026-11-20)

MaestroWeb #3584: `run-migration.yml` si lancia solo con `--ref main`; il file SQL si sceglie con `-f ramo_sorgente=<ramo>` (`beta` o `feature/issue-N-slug`). Vale dopo il `/promuovi` di #3584.

## v2.1.0 (2026-10-13)

MaestroWeb #2818: prima di ogni merge in `beta` si lancia `pr:sovrapposizione` (exit 0 merge senza rifare l'E2E, 1 riallinea, 2 stop). Le PR non alzano più `version`.

## v2.0.0 (2026-09-04)

Portata nel workflow v2 — aggiornati i riferimenti (`issue-run`→`dev-loop`, `WORKFLOW.md`→`FLUSSO.md`), aggiunto lo Step 3.5 esplicito (prova dal vivo + card Ascanio + `deps:schede`), prima implicito nella skill `dev-loop-opus-sonnet` di MaestroWeb.

- **v1.1.0** (2026-07-24): Step 5 riscritto per il flusso di promozione selettiva
  (`scripts/approva-promote.ts`, maestroweb issue #1478) — con merge-diretto-in-beta, l'intero
  `beta` non è più sicuro da mergiare in blocco perché contiene sempre un mix di issue
  approvate/non approvate. Documentato anche il fail-safe su commit orfani e il vincolo
  `--merge` mai `--squash`.
- **v1.0.0** (2026-07-14): Prima versione — integrazione beta + re-test + deploy test su dati reali + avviso + gate prod. Estratta dal ciclo collaudato sulle 9 issue Ascanio.
