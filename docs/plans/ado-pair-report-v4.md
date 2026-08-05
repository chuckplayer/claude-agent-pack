---
plan_id: ado-pair-report-v4
branch: main
origin_skill: plan
created: 2026-08-04
---

## What ships

> **SUPERSEDED 2026-08-04 by `## REVISED DESIGN` below, after two reviews and one probe.** This section
> and the four that follow it describe the design **as planned**, keyed on a "category" that turned out to
> be the wrong object and priced with a read budget nobody had measured. They are kept unedited as the
> record of what was proposed and reviewed — the reviews below refer to them line by line. **Read
> `## REVISED DESIGN` for what is actually being built**, and treat any conflict between the two as
> resolved in its favour.

**The fourth pair-report design, as a preflight advisory inside batch write mode.** One file of
substance, one memory amendment, one verification.

A zero-write derivation, run before the preview, that classifies every parent/child pair the tree
requires into one of **three** states per candidate team — `RISK`, `NO_KNOWN_RISK`, `UNKNOWN` — and
surfaces `RISK` as a **warning requiring acknowledgement inside the single existing confirmation**.
Never a stop.

**Nothing about the mechanism is new in this plan.** It was executed on 2026-08-04 before any design
text existed, and it is recorded in
`memory/decisions/2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md`. What this plan adds
is the two things that memo left open: **who the team is**, and **where the classifier ends and the
policy begins**.

**Read the memo's amendments 1–3 and both review sections before implementing.** Three earlier designs
died here, and each died of a premise nobody ran. This one's premise was run; its *scope* is what was
wrong, twice over.

## The mechanism, split into the two halves that must stay apart

Codex's second review asked for the classifier and the policy to be architecturally distinct, before
any text exists, so a later disposition change is local rather than a rewrite. That split is the
organising principle of the whole cut, so it is stated first.

### Half 1 — the classifier (8a resolves the team, 8c derives the verdict)

Purely derivational. It produces labels and no consequences.

1. **Enumerate the project's teams.** `az devops team list --project <project> --org https://dev.azure.com/<org>`
2. **Narrow to the teams that can see these items.** For each team, read its team field values:

   ```bash
   az devops invoke --area work --resource teamfieldvalues \
     --route-parameters project=<project> team=<team-a> \
     --org https://dev.azure.com/<org> --http-method GET --api-version 7.1
   ```

   A team is a **candidate** when one of its `System.AreaPath` values covers the area path 8a already
   resolved — exact match, or a value with `includeChildren: true` at or above it.
3. **Read each candidate team's backlog levels.** One GET per candidate:

   ```bash
   az devops invoke --area work --resource backlogs \
     --route-parameters project=<project> team=<team-a> \
     --org https://dev.azure.com/<org> --http-method GET --api-version 7.1
   ```

4. **Invert to `type -> level id`, then classify each required pair, per candidate team:**

   | State | Condition |
   |---|---|
   | **`RISK`** | both types resolve to exactly one level, and it is the **same** level |
   | **`NO_KNOWN_RISK`** | both types resolve to exactly one level, and the levels **differ** |
   | **`UNKNOWN`** | a type appears in **no** level; a type appears in **two or more** levels; the read was blank, non-zero, or unparseable; or the response is not the documented level shape |

**Compare on the level `id`; display the level `name`.** Microsoft documents a level `id` as only *"can
be"* the category reference name, so on an inherited process it may be neither meaningful nor
printable. Equality still works as a test — which is all the classifier needs — and the `name` is what
an operator can read.

**`isHidden` levels are NOT filtered out, and that is a decision rather than an omission.** A hidden
level still holds types, and the service's same-category refusal is not a display concern. Filtering
would move a type into "no level" and produce `UNKNOWN` — silence — on a configuration the check
should be able to speak about. The consequence is accepted knowingly: a type on both a visible and a
hidden level yields two levels, hence `UNKNOWN`, which is the honest answer.

**A type on two or more levels is `UNKNOWN`, never first-match.** The schema makes `type -> level` a
relation, not a function, so a first-match inversion makes the verdict depend on **array order**. An
order-dependent verdict is worse than no verdict.

**The `SPIKE` alias dedupes on the mapped ADO type pair, not the tree-level pair.** `SPIKE` maps to the
same ADO type as `STORY` (8c), so `FEATURE -> SPIKE` and `FEATURE -> STORY` are the **identical** pair
and must render as one row. Two rows would show an operator two independent risks where one exists.

### Half 2 — the policy (8e, and one line in 8i)

| Classifier output | Disposition |
|---|---|
| `RISK` on any candidate team | **WARN inside 8e item 2's existing acknowledgement.** Never a stop. |
| `NO_KNOWN_RISK` | Reported with an explicit no-guarantee statement. Never presented as "safe". |
| `UNKNOWN` | Surfaced **separately**, folded into neither bucket. Never a stop. |
| Read failed / budget exceeded | A visible **"backlog hierarchy risk check unavailable"** line. Proceed. |

**Disposition lives in exactly one passage, and the classifier passage states verdicts as labels only.**
That is the property BAR-003 checks. It is cheap now and a rewrite later.

## What this check may never claim

Every one of these is a wording constraint the two reviews converged on, and every one is checkable.

- **Never "will fail" or "invalid".** The form is *"using team `<team-a>`'s configuration, these links
  may degrade reordering on that team's boards"*.
- **Never a project-wide verdict.** The derived value is one team's configuration. `"This pair is
  invalid for the project"` is overclaiming.
- **Never "unflagged pairs are safe".** Per the memo's amendment 2, the `NO_KNOWN_RISK` direction is
  **inferred, not executed** — no nested *different-category* child has ever been reorder-tested. Every
  false negative this check can produce lives in that untested half, which makes the no-guarantee
  sentence the honest ceiling on what the check can say.
- **Never a board-health claim.** Scope the negative statement to **the pairs this tree requires**. The
  check cannot see pre-existing nesting the run neither creates nor touches — a tree root matched to an
  item already sitting under a same-category parent flags nothing while the board is already degraded.
- **State only the narrow consequence, and do not restate it from memory.** REST refuses the
  same-category **child's** reorder at both product and iteration scope; on the **sprint** board the UI
  disables reordering **board-wide** and hides the **parent**. 8c line 219 already warns that this
  mechanism is what keeps being wrong here, and a preview line is a runtime restatement of it.

## Calls made for you

- **Multi-team resolution: narrow by area path, then run per candidate team.** *Operator's call, asked
  and answered 2026-08-04.* Exactly one candidate → use it and name it. Several → derive per candidate
  and report per team, flagging if **any** candidate flags. Zero → `UNKNOWN`. This needs no operator
  question, and it matches where the harm actually lives: a backlog is team-scoped, so a pair can
  degrade one team's board and not another's in the same project.
- **Runtime discovery only — no `AZURE_DEVOPS_TEAM`.** *Operator's call.* So `README.md`, `install.sh`,
  the environment contract in `docs/azure-devops-github-skills-brief.md`, and
  `scripts/lint-identifiers.sh`'s placeholder list are **not** edit sites, and a stale configured value
  cannot silently point the read at the wrong team's board.
- **A silent implicit default team is not acceptable.** The team used is **named in the preview**, in
  every branch. This is the one thing both reviews stated in the same words.
- **`wit/workitemtypecategories` is rejected consciously.** It needs no team and looks like the fix. It
  is project-scoped *by construction*, so it cannot represent a per-team bug override — and that
  override is what moves the `story-type -> bug-type` pair, the whole reason v4 keys on category. Do not
  "simplify" the design into losing its best case.
- **Warning requiring acknowledgement, not a stop.** Two models converged on this independently. The
  argument that settles it: the flagged thing is a **link**, the reversible part of this mode, while the
  irreversible half — item creation and permanent per-project tag values — proceeds under a preview
  line. A stop would block the reversible thing and wave through the irreversible one. **The bar for
  revisiting this is specific: name a case where the remedy is unavailable to the operator.** None is on
  record; the UI warning itself names both remedies.
- **It goes inside 8e item 2, so something can enforce it.** `skills/devops-azure/SKILL.md:306` already
  carries *"including any warning requiring acknowledgement"*. Item 2 is one of the **numbered nine**
  that `docs/plans/devops-azure-batch-write.md` BAR-002 checks; the un-numbered informational bucket
  beyond item 9 is checked by nothing. **Disposition and checkability are the same question here.**
- **A read budget: above 20 teams in the project, skip the enumeration and report `UNKNOWN`.** These are
  cheap GETs but they are sequential `az` invocations *before a preview*, and 1 + N + M of them on a
  50-team project is a minute of silence where the operator expects a preview. `UNKNOWN` is never a
  stop, so the cap creates no unusable state — unlike the `VS402337` ceiling the third design tripped
  over.
- **8e item 7 is not an edit site.** It counts **write** invocations — creates plus link adds. These are
  reads, and 8e's opening line already sanctions reads before the preview. Do not let a read count leak
  into the number the operator confirms.
- **Step 7's one-confirmation rule is not an edit site.** No second confirmation is added; the
  acknowledgement rides inside the existing one at zero cost.

## Risks

- **Under the sanctioned default mapping the check can never fire.** Its entire yield is catching a bad
  operator **override** — and an override triggers a full re-preview, so the derivation runs again per
  cycle. That may well be worth one read; it should be shipped knowing the yield is one class of
  operator error and not a general safety net.
- **The `NO_KNOWN_RISK` direction is inferred.** Two `RISK` rows are executed and both sit in the same
  category; no nested different-category child was ever reorder-tested. BAR-009 exists to close this and
  may return NOT RUN.
- **Area-path coverage semantics are documented, not executed.** `includeChildren` and the
  `teamfieldvalues` response shape are read from Microsoft's reference. BAR-008 executes them; until it
  does, the candidate-set derivation is the one part of the classifier resting on documentation — which
  is exactly the failure class this feature has produced three times.
- **The per-team preview shape is new, and preview text is not free.** This mode's entire safety rests
  on one operator reading one preview carefully. A three-team project adds three verdict lines; more
  text in that preview is a real cost, not a neutral addition.
- **Precedent: this is the first check in 8c–8h to act on a derived prediction.** Every existing stop
  fires on an **observed service response** or a **reconciliation mismatch**. Shipping this as an
  advisory rather than a stop is what makes the precedent acceptable — and **that is the least reversible
  thing in this cut.** If a later cut promotes it to a stop, that decision inherits a precedent nobody
  argued for on its own terms.
- **The classifier is right about a team and could still be reported as a fact about the project.** That
  is the failure v4 nearly shipped with, and the only defence is the wording constraints above. They are
  prose, applied by a reader.

## Files

| # | File | Change |
|---|---|---|
| 1 | `skills/devops-azure/SKILL.md` | **8a**: team enumeration, area-path candidate narrowing, the 20-team read budget. **8c**: the classifier — three states, `id`-vs-`name`, `isHidden`, the two-level `UNKNOWN`, the `SPIKE` dedupe, and the four parse hazards at the parse site. **8e item 1**: the candidate team(s) and how they were resolved. **8e item 2**: the pair verdict and its acknowledgement. **8e:321**: the verdict as a fourth thing that follows from the mapping. **8i**: one line recording the acknowledged verdict |
| 2 | `memory/decisions/2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md` | Amend: open decisions **0**, **3** and **4** are settled, naming what was chosen. Leave **1** (settled already) and **5** (this review) as they stand |
| 3 | `docs/ado-delivery-pipeline-brief.md` | **Verify only.** Confirm its description of the preview and the single confirmation is still accurate — it should be, since nothing here adds a confirmation. **Record the check either way** |

