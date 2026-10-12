# tech-lead memory writes

Read by `tech-lead` **when it is about to write a memory file**: the subdirectory routing, the required
frontmatter and sections, how to supersede a prior file, and the Obsidian sync request it emits afterwards.
These rules are `tech-lead`'s own -- `devils-advocate` has its own table and uses a different filename prefix.

Write memory files to the appropriate subdirectory based on content type.
Use the filename format `YYYY-MM-DD-{prefix}-brief-slug.md`.

### When to write and where

| Subdirectory | Prefix | Write when |
|---|---|---|
| `memory/decisions/` | `decision-` | The plan involves a new pattern not already in the codebase, OR a technology/library choice is made |
| `memory/architecture/` | `arch-` | The plan will alter module boundaries, change data flow between components, add/remove a subsystem, or change integration patterns |
| `memory/context/` | `context-` | A platform quirk, tooling constraint, or environment-specific behavior is discovered during planning that would surprise a future reader |
| `memory/known-issues/` | `known-issue-` | A workaround is planned rather than a proper fix, a limitation is accepted, or a constraint forces a suboptimal approach |

Write to multiple subdirectories when a single planning session produces findings of different types. Each file stands alone -- do not combine different types into one file.

### Required frontmatter fields

```yaml
---
date: YYYY-MM-DD
type: decision | finding | constraint | pattern
status: active
superseded-by: n/a
scope: global | [specific module or path]
overrides-convention: yes | no
related-to: n/a | [comma-separated filenames]
---
```

Fenced lowercase YAML, `---` on line 1 and closed. Extra keys are permitted, so add
`discovered:` or another sanctioned extra where it carries a real fact.
`docs/MEMORY-WRITING.md` is the authority.

### Required sections by subdirectory

- **decisions/**: Summary, Context, Rationale, Alternatives Rejected, Implications, and (when Overrides-convention is yes) Convention Override Rationale
- **architecture/**: Summary, Components, Data Flow, Implications
- **context/**: Summary, Discovery Context, Impact, Workaround (if applicable)
- **known-issues/**: Summary, Symptoms, Root Cause (if known), Workaround, Revisit Trigger

### Superseding prior files

When superseding a prior decision: update the old file's `status` to `superseded` and populate its `superseded-by` field in the same operation as writing the new file.

If the decision deviates from CONVENTIONS.md for a specific scope, set `overrides-convention: yes` and document which convention is overridden and why it does not apply in this scope.

Direct all dispatched agents to check `memory/**/*.md` before acting, filtering by status.

### Obsidian sync request

You cannot reach the Obsidian vault yourself: your tool grant includes neither
`Bash` (to read `OBSIDIAN_VAULT_PATH`) nor `Agent` (to dispatch obsidian-writer).
Consistent with "you do not dispatch agents yourself," surface the request instead.

After writing any memory file to `./memory/`, emit this as the final section of your
output — one line per file written:

```
## Obsidian sync request
- `memory/<subdir>/<filename>.md` — <the file's frontmatter description, or its filename>
```

Emit the section whenever you wrote at least one memory file; omit it entirely when
you wrote none. Do not try to determine whether `OBSIDIAN_VAULT_PATH` is set — the
calling session gates on that and skips the dispatch silently when it is unset.

The calling session dispatches **obsidian-writer** with `write_mode: capture`, the
title and body read from each listed file, and the remaining fields (`vault_path`,
`projects_folder`, `project`, `timestamp`) resolved from its own
environment. If the sync never happens, nothing is lost — the project's `memory/` file
is the authoritative record.

