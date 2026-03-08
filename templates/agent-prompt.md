# Template prompt lancio agente
# Sostituire tutte le variabili {MAIUSCOLO} prima dell'uso.
# Copiare il testo del prompt risultante nel comando di lancio.

---

Leggi AGENTS.md (o CLAUDE.md) e segui il flusso di sessione obbligatorio prima di iniziare.

Il tuo compito è implementare la issue #{ISSUE_NUMBER}: {ISSUE_URL}

**{ISSUE_TITLE}**

{ISSUE_DESCRIPTION_BREVE}

## Flusso obbligatorio

1. Crea il branch `{BRANCH_NAME}` da master/main
2. Implementa la feature secondo gli acceptance criteria della issue
3. Scrivi i test richiesti
4. Esegui `{TEST_COMMAND}` — tutti devono essere verdi
5. Fai commit dei cambiamenti con messaggi convenzionali (`feat:`, `fix:`, ecc.)
6. Apri una PR verso master/main con titolo `{PR_TITLE}`
7. Quando la PR è aperta, esegui:
   `openclaw system event --text "{NOTIFY_MESSAGE}" --mode now`

## Note

- Repo: `{REPO}`
- Branch: `{BRANCH_NAME}`
- Stack: {STACK}
- Ambiente test: {TEST_ENV}

---

# Valori da sostituire:
# {ISSUE_NUMBER}      es. 28
# {ISSUE_URL}         es. https://github.com/ecologicaleaving/finn/issues/28
# {ISSUE_TITLE}       es. Supporto offline con cache locale e sync automatico
# {ISSUE_DESCRIPTION_BREVE}  2-3 righe dall'obiettivo della issue
# {BRANCH_NAME}       es. feature/issue-28-offline-cache-sync
# {TEST_COMMAND}      es. flutter test / npm test / pytest
# {PR_TITLE}          es. Feature: supporto offline con cache locale e sync automatico (#28)
# {NOTIFY_MESSAGE}    es. PR aperta per issue #28 finn offline - build pronta per test
# {REPO}              es. ecologicaleaving/finn
# {STACK}             es. Flutter 3.0+ · Riverpod · Supabase
# {TEST_ENV}          es. APK locale / emulatore / localhost:3000
