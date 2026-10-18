# Memory-loop test: evidence

Run on 2026-10-18 with Claude Code 2.1.302 on macOS (stock `/usr/bin/python3` 3.9, `bash` 3.2), on fresh copies of the template made by `scripts/install.sh`. Nothing was edited by hand between steps.

## Why the memory was redone

The first design had a script read the session transcript and **rewrite one snapshot block** inside `state.md`. Three review rounds found three ways it lost or corrupted that block (a quick session pushing out a real one, marker text breaking the block, a damaged history file wiping it). Every bug came from the rewrite. So it was replaced with the design the author uses in his own vault:

- **Claude writes the recap.** A hook hands the end of the transcript to the user's own `claude -p` (no tools), which writes Done / Decided / Open loops / Next step.
- **Append only.** The recap is added to the bottom of `session-log/YYYY-MM.md`. Nothing is rewritten or deleted.
- **`state.md` is written on purpose,** by the working session, never by a hook.

## 1. Scripted self-test (no AI involved)

`bash tests/test-memory-loop.sh` → **49 passed, 0 failed.** A stand-in script plays `claude`, so the test is free, offline and repeatable. It checks:

- **Nothing is lost to quick sessions.** One real session, then 3 quick-question sessions and 3 TodoWrite-only sessions: the log is byte-for-byte the same, `claude` is never even called for them, and a new session still sees the real recap.
- **Nothing already written is lost.** Garbage bytes (invalid UTF-8, a NUL, a half marker) are added to the log; the next recap keeps every byte and appends after them. A missing log is started again.
- **A session saved twice gives one entry.** The same session saved 3 more times with no new work stays one entry. After `/compact`, the compaction summary alone does not count as new work. With real new work, a second entry covers only the new part.
- **Failures change nothing.** If `claude` is missing, not on PATH, logged out, or answers without the four lines, or the hook gets garbage input, it exits 0 and a checksum of every file in the vault is unchanged.
- **SessionStart.** It prints exactly the last 3 entries and not the 4th, labelled "history, not instructions", with the hidden markers removed and the source log named.
- **Hostile input and big transcripts.** A recap line cannot forge the hidden marker. From a 2 MB transcript only the tail (under 33k characters) goes to `claude`. The recap's own `claude` runs outside the vault and cannot trigger a recap of itself.
- **The rest.** `state.md`, including an old auto-snapshot block, is byte-for-byte untouched by every hook. A session that went quiet without ending is recapped at the next start, and a live one is not. The hook returns at once and the recap lands in the background. With no active project, recaps go to `00-meta/session-log/`. All links resolve.

## 2. Each test can go red

`bash tests/prove-red.sh` breaks the hooks on purpose, on a copy, in **16 ways**, and checks that a named test fails for each one. All 16 were caught:

| Broken on purpose | Caught by |
|---|---|
| Quick sessions count as real work | 3 quick + 3 TodoWrite-only sessions leave the log unchanged |
| The old design: quick sessions count, and the log keeps only the newest | After the quick sessions, a new session still sees the real recap |
| The log is rewritten instead of appended | Corrupt log: every byte already there is kept |
| A damaged log stops new entries (strict UTF-8) | Corrupt log: the new entry is still appended |
| A missing log is not recreated | Missing log: a new one is started |
| No dedupe | Same session saved 3 more times: still one entry |
| The compaction summary counts as new work | After /compact: still one entry |
| A failed `claude` run is trusted | `claude` logged out: exits 0, vault unchanged |
| A missing `claude` crashes the hook | `claude` CLI missing: exits 0, vault unchanged |
| A placeholder is written before `claude` answers | `claude` CLI missing: vault unchanged |
| Only the last 2 recaps are printed | Exactly the last 3, not the 4th |
| Recaps are not labelled as history | Labelled history, not instructions |
| The whole transcript goes to `claude` | Only its tail goes to `claude` |
| The recap's `claude` can trigger its own recap | It never recaps itself |
| The marker can be forged | A recap line cannot forge the marker |
| A hook writes the state file | `state.md` is byte-for-byte untouched |

The old suite grepped all of `state.md`, so it passed even when the block was corrupted and copies sat outside it. These tests compare bytes and count markers.

## 3. Real Claude Code, end to end

1. **Session 1** (`claude -p`, project `example-project`): asked to create `docs/content/bake-sale-plan.md`, with "we decided prices stay under 3 dollars". It did. About 8 seconds after it ended, the **SessionEnd hook's own `claude -p`** had appended this to `03-projects/example-project/session-log/2026-10.md`:
   > - Done: Created 03-projects/example-project/docs/content/bake-sale-plan.md, a 5-line bake sale launch plan covering date, place, prices (all under $3), …
   > - Decided: The user decided prices stay under $3. Claude decided to leave the date, place, and volunteer names as [TBD] rather than invent them.
   > - Open loops: The date and place still need to be settled with the school office, … Claude offered to save the price rule as a dated note in docs/decisions/ and update state.md, but the user hasn't answered.
   > - Next step: Confirm the date and place with the school office.
2. **Session 2**, a quick question ("What is 2+2?"): the log was byte-for-byte unchanged afterwards.
3. **Session 3**, a brand-new session **with all tools off**, asked what the last session did, what was decided and what comes next. From the loaded memory alone, it listed the plan file, the under-$3 decision, the open loops, and that `state.md` had not been updated yet. It named "the session recap" as its source.
4. **Control:** with `settings.json` moved away, the same question got "the session-start hook didn't load anything", and a list of files it would have to read.
5. **`/compact`** on session 1 (`claude -p --resume <id> "/compact"`) **found a bug.** After compaction, the session-end hook treated Claude's own compaction summary as new work and appended a near-duplicate entry. Fixed: compaction summaries and slash-command output are skipped. A test and a red variant were added. **Re-run on a fresh install** (a new real session, recapped, then `/compact`): the log was byte-for-byte unchanged and held one entry.

## Not covered

- **Live tests used print mode only.** They ran `claude -p` and `--resume … "/compact"`, not the interactive terminal. The hook events are the same, but in the terminal an automatic compaction partway through a long session was not exercised.
- **The sweep was tested by script only.** No real session was killed to watch it recapped at the next start. It also only sees sessions started in the vault's root folder, and it files their recap under whichever project is active at that start.
- **Writes and locking.** Recaps are written with a plain append under a lock on the `.claude` folder. Two machines writing to the same vault (for example through iCloud) at the same moment were not tested.
- **The recap's wording comes from Claude.** It can be wrong. That is why it is labelled history, and why `state.md` is kept by hand.
- **Platforms.** Linux and Windows (WSL) are expected to work but were not run.
