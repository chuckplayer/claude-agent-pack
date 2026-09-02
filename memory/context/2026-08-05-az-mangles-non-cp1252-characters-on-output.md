---
date: 2026-08-05
type: platform quirk
status: active
superseded-by: n/a
scope: any code path that compares, matches, or parses a string printed by `az` on this machine — **and,
  per the section at the end, any checker whose own source text contains a non-cp1252 literal**
overrides-convention: no
related-to: memory/known-issues/2026-08-04-ado-backlog-level-is-not-work-item-type-category.md, memory/context/2026-08-04-az-query-and-json-parse-hazards-on-windows.md
---

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

## It also bites the checker's own source text, not only `az` output

**Found 2026-08-05 while mechanising an acceptance bar.** The bar admitted `…` (`U+2026`) as a legal token,
and a PowerShell checker holding that character as a **literal in its own source** reported the token as
**unadmitted** — the comparison failed because the literal was mangled between the script file and the
interpreter, not because the subject was wrong. Building the character from its **codepoint** fixed it:

```powershell
$ELL = [char]0x2026          # reliable
$bad  = @('…')               # mangles between file and interpreter on this machine
```

**Why this is the same hazard rather than a new one, and why it is worse:** the mechanism above corrupts a
value on its way *out of* `az`, so a comparison fails and the subject looks defective. Here the corruption
happens on the way *into the comparison*, from the checker's own file — so a **correct** subject is reported
as violating, and every instinct points at the subject. The instrument fails in a way indistinguishable from
the thing it measures being broken, which is the shape of the `--query` false negative in
[[2026-08-04-az-query-and-json-parse-hazards-on-windows]] and of the `grep -iF` abort in
[[2026-08-04-grep-iF-aborts-on-this-machine]].

**Workaround:** in any checker on this machine, express a non-ASCII literal as a **codepoint**, never as a
character in the source. Where a check reports that a *correct* value is non-compliant, **suspect the
checker's encoding before the value** — the same rule those two files already state for an unexpected
negative, extended to the checker's own text.
