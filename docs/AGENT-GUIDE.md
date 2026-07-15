# Agent Guide

Practical usage documentation for the Claude Code Agent Pack.

---

## First-Time Project Setup

> **Prerequisites -- complete these before agents work correctly in any project.**

After running the installer, do these three steps in each project where you want to use the agents:

**Step 1: Copy CLAUDE.md to the project root**

```powershell
# Windows
Copy-Item "$env:USERPROFILE\.claude\skills\claude-agent-pack\CLAUDE.md" ".\CLAUDE.md"
```

```bash
# macOS
cp ~/.claude/skills/claude-agent-pack/CLAUDE.md ./CLAUDE.md
```

Without this file, the orchestration rules do not exist. Agents will run, but without routing, memory, or convention rules.

**Step 2: Copy the memory scaffold and commit it**

```powershell
# Windows
Copy-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\claude-agent-pack\memory" "."
```

```bash
# macOS
cp -r ~/.claude/skills/claude-agent-pack/memory .
```

Commit the empty scaffold immediately. Without this, memory files written by agents are silently discarded between sessions because the directory does not exist in version control.

```bash
git add memory/
git commit -m "Add agent memory scaffold"
```

**Step 3 (optional): Copy and fill in CONVENTIONS.md**

```powershell
# Windows
New-Item -ItemType Directory -Force -Path ".\docs" | Out-Null
Copy-Item "$env:USERPROFILE\.claude\skills\claude-agent-pack\docs\CONVENTIONS.template.md" ".\docs\CONVENTIONS.md"
```

```bash
# macOS
mkdir -p ./docs
cp ~/.claude/skills/claude-agent-pack/docs/CONVENTIONS.template.md ./docs/CONVENTIONS.md
```

Open `docs/CONVENTIONS.md` and fill in your project-specific values. All agents read this file before acting and apply your team's standards automatically.

---

## Recommended Workflow

The full agent sequence from task to completion:

```
task -> [tech-lead] -> [devils-advocate] -> [codex-reviewer] -> engineer -> code-reviewer -> [security-reviewer] -> test-engineer
```

Bracketed agents are conditional:
- **tech-lead** -- invoke when the task is ambiguous, spans multiple concerns, or touches more than three files.
- **devils-advocate** -- invoke before implementation on new patterns, architectural decisions, or irreversible changes.
- **codex-reviewer** -- invoke after devils-advocate on architectural or irreversible decisions to get a cross-model second opinion via the Codex CLI. Requires `codex` to be installed and authenticated.
- **security-reviewer** -- invoke after implementation when changes touch auth, data access, PII, or secrets.

For small, well-scoped tasks, invoke the specialist directly (e.g., `Use the csharp-engineer to add a null check to OrderService.GetById`).

---

## The Memory Directory

The `memory/` directory gives agents a lightweight persistence layer. Decisions, architectural context, and known issues survive between sessions and are shared across the team via version control.

### Why it is committed to version control

Memory files are project knowledge, not personal notes. When a tech-lead records a significant architectural decision, every team member's future agent sessions benefit from that context automatically. Committing memory to git means the knowledge travels with the codebase.

### Who writes to memory

- **tech-lead** writes `decision-` prefixed files when architectural or technology decisions are made.
- **devils-advocate** writes `challenge-` prefixed files after challenge sessions conclude.
- All other agents are read-only with respect to `memory/`.

### How to read memory

Before acting on any non-trivial task, agents:
1. Run `Glob("memory/**/*.md")` to discover all memory files.
2. Skip files with `status: superseded` or `status: archived`.
3. Apply global-scoped files universally. Apply scoped files only when working within that scope.
4. For files with `Overrides-convention: yes`, apply the documented exception instead of the corresponding CONVENTIONS.md rule within the stated scope.

### Memory file format example

A tech-lead decision file:

```markdown
# Use Hangfire for background job processing

**Date:** 2025-03-01
**Type:** decision
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** 2025-03-01-challenge-hangfire-license-cost-accepted-risk.md

## Summary
Hangfire is the chosen background job framework for all async processing.

## Context
We needed a reliable way to enqueue and process background jobs with retry
semantics. Three options were evaluated during sprint planning.

## Rationale
Hangfire has the best Windows/.NET integration, supports SQL Server as a
backing store (which we already have), and provides a dashboard without
additional infrastructure.

## Alternatives Rejected
- Quartz.NET: more complex configuration, no built-in dashboard.
- Azure Service Bus: adds cloud dependency; team preference is to keep
  infrastructure minimal for now.

## Implications
All new background processing must use Hangfire. Do not introduce raw
Thread, Task.Run, or IHostedService patterns for job scheduling.
```

