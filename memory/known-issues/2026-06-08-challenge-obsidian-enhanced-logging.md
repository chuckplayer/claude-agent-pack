---
date: 2026-06-08
type: finding
status: active
superseded-by: n/a
scope: scripts/obsidian-stop-hook.js, scripts/obsidian-prompt-hook.js, scripts/tag-inferrer.js, install.sh, scripts/check-updates.sh
overrides-convention: no
related-to: 2026-05-14-decision-obsidian-hook-windows-resolution.md
---

## Summary

Pressure-tested a plan to enhance Obsidian auto-logging: refactor the Stop hook to read
stdin, wire orphaned session journals into session notes, capture decisions from a global
`~/.claude/session-decisions.txt` into ADR files (then clear the file), infer smart tags via
a new `tag-inferrer.js` module, and embed `session_id` in frontmatter. The plan's stdin
premise is sound, but it conflates the `Stop` and `SessionEnd` events — which run the SAME
script binary (`install.sh:379-380, 405-406`), distinguished only by a `"SessionEnd"` argv
the current code ignores. That conflation is the root cause of a critical data-loss risk.

## Context

User requested an adversarial review of the enhanced-logging implementation plan before
implementation. Verified against the live scripts in `~/.claude/scripts/`, the official
Claude Code hooks docs, `install.sh` hook registration, and `check-updates.sh`.

## Concerns Raised

### Critical

- **Destructive per-turn clear of global session-decisions.txt — Unresolved.**
  `Stop` fires once per turn (confirmed via docs and `install.sh:405`). The plan relaxes the
  SHA guard when decisions exist, so every turn with a decision writes ADRs and clears the
  global file. `SessionEnd` runs the same script and would then read an empty file or
  re-process. A crash between clear and ADR-write loses decisions with no recovery path. With
  the global file shared across concurrent projects, one project's Stop can clear another
  project's not-yet-consumed decisions — data loss, not the "bleed" the user accepted.
  Potential impact: silent loss of the highest-value, least-reproducible artifact.
  Recommended fix: make `SessionEnd` (detected via `process.argv[2] === 'SessionEnd'`, already
  wired) the sole consumer/clearer; or mark-don't-clear; or per-session file keyed by session_id.

### High

- **SHA guard exits before decision capture — Unresolved.**
  `obsidian-stop-hook.js:35-38` exits at statement 7, before any content is built. A decision
  check added later is unreachable on no-code-change turns (exactly the planning sessions that
  produce decisions). Must hoist a "anything new to log?" probe above the guard.

- **ADR slug collisions via PUT — Unresolved.**
  `tryApiWrite` uses HTTP PUT (line 173). `decisions/{date}-{slug}.md` has no uniqueness
  strategy; same-day same-slug decisions clobber each other; per-turn reprocessing duplicates.
  Fix: minute-precision timestamp + content hash in slug; resolve the clear-race first.

### Medium

- **Journals never deleted — Unresolved.** `session-journals/{sessionId}.jsonl` accumulate
  forever (prompt/agent hooks append, nothing deletes). Fix: SessionEnd-scoped deletion or
  age-based sweep (sweep preferred — survives crashes).

- **tag-inferrer.js drift — Unresolved.** `check-updates.sh:56-67` tracks only
  obsidian-stop-hook.js (prompt/agent hooks already untracked — latent bug). `install.sh:354-356`
  copies files individually. A 4th file silently drifts unless install + check-updates + a
  require-fallback are all added in the same PR. At one consumer, inlining may be lower risk.

- **Silent failure when decision-writing discipline lapses — Unresolved.** No feedback if
  Claude forgets to write session-decisions.txt. Prior memory (2026-05-14) left "M1 silent
  failure" only Partially Addressed (still no debug log); this refactor adds complexity on top.
  Fix: always render `## Decisions` with explicit "0 captured"; add the one-line debug log.

### Low (resolved during session)

- **stdin contract — Addressed.** Docs confirm Stop and SessionEnd both deliver session_id on
  stdin; prompt/agent hooks already consume it in production. Caveat: adding async stdin read
  to a currently-synchronous hook introduces a hang risk that `uncaughtException` does NOT
  catch. A hard setTimeout fallback routing through finish() degraded is mandatory.

## Implications

- The `Stop` vs `SessionEnd` split is the central unaddressed design decision. The same binary
  serves both; the distinguishing `"SessionEnd"` argv is already passed by install.sh and
  currently ignored. Splitting behavior by `process.argv[2]` dissolves the critical and several
  high/medium risks at once with no new infrastructure.
- Decisions are the only data in the system with no recoverability under the current plan.
- Reconsider the accepted "global session-decisions.txt, bleed accepted" decision: the
  constraint that justified it (no session_id) no longer holds in the refactored hook.
- Overall verdict given to user: REVISE-THEN-PROCEED. Do not ship the destructive per-turn clear.
