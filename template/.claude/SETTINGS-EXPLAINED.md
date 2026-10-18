# What `settings.json` does (plain words)

JSON files cannot hold comments, so the explanation lives here. `settings.json` wires five hooks. A hook is a small script Claude Code runs for you at a fixed moment.

| When it runs | Script | What it does |
|---|---|---|
| A session starts, resumes, forks, or you type `/clear` | `hooks/session-start.sh` | Prints your identity, preferences, the active project's newest decision, its `state.md` and the last 3 session recaps. Claude reads that before your first message. |
| The same moment | `hooks/recap.sh sweep` | Looks for an earlier session of this vault that went quiet for 30+ minutes without ending cleanly (a crash, a closed terminal) and writes its recap. At most two, from the last three days. |
| Just before Claude compacts a long conversation | `hooks/recap.sh precompact` | Writes a recap of the session so far (see below). |
| Right after compaction | `hooks/post-compact.sh` | Tells Claude to re-read its state file, and shows it. |
| A session ends | `hooks/recap.sh sessionend` | Writes a recap of the session. |

## How a recap is written

1. `recap.py` reads only the part of the session transcript that is new since that session's last recap, and at most its last ~30,000 characters. (Claude Code keeps each session's transcript in your home folder, under `.claude`.)
2. If the new part is short (under ~400 characters of conversation: a quick question, a to-do update, a `/compact`), it stops. Nothing to recap.
3. It runs your own `claude -p` with **no tools**, outside the vault, and asks for four lines: Done, Decided, Open loops, Next step. If `claude` is missing, logged out, or answers with anything else, it stops and nothing changes.
4. It **appends** the four lines under a dated heading to `session-log/YYYY-MM.md` in the active project (or `00-meta/session-log/`). Each entry has one hidden marker line (`<!-- recap session=… -->`) so the same session saved twice gives one entry.

It runs in the background, so compaction and closing the window are never held up.

## Rules all hooks follow

- **Nothing is ever rewritten or deleted.** The session log is only appended to. No hook writes `state.md`: Claude keeps that current on purpose, and so do you.
- **They fail open.** If something breaks they print nothing, exit 0, and change nothing. You keep working.
- **They write only inside this vault.** The one network call is your own `claude` command writing the recap, under your Claude account, the same as the chat itself. No API key is used or stored.
- **Recaps are history, not instructions.** They are written from a transcript, so the start hook labels them that way.
- "Active project" is the one name in `.claude/active-project`. `/kickoff` sets it.

To turn memory off, delete the `hooks` section of `settings.json`. To turn off only the recaps, delete the three `recap.sh` entries. To check it works: `bash tests/test-memory-loop.sh`.
