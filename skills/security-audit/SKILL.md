# Skill: security-audit

**Trigger:** Obbligatoria al CP4 (pronto per PR), prima del push. L'agente DEVE eseguirla dopo aver completato l'implementazione e prima di pushare il branch.  
**Agente:** Qualsiasi agente (Claude Code / Codex) in fase di pre-push  
**Versione:** 1.0.0

---

## Obiettivo

Gate di sicurezza obbligatorio prima di ogni push/PR. Combina check automatici (script) e check manuali (valutazione dell'agente) per garantire che nessun problema di sicurezza venga introdotto nel codebase.

---

## Sezione 1 — Check automatici (script)

L'agente esegue lo script di audit automatico passando la root del repo:

```bash
bash scripts/security-audit.sh /path/to/repo
```

Lo script verifica:
- **Secrets/credenziali** nel codice (API key, AWS key, private key, password hardcoded)
- **File sensibili** tracciati da git (.env, .pem, .key, credentials.json, ecc.)
- **Dipendenze vulnerabili** (npm audit, pip audit, govulncheck — se disponibili)
- **Debug/dev leftovers** (console.log, debugger, TODO/FIXME/HACK)
- **Permessi file** anomali (777, SUID/SGID)

**Exit codes:**
- `0` = tutto ok (possibili warning)
- `1` = problemi critici trovati
- `2` = errore nello script

Opzioni utili:
- `--strict` — fail anche su warning
- `--json` — output in formato JSON
- `--fix` — tenta fix automatico dove possibile

---

## Sezione 2 — Check manuali (l'agente valuta)

Dopo lo script, l'agente legge il codice modificato e verifica manualmente:

### Auth check
> Se la issue tocca API/route/endpoint:
- Ogni endpoint ha autenticazione?
- Ci sono route pubbliche che dovrebbero essere protette?
- Se non tocca API → **N/A**

### Input sanitization
> Se la issue tocca DB/form:
- Query parametrizzate? Input validato?
- No SQL injection, no XSS?
- Se non tocca DB/form → **N/A**

### CORS
> Se la issue tocca configurazione server:
- CORS non è `*` in produzione?
- Se non tocca config server → **N/A**

### Data exposure
> Per tutte le response API modificate:
- Non espongono dati sensibili (password hash, token, email di altri utenti)?
- Se non tocca response API → **N/A**

### Error handling
> Per il codice modificato:
- Gli errori non espongono stack trace o info interne in produzione?
- Se non tocca error handling → **N/A**

---

## Sezione 3 — Output

L'agente **posta un commento sulla issue** con il seguente formato:

```
## 🔒 Security Audit — Pre-PR

**Script automatico:** ✅ PASS / ❌ FAIL
<output dello script>

**Check manuali:**
- Auth: ✅/❌/N/A — <note>
- Input sanitization: ✅/❌/N/A — <note>
- CORS: ✅/❌/N/A — <note>
- Data exposure: ✅/❌/N/A — <note>
- Error handling: ✅/❌/N/A — <note>

**Verdict:** ✅ PASS / ❌ BLOCKED
```

---

## Sezione 4 — Gate

### Problemi CRITICI (script)
Se lo script trova problemi critici (exit code 1):
- **Secret nel codice** → l'agente DEVE rimuoverli prima di procedere
- **File sensibili tracciati** → l'agente DEVE rimuoverli e aggiungerli a `.gitignore`
- **Vulnerabilità alta nelle dipendenze** → l'agente segnala e valuta se fixabile

> L'agente **non può procedere al push** finché i problemi critici non sono risolti.

### Problemi dai check manuali
Se i check manuali trovano problemi:
- L'agente **segnala nel commento** sulla issue
- **Aspetta conferma di Claudio** prima di procedere

### Verdict
- **✅ PASS** — solo se script passa E check manuali ok/N/A → l'agente può procedere al push
- **❌ BLOCKED** — problemi trovati → l'agente deve fixare o aspettare conferma

---

## Flusso completo

```
1. Implementazione completata
2. Esegui: bash scripts/security-audit.sh <repo-root>
3. Se FAIL critico → fixa e ri-esegui
4. Valuta check manuali leggendo il codice
5. Posta commento sulla issue con il report
6. Se PASS → procedi al push
7. Se BLOCKED → aspetta conferma di Claudio
```
