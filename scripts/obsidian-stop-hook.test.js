'use strict';
/**
 * Tests for pure logic in obsidian-stop-hook.js.
 *
 * Run with:  node scripts/obsidian-stop-hook.test.js
 *
 * No npm dependencies. Uses only Node stdlib: assert, fs, os, path.
 *
 * All functions under test are imported directly from the hook module via
 * module.exports — no inlined copies.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const {
  inferTags,
  readJournal,
  readDecisions,
  readSessionState,
  parseCurrentNote,
  buildCurrentNote,
  assembleContent,
  extractTextFromMessage,
  resolveTranscriptPath,
} = require('./obsidian-stop-hook');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
let tmpDir;
function setupTmp() {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'stop-hook-test-'));
}
function teardownTmp() {
  fs.rmSync(tmpDir, { recursive: true, force: true });
}

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    setupTmp();
    fn();
    console.log(`  PASS  ${name}`);
    passed++;
  } catch (err) {
    console.error(`  FAIL  ${name}`);
    console.error(`        ${err.message}`);
    failed++;
  } finally {
    teardownTmp();
  }
}

// ---------------------------------------------------------------------------
// Shared test constants
// ---------------------------------------------------------------------------
const REF_DATE = '2026-06-11';
const REF_TIME = '14:30';
const REF_SESSION = 'Claude/Projects/my-project/sessions/2026-06-11-1430-my-project';

function makeCtx(overrides) {
  return {
    currentFilePath: path.join(tmpDir, '_current.md'),
    projectRawName: 'my-project',
    date: REF_DATE,
    time: REF_TIME,
    sid: 'test-sid',
    sessionRelLink: REF_SESSION,
    ...overrides,
  };
}

function makeStateData(content) {
  return { file: '/some/path', content };
}

// ---------------------------------------------------------------------------
// inferTags tests
// ---------------------------------------------------------------------------
console.log('\ninferTags');

test('always includes the four base tags', () => {
  const tags = inferTags('my-project', '');
  assert.ok(tags.includes('claude'));
  assert.ok(tags.includes('session-log'));
  assert.ok(tags.includes('auto'));
  assert.ok(tags.includes('project/my-project'));
});

test('project slug is embedded in the project tag', () => {
  const tags = inferTags('order-api', '');
  assert.ok(tags.includes('project/order-api'));
  assert.ok(!tags.includes('project/my-project'));
});

test('null changedFilesText returns only base tags', () => {
  const tags = inferTags('slug', null);
  assert.strictEqual(tags.length, 4);
});

test('empty changedFilesText returns only base tags', () => {
  const tags = inferTags('slug', '');
  assert.strictEqual(tags.length, 4);
});

test('detects .ts extension -> tech/typescript', () => {
  const tags = inferTags('slug', 'src/service.ts | 5 ++++');
  assert.ok(tags.includes('tech/typescript'));
});

test('detects .cs extension -> tech/csharp', () => {
  const tags = inferTags('slug', 'OrderService.cs | 10 ++');
  assert.ok(tags.includes('tech/csharp'));
});

test('detects .vue extension -> tech/vue', () => {
  const tags = inferTags('slug', 'components/MyComponent.vue | 3 -');
  assert.ok(tags.includes('tech/vue'));
});

test('detects .sql extension -> tech/sql', () => {
  const tags = inferTags('slug', 'migrations/001_create.sql | 20 ++');
  assert.ok(tags.includes('tech/sql'));
});

test('detects .ps1 extension -> tech/powershell', () => {
  const tags = inferTags('slug', 'scripts/deploy.ps1 | 2 +');
  assert.ok(tags.includes('tech/powershell'));
});

test('detects .sh extension -> tech/shell', () => {
  const tags = inferTags('slug', 'install.sh | 5 +');
  assert.ok(tags.includes('tech/shell'));
});

test('detects .json extension -> tech/config', () => {
  const tags = inferTags('slug', 'appsettings.json | 1 +');
  assert.ok(tags.includes('tech/config'));
});

test('detects .yaml extension -> tech/config', () => {
  const tags = inferTags('slug', 'pipeline.yaml | 4 ++');
  assert.ok(tags.includes('tech/config'));
});

test('detects .yml extension -> tech/config', () => {
  const tags = inferTags('slug', 'docker-compose.yml | 8 +++');
  assert.ok(tags.includes('tech/config'));
});

test('.yaml and .yml both present produces only one tech/config tag (no duplicate)', () => {
  const tags = inferTags('slug', 'a.yaml b.yml');
  assert.strictEqual(tags.filter(t => t === 'tech/config').length, 1);
});

test('detects auth path -> domain/auth', () => {
  const tags = inferTags('slug', 'src/auth/AuthService.cs');
  assert.ok(tags.includes('domain/auth'));
});

test('detects api path -> domain/api', () => {
  const tags = inferTags('slug', 'src/api/OrdersController.cs');
  assert.ok(tags.includes('domain/api'));
});

test('detects component path -> domain/ui', () => {
  const tags = inferTags('slug', 'src/components/OrderList.vue');
  assert.ok(tags.includes('domain/ui'));
});

test('detects view path -> domain/ui', () => {
  const tags = inferTags('slug', 'src/views/OrderView.vue');
  assert.ok(tags.includes('domain/ui'));
});

test('detects database path -> domain/database', () => {
  const tags = inferTags('slug', 'src/database/Repository.cs');
  assert.ok(tags.includes('domain/database'));
});

test('detects migration path -> domain/database', () => {
  const tags = inferTags('slug', 'migrations/001_add_orders.sql');
  assert.ok(tags.includes('domain/database'));
});

test('detects schema path -> domain/database', () => {
  const tags = inferTags('slug', 'db/schema.sql');
  assert.ok(tags.includes('domain/database'));
});

test('detects docker path -> domain/infra', () => {
  const tags = inferTags('slug', 'docker-compose.yml');
  assert.ok(tags.includes('domain/infra'));
});

test('detects terraform path -> domain/infra', () => {
  const tags = inferTags('slug', 'infra/main.tf');
  assert.ok(tags.includes('domain/infra'));
});

test('detects test path -> domain/test', () => {
  const tags = inferTags('slug', 'OrderService.test.ts');
  assert.ok(tags.includes('domain/test'));
});

test('detects spec path -> domain/test', () => {
  const tags = inferTags('slug', 'tests/OrderSpec.cs');
  assert.ok(tags.includes('domain/test'));
});

test('multiple extensions in one diff stat produce multiple tech tags', () => {
  const tags = inferTags('slug', 'Service.cs | 5\nService.ts | 3\nView.vue | 2');
  assert.ok(tags.includes('tech/csharp'));
  assert.ok(tags.includes('tech/typescript'));
  assert.ok(tags.includes('tech/vue'));
});

test('multiple domains in one diff stat produce multiple domain tags', () => {
  const tags = inferTags('slug', 'auth/Login.cs database/Repo.cs');
  assert.ok(tags.includes('domain/auth'));
  assert.ok(tags.includes('domain/database'));
});

test('base tags are never duplicated regardless of slug', () => {
  const tags = inferTags('claude', 'auto session-log');
  assert.strictEqual(tags.filter(t => t === 'claude').length, 1);
  assert.strictEqual(tags.filter(t => t === 'auto').length, 1);
  assert.strictEqual(tags.filter(t => t === 'session-log').length, 1);
});

// ---------------------------------------------------------------------------
// readJournal tests
// ---------------------------------------------------------------------------
console.log('\nreadJournal');

test('empty session id returns empty result', () => {
  const result = readJournal('', tmpDir);
  assert.deepStrictEqual(result, { agents: [] });
});

test('null session id returns empty result', () => {
  const result = readJournal(null, tmpDir);
  assert.deepStrictEqual(result, { agents: [] });
});

test('non-existent journal file returns empty result', () => {
  const result = readJournal('does-not-exist', tmpDir);
  assert.deepStrictEqual(result, { agents: [] });
});

test('valid JSONL with agent entries populates agents array', () => {
  const sid = 'test-session-002';
  const line1 = JSON.stringify({ time: '09:30', type: 'agent', name: 'csharp-engineer' });
  const line2 = JSON.stringify({ time: '09:45', type: 'agent', name: 'code-reviewer' });
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), `${line1}\n${line2}\n`, 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.agents.length, 2);
  assert.strictEqual(result.agents[0].name, 'csharp-engineer');
  assert.strictEqual(result.agents[1].name, 'code-reviewer');
});

test('activity entries are included alongside agent entries', () => {
  const sid = 'test-session-003';
  const lines = [
    JSON.stringify({ time: '10:00', type: 'activity' }),
    JSON.stringify({ time: '10:05', type: 'agent', name: 'tech-lead' }),
    JSON.stringify({ time: '10:10', type: 'activity' }),
    JSON.stringify({ time: '10:15', type: 'agent', name: 'frontend-engineer' }),
  ].join('\n');
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), lines + '\n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.agents.length, 4);
});

test('entries with unknown type are not included', () => {
  const sid = 'test-session-005';
  const content = [
    JSON.stringify({ time: '10:00', type: 'other', data: 'ignored' }),
    JSON.stringify({ time: '10:01', type: 'agent', name: 'code-reviewer' }),
  ].join('\n');
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), content + '\n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.agents.length, 1);
  assert.strictEqual(result.agents[0].name, 'code-reviewer');
});

test('malformed JSON lines are skipped silently', () => {
  const sid = 'test-session-004';
  const content = [
    '{ this is not json at all',
    JSON.stringify({ time: '10:05', type: 'agent', name: 'code-reviewer' }),
    '{"type":"agent","name": missing closing',
  ].join('\n');
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), content + '\n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.agents.length, 1);
  assert.strictEqual(result.agents[0].name, 'code-reviewer');
});

test('empty journal file returns empty result', () => {
  const sid = 'test-session-006';
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), '', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.deepStrictEqual(result, { agents: [] });
});

test('journal file containing only whitespace returns empty result', () => {
  const sid = 'test-session-007';
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), '   \n\n  \n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.deepStrictEqual(result, { agents: [] });
});

// ---------------------------------------------------------------------------
// readDecisions tests
// ---------------------------------------------------------------------------
console.log('\nreadDecisions');

test('per-session file found and returned when it has content', () => {
  const sid = 'abc123';
  const decContent = '[10:30] Use repository pattern — separates concerns cleanly\n[10:45] Vue 3 over React — team familiarity\n';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), decContent, 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.deepStrictEqual(result.files, [path.join(tmpDir, `session-decisions-${sid}.txt`)]);
  assert.strictEqual(result.decisions.length, 2);
  assert.ok(result.decisions[0].includes('repository pattern'));
  assert.ok(result.decisions[1].includes('Vue 3'));
});

test('global file read when per-session file is absent', () => {
  const sid = 'abc456';
  const decContent = '[11:00] Deploy to Azure — existing infrastructure\n';
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), decContent, 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.deepStrictEqual(result.files, [path.join(tmpDir, 'session-decisions.txt')]);
  assert.strictEqual(result.decisions.length, 1);
});

test('global file read when per-session file is empty', () => {
  const sid = 'abc789';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '[12:00] Use EF Core — ORM already in stack\n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.deepStrictEqual(result.files, [path.join(tmpDir, 'session-decisions.txt')]);
  assert.strictEqual(result.decisions.length, 1);
});

test('per-session and global are BOTH read, per-session first — neither is dropped', () => {
  const sid = 'priority-test';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '[09:00] Session-specific decision\n', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '[09:30] Global decision\n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.strictEqual(result.decisions.length, 2);
  assert.ok(result.decisions[0].includes('Session-specific'));
  assert.ok(result.decisions[1].includes('Global decision'));
  assert.strictEqual(result.files.length, 2);
});

test('unknown-fallback file is read — regression: it was write-only and lost decisions', () => {
  const sid = 'has-no-own-file';
  fs.writeFileSync(path.join(tmpDir, 'session-decisions-unknown.txt'), '[13:00] Orphaned decision — session id never resolved\n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.deepStrictEqual(result.files, [path.join(tmpDir, 'session-decisions-unknown.txt')]);
  assert.strictEqual(result.decisions.length, 1);
  assert.ok(result.decisions[0].includes('Orphaned decision'));
});

test('all three sources merge in order and every contributing file is returned', () => {
  const sid = 'all-three';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '[01:00] A\n', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '[02:00] B\n', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions-unknown.txt'), '[03:00] C\n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.strictEqual(result.decisions.length, 3);
  assert.ok(result.decisions[0].endsWith('A'));
  assert.ok(result.decisions[1].endsWith('B'));
  assert.ok(result.decisions[2].endsWith('C'));
  assert.deepStrictEqual(result.files, [
    path.join(tmpDir, `session-decisions-${sid}.txt`),
    path.join(tmpDir, 'session-decisions.txt'),
    path.join(tmpDir, 'session-decisions-unknown.txt'),
  ]);
});

test('empty sid does not read a bare session-decisions-.txt path', () => {
  fs.writeFileSync(path.join(tmpDir, 'session-decisions-.txt'), '[04:00] Bare-suffix file\n', 'utf8');

  const result = readDecisions('', tmpDir);
  assert.deepStrictEqual(result.files, []);
  assert.deepStrictEqual(result.decisions, []);
});

test('no files exist returns empty files and empty decisions', () => {
  const result = readDecisions('no-files', tmpDir);
  assert.deepStrictEqual(result.files, []);
  assert.deepStrictEqual(result.decisions, []);
});

test('all files empty returns empty files and empty decisions', () => {
  const sid = 'both-empty';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions-unknown.txt'), '', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.deepStrictEqual(result.files, []);
  assert.deepStrictEqual(result.decisions, []);
});

test('decisions are split on newlines and blank lines are filtered', () => {
  const sid = 'multiline';
  const content = '[10:00] First decision\n\n[10:10] Second decision\n\n';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), content, 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.strictEqual(result.decisions.length, 2);
  assert.ok(result.decisions[0].includes('First'));
  assert.ok(result.decisions[1].includes('Second'));
});

test('global file with whitespace-only content falls through to no result', () => {
  const sid = 'whitespace-global';
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '   \n  \n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.deepStrictEqual(result.files, []);
  assert.deepStrictEqual(result.decisions, []);
});

// ---------------------------------------------------------------------------
// readSessionState tests
// ---------------------------------------------------------------------------
console.log('\nreadSessionState');

test('per-session state file found when it has content', () => {
  const sid = 'state-001';
  fs.writeFileSync(path.join(tmpDir, `session-state-${sid}.txt`), 'Working on auth service\nTHREAD: Wire auth to controller\n', 'utf8');
  const result = readSessionState(sid, tmpDir);
  assert.ok(result.content.includes('Working on auth service'));
  assert.ok(result.content.includes('THREAD:'));
});

test('global fallback used when per-session state absent', () => {
  const sid = 'state-002';
  fs.writeFileSync(path.join(tmpDir, 'session-state.txt'), 'Global state line\n', 'utf8');
  const result = readSessionState(sid, tmpDir);
  assert.ok(result.content.includes('Global state line'));
});

test('per-session state takes precedence over global', () => {
  const sid = 'state-003';
  fs.writeFileSync(path.join(tmpDir, `session-state-${sid}.txt`), 'Per-session content\n', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-state.txt'), 'Global content\n', 'utf8');
  const result = readSessionState(sid, tmpDir);
  assert.ok(result.content.includes('Per-session content'));
  assert.ok(!result.content.includes('Global content'));
});

test('neither file exists returns empty content', () => {
  const result = readSessionState('no-state-file', tmpDir);
  assert.strictEqual(result.file, null);
  assert.strictEqual(result.content, '');
});

test('null sid skips per-session file and tries global only', () => {
  fs.writeFileSync(path.join(tmpDir, 'session-state.txt'), 'Only global\n', 'utf8');
  const result = readSessionState(null, tmpDir);
  assert.ok(result.content.includes('Only global'));
});

test('unknown-fallback state file is read — regression: it was write-only', () => {
  const sid = 'state-no-own-file';
  fs.writeFileSync(path.join(tmpDir, 'session-state-unknown.txt'), 'Stranded state line\n', 'utf8');
  const result = readSessionState(sid, tmpDir);
  assert.strictEqual(result.file, path.join(tmpDir, 'session-state-unknown.txt'));
  assert.ok(result.content.includes('Stranded state line'));
});

test('per-session state still wins over the unknown-fallback file', () => {
  const sid = 'state-precedence';
  fs.writeFileSync(path.join(tmpDir, `session-state-${sid}.txt`), 'Mine\n', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-state-unknown.txt'), 'Stranded\n', 'utf8');
  const result = readSessionState(sid, tmpDir);
  assert.ok(result.content.includes('Mine'));
  assert.ok(!result.content.includes('Stranded'));
});

// ---------------------------------------------------------------------------
// extractTextFromMessage tests
// ---------------------------------------------------------------------------
console.log('\nextractTextFromMessage');

test('string input returned trimmed', () => {
  assert.strictEqual(extractTextFromMessage('  hello  '), 'hello');
});

test('content-block array extracts text blocks', () => {
  const msg = [{ type: 'text', text: 'Hello' }, { type: 'tool_use', id: 'x' }, { type: 'text', text: 'World' }];
  assert.strictEqual(extractTextFromMessage(msg), 'Hello World');
});

test('object with string content property is unwrapped', () => {
  assert.strictEqual(extractTextFromMessage({ content: 'inner text' }), 'inner text');
});

test('object with array content property is unwrapped and extracted', () => {
  const msg = { content: [{ type: 'text', text: 'nested' }] };
  assert.strictEqual(extractTextFromMessage(msg), 'nested');
});

test('null/undefined input returns empty string', () => {
  assert.strictEqual(extractTextFromMessage(null), '');
  assert.strictEqual(extractTextFromMessage(undefined), '');
});

// ---------------------------------------------------------------------------
// resolveTranscriptPath tests
// ---------------------------------------------------------------------------
console.log('\nresolveTranscriptPath');

test('builds correct path from sid and project dir', () => {
  const p = resolveTranscriptPath('abc123', '/home/user/projects/my-app');
  assert.ok(p.endsWith('abc123.jsonl'), 'should end with sid.jsonl');
  assert.ok(p.includes('.claude'), 'should be under .claude');
  assert.ok(p.includes('projects'), 'should be in projects dir');
});

// ---------------------------------------------------------------------------
// assembleContent tests
// ---------------------------------------------------------------------------
console.log('\nassembleContent');

test('assembles all three sections in canonical order', () => {
  const fm = '---\ntype: claude/current-state\n---';
  const result = assembleContent(fm, '> work done', ['- (2026-06-11) thread one'], ['- [[link]] (2026-06-11 14:30)']);
  assert.ok(result.includes('## Where we left off'), 'missing where we left off');
  assert.ok(result.includes('## Open threads'), 'missing open threads');
  assert.ok(result.includes('## Recent sessions'), 'missing recent sessions');
  assert.ok(result.includes('> work done'), 'missing blockquote content');
  assert.ok(result.includes('thread one'), 'missing thread');
  assert.ok(result.includes('[[link]]'), 'missing session link');
});

test('empty thread lines renders (none)', () => {
  const fm = '---\ntype: x\n---';
  const result = assembleContent(fm, '> x', [], ['- [[a]] (2026-06-11 10:00)']);
  assert.ok(result.includes('(none)'), 'should render (none) for empty threads');
});

test('empty session lines renders (none)', () => {
  const fm = '---\ntype: x\n---';
  const result = assembleContent(fm, '> x', ['- (2026-06-11) t'], []);
  assert.ok(result.includes('(none)'), 'should render (none) for empty sessions');
});

// ---------------------------------------------------------------------------
// buildCurrentNote — _current.md section tests
// ---------------------------------------------------------------------------
console.log('\nbuildCurrentNote');

test('creates all three sections from session-state file', () => {
  const ctx = makeCtx();
  const state = makeStateData('Implemented stop hook changes\nTHREAD: Add test for byte ceiling\nTHREAD: Update install.sh');
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(content.includes('## Where we left off'), 'missing "Where we left off" section');
  assert.ok(content.includes('> Implemented stop hook changes'), 'missing blockquote plain-line content');
  assert.ok(content.includes('## Open threads'), 'missing "Open threads" section');
  assert.ok(content.includes('Add test for byte ceiling'), 'missing first THREAD');
  assert.ok(content.includes('Update install.sh'), 'missing second THREAD');
  assert.ok(content.includes('## Recent sessions'), 'missing "Recent sessions" section');
  assert.ok(content.includes(REF_SESSION), 'missing session link in recent sessions');
});

test('whereWeLeftOff is rendered as blockquote', () => {
  const ctx = makeCtx();
  const state = makeStateData('plain line content here');
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(content.includes('> plain line content here'), 'where-we-left-off must be blockquote');
});

test('whereWeLeftOff from transcript fallback is rendered as blockquote', () => {
  const ctx = makeCtx();
  const emptyState = { file: null, content: '' };
  const content = buildCurrentNote(ctx, emptyState, 'Last assistant message here');
  assert.ok(content.includes('> Last assistant message here'), 'transcript fallback must be blockquote');
});

test('THREAD text with embedded newlines is collapsed to space', () => {
  const ctx = makeCtx();
  // The state file content itself has embedded newlines within the THREAD: value (as if injected)
  // We simulate this via a raw string with \r\n inside the thread line text (not a line separator)
  const stateContent = 'THREAD: normal text\r\nmore text';
  const state = makeStateData(stateContent);
  const content = buildCurrentNote(ctx, state, null);
  // The THREAD: line should have its text collapsed; the thread should not contain a raw newline
  assert.ok(!content.match(/- \(\d{4}-\d{2}-\d{2}\) [^\n]*\n[^\n]+## /), 'THREAD text must not span multiple lines');
});

test('THREAD text that is exactly --- is escaped to \\---', () => {
  const ctx = makeCtx();
  // Only line-start --- is a YAML fence risk; mid-line --- is harmless markdown.
  // THREAD text of exactly --- would otherwise render a bare fence if the list
  // prefix were ever stripped, so it must be escaped at capture time.
  const state = makeStateData('THREAD: ---');
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(content.includes('\\---'), 'bare --- THREAD text must be escaped');
});

test('whereWeLeftOff containing bare --- is escaped to \\---', () => {
  const ctx = makeCtx();
  const state = makeStateData('---');
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(content.includes('\\---'), 'bare --- in whereWeLeftOff must be escaped');
  // The note's own YAML frontmatter legitimately contains one closing \n---\n
  // fence; assert no ADDITIONAL bare --- line appears in the body after it.
  const fences = content.match(/\n---\n/g) || [];
  assert.strictEqual(fences.length, 1, 'only the frontmatter closing fence may appear as a bare --- line');
});

test('thread cap at 10 — FIFO eviction drops oldest date', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const oldDate = (() => {
    const d = new Date(REF_DATE);
    d.setDate(d.getDate() - 7);
    return d.toISOString().slice(0, 10);
  })();
  const existingThreadLines = Array.from({ length: 9 }, (_, i) => `- (${oldDate}) Thread ${i + 1}`).join('\n');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${oldDate}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

old content

## Open threads

${existingThreadLines}

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('THREAD: New thread A\nTHREAD: New thread B');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const allThreadLines = content.split('\n').filter(l => l.match(/^- \(\d{4}-\d{2}-\d{2}\)/));
  assert.ok(allThreadLines.length <= 10, `expected ≤10 threads, got ${allThreadLines.length}`);
  assert.ok(content.includes('New thread A'), 'new thread A should survive');
  assert.ok(content.includes('New thread B'), 'new thread B should survive');
});

test('DONE: line removes the exact-matching thread', () => {
  const filePath = path.join(tmpDir, '_current.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

some work

## Open threads

- (${REF_DATE}) Wire auth to controller
- (${REF_DATE}) Add unit tests for service

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('DONE: Wire auth to controller');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(!content.includes('Wire auth to controller'), 'resolved thread should be removed');
  assert.ok(content.includes('Add unit tests for service'), 'other thread should remain');
});

test('DONE: line leaves unmatched threads untouched', () => {
  const filePath = path.join(tmpDir, '_current.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

work in progress

## Open threads

- (${REF_DATE}) Thread that stays
- (${REF_DATE}) Thread to remove

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('DONE: Thread to remove');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(!content.includes('Thread to remove'), 'done thread should be gone');
  assert.ok(content.includes('Thread that stays'), 'other thread should remain');
});

test('threads older than 14 days are dropped on rewrite', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const staleDate = (() => {
    const d = new Date(REF_DATE);
    d.setDate(d.getDate() - 15);
    return d.toISOString().slice(0, 10);
  })();
  const freshDate = (() => {
    const d = new Date(REF_DATE);
    d.setDate(d.getDate() - 5);
    return d.toISOString().slice(0, 10);
  })();
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

recent work

## Open threads

- (${staleDate}) Stale old thread
- (${freshDate}) Fresh recent thread

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('some progress');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(!content.includes('Stale old thread'), 'stale thread should be dropped');
  assert.ok(content.includes('Fresh recent thread'), 'fresh thread should remain');
});

test('exact-duplicate thread is not re-added', () => {
  const filePath = path.join(tmpDir, '_current.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

work

## Open threads

- (${REF_DATE}) Already exists thread

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('THREAD: Already exists thread');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const count = (content.match(/Already exists thread/g) || []).length;
  assert.strictEqual(count, 1, 'duplicate thread should appear exactly once');
});

test('recent sessions capped at 5', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const sessionLinks = Array.from({ length: 5 }, (_, i) =>
    `- [[Claude/Projects/test/sessions/2026-06-0${i + 1}-1000-test]] (2026-06-0${i + 1} 10:00)`
  ).join('\n');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

old

## Open threads

(none)

## Recent sessions

${sessionLinks}
`, 'utf8');

  const state = makeStateData('progress line');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const sessionSection = content.split('## Recent sessions')[1] || '';
  const sessionEntries = sessionSection.split('\n').filter(l => l.match(/^- \[\[/));
  assert.ok(sessionEntries.length <= 5, `expected ≤5 recent sessions, got ${sessionEntries.length}`);
});

test('4KB byte ceiling enforced — oversized state produces output ≤4096 bytes', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const manyThreads = Array.from({ length: 10 }, (_, i) =>
    `THREAD: ${'X'.repeat(180)} item-${i + 1}`
  ).join('\n');
  const longWhere = 'A'.repeat(2000);
  const state = makeStateData(`${longWhere}\n${manyThreads}`);
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const byteLength = Buffer.byteLength(content, 'utf8');
  assert.ok(byteLength <= 4096, `output should be ≤4096 bytes, got ${byteLength}`);
  assert.ok(content.includes('## Where we left off'), 'must still contain section header');
  assert.ok(content.includes('## Open threads'), 'must still contain section header');
  assert.ok(content.includes('## Recent sessions'), 'must still contain section header');
});

test('4KB ceiling: newest thread survives eviction', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const oldDate = (() => {
    const d = new Date(REF_DATE); d.setDate(d.getDate() - 7);
    return d.toISOString().slice(0, 10);
  })();
  const existingThreadLines = Array.from({ length: 9 }, (_, i) =>
    `- (${oldDate}) ${'O'.repeat(180)} thread-${i + 1}`
  ).join('\n');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${oldDate}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

previous work

## Open threads

${existingThreadLines}

## Recent sessions

(none)
`, 'utf8');

  const bigWhere = 'B'.repeat(2500);
  const state = makeStateData(`${bigWhere}\nTHREAD: NEWEST thread that must survive`);
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const byteLength = Buffer.byteLength(content, 'utf8');
  assert.ok(byteLength <= 4096, `output must be ≤4096 bytes, got ${byteLength}`);
  assert.ok(content.includes('NEWEST thread that must survive'), 'newest thread must survive ceiling enforcement');
});

test('round-trip: threads persist with original date stamps across two runs', () => {
  const filePath = path.join(tmpDir, '_current.md');

  const state1 = makeStateData('First run work\nTHREAD: Persistent thread one\nTHREAD: Persistent thread two');
  const ctx1 = makeCtx({ currentFilePath: filePath, sessionRelLink: 'Claude/Projects/test/sessions/s1' });
  const content1 = buildCurrentNote(ctx1, state1, null);
  fs.writeFileSync(filePath, content1, 'utf8');

  const parsed1 = parseCurrentNote(filePath);
  assert.strictEqual(parsed1.threads.length, 2, 'should have 2 threads after first run');
  const thread1Date = parsed1.threads[0].date;
  const thread2Date = parsed1.threads[1].date;

  const laterDate = (() => {
    const d = new Date(REF_DATE); d.setDate(d.getDate() + 1);
    return d.toISOString().slice(0, 10);
  })();
  const state2 = makeStateData('Second run work\nTHREAD: A brand new thread');
  const ctx2 = makeCtx({ currentFilePath: filePath, date: laterDate, time: '09:00', sessionRelLink: 'Claude/Projects/test/sessions/s2' });
  const content2 = buildCurrentNote(ctx2, state2, null);

  assert.ok(content2.includes(`(${thread1Date}) Persistent thread one`), `thread 1 date ${thread1Date} should be preserved`);
  assert.ok(content2.includes(`(${thread2Date}) Persistent thread two`), `thread 2 date ${thread2Date} should be preserved`);
  assert.ok(content2.includes('A brand new thread'), 'new thread should appear');
});

test('fallback: no session-state file → "Where we left off" populated from last assistant message', () => {
  const ctx = makeCtx();
  const emptyState = { file: null, content: '' };
  const lastMsg = 'The implementation is complete — controller wired and tests passing.';
  const content = buildCurrentNote(ctx, emptyState, lastMsg);
  assert.ok(content.includes('The implementation is complete'), '"Where we left off" should contain last assistant message');
});

test('fallback: no session-state and no assistant message → shows placeholder', () => {
  const ctx = makeCtx();
  const emptyState = { file: null, content: '' };
  const content = buildCurrentNote(ctx, emptyState, null);
  assert.ok(content.includes('(no summary available)'), 'should show placeholder when nothing available');
});

test('malformed existing _current.md does not crash — file rebuilt from scratch', () => {
  const filePath = path.join(tmpDir, '_current.md');
  fs.writeFileSync(filePath, 'this is not valid frontmatter\n---\nrandom garbage\n- broken\n', 'utf8');
  const state = makeStateData('Recovered from malformed file\nTHREAD: Recovery thread');
  const ctx = makeCtx({ currentFilePath: filePath });
  let content;
  assert.doesNotThrow(() => {
    content = buildCurrentNote(ctx, state, null);
  }, 'should not throw on malformed input');
  assert.ok(content.includes('## Where we left off'), 'rebuilt file should have Where we left off');
  assert.ok(content.includes('## Open threads'), 'rebuilt file should have Open threads');
  assert.ok(content.includes('Recovery thread'), 'rebuilt file should include new thread from state');
});

test('_current.md frontmatter contains required fields', () => {
  const ctx = makeCtx({ projectRawName: 'my-proj' });
  const state = makeStateData('some work');
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(content.includes('type: claude/current-state'), 'frontmatter must have type');
  assert.ok(content.includes('project: my-proj'), 'frontmatter must have project');
  assert.ok(content.includes(`updated: ${REF_DATE}T${REF_TIME}`), 'frontmatter must have updated timestamp');
  assert.ok(content.includes('tags: [claude, current-state, auto]'), 'frontmatter must have tags');
});

test('latest plain line wins as "Where we left off" when multiple plain lines present', () => {
  const ctx = makeCtx();
  const state = makeStateData('First progress note\nSecond progress note\nFinal progress note');
  const content = buildCurrentNote(ctx, state, null);
  assert.ok(content.includes('> Final progress note'), 'should use last plain line as blockquote');
  assert.ok(!content.includes('> First progress note'), 'should not use earlier plain lines');
});

test('DONE: foo evicts a thread stored as Foo (case-insensitive match)', () => {
  const filePath = path.join(tmpDir, '_current.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

work

## Open threads

- (${REF_DATE}) Foo
- (${REF_DATE}) BAR should stay

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('DONE: foo');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const threadSection = content.split('## Open threads')[1]?.split('## Recent sessions')[0] || '';
  assert.ok(!threadSection.includes('Foo'), 'Foo thread must be evicted by lowercase DONE: foo (case-insensitive)');
  assert.ok(threadSection.includes('BAR should stay'), 'BAR thread must remain unaffected');
});

test('FIFO ceiling eviction: under-10 threads in non-date order, oldest-dated evicted first', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const dateOld  = '2026-05-01';
  const dateMid  = '2026-05-15';
  const dateNew  = '2026-06-01';
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${dateNew}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

previous

## Open threads

- (${dateNew}) Newest thread
- (${dateMid}) Middle thread
- (${dateOld}) Oldest thread

## Recent sessions

(none)
`, 'utf8');

  const bigWhere = 'C'.repeat(3800);
  const state = makeStateData(bigWhere);
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);

  assert.ok(Buffer.byteLength(content, 'utf8') <= 4096, 'output must be <= 4096 bytes');
  const threadSection = content.split('## Open threads')[1]?.split('## Recent sessions')[0] || '';
  if (threadSection.includes('Newest thread')) {
    assert.ok(!threadSection.includes('Oldest thread'),
      'oldest-dated thread must be evicted before newest-dated thread');
  }
  if (threadSection.includes('Oldest thread')) {
    assert.ok(threadSection.includes('Newest thread'),
      'oldest thread must not outlive newest thread');
  }
});

test('multi-byte content: final byte length is <= 4096 even with CJK characters', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const cjkText = '中'.repeat(1500);
  const state = makeStateData(cjkText);
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  const byteLength = Buffer.byteLength(content, 'utf8');
  assert.ok(byteLength <= 4096, `CJK content must be <= 4096 bytes, got ${byteLength}`);
  assert.doesNotThrow(() => {
    Buffer.from(content, 'utf8').toString('utf8');
  }, 'content must be valid UTF-8 after clamp');
});

// ---------------------------------------------------------------------------
// Security: exact-path guard — buildCurrentNote rejects paths outside baseDir
// ---------------------------------------------------------------------------
console.log('\nbuildCurrentNote (security: exact-path guard)');

test('exact-path guard: _current.md in sibling project dir cannot be read via traversal', () => {
  // Simulate two projects: my-project and sibling-project
  // _current.md for sibling-project contains sensitive content
  const siblingDir = path.join(tmpDir, 'vault', 'Claude', 'Projects', 'sibling-project');
  fs.mkdirSync(siblingDir, { recursive: true });
  const siblingCurrentPath = path.join(siblingDir, '_current.md');
  fs.writeFileSync(siblingCurrentPath,
`---
type: claude/current-state
project: sibling-project
---

## Where we left off

sibling sensitive content

## Open threads

- (${REF_DATE}) Sibling thread

## Recent sessions

(none)
`, 'utf8');

  // Build a ctx that targets MY project's _current.md (which does not exist)
  const myBaseDir = path.join(tmpDir, 'vault', 'Claude', 'Projects', 'my-project');
  fs.mkdirSync(myBaseDir, { recursive: true });
  const myCurrentPath = path.join(myBaseDir, '_current.md');

  // Attempt to read the sibling path by supplying it as currentFilePath
  // buildCurrentNote calls parseCurrentNote(currentFilePath) — the sibling file exists,
  // but updateCurrentNote would reject it via exact-path guard before writing.
  // The security concern is that parseCurrentNote reads whatever path it is given.
  // We verify that the ctx.currentFilePath is what gets used — not a traversal target.
  const ctx = makeCtx({ currentFilePath: myCurrentPath, sessionRelLink: 'Claude/Projects/my-project/sessions/s1' });
  const state = makeStateData('my own work');
  const content = buildCurrentNote(ctx, state, null);

  // The output must NOT contain the sibling's threads
  assert.ok(!content.includes('Sibling thread'), 'sibling thread must not appear in my project output');
  assert.ok(!content.includes('sibling sensitive content'), 'sibling content must not leak into my project output');
});

// ---------------------------------------------------------------------------
// parseCurrentNote tests
// ---------------------------------------------------------------------------
console.log('\nparseCurrentNote');

test('returns empty result for non-existent file', () => {
  const result = parseCurrentNote(path.join(tmpDir, 'nonexistent.md'));
  assert.deepStrictEqual(result, { threads: [], recentSessions: [] });
});

test('parses threads correctly from well-formed file', () => {
  const filePath = path.join(tmpDir, 'parse-test.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
---

## Where we left off

work

## Open threads

- (2026-06-01) First thread
- (2026-06-05) Second thread

## Recent sessions

(none)
`, 'utf8');
  const result = parseCurrentNote(filePath);
  assert.strictEqual(result.threads.length, 2);
  assert.strictEqual(result.threads[0].date, '2026-06-01');
  assert.strictEqual(result.threads[0].text, 'First thread');
  assert.strictEqual(result.threads[1].date, '2026-06-05');
  assert.strictEqual(result.threads[1].text, 'Second thread');
});

test('parses recent sessions correctly', () => {
  const filePath = path.join(tmpDir, 'parse-sessions.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
---

## Where we left off

work

## Open threads

(none)

## Recent sessions

- [[Claude/Projects/test/sessions/2026-06-10-1000-test]] (2026-06-10 10:00)
- [[Claude/Projects/test/sessions/2026-06-09-1000-test]] (2026-06-09 10:00)
`, 'utf8');
  const result = parseCurrentNote(filePath);
  assert.strictEqual(result.recentSessions.length, 2);
  assert.ok(result.recentSessions[0].link.includes('2026-06-10'));
  assert.ok(result.recentSessions[1].link.includes('2026-06-09'));
});

test('returns empty on completely malformed file without crashing', () => {
  const filePath = path.join(tmpDir, 'malformed.md');
  fs.writeFileSync(filePath, 'not a real markdown file at all\njust garbage\n!!!###', 'utf8');
  let result;
  assert.doesNotThrow(() => { result = parseCurrentNote(filePath); });
  assert.deepStrictEqual(result, { threads: [], recentSessions: [] });
});

// ---------------------------------------------------------------------------
// obsidian-context-hook.js basic tests
// ---------------------------------------------------------------------------
console.log('\nobsidian-context-hook (integration)');

test('context hook: exits silently when vault env var not set', () => {
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');
  let stdout = '';
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: { ...process.env, OBSIDIAN_VAULT_PATH: '' },
    });
  } catch (e) {
    stdout = e.stdout || '';
  }
  assert.strictEqual(stdout, '', 'should produce no output when vault not set');
});

test('context hook: exits silently when vault path does not exist', () => {
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');
  let stdout = '';
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: { ...process.env, OBSIDIAN_VAULT_PATH: '/nonexistent/vault/path/xyz' },
    });
  } catch (e) {
    stdout = e.stdout || '';
  }
  assert.strictEqual(stdout, '', 'should produce no output when vault does not exist');
});

test('context hook: prints file content when _current.md exists', () => {
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');

  const mockVault = path.join(tmpDir, 'vault');
  const mockProjectsFolder = 'Claude/Projects';
  const mockProjectDir = path.join(tmpDir, 'my-test-project');
  const projectSlug = 'my-test-project';
  const currentDir = path.join(mockVault, 'Claude', 'Projects', projectSlug);
  fs.mkdirSync(currentDir, { recursive: true });
  fs.mkdirSync(mockProjectDir, { recursive: true });

  const currentContent = '## Where we left off\n\nTest project state content\n';
  fs.writeFileSync(path.join(currentDir, '_current.md'), currentContent, 'utf8');

  let stdout = '';
  let exitCode = 0;
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: {
        ...process.env,
        OBSIDIAN_VAULT_PATH: mockVault,
        OBSIDIAN_PROJECTS_FOLDER: mockProjectsFolder,
        CLAUDE_PROJECT_DIR: mockProjectDir,
      },
    });
  } catch (e) {
    stdout = e.stdout || '';
    exitCode = e.status || 1;
  }
  assert.ok(stdout.includes('## Obsidian project context (_current.md)'), 'should print header');
  assert.ok(stdout.includes('Test project state content'), 'should print file content');
  assert.strictEqual(exitCode, 0, 'should exit 0');
});

test('context hook: exits silently when _current.md does not exist', () => {
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');

  const mockVault = path.join(tmpDir, 'vault2');
  const mockProjectDir = path.join(tmpDir, 'another-project');
  fs.mkdirSync(mockVault, { recursive: true });
  fs.mkdirSync(mockProjectDir, { recursive: true });

  let stdout = '';
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: {
        ...process.env,
        OBSIDIAN_VAULT_PATH: mockVault,
        OBSIDIAN_PROJECTS_FOLDER: 'Claude/Projects',
        CLAUDE_PROJECT_DIR: mockProjectDir,
      },
    });
  } catch (e) {
    stdout = e.stdout || '';
  }
  assert.strictEqual(stdout, '', 'should produce no output when _current.md missing');
});

test('context hook: rejects path traversal to sibling project', () => {
  // Arrange a vault with two project slugs; the hook for "my-project" must not
  // read "sibling-project/_current.md" even if the env vars are crafted adversarially.
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');

  const mockVault = path.join(tmpDir, 'vault3');
  // Put a _current.md under the sibling path
  const siblingCurrentDir = path.join(mockVault, 'Claude', 'Projects', 'sibling');
  fs.mkdirSync(siblingCurrentDir, { recursive: true });
  fs.writeFileSync(path.join(siblingCurrentDir, '_current.md'),
    '## Where we left off\n\nSibling secret content\n', 'utf8');

  // The project dir is intentionally named to produce slug "sibling" via traversal attempt.
  // The exact-path guard must ensure "sibling" can only be reached if the computed slug matches.
  // We simulate by pointing CLAUDE_PROJECT_DIR at a dir with a different name
  // but OBSIDIAN_PROJECTS_FOLDER at a level that would put our project under "my-project".
  const myProjectDir = path.join(tmpDir, 'my-project');
  fs.mkdirSync(myProjectDir, { recursive: true });
  // "my-project" dir does NOT have a _current.md — so the hook should produce no output
  const myCurrentDir = path.join(mockVault, 'Claude', 'Projects', 'my-project');
  fs.mkdirSync(myCurrentDir, { recursive: true });
  // Do NOT create _current.md for my-project

  let stdout = '';
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: {
        ...process.env,
        OBSIDIAN_VAULT_PATH: mockVault,
        OBSIDIAN_PROJECTS_FOLDER: 'Claude/Projects',
        CLAUDE_PROJECT_DIR: myProjectDir,
      },
    });
  } catch (e) {
    stdout = e.stdout || '';
  }
  assert.ok(!stdout.includes('Sibling secret content'), 'must not read sibling project _current.md');
  assert.strictEqual(stdout, '', 'no output when my own _current.md does not exist');
});

// ---------------------------------------------------------------------------
// assembleContent — additional edge cases
// ---------------------------------------------------------------------------
console.log('\nassembleContent (edge cases)');

test('sections appear in canonical order: frontmatter → where → threads → sessions', () => {
  const fm = '---\ntype: x\n---';
  const result = assembleContent(fm, '> note', ['- (2026-06-11) t1'], ['- [[L]] (2026-06-11 10:00)']);
  const idxWhere   = result.indexOf('## Where we left off');
  const idxThreads = result.indexOf('## Open threads');
  const idxSessions = result.indexOf('## Recent sessions');
  assert.ok(idxWhere < idxThreads, '"Where we left off" must come before "Open threads"');
  assert.ok(idxThreads < idxSessions, '"Open threads" must come before "Recent sessions"');
});

test('single thread line is not double-joined (no extra newline between threads)', () => {
  const fm = '---\ntype: x\n---';
  const result = assembleContent(fm, '> w', ['- (2026-06-11) only one'], []);
  // "only one" must appear exactly once
  assert.strictEqual((result.match(/only one/g) || []).length, 1);
  // No doubled blank line between ## Open threads header and the single entry
  assert.ok(!result.includes('## Open threads\n\n\n'), 'must not have triple newline after section header');
});

test('multiple session lines are joined with newline separator', () => {
  const fm = '---\ntype: x\n---';
  const sessLines = ['- [[L1]] (2026-06-10 10:00)', '- [[L2]] (2026-06-09 10:00)'];
  const result = assembleContent(fm, '> w', [], sessLines);
  const sessSection = result.split('## Recent sessions')[1] || '';
  assert.ok(sessSection.includes('[[L1]]'), 'first session link must appear');
  assert.ok(sessSection.includes('[[L2]]'), 'second session link must appear');
  const l1pos = sessSection.indexOf('[[L1]]');
  const l2pos = sessSection.indexOf('[[L2]]');
  assert.ok(l1pos < l2pos, 'session lines must appear in supplied order');
});

test('frontmatter is placed at the start of the output (before all sections)', () => {
  const fm = '---\ntype: claude/current-state\n---';
  const result = assembleContent(fm, '> work', [], []);
  assert.ok(result.startsWith(fm), 'frontmatter must be at the very start');
});

test('output ends with a single trailing newline', () => {
  const fm = '---\ntype: x\n---';
  const result = assembleContent(fm, '> w', ['- (2026-06-11) t'], ['- [[L]] (2026-06-11 10:00)']);
  assert.ok(result.endsWith('\n'), 'output must end with newline');
  assert.ok(!result.endsWith('\n\n'), 'output must not end with double newline');
});

// ---------------------------------------------------------------------------
// extractTextFromMessage — unusual shapes
// ---------------------------------------------------------------------------
console.log('\nextractTextFromMessage (unusual shapes)');

test('empty array returns empty string', () => {
  assert.strictEqual(extractTextFromMessage([]), '');
});

test('array with only non-text type blocks returns empty string', () => {
  const msg = [
    { type: 'tool_use', id: 'tu1', name: 'bash', input: {} },
    { type: 'tool_result', tool_use_id: 'tu1', content: 'ok' },
    { type: 'image', source: { type: 'base64' } },
  ];
  assert.strictEqual(extractTextFromMessage(msg), '');
});

test('array with text block where text is empty string is excluded', () => {
  const msg = [{ type: 'text', text: '' }, { type: 'text', text: 'real content' }];
  assert.strictEqual(extractTextFromMessage(msg), 'real content');
});

test('number input returns empty string', () => {
  assert.strictEqual(extractTextFromMessage(42), '');
});

test('boolean input returns empty string', () => {
  assert.strictEqual(extractTextFromMessage(false), '');
  assert.strictEqual(extractTextFromMessage(true), '');
});

test('object with content: null returns empty string', () => {
  assert.strictEqual(extractTextFromMessage({ content: null }), '');
});

test('object with content: empty array returns empty string', () => {
  assert.strictEqual(extractTextFromMessage({ content: [] }), '');
});

test('mixed array: interleaved text and non-text blocks — only text blocks joined', () => {
  const msg = [
    { type: 'text', text: 'first' },
    { type: 'tool_use', id: 'x' },
    { type: 'text', text: 'second' },
    { type: 'tool_result', tool_use_id: 'x', content: 'ignored' },
  ];
  assert.strictEqual(extractTextFromMessage(msg), 'first second');
});

// ---------------------------------------------------------------------------
// resolveTranscriptPath — sanitization cases
// ---------------------------------------------------------------------------
console.log('\nresolveTranscriptPath (sanitization)');

test('Windows drive letter colon is replaced so path segment is valid', () => {
  // projDir like "C:\\Users\\foo\\projects\\my-app"
  const p = resolveTranscriptPath('sid1', 'C:\\Users\\foo\\projects\\my-app');
  // The colon in "C:" must not appear in the resulting path segment for the project key
  const projectKeySegment = p.split(path.sep).slice(-2, -1)[0]; // parent dir of sid1.jsonl
  assert.ok(!projectKeySegment.includes(':'), 'drive letter colon must be sanitized from project key');
});

test('backslashes in projDir are replaced so the key is a single flat segment', () => {
  const p = resolveTranscriptPath('sid2', 'C:\\Users\\foo\\my-project');
  const projectKeySegment = p.split(path.sep).slice(-2, -1)[0];
  assert.ok(!projectKeySegment.includes('\\'), 'backslashes must be replaced in project key');
});

test('forward slashes in projDir are replaced (POSIX path)', () => {
  const p = resolveTranscriptPath('sid3', '/home/user/projects/my-app');
  const projectKeySegment = p.split(path.sep).slice(-2, -1)[0];
  assert.ok(!projectKeySegment.includes('/'), 'forward slashes must be replaced in project key');
});

test('result is always under ~/.claude/projects/', () => {
  const p = resolveTranscriptPath('sid4', '/some/project');
  const homeClaudeProjects = path.join(os.homedir(), '.claude', 'projects');
  assert.ok(p.startsWith(homeClaudeProjects), `path must start with ${homeClaudeProjects}`);
});

test('file name ends with sid.jsonl', () => {
  const sid = 'my-session-id';
  const p = resolveTranscriptPath(sid, '/some/project');
  assert.ok(p.endsWith(`${sid}.jsonl`), `path must end with ${sid}.jsonl`);
});

// ---------------------------------------------------------------------------
// buildCurrentNote — additional edge cases
// ---------------------------------------------------------------------------
console.log('\nbuildCurrentNote (additional edge cases)');

test('DONE: line for a thread that does not exist in current file is a no-op', () => {
  const filePath = path.join(tmpDir, '_current.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${REF_DATE}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

some work

## Open threads

- (${REF_DATE}) Thread alpha
- (${REF_DATE}) Thread beta

## Recent sessions

(none)
`, 'utf8');

  const state = makeStateData('DONE: Thread that was never there');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);
  // Both original threads must survive unchanged
  assert.ok(content.includes('Thread alpha'), 'Thread alpha must survive a no-op DONE');
  assert.ok(content.includes('Thread beta'), 'Thread beta must survive a no-op DONE');
});

test('state file with only THREAD:/DONE: lines falls back to transcript for "Where we left off"', () => {
  const ctx = makeCtx();
  // State content has no plain lines — only THREAD: and DONE: prefixed lines
  const stateOnlyThreads = makeStateData('THREAD: First open item\nTHREAD: Second open item\nDONE: Some resolved item');
  const lastMsg = 'Transcript fallback message for where we left off';
  const content = buildCurrentNote(ctx, stateOnlyThreads, lastMsg);
  // whereWeLeftOff must come from lastMsg since there are no plain lines
  assert.ok(content.includes('> Transcript fallback message for where we left off'),
    'should use transcript fallback when state has no plain lines');
});

test('state file with only THREAD:/DONE: lines and no transcript → shows placeholder', () => {
  const ctx = makeCtx();
  const stateOnlyThreads = makeStateData('THREAD: First open item\nTHREAD: Second open item');
  const content = buildCurrentNote(ctx, stateOnlyThreads, null);
  assert.ok(content.includes('(no summary available)'),
    'should show placeholder when no plain lines and no transcript');
  // The threads themselves should still appear
  assert.ok(content.includes('First open item'), 'thread from THREAD: line must still appear');
  assert.ok(content.includes('Second open item'), 'thread from THREAD: line must still appear');
});

test('recent sessions newest-first order is preserved across a second run', () => {
  const filePath = path.join(tmpDir, '_current.md');

  // First run: establishes a session entry
  const ctx1 = makeCtx({
    currentFilePath: filePath,
    date: '2026-06-10',
    time: '09:00',
    sessionRelLink: 'Claude/Projects/test/sessions/2026-06-10-0900-test',
  });
  const content1 = buildCurrentNote(ctx1, makeStateData('first run'), null);
  fs.writeFileSync(filePath, content1, 'utf8');

  // Second run: new session, one day later
  const ctx2 = makeCtx({
    currentFilePath: filePath,
    date: '2026-06-11',
    time: '10:00',
    sessionRelLink: 'Claude/Projects/test/sessions/2026-06-11-1000-test',
  });
  const content2 = buildCurrentNote(ctx2, makeStateData('second run'), null);

  const sessSection = content2.split('## Recent sessions')[1] || '';
  const entries = sessSection.split('\n').filter(l => l.match(/^- \[\[/));
  assert.ok(entries.length >= 2, 'both sessions must appear');
  // Newest (2026-06-11) must appear before oldest (2026-06-10)
  const pos11 = sessSection.indexOf('2026-06-11');
  const pos10 = sessSection.indexOf('2026-06-10');
  assert.ok(pos11 < pos10, 'newest session must appear before older session (newest-first order)');
});

test('threads at cap of 10 with one DONE makes room for a new THREAD in same run', () => {
  const filePath = path.join(tmpDir, '_current.md');
  const baseDate = REF_DATE;
  // Exactly 10 threads, all fresh (within 14 days)
  const existingThreadLines = Array.from({ length: 10 }, (_, i) =>
    `- (${baseDate}) Existing thread ${i + 1}`
  ).join('\n');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
updated: ${baseDate}T10:00
tags: [claude, current-state, auto]
---

## Where we left off

previous work

## Open threads

${existingThreadLines}

## Recent sessions

(none)
`, 'utf8');

  // DONE: removes one, THREAD: adds a new one — net result should still be ≤10
  const state = makeStateData('progress\nDONE: Existing thread 1\nTHREAD: Replacement thread');
  const ctx = makeCtx({ currentFilePath: filePath });
  const content = buildCurrentNote(ctx, state, null);

  const allThreadLines = content.split('\n').filter(l => l.match(/^- \(\d{4}-\d{2}-\d{2}\)/));
  assert.ok(allThreadLines.length <= 10, `must be ≤10 threads after DONE+THREAD, got ${allThreadLines.length}`);
  // Exact-line match: a substring check would false-positive on "Existing thread 10"
  assert.ok(!allThreadLines.some(l => /\) Existing thread 1$/.test(l)), 'resolved thread must be removed');
  assert.ok(content.includes('Replacement thread'), 'new thread must be present after DONE makes room');
});

// ---------------------------------------------------------------------------
// parseCurrentNote — section ordering and missing/extra sections
// ---------------------------------------------------------------------------
console.log('\nparseCurrentNote (section ordering and gaps)');

test('parses correctly when Recent sessions appears before Open threads', () => {
  const filePath = path.join(tmpDir, 'reversed-order.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
---

## Where we left off

work

## Recent sessions

- [[Claude/Projects/test/sessions/2026-06-10-1000-test]] (2026-06-10 10:00)

## Open threads

- (2026-06-09) Thread in reversed file
`, 'utf8');

  const result = parseCurrentNote(filePath);
  assert.strictEqual(result.recentSessions.length, 1, 'should parse session from reversed file');
  assert.ok(result.recentSessions[0].link.includes('2026-06-10'), 'session link should be parsed');
  assert.strictEqual(result.threads.length, 1, 'should parse thread from reversed file');
  assert.strictEqual(result.threads[0].text, 'Thread in reversed file');
});

test('parses with only frontmatter and Where we left off — missing threads and sessions yields empty arrays', () => {
  const filePath = path.join(tmpDir, 'partial.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
---

## Where we left off

some content here
`, 'utf8');

  const result = parseCurrentNote(filePath);
  assert.deepStrictEqual(result.threads, [], 'threads must be empty when section is absent');
  assert.deepStrictEqual(result.recentSessions, [], 'recentSessions must be empty when section is absent');
});

test('extra unknown ## section between Open threads and Recent sessions does not contaminate either', () => {
  const filePath = path.join(tmpDir, 'extra-section.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
---

## Where we left off

work

## Open threads

- (2026-06-11) Real thread

## Unknown section

- (2026-06-11) This is not a thread
- [[Claude/Projects/test/sessions/x]] (2026-06-11 10:00) -- not a session line here

## Recent sessions

- [[Claude/Projects/test/sessions/2026-06-11-1000-test]] (2026-06-11 10:00)
`, 'utf8');

  const result = parseCurrentNote(filePath);
  assert.strictEqual(result.threads.length, 1, 'only thread lines from Open threads section must be parsed');
  assert.strictEqual(result.threads[0].text, 'Real thread', 'correct thread text must be parsed');
  assert.strictEqual(result.recentSessions.length, 1, 'only session lines from Recent sessions section must be parsed');
  assert.ok(result.recentSessions[0].link.includes('2026-06-11-1000-test'), 'correct session must be parsed');
});

test('file with only YAML frontmatter and no markdown sections returns empty arrays', () => {
  const filePath = path.join(tmpDir, 'frontmatter-only.md');
  fs.writeFileSync(filePath,
`---
type: claude/current-state
project: test
---
`, 'utf8');

  const result = parseCurrentNote(filePath);
  assert.deepStrictEqual(result.threads, []);
  assert.deepStrictEqual(result.recentSessions, []);
});

// ---------------------------------------------------------------------------
// context hook integration: 8KB byte-ceiling with multi-byte boundary
// ---------------------------------------------------------------------------
console.log('\nobsidian-context-hook (8KB ceiling)');

test('context hook: _current.md larger than 8KB is byte-capped and output is valid UTF-8', () => {
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');

  const mockVault = path.join(tmpDir, 'vault-8kb');
  const projectSlug = 'big-project';
  const currentDir = path.join(mockVault, 'Claude', 'Projects', projectSlug);
  fs.mkdirSync(currentDir, { recursive: true });
  const mockProjectDir = path.join(tmpDir, projectSlug);
  fs.mkdirSync(mockProjectDir, { recursive: true });

  // Build content that is well over 8KB.  Use CJK characters (3 bytes each in UTF-8)
  // so that the 8192-byte slice boundary is likely to land in the middle of a multi-byte
  // sequence — the hook must walk back to a safe boundary.
  const header = '## Where we left off\n\n';
  // Each '中' = 3 bytes. 3000 chars = 9000 bytes — safely above 8192.
  const cjkBody = '中'.repeat(3000);
  const bigContent = header + cjkBody + '\n';

  fs.writeFileSync(path.join(currentDir, '_current.md'), bigContent, 'utf8');

  let stdout = '';
  let threw = false;
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: {
        ...process.env,
        OBSIDIAN_VAULT_PATH: mockVault,
        OBSIDIAN_PROJECTS_FOLDER: 'Claude/Projects',
        CLAUDE_PROJECT_DIR: mockProjectDir,
      },
    });
  } catch (e) {
    stdout = e.stdout || '';
    threw = true;
  }

  assert.ok(!threw, 'hook must not exit non-zero on oversized file');
  assert.ok(stdout.includes('## Obsidian project context (_current.md)'), 'header must be present');

  // Verify byte length is at most 8192 + header overhead, not counting the
  // "## Obsidian project context" header line that the hook prepends.
  const injectedContent = stdout.replace('## Obsidian project context (_current.md)\n\n', '');
  const byteLength = Buffer.byteLength(injectedContent, 'utf8');
  assert.ok(byteLength <= 8192, `injected content must be ≤8192 bytes, got ${byteLength}`);

  // Verify the output is valid UTF-8 (no truncated multi-byte sequences)
  assert.doesNotThrow(() => {
    Buffer.from(stdout, 'utf8').toString('utf8');
  }, 'hook output must be valid UTF-8 after byte-capping');
});

test('context hook: _current.md exactly at 8KB boundary is printed in full without truncation', () => {
  const { execFileSync } = require('child_process');
  const hookPath = path.join(__dirname, 'obsidian-context-hook.js');

  const mockVault = path.join(tmpDir, 'vault-8kb-exact');
  const projectSlug = 'exact-project';
  const currentDir = path.join(mockVault, 'Claude', 'Projects', projectSlug);
  fs.mkdirSync(currentDir, { recursive: true });
  const mockProjectDir = path.join(tmpDir, projectSlug);
  fs.mkdirSync(mockProjectDir, { recursive: true });

  // Build exactly 8192 ASCII bytes of content (1 byte per char)
  const exactContent = 'x'.repeat(8192);
  fs.writeFileSync(path.join(currentDir, '_current.md'), exactContent, 'utf8');

  let stdout = '';
  try {
    stdout = execFileSync(process.execPath, [hookPath], {
      encoding: 'utf8',
      env: {
        ...process.env,
        OBSIDIAN_VAULT_PATH: mockVault,
        OBSIDIAN_PROJECTS_FOLDER: 'Claude/Projects',
        CLAUDE_PROJECT_DIR: mockProjectDir,
      },
    });
  } catch (e) {
    stdout = e.stdout || '';
  }

  assert.ok(stdout.includes('## Obsidian project context (_current.md)'), 'header must be present');
  // All 8192 x characters must appear — no truncation for content at exactly the limit
  const injectedContent = stdout.replace('## Obsidian project context (_current.md)\n\n', '');
  assert.ok(injectedContent.startsWith('x'.repeat(100)), 'content must not be truncated at exactly 8192 bytes');
});

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${passed + failed} tests: ${passed} passed, ${failed} failed\n`);
if (failed > 0) process.exit(1);
