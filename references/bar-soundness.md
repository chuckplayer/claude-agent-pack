# Bar soundness

The single authority on the ways an acceptance bar passes while the property it checks is false. Read by
`tech-lead` when it writes or revises bars, and by `devils-advocate` when it audits them. Neither restates
its rows, its count, or its scope anywhere else: a second description is a second thing to keep in sync,
and it will lose.

## ways a bar passes while the property it checks is false

Format compliance is not soundness. A bar can be perfectly shaped, pass its own check, and prove
nothing — and that is worse than a missing bar, because a gate then reports success.

**This table is derived from failures observed in this repo, together with the symmetric cases those
failures generalize to.** Most rows are a literal instance recoverable from the record, and two of
them recurred across consecutive cuts. **Not every direction of every row has happened here** — where
a row states an invariant broader than its instance, that is deliberate, because a rule that covers
only the half that already bit you invites the other half. Treat this as a checklist rather than a
caution, and **do not read it as a claim that each line is a past event.**

**Rows 1–5 test the `Evidence:` line. Row 6 applies the same test to a different sentence** — the one
asking a human to authorize a cost. That is why it is a row and not a footnote to row 1: the failure
shape is the same, but a reader working the table against an `Evidence:` line would never think to
aim it at a gate. **No count appears in this heading on purpose** — a numbered heading goes stale the
first time the table grows, which is the same defect as a stale count in a pointer.

| Failure | The test to apply | What it looked like here |
|---|---|---|
| **1. Stated ≠ true** | Does the evidence check that a claim is *present*, or that it is *correct*? For any claim about an external system's behaviour, presence is not correctness. | A bar required a sentence describing `[System.Tags] CONTAINS` as a substring filter. The sentence was there; the semantics were the opposite — `CONTAINS` matches whole tags — so the shipped query could never match anything. The bar checked prose and passed. |
| **2. Category vs instances** | Does the bar assert something about a *category* while the evidence enumerates *instances*? | A bar asserted tree values were guarded "before reaching a WIQL string, a tag, or an `az` argument", while naming regexes for only two identifier fields. Titles are `az` arguments and were covered by nothing — the bar would have passed with a command-injection path open. |
| **3. Self-falsification** | Could the check's *failure* produce the same result as the property *holding*? | A bar verified "nothing was created" by running the very query whose correctness was unverified. A malformed query returns zero rows exactly like an empty tracker, so the check confirmed itself either way. |
| **4. Producibility** | Does the tool actually emit the output the evidence names? Check before writing it, not at verification time. | A bar demanded "well-formed empty JSON, not blank". `az boards query` emits *nothing at all* for an empty result set, so no passing run could ever produce the named evidence. The bar was unsatisfiable as written. |
| **5. Pattern fragility and self-exemption** | Would the pattern still match after harmless reformatting? And does the evidence contain an escape clause? | `grep -c 'does not exist yet' returns 0` — the phrase was line-wrapped across two lines at one of three sites, so the bar passed on a two-of-three fix. Separately, `returns 0 unless the hit is benign, in which case classify it` lets the checker reclassify any result as compliant, which enforces nothing. |
| **6. Unverified cost in a consent gate** | Does the bar ask a human to authorize a cost — and did anyone verify the cost's scope against the system that will bear it? A cost stated in a gate is a factual claim about an external system, so row 1's test applies to it. **Both directions fail.** | BAR-015's gate asked for permission to create "roughly ten permanent **org-wide** tag values … visible in tag autocomplete for every user in the org". Tags are **per-project** — verified only after the bar had already run. The evidence was sound and the bar passed; what was false was the sentence the operator approved. Consent was obtained under a false description of an irreversible cost, and the overstatement propagated into three files. |

**Row 6 is the one row with a mechanical half, and it is required rather than encouraged.** A gated bar
carries **two fields**, and both are structured lines rather than prose:

```
- BAR-nnn: <subject>
  Evidence: manual -> <...>
  Gated: <the condition that must hold for this bar to run at all>
  Cost: <what the operator is asked to authorize, in units, and whether it is reversible>
```

**`Gated:` is what makes the requirement checkable, and prose does not substitute for it.** An earlier
version of `scripts/lint-plans.sh` triggered on the *word* "gated" appearing in a bar's text, and it
flagged a bar that merely described this check plus two bars that only referenced *another* bar's gate
— row 5 of this table, in the checker. A field cannot be tripped by a bar talking about gates. The
cost of that precision is stated rather than hidden: **a gated bar whose author omits `Gated:` escapes
the `Cost:` requirement entirely**, so the field is a floor on honest bars, not a trap for dishonest
ones — which is all a structural check can ever be.

State the cost in **units and reversibility**, and say which parts were **verified** rather than
assumed — "10 work items and ~10 tag values, permanent, per-project (tag scope verified 2026-08-03)"
is a cost line; "some throwaway items" is not. `scripts/lint-plans.sh` checks that a gated bar has the
line at all; **only a reader can check that the number is true**, which is the division of labour the
rest of this table assumes.

Why this field and no others: the four remaining rows are judgement, and a required field for
judgement produces filled-in boxes rather than thought. Row 6 is different because the *absence* of a
cost statement is itself mechanically visible, and BAR-015 shipped with the cost stated wrongly in
prose that nothing could check.

Three habits that prevent most of this:

- **Name the property, then ask what would disprove it.** If nothing could, the bar is decoration.
- **For any claim resting on external behaviour you have not run, say so in the bar.** "Ships unverified; verified only in BAR-nnn" is a legitimate and useful thing for a bar to record. Silent assumption is not.
- **When evidence is a command, state what a null result means.** Zero rows, empty output, and no match each have at least two causes — one where the property holds and one where the check broke.

**Prefer a bar that can fail.** Between a bar that is certain to pass and one that might expose something, write the second. The first cannot tell you anything you did not already believe.
