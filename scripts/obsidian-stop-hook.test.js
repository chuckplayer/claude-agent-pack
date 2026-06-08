'use strict';
/**
 * Tests for pure logic extracted from obsidian-stop-hook.js.
 *
 * Run with:  node scripts/obsidian-stop-hook.test.js
 *
 * No npm dependencies. Uses only Node stdlib: assert, fs, os, path.
 *
 * The functions under test are inlined here verbatim from the hook source so
 * that the hook script itself requires no structural changes.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

// ---------------------------------------------------------------------------
// Inline: inferTags  (lines 113-138 of obsidian-stop-hook.js)
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Inline: readJournal  (lines 152-167 of obsidian-stop-hook.js)
// The only dependency is fs.readFileSync; we point it at temp files in tests.
// ---------------------------------------------------------------------------
function readJournal(sid, overrideJournalDir) {
  if (!sid) return { prompts: [], agents: [] };
  const journalDir = overrideJournalDir || path.join(os.homedir(), '.claude', 'session-journals');
  const journalPath = path.join(journalDir, `${sid}.jsonl`);
  try {
    const lines = fs.readFileSync(journalPath, 'utf8').trim().split('\n').filter(Boolean);
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

// ---------------------------------------------------------------------------
// Inline: readDecisions  (lines 170-180 of obsidian-stop-hook.js)
// Accepts an optional overrideDir so tests can write to a temp directory.
// ---------------------------------------------------------------------------
function readDecisions(sid, overrideDir) {
  const base = overrideDir || path.join(os.homedir(), '.claude');
  const perSession = path.join(base, `session-decisions-${sid}.txt`);
  const global_ = path.join(base, 'session-decisions.txt');
  for (const f of [perSession, global_]) {
    try {
      const text = fs.readFileSync(f, 'utf8').trim();
      if (text) return { file: f, decisions: text.split('\n').filter(Boolean) };
    } catch {}
  }
  return { file: null, decisions: [] };
}

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
// inferTags tests
// ---------------------------------------------------------------------------
console.log('\ninferTags');

test('always includes the four base tags', () => {
  const tags = inferTags('my-project', '/some/dir', '');
  assert.ok(tags.includes('claude'));
  assert.ok(tags.includes('session-log'));
  assert.ok(tags.includes('auto'));
  assert.ok(tags.includes('project/my-project'));
});

test('project slug is embedded in the project tag', () => {
  const tags = inferTags('order-api', '/some/dir', '');
  assert.ok(tags.includes('project/order-api'));
  assert.ok(!tags.includes('project/my-project'));
});

test('null changedFilesText returns only base tags', () => {
  const tags = inferTags('slug', '/dir', null);
  assert.strictEqual(tags.length, 4);
});

test('empty changedFilesText returns only base tags', () => {
  const tags = inferTags('slug', '/dir', '');
  assert.strictEqual(tags.length, 4);
});

test('detects .ts extension -> tech/typescript', () => {
  const tags = inferTags('slug', '/dir', 'src/service.ts | 5 ++++');
  assert.ok(tags.includes('tech/typescript'));
});

test('detects .cs extension -> tech/csharp', () => {
  const tags = inferTags('slug', '/dir', 'OrderService.cs | 10 ++');
  assert.ok(tags.includes('tech/csharp'));
});

test('detects .vue extension -> tech/vue', () => {
  const tags = inferTags('slug', '/dir', 'components/MyComponent.vue | 3 -');
  assert.ok(tags.includes('tech/vue'));
});

test('detects .sql extension -> tech/sql', () => {
  const tags = inferTags('slug', '/dir', 'migrations/001_create.sql | 20 ++');
  assert.ok(tags.includes('tech/sql'));
});

test('detects .ps1 extension -> tech/powershell', () => {
  const tags = inferTags('slug', '/dir', 'scripts/deploy.ps1 | 2 +');
  assert.ok(tags.includes('tech/powershell'));
});

test('detects .sh extension -> tech/shell', () => {
  const tags = inferTags('slug', '/dir', 'install.sh | 5 +');
  assert.ok(tags.includes('tech/shell'));
});

test('detects .json extension -> tech/config', () => {
  const tags = inferTags('slug', '/dir', 'appsettings.json | 1 +');
  assert.ok(tags.includes('tech/config'));
});

test('detects .yaml extension -> tech/config', () => {
  const tags = inferTags('slug', '/dir', 'pipeline.yaml | 4 ++');
  assert.ok(tags.includes('tech/config'));
});

test('detects .yml extension -> tech/config', () => {
  const tags = inferTags('slug', '/dir', 'docker-compose.yml | 8 +++');
  assert.ok(tags.includes('tech/config'));
});

test('.yaml and .yml both present produces only one tech/config tag (no duplicate)', () => {
  const tags = inferTags('slug', '/dir', 'a.yaml b.yml');
  assert.strictEqual(tags.filter(t => t === 'tech/config').length, 1);
});

test('detects auth path -> domain/auth', () => {
  const tags = inferTags('slug', '/dir', 'src/auth/AuthService.cs');
  assert.ok(tags.includes('domain/auth'));
});

test('detects api path -> domain/api', () => {
  const tags = inferTags('slug', '/dir', 'src/api/OrdersController.cs');
  assert.ok(tags.includes('domain/api'));
});

test('detects component path -> domain/ui', () => {
  const tags = inferTags('slug', '/dir', 'src/components/OrderList.vue');
  assert.ok(tags.includes('domain/ui'));
});

test('detects view path -> domain/ui', () => {
  const tags = inferTags('slug', '/dir', 'src/views/OrderView.vue');
  assert.ok(tags.includes('domain/ui'));
});

test('detects database path -> domain/database', () => {
  const tags = inferTags('slug', '/dir', 'src/database/Repository.cs');
  assert.ok(tags.includes('domain/database'));
});

test('detects migration path -> domain/database', () => {
  const tags = inferTags('slug', '/dir', 'migrations/001_add_orders.sql');
  assert.ok(tags.includes('domain/database'));
});

test('detects schema path -> domain/database', () => {
  const tags = inferTags('slug', '/dir', 'db/schema.sql');
  assert.ok(tags.includes('domain/database'));
});

test('detects docker path -> domain/infra', () => {
  const tags = inferTags('slug', '/dir', 'docker-compose.yml');
  assert.ok(tags.includes('domain/infra'));
});

test('detects terraform path -> domain/infra', () => {
  const tags = inferTags('slug', '/dir', 'infra/main.tf');
  assert.ok(tags.includes('domain/infra'));
});

test('detects test path -> domain/test', () => {
  const tags = inferTags('slug', '/dir', 'OrderService.test.ts');
  assert.ok(tags.includes('domain/test'));
});

test('detects spec path -> domain/test', () => {
  const tags = inferTags('slug', '/dir', 'tests/OrderSpec.cs');
  assert.ok(tags.includes('domain/test'));
});

test('multiple extensions in one diff stat produce multiple tech tags', () => {
  const tags = inferTags('slug', '/dir', 'Service.cs | 5\nService.ts | 3\nView.vue | 2');
  assert.ok(tags.includes('tech/csharp'));
  assert.ok(tags.includes('tech/typescript'));
  assert.ok(tags.includes('tech/vue'));
});

test('multiple domains in one diff stat produce multiple domain tags', () => {
  const tags = inferTags('slug', '/dir', 'auth/Login.cs database/Repo.cs');
  assert.ok(tags.includes('domain/auth'));
  assert.ok(tags.includes('domain/database'));
});

test('base tags are never duplicated regardless of slug', () => {
  const tags = inferTags('claude', '/dir', 'auto session-log');
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
  assert.deepStrictEqual(result, { prompts: [], agents: [] });
});

test('null session id returns empty result', () => {
  const result = readJournal(null, tmpDir);
  assert.deepStrictEqual(result, { prompts: [], agents: [] });
});

test('non-existent journal file returns empty result', () => {
  const result = readJournal('does-not-exist', tmpDir);
  assert.deepStrictEqual(result, { prompts: [], agents: [] });
});

test('valid JSONL with prompt entries populates prompts array', () => {
  const sid = 'test-session-001';
  const line1 = JSON.stringify({ time: '09:15', type: 'prompt', text: 'Write a service' });
  const line2 = JSON.stringify({ time: '09:20', type: 'prompt', text: 'Add tests' });
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), `${line1}\n${line2}\n`, 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.prompts.length, 2);
  assert.strictEqual(result.prompts[0].text, 'Write a service');
  assert.strictEqual(result.prompts[1].text, 'Add tests');
  assert.deepStrictEqual(result.agents, []);
});

test('valid JSONL with agent entries populates agents array', () => {
  const sid = 'test-session-002';
  const line1 = JSON.stringify({ time: '09:30', type: 'agent', name: 'csharp-engineer' });
  const line2 = JSON.stringify({ time: '09:45', type: 'agent', name: 'code-reviewer' });
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), `${line1}\n${line2}\n`, 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.deepStrictEqual(result.prompts, []);
  assert.strictEqual(result.agents.length, 2);
  assert.strictEqual(result.agents[0].name, 'csharp-engineer');
  assert.strictEqual(result.agents[1].name, 'code-reviewer');
});

test('mixed prompt and agent entries are separated correctly', () => {
  const sid = 'test-session-003';
  const lines = [
    JSON.stringify({ time: '10:00', type: 'prompt', text: 'First prompt' }),
    JSON.stringify({ time: '10:05', type: 'agent', name: 'tech-lead' }),
    JSON.stringify({ time: '10:10', type: 'prompt', text: 'Second prompt' }),
    JSON.stringify({ time: '10:15', type: 'agent', name: 'frontend-engineer' }),
  ].join('\n');
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), lines + '\n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.prompts.length, 2);
  assert.strictEqual(result.agents.length, 2);
});

test('malformed JSON lines are skipped silently', () => {
  const sid = 'test-session-004';
  const content = [
    JSON.stringify({ time: '10:00', type: 'prompt', text: 'Valid entry' }),
    '{ this is not json at all',
    '{"type":"prompt","text": missing closing',
    JSON.stringify({ time: '10:05', type: 'agent', name: 'code-reviewer' }),
  ].join('\n');
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), content + '\n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.prompts.length, 1);
  assert.strictEqual(result.agents.length, 1);
});

test('entries with unknown type are neither prompt nor agent', () => {
  const sid = 'test-session-005';
  const content = [
    JSON.stringify({ time: '10:00', type: 'other', data: 'ignored' }),
    JSON.stringify({ time: '10:01', type: 'prompt', text: 'Real prompt' }),
  ].join('\n');
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), content + '\n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.strictEqual(result.prompts.length, 1);
  assert.strictEqual(result.agents.length, 0);
});

test('empty journal file returns empty result', () => {
  const sid = 'test-session-006';
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), '', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.deepStrictEqual(result, { prompts: [], agents: [] });
});

test('journal file containing only whitespace returns empty result', () => {
  const sid = 'test-session-007';
  fs.writeFileSync(path.join(tmpDir, `${sid}.jsonl`), '   \n\n  \n', 'utf8');

  const result = readJournal(sid, tmpDir);
  assert.deepStrictEqual(result, { prompts: [], agents: [] });
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
  assert.strictEqual(result.file, path.join(tmpDir, `session-decisions-${sid}.txt`));
  assert.strictEqual(result.decisions.length, 2);
  assert.ok(result.decisions[0].includes('repository pattern'));
  assert.ok(result.decisions[1].includes('Vue 3'));
});

test('global fallback used when per-session file is absent', () => {
  const sid = 'abc456';
  const decContent = '[11:00] Deploy to Azure — existing infrastructure\n';
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), decContent, 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.strictEqual(result.file, path.join(tmpDir, 'session-decisions.txt'));
  assert.strictEqual(result.decisions.length, 1);
});

test('global fallback used when per-session file is empty', () => {
  const sid = 'abc789';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '[12:00] Use EF Core — ORM already in stack\n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.strictEqual(result.file, path.join(tmpDir, 'session-decisions.txt'));
  assert.strictEqual(result.decisions.length, 1);
});

test('per-session file takes precedence over global file when both exist', () => {
  const sid = 'priority-test';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '[09:00] Session-specific decision\n', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '[09:30] Global decision\n', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.ok(result.decisions[0].includes('Session-specific'));
});

test('neither file exists returns null file and empty decisions', () => {
  const result = readDecisions('no-files', tmpDir);
  assert.strictEqual(result.file, null);
  assert.deepStrictEqual(result.decisions, []);
});

test('both files empty returns null file and empty decisions', () => {
  const sid = 'both-empty';
  fs.writeFileSync(path.join(tmpDir, `session-decisions-${sid}.txt`), '', 'utf8');
  fs.writeFileSync(path.join(tmpDir, 'session-decisions.txt'), '', 'utf8');

  const result = readDecisions(sid, tmpDir);
  assert.strictEqual(result.file, null);
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
  assert.strictEqual(result.file, null);
  assert.deepStrictEqual(result.decisions, []);
});

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${passed + failed} tests: ${passed} passed, ${failed} failed\n`);
if (failed > 0) process.exit(1);
