---
date: 2026-10-12
type: finding
status: active
superseded-by: n/a
scope: agents/tech-lead.md, references/, skills/plan/SKILL.md, skills/backlog/SKILL.md, skills/spec-intake/SKILL.md, scripts/lint-plans.sh
overrides-convention: no
related-to: 2026-10-12-challenge-token-reduction-references.md
description: devils-advocate challenge of Phase 3.3, splitting agents/tech-lead.md into plan-file-authoring, plan-directory-guard and memory-writes references; boundary leaks and unbacked residue
---

## Summary

Challenged the proposal (chat-only, no plan file, nothing edited) to move tech-lead's plan-file authoring
text, its plan-directory guard table, and its Memory Writes section into three `references/` files read on
demand, leaving fail-closed stubs. The token case holds: only `/plan` step 2 (and revisions) dispatch
tech-lead in plan-file mode, so chat-only dispatches dominate. The risk is behavioural. Several moved items
are needed in chat-only mode or at a trigger the stub does not name, and the skills that cite the guard
point at `agents/tech-lead.md`, a path no linter checks. All concerns **Unresolved**: findings went back to
the coordinating session and no decision was recorded.

## Context

Branch `feat/token-reduction-references`, Phase 3.3 of the token-reduction plan recorded in
[[2026-10-12-challenge-token-reduction-references]]. The bar-soundness, worktree-integration and plan-gate
extractions are already done. The caller asked six questions: boundary, two authorities, fail-closed, the
sentinel template, saving vs risk, and anything else.

## Concerns Raised

All **Unresolved**.

1. **Revision dispatches are not covered by the mode-B trigger.** The inline intro (`agents/tech-lead.md:29-31`)
   triggers on being told to *write* a plan file. A revision dispatch (`skills/plan/SKILL.md:141-143`) tells
   it to edit one. The revising rules (`:225-249`: Read first, Edit rather than Write, never touch
   `## Challenge`, report a post-audit revision in those words) are what the 2026-08-05 clause loss
   produced, and they move into a file the revision path has no reason to open. `/plan:142` also says "Both
   agents carry that rule in their own files", which stops being true.
2. **Mode-A text inside the moved Memory Writes section.** `:405` "Direct all dispatched agents to check
   `memory/**/*.md` before acting" is an instruction about plan output, not about memory writes. Output
   Format item 6 (`:322`, inline) asks for "target subdirectory, proposed filename" in chat-only mode, but
   the filename format and prefix table (`:361-370`) move. Before Planning step 4 (`:25`, inline) edits
   memory status without the "about to write a memory file" trigger firing. `docs/MEMORY-WRITING.md:15`
   says the prefix is in "each agent's own instructions" (that becomes stale). `:160` holds the superseding
   rule, which partly backstops it.
3. **Guard file content is undefined beyond the table.** "Where it goes" (`:36-69`) also holds the
   resolution procedure (Plan-directory key), the apply-always-even-to-a-handed-value rule (`:45-48`), the
   `docs/plans` fallback header (`:50`) and the symlink limit (`:64-69`). `/spec-intake` and `/backlog` fall
   back to `docs/specs`. If the shared guard file carries tech-lead's fallback or procedure, the shared
   authority becomes wrong for two of its three readers.
4. **Citations nothing mechanical catches.** `skills/plan/SKILL.md:37-38`, `skills/backlog/SKILL.md:29-32`,
   `skills/spec-intake/SKILL.md:29-35`, `references/orchestration-rules.md:92`, the comment at
   `scripts/lint-plans.sh:264-266`, the worked example at `agents/tech-lead.md:276`, and
   `docs/MEMORY-WRITING.md:15`. R1 and R2 (`scripts/lint-agents.sh:31-51`) see only `references/` paths and
   the token, never `agents/tech-lead.md`. Verified side fact: those three skill citations already fail to
   resolve in a consuming project, because agents install under `.claude/agents/` or `~/.claude/agents/`.
   So `/backlog` and `/spec-intake` fail closed to `docs/specs` there on every run, and `/plan` has no
   fail-closed clause at all. The proposal fixes a live defect, but only if those pointers change.
5. **Fail-closed has no handling at the caller.** If tech-lead refuses in mode B, `/plan` step 2 still runs
   `lint-plans.sh` on a non-existent path. That fails, and `/plan:71` routes the failure "back to tech-lead
   and re-run until it exits 0". Re-dispatching cannot fix a missing install file, and nothing forbids the
   coordinating session from writing the plan itself, which would skip the guard.
6. **Unbacked residue if the reference is skipped (not merely unreadable).** `lint-plans.sh` checks only 4
   frontmatter keys (`:130`), 2 of the 9 headings (`:164`), and accepts any Evidence indent, including one
   separated from its bar by a blank line (`:218`). Gate 4a requires exactly two spaces with immediate
   pairing (`references/plan-gate.md:43,63-71`). Never-overwrite, `plan_id` equal to the filename, the
   other 7 headings, exact indentation, and the revision rules are therefore enforced only by the moved text
   and its moved read-back checklist, or by gate 4a after the whole pipeline has run.
7. **Saving figure unmeasured.** A line-count estimate of the spans named puts them above the stated
   9-10K bytes. Neither figure was measured with `wc -c`.
8. **Smaller.** "Two Obsidian sync request sections" is one section (`:407`) plus a literal heading in its
   code block (`:417`). The responsibility matrix that stays inline sends its output to `## Build steps`
   (`:183`), a plan-file heading, so its "chat-only plans use it" premise is not what the text says.
   `:299-300` (copy Model Overrides into the plan) and `:162-177` (checkable calls, with a nested plan-gate
   pointer) are unassigned in the proposal. A generic name, `memory-writes.md`, for a tech-lead-specific
   prefix table invites devils-advocate, whose table differs, to be pointed at it.

No plan-sentinel check reads `agents/tech-lead.md`. Moving the full template breaks nothing mechanical.
Only the comment at `lint-plans.sh:266` goes stale.

## Implications

- Define plan-file mode as creating **or modifying** a plan file, and have the dispatching skill name the
  reference paths in its prompt, so the trigger does not rest on tech-lead recognising its mode.
- Update every citation in concern 4 in the same commit. Grep for them, because no linter will report them.
- Stage new `references/` files before running `lint-identifiers.sh`, per fact 4 of the related file.
- If a later session asks whether these concerns were addressed, compare against the split as committed.
  This challenge edited no file other than this one.
