---
name: memory-query
description: Searches the project's memory/ directory by keyword or regex pattern. Runs scripts/query-memory.sh, then summarizes matching files and their relevance. Use when looking for prior decisions, known issues, or architectural context on a topic.
---

# Memory Query

Search the project's `memory/` directory for entries matching a topic or pattern.

## 1. Get the search pattern

If the user provided a search term or topic, use it as the pattern. If not, ask what they are looking for.

## 2. Locate the pack and memory directory

- Find the pack directory (contains `scripts/query-memory.sh`).
- The memory directory defaults to `./memory` in the current project. If the user specifies a different path, use that.

## 3. Run the query

```bash
bash <pack-dir>/scripts/query-memory.sh "<pattern>" <memory-dir>
```

The script skips files with `status: superseded` or `status: archived`. Capture the full output.

## 4. Interpret the results

- If matches are found, the script prints the file path and matching lines for each hit.
- Read each matching file in full to understand its content.
- Summarize what was found: which files matched, what decision or context they record, and how it relates to the user's query.

## 5. Report

Present a concise summary organized by relevance:
- **Directly relevant** — files that answer the question or describe the topic
- **Tangentially related** — files that mention the topic in passing

For each relevant file, include the subdirectory (decisions / architecture / context / known-issues), a one-line summary of its content, and any key constraints or warnings it records.

If no matches are found, say so and suggest broader search terms or related topics the user might try.
