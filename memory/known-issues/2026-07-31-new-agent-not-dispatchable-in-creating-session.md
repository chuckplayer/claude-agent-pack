---
type: known-issue
status: active
discovered: 2026-07-31
scope: agents/*.md, install.sh, any cut that adds a new agent
overrides-convention: no
---

# A new agent file is not dispatchable in the session that creates it

**Skills hot-reload from the repo mid-session. Agents do not.**

`/spec-intake` was created and then successfully invoked in the same session (2026-07-31): the skill
appeared in the available-skills list as soon as its `SKILL.md` was written. Writing
`agents/backlog-auditor.md` in that same session produced the opposite result — dispatching it failed
with `Agent type 'backlog-auditor' not found`, and the error listed only the 19 previously installed
agents.

**Why.** `install.sh:66-78` copies `agents/*.md` into `~/.claude/agents/`. The harness enumerates that
directory when the session starts, so an agent file that exists only in the repo working tree — or that
is copied in mid-session — is not in the list the `Agent` tool resolves against.

**Workaround:** re-run `install.sh`, then start a new session. Only then can the agent be dispatched.

## Why this bites plan authoring specifically

`docs/plans/backlog.md:507` states, correctly, that *"`install.sh:76-88` globs `agents/*.md` and
`skills/*/`, so neither new file needs registration."* That is true and it is **not the same claim** as
"the new agent can be dispatched in this cut." Those two got conflated, and two acceptance bars
(BAR-012, BAR-013) were written to exercise `backlog-auditor` behaviourally inside the cut that creates
it. Both were unrunnable for environmental reasons rather than because anything was wrong with the
implementation.

**When a cut adds a new agent, write its behavioural bars as `manual` evidence explicitly deferred to a
post-install session**, or expect them to come back NOT RUN. A bar that cannot be run in the cut that
ships it fails the run on a criterion nobody can meet yet, which is a bar-design defect rather than an
implementation defect.

## What this does not affect

- **Skills.** A new `skills/<name>/SKILL.md` is invocable immediately in the same session.
- **Editing an existing agent.** The installed copy is what runs, so an edit to a repo agent file also
  has no effect until `install.sh` runs again — but the agent remains dispatchable throughout, which is
  why this is easy to miss.
- `scripts/check-updates.sh` already detects installed-vs-repo drift and is the tool that would surface
  the 19-vs-20 mismatch.
