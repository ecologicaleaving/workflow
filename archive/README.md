# Archivio

Tutto ciò che c'è qui sotto è il workflow **v1**, ritirato il 2026-09-04 quando
Davide ha ridefinito il flusso reale in sette punti (vedi `FLUSSO.md` nella
root del repo).

Non è più letto da nessun agente, non è sincronizzato da `scripts/sync.ps1`,
non va aggiornato. Si tiene per la storia — per capire da dove veniva una
regola, o recuperare una procedura vecchia se mai servisse di nuovo.

Le skill correnti sono in `skills/` e `tools/` nella root del repo. La fonte
di verità del flusso è `FLUSSO.md`.

`.github/workflows/kanban-automation.yml` e `label-automation.yml` sono
qui dal 2026-09-04: reusable workflow che leggevano `config.json` (anch'esso
archiviato). Verificato via grep sui repo locali in `00-Progetti` che nessun
repo esterno li richiama più (`uses: ecologicaleaving/workflow/.github/workflows/...`).
`.github/ISSUE_TEMPLATE/` è rimasto nella root del repo, non tocca `config.json`.
