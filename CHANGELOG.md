# Changelog

## ciclo-triage 2.3.0 (2026-10-15)

Card a due binari (MaestroWeb #2860, parte D #2864): ogni parte (sotto-issue) con label `ciclo:auto`/`ciclo:super` e riga di dipendenza; la sezione di partenza si sceglie sulle parti (`triage:binari`, `triage:sposta`). Versione minima richiesta dal lavoratore: 2.3.0 (`TRIAGE_SKILL_VERSIONE_MINIMA`): la skill va sul VPS PRIMA del merge in `beta`.

## aggiorna-pc 1.0.1 (2026-10-15)

Passo 2: `git pull --ff-only` prima di `sync.ps1` e gestione dei codici di uscita del nuovo sync a tre vie (5: `-SoloDalRepo`; 6 e 3: ci si ferma). Dopo il sync che cancellò 11 file il 15/10.

## aggiorna-pc 1.0.0 (2026-10-15)

Skill nuova (MaestroWeb #2858): «aggiorna il PC» allinea repo `workflow`, `claude-config-maestro` e radice MaestroWeb su `beta`, a ciclo spento. Fail-closed, solo `--ff-only`, mai `npm ci`, nessun interruttore toccato.

## ciclo-sviluppo 1.10.0 (2026-10-14)

Punto 0: controllo di allineamento prima del giro (MaestroWeb #2848), esito `{"errore":"allineamento: ..."}` e fetch di `origin master` del repo workflow. Il ciclo si ferma e non sincronizza da solo.

## v2.0.0 (2026-09-04)

Workflow ricostruito dai sette punti del flusso reale deciso da Davide.
`FLUSSO.md` sostituisce `WORKFLOW.md`/`8020-workflow` come fonte di verità.
Nove skill sopravvivono (`claudio`, `issue-validate`, `create-issue`,
`ascanio`, `dev-loop`, `commit`, `beta-release`, `approva`, `triage`) più due
tool (`beachcrer-sync-group`, `pdf-to-md`). Ventitré skill del vecchio
workflow ritirate — vedi `RETIRED.txt`. Il resto del vecchio workflow è in
`archive/`, storia preservata via `git mv`.
