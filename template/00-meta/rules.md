# Working rules

The rules behind the short list in `CLAUDE.md`. Each one exists because of a specific kind of failure.

## The three kinds

- **LAW**: safety, legal, privacy, no secrets. Permanent. Never softened into "use judgment".
- **METHOD**: how you know something is true. Verify, check negatives, decide in writing. Cheap to keep, never narrows what you can make.
- **CRAFT**: what output looks like (tone, layout, formats). Provisional. Test: *does the rule tell you what to make, or how to know?* A craft rule with no named failure behind it is a preference: delete it. A craft rule nobody has challenged in 90 days gets argued against.

## The generic rules

1. **Verify before claiming done (METHOD).** Failure: "it works" said about something nobody looked at. Open the file, run the command, view the render.
2. **Looking is not verifying (METHOD).** Failure: a defect the eye cannot tell from a choice. Ask the machine: how many pages, which font, what the link points to, what the QR code decodes to. Build that check into the script that makes the thing, not into one chat.
3. **Check negatives (METHOD).** Failure: "not installed" or "no results" believed without trying. Make one direct call before writing any *absent, unavailable, broken, unchanged*. A check that cannot tell "no effect" from "broken instrument" returns *unknown*, not *no*.
4. **First suspect the fix (METHOD).** Failure: five changes on five theories after the first fix caused the problem. When a fix does not work, undo it and measure with and without before adding a second change.
5. **Decision doc first (METHOD).** Failure: reverse-engineering a choice from file names six months later. Write the dated note before the structural change. Skip it only for typos and renames with no consequences.
6. **State the contract before a big build (METHOD).** Failure: shipping the wrong thing correctly. Echo a numbered list with a checkable result per item and get a yes.
7. **No secrets in files (LAW).** Failure: a key in a synced folder is effectively published.
8. **Raw sources are never edited (LAW).** Failure: losing the original.
9. **Links survive moves (METHOD).** Failure: dozens of silently dead links after a reorganisation. `python3 tools/check-links.py` finds them.
10. **A rules file states the rule that is live, once.** History and reversals belong in a decision doc, not struck through in the rules.

Add your own rules at the bottom, each with its kind and the failure that produced it.

## Related
- [CLAUDE.md](../CLAUDE.md) · [Naming](naming-conventions.md) · [Decision template](templates/decision.md)