File 1 is one coupled edit: the classifier and the policy are split *within* it, and splitting them
across files would put half a mechanism where no reader of the other half will look. Files 2 and 3 are
independent of it.

## Challenge — 2026-08-04

Pressure-tested before any SKILL.md text exists. **Verdict: implement smaller.** The mechanism is sound
and was executed; what is not established is the *predicate* the classifier tests, and the design around
it is priced for a verdict vocabulary it does not need. Findings are ranked. Bars below were edited in
place; five were added (BAR-012 … BAR-016).

### 1. The classifier tests backlog **level** equality while every sentence around it says **category** — and no category route was ever read

This is the highest-value finding and it is a correctness question, not a wording one.

Everything executed on 2026-08-04 read **backlog levels**: `work/backlogs` returns levels, each with a
`workItemTypes` list, and the plan compares level **`id`**. Everything *said* about it — this plan's
`RISK` row, the memo's title, `SKILL.md:224` ("`Microsoft.RequirementCategory` holds `Product Backlog
Item`, `User Story`, **and** `Bug`"), the memo's "under `asTasks` the bug type moves to the task
category" — is a claim about **work item type categories**. No read of any category route appears
anywhere in the record. Backlog levels and WIT categories are distinct process-configuration concepts,
and **this plan already contains the evidence that they can come apart**: it notes that Microsoft
documents a level `id` as only *"can be"* the category reference name. If a level id need not be a
category refname, then level identity need not be category identity.

The consequence is a false negative in the **silent** direction — the direction amendment 2 says every
false negative already lives in. Two distinct levels that share a category yield "levels differ" →
`NO_KNOWN_RISK` → silence, while the service refuses. That is reachable exactly on the inherited and
customised processes this design exists to be right about, and it is invisible to a stock-template probe.

Note also what this does to `SKILL.md:219` — *"Do not restate the mechanism from memory; the mechanism is
what keeps being wrong here."* Line 224 sits five lines below it and states a category fact nobody read.
Whichever way the discriminator lands, that sentence is the mechanism restated from memory for a fourth
time.

**Two ways out, and they are not equivalent.** Either name the predicate as **same backlog level for team
`<team-a>`** throughout, drop the derived category claim, and quote ADO's own warning text where the word
"category" is wanted — or read the project-scoped category route once and test what the prose claims. See
finding 3's alternative A for why the second is worth more than it costs. BAR-002 and BAR-013 now check
this.

### 2. The plan's one genuine achievement is not applied to the plan's own new premise

v4's headline is that its mechanism *"was executed on 2026-08-04 before any design text existed"*. The
plan then introduces a **new** premise — `teamfieldvalues`' response shape and `includeChildren`'s
coverage semantics — read from Microsoft's reference, and schedules its execution as BAR-008, an
*acceptance* bar. Acceptance bars run after the text is written.

That is v1 and v2's sequence exactly, one level down: text built on a documented premise, premise checked
afterwards. The plan says so in its own `## Risks` — *"which is exactly the failure class this feature has
produced three times"* — and ships anyway. Naming a failure class is not disposing of it.

The candidate-set half of BAR-008 is cheap, zero-write, and answerable in minutes. It belongs **before**
the 8a text, on the same footing as the mechanism probe. Split out as BAR-012.

### 3. Yield versus cost: the verdict vocabulary is the expensive part, and it is optional

Priced as specified: 1 + N + M sequential reads before every preview, a three-state classifier, a policy
passage, a per-team preview shape, a new acknowledgement, a list of wording constraints enforced by a
reader, and edits at six sites in one file — for a check whose entire conceded yield is one class of
operator error.

**Two alternatives the plan does not consider. Both were checked against the codebase first.**

**A. Read the project-scoped category route *in addition*, as a control — not instead, as a substitute.**
The plan rejects `wit/workitemtypecategories` only as a *replacement*, and that rejection is sound as far
as it goes (see finding 8). Its additive use is unconsidered and is worth more than the substitution ever
was. It needs no team, costs one zero-write read, and its **agreement or disagreement with the
team-scoped level grouping is the first direct evidence that the grouping is team-varying at all** — the
premise the whole team apparatus rests on. It also supplies precisely what the prior challenge's concern
7 said was missing: a control that is not the same call as the test. Concern 7's complaint was that the
positive control is shape-only and *"cannot see that it read the wrong team's configuration"*; two
independent routes agreeing on the story/task grouping is the cross-route analogue of 8d's
drop-the-predicate control. **The route rejected as a trap is the missing control.**

**B. State facts, not verdicts — and put them inside 8e item 2's existing mapping display.** Item 2
already shows the proposed type mapping and asks for confirmation. Showing, per mapped type, the backlog
level(s) it sits on for the named team is a natural extension of that display: it lands inside the
checked nine with **no** widening of item 2's clause, and the operator confirming the mapping now confirms
it with the level names in front of them. What this drops is the whole apparatus:

- no `RISK`/`NO_KNOWN_RISK`/`UNKNOWN` vocabulary, so **no third state to collapse** — the null-versus-null
  false flag (prior challenge concern 6) dissolves structurally rather than being handled;
- no negative claim, so **nothing to hedge with a no-guarantee sentence** — silence about a pair whose
  levels differ is not a verdict about it;
- a type on no level, or on two, or on a hidden level, each renders as a **printed fact**, so the
  order-dependence hazard and the `isHidden` decision both stop being decisions;
- no policy passage, so BAR-003's split is moot;
- and where two required types do land on one level, one sentence citing the **observed** refusal
  (HTTP 400, `SameTypeHierarchyException`, both scopes, 2026-08-04) replaces a hedged prediction — which
  retires finding 9's precedent problem rather than accepting it.

This is not a new idea in this pack. `memory/decisions/2026-08-04-decision-ado-pair-report-states-facts-only.md`
is `archived`, but read *why*: its facts-only constraint **held** — *"its prose constraint … was
well-built and held. The falsehood arrived through the mechanism instead."* v3 died of a mis-joined edge
list, not of refusing to predict. v4 has the mechanism v3 lacked. Facts-only plus v4's mechanism is the
combination neither previous cut had.

**C. Derive only on an in-band override, since that is where the conceded yield lives.** Named and
**rejected** here, so it is not mistaken for an oversight: see finding 4.

### 4. The plan understates its own yield, on exactly the kind of premise it exists to guard against

*"Under the sanctioned default mapping the check can never fire"* is true for **stock** process
templates, where `Feature`, `User Story` and `Task` sit on three different levels. It is not established
for inherited or customised processes — and `SKILL.md:181–183` records this pack being burned by that
distinction already: a project whose process was *named* Scrum had the Scrum type blocked and the Agile
type enabled, with the lesson written as *"the process template's name predicts nothing."* A customised
process can put the default-mapped types on one level with no operator override anywhere.

So the sentence that makes "do not implement" look attractive is itself an unverified claim about an
external system — bar-soundness row 1, applied to the plan's own `## Risks`. Two consequences: the yield
is larger than conceded, and alternative C is wrong, because deriving only on override would miss the
customised-process case entirely. Keep the check on the default path.

### 5. BAR-001 and BAR-003 contradict each other, and BAR-003 is unsatisfiable as written

BAR-001(iv) **requires** 8a to state `UNKNOWN`-and-proceed as the read budget's escape. "Proceed" is a
consequence. BAR-003 requires that the derivation text state no consequences and that disposition live in
one passage. As written, satisfying either fails the other.

