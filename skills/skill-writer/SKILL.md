---
name: skill-writer
description: Scaffold a new skill for the Claude Agent Pack. Interviews the user about the skill's purpose and behavior, reads existing skills as examples, writes the SKILL.md, and validates it with /lint-agents. Use when the user wants to create a new slash command entry point. Trigger this when someone says: create a new skill, build a slash command, add a skill, I want a new /command, write a skill for the pack, make a new skill. Do NOT use to update an existing skill — read the existing SKILL.md and edit it directly. Do NOT use to create agents — agents use AGENT.md files with different conventions.
---

# Skill Writer

Scaffold a new skill for the Claude Agent Pack by interviewing the user, grounding the skill in existing conventions, and writing a correct, lint-passing SKILL.md.

## 1. Read existing skills for conventions

Before asking the user anything, read 2–3 existing skills to understand structure, tone, and frontmatter conventions:

```
skills/conventions/SKILL.md
skills/check-readiness/SKILL.md
skills/implement/SKILL.md
```

Note the frontmatter fields (`name`, `description`) and the section structure used in the body.

## 2. Interview the user

Ask these questions conversationally — one at a time, not as a list dump:

1. **Name:** What should the skill be called? (This becomes the slash command, e.g. `skill-writer` → `/skill-writer`)
2. **Purpose:** What does this skill do in one sentence?
3. **Trigger:** When should a user invoke it? What are the clearest trigger phrases or situations?
4. **Behavior:** Walk me through what the skill should do step by step. What agents, if any, does it invoke? Does it read files, interview the user, write output?
5. **Output:** What does the skill produce at the end — files written, a report, a prompt to the user?

Clarify ambiguities before writing. A good skill description is specific enough that the tech-lead can route to it unambiguously.

## 3. Draft the SKILL.md

Write the file to `skills/<name>/SKILL.md`. Follow this structure exactly:

```markdown
---
name: <name>
description: <one clear sentence — used for routing by tech-lead; must unambiguously state when this skill is invoked>
---

# <Title>

<One-paragraph summary of what the skill does and why.>

## 1. <First step>

...

## N. <Last step>

...
```

Rules:
- The `description` field is the routing contract — make it specific and unambiguous.
- Steps should be imperative and actionable, not vague.
- If the skill invokes agents, name them explicitly and in order.
- If the skill is interactive (asks the user questions), say so in step 1 and describe the questions.
- Do not add frontmatter fields beyond `name` and `description` — these are the only supported fields.

## 4. Present the draft

Show the user the complete SKILL.md content and ask: "Does this capture the skill correctly? Any changes before I write it?"

Make any corrections, then write the final file.

## 5. Update the README

Add the new skill to the Skills table in `README.md`. Match the existing row format:

```markdown
| `/skill-name` | What it does (one sentence) |
```

Insert it in alphabetical order by skill name.

## 6. Run /lint-agents

Always run `/lint-agents` after writing to validate the new skill file. If it fails, fix the reported issues and re-validate before finishing.

## 7. Confirm

Report back:
- The file written (`skills/<name>/SKILL.md`)
- The README row added
- Whether lint passed or any issues were found

## Gotchas

- **Description over 1024 characters:** The lint check will catch this, but write the description tightly from the start. Include what, when, and trigger phrases — but do not repeat the same information twice.
- **Vague trigger phrases in the description:** "Use when helpful" is not a trigger phrase. Trigger phrases must be specific phrases a real user would actually type. Ask the user for examples of how they would invoke the skill.
- **Skill name conflicts with an existing skill:** Check the skills/ directory before writing. If a name collision exists, ask the user whether to update the existing skill or choose a different name.
- **lint-agents fails on frontmatter:** The only allowed frontmatter fields are `name` and `description`. Do not add `category`, `version`, `author`, or any other fields — the linter will reject them.
- **Skipping the user approval step:** Step 4 requires showing the draft and getting explicit approval before writing. Do not skip this to save time — it avoids a write-fix-rewrite cycle if the intent was misunderstood.
