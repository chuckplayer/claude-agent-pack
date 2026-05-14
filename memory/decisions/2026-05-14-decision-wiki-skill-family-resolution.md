**Date:** 2026-05-14
**Type:** decision
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/wiki-*, agents/wiki-*
**Overrides-convention:** no
**Related-to:** 2026-04-26-challenge-llm-wiki-skill-family.md

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
**Open.** The `install.sh` wizard does not mention wiki vault directories.
Wiki vault initialization is on-demand via `/wiki-init`, not during install,
so there is nothing to disclose at install time. However, the uninstall.sh
does not clean up `~/.claude/wiki/` either. This should be addressed in a
future uninstall.sh update with an advisory note.

### L16 — Dataview compatibility unverified
**Open.** `last_updated` is written as a quoted YAML string. Dataview
requires unquoted date values for date filtering. Not yet tested in Obsidian.
Revisit trigger: if a user reports Dataview date queries returning no results.
Fix: change frontmatter template to write `last_updated: YYYY-MM-DD` without
quotes.

## Implications

- All four wiki agents and three wiki skills are production-ready for the
  defined use case (Obsidian-native, per-domain vaults under ~/.claude/wiki/).
- L15 (uninstall gap) and L16 (Dataview date format) are the only items
  requiring future attention.
- The pure-LLM, no-script architecture is the correct pattern for wiki skills
  and should be the default for any new knowledge-management skill family.