Worse, BAR-003's locality test — *"name the single contiguous passage a reader would edit to change `RISK`
from a warning to a stop, and confirm no other passage would also need editing"* — is **false on a
correct implementation**. A stop in this mode is plumbed at **8e item 4** (*"and if there is one, the
preview does not offer to proceed at all"*) and again at **8e:327**. Promoting `RISK` to a stop touches
those regardless of how cleanly the classifier and policy are split. The bar as written fails a file that
did everything right. Both repaired below.

**Answering the question directly: the edit-locality test is the right *idea* and the wrong *formulation*.**
The property that is actually checkable is one-directional — *no passage in 8c would need editing* — and
that is what BAR-003 now asks.

### 6. "Acknowledgement at zero cost" reads an instance as a category

`SKILL.md:306` reads *"every gate verdict from **8a** here, including any warning requiring
acknowledgement"*. The clause is scoped to 8a's gate verdicts. The plan derives the pair verdict in **8c**.
So the claim that acknowledgement is already carried and costs nothing is bar-soundness row 2 in the
plan's own argument: the mechanism (one confirmation, acknowledgements inside it) genuinely exists, but
the *clause the plan cites* does not cover a verdict from 8c.

Two ways to close it, and each has a cost the plan does not name. Widen item 2's clause — cheap, but it is
an edit to a sentence `docs/plans/devops-azure-batch-write.md` BAR-002 checks. Or make the verdict an 8a
gate — which changes 8a's *"apply **four gates with three verdicts**"* (`SKILL.md:121`). Either is fine;
neither is free, and neither appears in `## Files`.

### 7. The 20-team budget is a number with an unmeasured justification

The cap's stated reason is wall-clock before a preview: *"1 + N + M of them on a 50-team project is a
minute of silence."* At the cap itself the arithmetic is 1 + 20 + up to 20 ≈ **41** sequential `az`
invocations — which, at any plausible `az` cold-start cost, is roughly the same silence the cap was set to
prevent. Nobody measured a single invocation's latency. A cap justified by a duration nobody timed is the
same shape as a cost stated in a gate that nobody verified (bar-soundness row 6), and BAR-001(iv) as
written — *"stated as a **number**"* — passes for any number at all. Repaired below.

Adjacent, smaller: the team count that the cap is applied to comes from a list read that may itself be
silently paginated, and a truncated list would narrow the candidate set to a subset with no signal. The
cap happens to mask this today (a truncated 100 exceeds 20 and yields `UNKNOWN`); raising the cap would
unmask it.

### 8. The four parse hazards are pinned one section away from where two of them bite hardest

BAR-006 requires the hazards at the 8c `backlogs` parse and says **"not elsewhere in the file"**. But 8a
now performs two `az devops invoke`-class reads of its own, and three of the four hazards land there
first:

- the **team list** is the array response in this cut, so it is the `ConvertFrom-Json` double-wrap case;
- the **team name contains a space** in the conventional form and reaches `teamfieldvalues` as a *route
  parameter* — native-argument mangling bites at 8a before 8c ever runs;
- `teamfieldvalues` and `teamsettings` are **literal siblings** on the same route family, which is the
  documented instance of `az devops invoke` silently serving the wrong route.

BAR-006's scoping rule is right in principle — a hazard three sections away is not available to the reader
writing the parse — and it is aimed at one of the two parse sites. Extended below.

### 9. The precedent is under-disposed, and "advisory" understates what ships

Two things are true at once. The plan is the first artifact in this line to name the precedent, which is
progress. And its disposal — *"shipping this as an advisory rather than a stop is what makes the precedent
acceptable"* — is weaker than it reads, for two reasons.

First, an **acknowledgement-requiring warning is not merely advisory**. It modifies the one confirmation
this mode has: the operator cannot proceed without explicitly acknowledging it. Every other
acknowledgement-requiring warning in this mode — 8a's audit-findings, depth-narrowed and stale-provenance
gates — fires on a **locally verifiable fact about the tree or the spec**. This one would fire on a
prediction about an external system's future behaviour. That is still a first, one notch below the one the
plan disclaims.

Second, the precedent is recorded **only in this plan and the memo**. This feature's entire history is
that reviewers catch these and readers do not. If the precedent is to constrain the next reader who
considers promoting it to a stop, it has to be a sentence in `SKILL.md` at the site. BAR-014 added.

Alternative B in finding 3 dissolves this finding rather than mitigating it: a report citing an observed
refusal is not acting on a derived prediction.

### 10. The two-or-more-levels `UNKNOWN` silences a case the same evidence supports

The plan's argument is *"a first-match inversion makes the verdict depend on array order. An
order-dependent verdict is worse than no verdict."* Both sentences are right, and the conclusion does not
follow from them: **order-dependence is a property of first-match, not of the multi-level case.**
Order-independent readings of the same data exist — asking whether any single level contains both types is
one, and it does not depend on array order at all.

So the question is not order-dependence, it is which way to resolve ambiguity. Consider a type on levels
L1 and L2 where the paired type is on L1 only: a level containing **both** types exists, and the plan
reports `UNKNOWN`. For a check that is never a stop, the cost of over-flagging is one warning line the
operator can dismiss; the cost of silence is the failure mode the feature exists to surface, in the half
of the mechanism that amendment 2 says was never executed. **For an advisory, the asymmetry favours
flagging.** Same argument retires the `isHidden` consequence the plan accepts knowingly: a type on one
visible and one hidden level would stop producing silence.

This is not a demand for a particular rule. It is that the plan disposes of the case by citing a hazard
that a different reading does not have, and the choice to prefer silence over a conservative flag is
never argued. BAR-002 now requires the argument, and requires whatever ships to be order-independent.

### 11. Wording constraints: something mechanical *is* available, and BAR-004's grep fails a correct file

The plan's whole defence against reporting a team-scoped fact as a project-wide one is a bulleted list of
phrasings applied by a reader. Two things are available that are not being used.

**A single sanctioned sentence, fenced, quoted verbatim in the file.** The wording constraints then
collapse to one literal that a checker can find, and the runtime has one form to emit rather than a set of
prohibitions to respect. Precedent is in the same section: 8e item 5 already requires *"the exact `az`
command for the first item, **verbatim**. Not a template and not a description."* Applying the same idiom
to the one sentence that must not overclaim is consistent, not novel.

**And BAR-004's forbidden-token half fails today.** It asks a reader to confirm *"no `will fail` and no
`invalid`"*. `invalid` already appears twice in correct existing text — `SKILL.md:321` (*"an in-band
override **invalidates** the preview"*) and `SKILL.md:460` (*"a failed link never **invalidates** the
item's creation record"*) — and `safe` appears six times. This is the defect BAR-005 already guards
against for `SPIKE` and BAR-004 does not: an expected-hit set written down before the check runs, and no
count assertion (bar-soundness row 5). Note also that the matcher cannot be `grep -iF` on this machine
(`memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md`). Repaired below.

### 12. Three seams no bar reaches

- **`## Files` row 3 is checked by nothing.** `docs/ado-delivery-pipeline-brief.md` is verify-only with
  *"record the check either way"*, and no bar records it. It is likely to pass — the brief describes the
  preview at feature granularity and enumerates no preview items — but "likely to pass" and "checked" are
  the distinction this pack keeps losing. BAR-016 added.
- **Counts elsewhere in the two edited sections go stale silently.** Item 1 says *"all four, since area and
  iteration are project-specific"*; 8a says *"four gates with three verdicts"*; 8e says *"nine things"*.
  Adding a team to item 1 makes the first false, and finding 6's second option makes the second false.
  Nothing checks any of them, and `docs/plans/devops-azure-batch-write.md` BAR-002 checks item 1 by its
  four literals, so it stays green either way. BAR-015 added.
- **Zero candidate teams is more likely a broken derivation than a real configuration.** On a project with
  at least one team, the default team usually owns the root area path, so an empty candidate set is
  evidence the parse or the coverage rule is wrong. Reported as a bare `UNKNOWN` it is indistinguishable
  from a configuration where no team's board displays these items — bar-soundness row 3. Folded into
  BAR-001.
- **BAR-009 and BAR-010 both counted the memo's table wrongly.** Each said "four `INFERRED` rows"; the
  table has **four `OK` rows of which exactly two** carry that literal, the other two reading "executed
  for a *flat* item and for the parent". A checker working from the bar rather than the file would find
  two and report a defect in a correct memo — bar-soundness row 5, inside a bar written to guard the memo
  against exactly that. Both corrected.

### Reversibility and scope

The `SKILL.md` text is **easily reversible**. Two things in this cut are not. The **committed memo** and
its six-row table are the artifact most likely to become citable fact — that already happened once, to
v3's `101/20/1` counts, and BAR-010's instruction to leave amendment 2 and the status column alone is the
right guard. And whichever **predicate** the classifier is built on will be restated wherever the feature
is described afterwards; finding 1 is cheap to settle now and expensive to correct once "same category"
has propagated into four files, which is the exact cost the org-wide-tag overstatement incurred.

**Smaller version that proves the approach:** alternative B — level names as facts inside 8e item 2, plus
one sentence citing the observed refusal when two required types coincide. It needs 8a's team resolution
and 8c's inversion (kept), and drops the three-state vocabulary, the policy passage, the acknowledgement,
and the wording-constraint list. If it proves useful, the verdict layer is a later cut with the classifier
already in place — which is exactly the split Codex asked for, obtained by not building the second half
yet.

## EXECUTED 2026-08-04 — BAR-012 and BAR-013 were run before any text was written. Read this before the plan above.

Zero writes. Eight projects in one org, both routes. Full record:
`memory/known-issues/2026-08-04-ado-backlog-level-is-not-work-item-type-category.md`.

**Read the cross-model section below before this one — it splits finding 1 into a confirmed half and an
unproven half, and the first version of this section overstated it as confirmed entire.**

**Challenge finding 1's remedy is CONFIRMED; its feared mechanism is NOT.** A backlog
*level* and a work item type *category* are different things carrying the **same reference names**, and
they disagree: the `Microsoft.RequirementCategory` **level** holds `Bug` while the
`Microsoft.RequirementCategory` **category** does not, in **4 of the 6** projects that returned data — and
they **agree in 1**, which is how the false claim survived four design attempts. The executed refusal was
`User Story -> Bug`, so **the predicate the service enforces is backlog-level membership for a team**, and
a category-keyed rule would have stayed silent while the service refused.

**BAR-013's third outcome is therefore excluded by execution**, and its second is confirmed. `SKILL.md`
line ~224 is a **shipped factual defect** independent of this feature.

**BAR-012 is satisfied on its shape half and partially on its semantics.** `teamfieldvalues` returns
`field.referenceName = System.AreaPath` with a `values` array carrying `value` and `includeChildren` as
documented, and a root-level value with `includeChildren: true` covering descendants was observed. What was
**not** constructible is a team whose value is a strict ancestor of another team's — so the coverage rule's
shape is executed and its discriminating case is not.

**Five things were found that neither review predicted, and three of them change the design:**

1. **The `backlogs` response is an envelope `{count, value}`, not an array.** Parsing the envelope instead
   of `.value` yields **one row with every field empty, exit 0** — the check degrades to total silence
   while reporting success. This fired on the first live call.
2. **The route returns HTTP 500 for some teams that appear in the team list** — two of eight projects, on
   their first-listed team, non-zero exit. So a per-candidate loop **partially** fails as a matter of
   course. **The plan has no story for partial per-team failure**, only for total failure, and this is the
   single largest gap the probe exposed.
3. **A mapped type resolving to zero levels is ordinary, not exotic.** One team returned only two levels
   (requirement and task, no feature or epic); two others had no requirement level at all. So `UNKNOWN`
   from a missing level will be a routine outcome on real projects, not an edge case.
4. **A team commonly configures no area path at all** — two of three teams in one project returned an
   empty `defaultValue` and no `values`. "Read succeeded, no area path" and "read failed" are different
   states and only one is `UNKNOWN`; a candidate set is often empty or a single team for benign reasons.
5. **Multi-team is the norm, and process customisation is heavy.** 12 of 28 projects have more than one
   team and the largest has **81**; requirement levels hold up to **nine** types, most of them
   process-specific. This **confirms challenge finding 4**: "the check can never fire under the sanctioned
   default mapping" is not safe here, and two ordinary mapping choices can land on one level with no
   operator override at all. The team list was **not** truncated at 81 (default equalled `--top 1000`),
   which retires the pagination half of finding 7. `az` also emitted a **cp1252 encoding warning** that
   discards unsupported characters, so a team name with a non-cp1252 character is **silently mangled on
   output on this machine** — a fifth parse hazard, at 8a, for a design that routes on team names.

**Consequences for the plan above, none of which are yet applied to it:** every occurrence of "category"
in the mechanism must become "backlog level for team `<team-a>`"; `## Files` gains the `SKILL.md:224`
correction; the disposition table needs a **partial** read-failure row; and BAR-006 gains a fifth hazard.
The `20`-team budget is now known to bite real projects rather than hypothetical ones.

## SECOND REVIEW 2026-08-04 — cross-model (Codex, `gpt-5.5`), read-only, exit 0

It did **live documentation research** rather than inference, which is what this question needed. It ran
**before the probe above was executed**, so its finding-1 assessment rests on documentation alone — read
the two together.

**It splits finding 1, and the split matters more than either half.**

- **Confirmed:** backlog levels and work item type categories are separately-configurable concepts. The
  ProcessConfiguration XML has `PortfolioBacklog`/`RequirementBacklog`/`TaskBacklog` each carrying a
  `category` attribute, the category route is **project**-scoped while `work/backlogs` is **team**-scoped
  and documents its type list as overridable by team bug settings, and a level `id` is documented as only
  *"can be"* a category refname. **So the plan's category prose is unverified and the concepts are
  genuinely distinct.**
- **Unproven:** *"two valid backlog levels sharing one category"* — the specific silent false-negative
  finding 1 warns about — has **no documented support**. Inherited-process docs say each type belongs to
  only one backlog level, and the XML models one category per level. **Mark it a plausible adversarial
  hypothesis, not an established defect.**

**Reconciling that with the probe above, because they look contradictory and are not.** The divergence
observed — `Bug` on the requirement *level* but not in the requirement *category* — **is** the documented
per-team bug-behavior override, which Codex independently says to *"treat as expected"*. So the probe did
not demonstrate finding 1's feared mechanism. What the probe *did* establish, and which needs no such
mechanism, is that **a category-keyed classifier is wrong by execution**: the refused pair was co-level and
not co-category, so keying on categories yields silence where the service refuses.

**Both reviewers converge on the same remedy, and it is the cheaper of the two the challenge offered:**
name the predicate *"both types appear in the same returned team backlog level object"*, and stop saying
"category" in the surrounding prose. **That is what the existing level-`id` comparison already computes** —
so the fix is wording plus `SKILL.md:224`, **not** a new classifier input. Codex adds one mechanical
sharpening: **do not treat `BacklogLevelConfiguration.id` as a category reference at all**; the sound
positive signal is co-membership in the returned level object.

**Four things it adds that neither the plan nor the internal review had:**

1. **Facts-only is not sufficient on its own — the UI copy is the control.** Even a facts report invites
   operators to read quiet rows as "safe". It supplied concrete wording: same-level co-membership is
   reported as an observed condition that *"can make backlog reordering fail"*, and differing levels are
   *"informational only and not a guarantee that Azure DevOps will accept all reorder operations"*. **No
   green checks, no "safe", no "no known risk"** — a hard copy constraint, not a documentation note. This
   is the actionable form of the internal review's finding 9.
2. **Warn only on positive co-membership.** Drop `NO_KNOWN_RISK` as a label entirely; the negative case is
   *"no same-level condition observed by this route"*, which is a statement about the route rather than
   about the pair.
3. **A disposition for alternative A that is neither classifier nor bare control.** Read the category
   route additively and surface **non-bug** type disagreement between the two routes as its own
   `UNKNOWN`/config-mismatch state. Bug-category mismatch is expected and must not be surfaced. This is a
   third shape neither the plan nor the internal review proposed.
4. **Log the raw route evidence** so a future ADO surprise is debuggable rather than re-derived. This
   feature has re-derived its own mechanism four times.

**It sides with the challenge against the plan on finding 4**, independently: *"can never fire under the
sanctioned default mapping"* holds only for stock processes under expected team settings, and customised or
inherited processes plus per-team bug behavior can produce same-level pairs with **no operator override at
all**. It frames that as making the check **more** worth shipping. **Two models and one probe now agree the
plan's `## Risks` concession is wrong.**

**What it did not review, stated so nothing reads as covered:** findings **2, 5, 6, 7, 8, 10, 11 and 12**
were outside the brief it was given. The BAR-001/BAR-003 contradiction, the acknowledgement-clause scoping
bug, the unmeasured team budget, and the parse-hazard placement have had **one** reviewer.

## Dependency between the challenge's alternatives — recorded by the coordinating session

Asked of `devils-advocate` after its pass, because `## Challenge` finding 3 offers two alternatives and
`### Reversibility and scope` recommends one without saying whether it depends on the other. Its answer,
recorded here so the reasoning survives the session:

**A and B are independent, and B is the one that does not need finding 1 settled. "Implement smaller"
means B alone.**

The reason is structural and is the strongest argument for B. **B makes only two claims, both
observations:** that these mapped types sit on these backlog levels for team `<team-a>` — straight from
the `backlogs` read — and, where two coincide, that this is the configuration in which REST refused the
child's reorder on 2026-08-04 at both scopes. Neither claim needs to know whether the service's internal
predicate is a level or a category, because B restates an **observed correlation** between a read value
and an observed refusal. **Finding 1's hazard lives entirely in the negative direction, and B makes no
negative claim** — silence about a pair whose levels differ is not a verdict about it. The full design
*does* make that claim (`NO_KNOWN_RISK`, hedged), and its soundness is what depends on level ≈ category.

So the dependency is one-way:

| | Status |
|---|---|
| **Full design → A** | **Blocking.** BAR-013 must settle the predicate before any text asserts a category grouping; BAR-002's first clause enforces it. |
| **B → A** | **Advisory.** Worth running anyway — one zero-write read, and it is the cross-route control the prior challenge's concern 7 said was missing, which B inherits because B names a team and no read can prove the right team was read. It gates nothing. |
| **Either shape → BAR-012** | **Blocking.** B still needs 8a's team resolution, so `includeChildren` and the `teamfieldvalues` shape must be executed before 8a is written either way. **Adopting B does not relieve this**, and it is the one genuine pre-text blocker. |

**One consequence if B is adopted: BAR-013 must be reclassified as a control rather than a gate.** As
written its failure condition is "shipping while any text asserts a category grouping this read did not
observe", which under B cannot trigger. It is left in gate form deliberately — that framing is correct
if the full design is kept, and the shape is not yet chosen.

## REVISED DESIGN — adopted 2026-08-04. This is what gets built.

Chosen by the operator after both reviews and the probe: **the challenge's alternative B, with Codex's
copy constraints, plus alternative A additively as a non-bug mismatch surface.** Everything above this line
that conflicts with it is superseded.

**What it is: a facts display, not a classifier.** Inside 8e item 2 — which already shows the proposed type
mapping and asks for confirmation — each mapped ADO type is shown with the backlog level(s) it occupies for
each examined team. Where two types the tree requires occupy the **same returned level object**, one
sanctioned sentence is added. There is no verdict vocabulary, no acknowledgement, and no third state.

### The predicate, stated once and never as a category

**Two types are flagged when they appear in the same returned team backlog level object.** Not "the same
category" — that is a different object with the same reference names, and a category-keyed rule stays silent
where the service refuses (probe above; `SKILL.md` corrected in `ad837df`). **Never read a level `id` as a
category reference name**; it is documented only as *"can be"* one. Where operator-facing text wants the
word "category", it **quotes ADO's warning** and attributes it.

### What is displayed

| Case | Output |
|---|---|
| Two required types in the **same** returned level | The sanctioned sentence below, naming the team, the level, and both types |
| Types in **different** returned levels | `no same-level condition observed by this route` — a statement about the route, not about the pair |
| A type in **no** returned level, or in two | The observed fact printed as-is (`no level returned for <type>`), not a verdict |
| A team's level read **failed** | `not determined for team <team-a>` on that team's line only — the other teams still report |
| **Non-bug** type disagreement between the two routes | `config mismatch` surfaced separately, naming the types |
| **Bug** type disagreement between the two routes | **Not surfaced.** It is the documented per-team bug-placement override and is expected |

**The sanctioned sentence is quoted verbatim in the file**, the way 8e item 5 already requires the first
`az` command to be verbatim, so the one sentence that must not overclaim has a single literal form:

> Same returned backlog level observed for team `<team-a>`: `<type-1>` and `<type-2>` both sit on
> `<level-name>`. A live probe on 2026-08-04 and Microsoft's documentation show this can make backlog
> reordering fail on that team's boards. Different returned levels are informational only and are not a
> guarantee that Azure DevOps will accept all reorder operations.

**Hard copy constraints, from the cross-model review:** no green checks, no "safe", no "no known risk", no
`RISK`/`NO_KNOWN_RISK`/`UNKNOWN` labels anywhere in operator-facing text. Silence is never presented as a
clean bill of health, and the negative line is scoped to *this route* and to *the pairs this tree requires*.

### Team resolution, re-priced against a measurement

Runtime discovery and area-path narrowing are kept as chosen. **The read budget is now derived from a
measured cost rather than an assumed one:** `az` invocations against this org measured **~3.3s each**
(five samples, 2.46–3.77s). So the previously proposed 20-team cap meant `1 + 20 + 20 = 41` invocations ≈
**135 seconds** before a preview — *worse* than the minute of silence it was set to prevent. **Challenge
finding 7 was right and the number was indefensible.**

`N` is the project's **total** team count and is not reducible: narrowing requires reading every team's
`teamfieldvalues`, and no project-wide route returns them. So the budget is stated in **invocations against
a measured per-invocation cost**, and the fallback is not a refusal:

| Condition | Behaviour |
|---|---|
| `1 + N + M` ≤ **10** invocations (≈ 33s) | Narrow fully by area path, examine every candidate team |
| Above it | **Fall back to the project's default team only** — `az devops project show` returns `defaultTeam.name` in one ~2s read — and state on the face of the output that other teams were **not examined** |

The fallback is deliberate and is the facts-only philosophy applied to its own cost: show what was read,
say what was not. A refusal would make the feature silent on the 12-of-28 projects here that have more than
one team, and a project with **81** teams would need ~271s.

### What this shape drops, and what that dissolves

- **No verdict vocabulary**, so challenge finding 10's silence-versus-flag choice and the null-versus-null
  false flag (prior challenge concern 6) stop being decisions — an unresolved type prints as an observed
  fact.
- **No acknowledgement**, so **challenge finding 6 dissolves entirely**: `SKILL.md:306`'s clause is scoped
  to 8a's gate verdicts, and nothing here needs it. 8a's *"four gates with three verdicts"* is **not** an
  edit site, and no sentence checked by `docs/plans/devops-azure-batch-write.md` BAR-002 is widened.
- **No policy passage**, so the classifier/policy split is moot and BAR-003 is withdrawn.
- **The precedent problem dissolves rather than being accepted** (challenge finding 9): a report citing an
  **observed** refusal is not a derived prediction, so this stops being the first check in 8c–8h to act on
  one.
- **`isHidden` stops being a decision** — the level is printed with whatever the route returned.

### What it must additionally carry, from the probe

- **Partial per-team read failure is the normal case, not an edge.** Two of eight projects returned HTTP 500
  on the `backlogs` route for a team that appears in the team list. Failure is reported **per team line**,
  never as a whole-check outcome.
- **Five parse hazards, at both parse sites** (8a and 8c): the `{count, value}` **envelope** (parsing it
  instead of `.value` yields one empty row at exit 0); `az devops invoke` silently serving a **sibling
  route** (`teamfieldvalues`/`teamsettings` are literal siblings); PowerShell 5.1 **`ConvertFrom-Json`
  double-wrap**; **native-argument mangling**, which bit this session for real on a `git commit -m`
  here-string and bites here because a conventional team name contains a space; and **cp1252 output
  mangling**, which silently discards unsupported characters from a team name on this machine.
- **A team configuring no area path is a distinct state from a failed read** — observed in two of three
  teams in one project — and only the latter is "not determined".
- **Raw route evidence is logged in 8i** so a future ADO surprise is debuggable rather than re-derived. This
  feature has re-derived its own mechanism four times.
- **The plan's `## Risks` concession is deleted, not softened.** *"Under the sanctioned default mapping the
  check can never fire"* is wrong: two models and one probe agree. Requirement levels in this org hold up to
  **nine** types, mostly process-specific, so two ordinary mapping choices can collide with **no operator
  override at all**.

### Edit sites, revised

| # | File | Change |
|---|---|---|
| 1 | `skills/devops-azure/SKILL.md` | **8a**: team enumeration, area-path narrowing, the measured invocation budget and default-team fallback, three parse hazards. **8c**: the level inversion, the same-level predicate, the additive category read and its non-bug mismatch surface, two parse hazards. **8e item 2**: the per-type level display and the sanctioned sentence. **8e:321**: the level facts follow from the mapping. **8i**: raw route evidence |
| 2 | `memory/decisions/2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md` | Amend: the mechanism is level-keyed, not category-keyed; decisions 0/3/4 settled; the file's own title is now misleading and must say so |
| 3 | `docs/ado-delivery-pipeline-brief.md` | **Verify only**, and record the result either way |

**No longer edit sites**, each for a stated reason: 8e item 1 (no new resolved value is displayed there —
the team appears on the level lines in item 2), 8e item 7 (reads, not writes), 8a's gate table (no gate is
added), and step 7's one-confirmation rule (no confirmation is added).

