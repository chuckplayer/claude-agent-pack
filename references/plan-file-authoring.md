# Plan file authoring

Read by `tech-lead` **when the dispatching prompt tells it to create or revise a plan file** -- never in a
chat-only dispatch. It holds where the plan goes, how it is named, its shape, the `## Deviations` sentinel,
the read-back checklist, the rules for revising a plan that has already been audited, and the format of the
acceptance bars. The responsibility-matrix rule and the rule never to write a plan file outside the repository
stay in `tech-lead.md`, because chat-only plans use them.

**The plan directory guard comes first.** `{{AGENT_PACK_REFS}}/plan-directory-guard.md` is applied to the
directory value before any step below, and is not restated here.

## Where the plan goes

**This section and Naming apply when you are creating a plan.** On a revision you are handed the path of an
existing file: edit that file in place as "Revising a plan file that has already been audited" says, and do
not apply Naming — a `-2` suffix would create a second plan instead of revising the first.

The dispatching skill normally passes you a resolved plan directory. If it passed none, resolve it
yourself: read `docs/CONVENTIONS.md` and look for

```
- **Plan directory:** <path>
```

**Whichever value you hold, resolved by you or handed to you, fall back to `docs/plans` if any condition in
the guard table holds.** The table is in `plan-directory-guard.md`; it has already been applied, to this
value, before you reach this step.

## Naming

`<plan_dir>/<plan-id>.md`, where `plan-id` is a kebab-case slug describing the work. **Read the
target path first.** If a file is already there, append `-2`, `-3`, … until the name is free —
never overwrite an existing plan, which may belong to another branch's in-flight work.


## Shape

```markdown
---
plan_id: <the kebab-case slug, matching the filename>
branch: <the git branch this plan governs>
origin_skill: <the skill that dispatched you, e.g. plan or implement>
created: YYYY-MM-DD
work_item: <optional — see below. Omit the key entirely when there is no work item id>
---

## What ships

## What does not ship

## Calls made for you

## Deviations

_Deviations not yet reviewed. The coordinating session replaces this line before
merge-reviewer runs — with `None.` if nothing diverged, or one bullet per departure.
Leave this line exactly as it is._

## Risks

## Out of scope

---

## Inputs

## Build steps

## Acceptance bars
```

The frontmatter binds the plan to one run. `plan_id` and `branch` are what let a downstream stage
confirm it is reading *this* run's plan rather than a stray file — record them accurately.

**`work_item:` is optional, and you write it only when the caller supplied an Azure DevOps work item
id with the task.** Omit the key entirely otherwise — an empty or placeholder value is worse than no
key, because `/implement` step 0 reads the key to decide whether to run work-item mode at all.

- **Record the id the caller gave you. Do not go looking for one**, do not infer one from a branch
  name, and **make no `az` call** — you hold no `Bash` and this is not your read to perform. If the
  caller included item text in the task description, that text is your input like any other; the key
  records only the id.
- **A work item id is not a pull request id.** They are separate numbering spaces in Azure DevOps.
  This key holds the work item id and nothing else.
- **The key is not required and `scripts/lint-plans.sh` does not check it**, so a plan without it is
  valid and every plan written before it existed stays valid. Its only consumer is `/implement`
  step 0, where an id passed explicitly with the invocation **wins** over the key.

Why it exists: without it the id has to be supplied twice — once to plan, once to implement — and a
plan and the work item it was planned from are unrelated files.

**Narrative half** (the six sections above the rule) is for the human. Order the content by what
they are most likely to want changed: user-facing shape first, data choices next, mechanical work
last. Put the calls you made on their behalf in `## Calls made for you` so they can veto them.


## `## Deviations` — always emit it, never fill it in

**Emit this section in every plan you write.** It is the one section of the template that arrives
with content already in it — the sentinel line — and that content is an instruction rather than
something for you to replace. Copy the heading *and* the sentinel line exactly as they appear in the
shape above, then move on to `## Risks`.

**Omitting the section is a failure, not a tidy-up.** "Never fill it in" means leave the sentinel
untouched; it does **not** mean leave the section out. A downstream gate fails a plan that has no
`## Deviations` section at all, on the same grounds it fails a plan with no `## Acceptance bars`.

You cannot know deviations at plan time: they are departures from your own stated calls, discovered
while the work happens, and recorded by the coordinating session before merge-reviewer runs.

The sentinel is a self-describing line rather than an empty section on purpose. **An empty section
cannot be told apart from an unfilled one**, and "indistinguishable from nobody looking" is the
failure this pack has produced repeatedly. The sentinel makes *nothing diverged* and *nobody
checked* two different, detectable states — a downstream gate fails while it is still present.

That is also why the line describes its own replacement: you are not the only agent that writes to
this file. `devils-advocate` holds `Write`, edits the plan in place when a caller asks it to
pressure-test the bars, and has no instructions anywhere about the plan's shape. A bare marker
would invite it to helpfully fill in or delete something load-bearing. A line that says who
replaces it and when does not.

**Write calls that can be checked — the burden is yours, not the gate's.** A later stage verifies
stated calls against what shipped, but it can only do so for a call that names one thing it can look
up. A call naming nothing specific is **out of scope for that check by construction**: it is
documentation for the human, not something enforceable. That is not a failure, but it is a weaker
line than it looks, so prefer calls a stranger could disagree with.

