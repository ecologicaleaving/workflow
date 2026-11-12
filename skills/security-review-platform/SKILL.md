# Skill: security-review-platform

**Trigger:** `/security-review` su un progetto già in produzione, oppure quando Davide chiede «facciamo i controlli di sicurezza su X».
**Agente:** qualsiasi agente tecnico.
**Versione:** 1.0.0 — derivata dall'epic #634 su MaestroWeb (26-28/07/2026), dove questo metodo ha trovato 2 finding critici e 6 alti.

> Diversa da `security-audit`, che è il gate **pre-push** su un diff (secrets, dipendenze, debug leftover). Questa è una **review di postura** su un sistema già vivo.

---

## Il principio, prima di tutto

**Un audit fatto leggendo il codice produce falsi negativi.** Non è un'opinione: sull'epic #634 *ogni* finding grave era invisibile nel codice.

| Cosa sembrava | Cosa era |
|---|---|
| Le migration mostravano policy RLS corrette | 6 tabelle erano leggibili da chiunque senza login — le policy vere non stavano nelle migration |
| `iptables -L` mostrava una regola DROP attiva sulla porta | La porta era aperta: la regola non poteva matchare |
| Il `systemd` timer risultava `enabled` e `active` | Non era scattato nemmeno una volta |
| Gli header di sicurezza erano nella config nginx | Gli asset statici uscivano senza nemmeno uno |
| Le credenziali erano documentate come «ambiente di test» | Aprivano la produzione, con privilegi di superadmin |

**Regola operativa: ogni finding va verificato dall'esterno, con una richiesta reale.** Se non hai provato, non l'hai verificato — scrivi «non verificato», non dedurre.

---

## Fase 1 — Superficie dati (la più importante)

Su Supabase/PostgREST, o qualunque backend con API generata dallo schema.

**Cosa fare**: prendere la chiave pubblica del progetto (`NEXT_PUBLIC_*_ANON_KEY`, sta nel bundle JS: è pubblica per costruzione) e provare a leggere **ogni tabella** senza login.

```bash
curl -s "$URL/rest/v1/<tabella>?select=*&limit=1" -H "apikey: $ANON_KEY"
```

Righe restituite = leak. `[]` o `42501` = protetta.

**Due cause ricorrenti, entrambe viste in produzione:**

1. **RLS mai abilitata**, con la motivazione «questa tabella la usa solo il service_role». È falsa: ogni tabella in `public` ha un GRANT di default per `anon`/`authenticated` ed è esposta via PostgREST, indipendentemente da chi la usa *davvero*.
2. **`FOR ALL USING (true)` senza clausola `TO`**. Senza `TO` la policy vale per `PUBLIC`, cioè anche `anon`. Il caso reale si chiamava `service_role_full_access` e di service_role aveva solo il nome. Al service_role una policy **non serve mai**: bypassa RLS per definizione. Se ne stai scrivendo una, o è inutile o sta aprendo a chiunque.

**Poi verifica la scrittura**, non solo la lettura — ma con un filtro su un ID inesistente, così tocchi 0 righe. **Attenzione**: un `204` su 0 righe **non prova** il permesso, perché RLS filtra le righe e non rifiuta l'operazione. Prova il GRANT, non la policy. Distinguere, o si producono finding falsi.

**Le view non ereditano la RLS della tabella base**: mettere in sicurezza la tabella non chiude la view. Serve `security_invoker = on`.

**Se il ruolo di test è admin/superadmin, la verifica non vale.** Le policy hanno forma `is_superadmin() OR <scope>`: con un account god il secondo ramo non viene mai valutato, e un errore nello scope resta invisibile. Serve un utente normale. Se non c'è, **dichiaralo come limite** invece di far finta di aver verificato.

## Fase 2 — Credenziali nel repo

```bash
git ls-files | ... # cerca su file VERSIONATI, non sul working dir
```

Cerca: password in chiaro, JWT, API key provider, chiavi private.

**Sui JWT, decodifica il payload**: una chiave `anon` è pubblica e non è un finding; una `service_role` è critica. Segnalare ogni stringa `eyJ` genera rumore e fa ignorare il report.

**La domanda che conta non è «è una credenziale di test?», è «funziona in produzione?».** Provala. Nel caso reale la password era documentata come ambiente di test da 4 mesi e apriva la produzione con privilegi di superadmin.

**Rimuoverla dal codice non basta**: resta nella history git. Va **ruotata**. Se il report non lo dice esplicitamente, il problema resta aperto anche a PR mergiata.

## Fase 3 — Header e TLS

Verifica gli header **su una pagina HTML e su un asset statico**, separatamente.

```bash
curl -sSI https://sito/una-pagina
curl -sSI https://sito/_next/static/chunks/qualcosa.js
```

In nginx **`add_header` non si eredita** in una `location` che ne dichiara uno proprio. Una location che imposta `Cache-Control` sugli asset perde *tutti* gli header di sicurezza. Nel caso reale il file documentava il gotcha in un commento e lo applicava a metà.