### Bar dispositions under the revised design

**APPLIED 2026-08-04 — the bar bodies below are rewritten against this design.** This table is the record
of what moved and why. `scripts/lint-plans.sh`: 24 passed, 0 failed, 18 bars, ids unique, BAR-009's
`Gated:`/`Cost:` pair intact.

**Who rewrote them, stated because it matters:** `devils-advocate` authored the audited versions and the
coordinating session rewrote them against a design the reviewer did not see, exactly as
`docs/plans/bar-cost-and-first-run.md` had to do when its change 2 was redesigned mid-review. **BAR-005,
BAR-011 and BAR-016 are the reviewer's text, unaltered.** Every other edit is the session's, and each
reviewer finding that motivated one is preserved in the bar rather than discarded — BAR-003 is withdrawn
with its diagnosis kept, BAR-009 is demoted rather than deleted, and BAR-014 takes its own escape clause.

| Bar | Disposition |
|---|---|
| BAR-001 | **Edit** — budget becomes the measured invocation count plus the default-team fallback; drop the `UNKNOWN` label |
| BAR-002 | **Edit** — predicate is same-returned-level co-membership; no verdict vocabulary; no level-`id`-as-category reading |
| BAR-003 | **Withdraw** — no policy passage exists to be split from the classifier |
| BAR-004 | **Edit** — no acknowledgement; check the sanctioned sentence verbatim and the no-green-checks constraints |
| BAR-005 | **Keep** — the `SPIKE` dedupe applies to the facts display unchanged |
| BAR-006 | **Edit** — five hazards, both sites |
| BAR-007 | **Edit** — "pair verdict" becomes "level facts"; the item-7 negative half is unchanged and still matters |
| BAR-008 | **Edit** — add the partial-per-team-failure observation |
| BAR-009 | **Keep, demoted** — B makes no negative claim, so this is no longer load-bearing; NOT RUN remains acceptable |
| BAR-010 | **Edit** — decision 3's settled value changed, and the memo's title is now part of what must be corrected |
| BAR-011 | **Keep** |
| BAR-012 | **Satisfied on shape, partial on semantics** — see `## EXECUTED`; the strict-ancestor case was not constructible |
| BAR-013 | **Reclassify as a control, and partially executed** — the two routes were compared; its third outcome is excluded by execution |
| BAR-014 | **Edit** — satisfied by the observed-refusal citation, per its own escape clause |
| BAR-015 | **Edit** — drop the "four gates with three verdicts" clause; that phrase is no longer falsifiable by this cut |
| BAR-016 | **Keep** |
| BAR-017 | **Added** — a failed read is reported per team, with the three states a team's line can carry distinguished |
| BAR-018 | **Added** — raw route evidence logged in 8i, as observations rather than as the conclusion |

