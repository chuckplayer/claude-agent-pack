---
plan_id: bar-cost-and-first-run
branch: main
origin_skill: plan
created: 2026-08-03
revised: 2026-08-03
---

## What ships

Two changes with one root cause. **Five files, none of them new.**

1. **A sixth row in the `### Bar soundness` table** (`agents/tech-lead.md`) covering a bar whose
   **gate** states a cost nobody verified — plus the framing fixes that row forces, because the
   table currently describes itself as being about `Evidence:` lines only, and two other files
   restate that framing or its row count.
2. ~~**A zero-write link-pair preflight** with a refused link made **fatal** for an undemonstrated
   pair.~~ **WITHDRAWN 2026-08-03 — its premise was falsified by execution.** Azure DevOps accepts an
   undemonstrated, hierarchy-inverting pair with exit 0, so the refusal the fatal rule waits for never
   arrives. See `## Challenge — 2026-08-03 (second pass)` finding 1 and its `EXECUTED` block.

   **This is the second design for change 2 to die, and the two deaths have the same cause:** both
   rested on an assertion about how Azure DevOps behaves that nobody had run — first "a link needs two
   created items", then "the template refuses a bad pair". That is bar-soundness row 1 applied to this
   plan's own mechanism, and it is exactly BAR-015's offence. **A third attempt at change 2 should not
   be drafted until the behaviour it depends on has been executed first.**

   **What survives is advisory and is not this cut.** The pair report itself is genuinely useful, but
   against the *opposite* hazard: an unnatural pair is accepted silently and then breaks backlog
   reordering and sprint-backlog display. That is a **warning**, it has no gate attached, and it needs
   its own design — including whether a warning nothing enforces is worth the two reads.

   **One consequence lands outside this plan and is not optional.** 8c currently states the hierarchy
   constraint is "learned only by attempting a link and having it fail". That claim is **false and
   shipped** in `b5c8d9c`. Correcting it is a real defect fix, it is independent of everything above,
   and it should not wait on a third design for change 2. **Shipped separately in `3e320b5`**, which
   also replaced the type-divergence STOP's false justification with the true and more serious one:
   the mixed hierarchy is *accepted*, and the damage is silent.

3. **`scripts/lint-plans.sh`, and a required `Cost:` field on gated bars.** Added after Codex's review
   observed that this table is prose applied by one agent to another agent's artifact with nothing
   mechanically enforcing it. The script validates plan structure — frontmatter keys, required
   sections, unique bar ids, a typed `Evidence:` line per bar — and enforces the one part of row 6 a
   machine can see: **a bar declaring itself `gated` must carry a `Cost:` line.**

   **Only that one row gets a field, deliberately.** The other rows are judgement, and a required
   field for judgement yields filled-in boxes rather than thought. Row 6 qualifies because the
   *absence* of a cost statement is mechanically visible while a *wrong* one is not — so the script
   checks presence and a reader still checks truth. Codex's fuller schema (`Claim`, `Failure mode`,
   `Human authorization text` as separate fields) is **not** adopted here: it would restructure every
   bar in the repo to buy checks on fields whose content still needs a human, and this cut has already
   had two designs die of over-reach.

**The shared root cause is worth stating once, because it is why these belong in one cut.** BAR-015
asserted things about Azure DevOps that nobody had executed: that tags are org-wide (false), and
implicitly that a listed work item type is creatable (false for `Product Backlog Item` in the target
project). Change 1 is the **standard** that names this failure. Change 2 is the **procedure** that
satisfies the standard for the one mode where the cost of being wrong is permanent and unremovable.
Shipping the standard without the procedure would add a row nothing acts on; shipping the procedure
without the standard would fix one mode and leave the next author to rediscover the lesson.

## Why row 6 is a new row and not an extension of row 1

Rows 1–5 all answer the same question: *can this `Evidence:` line pass while the property it checks
is false?* Every one of them is a defect in a **verdict**.

A gate that misstates its cost produces **no false verdict at all**. BAR-015's evidence was sound —
it ran, it passed, and what it proved was true. The defect was upstream of the verdict: the operator
was asked to authorize *"roughly ten permanent org-wide tag values … visible in tag autocomplete for
every user in the org"*, and the real cost was ten values in one project's autocomplete. **Consent
was obtained under a false description of the cost.** That is a different harm on a different axis,
and folding it into row 1 would bury it — row 1's test ("is the claim present, or correct?") is
applied to evidence, and a reader working through the table would not think to apply it to the
sentence asking a human for permission.

**Both directions are defects, and the asymmetry people assume is wrong.** Understating a cost is
obviously bad: the operator approves something they would have refused. Overstating it feels safe
and is not — it teaches the operator that the gate exaggerates, which degrades every future preview
they read, and this repo's whole batch-write design rests on one operator reading one preview
carefully. Row 6 must say both directions fail, or it will be read as "round up when unsure".

## Change 2 was redesigned after review. Read this before the rest.

**The first version of this plan proposed a "first-run pause": ask the operator whether batch mode had
run against this project before, and if not, stop the batch after two created items to check the
mechanism. That design is withdrawn in full.** Four things killed it, three found by review and one by
execution:

1. **Its central justification was false.** It claimed a hierarchy link is "untestable until a second
   item exists to be the child". Verified against `<org>/<project-a>`: linking `706537` (a `User Story`
   with no parent) to the pre-existing `706507` (a `Feature`) returned exit 0 with the parent relation
   confirmed, then removed cleanly. **A link target can be any pre-existing item**, so one create
   suffices — and as below, zero do.
