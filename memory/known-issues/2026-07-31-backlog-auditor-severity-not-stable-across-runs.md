---
type: known-issue
status: active
discovered: 2026-07-31
scope: agents/backlog-auditor.md
---

# backlog-auditor assigns different severities to identical input across runs

Two `backlog-auditor` dispatches over a **byte-identical** tree (`git hash-object`
`d45358670f783a39a99a80365b0680b2bc5d1f3d`), identical spec, identical handed plan, and identical
handed hashes returned **different severities for the same two findings**:

| Finding | Dispatch 1 | Re-verification dispatch |
|---|---|---|
| `STORY-6` → `Depends on: STORY-99` (target defines no item) | `High` | `Critical` |
| `STORY-3` ↔ `STORY-4` dependency cycle | `High` | `Critical` |

`agents/backlog-auditor.md` dimension 6 specifies **`High`** for both ("a target naming no item in the
tree, or a cycle → **High**, naming every id involved"). Dispatch 1 was correct; the re-verification
inflated both to `Critical`.

**Why this matters beyond a cosmetic label.** `Critical` and `High` are not interchangeable in this
pack — `merge-reviewer` blocks the pipeline on `Critical` findings and treats `High` as advisory in
several lenses. An audit that re-runs over an unchanged tree and silently promotes two findings to
`Critical` changes what a downstream reader and a downstream gate do, with no change in the artifact
being audited. Detection was correct and stable in both runs; only the severity moved.

**It also makes a bar that pins severities partially uncheckable.** `docs/plans/backlog.md` BAR-012
requires the dangling-target and cycle findings "by id at `High` under dimension 6". That clause can
pass or fail on identical input depending on the run, so a single passing run is not evidence the
behaviour is stable.

**Workaround:** none applied. When a severity matters to a decision, re-read
`agents/backlog-auditor.md`'s dimension table as the authority rather than trusting the severity a
given report assigned, and treat a severity that disagrees with the table as a reporting defect rather
than a judgement about the tree. A durable fix would need the dimension tables restated as an explicit
severity lookup the agent is told to consult per finding, and that has not been attempted.

Discovered while closing BAR-012 in the `/backlog` cut. Distinct from
[[2026-07-31-new-agent-not-dispatchable-in-creating-session]], which is about agent files not being
re-read within a session; this one reproduces within a single session and is not a loading problem.
