'use strict';
// UserPromptSubmit hook — two jobs:
// 1. Keep current-session-id up to date so CLAUDE.md echo commands can reference it.
// 2. Write an activity marker to the session journal so the Stop hook's SHA guard
//    doesn't suppress the full session log when no git changes occurred.
//
// Prompt text collection is handled by the Stop hook, which reads directly from the
// Claude Code transcript JSONL (fully committed to disk by Stop time, no race conditions).
const { mkdirSync, appendFileSync, writeFileSync } = require('fs');
const path = require('path');
const os = require('os');

process.on('uncaughtException', () => process.exit(0));

const sessionId = (process.env.CLAUDE_CODE_SESSION_ID || '').replace(/[^a-zA-Z0-9_-]/g, '');
if (!sessionId) process.exit(0);

// 1. Persist session_id for CLAUDE.md echo commands
try {
  writeFileSync(path.join(os.homedir(), '.claude', 'current-session-id'), sessionId + '\n', 'utf8');
} catch {}

// 2. Write activity marker so Stop hook bypasses SHA guard
const now = new Date();
const p2 = n => String(n).padStart(2, '0');
const time = `${p2(now.getHours())}:${p2(now.getMinutes())}`;

try {
  const journalDir = path.join(os.homedir(), '.claude', 'session-journals');
  mkdirSync(journalDir, { recursive: true });
  appendFileSync(
    path.join(journalDir, `${sessionId}.jsonl`),
    JSON.stringify({ time, type: 'activity' }) + '\n',
    'utf8'
  );
} catch {}

process.exit(0);
