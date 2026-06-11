'use strict';
// SessionStart hook — prints the project's _current.md to stdout so Claude Code
// injects it into context at the start of each session.
// Read-only: this hook never writes anything.
const { existsSync, readFileSync } = require('fs');
const path = require('path');

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
const slug = rawName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 30);

// --- Compute path to _current.md ---
const folderParts = projectsFolder.replace(/\\/g, '/').split('/').filter(Boolean);
const baseDir = path.join(vault, ...folderParts, slug);
const currentPath = path.join(baseDir, '_current.md');

// Security guard: exact-path equality — the only readable path is the canonical _current.md.
// This is stronger than a subtree check and prevents path-traversal to sibling projects.
const canonicalCurrentPath = path.resolve(baseDir, '_current.md');
if (path.resolve(currentPath) !== canonicalCurrentPath) process.exit(0);

// --- Read and print _current.md if it exists ---
if (!existsSync(currentPath)) process.exit(0);

try {
  const raw = readFileSync(currentPath, 'utf8');
  // Cap at 8KB (byte-aware: walk back to a valid UTF-8 boundary if needed)
  let content = raw;
  if (Buffer.byteLength(raw, 'utf8') > 8192) {
    const buf = Buffer.from(raw, 'utf8').slice(0, 8192);
    let end = buf.length;
    // Walk back over trailing continuation bytes to find the last lead byte,
    // then drop the whole sequence if the cut left it incomplete — an orphan
    // lead byte would otherwise decode to U+FFFD and exceed the byte cap.
    let back = end;
    while (back > 0 && (buf[back - 1] & 0xc0) === 0x80) back--;
    if (back > 0 && (buf[back - 1] & 0x80) !== 0) {
      const lead = buf[back - 1];
      const seqLen = lead >= 0xf0 ? 4 : lead >= 0xe0 ? 3 : 2;
      if (end - (back - 1) < seqLen) end = back - 1;
    }
    content = buf.slice(0, end).toString('utf8');
  }
  process.stdout.write('## Obsidian project context (_current.md)\n\n');
  process.stdout.write(content);
  if (!content.endsWith('\n')) process.stdout.write('\n');
} catch {}

process.exit(0);
