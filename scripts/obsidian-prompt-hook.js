'use strict';
// UserPromptSubmit hook — appends each user prompt to the session journal.
// The Stop hook reads this journal to populate "What was discussed" in session logs.
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

    // Extract the most recent user message from transcript
    const transcript = Array.isArray(payload.transcript) ? payload.transcript : [];
    let prompt = '';
    for (let i = transcript.length - 1; i >= 0; i--) {
      const msg = transcript[i];
      if (msg.role === 'user') {
        const content = Array.isArray(msg.content)
          ? msg.content.map(b => (typeof b === 'string' ? b : (b.text || ''))).join(' ')
          : String(msg.content || '');
        prompt = content.replace(/[\n\r]+/g, ' ').trim().slice(0, 200);
        break;
      }
    }
    // Fallback: top-level message field
    if (!prompt && payload.message) {
      prompt = String(payload.message).replace(/[\n\r]+/g, ' ').trim().slice(0, 200);
    }
    if (!prompt) return;

    const now = new Date();
    const p2 = n => String(n).padStart(2, '0');
    const time = `${p2(now.getHours())}:${p2(now.getMinutes())}`;

    const journalDir = path.join(os.homedir(), '.claude', 'session-journals');
    mkdirSync(journalDir, { recursive: true });
    const journalFile = path.join(journalDir, `${sessionId}.jsonl`);
    appendFileSync(journalFile, JSON.stringify({ time, type: 'prompt', text: prompt }) + '\n', 'utf8');
  } catch {}
  // Always exit 0 — never block the prompt
  process.exit(0);
});
