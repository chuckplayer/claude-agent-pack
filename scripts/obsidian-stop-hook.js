'use strict';
const { execFileSync } = require('child_process');
const { existsSync, mkdirSync, writeFileSync, appendFileSync, readFileSync, readdirSync } = require('fs');
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

// --- SHA guard: skip if nothing has changed since last log ---
const shaFile = path.join(os.homedir(), '.claude', 'obsidian-last-logged-sha');
const headSha = git('rev-parse', 'HEAD');
if (headSha && existsSync(shaFile)) {
  const lastSha = readFileSync(shaFile, 'utf8').trim();
  if (headSha === lastSha && !git('status', '--short')) process.exit(0);
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

// --- Build timestamp and slug ---
const now = new Date();
const p2 = n => String(n).padStart(2, '0');
const date = `${now.getFullYear()}-${p2(now.getMonth() + 1)}-${p2(now.getDate())}`;
const time = `${p2(now.getHours())}:${p2(now.getMinutes())}`;
const ts   = `${date}-${p2(now.getHours())}${p2(now.getMinutes())}`;
const slug = rawName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 30);

// --- Compute base directory for this project ---
// projectsFolder may be multi-segment (e.g. "Claude/Projects"), split and join safely
const folderParts = projectsFolder.replace(/\\/g, '/').split('/').filter(Boolean);
const baseDir = path.join(vault, ...folderParts, slug);

// --- Resolve target paths ---
const sessionPath = path.join(baseDir, 'sessions', `${ts}-${slug}.md`);
const dailyPath   = path.join(baseDir, 'daily', `${date}.md`);

// Security guard: allow Claude/ root and the effective projects folder root
const claudeRoot  = path.resolve(vault, 'Claude');
const projectRoot = path.resolve(vault, ...folderParts);
const allowedRoots = [claudeRoot, projectRoot];
const inside = p => allowedRoots.some(root =>
  path.resolve(p).startsWith(root + path.sep) || path.resolve(p) === root
);
if (!inside(sessionPath) || !inside(dailyPath)) process.exit(0);

mkdirSync(path.dirname(sessionPath), { recursive: true });
mkdirSync(path.dirname(dailyPath),   { recursive: true });

// --- Build session file content ---
const commitLines = recentCommits.split('\n').map(l => `- ${l}`).join('\n');

const changedSection = changedFiles
  ? `## Files changed in last commit\n${changedFiles}\n\n`
  : '';

const uncommittedSection = uncommitted
  ? `## Uncommitted changes\n${uncommitted.split('\n').filter(Boolean).map(l => `- ${l}`).join('\n')}\n\n`
  : '';

const sessionContent =
`---
type: claude/session
project: ${rawName}
project_dir: ${projectDir}
date: ${date}
ended_at: ${date}T${time}
branch: ${branch}
tags: [claude, session-log, auto]
---

## Recent commits
${commitLines}

${changedSection}${uncommittedSection}<!-- auto-logged by Stop hook -->
`;

writeFileSync(sessionPath, sessionContent, 'utf8');

// --- Append to daily note ---
// Wikilink must be relative to vault root with forward slashes (Obsidian requirement)
const relSession = path.relative(vault, sessionPath).replace(/\\/g, '/').replace(/\.md$/, '');
const dailyLine = `- ${time} **session** [[${relSession}]] — branch: ${branch} (auto)`;
if (!existsSync(dailyPath)) {
  writeFileSync(dailyPath, `# ${date}\n\n${dailyLine}\n`, 'utf8');
} else {
  appendFileSync(dailyPath, `\n${dailyLine}\n`, 'utf8');
}

// --- Memory snapshot: freeze ./memory/**/*.md into the vault ---
const memoryDir = path.join(projectDir, 'memory');
if (existsSync(memoryDir)) {
  try {
    // Collect all .md files recursively (depth 2: memory/<subdir>/<file>.md)
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
          try {
            snapshot += `## ${label}\n\n${readFileSync(fullPath, 'utf8')}\n\n---\n\n`;
          } catch {}
        }
        writeFileSync(snapshotPath, snapshot, 'utf8');
      }
    }
  } catch {}
}

// --- Persist SHA for next run ---
if (headSha) writeFileSync(shaFile, headSha + '\n', 'utf8');

process.exit(0);
