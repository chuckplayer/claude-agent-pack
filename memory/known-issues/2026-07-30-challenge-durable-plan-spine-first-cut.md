---
date: 2026-07-30
type: finding
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: docs/obsidian-cli-and-plan-spine-brief.md
---

## Summary

Pressure-tested the durable plan spine first cut (workstream 2 of
`docs/obsidian-cli-and-plan-spine-brief.md`, as amended 2026-07-30) before any file was
edited. The dominant finding: **nothing in the design binds a plan file to the pipeline
run or branch that produced it.** The plan is discovered by directory glob, so any plan
left in `<plan_dir>/` by an earlier `/plan`, an abandoned `/implement`, or unrelated work
is indistinguishable from the plan for the current run — which breaks the `/hotfix` and
`/debug` ceremony exemption, breaks the `/implement` adoption rule when more than one plan
exists, and makes stranded plans accumulate with no reaper. Twelve further concerns are
recorded below, including six duties the design names that no component holds (concern 12)
and a conflict with the active branch-scope decision that arises whichever way the gate
script receives its file list (concern 13). No concern was resolved during the session; the design decisions listed in
the brief's "Amendments accepted 2026-07-30" were already taken by the user before the
challenge ran.

## Context

The team lead dispatched devils-advocate to attack the design of the 8-file first cut on
branch `feat/durable-plan-spine` (clean tree at `da68239`), specifically: the two-commit
merge-reviewer design, whether acceptance bars are load-bearing, whether extracting the
gate to `scripts/plan-gate.sh` buys testability, whether the distillation gate is
falsifiable, what the cut breaks that nobody considered, and the strongest argument for a
materially smaller version.

## Concerns Raised

### 1. Plans are not bound to a branch or run — the exemptions are exempt by assumption
**Unresolved.** merge-reviewer is invoked by five skills, not one: `/implement` step 10,
`/refactor` step 8 (`skills/refactor/SKILL.md:104`), `/scaffold` step 9
(`skills/scaffold/SKILL.md:89`), `/hotfix` step 6 (`skills/hotfix/SKILL.md:61`), and
`/debug` on the commit path (`skills/debug/SKILL.md:79`). The gate reads "if a plan
exists, enforce it," and a plan's existence is a property of the *directory*, not of the
run. So a `PROPOSED` plan written by a `/plan` session the user never implemented is
enforced against — and then flipped to `SHIPPED` and deleted by — the next unrelated
`/hotfix`. The brief's constraint "`/hotfix` and `/debug` keep their ceremony exemption"
(brief line 229) holds only because those skills do not *create* plans; it does not stop
them from *consuming* one. Potential impact: a plan for work A is deleted by a commit for
work B, and the FAIL/PASS verdict on B is computed against A's acceptance bars.

### 2. Commit one does not carry the implementation on the common path
**Unresolved.** The amendment states commit one "carries the implementation with the plan
file still present" (brief lines 105-108). But merge-reviewer Step 0
(`agents/merge-reviewer.md:48-51`) merges each worktree branch with `git merge --no-ff`
*before* the checklist, so on every run where engineers ran under `isolation: "worktree"`
the implementation is already committed by the time `git add -A`
(`agents/merge-reviewer.md:245`) runs. The only unstaged content left is the plan file
itself. Commit one therefore becomes a plan-only commit landing *after* the
implementation commits, and the message-drafting rule at `agents/merge-reviewer.md:251`
("describe the staged delta being committed") will correctly describe it as such. The
"PR shows intended shape against implementation" benefit that justified committing at all
is weakened, not delivered.

### 3. The empty-commit guard and the two-commit flow interact unhandled
**Unresolved.** `agents/merge-reviewer.md:249` skips straight to the PASS output when
nothing is staged, bypassing the commit entirely. Two unhandled cases: (a) no plan exists
and nothing is staged — commit two must be skipped too, or the agent creates an empty
commit; (b) a plan exists but all implementation was already committed — the guard does
not fire, and case 2 above results. Nothing in the design states that commit two is
conditional on a plan having been present.

