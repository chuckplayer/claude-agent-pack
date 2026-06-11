'use strict';
const { execFileSync } = require('child_process');
const { existsSync, mkdirSync, writeFileSync, appendFileSync, readFileSync, readdirSync, unlinkSync } = require('fs');
const path = require('path');
const os = require('os');

// ---------------------------------------------------------------------------
// Pure helpers — module-scoped, exported for testing
// ---------------------------------------------------------------------------

/**
 * Infer Obsidian tags from the diff-stat text of the last commit.
 * @param {string} projectSlug
 * @param {string} changedFilesText
 * @returns {string[]}
 */
function inferTags(projectSlug, changedFilesText) {
  const tags = ['claude', 'session-log', 'auto', `project/${projectSlug}`];
  const extMap = {
    '.cs': 'tech/csharp', '.ts': 'tech/typescript', '.vue': 'tech/vue',
    '.py': 'tech/python', '.sql': 'tech/sql', '.ps1': 'tech/powershell',
    '.sh': 'tech/shell', '.json': 'tech/config', '.yaml': 'tech/config', '.yml': 'tech/config',
  };
  const domainMap = [
    [/\bauth/i, 'domain/auth'],
    [/\bapi\b/i, 'domain/api'],
    [/\bui\b|\bcomponent|\bview/i, 'domain/ui'],
    [/\bdatabase|\bdb\b|\bmigration|\bschema/i, 'domain/database'],
    [/\binfra|\bdocker|\btf\b|\bterraform/i, 'domain/infra'],
    [/\btest|\bspec/i, 'domain/test'],
  ];
  const seen = new Set(tags);
  const addTag = t => { if (!seen.has(t)) { tags.push(t); seen.add(t); } };
  if (changedFilesText) {
    for (const [ext, tag] of Object.entries(extMap)) {
      if (changedFilesText.includes(ext)) addTag(tag);
    }
    for (const [pattern, tag] of domainMap) {
      if (pattern.test(changedFilesText)) addTag(tag);
    }
  }
  return tags;
}

/**
 * Read agent/activity entries from the session journal.
 * @param {string} sid
 * @param {string} [overrideJournalDir]
 * @returns {{ agents: object[] }}
 */
function readJournal(sid, overrideJournalDir) {
  if (!sid) return { agents: [] };
  const journalDir = overrideJournalDir || path.join(os.homedir(), '.claude', 'session-journals');
  const journalPath = path.join(journalDir, `${sid}.jsonl`);
  try {
    const lines = readFileSync(journalPath, 'utf8').trim().split('\n').filter(Boolean);
    const agents = [];
    for (const line of lines) {
      try {
        const e = JSON.parse(line);
        if (e.type === 'agent' || e.type === 'activity') agents.push(e);
      } catch {}
    }
    return { agents };
  } catch { return { agents: [] }; }
}

/**
 * Read captured decisions from per-session or global decisions file.
 * @param {string} sid
 * @param {string} [overrideDir]
 * @returns {{ file: string|null, decisions: string[] }}
 */
function readDecisions(sid, overrideDir) {
  const base = overrideDir || path.join(os.homedir(), '.claude');
  const perSession = path.join(base, `session-decisions-${sid}.txt`);
  const global_ = path.join(base, 'session-decisions.txt');
  for (const f of [perSession, global_]) {
    try {
      const text = readFileSync(f, 'utf8').trim();
      if (text) return { file: f, decisions: text.split('\n').filter(Boolean) };
    } catch {}
  }
  return { file: null, decisions: [] };
}

/**
 * Read the session-state file; per-session first, global fallback.
 * @param {string} sid
 * @param {string} [overrideDir]
 * @returns {{ file: string|null, content: string }}
 */
function readSessionState(sid, overrideDir) {
  const base = overrideDir || path.join(os.homedir(), '.claude');
  const perSession = sid ? path.join(base, `session-state-${sid}.txt`) : null;
  const global_ = path.join(base, 'session-state.txt');
  for (const f of [perSession, global_].filter(Boolean)) {
    try {
      const text = readFileSync(f, 'utf8').trim();
      if (text) return { file: f, content: text };
    } catch {}
  }
  return { file: null, content: '' };
}

/**
 * Parse existing _current.md to extract threads and recent sessions.
 * @param {string} filePath
 * @returns {{ threads: {date: string, text: string}[], recentSessions: {link: string, dateTime: string}[] }}
 */
