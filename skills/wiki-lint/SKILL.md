---
name: wiki-lint
description: >
  Run a health check on an existing LLM wiki vault. Checks for orphaned pages,
  broken wikilinks, missing required frontmatter, stale last_updated fields,
  index gaps, and schema violations. Use when someone says "lint my wiki",
  "check my wiki", "wiki health check", "wiki is getting messy", "audit my
  wiki", "find orphaned pages", "is my wiki consistent". Read-only — does not
  modify wiki content, only reports findings and may propose CLAUDE.md schema
  improvements for the user to accept manually.
---

# Wiki Lint

Run a health check on the wiki vault. The linter is strictly read-only — it
finds problems and surfaces them; the user decides what to fix. The one
exception: the linter appends a lint entry to `log.md` to record that the
check ran.

## 1. Resolve the vault

Check `~/.claude/wiki/` for existing vaults (directories containing a
`CLAUDE.md`):

- **One vault found:** Use it. Confirm: "Running lint on vault at `<path>`."
- **Multiple vaults found:** List them and ask which to use.
- **No vaults found:** "No wiki vault found. Run `/wiki-init` to create one."

## 2. Read the vault schema

Read `<vault>/CLAUDE.md` in full. The linter needs the schema to know what
required frontmatter fields to check for each page type.

## 3. Dispatch wiki-linter

Invoke the **wiki-linter** agent with:

- Vault path: `<vault>`
- Vault schema: contents of `CLAUDE.md` (pass as context)

The linter will check for:
- Orphaned pages (no inbound wikilinks from any other page)
- Broken wikilinks (references to pages that don't exist on disk)
- Missing required frontmatter fields (per page type in CLAUDE.md)
- Stale `last_updated` fields (pages not updated in over 90 days while
  related sources have been ingested more recently)
- Index gaps (pages on disk not listed in `index.md`)
- Schema violations (page type not recognized by CLAUDE.md)
- Knowledge gaps (important concepts mentioned across pages but lacking
  their own page)

## 4. Present findings

The linter returns a severity-labeled report:

- **Critical** — data loss or corruption risk (e.g., a page referenced
  everywhere but missing from disk)
- **High** — structural problems that degrade query quality (orphans,
  broken links, index gaps)
- **Medium** — schema drift, missing frontmatter, stale dates
- **Low** — advisory (knowledge gaps, suggested new pages)

For each finding, the linter cites the specific file and the nature of the
problem.

## 5. Offer schema proposals

If the linter identifies patterns that suggest the schema needs updating (e.g.,
a field that appears ad-hoc across many pages but isn't in CLAUDE.md), it will
describe the proposed addition. Remind the user: "The linter never edits
`CLAUDE.md` — if you'd like to adopt this, edit it manually."

## 6. Append log entry

Append to `log.md`:
`## [<ISO-8601-datetime>] lint | <n> findings (C:<x> H:<y> M:<z> L:<w>)`

## Gotchas

- **Linter is advisory, not prescriptive:** The user decides what to fix.
  Do not automatically repair broken links or orphaned pages. Surfacing is
  the job.
- **Orphan detection requires reading all pages:** On large wikis this can
  be slow. Let the user know if the vault has many pages and confirm before
  proceeding.
- **Index gap vs. true orphan:** A page missing from `index.md` but linked
  from other pages is an index gap (High). A page missing from `index.md`
  AND unlinked from other pages is both an index gap and an orphan — report
  both.
- **Stale dates are advisory:** `last_updated` staleness is context-dependent.
  A destination page for a place the user researched two years ago and still
  plans to visit is not necessarily stale — use judgment and label it Low.
- **CLAUDE.md itself:** If CLAUDE.md has no page types defined (generic
  template), the linter cannot check frontmatter. Report this as a Low
  finding and suggest co-evolving the schema via `/wiki-ingest`.
