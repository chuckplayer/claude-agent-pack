---
date: 2026-10-12
type: finding
status: active
superseded-by: n/a
scope: install.sh, scripts/check-updates.sh, scripts/lint-identifiers.sh, CLAUDE.md, agents/, skills/, references/
overrides-convention: no
related-to: n/a
description: devils-advocate challenge of the chat-only token-reduction / references/ / project-scope-install plan; durable platform facts plus unresolved concerns
---

## Summary

Challenged a chat-only plan (no plan file) on branch `feat/token-reduction-references` to cut token use by
moving conditionally-needed content out of always-loaded files into an installed `references/` directory,
resolved via an install-time `{{AGENT_PACK_REFS}}` token, and to add a project-level install scope. The
goal itself was user-approved and not challenged. Several premises were checkable without the planned
Phase 0 spike and were checked; three of them are durable facts worth keeping regardless of what this plan
becomes. All concerns below are **Unresolved**: the session ended with findings returned to the
coordinating session, no decision recorded.

## Context

The plan mirrors the structure of a plugin in `<internal-repo>` (read-only reference). Twelve design calls,
phases 0-5. The challenge was asked to pressure-test the substitution scheme, fail-closed behaviour,
the CLAUDE.md split, the savings case, sequencing, and hidden couplings.

## Durable facts established (verified, not opinions)

1. **Subagent precedence and skill precedence are opposite.** Claude Code docs (sub-agents page): a
   project `.claude/agents/` definition wins over `~/.claude/agents/`. Docs (skills page): "personal over
   project" — `~/.claude/skills/` wins over `.claude/skills/`. A machine with both scopes installed runs
   user-scope skills that dispatch project-scope agents.
2. **Custom subagents load CLAUDE.md.** Docs: every built-in and custom subagent loads the CLAUDE.md
   hierarchy unless its definition sets `omitClaudeMd` (v2.1.271+); Explore and Plan skip it. Observed
   directly: a devils-advocate dispatch in this repo received the full repo `CLAUDE.md` as context. So
   CLAUDE.md's size is paid once per dispatch, not once per session.
3. **The Read tool resolves a leading `~`.** Executed 2026-10-12 from a subagent on this Windows machine:
   `Read("~/.claude/agents/ts-linter.md")` returned the file. One data point (one harness version, one
   machine, foreground subagent). Every pack agent already depends on this via its
   `~/.claude/agents/<name>.override.md` instruction.
4. **`scripts/lint-identifiers.sh` cannot see untracked files.** `files()` and `files_all()` (lines
   109-115) enumerate `git ls-files`, which lists tracked/indexed paths only. A newly created file is
   invisible to the check until it is staged, and merge-reviewer runs gate 2c before its `git add -A`. A
   cut whose new files are written directly by the coordinating session (no worktree branch merged in
   Step 0) commits those files to a public repo unscanned.
5. **Non-plugin skills get `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` substituted in their markdown
   body** (skills docs). Agent bodies have no documented substitution.

## Concerns Raised

All **Unresolved** — returned to the coordinating session for the operator.

- **Dual-scope install is the common case, not an edge**, given fact 1; a warning does not stop
  mixed-version pipelines. Impact: user skill v_old drives project agent v_new against two different
  references directories.
- **Savings are dominated by CLAUDE.md x dispatch count** (fact 2), roughly an order of magnitude above
  the agent and skill extractions combined; the phase order puts the biggest, simplest win behind the
  most complex plumbing.
- **Moving rules out of CLAUDE.md also removes them from subagents.** No engineer agent file carries the
  departure-reporting or run-existing-tests duty; `/scaffold` and `/debug` do not restate them;
  `skills/implement/SKILL.md` says "Per CLAUDE.md, every engineer must...". The Obsidian decision/state
  capture text is what makes the prompt/stop hooks capture anything.
- **New-file identifier blind spot** (fact 4) applies to exactly the content this cut creates.
- **Fail-closed detects absence only**, not an agent that skips the pointer, and not stale references.
- **Absolute-path rendering for user scope is unnecessary** given fact 3; the render's real value is
  binding each agent to its own scope's references.
- **Splitting `/devops-azure` into a second skill** breaks section-number citations from
  `/implement` (8a/8b/8c/8f/step 4) and moves cross-cutting `az` rules (8f) into batch-only scope; a
  supporting file beside the same SKILL.md (fact 5) yields the same saving without a new routing name.
- **Self-reference trap** in the new lint/assert rules: shipped text that documents the token or names
  `references/` will trip them, the same class as the retired prose trigger in `lint-plans.sh`.

## Implications

- Before any future cut adds files written outside a worktree, stage them (or otherwise make them
  visible to `git ls-files`) before running `lint-identifiers.sh`, or the clean result is vacuous for the
  new content. Fixing the script itself is a separate change.
- Any install design that allows both scopes must account for opposite precedence; "warn" is not a
  control.
- Any estimate of CLAUDE.md context cost must multiply by subagent dispatches.
- Fact 3 should be re-confirmed in a new session and in a background subagent before a design depends
  on it.
