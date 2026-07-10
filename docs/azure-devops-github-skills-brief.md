# Design Brief: Azure DevOps + GitHub Skills

**Goal:** Enable reading and creating work items/PRs across Azure DevOps (`AMWINSGST` org — Boards + Repos, multiple projects) and GitHub (`Amwins` org, multiple repos), without an MCP server.

**Constraints:**
- No MCP server available — must shell out to `az` (with `devops` extension) and `gh` CLIs
- First-time setup (auth, extension install, env vars) must be walked through by the skill, not assumed
- Pack (`claude-agent-pack`) must stay generic/portable — no Amwins-specific org/project names hardcoded into skill bodies

**Approach:** Router + sub-skill pattern (matches existing `obsidian`/`wiki` families):
- `skills/devops/SKILL.md` — entry point, asks "Azure DevOps or GitHub?" and dispatches
- `skills/devops-azure/SKILL.md` — `az devops` setup + work item/PR read+write ops
- `skills/devops-github/SKILL.md` — `gh` CLI setup + PR/issue read+write ops

**Key decisions:**
- Org/project/repo values supplied via environment variables, with multi-project support as a **delimited list in one var**:
  ```
  AZURE_DEVOPS_ORG=AMWINSGST
  AZURE_DEVOPS_PROJECTS=ReFac,AmLINK-Teams
  GITHUB_ORG=Amwins
  GITHUB_REPOS=amlink-schematic-builder,other-repo
  ```
  The skill parses the list, matches against a project/repo named in the request, and asks to disambiguate if the request doesn't clearly name one and more than one is configured.
- First-time setup walks the user through setting these env vars (persisted in shell profile or local `.env`) plus authenticating each CLI natively (`az devops login` / `az login`, `gh auth login`) — no PATs stored in plaintext in the repo
- Full v1 scope: read work items/PRs, create work items/PRs, comment/update state, link work items to PRs/commits
- All write operations (create, comment, update, link) always preview the exact payload and require explicit confirmation before running the CLI command

**Known risks (accepted):**
- Azure DevOps field schemas (work item types, area/iteration paths) vary per project — skill must discover these at runtime rather than assume fixed fields
- Two separate auth flows (az CLI vs gh CLI) to keep straight per repo URL
- Env vars not set/exported is the most likely first-run failure — setup walkthrough should check and report clearly
- Ambiguous project/repo targeting when multiple are configured and the request doesn't name one explicitly — skill must ask rather than guess

**Open questions:** none blocking