One further correction the rewrite produced, recorded because it is the defect this repo keeps shipping:
**BAR-006's subject was retitled from "the four parse hazards" to a count-free form** after the probe took
the list from four to six. A counted subject goes stale the first time the list grows, which is why
`agents/tech-lead.md` keeps a count out of its own heading — and the stale count was introduced *by this
rewrite* and caught one edit later.

## Acceptance bars

- BAR-001: the team is derived from the area path, bounded by a read budget, and named in the preview in every branch
  Evidence: files -> `skills/devops-azure/SKILL.md` 8a. Confirm five things. (i) Teams are enumerated with `az devops team list`, at run time, with **no environment variable and no hardcoded `<project> Team` convention**. (ii) The candidate set is the teams whose `teamfieldvalues` `System.AreaPath` values **cover the area path 8a already resolved**, with `includeChildren` honoured — not the whole team list, and not the default team. (iii) All three branches are written: exactly one candidate → used and **named**; several → examined **per candidate** and reported per team; zero → **the default-team fallback**, with a printed reason saying that a derivation defect is the likelier cause than a project where no team's board shows these items — on a project with at least one team the default team usually owns the root area path, so a bare "no candidates" here is produced identically by a broken parse and by a real configuration (bar-soundness row 3). **Also confirm the file distinguishes "the team configures no area path" from "the read failed"**: two of three teams in one probed project returned `System.AreaPath` with an empty `defaultValue` and no `values` array, at exit 0, so the benign state is common and only the failure is "not determined". (iv) The read budget is stated **in invocations against a measured per-invocation cost**, and the measurement is in the file: `az` invocations measured **~3.3s** against this org (five samples, 2.46–3.77s), so `1 + N + M` at a 20-team cap is ≈ **135s** — worse than the silence such a cap is set to prevent. **A number with no measured basis fails this bar even though it is a number** (bar-soundness row 6 applied to a limit rather than a gate); the earlier wording, "stated as a number", passed for any number at all. Confirm the budget is **10 invocations** or another figure the stated measurement supports, and that **the escape is the default-team fallback rather than a refusal** — `az devops project show` returns `defaultTeam.name` in one ~2s read — with the output stating on its face that other teams were **not examined**. A refusal here would make the feature silent on the majority of multi-team projects, which is the `VS402337` shape the third design carried. Also confirm the file states that `N` is the project's **total** team count and is **not reducible**, since narrowing requires every team's `teamfieldvalues` and no project-wide route returns them — a file implying the budget can be met by narrowing first has the data flow backwards. The team list was observed **not** truncated at 81 teams (default equalled `--top 1000`), so a truncation caveat is optional here rather than required. (v) **The file states that no available read can prove the right team was read** — the `backlogs` response carries no team echo — so the mitigation is that the team is *derived* and *named*, and the operator is the check. **This is a text check and this line says so:** presence of correct-sounding prose about an external system is not correctness (bar-soundness row 1), and (ii)'s coverage semantics are executed in BAR-012 **before** this text is written, not in BAR-008 afterwards.
- BAR-002: the classifier names the predicate it actually tests, emits three states, and enumerates every `UNKNOWN` trigger rather than implying it
  Evidence: files -> `skills/devops-azure/SKILL.md` 8c. **First, the predicate.** Confirm the text names what is compared as the **backlog level** for the named team, and that **no sentence in the cut asserts that two types share a work item type *category*** unless BAR-013 recorded a read that establishes it. Every executed read on record returns levels; "category" is a second claim, and the file's own note that a level `id` is only documented as *"can be"* the category refname is the reason the two may come apart. Where the operator-facing text wants the word, confirm it appears as a **quotation of ADO's warning** ("same category hierarchy on this backlog") rather than as this cut's own derived claim. A file that reports level equality while calling it category equality fails this bar (bar-soundness row 1). **Then confirm the verdict vocabulary is absent, which is the inverse of what this bar asked before the design changed.** `RISK`, `NO_KNOWN_RISK` and `UNKNOWN` must appear **nowhere in operator-facing text** — the adopted shape reports observed facts, and both reviewers independently asked for the labels to go. Confirm the flag fires on **positive co-membership only**: two required types appearing in the **same returned level object**. **Confirm the file does not compare level `id` as a category reference name** — the sound signal is co-membership in the returned object, and a level `id` is documented only as *"can be"* a refname; the `name` is what is displayed. Then confirm each remaining case renders as a **printed observation rather than a verdict**: a type in no returned level prints as such; a type in two or more prints both, and the rule that reads them must be **order-independent** — a rule whose output changes with the order of the returned arrays fails this bar regardless of what it outputs. Then confirm the negative line is phrased as a statement about the **route** (`no same-level condition observed by this route`) and never about the pair, and that `isHidden` needs no decision because the level is printed as returned. **A file that reintroduces any of the three labels fails**, even if its underlying rule is correct: the labels are what made silence read as a clean bill of health. **Check them against an expected-hit set and assert no count**, because forbidding a label requires naming it: the shipped text names all three in one sentence *to prohibit them*, and a whole-file absence assertion would fail the very sentence that enforces this bar (bar-soundness row 5, the defect BAR-005 already guards against for `SPIKE`). **Expected hits: the prohibition sentence in 8e item 2, and nothing else in operator-facing text.**
- ~~BAR-003~~ **WITHDRAWN with the revised design.** It checked that the classifier and the policy were separable, by naming the single passage a reader would edit to promote `RISK` to a stop. **The adopted shape has no policy passage and no `RISK`** — it prints observed facts and never disposes of them — so there is nothing to separate and the bar's subject does not exist. Retained rather than deleted because its diagnosis was load-bearing: it is the bar that found the BAR-001 contradiction and proved the two-directional locality test false on a correct file, and both of those corrections survive in BAR-001 and here. Original text follows.
- BAR-003: the classifier states no consequences and the disposition lives in one passage
  Evidence: files -> read `skills/devops-azure/SKILL.md` **8a, 8c and 8e** and confirm the **property**, not the presence of two headings. In the derivation text — which spans **8a and 8c**, since 8a resolves the team and applies the read budget — `RISK`/`NO_KNOWN_RISK`/`UNKNOWN` appear **only as labels**: no sentence in either section says what any of them causes, including the budget's escape, which states the label and not "and proceed". 8a is named explicitly because the classifier is split across two sections and an earlier version of this bar read only 8c, which is where half the derivation is not. In the disposition text, no sentence restates a derivation step. **The test that makes this non-cosmetic, stated one-directionally because the two-directional form is false on a correct file:** name the single contiguous passage in **8e** a reader would edit to change `RISK` from a warning to a stop, and confirm **no passage in 8a or 8c** would also need editing. Do **not** require that no other passage anywhere would change — a stop in this mode is plumbed at **8e item 4** and again at **8e:327**, so promoting `RISK` to a stop touches those however cleanly the split was done, and the earlier two-directional wording failed a file that did everything right (bar-soundness row 4: the named evidence was unproducible). **Any split satisfies "two sections exist"**, which is why this bar checks edit locality instead.
- BAR-004: the verdict lands inside the checked nine, the wording constraints hold, and the acknowledgement leaves a record
  Evidence: files -> `skills/devops-azure/SKILL.md`. Confirm the level facts and the examined team(s) appear **inside 8e item 2**, as an extension of the type-mapping display it already shows — that is one of the numbered nine `docs/plans/devops-azure-batch-write.md` BAR-002 checks, **not** the un-numbered informational bucket beyond item 9, which nothing checks. **Then confirm the negative half, which is what the revised design bought:** the file adds **no acknowledgement** and **no gate**, so `SKILL.md:306`'s clause — "every gate verdict from **8a** here, including any warning requiring acknowledgement", scoped to 8a's gates — is **not** widened, 8a's "four gates with three verdicts" is **unchanged**, and no sentence checked by that other plan's BAR-002 is edited. An earlier version of this bar required the opposite, because the superseded design needed an acknowledgement the cited clause did not actually cover (bar-soundness row 2, an instance clause read as a category). **A file that reintroduces an acknowledgement here fails this bar**, and it also reopens the precedent question the revised design dissolved. Then confirm the operator-facing line is written as **one sanctioned sentence, quoted verbatim in the file** the way 8e item 5 already requires the first `az` command to be quoted verbatim, rather than described. A single literal is the only mechanical handle available on the wording constraints, which are otherwise prose applied by a reader. Confirm that sentence satisfies five constraints: it does not say the pair *will* fail or is *invalid*; it reports a **same returned backlog level observed**, attributing the consequence to the 2026-08-04 probe and Microsoft's documentation rather than predicting; the claim is **scoped to a named team** rather than asserted of the project; it states that **different returned levels are informational only and not a guarantee** that Azure DevOps will accept all reorder operations; and the negative statement is scoped to **the pairs this tree requires**, never to board health. **Then the copy constraints, which are hard and not stylistic: no green checks, no "safe", and no `RISK`/`NO_KNOWN_RISK`/`UNKNOWN` label anywhere an operator reads.** A quiet row must not render as a pass — that is the whole failure mode a facts report is exposed to, and it is the one thing the cross-model review insisted on. **Check the forbidden wording against an expected-hit set written down before the check runs, and assert no count** — `invalid` already appears in correct existing text at `SKILL.md:321` ("an in-band override **invalidates** the preview") and `SKILL.md:460` ("a failed link never **invalidates** the item's creation record"), and `safe` appears six times, so a whole-file absence assertion fails a correct implementation (bar-soundness row 5, the same defect BAR-005 guards against for `SPIKE`). The matcher must not be `grep -iF`, which aborts on this machine (`memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md`). Then confirm the **narrow** consequence is stated — REST refuses the same-category **child's** reorder at both scopes, and the sprint board disables reordering board-wide and hides the **parent** — and that the broad version ("the board will not reorder", "items go missing", "silently") has **not** reappeared. That paragraph's mechanism has been wrong three times; a checker reading only for the new text will miss the old text coming back. Finally confirm **8i** carries the **raw route evidence** — the levels returned per examined team and the category route's grouping — so a future ADO surprise is debuggable rather than re-derived. This feature has re-derived its own mechanism four times, and the evidence log is the cross-model review's one addition that costs nothing and pays every time the service changes.
