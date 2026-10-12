# Orchestration rules -- long form

The long-form rules behind the always-loaded `CLAUDE.md` block. The block keeps what every session
and every subagent needs on every dispatch; this file keeps the rationale, the incident history and the
detailed mechanics, and is read **on demand** -- when a task reaches one of these topics, not at the
start of every run.

Read the section you need, not the whole file:

- **Invoke backlog-auditor AFTER a backlog tree exists** -- dispatching `backlog-auditor`, and why
  `/devops-azure` batch write mode sits outside the code pipeline.
- **A stage is complete when it reports** -- what to do when a subagent goes idle without a report.
- **Plan spine** -- the plan file, who writes and checks it, `lint-plans.sh`, `## Deviations`.
- **Work-item mode** -- `/implement` advancing an Azure DevOps work item.
- **Memory** -- the directory taxonomy, the engineer write permission, precedence between files.

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

  **Batch write mode on `/devops-azure` is the only writer of `external_refs:`.** It consumes a tree
  `/backlog` produced and creates the corresponding work items; `/backlog` never writes that field and
  never asks about trackers. Like `/backlog`, batch mode is **not part of the code pipeline** — it
  dispatches no agent and enters no gate, so nothing about it belongs in the routing rules in `CLAUDE.md`. Stated here explicitly so a later reader does not add batch mode to an agent list: the
  routing sections govern agents, and this mode is not one. This is the same failure the `/backlog`
  paragraph above guards against, arriving from a different direction.


## A stage is complete when it reports, not when its agent stops

**A subagent that goes idle without sending a report has not completed its stage.** Seven agents in
one session did exactly that on 2026-08-03 — `obsidian-writer`, `codex-reviewer`, `code-reviewer`,
`security-reviewer`, `git-engineer` twice, and `test-engineer`. The work was correct every time and
only the report was lost, which is precisely why it is dangerous: nothing is missing except the
judgement, so it is indistinguishable from success at a glance.

- **Never infer a verdict from process state.** Dispatched, finished, idle, or `completed` in a task
  list are facts about a process, not about a review. Only the report's content is evidence.
- **Re-dispatch a silent agent; never speak for it.** Do not reconstruct, summarise, or assume its
  findings, and never report the stage as run. merge-reviewer verifies stages from context, so an
  unreported stage passed off as complete yields a confident verdict about a review nobody read.
- **Prefer a re-runnable check over a report you must trust.** Anything mechanical — a test suite,
  a script gate, a `git` fact — should be executed rather than believed. This is why
  merge-reviewer holds `Bash` and why its gates 2a and 2b run their checks directly.
- **Reviewers whose only artifact is the report** (code-reviewer, security-reviewer,
  performance-reviewer, smell-reviewer, and devils-advocate when no plan file was handed to it) have
  nothing to re-run, so the first rule is the whole defence there.
- **An agent holding `Write` should persist its judgement, not only its edits.** This is the one
  mitigation that demonstrably worked, and `agents/devils-advocate.md` now carries it: the narrative
  findings go into the plan as a `## Challenge` section *before* the reply is composed. It does not
  fix the stall — it stops the stall taking the findings with it. It also relieves nobody of rule 1.
  A plan edited by an agent that never reported is the **most** misleading state of the lot, because
  it reads as fully reviewed.

The stall is in the harness and cannot be fixed from inside this pack. What the pack controls is
whether silence is read as assent. See
`memory/known-issues/2026-08-03-subagent-goes-idle-before-reporting.md`, and note the shared lesson
with `memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`: **absence of a signal is
never evidence that the signal would have been positive.**


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
- **devils-advocate** pressure-tests the bars in the plan file, editing in place, **and appends a
  `## Challenge` section holding its narrative findings before it composes its reply** — so a stall
  cannot take the judgement with it. That section is the only part of the plan file it writes rather
  than edits, and it leaves the `## Deviations` sentinel alone. It is the only
  check on bar quality; tech-lead both writes the bars and is measured by them. It applies the
  **`### Bar soundness` table in `agents/tech-lead.md`**. That table is the single authority and
  **defines its own scope** — do not restate its rows, its row count, or its scope here or in any other
  file, for the same reason the plan-directory guard table is cited rather than copied. This pointer is
  deliberately bare: an earlier version of it described the table as covering "the ways an `Evidence:`
  line passes while the property it checks is false", which stopped being true the moment the table
  grew a row about something other than an `Evidence:` line. **A second description of a scope is a
  second thing to keep in sync, and it will lose.** The table exists because format compliance is not
  soundness: a well-shaped bar that cannot fail makes a downstream gate report success while proving
  nothing, which is worse than a missing bar.
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

**`scripts/lint-plans.sh` checks a plan's structure, and it is the coordinating session's job, not
merge-reviewer's.** Three triggers, each blocking, each passing the plan path: after **tech-lead
writes** a plan (`/plan` step 2), after **devils-advocate edits** one (`/plan` step 3, `/implement`
step 3), and when **`/implement` adopts** one (step 2). The adoption trigger exists because
`/implement` acts on plans it did not write — a plan handed in by a caller other than `/plan` may have
been through neither the writer nor the audit, and without it a structurally unenforceable plan first
fails at gate 4a, after every engineer, reviewer, and test stage has run. It validates frontmatter
keys, the presence of `## Acceptance bars` and
`## Deviations`, unique bar ids, an `Evidence:` line typed `tests`/`manual`/`files` on every bar, and
one substantive rule: **a bar carrying a `Gated:` field must also carry a `Cost:` line** —
bar-soundness row 6 made mechanical, because a missing cost statement is visible to a script while a
*wrong* one is not. The trigger is the **structured field**, never the prose word "gated"; matching the
word flagged bars that only *mentioned* gating, including one describing the check itself.

