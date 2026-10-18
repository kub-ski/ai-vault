#!/bin/bash
# Install the vault template into a new folder.
#   ./scripts/install.sh ~/my-vault            copy the template there
#   ./scripts/install.sh ~/my-vault --git      also start a git history (local only)
# Safe: refuses to touch a folder that already has files in it. No sudo, no network, no passwords.
set -u
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-}"; GIT=0; [ "${2:-}" = "--git" ] && GIT=1
if [ -z "$DEST" ]; then echo "Usage: $0 <new-vault-folder> [--git]"; exit 1; fi
DEST="${DEST/#\~/$HOME}"
if [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "Stopped: $DEST already has files in it. Pick a new or empty folder."; exit 1
fi
command -v python3 >/dev/null || { echo "Stopped: python3 is needed (the hooks use it). On a Mac, run: xcode-select --install"; exit 1; }
mkdir -p "$DEST" || exit 1
cp -R "$SRC/template/." "$DEST/" || exit 1
chmod +x "$DEST"/.claude/hooks/*.sh
TODAY="$(date +%F)"
perl -pi -e "s/YYYY-MM-DD/$TODAY/" "$DEST/log.md" "$DEST/01-personal/identity.md" "$DEST/01-personal/communication-prefs.md" "$DEST/00-meta/state.md"
if [ "$GIT" = 1 ] && command -v git >/dev/null; then
  (cd "$DEST" && git init -q -b main && git add -A && git -c user.name="vault" -c user.email="vault@localhost" commit -q -m "Start vault from ai-vault template") && echo "Git history started (local only)."
fi
echo "Vault created at: $DEST"
echo "Self-test:"; bash "$SRC/tests/test-memory-loop.sh" "$DEST" || { echo "Self-test FAILED. Tell your AI what you see above."; exit 1; }
echo "Next: open Claude Code in that folder and run /kickoff."
