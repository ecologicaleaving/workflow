#!/usr/bin/env node
/**
 * security-audit-rls.mjs — audit della superficie esposta al ruolo `anon` (issue #1391, epic #634).
 *
 * Due controlli complementari:
 *
 *   STATICO   sulle migration: tabelle create senza ENABLE ROW LEVEL SECURITY,
 *             policy `USING(true)` senza clausola `TO`, funzioni SECURITY DEFINER
 *             senza `SET search_path`.
 *   RUNTIME   contro il DB reale con la sola anon key: quali tabelle restituiscono
 *             davvero righe a un client non autenticato.
 *
 * Il controllo statico da solo NON basta: le policy applicate a mano in produzione
 * non compaiono nelle migration, e viceversa. Il leak di #1391 è stato trovato dal
 * runtime, non dallo statico.
 *
 * Uso:
 *   node scripts/security-audit-rls.mjs            # statico + runtime (serve .env.local)
 *   node scripts/security-audit-rls.mjs --static   # solo statico, nessuna rete
 *
 * Exit code 1 se trova una violazione fuori allowlist → utilizzabile in CI.
 * La logica di parsing è esportata (`analyzeMigrations`) ed è coperta da
 * scripts/__tests__/security-audit-rls.test.mjs.
 */
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const MIGRATIONS = join(ROOT, 'supabase', 'migrations');

/**
 * Tabelle/view la cui lettura da parte di `anon` è INTENZIONALE.
 * Aggiungere una voce qui è una decisione di sicurezza: motivare sempre.
 */
export const ANON_READ_ALLOWLIST = {
  electricity_prices: 'Prezzi zonali PUN/GME — dato pubblico, nessuna informazione su clienti o impianti.',
};

/**
 * Analizza il contenuto delle migration e restituisce i finding.
 * Funzione pura: riceve una mappa { nomeFile: contenutoSql }, non tocca il filesystem.
 *
 * @param {Record<string, string>} fileMap  migration in ordine di applicazione
 * @param {Record<string, string>} allowlist tabelle pubbliche per scelta
 */