### 4. Three of the four "mechanical" checks are not mechanical at one invocation point
**Unresolved.** The brief's table (line 135) lists four mechanical checks. Only "plan file
exists" and "status is PROPOSED/IN_PROGRESS" are script-checkable when the gate runs.
"Deletion happened" cannot be observed by a script that runs *before* deletion, and a
script that runs after deletion can read nothing else — so the mechanical half needs two
invocations at different points, which the design does not specify. "Deletion was preceded
by a `memory/` write when one was warranted" contains a judgment predicate ("when
warranted") that no script can evaluate. Additionally, `status: PROPOSED → SHIPPED` is
written by merge-reviewer itself seconds before it checks it, in a file it then deletes:
a self-check with no independent observer.

### 5. Exit code 2 (no-plan-skip) is the common case and is indistinguishable from failure
**Unresolved.** `/implement` step 2 (`skills/implement/SKILL.md:18`) skips tech-lead for
well-scoped single-file tasks, and the accepted decision is that tech-lead writes the plan
only when the invoking skill instructs it. So the overwhelmingly common `plan-gate.sh`
outcome is exit 2 / skip — which is observationally identical to the write-only failure
mode the cut exists to prevent. Nothing records that a plan *was expected*, so nothing can
distinguish "no plan needed" from "the plan was never written."

