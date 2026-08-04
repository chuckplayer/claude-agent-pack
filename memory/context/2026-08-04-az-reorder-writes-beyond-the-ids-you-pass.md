**Date:** 2026-08-04
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** any use of az devops invoke / az rest against Azure DevOps
**Overrides-convention:** no
**Related-to:** 2026-08-04-ado-same-category-nesting-blocks-child-reorder-only.md, 2026-08-03-wiql-tags-contains-is-whole-tag-not-substring.md, 2026-07-30-powershell-mangles-native-exe-arguments.md

## Summary

Two `az`-against-ADO hazards found while executing the board-degradation probe on 2026-08-04. Both
produce a **confident wrong answer rather than an error**, which is the same family as
`[System.Tags] CONTAINS` and `az boards query --wiql` returning blank with exit 0.

## 1. `az devops invoke` silently serves a *sibling* route when the params do not disambiguate

`area=work` registers two resources both named `backlogs`:

```
{project}/{team}/_apis/work/backlogs/{backlogId}/workItems    <- backlog CONTENTS
{project}/{team}/_apis/work/backlogs/{id}                     <- backlog LEVEL metadata
```

Asking for the first — `--resource backlogs --route-parameters project=<project-a> team="<project-a> Team"
backlogId=Microsoft.RequirementCategory` — returned **the levels list** (`count: 4`) with **exit 0**.
No error, no warning, no hint that `backlogId` was ignored.

**Why that is dangerous rather than merely wrong.** The caller reads `.workItems` off the response,
finds the property absent, and gets `count = 0`. On this exact probe that read as *"the backlog is
empty"* — which is indistinguishable from the real finding the probe was looking for ("the nested item
is hidden"). A wrong-route fallback can therefore **manufacture the very result you are testing for.**

**Workaround.** For any sub-resource route, use `az rest` with the URL written out, and the ADO
resource id for the token:

```bash
az rest --method get --resource 499b84ac-1321-427f-aa17-267ca6975798 \
  --url "https://dev.azure.com/<org>/<project>/<team>/_apis/work/backlogs/<backlogId>/workItems?api-version=7.1"
```

**And always positive-control the read** — confirm it returns known-present rows before believing an
absence. `az devops invoke` remains fine where the route is unambiguous.

Incidental: `az devops invoke` with no `--area`/`--resource` dumps the whole resource registry (3694
entries here) and is the way to find a route template — but it prints `Please wait a couple of seconds
while we fetch all required information.` **to stdout, ahead of the JSON**, so it must be stripped
before parsing (`$raw.Substring($raw.IndexOf('['))`).

## 2. The reorder API writes to items you did not name

`PATCH {project}/{team}/_apis/work/workitemsorder` with body `{"ids":[706795],"previousId":..,"nextId":..}`
— **one** id — returned `count: 9` and assigned `Microsoft.VSTS.Common.BacklogPriority` to **every item
on that backlog level that had no order value yet**.

Six unrelated pre-existing items were mutated by a request that named one. Items that already had an
order value kept it, so the behaviour looks like lazy backfill of the order field across the level.

**Impact.** A "reorder one item" call is not a scoped write. On a real project that is a change to
shared backlog ordering state, and it will not appear in any report that tracks only the ids you sent.
`--dry-run` does not exist for this endpoint.

**Workaround.** Capture `BacklogPriority` for the whole backlog level **before** any reorder if you
intend to restore it; the response body's `value` array is the authoritative list of what was actually
written, so read it rather than assuming it matches your `ids`.

## 3. Exit codes on these calls are not trustworthy from PowerShell

A successful reorder returned exit **255** through PowerShell while the mutation demonstrably applied
(verified by re-reading the backlog order). A failed reorder returned exit 1 with the real error only
in stderr. Redirect the two streams to separate files and judge the outcome by **re-reading state**,
not by the exit code:

```powershell
az rest ... > out.txt 2> err.txt
```

This compounds [[2026-07-30-powershell-mangles-native-exe-arguments]]: a URL containing `&` handed to
`az` from PowerShell also fails in a way that surfaces as a JSON parse error on the *output*, not as a
bad-argument error. Prefer a WIQL query (no `&` in the URL) or a request-body file over long query
strings.
