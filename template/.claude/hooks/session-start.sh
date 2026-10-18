#!/bin/bash
# SessionStart (new session, resume, or /clear): load your memory into the conversation.
# Whatever this script prints becomes context Claude reads before your first message.
# (Claude Code loads the root CLAUDE.md by itself; this adds everything else.)
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh" 2>/dev/null || exit 0
cat >/dev/null 2>&1   # ignore the JSON Claude Code sends on stdin

echo "AI VAULT: your saved memory, loaded automatically at session start."
echo "Read it before replying. Do not paste it back to the user; just use it."
slug="$(active_slug)"
if [ -n "$slug" ]; then echo "Active project: $slug"; else echo "No active project set. Ask which one, or run /kickoff."; fi

show "$ROOT/01-personal/identity.md" 80
show "$ROOT/01-personal/communication-prefs.md" 80
if grep -qs "not filled in yet" "$ROOT/01-personal/identity.md"; then
  echo; echo "NOTE: identity.md is still the blank template. Offer to fill it in with the user."
fi
if [ -n "$slug" ]; then
  show "$ROOT/03-projects/$slug/CLAUDE.md" 60
  d="$(newest_decision)"; [ -n "$d" ] && show "$d" 60
fi
show "$(state_file)" 100
echo
echo "----- end of saved memory -----"
exit 0
