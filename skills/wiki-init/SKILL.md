---
name: wiki-init
description: >
  Initialize a new LLM-maintained wiki vault for a knowledge domain. Use when
  starting a new wiki, or when someone says "start a wiki", "create a wiki
  vault", "set up my wiki", "wiki init", "initialize wiki for <domain>",
  "new wiki for vacation", "create my vacation wiki". Also use when
  /wiki-ingest or /wiki-query report that no vault exists. Do NOT use for
  adding sources to an existing vault — use /wiki-ingest instead.
---

# Wiki Init

Bootstrap a new wiki vault for a knowledge domain. The vault is an
Obsidian-compatible directory of markdown files outside the pack repo.
It is also a git repo — version history is free.

## 1. Collect domain and path

Ask the user:

1. **Domain name** — a short slug (e.g., `vacation`, `research`, `cooking`).
   This becomes the vault directory name.
2. **Vault location** — default is `~/.claude/wiki/<domain>/`. Confirm or
   let them specify an alternative.

If a vault already exists at that path, stop and ask: "A vault already exists
at `<path>`. Use `/wiki-ingest` to add sources, or `/wiki-lint` to check its
health. Did you mean a different path?"

## 2. Create the directory structure

Run the following bash commands (substitute `<vault>` with the resolved path):

```bash
mkdir -p <vault>/{raw/assets,wiki/{entity,concept,source,comparison,synthesis}}
```

## 3. Write CLAUDE.md

Write the domain schema to `<vault>/CLAUDE.md`. Use the appropriate template:

### Vacation domain template

Write this content verbatim to `<vault>/CLAUDE.md`, replacing `<date>` with
today's date in YYYY-MM-DD format:

```markdown
# Wiki Schema: Vacation Planning

**Domain:** vacation
**Created:** <date>
**Co-evolve this file:** The LLM proposes schema changes; you edit manually to accept.

## Iron Rule

The LLM **never** modifies files in `raw/`. Raw sources are immutable.
All LLM writes go to `wiki/` only. If asked to edit a file in `raw/`,
refuse and explain why.

## Directory Structure

    raw/                 ← your sources (immutable, LLM read-only)
      assets/            ← downloaded images, PDFs
    wiki/
      entity/            ← destinations, accommodations
      concept/           ← itineraries, tips
      source/            ← trip reports
      comparison/        ← side-by-side analyses
      synthesis/         ← rolling summaries and thesis pages
    index.md             ← full catalog (ingestor maintains, do not edit manually)
    log.md               ← append-only operation history

## Page Types and Required Frontmatter

### entity/destination
File: `wiki/entity/<slug>.md` (slug: kebab-case, e.g., `chiang-mai`)

    ---
    type: entity/destination
    name: ""
    region: ""
    country: ""
    best_seasons: []
    visa_required: false
    cost_tier: mid          # budget | mid | luxury
    attractions: []
    tags: []
    last_updated: YYYY-MM-DD
    ---

### entity/accommodation
File: `wiki/entity/<slug>.md`

    ---
    type: entity/accommodation
    name: ""
    location_ref: "[[Destination Name]]"
    price_range: ""         # e.g., "$80-120/night"
    booking_source: ""
    pros: []
    cons: []
    rating: null            # 1-5 or null
    tags: []
    last_updated: YYYY-MM-DD
    ---

### concept/itinerary
File: `wiki/concept/<slug>.md`

    ---
    type: concept/itinerary
    title: ""
    destinations: []        # list of [[Wikilinks]]
    duration_days: null
    dates_planned: ""       # YYYY-MM-DD or range
    status: planned         # planned | active | completed
    tags: []
    last_updated: YYYY-MM-DD
    ---

### concept/tip
File: `wiki/concept/<slug>.md`

    ---
    type: concept/tip
    title: ""
    category: ""            # packing | hacks | health | safety | transport
    applies_to: []          # [[Wikilinks]] to regions or destinations
    tags: []
    last_updated: YYYY-MM-DD
    ---

### source/trip-report
File: `wiki/source/<slug>.md`

    ---
    type: source/trip-report
    title: ""
    trip_dates: ""
    destinations: []        # list of [[Wikilinks]]
    source_type: notes      # notes | conversation | external
    source_path: ""         # path in raw/ or "conversation"
    ingested_on: ""         # YYYY-MM-DDThh:mm
    ---

### comparison
File: `wiki/comparison/<slug>.md`

    ---
    type: comparison
    title: ""
    comparing: []           # list of [[Wikilinks]]
    criteria: []
    verdict: ""
    last_updated: YYYY-MM-DD
    ---

### synthesis
File: `wiki/synthesis/<slug>.md`

    ---
    type: synthesis
    title: ""
    question: ""
    source_pages: []        # list of [[Wikilinks]]
    conclusion: ""
    last_updated: YYYY-MM-DD
    ---

## Cross-Reference Format

Use Obsidian wikilinks: `[[Page Name]]`
The display name matches the page's `name` or `title` field value.
Do not use standard markdown links `[text](path)` for internal references.
Wikilinks render as plain text outside Obsidian — this is an accepted limitation.

## index.md Ownership

The wiki-ingestor agent is the sole owner of `index.md`.
It updates the index on every ingest. Do not edit index.md manually.
The index format:

    # Wiki Index

    ## Entities
    - [[Chiang Mai]] — destination, Thailand, budget-mid, updated 2026-04-26

    ## Concepts
    - [[2-Week SE Asia Itinerary]] — planned, 14 days

    ## Sources
    - [[Thailand Trip Report 2025]] — ingested 2026-04-26

    ## Comparisons & Synthesis
    - [[Chiang Mai vs Chiang Rai]] — destinations compared

## log.md Format

Each entry: `## [YYYY-MM-DDThh:mm] <op> | <title>`
Operations: `ingest`, `query`, `lint`, `file-back`
Parseable: `grep "^## \[" log.md | tail -10`

