# Memory File Format and Conventions

Agents that write to `memory/` must follow this spec. Read this before writing any memory file.

## Filename format

```
YYYY-MM-DD-{prefix}-brief-slug.md
```

The prefix is determined by the agent's subdirectory routing table (see each agent's own instructions for which prefix applies to which situation).

## Subdirectory taxonomy

| Subdirectory | Purpose |
|---|---|
| `memory/decisions/` | Architectural and design decisions with rationale |
| `memory/architecture/` | Module boundaries, data flow, and integration patterns |
| `memory/context/` | Environmental constraints, platform quirks, tooling workarounds |
| `memory/known-issues/` | Bugs, limitations, and workarounds that remain unresolved |

## Required frontmatter fields

Every memory file must open with these fields:

```
**Date:** YYYY-MM-DD
**Type:** decision | finding | constraint | pattern
**Status:** active
**Superseded-by:** n/a
**Scope:** global | [specific module or path]
**Overrides-convention:** yes | no
**Related-to:** n/a | [comma-separated filenames]
```

## General principles

- Write to multiple subdirectories when a single session produces findings of different types. Each file stands alone -- do not combine different types into one file.
- If the content deviates from CONVENTIONS.md for a specific scope, set `Overrides-convention: yes` and document which convention is overridden and why it does not apply in this scope.

## Superseding a prior file

When a new decision supersedes an old one, update the old file's `status` to `superseded` and populate its `Superseded-by` field in the same operation as writing the new file.

## Precedence rules

- Active files without `Overrides-convention: yes` rank below CONVENTIONS.md and above agent defaults.
- Active files with `Overrides-convention: yes` rank above CONVENTIONS.md, but only within their declared Scope.
- Narrower scope wins over broader scope when two files conflict.
- When two active files conflict at the same scope, flag the conflict -- do not pick one silently.
