#!/usr/bin/env node
/**
 * security-audit-secrets.mjs — cerca credenziali in chiaro nei file versionati
 * (issue #1392, epic sicurezza #634).
 *
 * Nato da un caso reale: `Maestro2026!` era committata in 4 file dal 24/03/2026,
 * presentata come "credenziale di test". Non lo era — la stessa password apriva
 * gli account reali in produzione, incluso uno con `is_superadmin`.
 *
 * Analizza SOLO i file tracciati da git (`git ls-files`): quel che non è versionato
 * non è il problema di questo controllo.
 *
 * Uso:
 *   node scripts/security-audit-secrets.mjs
 *
 * Exit code 1 se trova qualcosa fuori allowlist → utilizzabile in CI.
 */
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/** File esclusi dalla scansione: rumore noto, non segreti. */
const SKIP_FILES = [
  /^package-lock\.json$/,
  /^src\/lib\/database\.types\.ts$/,
  /^scripts\/security-audit-secrets\.mjs$/, // questo file contiene i pattern stessi
];

/**
 * Valori che sembrano segreti ma non lo sono. Motivare ogni voce.
 */
const ALLOWLIST = [
  { pattern: /secret123|'secret'|"secret"|'password'|"password"/, why: 'fixture nei test dei validator Zod' },
  { pattern: /your-public-anon-key|sk-ant-\.\.\.|<[^>]+>|\$\{[^}]+\}|xxx+|\.\.\./i, why: 'placeholder' },
];

const RULES = [
  {
    id: 'password-literale',
    // password: "qualcosa" / password=qualcosa in JSON, shell, codice
    re: /["']?password["']?\s*[:=]\s*["'][^"'\s${}]{6,}["']/gi,
    grave: true,
    msg: 'password in chiaro',
  },
  {
    id: 'jwt-service-role',
    re: /eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}/g,
    grave: true,
    msg: 'JWT committato',
    // Verifica il ruolo dentro il payload: anon è pubblica, service_role no.
    refine: (m) => {
      try {
        const payload = JSON.parse(Buffer.from(m.split('.')[1], 'base64').toString());
        if (payload.role === 'service_role') return 'JWT SERVICE_ROLE — accesso totale al DB';
        if (payload.role === 'anon') return null; // chiave pubblica, non è un segreto
        return `JWT con role=${payload.role}`;
      } catch { return null; }
    },
  },
  { id: 'api-key-provider', re: /\b(sk-ant-[A-Za-z0-9_-]{10,}|sk-[A-Za-z0-9]{32,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})\b/g, grave: true, msg: 'API key provider' },
  { id: 'private-key', re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/g, grave: true, msg: 'chiave privata' },
];

const files = execSync('git ls-files', { cwd: ROOT, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 })
  .split('\n').filter(Boolean)
  .filter((f) => !SKIP_FILES.some((re) => re.test(f)));

console.log(`Audit secrets — ${files.length} file versionati (#1392, epic #634)\n`);

let violations = 0;
const allowed = [];

for (const f of files) {
  let content;
  try { content = readFileSync(join(ROOT, f), 'utf8'); } catch { continue; }
  if (content.includes('\0')) continue; // binario

  for (const rule of RULES) {
    for (const m of content.matchAll(rule.re)) {
      const hit = m[0];
      if (ALLOWLIST.some((a) => a.pattern.test(hit))) { allowed.push(`${f} — ${rule.id}`); continue; }

      let detail = rule.msg;
      if (rule.refine) {
        const refined = rule.refine(hit);
        if (refined === null) continue; // scartato dal refine (es. JWT anon)
        detail = refined;
      }
      const line = content.slice(0, m.index).split('\n').length;
      violations++;
      console.log(`  ✗ ${f}:${line} — ${detail}`);
    }
  }
}

if (allowed.length) {
  console.log(`\n  ~ ${allowed.length} occorrenze in allowlist (placeholder e fixture di test)`);
}

console.log(`\n${'─'.repeat(60)}`);
if (violations) {
  console.log(`ESITO: ${violations} credenziali in chiaro da rimuovere.`);
  console.log('Rimuovere dal codice NON basta: la credenziale resta nella history git.');
  console.log('Va ANCHE ruotata (cambiata) sul sistema che protegge.');
  process.exit(1);
}
console.log('ESITO: nessuna credenziale in chiaro nei file versionati.');