### 6. The distillation gate has no reachable failing input except one
**Unresolved.** Per `CLAUDE.md`, engineers already hold `memory/known-issues/` write
permission, and tech-lead and devils-advocate write their own memory files. By the time
merge-reviewer runs, every agent that discovered something durable has already recorded
it. The single reachable true positive is: an engineer handoff asserts a workaround or
limitation and no new `memory/` file appears in branch scope. That specific form is
partly mechanical — Step 0c (`agents/merge-reviewer.md:132`) already produces the branch
file list the check would need. As currently specified ("the same judgment merge-reviewer
already applies to findings," brief line 435) the gate is structurally a no-op.

### 7. Plumbing gaps
**Unresolved.**
- `install.sh:489-495` is nested inside the Obsidian conditional. A `plan-gate.sh` copied
  there never installs for any user who declines Obsidian, making merge-reviewer's
  "warn loudly, run judgment only" fallback the *default* — i.e. today's untested prose.
  Compounds [[2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive]].
- `scripts/check-updates.sh:111` iterates a hardcoded list of five `obsidian-*-hook.js`
  files. `plan-gate.sh` drift between repo and `~/.claude/scripts/` is undetected unless
  it is added to that list — the exact drift class `check-updates.sh` exists to catch.
- `uninstall.sh:16-21` removes only the five Obsidian hook scripts, and only when the user
  opts into hook removal. `plan-gate.sh` is orphaned by uninstall.
- This repo's `docs/CONVENTIONS.md` is byte-identical to
  `docs/CONVENTIONS.template.md`, whose every value is an unfilled `[e.g., ...]`
  placeholder. A `**Plan directory:**` key added to the template will be *present and
  unfilled* in the live case, so a naive grep resolves `plan_dir` to the literal string
  `[e.g., docs/plans/]`. Both readers must treat a `^\[.*\]$` value as unset; nothing
  specifies that.
- `scripts/setup-project.sh:34-38` touches `.gitkeep` in each `memory/` subdir. A bare
  `mkdir -p docs/plans` without one produces a directory git will not track, so the change
  is a no-op in any fresh clone.

### 8. Stranded plans accumulate, and `git add -A` sweeps them
**Unresolved.** Deletion happens only on the PASS path. Every FAIL after the 2-retry
budget, every abandoned pipeline, and every `/plan` the user does not follow through leaves
a plan file behind — at `IN_PROGRESS` after `/implement` step 5, which the adoption rule
(matching `PROPOSED`) will not pick up, so the next run writes a suffixed second plan.
`<plan_dir>/` becomes the graveyard "distill-then-delete" was chosen to avoid, and because
commit one is `git add -A` (`agents/merge-reviewer.md:245`), a later unrelated run sweeps
the strandees into its commit. The design routinely manufactures untracked files in the
primary working tree, converting a latent `git add -A` hazard into a habitual one.

### 9. The cut's own acceptance bar tests the untestable half
**Unresolved.** Amendment 3 part 3 makes the cut's acceptance bar "confirm an unmet bar
actually produces a FAIL" (brief lines 144-149). "Bars met" is explicitly the *judgment*
half, excluded from the script. So the automated test covers the mechanical half while the
acceptance bar exercises the judgment half — one sample of a nondeterministic verdict from
`merge-reviewer` (`model: sonnet`, `agents/merge-reviewer.md:16`). The cut does not meet
its own standard of "concrete enough that a stranger could check them."

### 10. lint-agents.sh assertion rests on a linter nothing runs
**Unresolved.** The presence assertion (brief lines 451-453) guards the *repo* copy against
a future edit deleting the gate section. `scripts/lint-agents.sh` is generic frontmatter
validation today (`scripts/lint-agents.sh:89-171`); the assertion introduces the first
file-specific body check. Per the archived
[[2026-03-18-challenge-script-value-assessment]], lint-agents.sh has no CI pipeline and
its value was accepted as "speculative as a CI artifact." It also does not protect against
repo-vs-installed drift, which is the drift class that has actually bitten this pack.

### 12. Six duties this design names are held by no component — and the omission pattern is methodological
**Unresolved.** Enumerating every duty the design names against the file that would carry it:

| Duty | Owner |
|---|---|
| Resolve `plan_dir` from the CONVENTIONS key | tech-lead **and** merge-reviewer **and** `plan-gate.sh` — three resolvers, no single source |
| Reject an unfilled `[e.g., ...]` placeholder value | **unowned** (would need duplicating in all three) |
| Generate frontmatter `id` | tech-lead nominally; nothing consumes it |
| Suffix the slug on collision | tech-lead (brief line 169) |
| *Select* the right plan when several exist | **unowned** |
| Instruct tech-lead to write the plan | `/plan` step 2, `/implement` step 2 only |
| Pressure-test the bars in place | dispatch prose in `/plan` step 3 + `/implement` step 3 — **not** `agents/devils-advocate.md`, deliberately |
| Flip `IN_PROGRESS` | `/implement` step 5 only — no owner in `/refactor`, `/scaffold`, `/hotfix`, `/debug` |
| Write tests against the bars | **unowned** — `agents/test-engineer.md` is not in the 8-file list |
| Verify bars met / distillation / flip `SHIPPED` / delete / commit twice | merge-reviewer |
| Reap stranded plans | **unowned** |
| Install `plan-gate.sh` | `install.sh` (currently inside the Obsidian conditional) |
| Detect `plan-gate.sh` drift | **unowned** — `scripts/check-updates.sh` not in the list |
| Remove `plan-gate.sh` on uninstall | **unowned** — `uninstall.sh` not in the list |
| Handle `no-base` / no-git degradation in the distillation check | **unowned** |

`test-engineer` is the important omission: it is the only stage that converts bars into
something an *already-shipping* gate fails on (`agents/merge-reviewer.md:218-227`), and the
brief's own stage-duty table (line 411) assigns it a duty no file in the cut carries. The
file count is 11 minimum, not 8.

**The methodological leak:** the design records duties against *actors* (the stage-duty
table, brief lines 405-413) while the implementation edits *files*, and nothing reconciles
the two lists. Three actors in that table have no file in the edit set — devils-advocate
(deliberately), test-engineer (by omission), and the skills that dispatch them. Reconciling
every table row against a named file and line would have caught the plan-commit duty, the
`IN_PROGRESS` duty, the placeholder guard, and test-engineer on paper, before any of the
three were discovered one at a time.

### 13. The branch-scope interface conflicts with an active decision either way
**Unresolved.** `memory/decisions/2026-07-07-decision-merge-reviewer-branch-scope.md` is
active, scoped to `agents/merge-reviewer.md`, and `agents/merge-reviewer.md:114` states the
rule directly: capture scope **once**, "never re-derive scope from a single commit."

- **If `plan-gate.sh` recomputes scope:** it duplicates the `origin/HEAD` → local
  `main`/`master` → `no-base` ladder at `agents/merge-reviewer.md:125-137`. Divergence
  between the two implementations makes the distillation gate verdict, the test-coverage
  gate, and the PASS report narrate three different file sets from one agent run. It also
  violates the decision's "computed once" rule and its ordering constraint (decision line
  41: scope must be computed *after* Step 0's merges).
- **If the list is passed in as an argument:** the trust boundary moves from "the script
  computes correctly" (deterministic, testable) to "the model transcribes correctly"
  (neither). The script cannot distinguish a genuine 3-file list from a truncated 40-file
  one, so it has no way to validate its own input. That places the failure in exactly the
  spot the extraction was meant to remove it from. Compounded on Windows by argv length
  limits and unquoted paths containing spaces — silent truncation is the classic form.
- **Unaddressed in both cases:** what the script does when the base is `no-base` or the repo
  has no git at all (brief line 201). Hard-FAIL there reverses an explicitly rejected
  alternative (decision lines 52-53) and regresses `agents/merge-reviewer.md:144`'s
  deliberate degrade-with-warning.

The safer boundary nobody proposed: pass the **base ref** — one short token the script can
`git rev-parse --verify` and reject loudly if bogus — and let the script derive the file
list with the identical command at `agents/merge-reviewer.md:132`. One source of truth for
the base, deterministic derivation, loud failure on bad input.

---

## Addendum — challenge of the frozen `plan-gate.sh` interface (same session, 14-file design)

The design changed mid-challenge: the mechanical gate became a real script with a frozen
interface (`--plan`/`--dir` verify, `--print-dir`, `--ship`), exit codes 0/1/2 with
unknown-is-FAIL, a closed `reason=` code list, and installer/uninstaller/check-updates
plumbing. File count 10 → 14. Concerns 1-13 above are unaffected. Six further concerns:

### 14. Exit 1 conflates "the gate says no" with "the gate broke" — and a broken gate is worse than no gate
**Unresolved.** With `set -euo pipefail`, an unguarded `grep -q` that legitimately finds
nothing terminates the script with status 1, as does any unexpected internal error, as does
`bash: $'\r'` or a missing dependency. All are indistinguishable from a genuine FAIL. The
design specifies exit discipline and stdout discipline separately but never their
cross-product; the case **exit 1 with no `PLAN-GATE:` line** is undefined. merge-reviewer
would emit a FAIL with no `reason=` to route on, `skills/implement/SKILL.md:131-137` burns
both retry cycles routing nowhere, and the run halts undiagnosed — strictly worse than
today, where no gate exists and the pipeline proceeds. Two adjacent undefined cases: an
**unknown `reason=` code** (installed script newer than the installed merge-reviewer prose
that routes on the closed list — the pack's signature drift class, and nothing carries a
contract version token), and **empty stdout from a silently failed Bash tool** per
[[2026-07-10-bash-tool-silent-failure-windows]], whose "How to apply" states blank output
must be treated as tool breakage, not as a result. All three want the same disposition: a
malfunctioning gate should route to the **already-accepted** "gate not installed" path
(warn loudly, judgment half only) rather than to FAIL. That reuses a decision already taken
instead of adding one.

### 15. `--ship` is tested, portable, self-verifying code whose entire output is discarded
**Unresolved.** Moving the flip into the script is correct on its stated grounds — `sed -i`
really is non-portable and a prose recipe would have shipped a macOS-broken flip — and
`ship-verify-failed` re-reading after writing is the one place this design applies
workstream 1's read-back discipline. But `--ship` writes `SHIPPED` into a file
merge-reviewer deletes in the same commit, so the flip's only durable effect is nothing,
and `ship-verify-failed` can fire only on a filesystem-level fault. This sharpens the
smaller-version argument decisively: **if the file is deleted, the flip is ceremony; if the
flip matters, do not delete the file.** The design wants both and gets neither.
Secondary risk: argv is model-constructed by prose in `agents/merge-reviewer.md`, and
`--ship` and `--plan` will appear within a few lines of each other in that prose — the
highest-risk adjacency available for a mode-confusion error in a tool where one mode
mutates.

### 16. `bars-section-empty` catches the truncated write, not the lazy one
**Unresolved.** The degenerate case moves one step: bars present, non-empty, vacuous
("the code works", "tests pass"). No lexical check can establish falsifiability, so the
split's honest value is narrow but real — it catches an *interrupted or truncated*
tech-lead write, which is a different failure from a *lazy* one. It should be described
that way rather than as a defense against weak bars; the brief's "Weak bars" risk (lines
496-498) is untouched, and its named mitigation (devils-advocate) remains conditional with
`agents/devils-advocate.md` deliberately outside the edit set. Separately, eight WARN-level
H2 checks at exit 0 create a channel nothing is required to act on, on every run — routine
WARNs train the reader to skip the line, which hides `narrative-heading-missing` when it
finally matters.

