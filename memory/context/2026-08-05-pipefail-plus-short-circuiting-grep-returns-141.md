---
date: 2026-08-05
type: constraint
status: active
superseded-by: n/a
scope: every shell script in this repository that runs under `set -o pipefail` — all three blocking
  gate scripts do
overrides-convention: no
related-to: 2026-08-04-grep-iF-aborts-on-this-machine.md, 2026-07-10-bash-tool-silent-failure-windows.md, 2026-07-30-agent-output-must-be-attributable-to-be-evidence.md
---

## Summary

**Under `set -o pipefail`, piping into a matcher that short-circuits turns a successful match into a
non-zero pipeline.** `grep -q`, `grep -m1`, and `head -n` all exit as soon as they have what they
need. The producer — `printf`, `cat`, an earlier `grep` — is still writing, so it dies of **SIGPIPE
(141)**, and `pipefail` promotes that to the pipeline's status. The `if` therefore takes the **false**
branch *because the match was found early*.

```bash
set -o pipefail
printf '%s\n' "$big_body" | grep -qF 'needle'   # needle on line 1  ->  exit 141, not 0
grep -qF 'needle' <<< "$big_body"               # exit 0, correct
```

**It is size-dependent, which is why it hides.** Below the pipe buffer (~64 KiB on this machine) the
producer finishes writing before the matcher exits, no SIGPIPE occurs, and the pipeline returns the
matcher's status as expected. The bug appears only once the piped text crosses that threshold — so it
passes every small fixture and every early test, then changes behaviour as real data grows.

## Where it bit

`scripts/lint-plans.sh` line 176 tested the `## Deviations` sentinel with
`printf '%s\n' "$dev_body" | grep -qF 'Deviations not yet reviewed'`. A plan whose section body
reached **83 KB** reported **`## Deviations filled in`** while the sentinel sat untouched on the
section's **first line** — the earlier the match, the more producer output is left to fault, so *the
most obviously-correct input fails hardest*.

**Two things make this worse than an ordinary bug.** It is the **second** time that same check
reported the opposite of the truth on the one question it exists to answer — the first was a
prose-vs-structured-field mismatch, recorded in a comment directly above the defect. And the
inflated body came from a *second* defect in the same block: `sed -n '/^## Deviations/,$p'` read to
**end of file** instead of stopping at the next `## ` heading, sweeping three unrelated sections into
the "Deviations body". The bar-body loop 50 lines earlier already bounded itself at the next heading,
for the same reason, with a comment explaining why. **The lesson was learned once and applied in one
of the two places that needed it.**

## Workaround

- **Feed a variable to a matcher with a herestring, never a pipe:** `grep -q PATTERN <<< "$var"`.
  `printf | grep -q` has no advantage here and this failure mode.
- **When the producer must be a command**, either drop `-q`/`-m1` and consume all input
  (`[ -n "$(grep PATTERN file)" ]`), or read the file directly — `grep -q PATTERN file` never pipes.
- **Bound a section extraction at the next heading**, not at end-of-file. It keeps bodies small, which
  removes the trigger, and it is independently correct.
- **Treat 141 as its own case** when a pipeline's status is load-bearing. `0` matched, `1` did not
  match, `141` means *the pipeline was cut* — which is neither.

**Same lesson as the two related grep files: on this machine, an unexpected negative means suspect the
invocation before the subject.** And the same lesson as the whole `memory/known-issues/` set — a check
whose mechanism can fail silently must prove its mechanism before reporting a result.
`scripts/lint-plans.sh` now **self-tests on a fixture deliberately larger than the pipe buffer** and
exits **2** if any of its three cases misreports, because a small fixture cannot catch this class at
all.

## What it did not reach

**`agents/merge-reviewer.md` Tier 1 is unaffected.** It greps the same literal with the **`Grep`
tool**, not a shell pipeline, so the gate that actually blocks a merge never had the defect — only the
advisory script the coordinating session reads. Checked rather than assumed, 2026-08-05.
