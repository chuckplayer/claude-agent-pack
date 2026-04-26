---
name: wiki-query
description: >
  Ask a question against an existing LLM wiki vault. The LLM reads the index,
  drills into relevant pages, and synthesizes an answer with citations. Offers
  to file valuable answers back as new synthesis pages. Use when someone says
  "ask my wiki", "what does my wiki say about X", "search my wiki", "wiki
  query", "what have I learned about X", "find everything about X in my wiki",
  "compare X and Y from my notes". Do NOT use for adding new sources — use
  /wiki-ingest instead.
---

# Wiki Query

Ask a question against the wiki. The librarian reads the index, drills into
relevant pages, and synthesizes an answer with citations. Valuable answers
can be filed back as new synthesis pages — making your explorations compound
in the knowledge base just like ingested sources do.

## 1. Resolve the vault

Check `~/.claude/wiki/` for existing vaults (directories containing a
`CLAUDE.md`):

- **One vault found:** Use it. Confirm: "Using vault at `<path>`. What's your
  question?"
- **Multiple vaults found:** List them and ask which to use.
- **No vaults found:** "No wiki vault found. Run `/wiki-init` to create one,
  then `/wiki-ingest` to add sources."

## 2. Read the vault schema

Read `<vault>/CLAUDE.md` in full. This establishes domain context, page types,
and cross-reference conventions before the librarian begins.

## 3. Capture the question

Ask the user for their question if they haven't provided it yet. Any question
form is valid:

- Factual: "What visa do I need for Thailand?"
- Comparative: "Which is better for a first trip — Chiang Mai or Bangkok?"
- Synthesis: "What are the best budget destinations I've researched so far?"
- Open-ended: "What don't I know yet about SE Asia travel?"

## 4. Dispatch wiki-librarian

Invoke the **wiki-librarian** agent with:

- Vault path: `<vault>`
- Question: the user's question
- Vault schema: contents of `CLAUDE.md` (pass as context)

The librarian will:
1. Read `index.md` to locate relevant pages
2. Read those pages in full
3. Synthesize an answer with citations to specific wiki pages
4. Note any gaps — questions the wiki cannot yet answer

## 5. Offer to file back

After the librarian responds, ask:

> "Would you like me to file this answer back into the wiki as a synthesis
> page? It will be saved under `wiki/synthesis/` and added to the index."

If yes, have the librarian create the synthesis page with the appropriate
frontmatter and update `index.md` and `log.md`:
`## [<ISO-8601-datetime>] file-back | <synthesis title>`

If no, the answer remains in the conversation only.

## 6. Append query log entry

Regardless of whether the answer is filed back, append to `log.md`:
`## [<ISO-8601-datetime>] query | <question summary>`

## Gotchas

- **Wiki is sparse:** If `index.md` is nearly empty, the librarian will say so
  honestly. Do not hallucinate sources. Tell the user what's missing and
  suggest ingesting more sources first.
- **File-back creates a new page, not an edit:** Filing back a query result
  never overwrites an existing wiki page. It always creates a new
  `wiki/synthesis/<slug>.md`. If a similar synthesis already exists, the
  librarian should note it and offer to update the existing page instead.
- **Gaps are valuable output:** When the librarian identifies a knowledge gap
  ("the wiki has no information on visa requirements for Vietnam"), surface
  this clearly — it tells the user what to ingest next.
- **Circular queries:** If the user asks a question whose answer is itself
  a query result that was just filed back, that's fine — the librarian will
  find it in the index on the next query.
