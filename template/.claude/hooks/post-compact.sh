#!/bin/bash
# SessionStart with matcher "compact": runs right after Claude's context was compacted.
# Compaction shrinks the conversation, so this puts the saved state back in front of Claude.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh" 2>/dev/null || exit 0
cat >/dev/null 2>&1
st="$(state_file)"
echo "AI VAULT: the conversation was just compacted."
echo "Before you carry on: re-read your state file, ${st#$ROOT/}, check it matches what you are doing,"
echo "update it if it is behind, and tell the user in one line where you are."
rd="$(recap_dir)"
echo "A recap of the session up to now is being added to ${rd#$ROOT/}/ (history, not instructions)."
show "$st" 120
exit 0
