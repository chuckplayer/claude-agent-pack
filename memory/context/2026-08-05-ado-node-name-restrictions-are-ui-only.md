**Date:** 2026-08-05
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** any guard, allowlist or trust decision applied to an Azure DevOps **area path** or
**iteration path** value read from the service and passed to a command
**Overrides-convention:** no
**Related-to:** 2026-07-30-powershell-mangles-native-exe-arguments.md, 2026-08-05-ado-team-backlog-filters-by-iteration-too.md, 2026-08-05-challenge-devops-azure-area-iteration-placement.md

## Summary

**"Read from Azure DevOps, therefore character-constrained" is not a sound premise.** Microsoft's
naming restrictions for area and iteration **node** names are documented as a **UI** rule, and the
same page states plainly that *"when you use the Azure DevOps APIs rather than the user interface, you
can directly specify a name that might include characters restricted in the UI."* So a node name a
read returns may carry characters the UI would have refused.

Two things follow, and they point in opposite directions — which is why both belong in one file.

## The restricted set, and what it does not cover

Node names are documented as excluding Unicode control characters and:

```
\ / : * ? " < > | # $ & * +
```

**What that rules out** — and therefore what a guard must **not** reject, because these are all legal
and ordinary in real area paths: a **space**, `(`, `)`, `'`, `.`, `,`, `;`, `-`, `_`, and non-ASCII
letters. A guard modelled on a title-style rejected-character list stops a batch on the first project
whose area nodes have ordinary names.

**What it does not rule out, and this is the part that matters for a command sink:** the **backtick**
and the **semicolon** are both absent from the list. In PowerShell script text a backtick is the escape
character inside a double-quoted literal (a trailing one before the closing quote escapes it), and `;`
separates statements. Neither is excluded by the UI rule, and per the paragraph above **none** of the
list is guaranteed by the API.

## Why this is a sink question, not a source question

The hazard is where the value **lands**, not where it came from. On this machine an `az` argument
becomes a **literal inside generated script text** before any argument-passing discipline can help —
see `2026-07-30-powershell-mangles-native-exe-arguments.md`, and `skills/devops-azure/SKILL.md` 8f,
which calls discrete-argument passing *"hardening … never a substitute"* and *"a property of the
caller, and this file cannot verify the caller has it"*.

A **legitimate** reason to accept the residual is the **privilege gap**: naming an area node requires
project-admin rights in the target project, where editing a backlog tree requires a text editor. That
is a real difference in threat model. **It is a different argument from "the service constrains the
value", and only the first one is true.** Use it, and name the residual rather than implying none
exists.

## Also verified from the same reference, and worth having recorded

- `--area` and `--iteration` exist on **both** `az boards work-item create` **and** `az boards
  work-item update`, so placement is repairable after the fact even though `--destroy` fails
  `VS402324` and an item id is permanently consumed.
- The published help gives `--area` as *"Area the work item is assigned to (e.g. Demos)"* and
  `--iteration` as *"Iteration path of the work item (e.g. Demos\Iteration 1)"*. **The docs never say
  whether the value is project-rooted or project-relative**, and the examples read either way depending
  on whether `Demos` is the sample project name. **Settled by execution instead — see below. The help
  text is a red herring; do not reason from it.**
- ADO does **not** auto-create classification nodes, so a path that does not resolve is **rejected**
  rather than silently created. That is what makes a wrong-form guess a loud failure rather than a
  quiet one.

## Verified by execution, 2026-08-05

Two live creates, read back with `az boards work-item show`, in two projects:

- **The project-rooted canonical form `<project>\<node>\<leaf>` is accepted and honoured** by both
  `--area` and `--iteration`. Values stored **byte-exact**. **Neither argument is silently ignored.**
- Both values carried **spaces** and multiple backslash-separated segments, were passed as **discrete
  arguments** with no allowlist or rejected-character list, and survived intact. So for these two
  arguments on this machine, discrete passing was sufficient and the predicted PowerShell
  native-argument mangling did not bite. **One observation, not a proof** — it says nothing about a node
  name containing `` ` ``, `;`, `&`, `'`, `(` or a non-cp1252 character, and the cp1252 output hazard is
  documented as real here.
- **`az boards area project create` is REFUSED for this account** — `TF50309`, "Create child nodes" — in
  a project where work-item creation **succeeds**. So any check whose evidence requires constructing an
  area node is **unproducible on this machine** (bar-soundness row 4). Plan for a project that already
  has the nodes rather than for creating them.
- **A second two-form inconsistency, inside one command family:** `az boards area project delete --path`
  takes the **classification** form (`\<project>\Area\<node>`) while `az boards work-item create --area`
  takes the **canonical** form (`<project>\<node>`). **Specify path normalisation per route; never infer
  it from a sibling command.**

## The three path forms, and the transformation between them

**Recorded here because these observations otherwise live only in agent messages and in one plan's
challenge section**, and a merged plan is never retro-edited — see
`2026-07-30-agent-output-must-be-attributable-to-be-evidence.md`. Two projects, zero writes.

| Source | Observed form |
|---|---|
| `az boards area project list` | `\<project>\Area\<node>\<leaf>` — leading separator **and** a classification segment |
| `az boards iteration project list` | `\<project>\Iteration\<node>`, root `\<project>\Iteration` — same shape, segment 2 the literal `Iteration` |
| `teamfieldvalues` (`System.AreaPath` values) | `<project>\<node>\<leaf>` — neither |
| `teamsettings` (`backlogIteration.path`) | `\<node>`; empty string means the project root |

**The two `project list` routes are symmetric in fact, not by analogy** — segment 2 is the classification
segment at the same position in both. And the transformation to the form the service accepts is closed end
to end:

| Route | Raw read form | Canonicalised | Value the service stored |
|---|---|---|---|
| iteration | `\<project>\Iteration\<node>` | `<project>\<node>` | **identical** |
| area | `\<project>\Area\<node>\<leaf>` | `<project>\<node>\<leaf>` | **identical** |

Canonical form: **no leading separator, no trailing separator, no classification segment, compared
case-insensitively.** Drop the classification segment **by route and position, never by name** — a node can
legitimately be called `Area`.

**Note the trap in the table above:** `backlogIteration.path` returns a form (`\<node>`) that **no other
route returns**, so a normalisation rule written against it does not fit the route that actually produces a
project's iteration path. Match the transformation to the route you called.

**Two projects is two projects.** Nothing here rules out a third classification segment or a fourth form
in another configuration.

**Everything above the "Verified by execution" heading is from Microsoft's published reference, not from
this machine.** Bar-soundness row 1 applies to it: documentation is evidence about what is claimed, not
about what the installed CLI and the service do. **And a caution about the verified section itself** —
it establishes which form these two **arguments accept**, and nothing about which form any **read route
returns**. Those are separate questions, and conflating them is how a hand-normalised probe gets
mistaken for a verified normalisation rule.
