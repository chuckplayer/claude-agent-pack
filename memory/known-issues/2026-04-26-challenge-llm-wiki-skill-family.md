**Date:** 2026-04-26
**Last-updated:** 2026-05-14
**Type:** finding
**Status:** archived
**Superseded-by:** 2026-05-14-decision-wiki-skill-family-resolution.md
**Scope:** skills/wiki-*, agents/wiki-*, scripts/wiki-*
**Overrides-convention:** no
**Related-to:** n/a

> Most items resolved by implementation choices. L15 and L16 remain open —
> see superseded-by file. Archived — agents may skip this file.

## Summary

A devils-advocate session pressure-tested the planned `llm-wiki` skill family
(four skills, three agents, two scripts) for the Claude Agent Pack before
implementation. Multiple concerns were raised across the install-path model,
agent write-boundaries, vault discovery, and domain extensibility. The session
ended without explicit resolution of each item — this file preserves them so
they are not lost when implementation begins.

## Context

Plan under review: add `skills/wiki-init`, `skills/wiki-ingest`,
`skills/wiki-query`, `skills/wiki-lint` plus three agents (`wiki-ingestor`,
`wiki-librarian`, `wiki-linter`) and two scripts (`wiki-init.sh`,
`wiki-log.sh`). Vaults live at `~/.claude/wiki/<domain>/` with raw/, wiki/
substructure. Vacation-planning is the launch domain. Schema is co-evolved
in a per-vault CLAUDE.md. Pack memory and wiki memory are strictly separate.

## Concerns Raised

### Critical

- **Script path resolution after install (C1) — Unresolved.** `install.sh`
  copies only `SKILL.md` to `~/.claude/skills/<name>/`. The installed skill
  has no reliable way to reference scripts that live in the pack tree at an
  arbitrary location on the user's machine. No existing pack skill shells out
  to a pack-local script — there is no precedent. Resolution required before
  `wiki-init.sh` is written. Options on the table: inline bash into the skill
  body, install scripts to `~/.claude/scripts/`, env var, or pure-LLM skills.

- **Librarian/ingestor write-boundary ambiguity (C2) — Unresolved.**
  `/wiki-query` "always offers to file answers back" but librarian is
  described as read-only and ingestor is described as raw/-to-wiki/. Filing a
  query result is neither. Boundary must be decided and documented in both
  agent files before either is written.

### High

- **Iron rule has no enforcement mechanism (H3) — Unresolved.** "LLM never
  writes to raw/" is convention-only. Convention-only rules fail in long
  sessions, on typo-fix requests inside raw/ files, and across agent revisions
  that drop the rule. Either accept this risk explicitly or add filesystem-
  level enforcement (chmod, path-check guard).

- **Vault path discovery undefined (H4) — Unresolved.** Four skills, N vaults,
  no decided mechanism. Must be the same across all four skills.

- **Cross-domain agent context bleed (H5) — Unresolved.** Three agents are
  installed once and shared across vaults. Within a Claude Code session,
  consecutive invocations against different vaults may inherit prior context.
  Skills must aggressively reset context at top of invocation.

- **`index.md` writer not assigned (H6) — Unresolved.** Either ingestor
  writes (race condition + git merge conflict risk) or linter regenerates
  (then it is derived data and should not be in git). Pick a model.

- **`CLAUDE.md` co-evolution model not specified (H7) — Unresolved.** Three
  candidate models (user-only-writable / LLM-suggest-user-approve /
  LLM-writable) and the plan implies all three. The LLM will default to
  whichever is most convenient mid-task.

### Medium

- **Wikilink rendering outside Obsidian (M8) — Unresolved.** Wikilinks render
  as literal text in non-Obsidian viewers. Document as accepted limitation
  and instruct ingestor explicitly to use `[[wikilink]]` not `[name](path)`.

- **Four-skill discovery problem (M9) — Unresolved.** No `/wiki` umbrella
  entry point. Users will not remember which of four commands to use.

- **Pure-agent linting is non-deterministic (M10) — Unresolved.** Mechanical
  checks (frontmatter schema, orphans) belong in a script; LLM reasoning
  belongs to judgment calls. Current plan has only the latter.

- **Domain schema does not generalize (M11) — Unresolved.** Most entity
  types in the vacation schema are domain-specific. Adding new domains
  requires editing the bash script.

- **Unknown-domain UX is a wall (M12) — Unresolved.** "Exit with error
  listing available domains" leaves the user with no path forward except a
  pack fork. Compare to other generative skills in the pack which interview
  the user.

### Low

- **`log.md` timestamps lack precision (L13) — Advisory.** Same-day ops
  collide. ISO-8601 with time fixes it cheaply.

- **Vault path inside `~/.claude/` couples to Claude Code's directory
  semantics (L14) — Advisory.** Low-probability future conflict.

- **`install.sh` and uninstaller need to disclose `~/.claude/wiki/` (L15)
  — Unresolved.** Surprise directories on install/uninstall are a known
  pack anti-pattern.

- **Dataview compatibility unverified (L16) — Unresolved.** `last_updated`
  as a quoted string will not work as a Dataview date. Test one query in
  Obsidian before claiming Dataview-friendliness.

### Plan-text inconsistency (separate from challenges)

The plan's "Pack conventions" section says agents use `AGENT.md` files in
`agents/<name>/` directories. The pack actually uses flat `agents/<name>.md`
files (see `install.sh:23` and existing agent files). Fix the plan text
before implementation begins.

## Implications

Six items in the Key Questions list block clean implementation: install-path
resolution (C1), librarian/ingestor boundary (C2), vault discovery (H4),
index.md ownership (H6), domain extensibility (M11/M12), and iron-rule
enforcement (H3). The plan is implementable without resolving the remaining
items, but they will surface as user-visible defects within the first week
of real use.

A future session implementing this should re-read this file before starting
and explicitly mark each Unresolved item as Addressed or Accepted-risk in a
follow-up decision file under `memory/decisions/`.
