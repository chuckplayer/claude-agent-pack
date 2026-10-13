# Agent Orchestration Rules

Long-form rules, rationale and incident history live in `orchestration-rules.md`, installed with the
pack. Look first at `<project root>/.claude/agent-pack/references/orchestration-rules.md` (a project-scope
install), then at `~/.claude/agent-pack/references/orchestration-rules.md` (a user-scope install;
`~/` is your home directory). If neither exists the pack is not installed: say so rather than guessing
what it contains. Read the section a task reaches -- not the whole file, and not at the start of every run.

## Sub-Agent Routing

The tech-lead agent routes tasks based on each agent's `description` field -- that description is the
routing contract. To make a custom agent routable, write a clear, specific description that
unambiguously states when it should be invoked. The tech-lead will route to it automatically.

### Invoke devils-advocate BEFORE implementation when:
- The task introduces a pattern not already present in the codebase
- The change affects more than two architectural layers
- The decision is difficult or impossible to reverse
- A new technology, library, or integration is being added

### Invoke tech-lead BEFORE implementation when:
- The task is ambiguous or spans multiple concerns
- You are unsure which agents to invoke or in what order
- The work touches more than three files across different layers

When both are warranted, run tech-lead first to decompose the task into a plan, then devils-advocate to
challenge that plan. Only after devils-advocate completes should api-designer (if needed) and engineer
agents be invoked.

### Invoke codex-reviewer AFTER devils-advocate when:
- The decision is architectural, irreversible, or spans multiple systems
- A cross-model second opinion adds value beyond internal pressure-testing
- The `codex` CLI is available and authenticated on the machine

Run it sequentially after devils-advocate (it benefits from having devils-advocate's concerns as
context). It is advisory only -- it never blocks implementation.

### backlog-auditor
Dispatched by `/backlog` after the tree is written, and by nothing else. It audits a decomposition, not
code. Batch write mode on `/devops-azure` is not part of the code pipeline and dispatches no agent. Detail:
long-form file, "Invoke backlog-auditor AFTER a backlog tree exists".

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
- **git-engineer** before any engineer agent when the task involves code changes and the working
  branch has not already been confirmed: on `main` or `master`, ask whether to pull latest and create a
  new branch; on any other branch, confirm with the user that it is the correct branch for this work
- **api-designer** before csharp-engineer or frontend-engineer when the task creates or significantly
  modifies API endpoints

## Always invoke after implementation:
- **ts-linter** immediately after frontend-engineer or mcp-engineer, before code-reviewer. Pass the
  list of modified `.ts` files. Block on FAIL -- route back to the originating engineer before
  proceeding. If both ran in parallel, invoke ts-linter once after both complete, passing all modified
  `.ts` and `.vue` files together.
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

## A stage is complete when it reports, not when its agent stops

A subagent that goes idle without sending a report has not completed its stage. The work is often
correct and only the report is lost, which is exactly why it is dangerous: nothing is missing except the
judgement, so it reads as success.

- **Never infer a verdict from process state.** Dispatched, finished, idle, or `completed` are facts
  about a process, not about a review. Only the report's content is evidence.
- **Re-dispatch a silent agent; never speak for it.** Do not reconstruct, summarise, or assume its
  findings, and never report the stage as run.
- **Prefer a re-runnable check over a report you must trust** -- a test suite, a script, a `git` fact.
- Reviewers whose only artifact is the report (code-reviewer, security-reviewer, performance-reviewer,
  smell-reviewer, and devils-advocate when no plan file was handed to it) have nothing to re-run, so the
  first rule is the whole defence there. An agent holding `Write` should persist its judgement, not
  only its edits.

**Absence of a signal is never evidence that the signal would have been positive.**

Incident history and the full text: the long-form file, "A stage is complete when it reports".

## Built-in agent disambiguation

Use the built-in `claude-code-guide` agent for Claude Code feature questions
(how /X works, hooks, MCP, API). Do not answer those inline -- that wastes
planning tokens.

If `branch-manager` or `typescript-engineer` appear in the agent list, they are
stale copies from an earlier pack version -- re-run `install.sh` to remove them.
Route to `git-engineer` and `frontend-engineer` instead.


## Plan spine

Complex work can carry a durable plan file, `<plan_dir>/<plan-id>.md` (`plan_dir` is the
`- **Plan directory:**` key in `docs/CONVENTIONS.md`, default `docs/plans`), with `## Acceptance bars`
that merge-reviewer fails the run against. **Consumption is opt-in per invocation:** a stage acts on a
plan only when a skill hands it an explicit `plan_id` and path, and nothing ever globs the plan
directory. `/plan` and `/implement` pass a `plan_id`; `/hotfix`, `/debug`, `/scaffold` and `/refactor`
deliberately do not, so plan enforcement never applies to them. Engineers never write the plan file.
Plans are committed with the implementation and never deleted. Who writes and checks what, `lint-plans.sh`
and the `## Deviations` tiers: the long-form file, "Plan spine".

## Work-item mode

`/implement` advances an Azure DevOps work item only when a work item id reaches it -- passed with the
invocation, or carried in an adopted plan's `work_item:` key. **No id, no mode**, and nothing ever infers
an id from a branch name. `/hotfix`, `/debug`, `/scaffold` and `/refactor` pass none. merge-reviewer makes
no ADO call: gate 4b emits one line and the coordinating session performs every write behind an operator
confirmation. Hours are never set. Detail: the long-form file, "Work-item mode".

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


Directories under `memory/`: `decisions/`, `architecture/` (also `repo-map.md`), `context/`,
`known-issues/`. What each holds: the long-form file, "Subdirectory taxonomy".

### Engineer write permission

Engineer agents (csharp-engineer, frontend-engineer, mcp-engineer, database-engineer) may create or
update files in `memory/known-issues/` when all three conditions hold:

1. The constraint is **non-obvious** — it would not be apparent from reading the code.
2. It **affects future work** on this codebase (a gotcha that will bite the next engineer too).
3. It is **not already documented** in CONVENTIONS.md or an existing memory file.

Qualifies: ORM limitations, platform path quirks, an API that silently ignores a parameter, a framework
version quirk needing a workaround. Does not qualify: routine choices, naming, anything trivially
reversible or that disappears when the dependency is upgraded.

Use the standard memory frontmatter dialect — **fenced lowercase YAML**, seven required keys, exactly
as `docs/MEMORY-WRITING.md` specifies. For an engineer-written known issue that is:

```yaml
---
date: YYYY-MM-DD
type: known-issue
status: active
superseded-by: n/a
scope: the module, path, or tool the constraint applies to
overrides-convention: no
related-to: n/a
discovered: YYYY-MM-DD
---
```

`discovered:` is mandatory here — a sanctioned extra key under `MEMORY-WRITING.md`. Include a
`Workaround:` line in the body describing the fix applied.

### Precedence rules

- Active files without `overrides-convention: yes` rank below CONVENTIONS.md and above agent defaults.
- Active files with `overrides-convention: yes` rank above CONVENTIONS.md, but only within their declared Scope.
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
