---
name: plan
description: "Decompose a complex task using tech-lead and optionally pressure-test the plan using devils-advocate before implementation begins. Use when the task is ambiguous, spans multiple concerns, or when the user wants to stress-test an existing proposal before committing. Trigger this when someone says: how should I approach this, plan this out, I am not sure how to do this, think through this with me, is this a good approach, pressure-test my plan, help me design this. Do NOT use when the task is already well-scoped — go straight to /implement instead."
---

# Plan

Decompose or challenge a task before implementation begins.

## 1. Determine what the user needs

- **"I have a task I don't know how to approach"** → decompose with tech-lead (step 2)
- **"I have a plan I want to pressure-test"** → challenge with devils-advocate (step 3)
- **"Both"** → run tech-lead first (step 2), then devils-advocate on the result (step 3)

If unclear, ask: "Do you have a plan already, or do you need one decomposed first?"

## 2. tech-lead — task decomposition (if needed)

Invoke tech-lead with the full task description. Pass any constraints, related files, or architectural context. tech-lead reads `memory/architecture/repo-map.md` (if present) to accelerate routing and blast-radius assessment — if you already know the repo structure has changed a lot recently, suggest `/repo-map refresh` first so the plan is built against an accurate map.

**Instruct tech-lead to write a plan file, and pass it the resolved plan directory.** tech-lead
writes a plan file only when told to, so this instruction is what creates the artifact. Resolve
the directory first:

```bash
grep -m1 '^- \*\*Plan directory:\*\*' docs/CONVENTIONS.md 2>/dev/null | sed 's/^.*\*\*Plan directory:\*\*[[:space:]]*//'
```

Fall back to `docs/plans` when that returns nothing, or when the value fails **any condition in the
guard table in `agents/tech-lead.md`** — read that table rather than working from a list here. It is
the single authority on what is rejected, and a copy in this file would go stale the first time it
grows a row. Pass the resolved directory and the current branch name in the dispatch prompt.

tech-lead re-applies that guard to whatever it receives, so the two checks are genuinely
redundant — but do not rely on that as a reason to skip this one. Resolving here is what lets you
tell the user *why* their configured directory was rejected; tech-lead's copy is a backstop, not a
substitute.

Note the resulting `plan_id` from tech-lead's output — step 5 hands it forward.

**Then validate the plan's structure before presenting it.** This is a **blocking gate**, and it is
the coordinating session's job — merge-reviewer deliberately does not run it:

```bash
bash scripts/lint-plans.sh docs/plans/<plan-id>.md
```

- **Pass the plan path as a discrete argument.** Never interpolate it into a longer shell string and
  never build a command around it. The directory half comes from a `docs/CONVENTIONS.md` value the
  host repository controls, which makes an interpolated path a command-substitution risk rather than a
  style question; `agents/merge-reviewer.md` documents that reasoning in full.
- **Pass only the plan this run produced.** The script never globs the plan directory, for the same
  reason consumption is opt-in: a glob would validate and report on a plan belonging to unrelated work.
- On a machine where `bash` is not on the shell's PATH, use the Bash tool rather than skipping the
  step — the same rule `/implement` step 5c applies to `scripts/lint-agents.sh`.

**A non-zero exit blocks.** Missing frontmatter keys, a missing `## Acceptance bars` or
`## Deviations`, duplicate bar ids, an untyped `Evidence:` line, or a `Gated:` field with no `Cost:`
line all mean the plan cannot be enforced by merge-reviewer's gate 4a. Route the named failure back to
tech-lead and re-run until it exits 0. Every one of these is something the plan's author can fix
before any pipeline starts, which is exactly why the check belongs here and not at the end.

One output line is **not** a failure: `[--] ## Deviations still holds its sentinel` is correct at this
point — that section is filled in at `/implement` step 10, not now.

**A PASS is not a reviewed plan.** The script checks structure and makes no claim about truth. Whether
a bar's evidence proves anything, and whether a stated `Cost:` is accurate, is step 3's job and the
bar-soundness table's.

The tech-lead will:
- Identify which specialist agents are needed
- Determine the correct invocation order (sequential vs. parallel)
- Surface whether devils-advocate should run before implementation
- Produce a step-by-step plan with rationale for each step

Present the plan clearly to the user. If it introduces a new pattern, a new dependency, or an irreversible architectural change, recommend running step 3 before proceeding.

If tech-lead's output ends with an `## Obsidian sync request` section, handle it per step 6 before moving on.

## 3. devils-advocate — pressure-test (if warranted)

Invoke devils-advocate with:
- The full plan or proposal
- Any alternatives already considered and why they were rejected
- Any constraints, requirements, or deadlines that shaped the decision

The devils-advocate will surface unconsidered alternatives, challenge hidden assumptions, and identify risks.

**If a plan file was written in step 2, tell devils-advocate to pressure-test its acceptance bars
in the file, editing it in place.** Pass the plan path. It already holds `Write`, and this is the
only check on bar quality anywhere in the pipeline — tech-lead writes the bars *and* is the agent
whose work they measure, so unreviewed bars tend toward the unfalsifiable. Specifically ask it to
flag any bar whose `Evidence:` line names something that cannot actually be produced.

