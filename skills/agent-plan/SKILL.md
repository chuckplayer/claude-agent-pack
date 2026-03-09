---
name: agent-plan
description: Routes a task to the tech-lead agent for decomposition into a sequenced plan of specialist agent invocations. Use before implementation when the task is complex, spans multiple files, or the right approach is unclear.
---

# Plan with Tech-Lead

Use the **tech-lead** agent to decompose the task the user described.

The tech-lead will:
- Identify which specialist agents are needed
- Determine the correct invocation order (sequential vs. parallel)
- Surface whether devils-advocate should run before implementation
- Produce a step-by-step plan with a rationale for each step

After the tech-lead returns its plan:
1. Present the plan clearly to the user.
2. If the task introduces a new pattern, a new dependency, or an irreversible architectural change, recommend running `/challenge` on the plan before proceeding.
3. Ask: "Proceed with implementation, or revise the plan first?"
4. If the user proceeds, run `/implement` or execute the pipeline following the plan.
