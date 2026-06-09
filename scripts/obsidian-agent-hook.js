'use strict';
// SubagentStop hook — appends agent completions to the session journal.
// On Windows, Claude Code does not pipe stdin to hooks. Session ID is read from
// CLAUDE_CODE_SESSION_ID env var. Agent name falls back to 'subagent' when stdin unavailable.
const { mkdirSync, appendFileSync } = require('fs');
const path = require('path');
const os = require('os');

process.on('uncaughtException', () => process.exit(0));

// Primary: read session_id from env (works on Windows where stdin is not piped)
const sessionId = (process.env.CLAUDE_CODE_SESSION_ID || '').replace(/[^a-zA-Z0-9_-]/g, '');
if (!sessionId) process.exit(0);

const now = new Date();
const p2 = n => String(n).padStart(2, '0');
const time = `${p2(now.getHours())}:${p2(now.getMinutes())}`;

function writeJournalEntry(agentName) {
  const journalDir = path.join(os.homedir(), '.claude', 'session-journals');
  mkdirSync(journalDir, { recursive: true });
  const journalFile = path.join(journalDir, `${sessionId}.jsonl`);
  appendFileSync(journalFile, JSON.stringify({ time, type: 'agent', name: agentName }) + '\n', 'utf8');
}

// Try to read stdin for agent type; fall back to 'subagent' after 1.5s.
let raw = '';
const t = setTimeout(() => {
  writeJournalEntry('subagent');
  process.exit(0);
}, 1500);

process.stdin.setEncoding('utf8');
process.stdin.on('data', d => { raw += d; });
process.stdin.on('close', () => {
  clearTimeout(t);
  let agentName = 'subagent';
  try {
    const payload = JSON.parse(raw);
    agentName = (
      payload.agent_type ||
      payload.agentType ||
      payload.agent?.type ||
      payload.agent?.name ||
      payload.agent?.agent_type ||
      payload.name ||
      'subagent'
    ).replace(/[\r\n]/g, '').trim();
  } catch {}
  writeJournalEntry(agentName);
  process.exit(0);
});
