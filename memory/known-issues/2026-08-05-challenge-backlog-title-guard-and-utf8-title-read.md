**Date:** 2026-08-05
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/backlog/SKILL.md, skills/devops-azure/SKILL.md sections 8a/8b/8d/8f
**Overrides-convention:** no
**Related-to:** memory/context/2026-08-05-az-mangles-non-cp1252-characters-on-output.md, memory/context/2026-08-04-az-query-and-json-parse-hazards-on-windows.md, memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md, memory/known-issues/2026-08-03-challenge-devops-azure-batch-write.md

## Summary

Pressure-tested two proposed gate changes arising from a real 120-item batch write on 2026-08-05.
Nothing was implemented. **Neither proposal survives as scoped, and in both cases the observed pain has
a cheaper cause located in `skills/devops-azure/SKILL.md` rather than in the proposed target.**

Proposal 1 (`/backlog` validates title characters against 8f's forbidden set) would put a
platform-specific, **unverified and probably incomplete** denylist into a deliberately tracker-neutral
artifact, where 8b's own re-guard doctrine means it can buy **zero** security. The three observed stops
are better explained by two facts nobody has named: `/backlog`'s copy-ready template **itself emits a
title containing a backtick** (`skills/backlog/SKILL.md:332`), and title validation is specified only in
**8f (Create)** — the step that performs writes — so a stop is discovered per-pass rather than once,
against a mode whose own text calls a partially-created backlog the worst available outcome.

Proposal 2 (read titles for 8d's divergence line over REST) spends a second invocation mechanism, a
second auth path, and a bearer token in an agent transcript to repair a line that is explicitly never a
stop. Worse, **every computational fix in the option set rests on a mangling behaviour the record
documents as having two modes, only one of which was measured** — `az` is recorded as both substituting
`U+FFFD` *and* discarding characters, and only the substitute case was counted. The only option that
cannot be wrong is documenting the false-positive mode.

## Context

Team lead dispatched devils-advocate with both proposals stated, its own leanings stated deliberately for
attack, and one constraint: weigh any proposal that adds a second place where the same constraint must be
maintained, given this repo's history of controls built on mechanisms later found wrong and of
enumerations copied between files going stale. No plan file existed; the reply was the only other
artifact.

Verified during the pass: `skills/devops-azure/SKILL.md` 8f's forbidden set is backtick, `$`, `;`, `|`,
`&`, `<`, `>`, double quote, newline/control (`:436`); 8b defers titles to 8f explicitly (`:182`); 8d's
title line is informational, never a stop, never an update (`:321`, restated `:386`); `Invoke-RestMethod`
appears in the file only as probe *evidence* at `:257-258`, never as an invocation path; there is **no
title-extraction rule anywhere in the file** — 8f writes `--title "<title from tree>"` (`:429`) and
nothing defines how a title is derived from `#### STORY-1 — Record the date of loss`.

## Concerns Raised

### 1. `/backlog`'s own copy-ready template emits a title 8f rejects
**Unresolved. Cheapest fix in either proposal and it is not a validator.**
`skills/backlog/SKILL.md:332` — inside the block `:203` says to use **verbatim** — reads
``TASK-1.1 — Add `DateOfLoss` to the loss notice form with a not-future validator.`` A backtick inside a
task title, in the worked example every run copies. The pack instructs the behaviour it then stops on.
Correcting the example removes an instruction to produce a rejected title, restates no denylist, and is
defensible as plain-prose authoring for any tracker.

### 2. Title validation is specified in the write step, which explains three stops rather than one
**Unresolved. Highest-value finding.** 8b (`:182`) defers the title guard to 8f, and 8f is **Create**.
8f requires validating "every title" but nowhere requires a **single complete pass reported before the
preview**, so nothing bounds the number of stop-edit-rerun cycles at one. Relocating the check to a
precondition (8a/8b) that reports **every** offending item id and character in one list, before the
preview, addresses the observed pain entirely — in the file that owns the guard, with no second copy of
the set and no change to `/backlog`. Whether the three stops were mid-create is not established here and
matters: 8f `:452-463` stops at the failing item, and `:101` calls a partially created backlog worse than
either failure the per-write rule guarded. If any of the three stops landed mid-create, this is
correctness-adjacent rather than ergonomic.

### 3. A `/backlog`-side guard can buy no security, by the pack's own doctrine
**Unresolved.** 8b `:173`: "The tree is **hand-editable**, so a guard `/backlog` applied when it wrote
the file does not transfer to this second read." So proposal 1 cannot relieve 8f of one byte of its
obligation; its entire value is ergonomic. That reframes the trade as: a duplicated denylist in a
neutral artifact, for fewer hand-edits — and concern 2 delivers the same ergonomic win with no
duplication.

### 4. 8f's set is unverified at the title layer and probably incomplete, so a copy would fail open
**Unresolved.** The set was derived from the PowerShell string-literal layer, but this repo documents a
**second re-parsing layer**: the `az.cmd` shim re-parses the line and `cmd` treats `(` specially
(`memory/context/2026-08-04-az-query-and-json-parse-hazards-on-windows.md`, exit 255,
`--output was unexpected at this time`). `cmd` metacharacters **absent** from 8f's set include `%`
(expands inside double quotes) and `^`. No title-level probe of any of the nine characters exists. The
2026-08-05 run is weak evidence that `(` in a quoted title is safe — the template's own SPIKE titles
carry parentheses and ~95 items were created — but `%` remains uncovered and untested. If 8f's set is
later corrected, the `/backlog` copy is the **permissive** one: it fails open, 8f still fails closed, and
the ergonomic benefit that justified the copy evaporates silently.

### 5. Half the observed stops came from a character that is defence-in-depth, not break-out
**Unresolved, and the narrowing is probably still wrong — record the reasoning.** Given a title written
as a double-quoted PowerShell literal, only `"`, backtick, `$`, and newline/control break **out** of the
literal; `;`, `|`, `&`, `<`, `>` are dangerous only after a break-out already happened. The observed
stops were on backticks **and semicolons** — so a share of the pain came from the defence-in-depth half.
But narrowing the set would make the guard depend on the generated invocation actually using a
double-quoted literal, and 8f `:445` states plainly that this is "a property of the caller, and this file
cannot verify the caller has it" — the same unverifiable-caller trade 8f already refused for argument
splatting. So the over-broad set is defensible **as a deliberate choice**; what is missing is 8f saying
that out loud, so a later reader does not narrow it as an obvious cleanup.

### 6. Proposal 1's option (d) is already closed with reasons
**Addressed by the existing file.** "Change how titles reach `az`" was consciously rejected at 8f
`:438-441` on two grounds: the tool-call boundary here is **text, not `argv`** (the title becomes a
literal in generated script text one layer before splatting could help), and correct native-argument
passing is **independently unreliable** on this machine with a silent-corruption mode. Reopening (d)
needs new evidence about the harness, not a new argument.

### 7. An operator-confirmed title rewrite collides with two existing invariants
**Consciously rejected rather than overlooked.** Rewriting offending titles at preview time (not
silently — 8e already shows every title) looks like the natural fix for three stops. In-memory rewrite
makes the tree and ADO diverge permanently, so 8d's divergence line then fires on those items forever;
rewriting the tree violates 8g's rule that the only lines this mode may add are `external_refs:` blocks.
Both branches are worse than concern 2's fix.

### 8. There is no title-extraction rule, which is a deeper cause of divergence than encoding
**Unresolved, and it is upstream of proposal 2.** 8f writes `--title "<title from tree>"` and nothing
in either skill defines how a title is derived from a tree heading such as
`#### STORY-1 — Record the date of loss` — whether the id, the separator, or a trailing `(REQ-001)` is
included. 8d's divergence comparison requires that extraction to be **deterministic across runs**, and a
non-deterministic extractor produces divergences that no UTF-8-safe read path would fix. Repairing the
read path of a comparison whose left-hand side is undefined fixes the smaller half.

### 9. Proposal 2 is aimed at the lowest-value consumer of a UTF-8-safe read
**Unresolved.** 8d's line is informational by construction. The same quirk lands on a read that
**routes**: 8a `:163` already records that a team name carrying a non-cp1252 character is mangled on
output, and that design routes on team names, feeding them back as route parameters to
`teamfieldvalues` and `backlogs`. If a UTF-8-safe read path is worth adding, the read that routes is the
justification; if it is not worth adding for that, it is certainly not worth adding for a line that never
acts.

### 10. A REST path puts a bearer token into an agent transcript, in a public repo with session logging
**Unresolved. Not raised in the dispatch.** `az account get-access-token` prints a token to stdout,
which lands in the agent's context and transcript. This repo is public, `scripts/lint-identifiers.sh`
does not scan for tokens, and the pack writes `session-decisions-*.txt` / `session-state-*.txt` files
folded into Obsidian logs by the stop hook. Secondary: the pack's entire read-failure doctrine (blank
output is `UNKNOWN`, trust `$LASTEXITCODE` never `$?`) is written **for `az`**, and
`Invoke-RestMethod` throws on non-2xx instead of returning blank plus an exit code — so a REST path needs
a **second** read-failure doctrine, which is precisely the second-place-to-maintain hazard the dispatch
named.

### 11. Every computational fix for proposal 2 rests on an incompletely characterised behaviour
**Unresolved. This is the finding that decides proposal 2.**
`memory/context/2026-08-05-az-mangles-non-cp1252-characters-on-output.md:11-14` records **two** mangling
modes: substituting `U+FFFD`, and *"Unsupported characters are discarded"*. Only the substitute mode was
measured (`U+FFFD` 0, `U+2014` 1 over REST on three items). If characters can be **discarded**, lengths
differ, and any comparison-side repair — including treating `U+FFFD` as a one-character wildcard, which is
strictly narrower and better than option (c)'s normalisation — is unsound in the unmeasured mode. Option
(c) is worse still: it hides genuine divergence in every non-ASCII title. So the only option that cannot
be wrong on current evidence is **(e), documenting the false-positive mode**.

### 12. Option (b) is the cheapest and widest fix and nobody has executed it
**Unresolved, one command from being decidable.** The memory file's workaround is stated as an
alternative — REST **or** console UTF-8 — and only the REST half appears in the executed table.
Console UTF-8 would fix every `az` read in the run (titles, team names, area and iteration paths) with no
second mechanism, no second auth path and no token in the transcript. It is also a hypothesis: the
`cp1252` choice follows the console code page, but nothing here has run it. **No control should be
written on it until it is executed** — that is the exact failure class this repo keeps hitting. If it
works, it belongs at 8a as a run-wide precondition, not as an 8d-specific patch.

## Implications

- **Proposal 1 is not worth making as scoped.** Concerns 1 and 2 deliver its entire benefit inside the
  file that owns the guard, with no duplicated set and no violation of `/backlog`'s neutrality. Concerns
  3 and 4 say the copy would buy no security and would fail open the moment 8f's set is corrected.
- **Proposal 2 is not worth making as scoped.** Concern 11 says the computational fixes cannot be shown
  correct on current evidence; concerns 9 and 10 say the price is wrong for an informational line.
  Documenting the false-positive mode is unconditionally correct and costs one sentence.
- **Two facts should be established before anything is written:** whether the three stops occurred
  mid-create (concern 2), and whether console UTF-8 fixes the read (concern 12). Each is cheap and each
  changes the answer.
- **The title-extraction rule is an undocumented gap that both proposals stepped over** (concern 8). It
  is upstream of the divergence line and of the character guard alike.
- **8f should say why its set is over-broad** (concern 5), or a later reader will narrow it as an obvious
  cleanup and reintroduce the dependency on an unverifiable caller property that 8f already refused once.
