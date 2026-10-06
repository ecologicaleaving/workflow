// Sposta UNA card di MaestroWeb per numero, solo se è davvero nella sezione di partenza.
// Uso: node sposta-card.mjs <card_no> <da> <a> [assigned_to|-] [review_notes]
//   es. node sposta-card.mjs 234 todo parcheggiate - "Decisione presa: ..."
// Legge URL e chiave service_role da MaestroWeb/.env.local. Non stampa mai la chiave.
// «righe 0» = la card non era in <da>: nessuno spostamento, controlla prima di riprovare.
import { readFileSync } from 'node:fs';
const ROOT = process.env.MAESTRO_ROOT ?? 'C:/Users/KreshOS/Documents/00-Progetti/MaestroWeb';
const env = Object.fromEntries(readFileSync(`${ROOT}/.env.local`, 'utf8').split('\n')
  .filter((l) => l.includes('=') && !l.trim().startsWith('#'))
  .map((l) => { const i = l.indexOf('='); return [l.slice(0, i).trim(), l.slice(i + 1).trim()]; }));
const [n, da, a, who, note] = process.argv.slice(2);
const AMMESSI = ['todo', 'idee', 'pronte', 'lavorazione', 'revisione', 'backlog', 'parcheggiate', 'obsolete'];
if (!n || !da || !a) { console.error('Uso: node sposta-card.mjs <card_no> <da> <a> [assigned_to|-] [review_notes]'); process.exit(1); }
if (!AMMESSI.includes(a) || a === 'revisione' || a === 'backlog') {
  console.error(`Destinazione «${a}» non ammessa da questa skill (mai Revisione, Approvate o BackLog).`); process.exit(1);
}
if (a === 'todo' && (!who || who === '-')) { console.error('In «todo» serve assigned_to (davide|ascanio).'); process.exit(1); }
const U = env.NEXT_PUBLIC_SUPABASE_URL.replace(/\/$/, '');
const H = { apikey: env.SUPABASE_SERVICE_ROLE_KEY, Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`, 'Content-Type': 'application/json', Prefer: 'return=representation' };
const body = { stage: a };
if (who && who !== '-') body.assigned_to = who;
if (note) body.review_notes = note;
const r = await fetch(`${U}/rest/v1/qa_tasks?card_no=eq.${encodeURIComponent(n)}&stage=eq.${encodeURIComponent(da)}`, { method: 'PATCH', headers: H, body: JSON.stringify(body) });
const j = await r.json();
console.log(`S${n} ${da} → ${a}${body.assigned_to ? ` (${body.assigned_to})` : ''}: HTTP ${r.status}, righe ${Array.isArray(j) ? j.length : JSON.stringify(j).slice(0, 160)}`);