The rule of thumb: name an artifact, not a quality. `"Use Vitest"` and
`"No DbContext outside Infrastructure/Repositories/"` name things. `"Use the repository pattern"`
and `"keep it maintainable"` do not — the first names a *pattern* rather than an artifact, and
pattern compliance belongs to code-reviewer, which reads `docs/CONVENTIONS.md` for exactly that.

**The checkable-call definition lives in `{{AGENT_PACK_REFS}}/checkable-calls.md` — read it there rather
than working from a list here** (if that path is relative, prefix it with the project root). It is the
single authority, and a copy in this file would go stale the first time it changes. **If it cannot be
read, do not write the plan file at all:** stop and report the path that failed, because
a call written without the definition may name nothing a later gate can look up.


## Before you finish — read your own plan file back

Downstream stages fail on shape, not on intent, and a plan that is one heading short fails a gate on
work that was fine. Re-read the file you just wrote and confirm all six:

1. **All nine headings are present**, in the order shown in the shape — six above the rule, three
   below. Count them.
2. **`## Deviations` is there, with the sentinel line unmodified.** This is the one most easily
   dropped, because it is the only section you do not author.
3. **Every bar has its own `Evidence:` line on the next line, indented exactly two spaces.** Equal
   totals are not enough; each bar needs its own.
4. **The frontmatter has all four required keys**, and `plan_id` matches the filename. `work_item:` is a fifth, optional key — present only if the caller supplied a work item id, absent otherwise, and never empty.
5. **The plan file is where you meant to put it** — inside the repo, under the resolved plan
   directory.
6. **You read `bar-soundness.md` in this run** before writing or revising the bars. If you did not,
   you wrote them from memory: read it now and re-check every bar against it before you report.

Fix anything that fails before you report. A stranger reading this file is the next consumer, and
they cannot ask you what you meant.


## Revising a plan file that has already been audited

**A revision is a different operation from the first write, and on 2026-08-05 the difference cost real
work.** A revision dispatch composed a whole-file `Write` from the plan text in its own prompt. That
text was a snapshot taken *before* `devils-advocate` audited the file, so **three clauses the audit had
added were silently overwritten.** Nothing mechanical detected it — it surfaced only because
`merge-reviewer` asked `devils-advocate` to vouch for the current plan and got an honest *"I cannot."*
That recovery was luck.

Three rules, in force from the moment the file has been written once:

1. **`Read` the file first, every time.** The plan text in your prompt is a **snapshot**. If any audit
   has run since it was taken, your snapshot is stale by one audit — and you cannot tell that from
   inside your own context, which is exactly why this needs to be a rule rather than a judgement.
2. **Change it with `Edit` against what you just read. Never a whole-file `Write`.** A `Write`
   assembled from your context silently replaces everything you did not think to carry forward,
   including sections another agent authored that you may not know exist. The single sanctioned `Write`
   after the first is `devils-advocate` **appending** `## Challenge`.
3. **Never edit `## Challenge`, and never rewrite bar text an audit authored.** If an audited bar now
   looks wrong, **say so in your report** and let the coordinating session route it. Overwriting an
   auditor's judgement is the same failure as above, arriving deliberately rather than by accident.

**If you revise after an audit, say so in your report in those words** — the coordinating session owes
the run either "devils-advocate re-confirmed its edits survived" or "no post-audit revision occurred",
and it cannot state either one unless you tell it which happened.

**Working-memory half** (below the rule) is for the agents that come after you.


## Acceptance bars — the load-bearing part

Each bar is a list item with a stable id and a **required `Evidence:` line** naming how the bar
will be shown to hold. Evidence is one of `tests`, `manual`, or `files`.

**The format is a contract, not a suggestion — match it exactly:**

- The bar line starts at column zero with `- BAR-` followed by a three-digit number and a colon.
  Number them sequentially from `BAR-001`.
- The `Evidence:` line is the **next** line, indented **exactly two spaces**. Not four, not a tab.
- One `Evidence:` line per bar, never zero and never two.

A later stage counts bar lines and evidence lines and compares the two totals. **A four-space
indent, a tab, or a blank line between the bar and its evidence makes the evidence count zero
while the bar count stays right** — so every bar reads as unsupported and the gate misfires on a
plan that is actually fine. Getting the whitespace right is load-bearing.

```markdown
## Acceptance bars

- BAR-001: `/implement` adopts an existing plan instead of writing a second one
  Evidence: manual -> run /plan then /implement on one task, confirm one plan file exists
- BAR-002: the plan-directory guard rejects an unfilled `[e.g., ...]` placeholder
  Evidence: files -> references/plan-directory-guard.md rejection table
- BAR-003: OrderService.Cancel rejects an already-cancelled order
  Evidence: tests -> OrderServiceTests.Cancel_AlreadyCancelled_Throws
```

Write bars a stranger could check. A bar whose evidence cannot be named is not a bar — it is a
hope, and it will pass every gate while proving nothing. `tests` is the strongest evidence, but
`manual` and `files` are legitimate and complete answers for work with no test surface (prompt
files, documentation, shell scripts). Do not invent a test that cannot exist in order to look
rigorous.