2. **It counted items when the thing that varies is pairs.** A two-item probe validates exactly one
   `(parent, child)` pair. The `bar015-alpha` tree needs **two** — `Feature → User Story` and
   `User Story → Task` — so the probe would have validated half the tree's link surface and reported
   success. Neither one item nor two is the right number, because the number was never the question.
3. **Its stop condition did not exist.** 8h makes a link failure explicitly non-fatal and reported
   separately. So the pause would have reported "link refused", the operator would have answered
   continue, and the pause would have caught precisely nothing.
4. **Its position was undefined for real trees.** A `SPIKE`-first tree has no parent by 8h's own rule,
   a one-`FEATURE` tree has no second item, and a `narrowed_by_depth: true` tree can run several items
   before any link exists. "After the first parent and its first child" names an event that may never
   occur.

**The replacement costs zero writes and is keyed to pairs**, which dissolves 2 and 4 rather than
patching them.

## The preflight, and why it is producible

Every claim in this section was executed against `<org>/<project-a>` on 2026-08-03 rather than reasoned
about — which is the standard row 6 exists to enforce, applied to this plan's own mechanism.

**Two reads, and 8d already makes one of them.**

1. **The edge list.** One POST returns every parent/child edge in the project:

   ```bash
   az devops invoke --area wit --resource wiql --route-parameters project=<project> \
     --org https://dev.azure.com/<org> --http-method POST --in-file <query.json> --api-version 7.1
   ```

   with a `WorkItemLinks` query scoped by `[Source].[System.TeamProject]` and
   `[System.Links.LinkType] = 'System.LinkTypes.Hierarchy-Forward'`. Returned **122 edges** for `<project-a>`.
2. **The type map.** The flat `[System.Id], [System.WorkItemType]` query **8d already runs**.

Join them client-side and the project's demonstrated pairs fall out. For `<project-a>`:

| Demonstrated pair | Instances |
|---|---|
| `User Story → Task` | 101 |
| `Feature → User Story` | 20 |
| `Epic → Feature` | 1 |

Zero edges had an endpoint outside the type map. **Both pairs `bar015-alpha` required were already
demonstrated before that batch ran** — so a preflight would have cleared its links with no writes at
all, and the withdrawn pause would have created two permanent items to learn less.

**One CLI hazard, verified, and it must be written into the file.** The same link query through
`az boards query --wiql` returns **blank with exit code 0** on a project that demonstrably has links
— the positive control confirmed `706526` holds a parent relation. This is a fresh instance of the
`[System.Tags] CONTAINS` class: a query that looks valid, fails silently, and would make every pair
read as undemonstrated. **Use the `invoke` route; never `az boards query` for a link query**, and treat
blank as `UNKNOWN` per 8d rather than as "no edges".

## Calls made for you

- **The trigger is derived, not operator-declared.** The withdrawn design asked the operator whether
  this project was new. That question is now unnecessary: the pairs the tree needs and the pairs the
  project demonstrates are both computable, so the mode never has to ask and never has to remember.
  This also retires the risk that an operator answers reflexively on every future preview.
- **A refused link is fatal only for an undemonstrated pair**, and stays non-fatal for a demonstrated
  one. This is a **scoped, stated override of 8h**, and the asymmetry is the point: a refusal on a
  pair the project uses 101 times is probably transient and reporting it is right, while a refusal on
  a pair nothing demonstrates is structural — the template forbids it, every later item of that shape
  will fail too, and continuing means creating orphans that this mode has no path to delete.
- **No second confirmation, so `8e`'s one-confirmation rule is untouched.** The withdrawn pause needed
  one and would have contradicted step 7's existing "the rule is amended **once**, deliberately". A
  STOP is not a confirmation, so this design needs no amendment, and **step 7 is not an edit site.**
  This is a real simplification, not a technicality: the previous version would have left
  `skills/devops-azure/SKILL.md` self-contradicting in two places.
- **An undemonstrated pair is a preview WARNING, never a refusal.** Absence of a demonstrating edge is
  inconclusive — a new or sparse project has no edges at all, and a legitimately unused pair is not a
  forbidden one. This is the same evidentiary standard 8c already adopted for type creatability
  ("evidence, not proof"), and adopting it twice with one voice is deliberate.
- **A per-project "verified" registry remains rejected**, and the preflight is why it is now clearly
  unnecessary rather than merely unattractive: the answer is recomputed from the tracker every run, so
  there is no state to persist and nothing to go stale.

## Risks

- **The preflight is inconclusive on an empty or sparse project** — every pair reads as undemonstrated,
  so every link becomes fatal-on-refusal and the first structural refusal stops the batch. That is the
  intended behaviour and the safe direction, but on a genuinely fresh project it means the batch can
  stop after one create. Disclosed rather than mitigated: the alternative is treating unknown as
  permitted, which is what BAR-015 did.
- **`MODE (MustContain)` and the 20000-item ceiling.** An unscoped link query errored with `VS402337`
  (limit 20000) before scoping fixed it. A very large project could exceed that ceiling even scoped,
  and the file must say what happens then — a `UNKNOWN` stop, not a silent partial edge list.
- **Row 6 widens the table's scope**, so the table stops being purely about `Evidence:` lines. A real
  cost to its crispness, mitigated by stating the two axes in the intro rather than letting a reader
  infer that row 6 is a badly-fitting row 1.
- **The pair join is client-side**, so it inherits the PowerShell 5.1 JSON hazard in
  `memory/context/2026-08-03-powershell-convertfrom-json-array-double-wraps.md`. A double-wrapped edge
  list silently yields zero resolved pairs, which reads exactly like "nothing demonstrated" and turns
  every link fatal. The file must name that failure mode where it specifies the join.