function parseCurrentNote(filePath) {
  const empty = { threads: [], recentSessions: [] };
  if (!existsSync(filePath)) return empty;
  try {
    const text = readFileSync(filePath, 'utf8');
    const lines = text.split('\n');

    let inThreads = false;
    let inSessions = false;
    const threads = [];
    const recentSessions = [];

    for (const line of lines) {
      if (/^##\s+Open threads/i.test(line)) { inThreads = true; inSessions = false; continue; }
      if (/^##\s+Recent sessions/i.test(line)) { inSessions = true; inThreads = false; continue; }
      if (/^##/.test(line)) { inThreads = false; inSessions = false; continue; }

      if (inThreads) {
        // Format: - (YYYY-MM-DD) <text>
        const m = line.match(/^-\s+\((\d{4}-\d{2}-\d{2})\)\s+(.+)$/);
        if (m) threads.push({ date: m[1], text: m[2].trim() });
      }
      if (inSessions) {
        // Format: - [[<link>]] (YYYY-MM-DD HH:MM)
        const m = line.match(/^-\s+(\[\[.+?\]\])\s+\((\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\)/);
        if (m) recentSessions.push({ link: m[1], dateTime: m[2] });
      }
    }
    return { threads, recentSessions };
  } catch { return { threads: [], recentSessions: [] }; }
}

/**
 * Derive the authoritative transcript path for a session.
 * @param {string} sid
 * @param {string} projDir
 * @returns {string}
 */
function resolveTranscriptPath(sid, projDir) {
  const projectKey = projDir.replace(/[:\\/]/g, '-');
  return path.join(os.homedir(), '.claude', 'projects', projectKey, `${sid}.jsonl`);
}

/**
 * Extract plain text from a message in any of the three shapes Claude produces:
 *   string | content-block[] | { content: string | content-block[] }
 * @param {unknown} msg
 * @returns {string}
 */
function extractTextFromMessage(msg) {
  if (typeof msg === 'string') return msg.trim();
  if (Array.isArray(msg)) {
    return msg.filter(b => b && b.type === 'text' && b.text).map(b => b.text).join(' ').trim();
  }
  if (msg && typeof msg === 'object' && msg.content) {
    return extractTextFromMessage(msg.content);
  }
  return '';
}

/**
 * Assemble the canonical _current.md template.
 * Eliminates four copies of the inline template used during ceiling enforcement.
 * @param {string} frontmatter
 * @param {string} whereWeLeftOff
 * @param {string[]} threadsLines    - already-formatted lines (or ['(none)'])
 * @param {string[]} sessionsLines   - already-formatted lines (or ['(none)'])
 * @returns {string}
 */
function assembleContent(frontmatter, whereWeLeftOff, threadsLines, sessionsLines) {
  const threadsText  = threadsLines.length  > 0 ? threadsLines.join('\n')  : '(none)';
  const sessionsText = sessionsLines.length > 0 ? sessionsLines.join('\n') : '(none)';
  return `${frontmatter}\n\n## Where we left off\n\n${whereWeLeftOff}\n\n## Open threads\n\n${threadsText}\n\n## Recent sessions\n\n${sessionsText}\n`;
}

/**
 * Build the _current.md content string (pure — no file I/O).
 *
 * @param {{ currentFilePath: string, projectRawName: string, date: string, time: string, sid: string, sessionRelLink: string }} ctx
 * @param {{ file: string|null, content: string }} stateData
 * @param {string|null} lastAssistantMsg
 * @returns {string}
 */
function buildCurrentNote(ctx, stateData, lastAssistantMsg) {
  const { currentFilePath, projectRawName, date: nowDate, time: nowTime, sessionRelLink } = ctx;

  // Parse existing file for round-trip preservation
  const existing = parseCurrentNote(currentFilePath);

  // --- "Where we left off" section ---
  let whereWeLeftOff = '';
  if (stateData.content) {
    // Use the last non-THREAD: non-DONE: plain line from the state file.
    // Sanitize: collapse newlines to spaces, escape bare YAML document separators.
    const statePlainLines = stateData.content.split('\n')
      .filter(l => l.trim() && !l.trim().startsWith('THREAD:') && !l.trim().startsWith('DONE:'));
    if (statePlainLines.length > 0) {
      const raw = statePlainLines[statePlainLines.length - 1].trim();
      whereWeLeftOff = raw
        .replace(/[\r\n]+/g, ' ')
        .replace(/^---$/gm, '\\---');
    }
  }
  if (!whereWeLeftOff && lastAssistantMsg) {
    // Transcript path already collapses newlines; still sanitize separators.
    whereWeLeftOff = lastAssistantMsg
      .replace(/[\n\r]+/g, ' ')
      .trim()
      .slice(0, 500)
      .replace(/^---$/gm, '\\---');
  }
  if (!whereWeLeftOff) whereWeLeftOff = '(no summary available)';

  // Render as blockquote to prevent prompt injection leakage into surrounding YAML/markdown.
  const asBlockquote = whereWeLeftOff.split('\n').map(l => `> ${l}`).join('\n');

  // --- Open threads ---
  let threads = existing.threads.slice(); // copy

  // Apply DONE: removals — all comparisons are case-insensitive
  if (stateData.content) {
    const doneLines = stateData.content.split('\n')
      .filter(l => l.trim().startsWith('DONE:'))
      .map(l => l.trim().slice('DONE:'.length).trim().toLowerCase());
    for (const doneKey of doneLines) {
      threads = threads.filter(t => t.text.toLowerCase() !== doneKey);
    }

    // Add new THREAD: lines — dedup is also case-insensitive; sanitize text
    const newThreadLines = stateData.content.split('\n')
      .filter(l => l.trim().startsWith('THREAD:'))
      .map(l => {
        const raw = l.trim().slice('THREAD:'.length).trim();
        // Sanitize externally-sourced thread text
        return raw.replace(/[\r\n]+/g, ' ').replace(/^---$/gm, '\\---');
      })
      .filter(Boolean);
    for (const threadText of newThreadLines) {
      const exists = threads.some(t => t.text.toLowerCase() === threadText.toLowerCase());
      if (!exists) {
        threads.push({ date: nowDate, text: threadText });
      }
    }
  }

  // Evict threads older than 14 days
  const nowMs = new Date(nowDate).getTime();
  threads = threads.filter(t => {
    try {
      const age = nowMs - new Date(t.date).getTime();
      return age <= 14 * 24 * 60 * 60 * 1000;
    } catch { return true; }
  });

  // Sort ascending by date unconditionally — required both for the FIFO cap and
  // for the 4KB ceiling loop which calls shift() expecting oldest-first order.
  threads.sort((a, b) => a.date.localeCompare(b.date));

  // FIFO cap at 10 (drop oldest — list is already sorted ascending)
  if (threads.length > 10) {
    threads = threads.slice(threads.length - 10);
  }

  // --- Recent sessions ---
  const sessionWikiLink = `[[${sessionRelLink}]]`;
  const sessionEntry = { link: sessionWikiLink, dateTime: `${nowDate} ${nowTime}` };

  // Prepend current session; deduplicate by link
  let recentSessions = [sessionEntry, ...existing.recentSessions.filter(s => s.link !== sessionWikiLink)];
  // Cap at 5 (newest first, already in order since we prepended)
  if (recentSessions.length > 5) recentSessions = recentSessions.slice(0, 5);

  // --- Assemble file ---
  const frontmatter =
`---
type: claude/current-state
project: ${projectRawName}
updated: ${nowDate}T${nowTime}
tags: [claude, current-state, auto]
---`;

  const toThreadLines   = ts => ts.map(t => `- (${t.date}) ${t.text}`);
  const toSessionLines  = ss => ss.map(s => `- ${s.link} (${s.dateTime})`);

  let content = assembleContent(frontmatter, asBlockquote, toThreadLines(threads), toSessionLines(recentSessions));

  // --- Hard byte ceiling: 4096 bytes ---
  const encoder = s => Buffer.byteLength(s, 'utf8');
  if (encoder(content) > 4096) {
    // Phase 1: drop oldest open threads first
    while (threads.length > 0 && encoder(content) > 4096) {
      threads.shift(); // oldest is first (sorted ascending above)
      content = assembleContent(frontmatter, asBlockquote, toThreadLines(threads), toSessionLines(recentSessions));
    }
  }

  if (encoder(content) > 4096) {
    // Phase 2: drop oldest recent-session lines
    while (recentSessions.length > 1 && encoder(content) > 4096) {
      recentSessions.pop(); // remove oldest (last in newest-first list)
      content = assembleContent(frontmatter, asBlockquote, toThreadLines(threads), toSessionLines(recentSessions));
    }
  }

  if (encoder(content) > 4096) {
    // Phase 3: truncate "Where we left off"
    let truncated = asBlockquote;
    while (truncated.length > 0 && encoder(content) > 4096) {
      truncated = truncated.slice(0, Math.max(0, truncated.length - 50));
      content = assembleContent(frontmatter, truncated, toThreadLines(threads), toSessionLines(recentSessions));
    }
  }

  // Phase 4: final safety clamp — hard-truncate at a UTF-8 character boundary.
  //    Handles pathological multi-byte content that the loop above cannot fully drain.
  if (encoder(content) > 4096) {
    const buf = Buffer.from(content, 'utf8').slice(0, 4096);
    // Walk back over trailing continuation bytes to find the last lead byte,
    // then drop the whole sequence if the cut left it incomplete — an orphan
    // lead byte would otherwise decode to U+FFFD and exceed the byte cap.
    let end = buf.length;
    let back = end;
    while (back > 0 && (buf[back - 1] & 0xc0) === 0x80) back--;
    if (back > 0 && (buf[back - 1] & 0x80) !== 0) {
      const lead = buf[back - 1];
      const seqLen = lead >= 0xf0 ? 4 : lead >= 0xe0 ? 3 : 2;
      if (end - (back - 1) < seqLen) end = back - 1;
    }
    content = buf.slice(0, end).toString('utf8');
  }

  return content;
}

/**
 * Write _current.md, using the REST API when available, filesystem as fallback.
 * Security: only writes to the exact computed _current.md path, never a subtree.
 *
 * @param {{ currentFilePath: string, projectRawName: string, date: string, time: string, sid: string, sessionRelLink: string }} ctx
 * @param {{ file: string|null, content: string }} stateData
 * @param {string|null} lastAssistantText
 * @param {string} vault
 * @param {string} baseDir
 * @param {string} apiKey
 * @param {number} apiPort
 * @param {boolean} apiHttps
 * @param {function} tryApiWrite
 */
function updateCurrentNote(ctx, stateData, lastAssistantText, vault, baseDir, apiKey, apiPort, apiHttps, tryApiWrite) {
  // Security: exact-path equality — only the canonical _current.md path is writable here
  const canonicalPath = path.resolve(baseDir, '_current.md');
  if (path.resolve(ctx.currentFilePath) !== canonicalPath) return;

  mkdirSync(path.dirname(ctx.currentFilePath), { recursive: true });
  const content = buildCurrentNote(ctx, stateData, lastAssistantText);

  if (apiKey) {
    const relCurrent = path.relative(vault, ctx.currentFilePath).replace(/\\/g, '/');
    tryApiWrite(relCurrent, content, ok => {
      if (!ok) {
        try { writeFileSync(ctx.currentFilePath, content, 'utf8'); } catch {}
      }
    });
  } else {
    writeFileSync(ctx.currentFilePath, content, 'utf8');
  }
}

// ---------------------------------------------------------------------------
// Module exports — consumed by the test file; also used when require()'d
// ---------------------------------------------------------------------------
module.exports = {
  inferTags,
  readJournal,
  readDecisions,
  readSessionState,
  parseCurrentNote,
  buildCurrentNote,
  assembleContent,
  extractTextFromMessage,
  resolveTranscriptPath,
};

// ---------------------------------------------------------------------------
// Entry point — only runs when invoked directly (not when require()'d)
// ---------------------------------------------------------------------------
function main() {
  // Hook must never block a session from ending.
  process.on('uncaughtException', () => process.exit(0));

  // --- Guard: vault must be set and exist ---
  const vault = (process.env.OBSIDIAN_VAULT_PATH || '').replace(/[\r\n]/g, '');
  if (!vault || !existsSync(vault)) process.exit(0);

  // --- Projects folder — defaults to Claude/Projects when not configured ---
  const projectsFolder = (process.env.OBSIDIAN_PROJECTS_FOLDER || 'Claude/Projects')
    .replace(/[\r\n]/g, '').replace(/[\\/]+$/, '');

  // --- Project context ---
  const projectDir = (process.env.CLAUDE_PROJECT_DIR || process.cwd()).replace(/[\r\n]/g, '');
  const rawName = path.basename(projectDir).replace(/[\r\n:#{}|>`]/g, '');

  // --- Git helper: returns trimmed stdout or '' on any failure ---
  const git = (...args) => {
    try {
      return execFileSync('git', ['-C', projectDir, ...args], {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
      }).trim();
    } catch { return ''; }
  };

  // --- Read stdin to get session_id (Stop/SessionEnd both deliver JSON on stdin) ---
  let raw = '';
  const stdinTimeout = setTimeout(() => proceed({}), 2000); // fallback: no stdin
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', d => { raw += d; });
  process.stdin.on('close', () => {
    clearTimeout(stdinTimeout);
    let payload = {};
    try { payload = JSON.parse(raw); } catch {}
    proceed(payload);
  });

  function proceed(payload) {
    // CLAUDE_CODE_SESSION_ID env var is the primary source on Windows (stdin is not piped).
    const sessionId = (process.env.CLAUDE_CODE_SESSION_ID || payload.session_id || '').replace(/[^a-zA-Z0-9_-]/g, '');
    const isSessionEnd = process.argv[2] === 'SessionEnd';

    // --- Build timestamp and slug early (needed before SHA guard for GUID logging) ---
    const now = new Date();
    const p2 = n => String(n).padStart(2, '0');
    const date = `${now.getFullYear()}-${p2(now.getMonth() + 1)}-${p2(now.getDate())}`;
    const time = `${p2(now.getHours())}:${p2(now.getMinutes())}`;
    const ts   = `${date}-${p2(now.getHours())}${p2(now.getMinutes())}`;
    const slug = rawName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 30);

    // --- Compute paths early ---
    const folderParts = projectsFolder.replace(/\\/g, '/').split('/').filter(Boolean);
    const baseDir = path.join(vault, ...folderParts, slug);
    const sessionPath = path.join(baseDir, 'sessions', `${ts}-${slug}.md`);
    const dailyPath   = path.join(baseDir, 'daily', `${date}.md`);
    const currentPath = path.join(baseDir, '_current.md');
    // Wikilink for session note — computed early so it is available on the early-exit path
    const relSession = path.relative(vault, sessionPath).replace(/\\/g, '/').replace(/\.md$/, '');

    // Security guard for session/daily/snapshot/ADR paths — subtree check is appropriate here
    const claudeRoot  = path.resolve(vault, 'Claude');
    const projectRoot = path.resolve(vault, ...folderParts);
    const allowedRoots = [claudeRoot, projectRoot];
    const inside = p => allowedRoots.some(root =>
      path.resolve(p).startsWith(root + path.sep) || path.resolve(p) === root
    );
    if (!inside(sessionPath) || !inside(dailyPath)) process.exit(0);

    // Security guard for _current.md: exact-path equality (stronger than subtree)
    const canonicalCurrentPath = path.resolve(baseDir, '_current.md');
    const currentPathSafe = path.resolve(currentPath) === canonicalCurrentPath;

    // ctx object for _current.md helpers
    const ctx = { currentFilePath: currentPath, projectRawName: rawName, date, time, sid: sessionId, sessionRelLink: relSession };

    // --- REST API config ---
    const apiKey   = (process.env.OBSIDIAN_REST_API_KEY  || '').replace(/[\r\n]/g, '');
    const apiPort  = parseInt(process.env.OBSIDIAN_REST_API_PORT || '27124', 10);
    const apiHttps = process.env.OBSIDIAN_REST_API_HTTPS !== 'false';

    function tryApiWrite(vaultRelPath, content, cb) {
      const { request } = require(apiHttps ? 'https' : 'http');
      const encoded = vaultRelPath.split('/').map(encodeURIComponent).join('/');
      const opts = {
        hostname: '127.0.0.1', port: apiPort,
        path: '/vault/' + encoded, method: 'PUT',
        headers: {
          'Authorization': 'Bearer ' + apiKey,
          'Content-Type': 'text/markdown',
          'Content-Length': Buffer.byteLength(content, 'utf8'),
        },
        rejectUnauthorized: false, timeout: 4000,
      };
      const req = request(opts, res => cb(res.statusCode >= 200 && res.statusCode < 300));
      req.on('error', () => cb(false));
      req.on('timeout', () => { req.destroy(); cb(false); });
      req.write(content, 'utf8');
      req.end();
    }

    // --- Minimal GUID log: always written on early exit so every session is recorded ---
    function writeSessionGuidLine() {
      if (!sessionId) return;
      try {
        mkdirSync(path.dirname(dailyPath), { recursive: true });
        const guidLine = `- ${time} session-end \`${sessionId}\` — ${rawName}`;
        if (!existsSync(dailyPath)) {
          writeFileSync(dailyPath, `# ${date}\n\n${guidLine}\n`, 'utf8');
        } else {
          appendFileSync(dailyPath, `\n${guidLine}\n`, 'utf8');
        }
      } catch {}
    }

    // --- Read prompts from transcript ---
    function readPromptsFromTranscript(sid) {
      if (!sid) return [];
      try {
        const transcriptPath = resolveTranscriptPath(sid, projectDir);
        const lines = readFileSync(transcriptPath, 'utf8').trim().split('\n').filter(Boolean);
        const seen = new Set(), results = [];
        for (const line of lines) {
          try {
            const e = JSON.parse(line);
            if (e.type === 'last-prompt' && e.lastPrompt && !seen.has(e.lastPrompt)) {
              seen.add(e.lastPrompt);
              results.push(e.lastPrompt.replace(/[\n\r]+/g, ' ').trim().slice(0, 500));
            }
          } catch {}
        }
        return results;
      } catch { return []; }
    }

    // --- Extract last assistant message from transcript ---
    function readLastAssistantMessage(sid) {
      if (!sid) return '';
      try {
        const transcriptPath = resolveTranscriptPath(sid, projectDir);
        const lines = readFileSync(transcriptPath, 'utf8').trim().split('\n').filter(Boolean);
        let lastAssistant = '';
        for (const line of lines) {
          try {
            const e = JSON.parse(line);
            if (e.type === 'assistant' && e.message) {
              const text = extractTextFromMessage(e.message);
              if (text) lastAssistant = text;
            }
          } catch {}
        }
        if (!lastAssistant) return '';
        return lastAssistant.replace(/[\n\r]+/g, ' ').trim().slice(0, 500);
      } catch { return ''; }
    }

    const prompts = readPromptsFromTranscript(sessionId);
    const { agents } = readJournal(sessionId);
    const hasJournalEntries = prompts.length > 0 || agents.length > 0;

    // --- SHA guard: skip full log if nothing changed and no journal activity ---
    const shaFile = path.join(os.homedir(), '.claude', 'obsidian-last-logged-sha');
    const headSha = git('rev-parse', 'HEAD');

    let hasDecisions = false;
    if (isSessionEnd && sessionId) {
      const perSession = path.join(os.homedir(), '.claude', `session-decisions-${sessionId}.txt`);
      const global_ = path.join(os.homedir(), '.claude', 'session-decisions.txt');
      for (const f of [perSession, global_]) {
        try {
          if (existsSync(f) && readFileSync(f, 'utf8').trim()) { hasDecisions = true; break; }
        } catch {}
      }
    }

    // Check if session-state has content (needed even on early-exit path)
    const stateResult = readSessionState(sessionId);
    const hasStateContent = Boolean(stateResult.content);

    const hasActivity = hasJournalEntries || (isSessionEnd && hasDecisions);
    if (!hasActivity) {
      if (headSha && existsSync(shaFile)) {
        const lastSha = readFileSync(shaFile, 'utf8').trim();
        if (headSha === lastSha && !git('status', '--short')) {
          writeSessionGuidLine();
          // On early-exit, still update _current.md if session-state has content
          if (hasStateContent && currentPathSafe) {
            try {
              updateCurrentNote(ctx, stateResult, null, vault, baseDir, apiKey, apiPort, apiHttps, tryApiWrite);
            } catch {}
          }
          process.exit(0);
        }
      }
    }

    // --- Gather git context ---
    const branch = (git('branch', '--show-current') || 'not a git repo').replace(/[\r\n:#{}|>`]/g, '');
    const recentCommits = git('log', '--oneline', '-5') || '(none)';
    const changedFiles = (() => {
      try {
        return execFileSync('git', ['-C', projectDir, 'diff', '--stat', 'HEAD~1'], {
          encoding: 'utf8',
          stdio: ['ignore', 'pipe', 'ignore'],
        }).trim();
      } catch { return ''; }
    })();
    const uncommitted = git('status', '--short');

    mkdirSync(path.dirname(sessionPath), { recursive: true });
    mkdirSync(path.dirname(dailyPath),   { recursive: true });

    const tags = inferTags(slug, changedFiles);

    const guidSuffix = sessionId ? ` — \`${sessionId}\`` : '';
    const dailyLine  = `- ${time} **session** [[${relSession}]]${guidSuffix} — branch: ${branch} (auto)`;

    // --- Build session file content ---
    const commitLines = recentCommits.split('\n').map(l => `- ${l}`).join('\n');
    const changedSection = changedFiles
      ? `## Files changed in last commit\n${changedFiles}\n\n`
      : '';
    const uncommittedSection = uncommitted
      ? `## Uncommitted changes\n${uncommitted.split('\n').filter(Boolean).map(l => `- ${l}`).join('\n')}\n\n`
      : '';

    const promptsSection = `\n## Prompts\n${prompts.map(p => `- ${p}`).join('\n') || '(none recorded)'}\n`;
    const agentsSection  = `\n## Agents invoked\n${agents.map(a => `- ${a.time} ${a.name}`).join('\n') || '(none)'}\n`;

    let decisionsSection = '';
    let decisionsFile = null;
    let decisions = [];

    if (isSessionEnd) {
      const decResult = readDecisions(sessionId);
      decisionsFile = decResult.file;
      decisions = decResult.decisions;
      decisionsSection = `\n## Decisions\n${decisions.map((d, i) => `${i + 1}. ${d}`).join('\n') || '(none captured)'}\n`;
    }

    const yamlEsc = s => s.replace(/"/g, '\\"');
    const sessionContent =
`---
type: claude/session
project: ${rawName}
project_dir: "${yamlEsc(projectDir)}"
session_id: ${sessionId}
date: ${date}
ended_at: ${date}T${time}
branch: ${branch}
tags: [${tags.join(', ')}]
---

## Recent commits
${commitLines}

${changedSection}${uncommittedSection}${promptsSection}${agentsSection}${decisionsSection}<!-- auto-logged by Stop hook -->
`;

    // --- Memory snapshot helper ---
    function writeMemorySnapshot() {
      const memoryDir = path.join(projectDir, 'memory');
      if (!existsSync(memoryDir)) return;
      try {
        const collectMd = (dir, prefix) => {
          const entries = [];
          for (const entry of readdirSync(dir, { withFileTypes: true })) {
            const fullPath = path.join(dir, entry.name);
            const label = prefix ? `${prefix}/${entry.name}` : entry.name;
            if (entry.isDirectory()) {
              entries.push(...collectMd(fullPath, label));
            } else if (entry.name.endsWith('.md') && entry.name !== 'MEMORY.md') {
              entries.push({ fullPath, label });
            }
          }
          return entries;
        };
        const memFiles = collectMd(memoryDir, '').sort((a, b) => a.label.localeCompare(b.label));
        if (memFiles.length > 0) {
          const snapshotPath = path.join(baseDir, 'memory-snapshot.md');
          if (inside(snapshotPath)) {
            mkdirSync(path.dirname(snapshotPath), { recursive: true });
            let snapshot = `---\ntype: claude/memory-snapshot\nproject: ${rawName}\ndate: ${date}\ntags: [claude, memory, auto]\n---\n\n`;
            for (const { fullPath, label } of memFiles) {
              try { snapshot += `## ${label}\n\n${readFileSync(fullPath, 'utf8')}\n\n---\n\n`; } catch {}
            }
            writeFileSync(snapshotPath, snapshot, 'utf8');
          }
        }
      } catch {}
    }

    // --- SessionEnd-only: write ADR files (best-effort; errors intentionally swallowed) ---
    function writeADRs() {
      if (!decisions.length) return;
      const decisionsDir = path.join(baseDir, 'decisions');
      mkdirSync(decisionsDir, { recursive: true });
      for (let i = 0; i < decisions.length; i++) {
        const decisionText = decisions[i];
        const adrId = `ADR-${date}-${p2(now.getHours())}${p2(now.getMinutes())}-${String(i + 1).padStart(2, '0')}`;
        const adrPath = path.join(decisionsDir, `${adrId}.md`);
        if (!inside(adrPath)) continue;
        // Prevent --- lines in decision body from being parsed as YAML document separators
        const safeDecisionText = decisionText.replace(/^---$/gm, '\\---');
        const adrContent =
`---
type: adr
id: ${adrId}
project: ${rawName}
session_id: ${sessionId}
date: ${date}
status: accepted
session: "[[${relSession}]]"
tags: [adr, claude, ${tags.join(', ')}]
---

## Decision
${safeDecisionText}
`;
        try {
          if (apiKey) {
            const relAdr = path.relative(vault, adrPath).replace(/\\/g, '/');
            tryApiWrite(relAdr, adrContent, ok => {
              if (!ok) {
                try { writeFileSync(adrPath, adrContent, 'utf8'); } catch {}
              }
            });
          } else {
            writeFileSync(adrPath, adrContent, 'utf8');
          }
        } catch {}
      }

      // Clear the decisions file after reading
      if (decisionsFile) {
        try { writeFileSync(decisionsFile, '', 'utf8'); } catch {}
      }
    }

    // --- SessionEnd-only: cleanup journal ---
    function cleanupJournal() {
      if (!sessionId) return;
      const journalPath = path.join(os.homedir(), '.claude', 'session-journals', `${sessionId}.jsonl`);
      try { unlinkSync(journalPath); } catch {}
    }

    // --- SessionEnd-only: cleanup session-state file ---
    function cleanupSessionState() {
      if (!stateResult.file) return;
      try { unlinkSync(stateResult.file); } catch {}
    }

    function finish() {
      // Update _current.md on both Stop and SessionEnd
      if (currentPathSafe) {
        try {
          const lastAssistantMsg = readLastAssistantMessage(sessionId);
          updateCurrentNote(ctx, stateResult, lastAssistantMsg, vault, baseDir, apiKey, apiPort, apiHttps, tryApiWrite);
        } catch {}
      }

      writeMemorySnapshot();
      if (isSessionEnd) {
        writeADRs();
        cleanupJournal();
        cleanupSessionState();
      }
      if (headSha) {
        try { writeFileSync(shaFile, headSha + '\n', 'utf8'); } catch {}
      }
      process.exit(0);
    }

    function writeSessionFilesystem() { writeFileSync(sessionPath, sessionContent, 'utf8'); }

    function writeDailyNote() {
      if (!existsSync(dailyPath)) {
        writeFileSync(dailyPath, `# ${date}\n\n${dailyLine}\n`, 'utf8');
      } else {
        appendFileSync(dailyPath, `\n${dailyLine}\n`, 'utf8');
      }
    }

    if (apiKey) {
      const relSessionMd = path.relative(vault, sessionPath).replace(/\\/g, '/');
      const relDailyMd   = path.relative(vault, dailyPath).replace(/\\/g, '/');

      tryApiWrite(relSessionMd, sessionContent, sessionOk => {
        if (!sessionOk) writeSessionFilesystem();

        // Daily note via REST API: GET existing → append line → PUT back
        const { request } = require(apiHttps ? 'https' : 'http');
        const getOpts = {
          hostname: '127.0.0.1', port: apiPort,
          path: '/vault/' + relDailyMd.split('/').map(encodeURIComponent).join('/'),
          method: 'GET',
          headers: { 'Authorization': 'Bearer ' + apiKey },
          rejectUnauthorized: false, timeout: 4000,
        };
        const getReq = request(getOpts, getRes => {
          let existingContent = '';
          getRes.on('data', chunk => { existingContent += chunk; });
          getRes.on('end', () => {
            const newContent = getRes.statusCode === 200
              ? existingContent.trimEnd() + '\n\n' + dailyLine + '\n'
              : `# ${date}\n\n${dailyLine}\n`;
            tryApiWrite(relDailyMd, newContent, dailyOk => {
              if (!dailyOk) writeDailyNote();
              finish();
            });
          });
        });
        getReq.on('error',   () => { writeDailyNote(); finish(); });
        getReq.on('timeout', () => { getReq.destroy(); writeDailyNote(); finish(); });
        getReq.end();
      });
    } else {
      // No API key — filesystem writes only
      writeSessionFilesystem();
      writeDailyNote();
      finish();
    }
  }
}

if (require.main === module) main();
