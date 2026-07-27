# Design Brief: Obsidian CLI Transport + Durable Plan Spine

**Date:** 2026-07-27
**Status:** approved, not yet implemented
**Origin:** interview session comparing the pack against two external references — a "software factory" pipeline diagram and [simoncorry/foundry](https://github.com/simoncorry/foundry)

Two independent workstreams, documented together, built in order. They share no files.

---

## Goal

**Workstream 1 — Obsidian CLI transport.** Insert the official [Obsidian CLI](https://obsidian.md/cli)
into the vault-write chain, and eliminate the read-modify-write daily-note append that currently
risks clobbering hand-edits.

**Workstream 2 — Durable plan spine.** Give the pack a plan artifact that downstream stages act on
and can *fail against*. Today `tech-lead`'s plan lives in chat and dies there: nothing checks it
off, no acceptance criteria exist before code is written, and no stage can be blocked by it.

---

## Constraints

Each of these was verified during the interview, not assumed.

- **Agents are machine-level, not per-project.** `install.sh:6,14,17,25,33` copies `agents/` and
  `skills/` to `$HOME/.claude/`; one copy serves every project on the machine. Only
  `scripts/setup-project.sh:19-36` is per-project (it writes `CLAUDE.md`, `docs/CONVENTIONS.md`,
  `docs/MEMORY-WRITING.md`, and the four `memory/` subdirs). Both workstreams must therefore
  degrade cleanly in repos that never ran `setup-project.sh` — including repos with no `memory/`,
  no `docs/`, and possibly no git.
- **The Obsidian CLI always exits 0, even on error.** Probed on 2026-07-27: a bogus command, a
  missing file, and a path-traversal attempt each printed `Error: …` to stdout and returned exit 0.
  Exit-code-driven fallback is impossible. See
  `memory/known-issues/2026-07-27-obsidian-cli-exit-zero-on-error.md` (created by workstream 1).
- **The CLI requires the Obsidian desktop app to be running.** The filesystem rung is mandatory,
  not a courtesy.
- **`vault=` targets by name; the pack only knows `OBSIDIAN_VAULT_PATH` (a path).** Multi-vault
  users will write to the wrong vault unless the name is derived and passed explicitly.
- **CLI reads appear sandboxed to the vault** — `read path="../../../Windows/System32/drivers/etc/hosts"`
  was refused. Writes outside the vault were deliberately *not* tested, so the pack must keep
  validating vault-relative paths itself rather than delegating that safety.
- **The `Write` tool creates missing parent directories.** Probed three levels deep in a single
  call. Every agent holding `Write` already creates `memory/<subdir>/` implicitly on first write.
- **The 11-step `/implement` order does not change.** Agents gain duties against the plan file; no
  stages are added, split, reordered, or merged.
- **Reviewers stay read-only.** `code-reviewer`, `security-reviewer`, and `performance-reviewer`
  keep `Read, Grep, Glob`. Foundry has reviewer findings land as plan edits; the pack will not copy
  that, because granting `Write` to read-only agents trades a clean invariant for convenience. The
  lead session folds their findings into the plan instead.
- **Engineers never write the plan file.** They run under `isolation: "worktree"`; direct writes
  would conflict on the one file every stage depends on. They surface, the lead session writes —
  the same pattern as the 2026-07-27 `tech-lead`/`devils-advocate` Obsidian-sync fix (`cbf44ca`).
- **`/hotfix` and `/debug` keep their ceremony exemption.** No plan, no gate.

---

## Workstream 1: Obsidian CLI transport

### Scope: the append, not the creation

The CLI handles the **daily-note append only**. File creation stays on its current
REST-API-then-filesystem path, unchanged.

Rationale: the daily-note append (`agents/obsidian-writer.md:121-123`) is the pack's *only*
read-modify-write against the vault. It reads the whole daily note, adds a line, and writes the
entire file back — a data-loss window on a file the user also edits by hand. That is the actual
risk, and `append path= content=` closes it outright. It is also a single short line, so
`\n`-escaping is trivial.

File creation, by contrast, is already safe: its own path, write-once, no read-modify-write. Routing
it through the CLI would add content-escaping complexity (frontmatter `---` delimiters and `:`
separators inside a shell-quoted `content=` value) and a verification round-trip, to fix a problem
that does not exist.

### Transport chain

`OBSIDIAN_CLI_MODE` becomes a **preference ceiling with automatic downward degradation**, rather
than today's hard selector (`install.sh:308,312` currently sets only `rest-api` or `filesystem`).
Backwards compatible with every existing install.

| Operation | `rest-api` | `cli` *(new value)* | `filesystem` |
|---|---|---|---|
| Daily-note append | CLI → filesystem | CLI → filesystem | filesystem |
| Main file create | REST API → filesystem | filesystem | filesystem |

The REST API is not used for appends today and this brief does not add that; the append chain is
CLI-then-filesystem in both non-`filesystem` modes.

### The verification rule

Because exit codes carry no signal, define this once and reference it everywhere:

> A CLI call has succeeded only when **stdout does not begin with `Error:`** *and* **the effect is
> confirmed by reading the file back with the `Read` tool.** Anything unverified falls through to
> the next rung.

Read-back must use the `Read` tool, not `Bash`. On this machine Bash fails silently
(`memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`), and the CLI is invoked
*through* Bash — so a Bash-only verification would be a silent check of a silent channel. Verifying
through `Read` breaks that chain.

### Detection

`install.sh` probes platform-specific locations and records the result in a new `OBSIDIAN_CLI_PATH`:

- **Windows:** `Obsidian.com` alongside `Obsidian.exe` (confirmed present at
  `C:\Program Files\Obsidian\Obsidian.com`)
- **macOS:** `/usr/local/bin/obsidian`
- **Linux:** `~/.local/bin/obsidian`

An explicit path is required because the Windows binary is not on `PATH` and `command -v obsidian`
resolves ambiguously under Git Bash. `check-readiness.sh` reports detection status;
`uninstall.sh` removes the variable alongside the other `OBSIDIAN_*` keys.

### Preflight

A cheap read-only probe (`files total`) confirms the app is running before any write is attempted.
If it fails, skip straight to filesystem — do not attempt the append and then verify a failure.

### Path and vault handling

- Absolute paths convert to vault-relative for `path=`.
- The iron rule (`agents/obsidian-writer.md:54-59` — writes confined to `Claude/` and the effective
  projects folder) is validated on the **vault-relative** form, because `path=` bypasses filesystem
  path checks entirely.
- The vault name is derived from the basename of `OBSIDIAN_VAULT_PATH` and passed as `vault=` on
  every call. Never rely on the active vault.

### First cut — 6 files

1. `agents/obsidian-writer.md` — append step becomes CLI-first with verification and fallback
   (`tools:` already includes `Bash`, `Read`, `Write`; no frontmatter change needed)
2. `install.sh` — CLI detection, `OBSIDIAN_CLI_PATH`, accept `cli` as an `OBSIDIAN_CLI_MODE` value
3. `scripts/check-readiness.sh` — report CLI detection and mode
4. `uninstall.sh` — remove `OBSIDIAN_CLI_PATH`
5. `memory/known-issues/2026-07-27-obsidian-cli-exit-zero-on-error.md` — new
6. `README.md` — document `OBSIDIAN_CLI_PATH` and the revised `OBSIDIAN_CLI_MODE` semantics

### Deferred to a follow-on, not in the first cut

The CLI also replaces work the pack currently does by hand on the **read** side. Out of scope here
because the ask was the write chain, but worth recording:

- `/obsidian-search` — `search query= format=json` and `search:context` instead of glob-and-grep
- `wiki-linter` — `orphans`, `unresolved`, and `backlinks` natively instead of deriving them
  (conditional: a wiki vault is not necessarily an Obsidian vault). Foundry pays a Node script,
  `check-wiki-pointers.js`, for the same result.
- `property:set` / `property:read` — frontmatter edits without rewriting the file
- `daily:path` — respects the user's Daily Notes plugin config, though the pack deliberately uses
  its own per-project daily structure

---

## Workstream 2: durable plan spine

Adapted from Foundry's plan-file design, reconciled with the pack's `memory/` ethos.

### The artifact

`tech-lead` writes `docs/plans/<slug>.md` — kebab-case slug, frontmatter (`id`, `status: PROPOSED`,
`created`), then two halves split by a horizontal rule:

- **Narrative half (for the human).** What ships and what deliberately doesn't, the calls made on
  their behalf so they can veto, honest risks, out-of-scope. Ordered by what the human is most
  likely to want changed: user-facing shape first, data choices next, mechanical work last.
- **Working-memory half (for the agent).** Inputs, ordered build steps, and **acceptance bars
  concrete enough that a stranger could check them.**

Path comes from an optional key in the project's `docs/CONVENTIONS.md`, defaulting to
`docs/plans/`. That is the only per-project knob available, since agent files are machine-level.

### Stage duties

| Stage | Duty |
|---|---|
| `tech-lead` | Writes the plan, including the acceptance bars |
| `devils-advocate` | Pressure-tests the bars, editing the plan in place (already holds `Write`) |
| Engineers | Report departures from the plan in their handoff; the lead session writes them to a `## Deviations` section (deferred past the first cut) |
| `test-engineer` | Writes tests *against* the bars rather than inventing criteria |
| `merge-reviewer` | Verifies bars met, verifies durable findings recorded in `memory/`, flips `status: SHIPPED`, deletes the plan |

### Lifecycle

`PROPOSED` → `IN_PROGRESS` → `SHIPPED`, then deleted. Plans are scaffolding; `memory/` and git
history are the durable record.

The plan **is committed** when created, so the PR shows intended shape against implementation and a
teammate can review one against the other. merge-reviewer's final commit flips it to `SHIPPED` and
deletes it — net-zero in the PR's file list, preserved in commit history.

Deletion is gated on distillation: anything durable the run surfaced must be recorded in
`memory/decisions/` or `memory/known-issues/` first. Because `Write` creates parent directories, a
missing `memory/` is not an excuse to skip it. The gate cannot be "a memory file must exist" —
most tasks produce nothing durable, and that is a legitimate pass. It is the same judgment
merge-reviewer already applies to findings.

### First cut — 8 files

1. `agents/tech-lead.md` — write the plan file and the acceptance bars
2. `agents/merge-reviewer.md` — gate on bars, verify distillation, flip status, delete
3. `skills/plan/SKILL.md` — create the plan, pass it forward
4. `skills/implement/SKILL.md` — wire the plan through the pipeline
5. `scripts/setup-project.sh` — create `docs/plans/`
6. `docs/CONVENTIONS.template.md` — document the optional plan-path key
7. `docs/MEMORY-WRITING.md` — document lazy directory creation as intended behavior
8. `CLAUDE.md` — the plan-spine rules

Scoped to prove **write → read → fail** end-to-end before anything else hangs off the artifact.
Deviations logging, reviewer findings folded into the plan, and the `start-up`/`handoff` continuity
pair all wait for a later cut.

---

## Key decisions

- **CLI first, spine second.** The CLI work removes a live data-loss risk and is self-contained.
  The spine touches `tech-lead` and `merge-reviewer` and deserves undivided attention.
- **CLI for the append only.** Targets the actual risk; avoids escaping complexity for a
  problem that doesn't exist. See "Scope" above.
- **Bars written at plan time by tech-lead**, not by a new agent or a new stage — the plan stays
  self-contained, and tech-lead already holds both the context and the `Write` grant.
- **Distill-then-delete, not archive.** Keeps the `memory/` ethos without accumulating a `plans/`
  graveyard, and turns merge-reviewer's status flip into a real gate rather than bookkeeping.
- **Lazy directory creation, never eager.** An eager "ensure `memory/` exists" step would litter
  every repo on the machine with empty subdirectories. `setup-project.sh` keeps creating them
  eagerly with `.gitkeep`, because that is the explicit opt-in path.
- **Reviewers stay read-only** — deliberate divergence from Foundry.

---

## Known risks (accepted)

- **Silent CLI failure** is the dominant risk of workstream 1. If the verification rule is wrong,
  writes appear to succeed and land nowhere. Mitigated by the stdout-plus-read-back rule, verified
  through the `Read` tool rather than `Bash`.
- **Write-only artifact** is the dominant risk of workstream 2. The pack has produced this failure
  twice: the session-state file nothing reads back, and the unreachable Obsidian dispatch fixed in
  `cbf44ca`. Mitigated by scoping the first cut to prove enforcement over breadth.
- **Conditional gate.** `/implement` step 2 skips `tech-lead` for well-scoped single-file tasks, so
  many runs will have no plan at all. merge-reviewer's gate must read "if a plan exists, enforce
  it" — an unconditional gate would block every small change.
- **Weak bars.** A planner writing acceptance criteria may produce unfalsifiable ones, and
  `devils-advocate` — the only agent that would catch that — is itself conditional. Accepted for
  the first cut; the fix if it bites is a bars-specific check in merge-reviewer.
- **Multi-vault misrouting** if vault-name derivation is wrong. Mitigated by passing `vault=`
  explicitly on every call.
- **`docs/plans/` may collide** with an existing convention in a consuming repo. Mitigated by the
  overridable CONVENTIONS.md key.
- **Verification includes an install step.** Editing agents in this repo changes nothing until
  `install.sh` re-runs — `check-updates.sh` and `/system-check` exist because that drift is real.
  "Proven end-to-end" means edit → `install.sh` → run in a scratch project, not editing files here
  and reading them back.

---

## Reference notes

Ideas evaluated and **not** adopted, recorded so they are not re-litigated:

- **Reviewer findings as plan edits** (Foundry) — rejected; keeps read-only reviewers read-only.
- **Deleting plans outright** (Foundry) — rejected in favour of distill-then-delete.
- **A dedicated exam-sheet stage** (factory diagram step 3) — rejected; tech-lead already holds the
  context, and it avoids a new agent and a new pipeline step.
- **Self-graded proof artifacts** (`auto-loom-proof`, factory step 7) — rejected. An MP4 of the app
  passing its own exam proves nothing if the exam is wrong, while looking like proof. Foundry's
  `quiz` rider — testing the *human's* understanding of merged changes — is the honest version of
  the same instinct and is a candidate for a later cut.
- **Dynamic Workflows for the pipeline** — declined separately on 2026-07-27; see
  `memory/decisions/2026-07-27-decision-decline-dynamic-workflows-for-implement.md`.
