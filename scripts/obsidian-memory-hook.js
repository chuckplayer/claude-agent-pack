'use strict';
// PostToolUse hook (matcher: Write|Edit) — mirrors memory file writes to the Obsidian vault.
// Fires after every Write or Edit tool call; exits immediately for non-memory targets.
const { existsSync, mkdirSync, writeFileSync, readFileSync } = require('fs');
const path = require('path');

process.on('uncaughtException', () => process.exit(0));

const vault = (process.env.OBSIDIAN_VAULT_PATH || '').replace(/[\r\n]/g, '');
if (!vault || !existsSync(vault)) process.exit(0);

let raw = '';
const stdinTimeout = setTimeout(() => process.exit(0), 2000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', d => { raw += d; });
process.stdin.on('close', () => {
  clearTimeout(stdinTimeout);
  try {
    const payload = JSON.parse(raw);
    const toolInput = payload.tool_input || {};
    const filePath = (toolInput.file_path || '').replace(/[\r\n]/g, '');

    if (!filePath || !filePath.endsWith('.md')) process.exit(0);

    const basename = path.basename(filePath);
    if (basename === 'MEMORY.md') process.exit(0);

    // Must be inside .claude/projects/.../memory/
    const norm = filePath.replace(/\\/g, '/');
    if (!norm.includes('/.claude/projects/') || !norm.includes('/memory/')) process.exit(0);

    // By PostToolUse time the file is already written — read it to get current content.
    let content;
    try { content = readFileSync(filePath, 'utf8'); } catch { process.exit(0); }

    // Project slug — same derivation as the stop and context hooks, so the folder
    // name matches the one used under the projects folder. Namespacing by project
    // is required: memory filenames are generic and collide across projects.
    const projectDir = (process.env.CLAUDE_PROJECT_DIR || payload.cwd || process.cwd())
      .replace(/[\r\n]/g, '');
    const rawName = path.basename(projectDir).replace(/[\r\n:#{}|>`]/g, '');
    const slug = rawName.toLowerCase().replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '').slice(0, 30) || 'unknown';

    // Mirror to vault: Claude/Memory/<project-slug>/<filename>
    const targetDir = path.join(vault, 'Claude', 'Memory', slug);
    const targetPath = path.join(targetDir, basename);

    // Security guard: must stay inside vault/Claude/
    const claudeRoot = path.resolve(vault, 'Claude');
    if (!path.resolve(targetPath).startsWith(claudeRoot + path.sep)) process.exit(0);

    mkdirSync(targetDir, { recursive: true });
    writeFileSync(targetPath, content, 'utf8');
  } catch {}
  process.exit(0);
});