export function analyzeMigrations(fileMap, allowlist = ANON_READ_ALLOWLIST) {
  const tables = new Map();
  const t = (n) => {
    const k = n.replace(/^public\./, '').replace(/"/g, '').toLowerCase();
    if (!tables.has(k)) tables.set(k, { rls: null, policies: new Map(), created: null });
    return tables.get(k);
  };
  const unsafeDefiners = [];

  for (const f of Object.keys(fileMap).sort()) {
    const sql = fileMap[f].replace(/--[^\n]*/g, '');

    // Gli statement vanno applicati IN ORDINE: il pattern idempotente
    // "DROP POLICY IF EXISTS x; CREATE POLICY x" darebbe zero policy se
    // processassimo tutti i CREATE prima di tutti i DROP.
    const ordered = [
      ...sql.matchAll(/create\s+table\s+(?:if\s+not\s+exists\s+)?([\w."]+)/gi),
      ...sql.matchAll(/alter\s+table\s+(?:if\s+exists\s+)?([\w."]+)\s+(enable|disable)\s+row\s+level\s+security/gi),
      ...sql.matchAll(/create\s+policy\s+("[^"]+"|[\w]+)\s+on\s+([\w."]+)([\s\S]*?);/gi),
      ...sql.matchAll(/drop\s+policy\s+(?:if\s+exists\s+)?("[^"]+"|[\w]+)\s+on\s+([\w."]+)/gi),
    ].sort((a, b) => a.index - b.index);

    for (const m of ordered) {
      if (/^create\s+table/i.test(m[0])) {
        const e = t(m[1]); if (!e.created) e.created = f;
      } else if (/row\s+level\s+security/i.test(m[0])) {
        t(m[1]).rls = m[2].toLowerCase() === 'enable';
      } else if (/^create\s+policy/i.test(m[0])) {
        const name = m[1].replace(/"/g, '');
        const body = m[3];
        const to = (body.match(/\bto\s+([\w,\s]+?)(?:\busing\b|\bwith\b|$)/i) || [, ''])[1].trim();
        const permissive = /using\s*\(\s*true\s*\)/i.test(body) || /with\s+check\s*\(\s*true\s*\)/i.test(body);
        t(m[2]).policies.set(name, { to, permissive, file: f });
      } else {
        t(m[2]).policies.delete(m[1].replace(/"/g, ''));
      }
    }

    for (const m of sql.matchAll(/create\s+(?:or\s+replace\s+)?function\s+([\w."]+)\s*\(([\s\S]*?)\$\$/gi)) {
      if (/security\s+definer/i.test(m[2]) && !/set\s+search_path/i.test(m[2])) {
        unsafeDefiners.push({ fn: m[1], file: f });
      }
    }
  }

  // Policy permissive senza `TO` esplicito: valgono per PUBLIC, quindi anche anon.
  // L'allowlist vale anche qui: una tabella pubblica per scelta non è una violazione,
  // altrimenti il check resta rosso per sempre e smette di essere guardato.
  const openPolicies = [];
  const allowedOpen = [];
  for (const [name, meta] of tables) {
    for (const [p, d] of meta.policies) {
      if (d.permissive && (!d.to || /\bpublic\b/i.test(d.to))) {
        (allowlist[name] ? allowedOpen : openPolicies).push(`${name} :: "${p}" — ${d.file}`);
      }
    }
  }

  const noRls = [...tables].filter(([, v]) => v.created && v.rls !== true).map(([k]) => k);

  return { tables, noRls, openPolicies, allowedOpen, unsafeDefiners };
}

/** Legge le migration dal filesystem in una mappa { file: sql }. */
export function readMigrations(dir = MIGRATIONS) {
  const out = {};
  for (const f of readdirSync(dir).filter((x) => x.endsWith('.sql')).sort()) {
    out[f] = readFileSync(join(dir, f), 'utf8');
  }
  return out;
}

// ─── CLI ─────────────────────────────────────────────────────────────────────

async function main() {
  const STATIC_ONLY = process.argv.includes('--static');
  let violations = 0;
  const fail = (msg) => { violations++; console.log(`  ✗ ${msg}`); };
  const ok = (msg) => console.log(`  ✓ ${msg}`);

  console.log('Audit RLS / superficie anon — Maestro (#1391, epic #634)');
  console.log('\n── Analisi statica delle migration ──\n');

  const { noRls, openPolicies, allowedOpen, unsafeDefiners } = analyzeMigrations(readMigrations());

  console.log(`Tabelle create senza ENABLE ROW LEVEL SECURITY (${noRls.length}):`);
  noRls.length
    ? noRls.forEach((n) => fail(`${n} — RLS assente: il GRANT di default la espone via PostgREST`))
    : ok('nessuna');

  console.log(`\nPolicy USING(true)/WITH CHECK(true) senza "TO" esplicito (${openPolicies.length}):`);
  openPolicies.length
    ? openPolicies.forEach((p) => fail(`${p} — vale per PUBLIC, include anon`))
    : ok('nessuna');
  for (const p of allowedOpen) console.log(`  ~ ${p} — permissiva ma in allowlist`);

  console.log(`\nFunzioni SECURITY DEFINER senza SET search_path (${unsafeDefiners.length}):`);
  unsafeDefiners.length
    ? unsafeDefiners.forEach((d) => console.log(`  ! ${d.fn} — ${d.file} (hardening, non bloccante)`))
    : ok('nessuna');

  if (!STATIC_ONLY) {
    console.log('\n── Superficie reale esposta ad anon ──\n');
    const envPath = join(ROOT, '.env.local');
    if (!existsSync(envPath)) {
      console.log('  .env.local assente — controllo runtime saltato.');
    } else {
      const env = Object.fromEntries(
        readFileSync(envPath, 'utf8').split('\n')
          .filter((l) => l.includes('=') && !l.startsWith('#'))
          .map((l) => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()]),
      );
      const URL = env.NEXT_PUBLIC_SUPABASE_URL;
      const ANON = env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
      if (!URL || !ANON) {
        console.log('  URL/ANON key mancanti — saltato.');
      } else {
        const names = new Set();
        for (const sql of Object.values(readMigrations())) {
          for (const m of sql.replace(/--[^\n]*/g, '').matchAll(
            /create\s+(?:table|(?:or\s+replace\s+)?view|materialized\s+view)\s+(?:if\s+not\s+exists\s+)?([\w."]+)/gi,
          )) {
            names.add(m[1].replace(/^public\./, '').replace(/"/g, '').toLowerCase());
          }
        }
        let exposed = 0;
        for (const n of [...names].sort()) {
          const r = await fetch(`${URL}/rest/v1/${n}?select=*&limit=1`, { headers: { apikey: ANON } });
          if (!r.ok) continue;
          const rows = await r.json();
          if (!Array.isArray(rows) || rows.length === 0) continue;
          exposed++;
          if (ANON_READ_ALLOWLIST[n]) {
            console.log(`  ~ ${n} — leggibile da anon, ma in allowlist: ${ANON_READ_ALLOWLIST[n]}`);
          } else {
            fail(`${n} — restituisce righe a un client NON autenticato (colonne: ${Object.keys(rows[0]).join(', ')})`);
          }
        }
        if (exposed === 0) ok('nessuna tabella restituisce righe ad anon');
      }
    }
  }

  console.log(`\n${'─'.repeat(60)}`);
  if (violations) {
    console.log(`ESITO: ${violations} violazioni da sanare.`);
    process.exit(1);
  }
  console.log('ESITO: nessuna violazione.');
}

// Esegue solo se invocato da CLI, non quando importato dai test.
if (process.argv[1] && process.argv[1].endsWith('security-audit-rls.mjs')) {
  await main();
}
