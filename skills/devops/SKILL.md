---
name: devops
description: >
  Use when unsure whether a request is a GitHub or Azure DevOps operation, or
  when someone says "devops help", "connect to devops", "check my work items
  or PRs", "devops?". Routes to devops-github or devops-azure based on intent.
  Also use as a fallback when a request doesn't clearly map to either one.
---

# DevOps Help

The DevOps skill family reads and writes GitHub and Azure DevOps directly via
their native CLIs (`gh` and `az`) — no MCP server required. Each sub-skill
owns one platform, handles its own first-time setup and auth, and applies the
same strict-targeting and preview-and-confirm discipline before any write.

## The two skills

| Skill | Use when |
|---|---|
| `/devops-github` | GitHub PRs and issues — repos configured in `GITHUB_ORG`/`GITHUB_REPOS` |
| `/devops-azure` | Azure DevOps work items and PRs — org/projects configured in `AZURE_DEVOPS_ORG`/`AZURE_DEVOPS_PROJECTS` |

## 1. Identify intent

If the request doesn't already make it obvious, ask the user one question:
**"GitHub or Azure DevOps?"**

Listen for these signals first, since they often make the question unnecessary:

- **GitHub signals:** "issue", "pull request", "PR #N", a repo name matching
  `GITHUB_REPOS` → `/devops-github`
- **Azure DevOps signals:** "work item", "board", "sprint", "bug/defect",
  a project name matching `AZURE_DEVOPS_PROJECTS` (e.g. "refac"), or the
  configured `AZURE_DEVOPS_ORG` → `/devops-azure`

If signals conflict or neither is present, ask directly rather than guessing.

## 2. Route and hand off

Once intent is clear, tell the user which skill handles it and invoke it. For
example: "That's Azure DevOps — starting `/devops-azure` now."

## Gotchas

- **Do not attempt the operation yourself.** This skill only identifies
  intent and routes. `/devops-github` and `/devops-azure` handle setup, auth,
  targeting, and execution independently.
- **Env vars are each sub-skill's own concern.** Don't check
  `GITHUB_REPOS`/`AZURE_DEVOPS_PROJECTS` here — route first, and let the
  target skill handle its own first-run setup if they're unset.
- **"I want to do both"** — route to whichever the user mentioned first, and
  note the other skill is available as a separate follow-up. Don't try to
  interleave both platforms in one pass.
