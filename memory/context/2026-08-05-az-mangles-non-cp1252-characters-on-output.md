**Date:** 2026-08-05
**Type:** platform quirk
**Status:** active
**Superseded-by:** n/a
**Scope:** any code path that compares, matches, or parses a string printed by `az` on this machine
**Overrides-convention:** no
**Related-to:** memory/known-issues/2026-08-04-ado-backlog-level-is-not-work-item-type-category.md, memory/context/2026-08-04-az-query-and-json-parse-hazards-on-windows.md

## Summary

`az` on this machine cannot encode non-cp1252 characters on **output**. It replaces them, sometimes
emitting *"Unable to encode the output with cp1252 encoding. Unsupported characters are discarded"* and
sometimes emitting nothing at all while substituting `U+FFFD`. **The value in Azure DevOps is
unaffected** — only what reaches the console is mangled.

That combination is the hazard: a write succeeds, the service stores the character correctly, and a
read-back **appears to prove the write was corrupted**. Any check that compares a string it wrote
against a string `az` printed will report a mismatch that does not exist.

## What was executed

2026-08-05, `<org>/<project-b>`, during a 120-item batch write. Three work item titles contained an
em dash (`U+2014`) inside the title text. All three were created successfully.

| Read path | What the title looked like |
|---|---|
| `az boards query ... -o json` | `...documentation <U+FFFD> this direction is explicit...` |
| `Invoke-RestMethod` with a bearer token, same items | `...documentation — this direction is explicit...` |

Counted by code point over the REST response: `U+FFFD` **0**, `U+2014` **1**, on each of the three
items. So the titles are intact in the service and the mangling is entirely on `az`'s output side.

The earlier record of this quirk is an aside in
`memory/known-issues/2026-08-04-ado-backlog-level-is-not-work-item-type-category.md`, scoped to **team
names** because that is where it was first seen. **The scope is wider than that** — it is any string
`az` prints, which includes every title, description, tag, area path, and iteration path the pack
compares.

## Impact

- **`skills/devops-azure/SKILL.md` 8d's title-divergence line produces false positives on this
  machine.** That line exists as "the cheapest available signal that a matched key belongs to an item
  the tree does not mean", and it fires on any title containing a character outside cp1252 — an em
  dash, a curly quote, an accented name. A signal that cries wolf on ordinary punctuation trains an
  operator to skip the one line meant to catch a mismatched join. It was observed firing on 3 of 95
  reconciled items, all benign.
- **A read-back comparison is not evidence about a write** unless the read path is UTF-8 safe. This is
  the same shape as the `--query` projection hazard already recorded: absent or altered output is
  evidence about the *read*, not about the stored value.
- **It does not affect the tag round-trip probe as currently written**, because `8b`'s two regexes admit
  no non-ASCII character into a `feature:` slug or an item id, so a key tag is always pure ASCII. That
  is luck rather than design, and it is worth knowing the probe is safe only for that reason.

## Workaround

Read the value over a UTF-8-safe path before comparing it. Either call the REST endpoint directly with
a token from `az account get-access-token` and `Invoke-RestMethod`, or set the console to UTF-8 for the
duration of the read. **Do not "fix" a mismatch by rewriting the stored value** — the stored value is
already correct, and a write issued to repair a phantom mismatch is a real change made on false
evidence.
