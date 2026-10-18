#!/bin/bash
# SessionStart with matcher "compact": runs right after Claude's context was compacted.
# Compaction shrinks the conversation, so this puts the saved state back in front of Claude.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh" 2>/dev/null || exit 0
cat >/dev/null 2>&1
echo "AI VAULT: the conversation was just compacted. Your saved state, restored from disk:"
show "$(state_file)" 120
echo
echo "Before you carry on: re-read the state above, check it matches what you are doing, and tell the user in one line where you are."
exit 0