- BAR-005: the `SPIKE` alias dedupes, and no text credits the check with a capability it lacks
  Evidence: files -> `skills/devops-azure/SKILL.md`. Confirm the dedupe is on the **mapped ADO `(parent type, child type)` pair**, so `FEATURE -> SPIKE` and `FEATURE -> STORY` render as **one** row — dedupe on the tree-level pair would render two. Then `grep -n 'SPIKE' skills/devops-azure/SKILL.md` and read **every** hit against an expected set written down before the check runs: no hit may claim the check finds a SPIKE-specific problem. **Assert no count.** `SPIKE` appears legitimately in 8b's id regex, 8c's mapping table and by-name flag, and 8h's no-parent rule, so a count assertion fails a correct implementation (bar-soundness row 5).
- BAR-006: every parse hazard is named at the site where it bites, and blank is never an empty configuration
  Note: **this subject carries no count on purpose.** It said "four" when written and the probe found two more; a counted subject goes stale the first time the list grows, which is the same defect as a stale count in a pointer (`agents/tech-lead.md` states the rule for its own heading). Check the enumeration below, not a number.
  Evidence: files -> `skills/devops-azure/SKILL.md`. **This cut has two parse sites, not one**, and an earlier version of this bar named only the second while forbidding the hazards from appearing "elsewhere in the file" — which left the first site with no hazard text at all. Check the 8c passage that parses the `backlogs` response **and** the 8a passage that parses the team list and `teamfieldvalues`. Each hazard must appear at the site where it bites, not three sections away, since a hazard a reader does not encounter while writing the parse is not available to them. **A fifth hazard was found by execution after this bar was written and is now the most dangerous of the five: the `work/backlogs` response is an envelope `{count, value}`, not an array.** Parsing the envelope instead of its `.value` yields **one row with every field empty at exit 0** — so every type resolves to "no level" and the whole check degrades to silence while reporting success. It fired on the first live call of this design. Confirm it is named at the 8c parse site with the `.value` requirement explicit. **A sixth, at 8a only:** `az` emitted *"Unable to encode the output with cp1252 encoding. Unsupported characters are discarded"* on the largest project, so a team name carrying a non-cp1252 character is **silently mangled on output on this machine** — and this design routes on team names. Then confirm the original four, each with its repo citation: `az devops invoke` **silently serving a sibling route** — the documented instance is this route family, and `teamfieldvalues`/`teamsettings` are literal siblings on it, so this one belongs at **both** sites, with BAR-002's shape assertion named as the mitigation; the PowerShell 5.1 `ConvertFrom-Json` **double-wrap** (`memory/context/2026-08-03-powershell-convertfrom-json-array-double-wraps.md`), which lands at **8a** first because the team list is this cut's array response; **native-argument mangling** (`memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md`), which also lands at **8a** first because a conventional team name **contains a space** and reaches `teamfieldvalues` as a route parameter; and **blank output with exit 0 read as `UNKNOWN`, never as "no teams" or "no levels"**, trusting `$LASTEXITCODE` and never `$?`, at both sites. Each of these was dropped from the third design's specification and each would make the check report a clean derivation while having parsed nothing.
- BAR-007: an in-band mapping override re-runs the derivation, and the previewed write count is untouched
  Evidence: files -> `skills/devops-azure/SKILL.md`. Confirm the passage at the in-band-override rule names the **level facts** as a thing that follows from the mapping and therefore invalidates the preview — the levels are looked up by mapped ADO type, so an override that changes a type changes which levels are displayed and whether two of them coincide, and a preview showing the old level lines describes a run that would not happen. **Then the negative half, which is the one that can go wrong quietly:** confirm 8e **item 7 still counts creates plus parent/child link additions and nothing else**, and that no read introduced by this cut was added to it. Item 7 is the number the operator confirms and 8i reconciles three ways against it; a read counted there produces a reconciliation mismatch on every clean run. Also confirm **step 7's one-confirmation rule is unedited** and still carries both of its definite-singular statements of the amendment count — quote them from the file rather than from this bar.
- BAR-008: the whole derivation is executed end to end against a live project with zero writes
  Note: **RUN 2026-08-04 as part of a real 36-item batch write, and the derivation half is SATISFIED — with one caveat that must not be lost.** Team resolution resolved 1 team whose `System.AreaPath` value matched the resolved path exactly, at a budget of 3 invocations; the level read returned 4 levels for that team; the mapped types resolved to three distinct levels, so the output was `no same-level condition observed by this route` on both required pairs, and `SPIKE` items were parentless and contributed no pair. **The additive category control was genuinely exercised rather than vacuously passed:** the two routes differed on `Bug` **only** — present on the requirement level, absent from the requirement category — which is precisely the case the design says **not** to surface, and no config-mismatch line was emitted. **The caveat: this exercised the specification as text I followed by hand, not a skill the harness loaded.** The installed `~/.claude/skills/devops-azure/SKILL.md` was **108 lines and contained no batch write mode at all** at the time of the run, so nothing shipped in `ad837df` or `4e6ac5e` was reachable through `/devops-azure`. **A specification executed by its author is weaker evidence than one executed by the harness**, and this bar should be re-run after `install.sh` before anyone calls the path exercised. **Still NOT RUN:** the multi-candidate branch, because the project used has one team — see the note in the original text below, which was written expecting exactly this.
  Evidence: manual -> against `<org>/<project-a>`, run the classifier's four steps by hand and record the **observed values**: the team list, each team's `System.AreaPath` values with their `includeChildren` flags, the candidate set implied by the resolved area path, the `type -> level id` inversion per candidate, and the verdict for each pair a real tree requires. **Record values, never assert equalities** — a live project's team and level configuration changes, and pinning `<project-a>`'s current answer would fail a correct implementation later for a reason unrelated to the property (bar-soundness row 5). One thing must be **asserted**: that **zero `az` write invocations occurred**, measured against the project's pre-run item count — a non-zero value whose presence proves the read worked — and **not** against an anchor-tag query, which returns blank when nothing was created and would confirm "no writes" by breaking (bar-soundness row 3). The `includeChildren` assertion moved to **BAR-012**, which runs before the text is written rather than after; this bar is the end-to-end run of the shipped derivation and no longer the first execution of its premise. **Also assert the partial-failure path, which the probe showed is the normal case rather than an edge:** on a project with several teams, confirm that a team whose `backlogs` read fails is reported on **its own line** as not determined while the other teams still report. Two of eight probed projects returned HTTP 500 on that route for a team that appears in the team list, so a multi-team run that reports a single whole-check outcome is wrong in ordinary operation, not in an unlucky one. **Multi-team is available now and must be exercised:** 12 of 28 projects in this org have more than one team, so the earlier note that the multi-candidate branch would be unexercised no longer holds — a run that reports this bar clean against a single-team project has skipped the branch that carries every new failure mode, and must say so.
- BAR-009: the never-executed direction gets its first executed evidence, or the plan records that it did not
  Note: **DEMOTED by the revised design, and no longer load-bearing.** It was written when the design asserted `NO_KNOWN_RISK` — a negative claim whose soundness rested on this direction. The adopted shape makes **no negative claim** (silence is reported as a fact about the route), so a false negative here costs a missing line rather than a wrong assurance. **NOT RUN is now the expected outcome, not a concession.** Kept because the evidence would still be worth having, and because deleting a bar that records an untested direction is how the untested direction stops being visible.
  Evidence: manual -> **the untested half of the mechanism.** In a disposable project, nest a **different-category** child under a parent and attempt to reorder the child at **both** the product scope (`_apis/work/workitemsorder`) and the iteration scope (`_apis/work/iterations/{id}/workitemsorder`) — the two distinct endpoints the same-category probe used. Gate on a positive control first: a flat item in the same backlog must reorder successfully before any nesting exists, or a refusal proves nothing. Success at both scopes upgrades the memo's four `OK` rows to executed. **Count them from the file, not from this bar:** the table has **four** `OK` rows, of which exactly **two** carry the literal `INFERRED` and two read "executed for a *flat* item and for the parent". An earlier version of this bar said "four `INFERRED` rows", so a checker grepping for four labels would find two and report a defect in a correct memo (bar-soundness row 5). **A refusal is the more valuable outcome and must not be reported as a bar failure** — it would mean the classifier's silent direction is wrong, and the finding goes to the design, not to this bar. **NOT RUN is an acceptable outcome** provided the memo's amendment 2 wording stays exactly as it is and the plan's `## Risks` entry stands; what is not acceptable is shipping while any text implies this direction was executed.
  Gated: requires a disposable project the operator authorises for item creation, and it must not be run against a project anyone depends on.
  Cost: creates work items that this pack's `--destroy` permission cannot remove — `az boards work-item delete` soft-deletes to the project recycle bin and works, but `--destroy` fails `VS402324`, so the ids are **permanently consumed** and the items remain readable in the recycle bin by anyone with project access. The reorder call additionally **writes `Microsoft.VSTS.Common.BacklogPriority` across every item on the affected backlog level, not only the ids passed in the request body** (`memory/context/2026-08-04-az-reorder-writes-beyond-the-ids-you-pass.md`) — so a project used for this probe has values changed on items the probe never named.
- BAR-010: the memo's settled decisions stop reading as open
  Evidence: files -> `memory/decisions/2026-08-04-decision-pair-report-v4-keys-on-backlog-category.md`. Confirm open decisions **0**, **3** and **4** each record **what was chosen**, not merely that a choice exists: decision 0 names area-path narrowing with runtime discovery, the measured invocation budget and the default-team fallback; decision 3 names the **facts-only** display with **no verdict vocabulary**, so the three-state classifier it previously pointed at is recorded as **not adopted**; and decision 4 either corrects or drops the `SPIKE` claim. Confirm decisions **1** and **5** are left as they stand. **Then the correction this file most needs, which is its own framing:** the memo is titled and written as keying on **backlog category**, and the predicate is the backlog **level** — a different object with the same reference names (`ad837df`). Confirm the memo says so at the top rather than leaving a title that a later reader will cite, which is exactly what happened to the third design's `101/20/1` table. **Do not edit amendment 2 or the six-row table's status column** — every label in it is accurate until BAR-009 runs, and a memo edited to match a shipped design is how a table becomes citable fact, which is exactly what happened to the third design's `101/20/1` counts. **The count is four `OK` rows, two of them bearing the literal `INFERRED`**; an earlier version of this bar said "the four `INFERRED` labels", which does not match the file it protects.
- BAR-011: the changeset passes the mechanical gates it triggers, and the skipped gate is stated as skipped
  Evidence: tests -> invoke through `C:\Program Files\Git\bin\bash.exe` and **read the output every time**; blank output with exit 0 is this machine's documented Bash-tool failure signature (`memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`), so "exits 0" is satisfied identically by a gate running clean and by a gate never running (bar-soundness row 3). Run three: `bash scripts/lint-agents.sh` exits **0 with non-blank output naming the files it checked** — it fires because file 1 is in `skills/`; `bash scripts/lint-identifiers.sh` exits **0**, and if it exits **2** treat that as a self-test failure rather than a clean repo; and `bash scripts/lint-plans.sh docs/plans/ado-pair-report-v4.md` exits **0**, with the plan path passed as a **discrete argument** and never interpolated into a shell string. Then confirm `node scripts/obsidian-stop-hook.test.js` is **correctly skipped and the skip is stated out loud** — no file in this cut is one of the two hooks it covers, and a run of that suite here produces a PASS that checked nothing in the changeset.