Confronta **prod e test fra loro**: le configurazioni divergono nel tempo e la differenza segnala quale delle due è indietro.

Una **CSP** va introdotta in `Content-Security-Policy-Report-Only`: se sbagliata rompe l'app in silenzio.

Se davanti c'è Cloudflare, il certificato che vedi è il suo: **il tratto Cloudflare→origin dipende dalla modalità SSL nel pannello**. Se non è *Full (strict)*, quel tratto è debole. Richiede il pannello, non è deducibile da fuori.

## Fase 4 — Auth

```
durata access token, presenza refresh token
dopo il logout: l'access token è davvero revocato? il refresh è invalidato?
messaggi d'errore per account esistente vs inesistente: identici?
```

Verifica dove sta la sessione: in `localStorage` è esposta a XSS — e va letta **insieme** all'assenza di CSP e di MFA. Tre finding "medi" separati possono essere una catena completa.

**Sul rate limiting sii onesto**: pochi tentativi non dimostrano che non esista un limite. Leggilo dalla configurazione, non dedurlo a colpi di richieste su un endpoint di produzione.

## Fase 5 — GDPR

Inventario delle tabelle con dati personali, retention, cancellazione, trasferimenti a terzi.

**Due cose che non si vedono guardando lo schema:**

- **Un campo "tecnico" può essere un dato personale.** Nel caso reale `sites.name` conteneva nomi e cognomi di clienti: ogni log, ogni notifica esterna che includeva quel campo trattava dati personali.
- **La telemetria a granularità fine rivela abitudini di vita.** Una curva di consumo a 15 minuti dice quando qualcuno è in casa. Non è un dato tecnico neutro.

Controlla dove finiscono i dati: un'integrazione che manda documenti a un servizio LLM è un **trasferimento a terzi**, spesso extra-UE.

Il **diritto di cancellazione** non è una `DELETE`: va deciso per ogni tabella fra cancellare e **anonimizzare**, perché i log di comando hanno valore di audit. Se non c'è, apri una issue dedicata invece di improvvisarlo.

## Fase 6 — Infrastruttura (se il progetto ha un VPS)

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication'
ufw status
systemctl is-active fail2ban unattended-upgrades
ss -tlnp        # cosa ascolta
```

Poi **verifica dall'esterno** quali porte rispondono davvero: `ss` dice cosa ascolta, non cosa è raggiungibile.

**Docker pubblica su `0.0.0.0` bypassando UFW.** Il filtro va in `DOCKER-USER`, e lì:

- usa **`-m conntrack --ctorigdstport`**, mai `--dport`: quando il pacchetto arriva il DNAT è già avvenuto, quindi `--dport` vede la porta *interna* del container. Funziona per caso quando le due coincidono (`8080->8080`) e fallisce in silenzio quando differiscono (`3007->3000`), lasciando una regola perfettamente visibile in `iptables -L` che non filtra niente.
- **verifica che le regole siano persistite.** Nel caso reale proteggevano i database di 3 progetti ed esistevano solo in memoria: al primo reboot sarebbero finiti su internet. `iptables -L` non lo dice.

Se aggiungi un timer systemd di recupero: **niente `RemainAfterExit=yes`** (systemd non rilancia un service già `active`, e il timer non scatta mai) e usa `OnCalendar` invece di `OnUnitActiveSec`. **Poi provalo**: cancella una regola a mano e guarda se torna.

Attenzione: `systemctl restart docker` **non riporta su tutti i container** — mettilo in conto prima di lanciarlo su una macchina condivisa fra progetti.

---

## Come riportare

Un finding utile ha tre parti: **cosa**, **come l'hai verificato**, **quanto è grave davvero**.

- Classifica per severità reale, non teorica. Una console admin esposta con credenziali di fabbrica sembra critica; se il servizio dietro è vuoto e inattivo, è alta ma non critica — e dirlo mantiene credibile il resto del report.
- **Separa i finding dalle azioni che spettano ai fondatori.** Rotazione credenziali, pannelli esterni, decisioni di retention: l'agente non può eseguirle, e se restano annegate nel report non le fa nessuno. Elencale a parte.
- **Marca esplicitamente ciò che non hai potuto provare.** «Non verificato» è un esito legittimo; una deduzione presentata come verifica no.
- Se il fix richiede di toccare infrastruttura, consegna uno script **idempotente**, con rollback in testa, e usa **path assoluti** (uno script consegnato con path relativo è già fallito due volte in silenzio).

## Cosa lasciare al progetto

Non solo il report: uno **strumento che rileva la classe di problema**, agganciato a `package.json` e con exit code 1 per la CI. Su MaestroWeb sono `npm run audit:rls` e `npm run audit:secrets` (`scripts/security-audit-*.mjs`) — copiabili e adattabili: cambiano solo il path delle migration e del file di ambiente.

Uno strumento con **allowlist motivata** ha due effetti: la regressione si vede da sola, e le eccezioni intenzionali (una tabella pubblica per scelta) smettono di essere rumore che fa ignorare il check.
