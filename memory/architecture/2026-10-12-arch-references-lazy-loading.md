---
date: 2026-10-12
type: pattern
status: active
superseded-by: n/a
scope: references/, agents/tech-lead.md, agents/merge-reviewer.md, agents/devils-advocate.md, skills/plan, skills/backlog, skills/spec-intake, skills/implement, skills/devops-azure
overrides-convention: no
related-to: 2026-10-12-decision-install-time-reference-substitution.md
---

# Which reader reads which reference, on which branch

## Summary

Eleven pieces of text were moved out of always-loaded files and are read only when their branch is taken. This
file is the live location index for the moved authorities: when a rule is not where you remember it, look here.
Every reader carries a fail-closed clause, so an unreadable reference stops the work and names the path.

## Components

| Reference (installed under `<scope>/agent-pack/references/`) | Read by | When | If unreadable |
|---|---|---|---|
| `plan-directory-guard.md` | tech-lead; `/plan`, `/backlog`, `/spec-intake` | before any plan-file write or edit, create or revise; when a skill resolves a plan or spec directory | tech-lead writes no plan file and returns only a failure report; the skills fall back to their default directory (`docs/plans`, `docs/specs`) and say so |
| `plan-file-authoring.md` | tech-lead | after the guard, on any plan-file dispatch | no plan file; `/plan` stops, does not re-dispatch, does not write the plan itself |
| `checkable-calls.md` | tech-lead; merge-reviewer at Tier 3 | writing `## Calls made for you`; applying Tier 3 | no plan file; gate 4a FAIL |
| `bar-soundness.md` | tech-lead; devils-advocate | writing or revising bars; auditing bars | no plan file; "bar audit not performed", no bar edited |
| `plan-gate.md` | merge-reviewer | only when a `plan_id` was passed | gate 4a FAIL naming the path; never `not applicable` |
| `worktree-integration.md` | merge-reviewer | only when worktree branches were passed | stop and FAIL naming the path |
| `tech-lead-memory-writes.md` | tech-lead | only when about to write a memory file | the file is not written and is listed under Memory candidates |
| `implement-work-item-mode.md` | `/implement` | only when a work item id reached it | stop work-item mode, no ADO write, ask whether to continue code-only |
| `orchestration-rules.md` | the main session; `/plan`, `/implement` | when a task reaches plan spine, work-item mode, the stall rule or memory detail | optional; nothing depends on it |
| `skills/devops-azure/batch.md` (a supporting file, not a reference) | `/devops-azure` batch mode, via `${CLAUDE_SKILL_DIR}/batch.md` | only in batch mode, in full | stop before the preview; the one-confirmation licence applies only after it has been read |

Rules that deliberately stay inline so they hold when a reference cannot be read: the shell-injection rule for
a plan path (merge-reviewer), the guard-first and apply-always rule (tech-lead), the responsibility-matrix rule
(tech-lead), id validation and the `AUTHORIZED` gate and never-bare-`az` (`/implement`), and the three
properties of batch mode (devops-azure).

## Data Flow

A source file carries `{{AGENT_PACK_REFS}}/<name>.md`. `install.sh` copies references first, then agents, then
skills, rendering the token to `~/.claude/agent-pack/references` (user scope) or `.claude/agent-pack/references`
(project scope, with a relative-path clause). `lint-agents.sh` R1 checks every pointer resolves to a file under
`references/` and R5 warns about a reference nothing points at. The template for consumers points at
`orchestration-rules.md` in plain text, because `setup-project.sh` copies it without rendering.

## Implications

- Lazy loading saves tokens only on the branches not taken. See `known-issues/2026-10-12-known-issue-lazy-loading-saves-only-off-branch.md`.
- Adding a reader means adding its pointer with the fixed clause and a fail-closed sentence; adding a reference
  means a pointer from at least one shipped file, or R5 warns.
- Authority citations changed: the bar-soundness table and the checkable-call definition are no longer in
  `tech-lead.md` or `merge-reviewer.md`; do not cite those files for them.
