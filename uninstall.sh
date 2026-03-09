#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENTS_DIR="$HOME/.claude/agents"
SKILLS_DIR="$HOME/.claude/skills"

to_remove_agents=()
to_remove_skills=()

if [ -d "$AGENTS_DIR" ]; then
    for agent_file in "$SCRIPT_DIR/agents/"*.md; do
        filename="$(basename "$agent_file")"
        target="$AGENTS_DIR/$filename"
        if [ -f "$target" ]; then
            to_remove_agents+=("$target")
        fi
    done
fi

if [ -d "$SKILLS_DIR" ]; then
    for skill_dir in "$SCRIPT_DIR/skills/"*/; do
        skill_name="$(basename "$skill_dir")"
        target="$SKILLS_DIR/$skill_name"
        if [ -d "$target" ]; then
            to_remove_skills+=("$target")
        fi
    done
fi

if [ ${#to_remove_agents[@]} -eq 0 ] && [ ${#to_remove_skills[@]} -eq 0 ]; then
    echo "Nothing to remove -- no matching agents or skills found."
    exit 0
fi

echo "The following will be removed:"
echo ""
for path in "${to_remove_agents[@]}"; do echo "  agent: $(basename "$path")"; done
for path in "${to_remove_skills[@]}"; do echo "  skill: $(basename "$path")"; done

echo ""
read -p "Remove these? [y/N] " response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
for path in "${to_remove_agents[@]}"; do
    rm -f "$path"
    echo "  Removed agent: $(basename "$path")"
done
for path in "${to_remove_skills[@]}"; do
    rm -rf "$path"
    echo "  Removed skill: $(basename "$path")"
done

echo ""
echo "${#to_remove_agents[@]} agent(s) and ${#to_remove_skills[@]} skill(s) removed."
echo ""
echo "Note: project-level memory/ directories are not removed -- those live"
echo "in your repositories and are managed like any other project file."
