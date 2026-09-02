---
date: 2026-05-14
type: decision
status: archived
superseded-by: wiki family removed 2026-05-16; replaced by /obsidian-brief
scope: skills/wiki-*, agents/wiki-*
overrides-convention: no
related-to: 2026-04-26-challenge-llm-wiki-skill-family.md
---

## Summary

The wiki skill family was implemented and the April 2026 devils-advocate
concerns were reviewed post-implementation. Most critical and high items were
resolved by design choices made during implementation. Remaining open items
are documented below with accepted-risk or revisit-trigger decisions.

## Resolution of Each Concern

### C1 — Script path resolution after install
**Addressed.** Wiki skills are pure-LLM. No scripts are installed to
`~/.claude/scripts/`. All vault operations use Read/Write/Edit/Glob/Grep
tools directly. The concern about referencing pack-local scripts from
installed skills does not apply.

### C2 — Librarian/ingestor write-boundary ambiguity
**Addressed.** Boundaries are now explicit in both agent files:
- wiki-ingestor: sole owner of `index.md`, writes to `wiki/` only
- wiki-librarian: read-only except for `wiki/synthesis/` (explicit user
  request only), index additions, and `log.md` append
- The "file back" operation is assigned to wiki-librarian, not a third agent

### H3 — Iron rule has no filesystem enforcement
**Accepted risk.** "Never write to `raw/`" is enforced through three layers
of instruction: agent description, "Iron Rule" section, and Hard Constraints.
Filesystem chmod is not available to LLM agents. Three-layer instruction
enforcement is the maximum achievable in this architecture. Revisit trigger:
if a user reports a raw/ modification in production. Mitigation: the agents
are instructed to refuse and explain if asked to write raw/.

### H4 — Vault path discovery undefined
**Addressed.** Vaults live at `~/.claude/wiki/<domain>/`, established by
wiki-init. The domain is passed as context from each skill to the agent.
Consistent across all four skills.

### H5 — Cross-domain agent context bleed
**Addressed by design.** Each agent invocation begins by reading
`<vault>/CLAUDE.md` and `<vault>/index.md` fresh from the provided vault
path. Agents have no persistent memory between invocations — they reconstruct
their understanding from the current vault on every call. The vault path
parameter acts as the domain boundary.

### H6 — index.md writer not assigned
**Addressed.** wiki-ingestor is the sole owner of index.md. wiki-librarian
may add synthesis page entries (explicitly stated in its hard constraints).
No other agent modifies index.md. Race condition risk is accepted as low
given that both agents are invoked sequentially by their respective skills.

### H7 — CLAUDE.md co-evolution model not specified
**Addressed.** LLM-suggest-user-approve model. The ingestor proposes new
page types and asks the user to add them to CLAUDE.md before proceeding.
The linter proposes CLAUDE.md schema changes but never writes them (stated
in its description and hard constraints). CLAUDE.md is user-writable only.

### M8 — Wikilink rendering outside Obsidian
**Accepted.** Documented limitation. The wiki family is intentionally
Obsidian-native. Users who want non-Obsidian rendering can fork the schema.

### M9 — No umbrella entry point
**Addressed.** `/wiki` skill exists as an umbrella help/routing skill.

### M10 — Pure-agent linting is non-deterministic
**Partially addressed.** The wiki-linter's checks are well-defined structural
operations (broken wikilinks by file match, orphaned pages by inbound-link
map, index gaps by set comparison, missing frontmatter by field presence).
These can be applied consistently by an LLM following explicit rules.
The non-deterministic concern was overstated — these checks require reading
comprehension, not judgment. Accepted as adequate for the current use case.
Revisit trigger: if users report inconsistent lint results for the same vault.

### L13 — log.md timestamps lack precision
**Addressed.** log.md entries use ISO-8601 with minute precision
(e.g., `2026-04-26T14:30`), stated explicitly in wiki-ingestor step 5.
Same-day collision risk is negligible at minute granularity.

### L14 — Vault inside ~/.claude/ couples to Claude Code directory semantics
**Accepted.** Advisory. Low probability of conflict. No action taken.

### L15 — install.sh does not disclose ~/.claude/wiki/ creation
**Addressed.** Wiki vaults are created on-demand by `/wiki-init`, not by
`install.sh`, so there is nothing to disclose at install time. `uninstall.sh`
now detects `~/.claude/wiki/` at the end of the uninstall run and prompts
the user to remove it or keep it, with the manual delete path printed if
they keep it.

### L16 — Dataview compatibility unverified
**Addressed.** All `last_updated` frontmatter templates now use the unquoted
format `last_updated: YYYY-MM-DD` (not `"YYYY-MM-DD"`). Fixed in:
wiki-librarian synthesis template, wiki-ingestor update instruction (with
explicit "quoted dates break Dataview" note), and all six page-type templates
in wiki-init SKILL.md.

## Implications

- All four wiki agents and three wiki skills are production-ready for the
  defined use case (Obsidian-native, per-domain vaults under ~/.claude/wiki/).
- L15 (uninstall gap) and L16 (Dataview date format) are the only items
  requiring future attention.
- The pure-LLM, no-script architecture is the correct pattern for wiki skills
  and should be the default for any new knowledge-management skill family.