**Expect a `## Challenge` section appended to the plan.** devils-advocate is required to persist its
narrative findings there *before* composing its reply, because an agent that goes idle without
reporting otherwise takes its judgement with it. Treat that section as expected output, not drift.
It does **not** substitute for the report: if the plan gained a `## Challenge` section and no report
arrived, the stage did not complete — re-request once, and if that is also silent, say so in the
record rather than reading the artifact as a verdict.

**In the same pass, ask it to flag non-falsifiable entries in `## Calls made for you`.** A stated
call is only enforceable downstream if it names a concrete artifact someone could look up — a
dependency, a file or directory, a type or endpoint, a specific value. A call naming only a quality
("keep it maintainable") or a pattern ("use the repository pattern") has no lookup target, so
merge-reviewer's Tier 3 skips it by construction and it silently enforces nothing. Have
devils-advocate either sharpen such a call into a checkable form or say plainly that it is
documentation for the human rather than an enforceable decision. Gate coverage is a direct function
of how well these are written, and this pass is the only place it gets checked.

**If devils-advocate edited the plan file, re-run `scripts/lint-plans.sh` on it** — same command and
same blocking rule as step 2. This is not redundant with the step 2 run: devils-advocate edits bars in
place, so it can sharpen a vague bar into a gated one and introduce a `Gated:` field with no `Cost:`
line, which is a row-6 failure that did not exist when step 2 passed. Also confirm it left the
`## Deviations` sentinel alone; it is instructed not to touch it, and the script reports which state
that section is in.

If its output ends with an `## Obsidian sync request` section, handle it per step 6.

After it completes:
1. Present the key concerns raised clearly.
2. If the decision is architectural, irreversible, or spans multiple systems, continue to step 4 for a cross-model check before asking the user to decide.
3. Otherwise ask: "Proceed with the original plan, revise it, or abandon it?" and note which concerns were accepted as known risks vs. resolved.

## 4. codex-reviewer — cross-model second opinion (if warranted)

Invoke when the decision is architectural, irreversible, or spans multiple systems, and the `codex` CLI is available and authenticated. Skip silently (do not block on it) if `codex` is not installed — this step is advisory, not required.

Invoke codex-reviewer with:
- The full plan or proposal
- The concerns devils-advocate already raised (so it isn't duplicating ground already covered)

After it completes:
1. Present its synthesis alongside devils-advocate's findings — call out agreement, divergence, and any new concerns it surfaced.
2. Ask: "Proceed with the original plan, revise it, or abandon it?"
3. If proceeding, note which concerns (from either devils-advocate or codex-reviewer) were accepted as known risks vs. resolved.

## 5. Hand off to implementation

If the user is ready to implement:
- Invoke `/implement` and pass the finalized plan plus any risk notes from steps 3–4.
- **If a plan file was written, pass its `plan_id` and path explicitly.** `/implement` adopts a
  plan only when handed one — it never searches a directory — so omitting the id means it will
  re-plan from scratch and write a second plan file for the same work.
- If the user wants to revise the plan first, loop back to step 2, 3, or 4 as needed.

## 6. Obsidian sync requests

tech-lead and devils-advocate write memory files but cannot reach the vault themselves —
neither grants `Bash` or `Agent`. When either one ends its output with an
`## Obsidian sync request` section, you own the dispatch:

1. Check `$env:OBSIDIAN_VAULT_PATH`. If empty, skip silently — do not tell the user.
2. For each memory file listed in that section, dispatch **obsidian-writer** with:
   - `write_mode`: `"capture"`
   - `vault_path`: `OBSIDIAN_VAULT_PATH`
   - `projects_folder`: `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
   - `project`: basename of the project directory
   - `title`: the description given on that file's line
   - `body`: full content of the memory file (frontmatter + body)
   - `timestamp`: current datetime in `YYYY-MM-DDThh:mm` format

If obsidian-writer errors or the vault directory is missing, continue — the project's
`memory/` file is the authoritative record. Do not fail the plan over a failed sync.

## Gotchas

- **Over-planning paralysis:** If the user keeps asking for "one more round" of devils-advocate without moving toward implementation, surface the pattern and ask directly: "Are there unresolved concerns keeping you from proceeding, or is this ready to implement?" Planning is a means, not an end.
- **tech-lead and devils-advocate disagree:** When this happens, present both positions clearly and ask the user to decide. Do not pick one silently. The user owns the architectural decision.
- **devils-advocate and codex-reviewer disagree:** Same rule applies — present both perspectives and let the user decide. Do not treat codex-reviewer as a tiebreaker.
- **`codex` CLI not installed or not authenticated:** Skip step 4 without asking — it's advisory only, and a missing/broken CLI shouldn't block planning. Mention the skip briefly so the user knows it wasn't silently forgotten.
- **Skipping plan when the task is genuinely ambiguous:** If a task description is vague and the user says "just implement it," recommend a quick tech-lead decomposition first. A few minutes of planning prevents hours of rework from misunderstood requirements.
- **Plan becomes stale mid-implementation:** If the user pauses mid-/implement and comes back with changed requirements, return to /plan to re-decompose rather than patching the original plan. Stale plans cause the pipeline to route incorrectly.
- **A plan whose work is never implemented just stays in the tree.** That is harmless and needs no cleanup. Nothing globs the plan directory: consumption is opt-in, so a downstream stage acts on a plan only when a skill hands it a specific `plan_id`. An unimplemented plan cannot be picked up by an unrelated `/hotfix` or `/refactor` run, and it is not committed until some run commits it. Mention it to the user so they know it is there, then leave it alone.
