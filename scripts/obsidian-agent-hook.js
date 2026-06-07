'use strict';
// SubagentStop hook — appends agent completions to the session journal.
// The Stop hook reads this journal to populate "Agents invoked" in session logs.
const { mkdirSync, appendFileSync } = require('fs');
const path = require('path');
const os = require('os');

process.on('uncaughtException', () => process.exit(0));

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', d => { raw += d; });
process.stdin.on('close', () => {
  try {
    const payload = JSON.parse(raw);
    const sessionId = payload.session_id || '';
    if (!sessionId) return;

    // Try multiple possible field names for the agent identifier
    const agentName = (
      payload.agent_type ||
      payload.agentType ||
      payload.agent?.type ||
      payload.agent?.name ||
      payload.agent?.agent_type ||
      payload.name ||
      ''
    ).replace(/[\r\n]/g, '').trim();
    if (!agentName) return;

    const now = new Date();
    const p2 = n => String(n).padStart(2, '0');
    const time = `${p2(now.getHours())}:${p2(now.getMinutes())}`;

    const journalDir = path.join(os.homedir(), '.claude', 'session-journals');
    mkdirSync(journalDir, { recursive: true });
    const journalFile = path.join(journalDir, `${sessionId}.jsonl`);
    appendFileSync(journalFile, JSON.stringify({ time, type: 'agent', name: agentName }) + '\n', 'utf8');
  } catch {}
  process.exit(0);
});
