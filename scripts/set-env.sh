#!/usr/bin/env bash
# Set one or more env vars in ~/.claude/settings.json's "env" object.
# Reusable by any skill that needs to persist config across sessions without
# depending on the user's shell profile (which varies by OS/shell) --
# settings.json lives at the same relative path on macOS, Linux, and Windows.
#
# Usage: scripts/set-env.sh KEY=VALUE [KEY=VALUE ...]
#
# Uses scripts/lib/pack-common.sh, which always sits beside this script: nothing
# in the pack copies set-env.sh out of the checkout (the skills invoke it in place
# as `bash scripts/set-env.sh`). The JSON-tool probe and the secure settings
# writer (exclusive 0600 temp file, mode preserved, UTF-8, symlink-safe, atomic
# rename, python always -I) are the library's -- not a private copy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 KEY=VALUE [KEY=VALUE ...]" >&2
    exit 1
fi

PACK_LIB="$SCRIPT_DIR/lib/pack-common.sh"
if [ ! -f "$PACK_LIB" ]; then
    echo "ERROR: $PACK_LIB is missing -- incomplete pack checkout." >&2
    exit 1
fi
# shellcheck source-path=SCRIPTDIR source=lib/pack-common.sh
. "$PACK_LIB"

if ! pack_find_json_tool; then
    echo "ERROR: python3 or node is required to update settings.json -- neither found." >&2
    exit 1
fi

# Validate every pair before writing any of them.
pairs=()
for pair in "$@"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    if [ "$key" = "$pair" ]; then
        echo "ERROR: '$pair' is not in KEY=VALUE form" >&2
        exit 1
    fi
    pairs+=("$key" "$value")
done

# "~/..." is expanded by the interpreter (python expanduser / node os.homedir()),
# exactly as this script always resolved it.
# shellcheck disable=SC2088  # the tilde is for the interpreter, not the shell
if ! pack_settings_set_env "~/.claude/settings.json" "${pairs[@]}"; then
    echo "ERROR: failed to update ~/.claude/settings.json -- the existing file is unchanged." >&2
    exit 1
fi

for (( i=0; i<${#pairs[@]}; i+=2 )); do
    echo "[ok] env: ${pairs[$i]}=${pairs[$((i + 1))]}"
done
