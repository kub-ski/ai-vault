# Vault: home base

This folder is a **vault**: one place where your notes, projects and decisions live as plain Markdown files, so any AI you use can read them and pick up where you left off. This file is the router. It holds the rules that must be true in every session and points to everything else.

## Read at session start (in order)

A hook loads items 2 to 5 for you (see `.claude/SETTINGS-EXPLAINED.md`). If it did not, read them yourself.

1. This file.
2. `01-personal/identity.md` (who the user is) and `01-personal/communication-prefs.md` (how they like to work).
3. The active project's `CLAUDE.md` (the project is named in `.claude/active-project`).
4. The newest file in that project's `docs/decisions/`.
5. The project's `state.md` (what is done, what is next).

Then say in 3 or 4 lines what you loaded, by file name only, and ask what we are working on. `index.md` is the map of the vault: open it when you need to find something.

## The vault is the memory

Anything that must survive past this conversation goes in a file here, never only in the chat. If Claude Code offers its own auto-memory, ignore it and use the vault instead.

| What | Where |
|---|---|
| Who the user is | `01-personal/identity.md` |
| How they like to work | `01-personal/communication-prefs.md` |
| Project status, next steps | that project's `state.md` |
| Why we chose X | that project's `docs/decisions/` |
| What happened, newest first | `log.md` |

`state.md` is saved automatically by hooks before compaction and when a session ends. Run `/wrapup` at the end of real work to make the save deliberate.

## How to behave

1. **Verify before saying done.** Open the file, run the command, render the page. Look at what was actually produced. Never just assert it works.
2. **Check negatives with one direct call.** Before writing "not installed", "no access", "nothing found", "unchanged", try the thing once. A false "no" ends the inquiry and nobody notices.
3. **State what "working" means before a big build.** Write a numbered list with a checkable result for each item, and get a yes.
4. **Change only what was named.** Do not spread an edit to other files or pages.
5. **Long output goes in a file.** Over about 15 lines: write a file, reply with the path and a short summary.
6. **Decision doc first.** Before a structural choice (folders, naming, tools, direction), write the dated note in `docs/decisions/`, then do the work.
7. **Ask before writing to canonical files** you did not create this session (identity, prefs, this file, another project's files).

Every rule is one of three kinds. **LAW** (safety, legal, no secrets): permanent. **METHOD** (how you know: verify, check negatives, decide in writing): cheap, keep. **CRAFT** (what output looks like: style, formats): provisional; if nobody can name the failure a craft rule came from, delete it. Details: `00-meta/rules.md`.

## Bright lines

- **No secrets in the vault.** No passwords, API keys, tokens or private keys in any file. Keep them in a password manager or in `.env` files outside the vault. If you find one, tell the user to change it.
- **Raw sources are immutable.** Never edit anything in `06-sources/`. Write your notes about a source elsewhere.
- **Moving a file means fixing its links** in the same session. Run `python3 tools/check-links.py` after any move.
- **One canonical file per thing.** No copies. If two versions exist, merge into one and leave a one-line pointer in the other.
- **The root stays clean.** Only `CLAUDE.md`, `README.md`, `index.md`, `log.md` and the numbered folders. Quick captures go to `06-sources/raw/`.
- **Markdown links only**, relative paths. No `[[wikilinks]]`. Every entity page ends with a `## Related` list.

## Folders

`00-meta` rules and templates · `01-personal` about the user · `02-work` work or business areas · `03-projects` one folder per project · `04-research` investigations · `05-knowledge` reference notes that stay true · `06-sources` raw material, never edited · `99-archive` finished or retired. Naming: lowercase, hyphens, no spaces; dated files start `YYYY-MM-DD-`. See `00-meta/naming-conventions.md`.

## Related

- [Index](index.md) · [Log](log.md) · [Rules](00-meta/rules.md) · [Naming](00-meta/naming-conventions.md)