- BAR-012: the candidate-set premise is executed **before** any 8a text is written, not checked afterwards
  Note: **RUN 2026-08-04, before any 8a text existed — satisfied on shape, NOT RUN on its discriminating case.** `teamfieldvalues` returned `field.referenceName = System.AreaPath` with a `values` array carrying `value` and `includeChildren` as documented, and a root value with `includeChildren: true` covering descendants was observed. **The strict-ancestor case was not constructible** on any available project, so the coverage rule's shape is executed and its discriminating semantics are not — recorded as NOT RUN with the reason, which is what this bar's own text demands. See `## EXECUTED`.
  Evidence: manual -> against `<org>/<project-a>`, with **zero writes**, read the team list and each team's `teamfieldvalues` and record the **observed response shape** — which field carries the area-path values, and whether an `includeChildren` flag is present per value as Microsoft's reference describes. Then **assert** the coverage rule: on a team whose area-path value is an **ancestor** of a chosen path, confirm by observation whether that team is or is not the owner of items at the descendant path. If the project's single team makes the ancestor case unconstructible, say **NOT RUN with the reason** rather than reporting the shape check as sufficient — a shape that matches the documentation is not the coverage semantics, and BAR-001(ii) rests on the semantics. **The ordering is the point of this bar and is not a preference.** v4's one real achievement over v1 and v2 is that its mechanism was executed *before* any design text existed; `includeChildren` and the `teamfieldvalues` shape are this cut's **new** premise, read from documentation, and scheduling their execution as an acceptance bar puts the text first again. This bar is satisfied or explicitly NOT RUN **before** 8a is written; a run that writes 8a first and executes afterwards fails it even if the premise turns out true.
- BAR-013: whether backlog-level equality is a sound proxy for category equality is settled by a read, not by prose
  Note: **RUN 2026-08-04, and RECLASSIFIED from a gate to a control.** The two routes were compared across eight projects: the requirement **level** held `Bug` while the requirement **category** did not, in four of six projects that returned data, agreeing in one. **The third outcome this bar contemplated — that the refusal follows the process's category — is excluded by execution**, since the refused pair was co-level and not co-category. Its second outcome is confirmed. It is a **control** rather than a gate now because the adopted design asserts no category grouping, so its stated failure condition ("shipping while any text asserts a category grouping this read did not observe") can no longer trigger — the assertion it guarded was removed instead, and `SKILL.md` was corrected in `ad837df`. **What survives as the live requirement is the additive use:** non-bug disagreement between the two routes is surfaced as a config mismatch, and bug disagreement is not, being the documented per-team override. See `## EXECUTED` and `## SECOND REVIEW`.
  Evidence: manual -> against `<org>/<project-a>`, with **zero writes**, read the project-scoped `wit/workitemtypecategories` route once and record, per category, its `referenceName` and `workItemTypes`. Then set that grouping beside the team-scoped `backlogs` level grouping already on record and state **which of three the observation supports**: the two groupings agree on the mapped types (level equality is a sound proxy here, and this is also the **cross-route control** the prior challenge's concern 7 said was missing — a control that is not the same call as the test); they disagree in a way showing the refusal follows the **team's level** (team-scoping confirmed, and confirmed by execution for the first time); or they disagree in a way showing it follows the **process's category** (the team apparatus is answering a question the service does not ask, and the design changes shape). **Record the observation; do not assert which outcome is expected.** Two claims in the record depend on this and neither came from a category read: `SKILL.md:224` ("`Microsoft.RequirementCategory` holds `Product Backlog Item`, `User Story`, **and** `Bug`") and the memo's "under `asTasks` the bug type moves to the task category". **A refusal or an inconclusive result is a finding for the design, not a bar failure** — but shipping while any text asserts a category grouping this read did not observe is a failure, and that is what BAR-002's first clause checks. This is the route the plan rejects as a trap; the rejection is sound as a *substitution* and says nothing about the *additive* use, which is what this bar exercises.
- BAR-014: the precedent is recorded where the next reader will encounter it
  Evidence: files -> `skills/devops-azure/SKILL.md`, at the passage carrying the verdict. **Take this bar's own escape clause: the revised design ships the smaller shape, so it is satisfied by the citation rather than by a precedent sentence** — the sanctioned sentence attributes the consequence to the 2026-08-04 probe and Microsoft's documentation, which is an observed compatibility fact and not a derived prediction, so the precedent is **dissolved rather than disposed of**. Confirm the citation is present and attributed, and confirm **no acknowledgement and no gate** was added — those are what would have re-created the precedent. The clause below applied to the superseded design and is retained as the test to apply if a later cut reintroduces a verdict: confirm one sentence states that this is the only check in 8c–8h acting on a **derived prediction** rather than on an observed service response or a reconciliation mismatch, and that this is why it is never a stop. The plan and the memo both record the precedent; **neither is in the path of a reader editing this file**, and this feature's entire history is that reviewers catch these and readers do not. Confirm also that the file does not describe the verdict as merely informational: an acknowledgement-requiring warning modifies the one confirmation this mode has, and every other such warning in 8a fires on a locally verifiable fact about the tree or the spec rather than on a prediction. If the cut ships the smaller shape — levels as facts plus a citation of the observed refusal — this bar is satisfied by the citation instead, and the reason must be stated.
- BAR-015: no count or enumeration elsewhere in the edited sections was left stale
  Evidence: files -> `skills/devops-azure/SKILL.md`. Two phrases in the edited sections are counts this cut could falsify, and nothing else checks either: 8e item 1's **"all four"** (org, project, area path, iteration path — a fifth resolved value displayed there makes it wrong, which is why the revised design keeps the team on item 2's level lines instead), and 8e's **"nine things, in order"** (wrong if the level display became a tenth numbered item, which it must not — the un-numbered bucket beyond item 9 is checked by nothing). **8a's "four gates with three verdicts" is no longer falsifiable by this cut** and its clause is withdrawn from this bar: the revised design adds no gate. Confirm that phrase is **unedited** rather than checking it for staleness — if it changed, a gate was added and BAR-004 has already failed. Read each in the shipped file and confirm it is still true of what the file now says. `docs/plans/devops-azure-batch-write.md` BAR-002 checks item 1 by its four literals and stays green either way, so it is not a substitute for this check. **Assert the truth of each phrase, not its presence** — a stale count is present and wrong, which is the state this bar exists to catch.
- BAR-016: the verify-only file was actually verified, and the result is recorded either way
  Evidence: files -> `docs/ado-delivery-pipeline-brief.md`. Confirm its description of the batch preview and the single confirmation is still accurate after this cut, and **record the outcome in the handoff whether or not anything changed**. `## Files` row 3 is verify-only and was covered by no bar; the expected result is that it passes untouched, since the brief describes the preview at feature granularity and enumerates no preview items. **"Expected to pass" is not "checked"** — an unrecorded verification is indistinguishable from one nobody ran, which is the failure this pack has produced repeatedly.

- BAR-017: a failed read is reported per team and never as a whole-check outcome
  Evidence: files -> `skills/devops-azure/SKILL.md` 8c. **Added by the revised design, because the probe showed this is the ordinary case rather than an edge.** Two of eight probed projects returned HTTP 500 (`too many 500 error responses`, non-zero exit) on the `work/backlogs` route for a team that appears in the team list. Confirm three things. (i) Failure is attributed to **the team whose read failed**, on that team's own line, and the remaining examined teams still report their levels — a whole-check "unavailable" line on a multi-team project would discard facts that were successfully read. (ii) The file distinguishes the **three** states a team's line can carry, because two of them are benign and only one is a failure: levels returned; **no area path configured** for that team, so it was never a candidate; and **read failed**. Two of three teams in one probed project returned an empty `defaultValue` with no `values` array at exit 0, so conflating the middle state with the third would report failures on ordinary configurations. (iii) The file states that a type resolving to **no level** is an ordinary configuration and not an anomaly — one probed team returned only two levels, with no feature or epic level at all, and two others had no requirement level — so this prints as an observed fact and never as a defect. **This bar's subject is the negative of what the superseded design assumed**, which treated read failure as a single whole-check condition.
- BAR-018: the raw route evidence is logged, so the next surprise is debuggable rather than re-derived
  Evidence: files -> `skills/devops-azure/SKILL.md` 8i. Confirm the report records, for each examined team, **the levels the route returned** (id, name, and the type list) and **the category route's grouping**, as observed values rather than as the conclusion drawn from them. **Then confirm it is the evidence and not a restatement of the verdict:** a log that records "no same-level condition observed" has preserved nothing, since that is the output, and the whole point is that a future reader can see what the service said when the conclusion turns out wrong. This feature has re-derived its own mechanism **four** times and each design's probe harness was discarded — `## Reproducing` in the memo says so explicitly for the 2026-08-04 run. The cross-model review asked for this and it is the one addition here that costs nothing at write time and pays every time Azure DevOps changes.

## Deviations

- **Call:** `### Edit sites, revised` row 1 — 8a gets "three parse hazards". **Shipped instead:** four at
  8a. The **sibling-route** hazard was added there as well, because BAR-006 requires it at *both* parse
  sites and the edit-site table's count was written before that bar was. **Decided by:** the coordinating
  session, on discovering the two disagreed while verifying the implementation. The bar is the stricter
  and better-reasoned of the two, so the table's count was the thing that was wrong.
- **Call:** `### Edit sites, revised` row 2 — the memo's "title is now misleading and must say so".
  **Shipped instead:** the title says so and the file was **not renamed**, which the plan left open.
  **Decided by:** the coordinating session — three files and two commits in this session already cite it
  by path, so a rename buys a correct title at the cost of dead references. The title is left standing as
  the warning, with the correction as the file's first section.
- **Call:** BAR-002's "a file that reintroduces any of the three labels fails". **Shipped instead:** the
  labels appear once, in 8e item 2, **in the sentence that forbids them.** The bar was amended to carry an
  expected-hit set rather than the implementation being changed, because a prohibition cannot be written
  without naming what it prohibits — the alternative was a file that enforces the constraint nowhere.
  **Decided by:** the coordinating session, applying the same reasoning BAR-005 already carries for
  `SPIKE`.
- **BAR-001(v) was unmet on the first pass and fixed rather than deviated from** — the no-team-echo
  limitation was missing from 8a. Recorded here because "found during verification and fixed" is a
  materially different state from "shipped as specified", and only one of them says the bar did its job.
- Everything else shipped as the revised design stated it. **8e item 1, 8e item 7, 8a's gate table and
  step 7's one-confirmation rule were confirmed unedited**, as the design's "no longer edit sites" list
  requires — verified by reading each, not by assuming the absence of a diff.

## EXECUTED 2026-08-05 — BAR-012's discriminating case, closed by observation. Zero writes.