### 17. Executing from `~/.claude/scripts/` — sound about compromise risk, wrong about compromise impact
**Unresolved.** The parity argument holds on the security axis: anyone who can write that
directory already owns five hook scripts that run on every Stop, UserPromptSubmit,
SubagentStop, SessionStart, and PostToolUse(Write|Edit) (`install.sh:553-558`) — strictly
more powerful positions than a once-per-merge gate. Marginal attack surface is near zero,
and `check-updates.sh` parity restores integrity monitoring. The axis that *is* materially
different is trust semantics: a subverted hook costs a log line, whereas a gate rewritten
to `exit 0` turns the whole cut into a no-op **while reporting PASS** — instance six by
construction. The mitigation is not permissions but authority: the design must state
whether a gate PASS ever *substitutes* for merge-reviewer's judgment or is strictly
additive. Additive bounds the impact; substitutive does not.
(Checked and closed: `.gitattributes:5` already pins `*.sh` to `eol=lf`, so the first
installed shell script carries no CRLF hazard.)

### 18. `--print-dir` cannot protect the write path as specified
**Unresolved.** `plan-dir-unsafe` lives in the script, but `--print-dir` is specified to
always exit 0 and the caller passes its stdout to tech-lead as dispatch text. So on an
unsafe or placeholder directory, `--print-dir` either prints the bad path at exit 0 — and
tech-lead, holding `Write` (which creates parent directories, brief 218-220), materialises
it — or prints nothing at exit 0, and the caller cannot tell. **Either way the guard fires
only in verify mode, after the file exists in the wrong place.** The live case is concrete:
this repo's `docs/CONVENTIONS.md` is byte-identical to the template, so the key resolves to
the literal `[e.g., docs/plans/]` (concern 9). Guarding the write path requires
`--print-dir` to fail or fall back on an unsafe value, which contradicts the frozen
interface's "`--print-dir` → 0". Compounding: tech-lead now holds two sources of truth for
the directory (the passed string and its own fallback rule) with no rule for disagreement,
and no rule for whether an empty passed value means "gate absent, use fallback" or
"resolved to nothing".

