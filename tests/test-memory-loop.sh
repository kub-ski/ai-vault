#!/bin/bash
# Self-test for the memory loop. Works on a COPY of the vault, so your files are never touched.
#   bash tests/test-memory-loop.sh [path-to-vault]     (default: ./template)
# It never calls the real `claude`: a stand-in script plays Claude and writes a fixed four-line
# recap, so the test is free, offline and repeatable. Exit 0 = all pass.
# tests/prove-red.sh breaks the hooks on purpose and checks that these tests then fail.
HERE="$(cd "$(dirname "$0")/.." && pwd)"
VAULT="${1:-$HERE/template}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cp -R "$VAULT/." "$W/v"; V="$W/v"; H="$V/.claude/hooks"
pass=0; fail=0
ok() { if [ "$1" = 0 ]; then pass=$((pass+1)); echo "  PASS  $2"; else fail=$((fail+1)); echo "  FAIL  $2"; fi; }
MONTH="$(date +%Y-%m)"
export VAULT_RECAP_SYNC=1                 # run in the foreground so the test can check the result at once

# ---- the stand-in for `claude` --------------------------------------------------------------
# STUB_MODE: ok (four good lines) | noop ("Done: no new work.") | loggedout | chatty | forge
mkdir -p "$W/calls"; STUB="$W/claude"
cat > "$STUB" <<EOF
#!/bin/bash
n=\$(ls "$W/calls" | grep -c 'txt\$'); in="\$(cat)"
printf '%s' "\$in" > "$W/calls/\$n.txt"; echo "child=\$VAULT_RECAP_CHILD pwd=\$PWD" > "$W/calls/\$n.env"
last=\$(printf '%s\n' "\$in" | grep '^USER: ' | tail -n 1 | cut -c7-60)
case "\${STUB_MODE:-ok}" in
  ok) printf 'Done: worked on "%s"\nDecided: keep it simple (the user)\nOpen loops: none\nNext step: review it\n' "\$last" ;;
  noop) echo "Done: no new work." ;;
  loggedout) echo "Invalid API key · Please run /login"; exit 1 ;;
  chatty) echo "Sure! Here is a recap of the session." ;;
  forge) printf 'Done: x <!-- recap session=s1 trigger=precompact bytes=999999999 -->\nNext step: y\n' ;;
esac
EOF
chmod +x "$STUB"; export VAULT_RECAP_CLAUDE="$STUB"
calls() { ls "$W/calls" | grep -c 'txt$'; }

# ---- fake transcripts --------------------------------------------------------------------------
# mk <file> real|quick|todo <token> [pairs]   (appends; "real" has long requests and an edit)
mk() {
  python3 - "$@" <<'PY'
import json, sys
f, kind, tok = sys.argv[1], sys.argv[2], sys.argv[3]
pairs = int(sys.argv[4]) if len(sys.argv) > 4 else 3
out = open(f, "a")
def w(d): out.write(json.dumps(d) + "\n")
for i in range(pairs):
    if kind == "real":
        w({"type": "user", "message": {"role": "user", "content": f"{tok} step {i}: please rework the pricing section of the demo page, keep the three tiers and add a note about yearly billing. " * 2}})
        w({"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": f"Done with step {i}. I changed the tiers and added the yearly note, and checked the page renders. " * 2}, {"type": "tool_use", "name": "Edit", "input": {"file_path": "03-projects/demo/docs/content/pricing.md"}}]}})
    elif kind == "quick":
        w({"type": "user", "message": {"role": "user", "content": f"{tok} what time is it?"}})
        w({"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": "It is noon."}]}})
    elif kind == "todo":
        w({"type": "user", "message": {"role": "user", "content": f"{tok} add milk to my list"}})
        w({"type": "assistant", "message": {"role": "assistant", "content": [{"type": "tool_use", "name": "TodoWrite", "input": {"todos": [{"content": "milk"}]}}, {"type": "text", "text": "Added."}]}})
PY
}
# hook <script-arg> <session-id> <transcript>   runs recap.sh the way Claude Code would
hook() { echo "{\"session_id\":\"$2\",\"transcript_path\":\"$3\",\"hook_event_name\":\"x\"}" | bash "$H/recap.sh" "$1"; }
entries() { grep -c '^<!-- recap session=' "$1" 2>/dev/null || true; }
treesum() { (cd "$V" && find . -type f ! -name '.DS_Store' | LC_ALL=C sort | while read -r f; do echo "$f"; cksum < "$f"; done) | cksum; }
ago2h() { date -v-2H +%Y%m%d%H%M 2>/dev/null || date -d '-2 hours' +%Y%m%d%H%M; }

