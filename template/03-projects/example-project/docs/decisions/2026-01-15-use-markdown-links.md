---
type: decision
status: active
updated: 2026-01-15
---
# Decision: use plain Markdown links, not wikilinks

## Context
Some note apps write links as `[[page name]]`. Those only work inside that app. Claude Code, GitHub, VS Code and most other tools show them as plain text, so a note that links to another note becomes a dead end for the AI that is supposed to follow it.

## Decision
Every link in the vault is a Markdown link with a relative path: `[Rules](../00-meta/rules.md)`. We do not use `[[wikilinks]]`, even if the app offers them.

## Why this works
Any tool can follow the link, including Claude. Relative paths keep working when the vault moves to a new folder or machine. The cost: a moved file breaks the links that point to it, so moving a file now means fixing its links the same session, and `tools/check-links.py` finds the ones we miss.

## Implementation impact
- Rule written in the root `CLAUDE.md` (bright lines).
- Run `python3 tools/check-links.py` after moving or renaming files.
- If you use Obsidian: Settings, Files and links, turn off "Use [[Wikilinks]]".

## Related
- [Root CLAUDE.md](../../../../CLAUDE.md): where the rule is stated
- [Naming conventions](../../../../00-meta/naming-conventions.md)