A devils-advocate challenge file (referencing the same decision):

```markdown
# Hangfire license cost for commercial use

**Date:** 2025-03-01
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** 2025-03-01-decision-use-hangfire-for-background-jobs.md

## Summary
Hangfire Pro is required for multi-server or advanced features; free tier
may be insufficient at scale.

## Context
Raised during devils-advocate session before adopting Hangfire.

## Rationale
**Accepted risk:** The team reviewed Hangfire's licensing. Free tier is
sufficient for current single-server deployment. If the application scales
to multi-server, a Pro license will be required (~$699/year). The team
accepted this risk and noted that migration cost is low because Hangfire's
API does not change between tiers.

What would trigger revisiting this: moving to a multi-server deployment
or adding recurring job features available only in Pro.

## Implications
Before scaling to multi-server, evaluate Hangfire Pro licensing cost.
```

---

## Invocation Examples

### Explicit invocation

1. "Use the tech-lead agent to plan adding a payment processing feature."
2. "Use the devils-advocate agent to challenge our plan to migrate from REST to GraphQL."
2a. "Use the codex-reviewer agent to get Codex's take on this architecture decision."
3. "Use the csharp-engineer to add a `GetByExternalId` method to `OrderRepository`."
4. "Use the frontend-engineer to create a `useOrderStatus` composable that polls the order endpoint."
5. "Use the code-reviewer to review the changes in `OrderService.cs`."
6. "Use the security-reviewer to check the new authentication middleware."
7. "Use the test-engineer to write tests for `OrderService.GetById`."

### Letting orchestration work automatically

8. "Plan and implement a feature to export order history to CSV." (tech-lead orchestrates the full sequence)
9. "We need to add role-based access control to the API. What's the right approach?" (tech-lead plans, devils-advocate challenges, engineers implement, reviewers verify)
10. "Implement the changes described in the tech-lead's plan above." (engineers pick up the decomposed subtasks from tech-lead output)

---

## When to Skip Agents

Not every change needs the full pipeline.

- **Small bug fix** (one method, obvious cause): Go directly to `csharp-engineer` or `frontend-engineer`. Skip `tech-lead` and `devils-advocate`.
- **Trivial one-liner** (fixing a typo, updating a constant): No orchestration needed. Make the change directly.
- **Already-established pattern** (adding another endpoint that follows the exact same shape as existing ones): Skip `devils-advocate`. Use `csharp-engineer` directly.
- **Style or naming fix**: Use `code-reviewer` to verify if uncertain. No engineer agent needed.
- **Test update for a changed interface**: Use `test-engineer` directly. No plan needed.

The overhead of orchestration is justified when the task is genuinely ambiguous, multi-layered, or could take the wrong path. For clear, bounded work, invoke specialists directly.

---

## Adding Custom Agents

### The routing contract

The `description` field in an agent's frontmatter is the routing contract. The tech-lead routes based on descriptions, not a hardcoded table. A well-scoped description is sufficient for automatic routing.

Good description examples:
- "Use when writing or modifying Oracle stored procedures or PL/SQL packages."
- "Invoke to generate database migration scripts from EF Core model changes."
- "Use for all Terraform infrastructure changes to the Azure environment."

Vague description to avoid:
- "Helps with database stuff." (Too broad -- will receive tasks it cannot handle.)

### Where to place custom agents

- **Project-level** (overrides global for that project): `.claude/agents/` in the project root.
- **User-level** (available in all your projects): `~/.claude/agents/` (macOS) or `$env:USERPROFILE\.claude\agents\` (Windows).

Project-level agents take precedence over user-level agents with the same name. This lets you tune an agent's behavior for a specific codebase without affecting other projects.

### Minimum frontmatter

```yaml
---
name: your-agent-name
description: >
  Specific description of when this agent should be invoked.
  One or two sentences. Unambiguous scope.
