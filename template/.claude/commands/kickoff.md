---
description: Start of session. Load context, pick the active project, confirm what we are working on.
---

Start-of-session ritual. The SessionStart hook has probably loaded your memory already (it appears at the top of this conversation as "AI VAULT: your saved memory"). Do not re-read what it already gave you.

1. If that memory is missing, read `CLAUDE.md`, `01-personal/identity.md`, `01-personal/communication-prefs.md`.
2. List the folders in `03-projects/` (skip `README.md`). Ask which project we are working on, unless `$ARGUMENTS` or the user's message already names it.
3. Write the chosen slug (just the folder name, nothing else) to `.claude/active-project`. This is how the hooks know which `state.md` to load and save.
4. Read that project's `CLAUDE.md`, its `state.md`, and the newest file in its `docs/decisions/` (if not already loaded).
5. Confirm in 3 to 5 lines what you loaded (file names only) and where the project stands: what is done, what is next.
6. If the work spans more than one thing, list the tracks as a numbered list and work one at a time. Do not run a delete, overwrite or move that belongs to a different track without listing exactly what it affects and getting a yes.
