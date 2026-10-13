---
date: 2026-10-12
type: decision
status: active
superseded-by: n/a
scope: install.sh, uninstall.sh, scripts/check-updates.sh, scripts/lib/pack-common.sh, references/, every agent and skill that carries a reference pointer
overrides-convention: no
related-to: 2026-10-12-decision-claude-md-template-and-orchestration-reference.md
---

# Reference pointers are rendered at install time, per scope, and a second scope is refused

## Summary

Text that is only needed on one branch lives in top-level `references/*.md`. An agent or skill reaches it
through a pointer written `{{AGENT_PACK_REFS}}/<name>.md`. The installer renders the token when it copies the
file: to `~/.claude/agent-pack/references` for a user-scope install, and to `.claude/agent-pack/references`
for a project-scope install, where every pointer sentence carries the clause "if that path is relative, prefix
it with the project root". The installer takes `--scope user|project` and refuses to install into a second
scope unless `--force` is given.

## Context

The goal was to cut the tokens loaded on every dispatch. The installer used to copy only `agents/*.md` and
`skills/*/SKILL.md`, so a reference file had no delivery path, and a path written into an agent had to be valid
in whichever scope was installed. A project-level install was also requested, so the pack can be committed with
a project.

## Rationale

- A fixed token rendered per scope is the only form that is correct in both scopes, binds each installed copy to
  its own scope's references, and can be checked mechanically (the linter's R1 resolves every pointer, and the
  installer asserts zero tokens survive rendering, with a positive control).
- A read spike showed `~`, an absolute path, and a relative path with the project-root prefix all work from a
  read-only subagent; a relative path from the wrong working directory fails loudly rather than silently.
- Agents resolve project-over-user and skills resolve user-over-project, so a machine holding both scopes runs
  skills from one copy and agents from the other. A warning does not stop mixed-version pipelines, so the second
  scope is refused. Detection is an `agent-pack/.installed` marker or at least half the pack's agent names.
- References install into one namespaced directory that the installer wipes and recopies whole, which handles
  renames and deletions without a retired-references list.
- `check-updates.sh` compares the rendered source with the installed file, so substituted files do not report
  drift.

## Alternatives Rejected

- **Absolute paths for user scope:** unnecessary, because `~` resolves from a subagent.
- **Skill-local `references/` directories (the plugin's layout):** two install paths, two lint rules, two
  substitutions.
- **Warn-only on a dual-scope install:** does not prevent the mixed-version pipeline.
- **`sed` with an unescaped replacement:** the path can contain `&`, `|`, `\` or spaces.
- **A per-agent `omitClaudeMd` instead of text extraction:** a larger lever, but it removes the memory and
  conventions rules from that agent and needs its own decision per agent.

## Implications

- The rendered path is baked into every installed file, so changing the token or the directory later needs a
  migration.
- A project install must be committed (`.claude/`), and `worktree.baseRef` must be `head` for a worktree to see
  committed references. The installer warns but does not set it.
- Every reader needs a fail-closed clause, because a missing reference otherwise fails open (the agent just
  never reads it). See `architecture/2026-10-12-arch-references-lazy-loading.md`.
