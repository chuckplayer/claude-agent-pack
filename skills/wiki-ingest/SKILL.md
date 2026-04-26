---
name: wiki-ingest
description: >
  Add a source document to an existing LLM wiki vault. The LLM reads the
  source, creates or updates relevant wiki pages, and keeps the index current.
  Use when someone says "ingest this", "add this to my wiki", "process this
  source", "read this article into my wiki", "add these notes to my wiki",
  "file this trip report", "add this to vacation wiki". Requires an existing
  vault — run /wiki-init first if none exists. Do NOT use for querying the
  wiki — use /wiki-query instead.
---

# Wiki Ingest

Read a source and integrate its knowledge into an existing wiki vault.
A single ingest typically touches 5-15 wiki pages: a new source summary,
updated entity and concept pages, and a refreshed index.

## 1. Resolve the vault

Check `~/.claude/wiki/` for existing vaults (directories containing a
`CLAUDE.md`):

- **One vault found:** Use it. Confirm: "Using vault at `<path>`. Proceed?"
- **Multiple vaults found:** List them and ask which to use.
- **No vaults found:** "No wiki vault found. Run `/wiki-init` to create one
  first."

## 2. Read the vault schema

Read `<vault>/CLAUDE.md` in full before proceeding. This resets domain
context and establishes the page types, frontmatter requirements, and
cross-reference conventions for this vault.

## 3. Identify the source

Ask the user for the source. Accepted forms:

- **File path** — a file already in `<vault>/raw/` (preferred)
- **Pasted content** — the user pastes text directly; write it to
  `<vault>/raw/<slug>.md` first, then ingest
- **URL clip** — the user pastes a clipped article (e.g., from Obsidian
  Web Clipper); write to `<vault>/raw/<slug>.md` first, then ingest

Always confirm the source is in or will be placed in `raw/` before reading.

## 4. Dispatch wiki-ingestor

Invoke the **wiki-ingestor** agent with:

- Vault path: `<vault>`
- Source path: the resolved file in `raw/`
- Vault schema: contents of `CLAUDE.md` (pass as context)

The ingestor will:
1. Read the source
2. Discuss key takeaways briefly (a few bullet points)
3. Create or update wiki pages per the schema
4. Update `index.md`
5. Append a log entry: `## [<ISO-8601-datetime>] ingest | <source title>`

## 5. Review

After the ingestor completes, summarize what changed:
- New pages created
- Existing pages updated
- Index entries added
- Log entry appended

Ask: "Would you like to ingest another source, or ask a question with
`/wiki-query`?"

## Gotchas

- **Source not in raw/:** Never read from outside the vault tree. If the
  user provides a source path outside `<vault>/raw/`, copy it in first and
  confirm.
- **Parallel ingests:** Do not run two ingests on the same vault simultaneously.
  `index.md` has a single owner (the ingestor) and concurrent writes will
  conflict. Queue sources one at a time.
- **Large sources:** For very long sources (book chapters, long reports), ask
  the user if they want to ingest the whole thing or a specific section. The
  ingestor works best on focused inputs.
- **Source already ingested:** Check `log.md` before dispatching. If a source
  with the same title appears in the log, ask the user if they want to
  re-ingest (which will update the existing pages) or skip.
- **Schema gap:** If the source introduces concepts that don't fit any existing
  page type, the ingestor will flag it. Do not invent new frontmatter fields
  mid-ingest — propose the addition to the user and ask them to update
  `CLAUDE.md` first.
