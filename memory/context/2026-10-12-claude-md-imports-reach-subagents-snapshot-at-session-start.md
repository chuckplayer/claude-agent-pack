---
date: 2026-10-12
type: context
status: active
superseded-by: n/a
scope: CLAUDE.md, docs/CLAUDE.template.md, any change to always-loaded instructions
overrides-convention: no
related-to: n/a
---

# A custom subagent receives @imported CLAUDE.md content, from a snapshot taken at session start

Two facts, both observed rather than read from docs, that decide how this pack can split its always-loaded
instructions.

**1. `@path` imports in CLAUDE.md are expanded in a custom subagent's context.** The official docs say
imports are "expanded and loaded into context at launch alongside the CLAUDE.md that references them" and
that a subagent loads "every level of the CLAUDE.md hierarchy", but they do not say outright that
subagents get imports expanded. Tested 2026-10-12 on Claude Code 2.1.296: in a scratch project whose
CLAUDE.md was `@inc.md` plus one sentence of its own, a fresh `claude -p` session dispatched a custom agent
that quoted a sentence existing only in `inc.md`, and the sentence from the outer file. This is why the
repo's `CLAUDE.md` can be `@docs/CLAUDE.template.md` plus a short "This repository" section.

**2. A subagent gets the CLAUDE.md content loaded when the session started, not a fresh read at dispatch.**
After CLAUDE.md was rewritten mid-session, a subagent dispatched in the same session still quoted the *old*
wording and saw none of the new headings. So an in-session test of an edit to CLAUDE.md, or of an import
you just added, is inconclusive in both directions. Test in a new session, or in a nested `claude -p` run
from a scratch directory (the technique above).

Implications: any estimate of CLAUDE.md cost must multiply by subagent dispatches (see
`known-issues/2026-10-12-challenge-token-reduction-references.md`); and `omitClaudeMd: true` in an agent's
frontmatter (Claude Code 2.1.271 or later) would drop CLAUDE.md from that agent entirely, which is a larger
lever than any text extraction but removes the memory and conventions rules from it, so it needs its own
decision per agent.