tools: Read, Grep, Glob
model: sonnet
permissionMode: plan
version: "1.0.0"
---
```

---

## Customizing with CONVENTIONS.md

All agents read `./docs/CONVENTIONS.md` before acting if it exists. Team standards in that file override agent defaults.

**What happens if CONVENTIONS.md is missing:** Agents fall back to the standards embedded in their system prompts (C# 12+, strict TypeScript, Vue 3 Composition API, etc.). These are reasonable defaults but not tailored to your project.

**How it changes output:** An agent that would otherwise use a generic naming pattern will adopt your project's actual naming pattern. An agent that would invent a logging approach will follow the one you documented.

**To override individual agents at the project level:** Place an agent file in `.claude/agents/` with the same name as the global agent. The project-level version takes full precedence for that project. This is useful when a project has different standards for one agent but not others.

---

## Memory Hygiene

Memory files accumulate over time. Stale files consume tokens on every agent invocation and can mislead agents about the current state of the codebase.

### Signs a file should be `archived`

- The module it references no longer exists in the codebase.
- The technology it covers has been removed or replaced.
- The constraint it documents no longer applies (e.g., a third-party limitation that was lifted).

### Signs a file should be `superseded`

- A newer decision reverses or replaces it.
- The approach it documents was tried and abandoned.

### How to update status

To archive a file, open it and change the Status field:

```markdown
**Status:** archived
```

To supersede a file, update the old file and create a new one:

Old file:
```markdown
**Status:** superseded
**Superseded-by:** 2025-06-15-decision-migrate-to-minimal-api.md
```

New file:
```markdown
**Status:** active
**Superseded-by:** n/a
**Related-to:** 2025-03-01-decision-use-mvc-controllers.md
```

Both files should reference each other via `Related-to` and `Superseded-by` so the history is navigable.

### Recommended practice

Review `memory/` at the start of any significant feature work. Ask of each active file: does this still describe the codebase as it exists today? Treat stale memory like stale comments -- update or remove rather than leave misleading.

The tech-lead's pre-task memory check already serves as a light audit. If the tech-lead finds files with no clear application to the current codebase during this check, it archives them immediately.

---

## Memory Scaling

The token cost of memory reads scales with the number of active files. Agents already skip `superseded` and `archived` files, which reduces this cost. The real defense against accumulation is recognizing the signals that pruning is needed and acting on them.

### Observable signals that memory needs a pruning pass

- An agent cites a decision about a service, module, or dependency that no longer exists in the codebase.
- A challenge file references a concern that was resolved long ago and its resolution is now common knowledge on the team.
- The tech-lead's pre-task memory check visibly dominates its initial response -- more time recounting decisions than planning the actual work.
- Multiple agents in the same session re-read the same memory files that are clearly not relevant to the task at hand.

### The 30-file soft ceiling

> "If `memory/` contains more than 30 files with `status: active`, run a hygiene pass first. For each file ask: does this still describe the codebase as it exists today? If not, archive or supersede it before proceeding."

30 is not a hard limit -- a complex domain with active architectural evolution may legitimately sustain more. The number is a concrete checkpoint, not a rule. The observable signals above are more reliable than the count alone.

### The review norm

At the start of any significant feature work, the tech-lead's pre-task memory check already serves as a light audit. No separate calendar-based review is needed. If the tech-lead finds files with no clear application to the current codebase during this check, it archives them immediately rather than silently skipping them.

### What this approach does not solve

Hygiene buys time and sets good norms but does not raise the architectural ceiling. If a project reaches 40+ active decisions and agents are heavily used, a summary file approach becomes worth the maintenance overhead. Revisit that decision with real usage data rather than in advance.

---

## Troubleshooting

**An agent ignores CONVENTIONS.md**

Verify the file exists at `./docs/CONVENTIONS.md` relative to the project root (not inside a subdirectory). Agents look for it at that exact path. If the path is different, copy the file or add a note to CLAUDE.md pointing to the actual location.

**The tech-lead routes to the wrong specialist**

The tech-lead routes by reading agent `description` fields. If routing is wrong, the description of the target agent may be ambiguous or too broad. Open the agent file and tighten the description to more precisely state when it should (and should not) be invoked.

**An agent's output is too broad or too narrow**

If output is too broad: the description may be matching tasks it should not handle. Narrow the description.

If output is too narrow: the agent may be over-filtering based on scope. Check whether the `Scope` field in a memory file is limiting the agent inappropriately. Also check whether CONVENTIONS.md contains a rule that is unintentionally restricting output.

**A memory file contains stale or incorrect information**

Do not delete the file -- the history is valuable. Update the `Status` field to `archived` (if the context no longer applies) or `superseded` (if a newer decision replaces it). If superseding, populate the `Superseded-by` field and create the replacement file with `Status: active`. Both files should reference each other via `Related-to`.
