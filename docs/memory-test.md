# Memory-loop test: evidence

Run on 2026-10-18 with Claude Code on a fresh copy of the template (made by `scripts/install.sh`). Nothing was edited by hand between steps.

## 1. Scripted self-test (no AI involved)

`bash tests/test-memory-loop.sh` → **25 passed, 0 failed** (19 at first run; 6 added after two review rounds). It fakes a finished session, runs the save hook the way PreCompact would, then runs the start hooks as a "new session" and checks the facts come back (request, changed file, last message, newest decision only, restored state after compaction, user notes never overwritten, garbage input harmless, links resolve). Building this check into the repo was the point: it caught one real bug while I wrote it (a SessionEnd with an unreadable transcript blanked a good snapshot; fixed).

## 2. Real Claude Code, end to end

1. Fresh vault, project set: `example-project` in `.claude/active-project`.
2. **Session 1** (`claude -p`): asked to create `03-projects/example-project/docs/content/launch-plan.md`. It did. When the session ended, the **SessionEnd hook** wrote this into `03-projects/example-project/state.md` on its own:
   - Recent requests: "Create the file 03-projects/example-project/docs/content/launch-plan.md containing a 3-line launch plan for a bake sale..."
   - Files changed: `03-projects/example-project/docs/content/launch-plan.md`
   - Claude last said: "I created `...launch-plan.md` with a 3-line bake sale plan..."
3. **/compact** (`claude -p --resume <id> "/compact"`) with two temporary probe commands added to the hooks: both **PreCompact** and the **SessionStart (compact)** hook fired (probe log: `precompact-fired`, `compact-sessionstart-fired`). The probes were removed afterwards.
4. **Session 2, a brand-new session, all file tools blocked**, asked: which project is active, which file changed last session, is identity filled in? Answer, from the loaded memory alone:
   > Active project: example-project
   > Last session changed: `03-projects/example-project/docs/content/launch-plan.md`
   > Identity: not filled in yet; `identity.md` is still the blank template.
5. **Control (settings.json moved away, same question):** "I can't tell... the session-start hook seems not to have run." So the answer in step 4 came from the hooks, not from a lucky guess.

## Not covered

- The restored text after compaction was verified by the script and by the probe (hook fired), not by asking a live compacted conversation what it remembered. A second `/compact` on a short session returned `compact_error` (too little to compact), so a long real session was not exercised.
- Tested on macOS with the stock `/usr/bin/python3` and `bash` 3.2. Linux and Windows (WSL) are expected to work but were not run.
- `claude -p` (print mode) was used, not the interactive terminal UI. The hook events are the same.

## 3. Re-run after review (2026-10-18)

An independent review found that a short question-only session replaced the snapshot of a real working session, that marker text in a request could corrupt `state.md`, and that stored text was not labelled as history. All three are fixed and now have checks (22 in total). Live re-run on a fresh install: session 1 created a file; session 2 ("What is 2+2?") ran and **did not** replace the snapshot; session 3, file tools blocked, answered "The last session changed `03-projects/example-project/docs/content/menu.md`, according to the auto-snapshot in `state.md`."

## 4. Round 2: the case that still wiped the snapshot

A real session (a request and an edit) followed by two no-edit sessions with two questions each still replaced the real snapshot. Fix: only a session that changed something (a Write, Edit or TodoWrite) counts as real; the last three real ones are kept; no-edit sessions become one-line "quick sessions". History is a small JSON file next to `state.md`, and a session saved twice (before compaction and at its end) is one entry.
Red/green proof: the new check reproduces the case exactly. Against the previous hook (c6efedd) it fails; with the fix disabled by one line (`"real": True`) it fails (3 checks red); with the fix it passes (25/25).
