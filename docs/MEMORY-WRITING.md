# Memory File Format and Conventions

Agents that write to `memory/` must follow this spec. Read this before writing any memory file.

`scripts/lint-memory.sh` enforces the mechanical half of this document — the fence, the key names, and
the presence of the required keys. It checks **dialect conformance only**; it does not judge whether a
value is *true*, and it deliberately does not close the `type:` vocabulary (see below).

## Filename format

```
YYYY-MM-DD-{prefix}-brief-slug.md
```

The prefix is determined by the agent's subdirectory routing table (see each agent's own instructions for which prefix applies to which situation).

**Exception — singleton living documents:** A file that is continuously refreshed in place rather than written once uses a fixed, undated name. The only current instance is `memory/architecture/repo-map.md` (maintained by `/repo-map`), which carries two extra frontmatter fields, `last-updated:` and `verified-at-commit:`. Do not date these files — the date convention is for immutable point-in-time records.

## Subdirectory taxonomy

| Subdirectory | Purpose |
|---|---|
| `memory/decisions/` | Architectural and design decisions with rationale |
| `memory/architecture/` | Module boundaries, data flow, and integration patterns |
| `memory/context/` | Environmental constraints, platform quirks, tooling workarounds |
| `memory/known-issues/` | Bugs, limitations, and workarounds that remain unresolved |

## Frontmatter

**One dialect: fenced lowercase YAML.** A `---` fence on line 1, closed by a matching `---`. Keys are
lowercase and hyphenated. Nothing precedes the opening fence.

```yaml
---
date: YYYY-MM-DD
type: decision | finding | constraint | pattern | known-issue | context | platform quirk
status: active | superseded | archived | resolved
superseded-by: n/a
scope: global | [specific module or path]
overrides-convention: yes | no
related-to: n/a | [comma-separated filenames]
---
```

Those **seven keys are required in every `memory/**/*.md`**, in that order. Where a key has no value
to carry, `n/a` is the filler this corpus uses — write `n/a` rather than omitting the key or leaving
it blank.

Three earlier dialects were retired on 2026-09-02 and must not be reintroduced: bold
markdown-emphasised keys with no fence, bare lowercase keys with no fence, and a fenced block
nesting `type`/`status` under a `metadata:` map. If you are copying the shape of an older file from memory
rather than reading it, check the file.

### The key set is a minimum, not a closed schema

**Extra keys are permitted, and `lint-memory.sh` does not fail on one it does not recognise.** A
memory file records facts; a schema that rejected unlisted keys would force deleting facts to satisfy
a format, which is precisely backwards.

Four extras are in active use and are sanctioned by name:

| Extra key | Where it appears | Meaning |
|---|---|---|
| `discovered:` | any file recording something found rather than decided | the date the behaviour was observed |
| `resolved:` | a file whose `status:` is `resolved` | the date it stopped being true |
| `last-updated:` | files revised after first writing | the date of the most recent revision |
| `verified-at-commit:` | `memory/architecture/repo-map.md` | the git SHA the content was checked against |

`discovered:` is not merely tolerated — **`CLAUDE.md`'s Engineer write permission section requires
it** on files an engineer agent writes to `memory/known-issues/`.

Place extras after the seven required keys. If you add a genuinely new extra, add a row above so the
next writer knows it was deliberate.

### `description:` is optional

A one-line `description:` is allowed and six files carry one. It is **not required**, and no new file
needs one — the filename is the primary handle for triage, and `/memory-query` triages on the filename
first, consulting `description:` only where it happens to be present. Do not add a `description:` to
an existing file just to make the corpus uniform.

**There is no `name:` key.** It duplicated the filename and was removed on 2026-09-02.

### `type:` — required key, open vocabulary

`type:` **must be present**. Its **value vocabulary is deliberately not enforced**, by this document
or by `lint-memory.sh`. Seven values are in use:

`decision`, `finding`, `constraint`, `pattern`, `known-issue`, `context`, `platform quirk`

Prefer one of those seven. Narrowing the vocabulary would mean rewriting the `type:` of files that
already carry a different value, and **rewriting a recorded fact is not a formatting change** — so
closing this list is deferred to a later cut that can consider each file on its merits.