### 19. Every reason code added converts an unowned duty from cosmetic into blocking
**Unresolved.** This is the addendum's most consequential emergent property.
`ambiguous-plan-set` weaponises the missing plan-reaper (concern 8): one strandee at
`IN_PROGRESS` plus one fresh `PROPOSED` is now a hard FAIL that halts *future* pipelines,
where before it was clutter. `status-invalid` weaponises the missing `IN_PROGRESS` owner in
`/refactor`, `/scaffold`, `/hotfix`, and `/debug` (concern 12): a plan reaching
merge-reviewer still at `PROPOSED` through any of those four paths now hard-FAILs instead of
passing quietly. The gate became more rigorous while the ownership map stayed incomplete,
so rigour is now amplifying the gaps rather than covering them. New duties the addendum
itself leaves unowned: act on WARN output; distinguish gate malfunction from gate verdict
(concern 14); guard the write-side path resolution (concern 18); reconcile a passed
directory against tech-lead's fallback; detect contract skew between the installed script
and the installed merge-reviewer prose. `agents/test-engineer.md` is still not among the 14
files.

## Implications

- **Highest-value unaddressed question:** should the plan record the branch (and/or run) it
  belongs to, so merge-reviewer selects the plan for the current branch rather than any
  plan in the directory? That one field closes concerns 1, 5 (partly), and 8 (selection
  half), and it is the difference between a spine and a directory of loose files.
- **A materially smaller version exists that proves write → read → fail with no new
  script, no status lifecycle, no second commit, and no deletion:** tech-lead writes the
  bars into the plan; test-engineer writes tests against the bars; merge-reviewer's
  *existing* test-coverage gate (`agents/merge-reviewer.md:218-227`) already FAILs when
  required tests are absent. Read-back is enforced by a gate that already ships. The
  status lifecycle, two commits, deletion, and distillation gate are bookkeeping about the
  artifact rather than about the work.
- Anyone implementing this cut should treat `agents/merge-reviewer.md` as the highest-risk
  edit in the set: it is the only file where the two-commit sequencing, the empty-commit
  guard, the conditional gate, and the judgment calls all interact.
- **After the 14-file addendum:** the frozen `plan-gate.sh` interface is a genuine
  improvement on prose in four respects — one implementation of directory resolution instead
  of three, a portable flip instead of non-portable `sed -i`, `ship-verify-failed` applying
  read-back discipline to its own write, and installer/uninstaller/check-updates parity. It
  does not address concerns 1-13, and it introduces the amplification effect in concern 19:
  each new `reason=` code turns a duty nobody owns into a pipeline halt. Closing the
  ownership map (concern 12) is now a precondition for the gate being safe, not merely for it
  being complete.
