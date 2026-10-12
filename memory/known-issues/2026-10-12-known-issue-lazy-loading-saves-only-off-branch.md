---
date: 2026-10-12
type: known-issue
status: active
superseded-by: n/a
scope: references/, agents/tech-lead.md, skills/devops-azure, skills/plan, scripts/lint-agents.sh
overrides-convention: no
related-to: 2026-10-12-decision-install-time-reference-substitution.md
discovered: 2026-10-12
---

# Lazy-loaded references save tokens only on the branches not taken, and some paths now cost more

## Summary

Moving text into `references/` removes it from every dispatch that does not need it, and adds a read to the ones
that do. The always-loaded cut measured about 42 percent on `/hotfix`, 38 percent on `/implement` without a
plan, and 40 percent with a plan (35 to 37 percent counting the references those paths read). One path costs
more than before, and several guarantees are only as strong as the model's willingness to read.

## Symptoms

- **`/plan` in plan-file mode costs about 4.8K bytes more than before.** tech-lead reads the guard, the
  authoring rules, the checkable-call definition and the bar-soundness table (24.4K) to avoid carrying 19.6K.
  It was 16K worse until the checkable-call definition was split out of the 14K plan gate. It is the only path
  that reads three references and is low frequency.
- **devops-azure batch mode reads an 84K file in full**, as the original skill did, and the Read tool may need
  ranges.
- **A skipped read is not caught by the fail-closed clauses**, which cover an unreadable file only. The
  mitigations are inline rules that degrade to the stricter behaviour (batch mode falls back to per-write
  confirmation; the shell-injection and `AUTHORIZED` rules are inline) and, for tech-lead, a read-back item
  confirming the table was read.
- **No linter rule checks the `${CLAUDE_SKILL_DIR}/batch.md` pointer** (R1 resolves only the install token),
  and nothing checks the plain-text pointer in the consumer template.
- **`scripts/lint-plans.sh` does not exist in a consuming project**, but `/plan` runs it by repo path. Pre-existing.

## Root Cause

A reference is a second read the model must choose to make. Extraction saves where the branch is rare and costs
where it is common, and the saving is per dispatch, so frequency decides it.

## Workaround

Measure a candidate extraction against the paths that read it before moving text, as the byte table did, and
keep a rule inline when it must hold even if the reference is not read.

## Revisit Trigger

Revisit when any of these are decided: `omitClaudeMd: true` on agents that do not need the memory and
conventions rules (a larger lever than any extraction here; needs a per-agent decision); extracting
devils-advocate's own memory-write section the way tech-lead's was; a `lint-plans.sh` rule enforcing the
two-space `Evidence:` indent that gate 4a already applies; a single-awk-pass rewrite of the per-file linter
(about 25 forks per file is most of its 50 s runtime); a key allowlist for `scripts/set-env.sh`; and durable
installer tests (the engineers' drivers hold about 340 cases, none committed). Also unverified: a user-scope
install and uninstall round trip, real symlinks and junctions on this Windows machine, and live behaviour of
the edited agents outside a project-scope scratch install.
