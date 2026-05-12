---
name: lint-agents
description: "Validates required frontmatter fields and body content in every agent and skill file in the pack by running scripts/lint-agents.sh. Interprets failures with specific fix instructions. Use before committing new or modified agents/skills, or as a CI gate. Trigger this when someone says: lint agents, validate agents, check agent files, run lint-agents, validate the pack, check if my agent is valid, did I write the skill correctly."
---

# Lint Agents

Run the Agent Pack linter to validate all agent and skill files, then interpret any failures with specific, actionable fix instructions.

## 1. Run the linter

```bash
bash scripts/lint-agents.sh
```

Capture the full output. If the script does not exist or is not executable, report:

> `scripts/lint-agents.sh` not found. Run `/setup-project` to scaffold the project structure, or check that you are in the correct repository root.

## 2. Parse the output

For each file reported in the output:

- **PASS** — note it as passing. No action needed.
- **FAIL** — identify the specific reason from the linter message and produce a targeted fix instruction (see below).

## 3. Produce fix instructions for each failure

Map linter failure messages to actionable fixes:

| Failure message | Fix |
|---|---|
| Missing required field: `name` | Add `name: <value>` to the frontmatter. For agents, this is the agent's identifier. For skills, it matches the slash command name. |
| Missing required field: `description` | Add `description: >` followed by a multi-line description, or `description: "..."` for a single-line value. The description is the routing contract — make it specific. |
| Unknown frontmatter field: `<field>` | Remove the `<field>` line. Only `name`, `description`, `model`, `effort`, `tools`, `permissionMode`, and `version` are valid for agents; only `name`, `description`, `model`, and `effort` are valid for skills. |
| Description exceeds 1536 characters | Shorten the description. Remove repeated information — trigger phrases, exclusions, and the core purpose should each appear once. |
| Missing body content | The file has frontmatter but no body. Add at minimum one section (`## ...`) explaining what the agent or skill does. |
| Body is too short | Expand the body. Agent files must contain behavioral instructions, not just a title. |

If the failure message does not match any of the above patterns, quote the exact linter message and suggest reading the relevant agent or skill file against the conventions in `skills/skill-writer/SKILL.md`.

## 4. Report

Output a structured summary:

```
## Lint Results

### Passing
- agents/csharp-engineer.md ✓
- skills/implement/SKILL.md ✓
[...]

### Failing
- agents/my-new-agent.md ✗
  **Reason:** Missing required field: `description`
  **Fix:** Add `description: >` followed by a clear routing description to the frontmatter.

[...]

### Summary
- Total files checked: N
- Passing: N
- Failing: N

### Gate result: [PASS | FAIL]
```

Gate is PASS only if zero files fail. A single failing file is a FAIL gate.

## Gotchas

- **Running from the wrong directory:** `scripts/lint-agents.sh` expects to be run from the repository root. If the working directory is wrong, the script will report file-not-found errors for every agent. Verify the working directory before diagnosing individual failures.
- **Newly added files not appearing:** The linter discovers files via glob. If a new agent or skill file was just created but is not in the expected directory (`agents/` or `skills/<name>/SKILL.md`), it will not be checked. Verify the file path matches the convention.
- **Fixing one failure revealing another:** After fixing a failure and re-running, a previously hidden failure in the same file may appear. This is normal — address failures one at a time or fix all visible issues before re-running.