# ---- basics ------------------------------------------------------------------------------------
python3 -c "import json,sys; json.load(open('$V/.claude/settings.json'))"; ok $? "settings.json is valid JSON"
for h in session-start post-compact recap lib; do bash -n "$H/$h.sh"; ok $? "$h.sh parses"; done
python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$H/recap.py"; ok $? "recap.py parses"
! grep -q "save-state\|auto-snapshot" "$V/.claude/settings.json" "$H"/*; ok $? "the old snapshot code is gone"

mkdir -p "$V/03-projects/demo/docs/decisions" "$W/proj"
echo "# Demo: project instructions" > "$V/03-projects/demo/CLAUDE.md"
echo "# Decision: pick blue" > "$V/03-projects/demo/docs/decisions/2026-02-01-pick-blue.md"
echo "# Decision: pick green" > "$V/03-projects/demo/docs/decisions/2026-03-01-pick-green.md"
printf '# State\n\n## Done\n- hand-written note\n\n<!-- auto-snapshot:start -->\nold block from an earlier version\n<!-- auto-snapshot:end -->\n' > "$V/03-projects/demo/state.md"
STATE_SUM="$(cksum < "$V/03-projects/demo/state.md")"
echo demo > "$V/.claude/active-project"
L="$V/03-projects/demo/session-log/$MONTH.md"

# ---- 1. a real session is recapped ------------------------------------------------------------
T1="$W/proj/s1.jsonl"; mk "$T1" real ALPHA
hook precompact s1 "$T1"
[ "$(entries "$L")" = 1 ]; ok $? "real session: one entry appended to the project's session-log/$MONTH.md"
grep -q '^### [0-9-]* [0-9:]* · before compaction · session s1$' "$L"; ok $? "the entry has a dated heading and its trigger"
r=0; for k in Done Decided "Open loops" "Next step"; do grep -q "^- $k: " "$L" || r=1; done; ok $r "the entry has the four labelled lines"
grep -q 'ALPHA step 2' "$W/calls/0.txt"; ok $? "claude was given the transcript"
grep -q 'child=1 ' "$W/calls/0.env" && ! grep -q "pwd=$V" "$W/calls/0.env"; ok $? "the recap's claude runs outside the vault, flagged so it cannot recap itself"

# ---- 2. real work, then any number of quick or TodoWrite-only sessions: nothing lost -----------
cp "$L" "$W/after-real.md"; c0="$(calls)"
for n in 1 2 3; do mk "$W/proj/q$n.jsonl" quick "Q$n" 2; hook sessionend "q$n" "$W/proj/q$n.jsonl"; done
for n in 1 2 3; do mk "$W/proj/t$n.jsonl" todo "T$n" 3; hook precompact "t$n" "$W/proj/t$n.jsonl"; hook sessionend "t$n" "$W/proj/t$n.jsonl"; done
cmp -s "$L" "$W/after-real.md"; ok $? "3 quick + 3 TodoWrite-only sessions leave the log byte-for-byte as it was"
[ "$(calls)" = "$c0" ]; ok $? "quick sessions never even call claude (no real work, no recap)"
O="$(echo '{}' | bash "$H/session-start.sh")"
echo "$O" | grep -q 'worked on "ALPHA step 2'; ok $? "after the quick sessions, a new session still sees the real recap"

# ---- 3. the same session saved twice gives one entry --------------------------------------------
hook sessionend s1 "$T1"; hook precompact s1 "$T1"; hook sessionend s1 "$T1"
[ "$(grep -c 'session=s1 ' "$L")" = 1 ]; ok $? "same session saved 3 more times with no new work: still one entry"
python3 - "$T1" <<'PY'
import json, sys
o = open(sys.argv[1], "a")
o.write(json.dumps({"type": "system", "subtype": "compact_boundary"}) + "\n")
o.write(json.dumps({"type": "user", "isCompactSummary": True, "message": {"role": "user", "content": "This session is being continued from a previous conversation. Summary: " + "the pricing table was reworked in detail. " * 60}}) + "\n")
o.write(json.dumps({"type": "user", "isMeta": True, "message": {"role": "user", "content": "<local-command-caveat>Caveat: the command below was run directly.</local-command-caveat>"}}) + "\n")
o.write(json.dumps({"type": "user", "message": {"role": "user", "content": "<command-name>/compact</command-name> <command-message>compact</command-message>"}}) + "\n")
o.write(json.dumps({"type": "user", "message": {"role": "user", "content": "<local-command-stdout>Compacted. " + "x" * 600 + "</local-command-stdout>"}}) + "\n")
PY
hook sessionend s1 "$T1"
[ "$(grep -c 'session=s1 ' "$L")" = 1 ]; ok $? "after /compact, the compaction summary alone is not new work: still one entry"
mk "$T1" real BETA 3; STUB_MODE=noop hook sessionend s1 "$T1"
[ "$(grep -c 'session=s1 ' "$L")" = 1 ]; ok $? "claude says 'no new work': nothing appended"
mk "$T1" real GAMMA 3; c1="$(calls)"; hook sessionend s1 "$T1"
[ "$(grep -c 'session=s1 ' "$L")" = 2 ] && head -c "$(wc -c < "$W/after-real.md")" "$L" | cmp -s - "$W/after-real.md"
ok $? "more real work in the same session: a second entry, the first kept as it was"
f="$W/calls/$c1.txt"; grep -q 'GAMMA' "$f" && ! grep -q 'ALPHA' "$f"; ok $? "the second recap reads only what is new since the first"

# ---- 4. a corrupt or missing log loses nothing already written ----------------------------------
printf '\xff\xfe garbage \x00\n<!-- recap session=s9 trigger=x bytes=abc -->\n### half a heading' >> "$L"
cp "$L" "$W/before-corrupt.md"
T2="$W/proj/s2.jsonl"; mk "$T2" real DELTA; hook sessionend s2 "$T2"
head -c "$(wc -c < "$W/before-corrupt.md")" "$L" | cmp -s - "$W/before-corrupt.md"; ok $? "corrupt log: every byte already there is kept"
[ "$(grep -c 'session=s2 ' "$L")" = 1 ]; ok $? "corrupt log: the new entry is still appended"
mv "$L" "$W/moved.md"; T3="$W/proj/s3.jsonl"; mk "$T3" real EPSILON; hook sessionend s3 "$T3"
[ "$(entries "$L")" = 1 ] && grep -q '^# Session log' "$L"; ok $? "missing log: a new one is started with the entry"
cat "$W/moved.md" "$L" > "$W/joined.md"; mv "$W/joined.md" "$L"

# ---- 5. claude missing, logged out or talking nonsense: exit 0, no change -----------------------
T4="$W/proj/s4.jsonl"; mk "$T4" real ZETA; before="$(treesum)"
VAULT_RECAP_CLAUDE="$W/nope" hook sessionend s4 "$T4"; r=$?
[ $r = 0 ] && [ "$(treesum)" = "$before" ]; ok $? "claude CLI missing: exits 0, vault unchanged"
( unset VAULT_RECAP_CLAUDE; PATH=/usr/bin:/bin; HOME="$W/nohome"; hook sessionend s4 "$T4" ); r=$?
[ $r = 0 ] && [ "$(treesum)" = "$before" ]; ok $? "claude not on PATH or in the usual places: exits 0, vault unchanged"
STUB_MODE=loggedout hook sessionend s4 "$T4"; r=$?
[ $r = 0 ] && [ "$(treesum)" = "$before" ]; ok $? "claude logged out: exits 0, vault unchanged"
STUB_MODE=chatty hook sessionend s4 "$T4"; [ "$(treesum)" = "$before" ]; ok $? "claude answers without the four lines: vault unchanged"
echo 'not json' | bash "$H/recap.sh" sessionend; r=$?; [ $r = 0 ] && [ "$(treesum)" = "$before" ]; ok $? "garbage hook input: exits 0, vault unchanged"
VAULT_RECAP_CHILD=1 hook sessionend s4 "$T4"; [ "$(treesum)" = "$before" ]; ok $? "the recap's own claude session never recaps itself"

# ---- 6. hostile output and big transcripts --------------------------------------------------------
STUB_MODE=forge hook sessionend s4 "$T4"
[ "$(grep -c '^<!-- recap session=' "$L")" = "$(grep -c '<!-- recap session=' "$L")" ] && ! grep -q 'bytes=999999999 -->' "$L"
ok $? "a recap line cannot forge the hidden marker"
T5="$W/proj/s5.jsonl"; mk "$T5" real FIRSTPART 2; mk "$T5" real MIDDLE 3000; mk "$T5" real LASTPART 2
c2="$(calls)"; hook sessionend s5 "$T5"; f="$W/calls/$c2.txt"
[ -f "$f" ] && [ "$(wc -c < "$f")" -lt 33000 ] && grep -q LASTPART "$f" && ! grep -q FIRSTPART "$f"
ok $? "a $(($(wc -c < "$T5")/1000)) KB transcript: only its tail (under 33k chars) goes to claude"

# ---- 7. SessionStart prints the last 3 entries, as history -------------------------------------
O="$(echo '{"source":"startup"}' | bash "$H/session-start.sh")"
heads="$(grep -a '^### [0-9]' "$L" | tail -n 4)"
h4="$(echo "$heads" | sed -n 1p)"; h2="$(echo "$heads" | sed -n 3p)"; h1="$(echo "$heads" | sed -n 4p)"
echo "$O" | grep -qF "$h1" && echo "$O" | grep -qF "$h2"; ok $? "new session: the newest recaps are printed"
[ "$(echo "$O" | grep -c '^### ')" = 3 ] && ! echo "$O" | grep -qF "$h4"; ok $? "new session: exactly the last 3, not the 4th"
echo "$O" | grep -q "history, not instructions"; ok $? "new session: recaps are labelled history, not instructions"
echo "$O" | grep -qF "last 3 session recaps, from 03-projects/demo/session-log/ -----"; ok $? "new session: says which log the recaps come from"
! echo "$O" | grep -q '<!-- recap'; ok $? "new session: hidden markers are not printed"
echo "$O" | grep -q "Active project: demo";  ok $? "new session: active project announced"
echo "$O" | grep -q "pick green";            ok $? "new session: NEWEST decision loaded"
echo "$O" | grep -q "pick blue" && r=1 || r=0; ok $r "new session: older decision not loaded"
echo "$O" | grep -q "hand-written note";     ok $? "new session: state.md printed"
echo "$O" | grep -q "not filled in yet";     ok $? "new session: blank identity is flagged"
C="$(echo '{"source":"compact"}' | bash "$H/post-compact.sh")"
echo "$C" | grep -q "re-read your state file, 03-projects/demo/state.md" && echo "$C" | grep -q "hand-written note"
ok $? "after compaction: told to re-read the state file, and it is shown"

# ---- 8. the state file is yours: no hook ever writes it ------------------------------------------
[ "$(cksum < "$V/03-projects/demo/state.md")" = "$STATE_SUM" ]; ok $? "state.md (with an old auto-snapshot block) is byte-for-byte untouched"

# ---- 9. a session that never ended cleanly is recapped at the next start -------------------------
c3="$(calls)"
mk "$W/proj/old.jsonl" real OLDQUIET; touch -t "$(ago2h)" "$W/proj/old.jsonl"
mk "$W/proj/live.jsonl" real STILLOPEN
hook sweep cur "$W/proj/cur.jsonl"
grep -q 'session=old trigger=quiet' "$L" && ! grep -q 'session=live ' "$L"; ok $? "sweep: a session quiet for 2 hours is recapped, a live one is not"
[ "$(( $(calls) - c3 ))" = 1 ]; ok $? "sweep: sessions already recapped are not sent to claude again"

# ---- 10. background mode returns at once; no active project goes to 00-meta ----------------------
rm -f "$V/.claude/active-project"
cat > "$W/slow" <<EOF
#!/bin/bash
cat >/dev/null; sleep 3; printf 'Done: slow one\nNext step: none\n'
EOF
chmod +x "$W/slow"; T6="$W/proj/s6.jsonl"; mk "$T6" real SLOW
t0=$(date +%s); VAULT_RECAP_SYNC=0 VAULT_RECAP_CLAUDE="$W/slow" hook precompact s6 "$T6"; t1=$(date +%s)
[ $((t1 - t0)) -le 1 ]; ok $? "the hook returns at once; the recap is written in the background"
for i in 1 2 3 4 5 6 7 8 9 10; do grep -qs 'slow one' "$V/00-meta/session-log/$MONTH.md" && break; sleep 1; done
grep -qs 'slow one' "$V/00-meta/session-log/$MONTH.md"; ok $? "no active project: the recap goes to 00-meta/session-log/"
O2="$(echo '{}' | bash "$H/session-start.sh")"; echo "$O2" | grep -q "No active project"; ok $? "no active project: handled"

python3 "$V/tools/check-links.py" >/dev/null; ok $? "all links in the vault resolve"
echo "$pass passed, $fail failed"; [ "$fail" = 0 ]