### `status:` — four accepted values

| Value | Meaning |
|---|---|
| `active` | current; agents must apply it |
| `superseded` | replaced by a newer file, named in `superseded-by:` |
| `archived` | no longer applies at all; history only — **skipped** by the read filter |
| `resolved` | the issue it records was fixed, but the file stays in the active read set — **not skipped** |

`superseded` and `archived` are different: superseded means a newer decision replaced this one and
that file must be cited; archived means the content no longer applies at all.

**`resolved` is deliberately absent from every skip filter in the pack, and that asymmetry is a
decision rather than an oversight.** The skip instructions — in `CLAUDE.md`, `docs/AGENT-GUIDE.md`,
`skills/memory-audit/SKILL.md` and `skills/memory-query/SKILL.md` — name `superseded` and `archived`
only. Do not "fix" the apparent inconsistency by adding `resolved` to them.

The reason is that `resolved` conflates two claims that come apart: *the bug is no longer live*
(true) and *the guidance is no longer live* (often false). A fixed bug's file routinely carries the
constraint that caused it and the pattern that prevents its return, and both outlive the fix.
`memory/known-issues/2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` is the
worked example: its bug is fixed, but it also documents that `set -euo pipefail` plus a bare `read`
at EOF aborts a script — a permanent constraint over every script in `scripts/` — and the
`prompt`/`ASSUME_DEFAULTS` pattern any new prompt must follow or the bug returns. Skipping it would
bury live guidance in a repo whose own `CLAUDE.md` records regressions of bugs already fixed once.

If a `resolved` file genuinely holds nothing but history, set it to `archived` instead. Reach for
`resolved` when the fix is worth recording *and* the surrounding constraint still binds.

`superseded-by:` is **presence-checked, not resolved.** It normally holds a filename, but prose is
acceptable when no single file supersedes the entry — two files legitimately read
`superseded-by: fixed in place 2026-07-30; see Revisit trigger` and
`superseded-by: wiki family removed 2026-05-16; replaced by /obsidian-brief`. No checker verifies that
the value names a real file, and none should: a checker that did would fail both of those.

### Values that need quoting

Values are plain YAML scalars. Wrap a value in single quotes (doubling any internal `'`) when it
contains `: `, contains ` #`, or begins with a YAML indicator character — a backtick, `-`, `*`, `[`,
`{`, `&`, `!`, `|`, `>`, `@`, `%`, `#`, or a quote. Two files in the corpus need this today. A value
that soft-wraps across lines must have its continuation lines indented, which folds them into one
scalar.

## General principles

- Write to multiple subdirectories when a single session produces findings of different types. Each file stands alone -- do not combine different types into one file.
- If the content deviates from CONVENTIONS.md for a specific scope, set `overrides-convention: yes` and document which convention is overridden and why it does not apply in this scope.

## Immutability protects facts, not syntax

A dated memory file is an immutable point-in-time record: **do not rewrite what it says.** That rule
governs its *content* — the observation, the date, the rationale, the `type:` and `status:` values.

**It does not freeze the file's syntax.** Migrating a file's frontmatter to this dialect, adding a
required key that was missing, or quoting a value so it parses are all format changes that leave every
recorded fact byte-for-byte intact, and they are allowed. The 2026-09-02 normalization changed all 52
files on exactly this basis and altered no fact in any of them.

The distinction matters in both directions. Changing `type: platform quirk` to `type: context` to
satisfy a tidier vocabulary would be a *content* edit dressed as a format one — which is why the
vocabulary above stays open. And re-editing a file merely because its wording now reads oddly is not
a format change either.

## Superseding a prior file

When a new decision supersedes an old one, update the old file's `status:` to `superseded` and populate its `superseded-by:` field in the same operation as writing the new file.

## Precedence rules

- Active files without `overrides-convention: yes` rank below CONVENTIONS.md and above agent defaults.
- Active files with `overrides-convention: yes` rank above CONVENTIONS.md, but only within their declared Scope.
- Narrower scope wins over broader scope when two files conflict.
- When two active files conflict at the same scope, flag the conflict -- do not pick one silently.