Three constraints on it, each for a reason already established elsewhere:

- **It takes explicit paths and never globs a plan directory**, for exactly the reason consumption is
  opt-in below: a glob would let one run validate and report on a plan belonging to unrelated work.
- **Pass the path as a discrete argument; never interpolate it into a shell string.** The path derives
  from a `docs/CONVENTIONS.md` value controlled by the host repository, and `agents/merge-reviewer.md`
  documents in full why that is a command-substitution risk rather than a style question. The same
  reasoning applies to any caller, not only to that agent.
- **merge-reviewer deliberately does not run it.** It is forbidden from putting the plan path into a
  shell command at all, and it holds `git commit`, `git add -A`, and branch deletion — so it keeps
  using `Grep` and `Read` for gate 4a. This is a real division, not an oversight: the script checks
  *structure*, gate 4a judges *evidence*, and the script's failures are all things a plan's author can
  fix before the pipeline ever starts.

**Plans written before this check existed pass it, and that is deliberate rather than lucky.** They
carry no `Gated:` field, so the `Cost:` rule never fires on them — a field-based trigger cannot
retroactively condemn text written before the field existed. This removes a tension the first draft of
this check had: a prose trigger failed four bars in `docs/plans/devops-azure-batch-write.md`, which
would have invited editing a merged plan to quiet a linter. **A merged plan is the record of what a
change meant to do and is never retro-edited.** Run the script on the plan handed to your run, not on
the directory.

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


## Work-item mode is opt-in per invocation, on the same footing as the plan spine

**`/implement` work-item mode advances an Azure DevOps work item alongside the code**, and it runs
**only** when a work item id reaches it — passed with the invocation, or carried in an adopted plan's
optional `work_item:` frontmatter key. **No id, no mode:** steps 0, 1a, 10c and 11a are skipped, the
run says so once, and everything else proceeds unchanged. **That is the default and the common
case** — `/implement` against a repository with no tracker at all must keep working, and it does.

**`/hotfix`, `/debug`, `/scaffold` and `/refactor` pass no work item id**, so merge-reviewer's gate
4b is `not applicable` for them **by construction rather than by rule** — the same shape, and for the
same reason, as their exemption from plan enforcement above: five skills dispatch merge-reviewer, so
a gate that searched for a work item could advance an item belonging to unrelated work. **Nothing
ever infers a work item from a branch name.**

Two properties worth keeping straight, because each has already been the subject of a wrong
assumption:

- **merge-reviewer makes no ADO call.** Gate 4b emits one line — `AUTHORIZED`, `WITHHELD`, or
  `not applicable` — and the **coordinating session** performs every write, behind an operator
  confirmation that displays the command. So gate 4b is an **input to that confirmation, not the
  control on the write**. The separation is deliberate: an agent that mutates a *shared* tracker and
  then goes idle without reporting is worse than the same failure on a local file, and
  preview-and-confirm needs a human interlocutor a subagent cannot obtain.
- **Hours are never set.** Elapsed wall-clock goes in a discussion comment that explicitly names
  `Microsoft.VSTS.Scheduling.CompletedWork` as not set, because that field feeds velocity reporting
  and an automated run's elapsed time is not effort. `skills/devops-azure/SKILL.md`'s
  `Where it lives` table is the authority on where each ADO fact belongs.

**A work item id is not a pull request id.** They are separate numbering spaces; only `/implement`
step 11a takes a PR id, and it is skipped rather than attempted when none is available.

**Plans are committed and never deleted.** The plan lands in the same commit as the implementation
so a reviewer can read intended shape against what was built. An accumulating `docs/plans/` is the
intended end state, exactly as `memory/decisions/` accumulates — a kept plan is the record of what
a change meant to do. A plan whose work is never implemented simply stays in the tree; because
consumption is opt-in, it is inert and needs no cleanup.


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

**`discovered:` is still mandatory here.** It is not one of the seven required keys, but it is a
*sanctioned extra* under `MEMORY-WRITING.md` — that document names it and permits it rather than
contradicting this requirement. Extra keys in general are permitted, so adding one does not break the
dialect. Include a `Workaround:` line in the body describing the fix applied.

The engineer write-permission block previously instructed three bare keys with no fence, which was a third dialect competing
with the two in the corpus. All 52 files were normalized on 2026-09-02; write the dialect above and
nothing else.

### Precedence rules

- Active files without `overrides-convention: yes` rank below CONVENTIONS.md and above agent defaults.
- Active files with `overrides-convention: yes` rank above CONVENTIONS.md, but only within their declared Scope.
- Narrower scope wins over broader scope when two files conflict.
- When two active files conflict at the same scope, flag the conflict -- do not pick one silently.