## Files

| # | File | Change |
|---|---|---|
| 1 | `agents/tech-lead.md` | Row 6; retitle to drop the count and widen past `Evidence:`; intro names the two axes |
| 2 | `agents/devils-advocate.md` | Remove "five" from the dimension-8 pointer |
| 3 | `CLAUDE.md` | Widen the Plan-spine framing sentence past `Evidence:` lines |
| 4 | `skills/devops-azure/SKILL.md` | The preflight and its two reads in 8c/8d; the `az boards query` link hazard; the pair report in 8e; the scoped fatal-link override in 8h |
| 5 | `docs/ado-delivery-pipeline-brief.md` | Verify its confirmation-rule sentence is still accurate — it should be, since this design adds no amendment. Record the check either way |

Files 1–3 are one coupled edit (the row and every pointer's framing) and must be written together.
File 4 is independent of them. **Step 7 of `skills/devops-azure/SKILL.md` is deliberately not an edit
site**, per the third call above.

## Review record — read this before trusting the bars below

**`devils-advocate` audited the bars in place and its narrative challenge was never received.** It went
idle without reporting, was asked directly for its findings via `SendMessage` with its transcript
intact, and went idle a second time without reporting, making no further edits between the two
attempts. Per `memory/known-issues/2026-08-03-subagent-goes-idle-before-reporting.md` the escalation
path stops there, so its ranked concerns and its implement / smaller / reconsider **verdict are
unrecoverable.**

- **Received:** dimension 8, the bar audit. It rewrote four bars, hardened two, and **added BAR-007**.
  Its catches were load-bearing — three of my own bars were falling into the table's own failure modes
  (a `grep -c` count that fails a correct implementation; a grep that could not distinguish removing
  "five" from replacing it with "six"; an `exits 0` assertion satisfied identically by the check
  running clean and never running at all).
- **Never received:** dimensions 1–7 — the challenge to the design itself.

**What happened after.** Two of its bar findings were really design defects, and rather than leave them
recorded only as bar conditions, they are now in `## Change 2 was redesigned after review` above,
together with two more found by execution. **BAR-004 and BAR-005 were rewritten by me** against the new
design; the pause they described no longer exists. **BAR-007 is inverted rather than dropped** — its
premise was that the brief would go stale by describing the rule as amended once, and since this design
adds no amendment, the bar now asserts that sentence stays *accurate*. Its finding is preserved in the
form the new design makes true. **BAR-001, BAR-002, BAR-003 and BAR-006 are its text, unaltered.**

The design still carries **no external challenge to its narrative** — including to the redesign, which
no reviewer has seen.

## Challenge — 2026-08-03 (second pass)

Second `devils-advocate` pass, dispatched to challenge the **redesign** (dimensions 1–7) and to audit
**BAR-004, BAR-005 and BAR-007** only. BAR-001/002/003/006 were left untouched as the first reviewer's
text. **Verdict: implement smaller — ship change 1, hold change 2's fatal rule.** Findings, ranked:

### 1. Change 2's central premise appears to be false, and it is the same class of error change 1 exists to name

The preflight's teeth rest on a claim nobody has executed: that Azure DevOps **refuses** a
parent/child link because of the `(parent type, child type)` pair. That claim is already in the shipped
file — 8c: "that constraint comes from the process template, and this mode learns it **only by
attempting a link and having it fail**". Microsoft's own reference contradicts it. `System.LinkTypes.Hierarchy`
documents exactly three restrictions — **one parent per item**, **no circular references** (tree
topology, `acyclic: true`), and same-project recommended for Excel round-tripping. **There is no
type-pair restriction.** The "natural hierarchy" of Epic → Feature → Story → Task is published as a
**best practice**, and the troubleshooting guide for violating it instructs the reader to *"remove any
parent-child links that exist among nested items of the same work item type or category"* — you cannot
remove a link the service refused to create. Sources: `learn.microsoft.com/azure/devops/boards/queries/link-type-reference`
and `.../boards/backlogs/resolve-backlog-reorder-issues`.

Two consequences, and the second is worse than the first:

- **The fatal path likely never fires on type grounds.** Every pair the preflight flags will link
  successfully, so the mechanism produces warnings that are always false alarms — the exact
  preview-inflation harm row 6 is being added to forbid. Change 2 would ship a violation of change 1
  in the same commit.
- **The real hazard has the opposite shape and this design cannot see it.** An unnatural pair
  (`Feature → Task`, story-under-story) is **accepted with exit 0** and then silently breaks the
  backlog: *"You can't reorder work items and some work items might not be shown"*, and intermediate
  nodes stop appearing on sprint backlogs and taskboards. A refusal-based control detects none of
  that. The *warning* half of the preflight is genuinely useful against it; the **fatal-on-refusal
  half is aimed at a failure mode that does not appear to exist.**

This is bar-soundness row 1 (stated ≠ true, for a claim about an external system's behaviour) applied
to this plan's own mechanism, and it is precisely BAR-015's offence. **Executable, cheaply and
reversibly, before shipping:** the plan already established that `relation add`/`remove` is reversible
on pre-existing items. `<project-a>` has `Feature` and `Task` items and does not demonstrate `Feature → Task`.
If that link returns exit 0, condition (v) of BAR-004 is asserting something false.

> **EXECUTED 2026-08-03, and this finding is confirmed. Change 2's fatal rule is dead.** The probe was
> run with one adjustment: `Feature → Task` needed a parentless `Task`, and every `Task` in the batch
> already had a parent, so a refusal could have been the documented **one-parent-per-item** restriction
> rather than a type rule — which would have proved nothing. Instead `706537` (a `User Story` with
> **zero** parent relations) was linked as child of `706531` (a `Task`): the pair `Task → User Story`,
> which `<project-a>` does not demonstrate **and** which inverts the natural hierarchy. **Result: exit 0,
> accepted.** The relation was then removed, exit 0, and `706537` confirmed back to zero parents.
>
> So `System.LinkTypes.Hierarchy` enforces no type-pair rule, **"undemonstrated pair" does not imply
> "the template forbids it"**, and a refusal-based control cannot fire because the refusal does not
> happen. Two things follow beyond this plan: **8c's shipped claim** that the hierarchy constraint is
> "learned only by attempting a link and having it fail" is **wrong and is now a defect in `b5c8d9c`**,
> not merely a weak premise here; and the reviewer's mirror-image hazard stands unchallenged — an
> unnatural pair is accepted silently, so only the **warning** half of the preflight has any value.

### 2. The fatal/non-fatal asymmetry is not backwards — it is uncorrelated with cause

The dispatch asked whether the asymmetry is inverted. It is worse than inverted: the variable it keys
on has no causal relation to the failure. The refusals ADO actually produces are **child already has a
parent**, **circular link**, **insufficient permission**, and **target missing / wrong project**. None
of these correlate with pair demonstration. So:

- A **child that already has a different parent** — a genuine structural defect that 8h already treats
  as a STOP on the resume path — becomes **non-fatal** whenever it lands on a conventional pair, which
  is the common case for every real tree.
- A **transient 503 or throttle** becomes **fatal** on any fresh or sparse project, because every pair
  there reads undemonstrated.

The plan's stated reason for the asymmetry ("a refusal on a pair the project uses 101 times is
probably transient") is an unevidenced empirical claim — again the row-6 pattern. There *is* a sound
reason available and the plan does not make it: 8h's resume path can **repair a missing parent link**
on a later run, so a transient failure is recoverable while a structural one would fail identically
forever. If the design survives, that is the argument to write down. It still does not rescue keying
fatality to pair demonstration, because pair demonstration is not the discriminator.

### 3. Zero-edge projects: the design is at its most brittle exactly where it was meant to help

A fresh project is the **normal** case for a first batch, and there every pair reads undemonstrated.
The result is not "the safe direction" — it is a strict regression against the file as it stands
today:

- Every pair warns. The preview with the **most** warnings is the run where the operator has the
  **least** information, and every one of those warnings is (per finding 1) probably spurious.
- 8h's non-fatal link rule is suspended wholesale for the entire first run, so a single transient link
  failure now **stops the batch mid-way and leaves a partially created backlog** — the outcome the
  step-7 amendment note itself calls "worse than either failure the per-write rule guards against".
  Before this change, that run completes and reports.
- The withdrawn pause was **better** here on one axis: it bounded the damage at two items. Fatal-on-
  refusal bounds it nowhere — it stops wherever the batch happens to be, up to 100 items in.

The plan's defence ("the alternative is treating unknown as permitted, which is what BAR-015 did") does
not transfer. BAR-015's failure was **type creation** (`VS403074`), which 8f already stops on at item 1.
Creation is irreversible; a link is not — the plan verified that itself and then did not use it.

### 4. "Two reads, and 8d already makes one" is wrong about which section, and the ceiling is a real blocker

- **The flat `[System.Id], [System.WorkItemType]` project-wide query is 8c's in-use cross-check, not
  8d's.** 8d's unconditional query is **tag-scoped** (`CONTAINS '<feature>'`) and returns only this
  feature's items — useless as a project type map. 8d's only project-wide read is the **conditional**
  positive control in its blank-ambiguity rule. The read count (two) is right; the attribution is
  wrong, and BAR-004 (ii) inherits the error. Fixed in the bar.
- **The 20000-item ceiling hits the type map too**, not only the link query — 8c's cross-check is also
  an unscoped-by-tag `WorkItems` query. The plan names the risk for one read and not the other.
- **"UNKNOWN-and-stop" is not adequate as specified.** Every other stop in this mode is retryable or
  has a stated escape: 8d's blank case has a positive control that lets the normal path through, 8a's
  100-item cap names the scoped-run escape. A ceiling stop is **permanent for that project** — batch
  mode simply becomes unusable above the ceiling, silently, and 20000 items is ordinary for an
  enterprise project (`<project-a>`'s 113 is the small end). At minimum the file must distinguish a retryable
  UNKNOWN from "this project can never run batch mode", and a narrowing option exists that the plan
  never considers (scope the link query to the source/target types the tree actually needs).
- **`MODE` is named as a risk and never resolved.** Unpinned, a `MayContain`/`DoesNotContain` link
  query returns rows with **null targets**, which the client-side join either drops silently or
  resolves into a bogus pair. "Zero unresolved endpoints on <project-a>" is evidence the planning run used
  `MustContain`; that observation does not transfer unless the file pins the mode. Added to BAR-004.
- The POST body must come from `--in-file`, not stdin — a PowerShell pipe corrupts JSON on the way to
  stdin on this machine, the same class as `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md`.
  **No file in this repo's `memory/` records the stdin case**, so if the preflight ships, that gap is
  worth closing. Added to BAR-004.

### 5. What the pause had that the preflight lacks is almost entirely phantom

Enumerated against the file rather than argued: tag round-trip is covered by 8f's item-1 probe;
type creatability (`VS403074`) by 8f's stop at item 1; write-back mechanics and the read-back diff by
8g's stop-on-failure at item 1; area and iteration by 8a's discovery plus 8e item 1; title content by
8e item 5, which already shows **every** item's title, type and tag before any write; anchor-query
health by 8d's positive control. The mode already fails at item 1 for everything the pause claimed to
test. **The one real loss is a human reading real created artifacts** — which is how the
`external_refs:` mis-nesting was found while executing BAR-015, and no rule in the file enumerates
that class. It is thin, and the pause would not have caught it reliably either. Dropping the pause was
correct.

### 6. Row 6 survives, but the framing it is claimed to force does not

The distinction the plan draws — rows 1–5 are defects in a verdict, row 6 is not — **does not hold**.
Row 6's instance is a bar that asserted a property ("the operator is shown the true scope of what they
are granting"), passed its check, and the property was false. That is verbatim the table's existing
frame. What is genuinely new is the **sentence the test is applied to** (the consent text, not the
`Evidence:` line), and that justifies a row: a reader working the table against evidence would not
think to apply it to a gate. It does **not** justify the "two axes" reframing, and by extension it does
not justify the `CLAUDE.md` edit (file 3). Row 6 plus dropping the count from the heading and the
pointer (files 1 and 2) is the whole necessary change; the axis narrative is optional scope resting on
a distinction that collapses under inspection.

**"Both directions are defects" is doing real work, but half of it has no in-repo instance.** The
overstating direction is already this repo's committed position — 8e item 8 says "overstating it is not
the safe direction" in shipped text — and BAR-015's actual defect **was** the overstatement
(org-wide for what was per-project). The **understating** direction has no instance here. The table's
intro claims "every failure below has happened in this repo", so a row 6 that presents both directions
as observed history breaks that claim. Flagged rather than fixed: BAR-001 is out of this pass's scope
and currently requires the row to "name both failure directions" without requiring it to be honest
about which one occurred.

### 7. Second-order effects the plan does not name

- A run's outcome stops being a function of the tree and the confirmed mapping alone — **the same tree
  now behaves differently in two projects** because of their history. That is new, and it makes a
  failure irreproducible outside the project that produced it.
- It sets a precedent that **"the project already does X" licenses X**, which will be reused for tags,
  area paths, iterations and states. Worth adopting deliberately if at all, not as a side effect.
- Batch mode's viability becomes coupled to **project size** for the first time. The 100-item cap was
  about the tree; this is about everything already in the tracker.
- 8h becomes rule-plus-scoped-override while already carrying its own STOP for a wrong parent — three
  fatality behaviours in one section, which is how a reader gets one of them wrong.

### 8. Reversibility and the smaller version

Change 1: easily reversible, doc-only, three files. Change 2's *edits* are reversible; its *effects*
are not — it raises the probability of a partially created backlog with no delete path, in exchange for
preventing a failure mode that the vendor's documentation says does not occur.

**Ship change 1 alone.** The coupling argument ("a row nothing acts on") fails on its own terms: row 6
binds tech-lead and devils-advocate on **every** future plan the moment it lands, and the instance that
motivates it — 8e item 8's per-project correction — has already shipped. Change 2 is not what makes
row 6 act.

**Then, if change 2 proceeds, the materially smaller version is: keep the pair report as a preview
WARNING and leave 8h's non-fatal rule alone.** That delivers every operator-visible benefit, costs one
read, needs no scoped override, needs no verification of an unexecuted refusal premise, and cannot
convert a transient failure into a partial backlog. The fatal rule is the only part of change 2 that
depends on finding 1 being wrong.

### Bars audited this pass

**BAR-004** — edited. Row 1 (`8d` named for a read that lives in 8c; condition (v) checks that a claim
about ADO's behaviour is *present*, never that it is *correct*) and row 2 (asserts "both reads are
named" as a category while enumerating only some of the properties that make the read correct —
`MODE`, the `--in-file` route). **BAR-005** — edited. Row 3 (zero writes confirmed by an anchor-tag
query that returns **blank** when nothing was created, which is indistinguishable from a broken query
under 8d's own rule), row 4 (its negative half names an output — a refused link — the service may
never emit, the same unsatisfiability as the "well-formed empty JSON" case), and row 5 (exact instance
counts `101/20/1` against a live project fail a correct implementation the moment someone adds a Task;
and the escape clause "leave the fatal path exercised only by the demonstrated-pair asymmetry" lets the
checker pass while the fatal path is never exercised at all — the demonstrated-pair branch is the
**non-fatal** one and exercises nothing). **BAR-007** — edited. The inversion **preserves the
detector** (it fails if an amendment is reintroduced) but had three defects: the quoted step-7 text
does not match the file, which reads "the rule is amended **once, deliberately, in the file that owns
it.**" (row 5 — a literal check fails an untouched file); "confirm the brief's sentence is unchanged"
is row 3, since *unchanged* is satisfied identically by "still true" and by "nobody looked while a
second amendment landed in SKILL.md"; and step 7 carries a **second** definite-singular count ("**One
amendment**, scoped to batch write mode alone") that the bar did not name, which is the very class the
original finding was about.

## Acceptance bars

- BAR-001: row 6 exists **as a row inside the table**, names both failure directions, and states that it produces no false verdict
  Evidence: files -> `agents/tech-lead.md`. `grep -n 'Unverified cost' agents/tech-lead.md`, with the **expected hit set written down before the check runs**: exactly one hit must be a `|`-delimited table row, and any additional hit must be the intro sentence BAR-003 requires. **Assert no count.** The line-wrap reasoning holds — a markdown table row cannot be line-wrapped without breaking the table, so unlike BAR-012 of `docs/plans/devops-azure-batch-write.md` this text cannot pass on a partial fix by reflowing — but that defends the *pattern*, not `grep -c … returns 1`: `grep -c` counts lines, and BAR-003's intro may legitimately name the row, so a count assertion fails a correct implementation. `grep -n` plus an expected hit set is the form the previous cut's concern 12 already established here. **The row's title is prescribed only in this bar and nowhere in the narrative** — an implementation that titles it otherwise is a deviation to record, not a bar to rewrite. Then read the row and confirm three things no match can: it names **understating and overstating as both defective**, it says the failure is **consent under a false description** rather than a false pass, and its instance column names BAR-015's org-wide claim.
- BAR-002: no pointer to the table carries a row count, and no pointer restates a row
  Evidence: files -> `grep -rniE '(five|six|[0-9]+) (ways|failure modes|rows)' agents/ CLAUDE.md skills/` returns **no hit that is a pointer to this table**, read hit by hit against an expected set. **Deliberately broader than the two literal phrases in the tree today**, because "the five failure modes" rewritten to "the **six** failure modes" satisfies a grep for `five` while putting the count straight back — a bar that greps only for the string being removed cannot tell a fix from a re-creation. **`docs/` is out of scope on purpose:** `docs/plans/backlog.md` carries a matching phrase and plan files are historical record that is never retro-edited. Then confirm the negative half, which is the one that matters: `agents/devils-advocate.md` and `CLAUDE.md` still *point at* the table and do not enumerate its contents — read both and confirm no row text was copied while removing the count. **A pointer that loses its pointer is a worse outcome than a stale count**, and a grep for absent numbers cannot detect it. Run the grep through `C:\Program Files\Git\bin\bash.exe` and read its output; a blank result from the Bash tool is `UNKNOWN` on this machine, never a pass.
- BAR-003: the table's intro tells a reader it has two axes, and the heading itself carries no count
  Evidence: files -> `agents/tech-lead.md`. Confirm the intro states that rows 1–5 concern the `Evidence:` line and row 6 concerns the gate. **Then read the `### Bar soundness` heading and confirm it names no number at all.** The heading is checked here because **nothing else checks it**: BAR-002 greps for pointers, and a heading retitled to "six ways" is a heading that goes stale on row 7 — re-creating the exact defect this cut exists to remove, at the one site the cut is named after. **This bar also exists because BAR-001 alone would pass on a row 6 that reads as a badly-fitting row 1** — the row can be correct in isolation and still leave the table incoherent, and nothing else checks the seam.
- BAR-008: `scripts/lint-plans.sh` fails a gated bar with no `Cost:` line, and passes one that has it
  Evidence: tests -> run the script through `C:\Program Files\Git\bin\bash.exe`, passing the plan path as a **discrete argument**. Positive: `bash scripts/lint-plans.sh docs/plans/bar-cost-and-first-run.md` exits **0** with non-blank output listing each bar. Also confirm `docs/plans/devops-azure-batch-write.md` exits **0** — a historical plan carries no `Gated:` field, so the rule correctly does not fire on it, and a run that fails it would mean the trigger had regressed to prose-matching. **Negative half, which is the one that matters, and it needs a fixture rather than a real plan:** write a throwaway plan **outside `docs/plans/`** holding one bar with a `Gated:` line and no `Cost:` line, and confirm the script exits **1** naming that bar. A fixture is used deliberately — the earlier prose trigger produced its negative result by failing four bars of a **merged** plan, two of which only *mentioned* another bar's gate, and the fix for that must not be validated against the same misleading target. **Exit 0 alone is not evidence** — blank output with exit 0 is this machine's documented Bash-tool failure signature, so read the output every time.
- BAR-009: the script cannot be pointed at a directory, and no pointer to the bar-soundness table names a count
  Evidence: files -> read `scripts/lint-plans.sh` and confirm it accepts **explicit paths only**, with no glob of any plan directory and a non-zero exit plus usage message when given no argument — verify by running it with no arguments and confirming exit **1**. Then confirm the `Cost:` rule is documented in `agents/tech-lead.md` beside row 6 rather than only in the script, since a check whose rule lives only in code cannot be applied by the agent that writes bars. **This bar also carries the count check for change 1**, because both are the same defect: `grep -rniE '(five|six|[0-9]+) (ways|failure modes|rows)' agents/ CLAUDE.md skills/` returns no hit that is a pointer to the table, read hit by hit.
- ~~BAR-004~~ **WITHDRAWN with change 2** — it specified the preflight's fatal rule, and the premise that rule rested on was falsified by execution. Retained rather than deleted: it is the record of what the withdrawn design was going to promise, and its condition (v) is the one that asserted the false claim. Original text follows.
- BAR-004: the preflight is specified with its two reads, the CLI hazard that defeats it, its inconclusive case, and the scoped override that gives it teeth
  Evidence: files -> `skills/devops-azure/SKILL.md`. Confirm all six. (i) The required pairs are **derived from the tree under the confirmed mapping**, and the demonstrated pairs from the project — with **no operator question and no persisted state**. (ii) Both reads are named, **each with the properties that make it correct and not merely with its route** — the `az devops invoke … --area wit --resource wiql` POST with a `WorkItemLinks` query scoped by `[Source].[System.TeamProject]`, its **`MODE` pinned explicitly** (unpinned, a `MayContain`/`DoesNotContain` result carries **null targets** that the client-side join drops silently or resolves into a bogus pair, and the planning run's "zero unresolved endpoints" does not transfer to a file that leaves the mode open), and its body passed via **`--in-file`, never piped on stdin** (a PowerShell pipe corrupts JSON on its way to stdin on this machine — same class as `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md`, and no repo memory file records the stdin case yet; a corrupted body is a failed query, which reads as no edges); plus the flat project-wide `[System.Id], [System.WorkItemType]` query, **which is 8c's in-use type cross-check and not 8d's**. **Do not check this bar against 8d for the type map:** 8d's unconditional query is tag-scoped (`CONTAINS '<feature>'`) and returns only this feature's items, and its only project-wide read is the *conditional* positive control in the blank-ambiguity rule. A checker who accepts "8d already runs it" either passes a file that added a redundant third read or fails a correct one. (iii) **The file states that `az boards query --wiql` returns blank with exit 0 for a link query on a project that has links**, and forbids that route — without this clause the preflight silently reports every pair undemonstrated, which inverts the whole mechanism while looking like a clean run. (iv) An undemonstrated pair is a **preview WARNING, never a refusal**, with the "evidence, not proof" reasoning stated. (v) **A refused link is fatal for an undemonstrated pair and non-fatal for a demonstrated one**, written as an explicit scoped override of 8h — 8h currently makes every link failure non-fatal, so without this the preflight informs and prevents nothing. **This condition checks that a claim about ADO's behaviour is *present*, and presence is not correctness** (bar-soundness row 1): it presumes ADO refuses a parent link on `(parent type, child type)` grounds, and **nothing in this repo has executed such a refusal.** Microsoft documents only three hierarchy restrictions — one parent per item, no cycles, same-project recommended — and describes the natural hierarchy as a *best practice* whose violation is removed after the fact rather than refused at creation. So this condition is satisfiable by prose that is false. **The file must therefore also record the premise's verification status in the file itself** — either "verified: an undemonstrated pair was refused, `<pair>`, `<error>`" or "**ships unverified**: no type-grounded link refusal has been observed; the fatal path may be unreachable" — and a checker reporting PASS on (v) without reading that line has verified the sentence and not the mechanism. (vi) The file names the failure behaviour for the `VS402337` 20000-item ceiling and for a double-wrapped client-side join, each as `UNKNOWN`-and-stop rather than as an empty pair set — **and the ceiling clause must say whether that stop is retryable or terminal for the project**, since the ceiling applies to 8c's flat type query as well as to the link query, and a stop that no retry can clear makes batch mode permanently unusable above the ceiling rather than temporarily blocked. **Conditions (iii), (v) and (vi) all describe the same class of defect** — a mechanism that fails into "looks fine, checked nothing" — and each is checked separately because each has a different cause.
- ~~BAR-005~~ **WITHDRAWN with change 2, and it called its own outcome.** Its rewritten form required a zero-creation probe first and said that if the undemonstrated pair linked successfully the verdict is **FAIL-BY-PREMISE, stop, and take the finding to the design rather than to the bar.** That probe was run: `Task → User Story` on `<org>/<project-a>`, accepted, exit 0, reverted. So this bar reached its own stated failure state before a single item was created for it — which is the clearest thing in this plan about what a sound bar buys you. Original text follows.
- BAR-005: the preflight computes <project-a>'s pairs from two reads and zero writes, and the fatal path fires on a pair <project-a> does not demonstrate
  Evidence: manual -> **runnable today; no project gate.** Positive half, already executed once during planning and to be re-executed against the shipped file: against `<org>/<project-a>`, confirm the preflight resolves **exactly the pair set** `User Story → Task`, `Feature → User Story`, `Epic → Feature`, with **zero edges unresolved**. **Record the per-pair instance counts as observed values; do not assert `101/20/1` as expected equalities.** `<project-a>` is a live project — one Task created by anyone moves the count and would fail a correct implementation for a reason unrelated to the property, which is the `grep -c` defect in another costume (bar-soundness row 5). A count that differs from the planning run's is recorded, not a failure; a **pair set** that differs is. Then **zero `az` write invocations**, and check it with a **non-blank-valued measure plus a positive control, never with the anchor-tag query alone**: on a tree whose items were never created that query returns **blank**, which under 8d's own rule is indistinguishable from a query that failed silently, so "nothing was written" would be confirmed by the check breaking (row 3, and the same self-confirming shape BAR-014 of `docs/plans/devops-azure-batch-write.md` had to be amended to remove). Use the project's total and per-type item counts — non-zero values that *change* if a write happened, and whose presence proves the read worked — and compare against the pre-run values rather than against 8i's numbers, which the same session produces. Confirm a tree needing only `Feature → User Story` and `User Story → Task` reports **all pairs demonstrated** and no warning. **Negative half, and read the next sentence before running it:** build a tree requiring a pair `<project-a>` does **not** demonstrate (`Feature → Task`) and confirm the preview **warns naming that pair**. That much is producible and is the warning half of the mechanism. **The refusal half may not be producible at all, and this bar must not pretend otherwise:** Microsoft documents no type-pair restriction on `System.LinkTypes.Hierarchy`, so the expected refusal is an output the service may never emit — the same unsatisfiability as the "well-formed empty JSON" clause this repo already had to amend (row 4). So: **first, with zero creations, link two pre-existing `<project-a>` items of the undemonstrated pair and remove the link again** — `relation add`/`remove` is verified reversible on pre-existing items. If that returns exit 0, **the fatal path is unreachable on type grounds; report BAR-005 as FAIL-BY-PREMISE and stop** — do not create items to test a refusal that cannot happen, and take the finding to the design rather than to the bar. Only if the probe is genuinely refused does the creating half of this bar run at all. **State the cost accurately, per row 6:** that half creates permanent work items in `<project-a>` that this mode cannot remove. **There is no passing state in which the fatal path went unexercised.** If the link is accepted, this bar is FAIL-BY-PREMISE as above; the demonstrated-pair branch is the **non-fatal** one and exercises the fatal path in no sense, so "leave it exercised by the asymmetry" is not available as an outcome.
- BAR-006: the changeset passes the mechanical gates it triggers
  Evidence: tests -> `bash scripts/lint-agents.sh` exits **0 with non-blank output naming the files it checked**, and record the pass/fail counts. **Exit 0 alone is not evidence here:** blank output with exit 0 is the documented signature of the Bash-tool failure on this machine (`memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`), so "exits 0" is satisfied identically by the lint running clean and by the lint never running — the self-falsifying shape row 3 of the bar-soundness table describes. Invoke through `C:\Program Files\Git\bin\bash.exe` and read the output. The gate fires because **files 1, 2, and 4** touch `agents/` and `skills/`; `CLAUDE.md` (file 3) and `docs/` (file 5) are outside the script's scope and it says nothing about them. `node scripts/obsidian-stop-hook.test.js` is **correctly skipped** — no file in this cut is one of the two hooks it covers — and the skip must be **stated**, per the trigger scope in `1530b99`. A run that executes the hook suite here has produced a PASS that checked nothing in the changeset, which is the defect that gate's scope exists to prevent.
- BAR-007: the one-confirmation rule is left untouched, and the brief's description of it stays accurate
  Evidence: files -> **inverted from the bar `devils-advocate` wrote, and the inversion is recorded rather than silent.** Its premise was that this cut would add a second amendment to 8e's one-confirmation rule, making the brief's "**The amendment** landed 2026-08-03" — definite singular, no number — go stale through a field nobody classified as a count. The redesign adds no amendment, so that sentence stays true and the bar checks the property that now matters. **Check the property, not the diff.** Confirm that `skills/devops-azure/SKILL.md` contains **exactly one** sanctioned amendment to the per-write confirmation rule, and that step 7 still carries **both** of its definite-singular statements of that count, unedited: the heading "**One amendment, scoped to batch write mode alone**" and the closing "the rule is amended **once, deliberately, in the file that owns it.**" **Quote them from the file when checking rather than from this bar** — the bar previously mis-quoted the second as "amended **once**, deliberately", and a literal check against a mis-quote fails a file nobody touched (row 5). Both phrases matter because both are counts wearing no number, which is the class the original finding named; a bar checking one of two sites is the two-of-three-sites defect the table already records. Then confirm 8e still describes exactly one confirmation covering the batch. **Then reach the brief, and reach it by truth rather than by byte-equality:** locate its sentence describing the amendment (search the text, not a line number — the file moves) and confirm the count it asserts is **still true of `skills/devops-azure/SKILL.md` as shipped**. "The brief is unchanged" is satisfied identically by "the sentence is still correct" and by "nobody looked at the brief while a second amendment landed in SKILL.md" (row 3), so an unchanged-file check enforces nothing on its own. Finally confirm the preflight's stop is written as a **STOP and not a confirmation** — if an implementation adds a second operator prompt, this bar fails and step 7 becomes an edit site that `## Files` does not list. **The original finding is preserved, not discarded:** a design that reintroduces the amendment must reopen the brief, and this bar is what detects that.

## Deviations

- **Call:** `## Files` row 3 — "widen the Plan-spine framing sentence past `Evidence:` lines" in
  `CLAUDE.md`. **Shipped instead:** the sentence's scope description was **deleted**, leaving a bare
  pointer that names the table as defining its own scope. **Decided by:** the coordinating session,
  reconciling `devils-advocate`'s finding 6 (the "two axes" reframing does not hold, so file 3 is
  unjustified) with Codex's Q4 (touch it, but make it a generic pointer). A bare pointer asserts no
  scope at all, so it satisfies both — the edit became a simplification rather than the widening the
  plan called for.
- **Call:** the narrative's framing that rows 1–5 and row 6 are "two axes" of harm. **Shipped
  instead:** the table states that rows 1–5 test the `Evidence:` line and row 6 applies **the same
  test** to a different sentence. **Decided by:** the coordinating session, adopting
  `devils-advocate`'s mechanical argument that row 6's instance fits the existing frame exactly, so
  the new thing is the *target*, not the harm. Row 6 itself is unchanged by this; only the table's
  self-description is.
- **Call:** change 3's `Cost:` requirement, triggered by a bar "declaring itself **gated**".
  **Shipped instead:** triggered by a structured `Gated:` field. **Decided by:** the coordinating
  session, after the prose trigger flagged BAR-008 — a bar *describing the check* — plus two bars in a
  merged plan that only referenced another bar's gate. That is row 5 of the very table being extended,
  occurring in its own checker. The field version also removes any pressure to retro-edit merged plans.
- **Call:** Codex's fuller schema (`Claim`, `Failure mode`, `Human authorization text`, `Cost scope` as
  separate fields with automated checks). **Shipped instead:** one field pair, `Gated:`/`Cost:`.
  **Decided by:** the coordinating session; recorded in change 3's text with its reason — the other
  rows are judgement, and a required field for judgement produces filled-in boxes rather than thought.
  The remainder is logged as future work, not adopted.
- **Change 2 is withdrawn, not deviated from.** Both of its designs were falsified by execution and the
  record is in `## Change 2 was redesigned after review` and the two `WITHDRAWN` bars. It is named here
  so a reader of this section alone does not conclude it shipped.
