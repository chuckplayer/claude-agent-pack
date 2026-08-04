**Date:** 2026-08-04
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** every `az` invocation from PowerShell on this machine — skills/devops-azure, skills/review-pr, and any script shelling out to the Azure CLI
**Overrides-convention:** no
**Related-to:** 2026-07-30-powershell-mangles-native-exe-arguments.md, 2026-08-03-powershell-convertfrom-json-array-double-wraps.md, 2026-07-10-bash-tool-silent-failure-windows.md, 2026-08-04-ado-backlog-level-is-not-work-item-type-category.md

## Summary

**`--query` is not safely usable from PowerShell on this machine, and the failure mode differs by which
character it contains.** Three distinct breakages, all found by execution 2026-08-04 while running a real
36-item batch write. The first attempt **failed at item 1 with zero items created**, which is the only
reason this is a note rather than a cleanup.

| In the `--query` value | What happens | Verdict |
|---|---|---|
| A **double quote** — e.g. `{id:id, title:fields."System.Title"}` | PowerShell destroys it at the native-command boundary. `az` received `'{id:id, title:fields." System.Title\\,'` and exited **2** | **unusable** |
| **Parentheses** — e.g. `keys(@)`, `length(value)` | The `az.cmd` shim re-parses the line, and `cmd` treats `(` specially. Observed: `--output was unexpected at this time`, with the whole rewritten command echoed, exit **255** | **unusable** |
| **Brackets and dots only** — e.g. `value[].name`, `value[0].id` | Works. Returned 278 bytes and parsed cleanly | **safe** |

So the usable subset is **bracket-and-dot paths with no quotes and no parentheses**. Anything needing a
quoted identifier (any ADO field name, since they all contain dots) or a JMESPath function is out.

## The parse hazard that makes `--query` tempting in the first place

**`ConvertFrom-Json` on PowerShell 5.1 fails on the `workitemtypes` response**, which is ~750 KB for a
17-type project because each type carries a full `fieldInstances` array. The error is:

```
ConvertFrom-Json : Cannot process argument because the value of argument "name" is not valid.
```

**That message names an argument called "name" and looks like a bad parameter. It is a size limit.** The
read itself succeeded — exit 0, 747 KB, `"count": 17` visible in the first 200 characters. Writing the
output to a file and using `Get-Content -Raw` fails identically, so it is the parser and not the pipeline.

**Two mitigations, and the choice depends on the response:**

- **A single work item is ~4 KB and parses fine.** Use plain `--output json` and read fields with
  `$o.fields.'System.Title'`. This is the right answer for creates, shows, and anything item-scoped —
  no `--query` needed, so none of the three breakages above apply.
- **For a large list**, `--query` with a bracket-and-dot path is the only route that works
  (`value[].name`), because it is the one form PowerShell and `cmd` both leave intact.

## Why this is a fourth entry in a family and not a restatement

This repo already documents native-argument mangling and the `ConvertFrom-Json` array double-wrap. Both
of those **also fired during the same run** — the double-wrap reported `rows returned: 1` for a query that
had returned 36 — so the value here is the *specific* new facts: that `--query` has **two different**
failure modes with different causes, that brackets survive while parentheses do not, and that the
size-limit error message points at a nonexistent parameter.

**The common lesson across all four is the one already on record:** every one of these fails in a way that
looks like a legitimate empty or small result rather than an error. `types defined: 0` was printed for a
project with 17 types, because `2>$null` hid an exit 2 from a **command that does not exist** —
`az boards work-item type list` is not a valid command, and the correct route is
`az devops invoke --area wit --resource workitemtypes`.

## Workaround

1. **Do not use `--query` for field projection.** Parse item-scoped responses directly.
2. **Never suppress stderr on an `az` call you are about to draw a conclusion from.** `2>$null` turned a
   nonexistent command into "zero types".
3. **Check `$LASTEXITCODE`, never `$?`**, and treat blank output as `UNKNOWN`.
4. **Give every count a positive control.** A parser that matched zero items reported "all ids pass" during
   this run; the control is what turned that into a visible failure.
