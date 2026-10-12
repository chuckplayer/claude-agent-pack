---
date: 2026-10-12
type: finding
status: active
superseded-by: n/a
scope: install.sh, agent and skill pointers to references/, any design that reads a file from a subagent
overrides-convention: no
related-to: 2026-10-12-decision-install-time-reference-substitution.md
---

# Which path forms a subagent can Read, and which install scope wins

## Summary

From a read-only subagent, three path forms resolve and one fails loudly. Agents and skills resolve scope in
opposite orders. A skill body receives `${CLAUDE_SKILL_DIR}` already substituted. All of this was observed by
running it, on Claude Code 2.1.296 on Windows, not read from documentation alone.

## Discovery Context

A spike before the references design, and live behaviour tests after it: nested `claude -p` sessions run from a
scratch project directory, with the event stream captured so the subagent's own tool calls could be read
(`--output-format stream-json --verbose`; a subagent's calls carry a `parent_tool_use_id`).

## Impact

- `~/.claude/...`, an absolute path, and a project-relative path with the project root prefixed all Read from a
  subagent. A relative path read from the wrong working directory fails with "file does not exist", which is
  why the pointer sentence carries the prefix clause. Confirmed live: a project-scope install's merge-reviewer
  read `.claude/agent-pack/references/plan-gate.md` resolved against the project root.
- Subagent precedence is project over user; skill precedence is user over project. A machine with both scopes
  therefore runs skills from one copy and agents from the other.
- `${CLAUDE_SKILL_DIR}` in a project-scope skill body became an absolute path and a sibling file was Read
  through it. It was not tested for a user-scope skill.
- The Read tool may refuse or truncate a very large file; the 84K `batch.md` therefore carries an instruction to
  read it in ranges until all of it is read.
- A subagent given an unreadable reference did what the fail-closed stub said: merge-reviewer returned a FAIL
  naming the exact path for both the plan gate and the worktree steps, and tech-lead stopped with a failure
  report and no chat plan. With the references present, tech-lead read the guard first, then the authoring
  rules, then the checkable-call definition, then bar soundness, and wrote nothing in test mode.

## Workaround

To test a subagent's behaviour from a script, run `claude -p` from a scratch project directory that has the pack
installed at project scope (`install.sh --scope project --project-dir <scratch> --force --yes`), and parse the
stream-json events for subagent tool calls instead of trusting the subagent's own account of what it read. An
agent definition is enumerated when a session starts, so test a changed agent in a new session, not the one
that edited it. Not covered: a user-scope install, because the harness refuses `HOME` redirects.
