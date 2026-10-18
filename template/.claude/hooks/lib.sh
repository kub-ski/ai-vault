#!/bin/bash
# Shared helpers for the memory hooks. Sourced, never run on its own.
# Every hook "fails open": if anything goes wrong it prints nothing and exits 0,
# so a broken hook can never block you from working.

# The vault root = two folders up from this file (.claude/hooks/lib.sh).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Which project is "active"? The slug is one line in .claude/active-project
# (the /kickoff command writes it). Only plain a-z 0-9 - are accepted.
active_slug() {
  local s=""
  [ -f "$ROOT/.claude/active-project" ] && s="$(tr -d ' \r\n' < "$ROOT/.claude/active-project")"
  case "$s" in ""|*[!a-z0-9-]*) echo ""; return ;; esac
  [ -d "$ROOT/03-projects/$s" ] && echo "$s" || echo ""
}

# Where session state lives: the active project's state.md, else 00-meta/state.md.
state_file() {
  local s; s="$(active_slug)"
  if [ -n "$s" ]; then echo "$ROOT/03-projects/$s/state.md"; else echo "$ROOT/00-meta/state.md"; fi
}

# Newest decision doc (dated file names sort by date) in a project's docs/decisions/.
newest_decision() {
  local s; s="$(active_slug)"; [ -n "$s" ] || return 0
  ls -1 "$ROOT/03-projects/$s/docs/decisions/"*.md 2>/dev/null | sort | tail -n 1
}

# Print a file with a header, capped so one big file cannot flood the context.
show() { # show <path> <max-lines>
  [ -f "$1" ] || return 0
  echo; echo "----- ${1#$ROOT/} -----"
  head -n "${2:-120}" "$1"
}