## Schema Co-Evolution

This schema is a starter. When the LLM identifies a gap (missing field,
new page type needed, convention to clarify), it will describe the proposed
change and stop. Edit this file manually to accept the change.
```

### Other domains

For any domain other than `vacation`, write a generic `CLAUDE.md` with the
same iron rule, directory structure, log format, and index format sections,
but leave the Page Types section as:

```markdown
## Page Types

No page types defined yet. The LLM will propose types as you ingest sources.
Accept proposals by editing this file.
```

Then tell the user: "I've initialized a generic vault for `<domain>`. As you
ingest your first sources, we'll define the page types together and add them
to `CLAUDE.md`."

## 4. Write index.md and log.md

Write `<vault>/index.md`:

```markdown
# Wiki Index

*No pages yet. Run `/wiki-ingest` to add your first source.*
```

Write `<vault>/log.md`:

```markdown
# Wiki Log

```

Then append the init entry:

```
## [<ISO-8601-datetime>] init | <domain> vault created
```

## 5. Initialize git

```bash
cd <vault> && git init && git add . && git commit -m "init: bootstrap <domain> wiki vault"
```

## 6. Confirm

Tell the user:

- Vault created at `<path>`
- Domain schema written to `CLAUDE.md`
- Git initialized
- Next step: drop sources into `<path>/raw/` and run `/wiki-ingest`

Remind them: "Raw sources are immutable — the LLM never modifies files in
`raw/`. You can optionally run `chmod -R a-w <path>/raw/` for filesystem-level
enforcement."

## Gotchas

- **Vault already exists:** Always check before creating. If it exists, do
  not overwrite — route the user to the correct skill.
- **Domain slug has spaces or uppercase:** Normalize to lowercase kebab-case
  before creating the directory (e.g., "My Vacation" → `my-vacation`).
- **git not available:** If `git init` fails, skip it silently and note that
  version history will not be available. Do not block vault creation.
- **Other domains:** Do not invent a domain-specific schema for unknown
  domains. Use the generic template and co-evolve. The vacation schema took
  iteration — new domains should too.
