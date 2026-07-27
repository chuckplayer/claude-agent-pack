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
- If the user wants to revise the plan first, loop back to step 2, 3, or 4 as needed.

## 6. Obsidian sync requests

tech-lead and devils-advocate write memory files but cannot reach the vault themselves —
neither grants `Bash` or `Agent`. When either one ends its output with an
`## Obsidian sync request` section, you own the dispatch:

1. Check `$env:OBSIDIAN_VAULT_PATH`. If empty, skip silently — do not tell the user.
2. For each memory file listed in that section, dispatch **obsidian-writer** with:
   - `write_mode`: `"capture"`
   - `vault_path`: `OBSIDIAN_VAULT_PATH`
   - `cli_mode`: `OBSIDIAN_CLI_MODE` (default `"filesystem"`)
   - `rest_api_port`: `OBSIDIAN_REST_API_PORT` (default `27124`)
   - `rest_api_https`: `OBSIDIAN_REST_API_HTTPS` (default `"true"`)
   - `projects_folder`: `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
   - `project`: basename of the project directory
   - `session_api_written`: `false`
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
