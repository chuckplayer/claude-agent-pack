# Agent Orchestration Rules

## Sub-Agent Routing

The tech-lead agent routes tasks based on each agent's `description` field --
that description is the routing contract. To make a custom agent routable,
write a clear, specific description that unambiguously states when it should
be invoked. The tech-lead will route to it automatically.

### Invoke devils-advocate BEFORE implementation when:
- The task introduces a pattern not already present in the codebase
- The change affects more than two architectural layers
- The decision is difficult or impossible to reverse
- A new technology, library, or integration is being added

### Invoke tech-lead BEFORE implementation when:
- The task is ambiguous or spans multiple concerns
- You are unsure which agents to invoke or in what order
- The work touches more than three files across different layers

### When both tech-lead and devils-advocate are warranted:
Run tech-lead first to decompose the task into a plan. Then run devils-advocate
to challenge that plan. Only after devils-advocate completes should api-designer
(if needed) and engineer agents be invoked.

### Invoke codex-reviewer AFTER devils-advocate when:
- The decision is architectural, irreversible, or spans multiple systems
- A cross-model second opinion adds value beyond internal pressure-testing
- The `codex` CLI is available and authenticated on the machine

Run codex-reviewer sequentially after devils-advocate (it benefits from having
devils-advocate's concerns as context). It is advisory only -- it never blocks
implementation.

### Invoke backlog-auditor AFTER a backlog tree exists:
- **backlog-auditor** is dispatched by `/backlog` after the tree is written, and by nothing else. It
  is the **independent audit of a decomposition, not a code reviewer** — it reads a
  feature/story/task tree, recomputes that tree's coverage from the spec of record, and reports
  disagreement without regenerating anything. It mirrors `tech-lead -> devils-advocate`: the skill
  that built the artifact cannot be the check on it.

  `/backlog` is outside the plan-spine gate for a **different reason** than the four exempt skills
  below, and the distinction is worth keeping straight: they invoke merge-reviewer and deliberately
  hand it no `plan_id`, whereas **`/backlog` never invokes merge-reviewer at all.** There is no gate
  in its path to exempt it from. It does read acceptance bars from plans handed to its own run, but
  reading bars to attach them to stories is not the same act as feeding a `plan_id` to a downstream
  gate. Do not add `/backlog` to the four-skill enumeration in the **Plan spine** section — that list
  is about skills that dispatch merge-reviewer without a plan, and `/backlog` is not one of them.

### Parallel dispatch (run simultaneously):
- Tasks with no shared files and no output dependencies
- Independent reviews of separate files or modules
- Example: csharp-engineer and frontend-engineer on separate layers

### Sequential dispatch (run in order):
- Any task where agent B depends on output from agent A
- Any two tasks that modify the same file
- Always: frontend-engineer -> ts-linter -> code-reviewer -> (if applicable) security-reviewer
- Always: mcp-engineer -> ts-linter -> code-reviewer -> (if applicable) security-reviewer
- Always: csharp-engineer -> code-reviewer -> (if applicable) security-reviewer

## Always invoke before implementation:
- **git-engineer** before any engineer agent when the task involves code
  changes and the working branch has not already been confirmed:
  - If on `main` or `master`: ask whether to pull latest and create a new branch
  - If on any other branch: confirm with the user that it is the correct branch
    for this work before proceeding
- **api-designer** before csharp-engineer or frontend-engineer when the task
  creates or significantly modifies API endpoints

## Always invoke after implementation:
- **ts-linter** immediately after frontend-engineer or mcp-engineer, before code-reviewer.
  Pass the list of modified `.ts` files. Block on FAIL -- route
  back to the originating engineer before proceeding.
  If both frontend-engineer and mcp-engineer ran in parallel, invoke ts-linter
  once after both complete, passing all modified `.ts` and `.vue` files together.
- **code-reviewer** after any output from csharp-engineer, frontend-engineer, or mcp-engineer
- **security-reviewer** when changes touch authentication, authorization,
  data access, PII handling, API endpoints, or configuration with secrets
- **performance-reviewer** when changes include database queries, API endpoints,
  loops over collections, or caching logic
- **smell-reviewer** after every code change that introduces or modifies classes,
  methods, or files. Skip for documentation-only, config-only, or SQL-migration-only
  changes with no application logic. The `/hotfix` and `/debug` fast paths
  intentionally skip smell-reviewer for speed -- that exemption is deliberate,
  not an oversight.
- Run security-reviewer, performance-reviewer, and smell-reviewer in parallel
  after code-reviewer completes -- they are independent of each other. Omit
  security-reviewer and performance-reviewer when their trigger conditions are
  not met; smell-reviewer always runs on code changes.
- **test-engineer** after any new public methods or API endpoints are created, or
  when existing methods are modified -- engineer agents must verify test coverage
  and assess test impact (which existing tests are affected) before handoff
- **merge-reviewer** as the final gate in the implement pipeline, after
  test-engineer completes. Verifies all required stages passed and commits
  to the feature branch if clean. Never merges to main.

## Engineer responsibilities (csharp-engineer, frontend-engineer, python-engineer, mcp-engineer, database-engineer, infrastructure-engineer)
Before handing off to code-reviewer, every engineer agent must:
1. **Verify unit test coverage** — identify which changed methods/functions lack
   adequate test coverage and flag gaps explicitly in the handoff summary.
2. **Run existing tests** — execute the existing test suite (or the relevant subset
   that covers the changed code) and confirm all tests pass. If any tests fail,
   fix them before handing off. Do not proceed to code-reviewer with failing tests.
3. **Report departures from the plan's stated calls.** When the dispatching prompt
   quotes design calls from a plan, end the handoff with a line reading
   `Departures from stated calls:` — list any call you did not follow and what you
   did instead, or write `none`. **An absent line is not a "no".** You cannot read the
   plan yourself (it is uncommitted and invisible inside your worktree), so the calls
   arrive in your prompt and your handoff is the only route back. A departure you
   leave unreported reaches merge-reviewer's Tier 3 as an unrecorded contradiction,
   which fails the run — the departure itself is usually fine, the silence is not.
4. **Do not skip these** even for small changes -- a one-line fix can break
   multiple tests or leave a coverage gap.

> This section is the durable home for these duties. `/implement` step 5 also states
> the departure requirement in its dispatch prompt, because an engineer dispatched by
> some other caller would otherwise never learn of it — the prose alone made the duty a
> property of one caller rather than of the engineer.

## Never invoke automatically:
- **codex-reviewer** on bug fixes, trivial changes, or when `codex` CLI is unavailable
- **devils-advocate** on small bug fixes or trivial changes
- **tech-lead** when the task is already well-defined and scoped
- **test-engineer** before implementation is complete, reviewed, and test impact assessed
- **git-engineer** when the task involves no file changes (read-only tasks,
  reviews, planning)
- **api-designer** for internal refactors that do not change the API surface
- **performance-reviewer** when no database queries, endpoints, or hot-path
  code is involved
- **smell-reviewer** for documentation-only, config-only, or SQL-migration-only
  changes with no application logic
- **merge-reviewer** before the full pipeline (engineer → code-reviewer →
  test-engineer) has completed
- **backlog-auditor** on code changes, as a review lens in any code pipeline, or before a backlog
  tree exists. It audits a decomposition, not an implementation — pulling it into a code review is a
  loose name match, not a routing decision

## Built-in agent disambiguation

Use the built-in `claude-code-guide` agent for Claude Code feature questions
(how /X works, hooks, MCP, API). Do not answer those inline -- that wastes
planning tokens.

If `branch-manager` or `typescript-engineer` appear in the agent list, they are
stale copies from an earlier pack version -- re-run `install.sh` to remove them.
Route to `git-engineer` and `frontend-engineer` instead.

## Plan spine

Complex work can carry a **durable plan file** that downstream stages act on and can fail against.
Without it, a plan lives in chat and dies there: nothing checks it off and no stage can be blocked
by it.

**The artifact.** `<plan_dir>/<plan-id>.md`, where `plan_dir` comes from the
`- **Plan directory:**` key in `docs/CONVENTIONS.md` and defaults to `docs/plans` (no trailing
slash — that exact string is the fallback value both the writer and the gate use). Frontmatter
carries `plan_id`, `branch`, `origin_skill`, and `created`. The body is a narrative half for the
human and a working-memory half for the agents, the latter holding `## Acceptance bars` — each bar
a list item with a stable `BAR-nnn` id and a required `Evidence:` line naming `tests`, `manual`, or
`files`.

**Who does what:**

- **tech-lead** writes the plan and its bars — but **only when the invoking skill instructs it**,
  never unconditionally. It applies a guard rejecting unsafe and placeholder plan-directory values,
  because its `Write` tool creates parent directories, so an unguarded config value could write
  outside the repo. **The guard table in `agents/tech-lead.md` is the single authority on what is
  rejected — do not restate the conditions here or anywhere else.** An enumeration copied into a
  second file goes stale the first time the table grows a row, and a stale list that reads as
  authoritative is worse than a pointer.
- **devils-advocate** pressure-tests the bars in the plan file, editing in place. It is the only
  check on bar quality; tech-lead both writes the bars and is measured by them.
- **Engineers never write the plan file.** They run under `isolation: "worktree"` and would
  conflict on the one file every stage depends on. They surface; the lead session writes.
- **test-engineer** maps evidence to every bar id and reports it in its handoff. This is the only
  point where a bar is connected to something real.
- **Engineers also report departures** from the plan's stated calls in their handoff. They cannot
  read the plan — it is uncommitted and invisible inside a worktree — so `/implement` step 5 pastes
  the relevant calls verbatim into their dispatch prompt and requires an explicit "none" when
  nothing diverged.
- **merge-reviewer** enforces the bars in gate 4a — an extension of the existing test-coverage
  gate, not a new gate. It does **not** flip a status field and does **not** delete the plan. It
  also enforces `## Deviations` in three tiers; `agents/merge-reviewer.md` is the single authority
  on what each tier checks, so do not restate them here.

**`## Deviations` records overridden calls.** tech-lead writes the section as a self-describing
sentinel and never fills it in — it cannot know deviations at plan time. The coordinating session
replaces the sentinel at step 10 with `None.` or one bullet per departure, naming the stated call,
what shipped instead, and who decided. Both engineers and the coordinating session are sources; in
practice the session is the more common one. A sentinel rather than an empty section is deliberate:
an untouched section and one nobody looked at are otherwise indistinguishable, which is the failure
class this pack has produced repeatedly.

**Consumption is opt-in per invocation.** A stage acts on a plan only when a skill hands it an
explicit `plan_id` and path. **Nothing ever globs the plan directory.** This is a safety property,
not a style preference: five skills dispatch merge-reviewer, so a directory-glob trigger would let
an unrelated `/hotfix` run enforce — and previously even delete — a plan belonging to different
work, producing a confident verdict about the wrong thing.

`/plan` and `/implement` pass a `plan_id`. **`/hotfix`, `/debug`, `/scaffold`, and `/refactor`
deliberately do not**, so they are exempt from plan enforcement *by construction* rather than by
rule, and their SKILL.md files need no plan-related logic. `/scaffold` never invokes tech-lead at
all. Do not add plan handling to any of the four without also deciding who owns the artifact for
that path.

**Plans are committed and never deleted.** The plan lands in the same commit as the implementation
so a reviewer can read intended shape against what was built. An accumulating `docs/plans/` is the
intended end state, exactly as `memory/decisions/` accumulates — a kept plan is the record of what
a change meant to do. A plan whose work is never implemented simply stays in the tree; because
consumption is opt-in, it is inert and needs no cleanup.

## Worktree policy
See `skills/implement/SKILL.md` for the full worktree branching and isolation rules.

## Conventions
If ./docs/CONVENTIONS.md exists, all agents must read it before acting.
Team standards in that file take precedence over agent defaults.

## Memory
If ./memory/ exists, all agents must check it before acting on any non-trivial task.
Use Glob on memory/**/*.md to discover files. Skip any file with
`status: superseded` or `status: archived` -- these are history only.

The tech-lead and devils-advocate agents write new memory files after significant
decisions. Engineer agents (csharp-engineer, frontend-engineer, mcp-engineer,
database-engineer) may write to `memory/known-issues/` when they discover a
genuine platform quirk, implementation constraint, or workaround during their
work — see **Engineer write permission** below. All other agents are read-only
with respect to `./memory/`.

### Subdirectory taxonomy

- **`memory/decisions/`** — Architectural and design decisions with rationale.
- **`memory/architecture/`** — Module boundaries, data flow, and integration patterns.
  Also hosts `repo-map.md`, a durable directory-level map of the codebase
  (what each directory does + its entry-point files), maintained by `/repo-map`
  and stamped with the git commit it was verified against. `/onboard`, tech-lead,
  `/plan`, `/refactor`, and `/scaffold` read it; merge-reviewer, git-engineer, and
  `/memory-audit` flag it for refresh when the tree drifts.
- **`memory/context/`** — Environmental constraints, platform quirks, and tooling workarounds.
- **`memory/known-issues/`** — Bugs, limitations, and workarounds that remain unresolved.

### Engineer write permission

Engineer agents (csharp-engineer, frontend-engineer, mcp-engineer, database-engineer)
may create or update files in `memory/known-issues/` when all three conditions hold:

1. The constraint is **non-obvious** — it would not be apparent from reading the code.
2. It **affects future work** on this codebase (a gotcha that will bite the next engineer too).
3. It is **not already documented** in CONVENTIONS.md or an existing memory file.

**What qualifies:** ORM limitations, Windows-specific path behaviors, an external API
that silently ignores a parameter, a framework version quirk that requires a workaround.

**What does not qualify:** routine implementation choices, variable naming, anything
trivially reversible, or anything that disappears when the dependency is upgraded.

Use standard memory frontmatter: `type: known-issue`, `status: active`,
`discovered: YYYY-MM-DD`. Include a `Workaround:` line describing the fix applied.

### Precedence rules

- Active files without `Overrides-convention: yes` rank below CONVENTIONS.md and above agent defaults.
- Active files with `Overrides-convention: yes` rank above CONVENTIONS.md, but only within their declared Scope.
- Narrower scope wins over broader scope when two files conflict.
- When two active files conflict at the same scope, flag the conflict -- do not pick one silently.

## Obsidian decision capture

When you and the user reach a significant technical decision — an architectural choice, technology selection, pattern adoption, or approach the user explicitly accepts — append a record to `~/.claude/session-decisions.txt` **before moving on**:

```bash
echo "[$(date +%H:%M)] <what was decided> — <why in 10 words or fewer>" >> ~/.claude/session-decisions-${CLAUDE_CODE_SESSION_ID:-$(cat ~/.claude/current-session-id 2>/dev/null | tr -d '[:space:]')}.txt
```

**`$CLAUDE_CODE_SESSION_ID` first, always.** `~/.claude/current-session-id` is a single global file
that *every* concurrent session overwrites on every prompt submission, so reading it resolves to
whichever session most recently took a turn — not necessarily this one. Under two or more live
sessions that silently files decisions into another session's log. The env var is per-session and
cannot race. The file remains only as a fallback for a session where the var is somehow unset.

The Stop hook reads this file after each response and includes it in the session log automatically. You do not need to ask the user's permission — just record it and continue.

**What counts:** architecture choices, library/framework selections, pattern adoptions, reversals of previous decisions, anything that would belong in `memory/decisions/`.

**What does not count:** routine implementation details, variable names, minor style choices, anything trivially reversible.

Do not call `/obsidian-capture` for this — writing to the decisions file is sufficient and less disruptive.

## Obsidian session state capture

As significant work progresses or when stopping mid-thread, append lines to the session-state file **before ending your response**:

```bash
echo "<where work currently stands>" >> ~/.claude/session-state-${CLAUDE_CODE_SESSION_ID:-$(cat ~/.claude/current-session-id 2>/dev/null | tr -d '[:space:]')}.txt
```

Three line types are supported in the same file:

- **Plain line** (no prefix) — describes where work currently stands. Becomes the "Where we left off" entry in `_current.md`. Latest write wins; write it once near the end of a work stream.
- **`THREAD: <short description>`** — records an open thread or unfinished item that should persist across sessions.
- **`DONE: <thread text>`** — resolves a previously recorded thread. Matching is case-insensitive; the text must otherwise match the original THREAD: text (used for removal).

```bash
# Plain progress note
echo "Implemented auth service; wiring to controller next" >> ~/.claude/session-state-${CLAUDE_CODE_SESSION_ID:-$(cat ~/.claude/current-session-id 2>/dev/null | tr -d '[:space:]')}.txt

# Open thread
echo "THREAD: Add rate limiting to /api/orders endpoint" >> ~/.claude/session-state-${CLAUDE_CODE_SESSION_ID:-$(cat ~/.claude/current-session-id 2>/dev/null | tr -d '[:space:]')}.txt

# Resolve a thread (case-insensitive match against stored thread text)
echo "DONE: Add rate limiting to /api/orders endpoint" >> ~/.claude/session-state-${CLAUDE_CODE_SESSION_ID:-$(cat ~/.claude/current-session-id 2>/dev/null | tr -d '[:space:]')}.txt
```

The Stop hook folds this file into the project's `_current.md` automatically at session end. No skill invocation needed.

The same `$CLAUDE_CODE_SESSION_ID`-first rule applies here as for decision capture above, and for the
same reason — `current-session-id` races between concurrent sessions.

**What counts:** unfinished multi-session work, blocked items, "we stopped here because X", open questions that need follow-up next session.

**What does not count:** trivial sub-steps completed within the session, anything already resolved before the session ends.
