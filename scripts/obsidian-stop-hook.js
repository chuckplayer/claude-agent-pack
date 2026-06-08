'use strict';
const { execFileSync } = require('child_process');
const { existsSync, mkdirSync, writeFileSync, appendFileSync, readFileSync, readdirSync, unlinkSync } = require('fs');
const path = require('path');
const os = require('os');

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
  const sessionId = (payload.session_id || '').replace(/[^a-zA-Z0-9_-]/g, '');
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

  // Security guard: allow Claude/ root, the effective projects folder root, and decisions subdir
  const claudeRoot  = path.resolve(vault, 'Claude');
  const projectRoot = path.resolve(vault, ...folderParts);
  const allowedRoots = [claudeRoot, projectRoot];
  const inside = p => allowedRoots.some(root =>
    path.resolve(p).startsWith(root + path.sep) || path.resolve(p) === root
  );
  if (!inside(sessionPath) || !inside(dailyPath)) process.exit(0);

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

  // --- SHA guard: skip full log if nothing has changed since last log ---
  // For SessionEnd: bypass if decisions exist (to ensure ADRs are always written)
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

  if (!isSessionEnd || !hasDecisions) {
    if (headSha && existsSync(shaFile)) {
      const lastSha = readFileSync(shaFile, 'utf8').trim();
      if (headSha === lastSha && !git('status', '--short')) {
        // Nothing changed — still record the session GUID in the daily note, then exit.
        writeSessionGuidLine();
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

  // --- Smart tag inference ---
  function inferTags(projectSlug, _projectDir, changedFilesText) {
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

  const tags = inferTags(slug, projectDir, changedFiles);

  // --- REST API config ---
  const apiKey   = (process.env.OBSIDIAN_REST_API_KEY  || '').replace(/[\r\n]/g, '');
  const apiPort  = parseInt(process.env.OBSIDIAN_REST_API_PORT || '27124', 10);
  const apiHttps = process.env.OBSIDIAN_REST_API_HTTPS !== 'false';

  // Wikilink for session note (no .md extension, forward slashes)
  const relSession = path.relative(vault, sessionPath).replace(/\\/g, '/').replace(/\.md$/, '');
  const guidSuffix = sessionId ? ` — \`${sessionId}\`` : '';
  const dailyLine  = `- ${time} **session** [[${relSession}]]${guidSuffix} — branch: ${branch} (auto)`;

  // --- SessionEnd-only: read journal ---
  function readJournal(sid) {
    if (!sid) return { prompts: [], agents: [] };
    const journalPath = path.join(os.homedir(), '.claude', 'session-journals', `${sid}.jsonl`);
    try {
      const lines = readFileSync(journalPath, 'utf8').trim().split('\n').filter(Boolean);
      const prompts = [], agents = [];
      for (const line of lines) {
        try {
          const e = JSON.parse(line);
          if (e.type === 'prompt') prompts.push(e);
          else if (e.type === 'agent') agents.push(e);
        } catch {}
      }
      return { prompts, agents };
    } catch { return { prompts: [], agents: [] }; }
  }

  // --- SessionEnd-only: read decisions ---
  function readDecisions(sid) {
    const perSession = path.join(os.homedir(), '.claude', `session-decisions-${sid}.txt`);
    const global_ = path.join(os.homedir(), '.claude', 'session-decisions.txt');
    for (const f of [perSession, global_]) {
      try {
        const text = readFileSync(f, 'utf8').trim();
        if (text) return { file: f, decisions: text.split('\n').filter(Boolean) };
      } catch {}
    }
    return { file: null, decisions: [] };
  }

  // --- Build session file content ---
  const commitLines = recentCommits.split('\n').map(l => `- ${l}`).join('\n');
  const changedSection = changedFiles
    ? `## Files changed in last commit\n${changedFiles}\n\n`
    : '';
  const uncommittedSection = uncommitted
    ? `## Uncommitted changes\n${uncommitted.split('\n').filter(Boolean).map(l => `- ${l}`).join('\n')}\n\n`
    : '';

  // Gather SessionEnd-only data
  let promptsSection = '';
  let agentsSection = '';
  let decisionsSection = '';
  let decisionsFile = null;
  let decisions = [];

  if (isSessionEnd) {
    const journal = readJournal(sessionId);
    const { prompts, agents } = journal;
    promptsSection = `\n## Prompts\n${prompts.map(p => `- ${p.time} ${p.text}`).join('\n') || '(none recorded)'}\n`;
    agentsSection = `\n## Agents invoked\n${agents.map(a => `- ${a.time} ${a.name}`).join('\n') || '(none)'}\n`;

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

  function finish() {
    writeMemorySnapshot();
    if (isSessionEnd) {
      writeADRs();
      cleanupJournal();
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
        let existing = '';
        getRes.on('data', chunk => { existing += chunk; });
        getRes.on('end', () => {
          const newContent = getRes.statusCode === 200
            ? existing.trimEnd() + '\n\n' + dailyLine + '\n'
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
