**Date:** 2026-08-05
**Type:** known-issue
**Status:** active
**Discovered:** 2026-08-05
**Scope:** every `az` invocation from this pack on Windows — and any other native target that resolves to a
`.cmd` or `.bat` file
**Overrides-convention:** no
**Related-to:** 2026-07-30-powershell-mangles-native-exe-arguments.md, 2026-08-05-ado-node-name-restrictions-are-ui-only.md, 2026-08-04-az-query-and-json-parse-hazards-on-windows.md

## Summary

**`az` on Windows is `az.cmd`, a batch file — so `cmd.exe` re-parses every argument after PowerShell is
done with it.** `(Get-Command az).Source` returns
`C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd` on this machine. A batch file has no argument
vector: whatever PowerShell produced is handed over as **text**, and `cmd.exe` applies its own
metacharacter rules to it. **Correct PowerShell quoting does not survive this layer, and neither does
discrete-argument passing.**

Verified by execution 2026-08-05. **Two channels, and they have different trigger conditions — the
distinction is the whole practical content of this file.**

**Channel 1 — `%` expansion. Unconditional.** Confirmed against the **real `az.cmd`**: a read-only WIQL
query carrying `'Zz%USERNAME%Probe'` returned `TF51011: The specified area path does not exist. The error
is caused by 'Zz<username>Probe'`. Azure DevOps echoed the **expanded** value — the placeholder here stands
for the machine's actual account name, which is what came back — so the expansion happened
before `az` transmitted anything. It occurs whether or not the argument is quoted, and a single-quoted
PowerShell literal does not prevent it.

**Channel 2 — `;` `&` `^` `<` `>`. Only when the argument reaches `cmd.exe` unquoted.** Measured by
passing bare values to a `.cmd` target through the `&` call operator:

| Value in the PowerShell literal | What the batch file received |
|---|---|
| `Proj\A^B\Node` | `Proj\AB\Node` — **caret consumed as an escape** |
| `Proj\A;B\Node` | `Proj\A` — **argument truncated at the separator** |
| `Proj\A&B\Node` | `Proj\A` — **argument truncated at the separator** |
| `Proj\<x>\Node` | invocation failed, *"The system cannot find the file specified"* — **`<`/`>` taken as redirection** |
| `` Proj\A`B\Node ``, `Proj\A$B\Node`, `Proj\A'B\Node`, `Proj\A (B)\Node` | unchanged |

**PowerShell auto-quotes an argument containing a space, which suppresses channel 2 — and that is a
horrifying thing to depend on.** The same five characters passed through the real `az` inside a `--wiql`
value (which always contains spaces, so it is always quoted) arrived **intact**. So whether the hazard
fires depends on whether the value happens to contain a space: `Proj\Data Engineering\X` is quoted and
safe, `Proj\A;B` is not quoted and is truncated. **A control that holds only for values containing a
space is not a control.** An earlier draft of this file reported channel 2 as unconditional; that was
measured on bare arguments only and overstated it.

**Not measurable by the WIQL oracle:** a value containing `'` fails at Azure DevOps's **own** WIQL parser
(*"Expecting closing quote"*) identically on both invocation paths, so it says nothing about either shell
layer. That is the separate, already-documented WIQL quote hazard.

## The fix that exists on this machine

**`az` ships a real `python.exe` beside the shim** — `C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe`
— and `python.exe -m azure.cli <args>` reaches the **same CLI (2.88.0)** with **no `cmd.exe` layer at all**.
Verified 2026-08-05 with the same payload that expands through the shim: `Zz%USERNAME%Probe` arrived
**intact**, echoed verbatim by `TF51011`.

| Payload | via `az.cmd` | via `python.exe -m azure.cli` |
|---|---|---|
| `Zz%USERNAME%Probe` | `Zz<username>Probe` — **expanded** | `Zz%USERNAME%Probe` — intact |
| `ZzA^BProbe`, `ZzA;BProbe`, `ZzA&BProbe`, `` ZzA`BProbe ``, `ZzA (B)Probe` | intact *(quoted — see channel 2)* | intact |

**This is the preferred fix: it removes both channels at once and rejects nothing**, so it costs no
legitimate value the service accepts.

This is the **BatBadBut** class (CVE-2024-27980, CVSS 8.1): argument injection into `.bat`/`.cmd` targets
that survives argument-vector discipline, because the target has no argument vector.

## Why it is dangerous rather than merely annoying

**A single-quoted PowerShell literal is the standard advice for neutralising `` ` ``, `$` and `;`, and it
is correct — at the PowerShell layer only.** So the mitigation looks right, tests clean against
PowerShell's own parser, and still fails. Three of the altered characters are **not** in Azure DevOps's
UI-restricted set for area and iteration node names — `%`, `^` and `;` are all typeable by an ordinary
project member with no elevated rights — so a legitimately-named node reaches a truncated or rewritten
command with no attacker and no privilege bypass involved.

`%` is the worst of them: expansion is **silent**, produces a plausible-looking value, and leaks the
expanding environment's contents into whatever the command does with it.

## Workaround

**None of these is free, and the choice is a design decision rather than a patch:**

- **Do not rely on quoting to make an arbitrary value safe through a `.cmd` target.** State which layer a
  quoting rule protects. A rule that says "single-quoted, therefore safe" is wrong on Windows for any
  batch-file entry point.
- **Prefer an invocation path that avoids the reparse** where one exists — the underlying Python entry
  point rather than the `.cmd` shim, or a REST call.
- **If the value must cross the batch layer, a sink-justified stop list is the honest fallback** — `%`,
  `^`, `;`, `&`, `<`, `>` — justified by `cmd.exe`'s parser and **not** by the target service's naming
  rules. Note the cost plainly: it rejects values the service accepts, and where the value names something
  the operator does not own (an area path in someone else's project) that stop is **not remediable by
  them**.
- **Escaping for this layer is fiddly and not recommended as a first resort** — `%` needs doubling in some
  contexts and not others, and `^` interacts with the same pass.

**The general lesson, and it is the third instance of this shape in this repo: a control must name the
layer it defends.** `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md` records
PowerShell silently rewriting native arguments; this file records `cmd.exe` rewriting them again one layer
down. Both defeat mitigations that are individually correct.

## How it was found

`skills/devops-azure/SKILL.md` gained two new `az` arguments (`--area`, `--iteration`) carrying
service-sourced path values, with a specified sink discipline of "single-quoted PowerShell literal with
`'` doubled". A security review of that passage raised the batch-file reparse as an unconsidered layer;
the table above is the execution that confirmed it. **The passage's stated claim that the literal
"neutralises `` ` ``, `$` and `;`" is false for `;`.** Recorded in
`docs/plans/devops-azure-area-iteration-placement.md`.