Appended rather than edited into the bar above. **BAR-012's `Note` still reads "NOT RUN on its
discriminating case" and the 2026-08-04 section still says the strict-ancestor case was "not
constructible" — both are superseded on that half by this section, and are left standing** because a
merged plan records what a change meant to do. The same append-don't-rewrite handling the `## SECOND
REVIEW` section already applies to the 2026-08-04 record.

**The semantics half is SATISFIED, and the answer is the permissive one.** A team whose area-path value is
a **strict ancestor** of a chosen path, carrying `includeChildren: true`, **is** the owner of items at the
descendant path — and **ownership is not exclusive**. The same items appear in **both** teams' requirement
backlogs at once. Observed in a 7-team project, `<org>/<project-a>`:

| | area value | `includeChildren` | `backlogIteration` | requirement backlog returned | the four descendant-path items |
|---|---|---|---|---|---|
| team A (ancestor) | `<project-a>\A` | **true** | `\I` | **11** items | **all four present** |
| team B (descendant) | `<project-a>\A\B` | false | `''` (project root) | **4** items | exactly those four |

The four items are pre-existing `Product Backlog Item`s at `<project-a>\A\B`, on iterations `\I` and
`\I\S1`. Both teams return the same five levels, and `Microsoft.RequirementCategory` holds
`Product Backlog Item|Bug` on both — so the level route's grouping is not the variable here.

**The confound that blocked this for a day is `backlogIteration`, and holding it constant is the whole
method.** A team backlog filters by iteration *as well as* area path — a fact this repo's `memory/` does
not yet record, and which nothing in either skill mentions. Team A's window is `\I`; the
120-item batch of 2026-08-05 wrote every item to the **project-root** iteration, which is outside `\I`.
Reading those items would have returned nothing for team A and proved nothing — indistinguishable from
`includeChildren` not granting ownership. **The four items used here sit inside *both* windows**, so area
path is the only variable that moves. **A run that does not state which iteration window each team carries
has not executed this bar**, whatever it returns.

**This closes the bar with zero writes, which its own `Evidence` line requires.** The route recorded in the
2026-08-05 session notes as the fix — *create one item at the descendant area path* — **would have breached
that constraint**, and was unnecessary: the discriminating items already existed and predate this feature
entirely.

**Two hazards found, one of them new and one a second sighting:**

1. **`az devops invoke --area work --resource backlogs` silently drops a `backlogId` route parameter and
   serves the sibling `backlogs` *list*.** Exit 0, envelope `{continuation_token, count, value}`,
   `count=5`, first `value[0].id` the project's custom top level — i.e. **the level list, presented where
   the caller asked for that level's work items**. Nothing in the response says the sub-route was not
   reached. This is a **second confirmed instance of BAR-006's sibling-route hazard**, now with a concrete
   reproduction rather than a documented-instance citation, and it is the reason this read went over REST.
   The slashed form `--resource teamsettings/iterations` is rejected outright (exit 1), which is the benign
   failure; this one is the dangerous shape.
2. **`Invoke-RestMethod` needs its own read-failure doctrine, exactly as the 2026-08-03 challenge
   predicted.** It **throws** on non-2xx instead of returning blank plus a non-zero exit, so the pack's
   entire "blank output is `UNKNOWN`, trust `$LASTEXITCODE` never `$?`" rule — written for `az` — does not
   transfer. The read here wraps each call and reports the status code, and distinguishes *no `workItems`
   key* from *an empty list*, because only the second is a zero result.

**The bearer-token cost was paid without the exposure the challenge feared** — concern 10 of
`memory/known-issues/2026-08-05-challenge-backlog-title-guard-and-utf8-title-read.md`. The token was fetched into a
variable **inside a single shell process**, used as a header, and never echoed; only its character length
reached the agent transcript. Verified afterwards rather than asserted: **zero** strict three-segment JWTs
in either session transcript or in any temp file written by the run. **Redacting a token after capture is
the weaker mitigation** — it does not invalidate the credential and it has to catch every copy — so
never-capture is the pattern this pack should use if a REST read is needed again.

**Still NOT RUN, and unchanged by this section:** BAR-008's multi-team and per-team-read-failure halves,
and its re-run through a harness-loaded skill. `install.sh` had not been re-run at the time of this
section, so nothing here exercised `/devops-azure` as the harness would load it — **this was the
specification followed by hand, which BAR-008 already records as the weaker evidence.** BAR-009 remains
NOT RUN and expected to stay so.

**One incidental confirmation.** Item titles read back over `az` carry `U+FFFD` where the tree wrote an em
dash, while the same titles are intact over REST — the cp1252 output mangling, observed a second time and
on titles rather than team names. It changes no decision here; the challenge already concluded that
documenting the false-positive mode is the only unconditionally correct fix.

## EXECUTED 2026-08-05 (second) — BAR-008's remaining halves, through the harness-loaded skill. Zero writes.

Appended rather than edited, on the same handling as the two sections above: **BAR-008's `Note` still reads
"Still NOT RUN: the multi-candidate branch" and its `Evidence` line still calls multi-team unexercised —
both are superseded by this section and are left standing**, because a merged plan records what a change
meant to do.

**All three remaining halves are now RUN. The bar is satisfied.**

**What "harness-loaded" means here, stated precisely because the bar rests on it.** `install.sh` was
re-run before this section: the installed `skills/devops-azure/SKILL.md` is **596 lines and hash-identical
to the repository copy**, with batch write mode present, against the **108 lines and no batch mode** the
2026-08-04 note records. The specification reached this run through the harness's skill loader rather than
by my reading the repo file by hand, which is the difference the bar asked for. **What it does not mean is
that something other than an agent executed the steps** — no such executor exists, and a later reader
should not take this section as claiming one.

### The multi-candidate branch — RUN, against a 7-team project

Target area path `<project-a>\A\B`, the same descendant path the section above used.

| | |
|---|---|
| `N` (total teams) | **7** |
| `M` (candidates) | **2** — team B by exact match, team A as **ancestor with `includeChildren: true`** |
| Budget `1 + N + M` | **10, exactly at the cap of 10** → narrow fully, examine both |
| Non-candidates | 4 teams with area values not covering the path; **1 team with no area value at all** |
| Levels returned | **5 per examined team**, identical on both |
| Required pairs | `Feature → Product Backlog Item` and `Product Backlog Item → Task`, both on **different** levels on both teams → `no same-level condition observed by this route` |

**The type mapping was discovered, not assumed, and the stock mapping was wrong for this project.**
`User Story` **does not exist** among the project's 16 types; the requirement level holds the Scrum
requirement type instead, with 23 existing items proving it creatable. The operator confirmed the override,
which is 8e's in-band-override path working as specified.

**The additive category control was again exercised non-vacuously.** The two routes disagreed on the bug
type **only** — present on the requirement *level*, absent from the requirement *category* — which is
precisely the documented per-team override the design says **not** to surface, and no config-mismatch line
was emitted. This is the second independent observation of that shape.

### The per-team-read-failure branch — RUN, and the finding is that the budget hides it

**This half needed an org-wide sweep to construct at all, and the sweep is the more valuable result.**
Across **29 projects and 184 teams**, every team whose `work/backlogs` read fails returns HTTP 500 — and
**28 of those 29 teams have no area path configured**, so the derivation excludes them as non-candidates
*before* it would ever read their backlog. **The failure state and the benign "never a candidate" state
coincide almost perfectly**, which is the opposite of what BAR-017 assumed when it called partial failure
"the ordinary case rather than an edge".

**The one exception is the whole finding.** In a 16-team project `<project-b>`, two teams carry the project
root as an exact area value: one returns 5 levels, the other **fails with HTTP 500**. Point a tree at that
root path and both are candidates, so the branch is reachable — **but `1 + 16 + 2 = 19` exceeds the cap of
10, so 8a falls back to the default team, and the default team is the healthy one.** In the single project
in this org where the failure branch can fire, **the read budget's fallback reads past it and reports a
clean derivation.**

With the budget **deliberately overridden on operator authorisation**, the branch behaves as BAR-008
requires: the failing team prints `not determined for team <team> — read failed` **on its own line**, and
the other candidate still reports its five levels beside it. **So the branch is correct and effectively
unreachable at the same time**, and the second half of that sentence is not visible from reading the file.

**One incidental observation from that project, recorded because it contradicts a natural assumption:** its
requirement level carries **four** work item types and its task level carries four including the bug type —
so the bug type sits on the **task** level there, not the requirement level. Level composition varies far
more between projects than the two probed so far suggested, and any future reasoning from "the requirement
level holds the requirement type and the bug type" is reasoning from a sample of two.

### Zero writes, asserted rather than assumed

**Zero `az` write invocations across everything in this section.** The two derivation runs issued **22** and
**20** read invocations; the sweep issued **243** by construction (1 project list + 29 team lists + 184
backlogs + 29 follow-up reads on the failures). The positive control the bar requires is the **61
pre-existing work items** the reconciliation control query returned in `<project-a>` — a non-zero value
whose presence proves the read mechanism worked, rather than an anchor-tag query that returns blank when
nothing was created.

The reconciliation path itself executed end to end: the anchor-tag query returned **blank at exit 0**, the
**positive control returned 61 rows**, so the blank was resolved as *genuinely zero matches* rather than as
a failed read — the normal first-run path, and the first time that control has been exercised live.

### Two live defects in the shipped skill, found by executing it

Neither is a bar failure; both are defects in `skills/devops-azure/SKILL.md` that this run found because it
ran the file rather than read it. **Both are `/plan` work and are deliberately not fixed in this section.**

1. **8a compares two area-path forms that never match literally.** `az boards area project list` returns the
   path with a leading separator **and a classification segment** (`\<project>\Area\…`); `teamfieldvalues`
   returns it with **neither**. 8a says a team is a candidate when one of its values "covers the area path
   resolved above" and never mentions normalisation, so a literal comparison yields **zero candidates on a
   correctly configured project** and falls to the default-team branch — whose printed reason says a
   derivation defect is the likelier cause. It would be right. This run found 2 candidates only because the
   normalisation was written into the probe.
2. **The sanctioned create command sets neither the area nor the iteration.** Both parameters exist on
   `az boards work-item create`; 8f's verbatim command omits both, while 8e item 1 promises the operator all
   four resolved values. Items land at the project root instead — **already observed**: the 120-item batch of
   2026-08-05 wrote every item to the project-root iteration, which is the confound that blocked BAR-012 for
   a day. It also undercuts the derivation's own premise, since the team set is derived from an area path the
   batch never writes.

**And a correction to BAR-017's premise**, above: partial per-team read failure is **rare and mostly
unreachable**, not ordinary. The bar's requirement — per-team lines, three states, one failure attributed to
one team — remains right; its stated justification does not survive the sweep.

**Correction to defect 1, appended the same day by the `/plan` run that consumed it.** The paragraph above
says a zero-candidate derivation "falls to the default-team branch — whose printed reason says a derivation
defect is the likelier cause. It would be right." **That describes BAR-001(iii)'s requirement, not the
shipped file.** Verified mechanically: `normalis`, `derivation defect`, `no candidates` and `zero candidates`
all return **zero hits** in `skills/devops-azure/SKILL.md`, and the default-team fallback is gated on
`1 + N + M > 10` **alone**. So `M = 0` does not reach the fallback at all — it takes the *"narrow fully;
examine every candidate team"* row and examines none, naming no team, displaying no levels, and reporting a
clean derivation. **Defect 1 is therefore worse than recorded above: the failure is silence, not a wrong
message.** Left in place rather than rewritten, on the same append-don't-rewrite handling as the rest of this
file; the corrected form is what `docs/plans/devops-azure-area-iteration-placement.md` BAR-003 is written
against, and that bar fails against the file as it stands today.

### What the gates actually proved, stated because it is easy to overclaim

The tree used here is **synthetic, and its `audit: findings addressed` line is one I wrote myself.** It
passed the REFUSE gate on that claim — which is exactly the caveat 8a states about its own gates resting on
hand-editable frontmatter that nothing binds to tree content. **This run is evidence about the derivation,
not evidence that the audit gate works.**

**Still NOT RUN and unchanged:** BAR-009, which remains expected to stay so.
