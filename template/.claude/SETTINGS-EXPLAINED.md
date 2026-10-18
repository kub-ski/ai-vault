# What `settings.json` does (plain words)

JSON files cannot hold comments, so the explanation lives here. `settings.json` wires four hooks. A hook is a small script Claude Code runs for you at a fixed moment.

| When it runs | Script | What it does |
|---|---|---|
| A session starts, resumes, forks, or you type `/clear` | `hooks/session-start.sh` | Prints your identity, preferences, the active project's newest decision and its state file. Claude reads that before your first message. |
| Just before Claude compacts a long conversation | `hooks/save-state.sh precompact` | Saves a snapshot (your recent requests, files changed, Claude's last message) into the state file. |
| Right after compaction | `hooks/post-compact.sh` | Puts the saved state back in front of Claude, so it does not forget mid-task. |
| A session ends | `hooks/save-state.sh sessionend` | Saves the same snapshot, so closing the window loses nothing. |

Rules all four follow:

- They write only inside this vault and never use the network. To save a snapshot, `save-state.sh` reads the session transcript that Claude Code keeps under `~/.claude/`.
- They fail open. If something breaks they print nothing and exit, and you keep working.
- Your own notes in `state.md` (Done, Next, Open questions) are never overwritten. Only the block between `<!-- auto-snapshot:start -->` and `<!-- auto-snapshot:end -->` is.
- "Active project" is the one name in `.claude/active-project`. `/kickoff` sets it.

To turn memory off, delete the `hooks` section of `settings.json`. To check it works: `bash tests/test-memory-loop.sh`.
