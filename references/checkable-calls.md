# Checkable calls

The single authority on what counts as a **checkable call** in a plan's `## Calls made for you`. Read by
`tech-lead` when it writes the calls, so that each one names something a later stage can look up, and by
`merge-reviewer` when it applies Tier 3 of the plan gate (`plan-gate.md`), which verifies stated calls against
what shipped. It is a separate small file so that `tech-lead` does not read the whole plan gate for a
definition of about two kilobytes. Do not restate it elsewhere: a second description is a second thing to keep
in sync, and it will lose.

**This is the single authority on what counts as a checkable call.** Do not restate the lists below
in another file; point at this section instead.

A call is **checkable** when it names one thing you can look up:

- a named dependency, library, tool, or runner
- a named file or directory path
- a named type, function, or endpoint
- a specific numeric or enumerated value
- an explicit will/won't about one of the above

**Permanently out of scope**, because none of these yields a lookup target: adjectives and quality
claims ("keep it maintainable", "prefer clarity"), effort estimates, motivations, risk narration,
sequencing intent — and **pattern names**.

Pattern names are the exception worth explaining, because they look checkable and are not. "Use the
repository pattern for data access" names a *pattern*, not an artifact: there is no single thing to
look up, and whether a given `DbContext` reference violates it is an architecture judgment with
legitimate readings on both sides — a read-only projection, a bulk operation, a half-finished
refactor. **That judgment already has an owner, and it is not you.** `code-reviewer` reads
`docs/CONVENTIONS.md` and reviews pattern compliance, `smell-reviewer` catches the structural form,
both run earlier, and a code-reviewer Critical already blocks. Adjudicating it again here would be a
second and worse ruling on a question answered upstream — made by the only agent holding `Bash` and
the commit.

The same intent written falsifiably *is* in scope, and the difference is entirely in the writing:

> "All order data access goes through `IOrderRepository`. No `DbContext` reference outside
> `Infrastructure/Repositories/`."

That names a type and a directory boundary, so it can be looked up and contradicted.
