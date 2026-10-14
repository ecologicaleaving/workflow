# Changelog

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
