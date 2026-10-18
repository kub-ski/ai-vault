---
description: End of session. Summarise, save state, log it, propose decision docs, ask before touching canonical files.
---

End-of-session ritual. Be brief and concrete: file paths, no fluff.

**1. Summary.** 5 to 8 bullets: what we did, what changed (paths), what was decided.

**2. Update the state file.** Open the active project's `state.md` (the slug is in `.claude/active-project`; with no active project use `00-meta/state.md`). Rewrite the sections Done, Next, Open questions and "Branches, links, versions" so a stranger could resume from them. Set `updated:` to today. You may edit `state.md` without asking: it exists for this. (If an old `<!-- auto-snapshot -->` block from an earlier version of the kit is still in it, ask the user before removing it.) Never edit `session-log/`: a hook appends Claude's recap there when the session ends.

**3. Log.** Add a new entry at the top of `log.md` (below the intro), three lines at most:

```
## [YYYY-MM-DD] <type> | <title>
- what happened, one line
- link to the decision doc or file if there is one
```

**4. Decision docs.** Did we make a structural decision (folders, naming, tools, direction, reversing an earlier call)? If yes, propose a doc `docs/decisions/YYYY-MM-DD-short-name.md` from `00-meta/templates/decision.md`. Show the user the draft and write it only after a yes. If we implemented first and documented after, say so.

**5. Drift check.** Run these and report anything that is not clean:
- `python3 tools/check-links.py` (dead links, especially after moves)
- A secrets sweep: `grep -rlE "BEGIN (OPENSSH|RSA|EC|DSA|PGP) PRIVATE KEY|sk-ant-|sk-proj-|ghp_[A-Za-z0-9]|xox[bap]-|AKIA[0-9A-Z]{16}" --include="*.md" --include="*.json" --include="*.env" . ; true`. If one hits, do not print it: tell the user to change that credential and move the file out of the vault.
- Root clean: only `CLAUDE.md`, `README.md`, `index.md`, `log.md` and the numbered folders (plus dotfiles). Anything else at the root is a stray; propose where it goes.
- A new project or page that is not in `index.md`: propose the line.

**6. Canonical files.** If a change belongs in `01-personal/identity.md`, `01-personal/communication-prefs.md`, `CLAUDE.md` or `00-meta/rules.md` (a new preference, a correction that should stick, a new rule), show the exact diff and ask. Never edit those silently. Never use Claude Code's own auto-memory: the vault is the memory.

**7. Close.** One line: "Saved. Next time: <the first item under Next>."
