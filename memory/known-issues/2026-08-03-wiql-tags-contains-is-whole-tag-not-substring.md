---
type: known-issue
status: active
discovered: 2026-08-03
scope: skills/devops-azure/SKILL.md
---

# WIQL `[System.Tags] CONTAINS` matches whole tags, not substrings — and `=` is unsupported

Verified empirically against `<org>/<project-a>` with a real work item (`706403`, since deleted) carrying
the tag `zzprobe-a:STORY-1`:

| Query | Result |
|---|---|
| `[System.Tags] CONTAINS 'zzprobe-a:'` (prefix of the tag) | **no match** |
| `[System.Tags] CONTAINS 'zzprobe'` (prefix of the tag) | **no match** |
| `[System.Tags] CONTAINS WORDS 'zzprobe-a'` | **no match** |
| `[System.Tags] CONTAINS 'zzprobe-a:STORY-1'` (the whole tag) | **matched** |
| `[System.Tags] = 'zzprobe-a:STORY-1'` | **error — operator not supported on this field** |
| control: `[System.Id] = 706403` | matched |

`CONTAINS` on `System.Tags` is **tag-set membership**, despite reading like a string operator. A query
for a prefix of a tag returns **zero rows on a tracker full of matching items**, with exit code 0.

**Two related facts, same run.** A colon **is** accepted inside a tag value and round-trips exactly — no
splitting, no normalization. Multiple tags are returned as one string delimited by `"; "` (semicolon
**and** space).

**Why this matters beyond one query.** It nearly shipped a `/devops-azure` batch write mode whose entire
resume path queried `CONTAINS '<feature>:'`. That returns nothing, always — so every already-created
item would have fallen to the "no entry" disposition and been **created a second time on every run**,
which is the exact duplication the mode's six-row reconciliation table exists to prevent. A
positive-control query does **not** catch this: the query is valid and merely semantically wrong, so the
control reports the mechanism healthy and the caller then trusts a confidently wrong empty result.

**Workaround:** tag each item **twice** at creation — a per-item key tag `<feature>:<item-id>` for
identity, and a bare **anchor tag** `<feature>` with no colon. The anchor is a whole tag, so
`CONTAINS '<feature>'` returns every item of the feature in one query; exact equality against the split
tag set then resolves which item each row is. Applied in `skills/devops-azure/SKILL.md` sections 8d
and 8f.

**A second trap found in the same run, worth its own line.** Reading a tag back with a shell-quoted
JMESPath projection — `--query 'fields."System.Tags"' -o tsv` — returned **empty for an item whose tag
was present and correct**, because the quoted expression was mangled before `az` received it (see
[[2026-07-30-powershell-mangles-native-exe-arguments]]). A projection containing quotes or parentheses
can fail at the shell layer and yield nothing with **exit code 0**; `--query "keys(fields)"` failed
outright with `-o was unexpected at this time`. So **absent output from a projection is evidence about
the projection, not about the data.** Read `--output json` and search the object instead.

Also noted: `az boards work-item delete` **requires `--project`**, while `az boards work-item show` does
not — work item ids are unique org-wide, so the asymmetry is in the CLI rather than in the data model.

Found by executing an acceptance bar against a live org rather than reviewing prose. Four review passes
(`devils-advocate`, `code-reviewer`, `security-reviewer`, and a `merge-reviewer` gate) all read
`CONTAINS` as substring matching, because it reads that way.
