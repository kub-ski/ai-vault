#!/bin/bash
# Self-test for the memory loop. Works on a COPY of the vault, so your files are never touched.
#   bash tests/test-memory-loop.sh [path-to-vault]     (default: ./template)
# Steps: fake a session -> save-state (as PreCompact would) -> session-start and post-compact
# in a "new session" -> check the saved facts come back. Exit 0 = all pass.
HERE="$(cd "$(dirname "$0")/.." && pwd)"
VAULT="${1:-$HERE/template}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cp -R "$VAULT/." "$W/v"; V="$W/v"
pass=0; fail=0
ok() { if [ "$1" = 0 ]; then pass=$((pass+1)); echo "  PASS  $2"; else fail=$((fail+1)); echo "  FAIL  $2"; fi; }

python3 -c "import json,sys; json.load(open('$V/.claude/settings.json'))"; ok $? "settings.json is valid JSON"
for h in session-start post-compact save-state lib; do bash -n "$V/.claude/hooks/$h.sh"; ok $? "$h.sh parses"; done

# a pretend project and a pretend finished session transcript
mkdir -p "$V/03-projects/demo/docs/decisions"
echo "# Demo: project instructions" > "$V/03-projects/demo/CLAUDE.md"
echo "# Decision: pick blue" > "$V/03-projects/demo/docs/decisions/2026-02-01-pick-blue.md"
echo "# Decision: pick green" > "$V/03-projects/demo/docs/decisions/2026-03-01-pick-green.md"
echo demo > "$V/.claude/active-project"
T="$W/t.jsonl"
cat > "$T" <<'J'
{"type":"user","message":{"role":"user","content":"Please add the pricing table to the demo page"}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Adding it now."},{"type":"tool_use","name":"Write","input":{"file_path":"VAULTDIR/03-projects/demo/docs/content/pricing.md","content":"x"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"ok"}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Pricing table is in pricing.md. Next: review the numbers with the user."}]}}
J
perl -pi -e "s#VAULTDIR#$V#g" "$T"
echo "{\"session_id\":\"s1\",\"transcript_path\":\"$T\",\"hook_event_name\":\"PreCompact\"}" | bash "$V/.claude/hooks/save-state.sh" precompact
S="$V/03-projects/demo/state.md"
grep -q "add the pricing table" "$S";            ok $? "snapshot saved the user's request"
grep -q "03-projects/demo/docs/content/pricing.md" "$S"; ok $? "snapshot saved the changed file (path relative to vault)"
grep -q "Next: review the numbers" "$S";         ok $? "snapshot saved Claude's last message"
echo "{\"session_id\":\"s1\",\"transcript_path\":\"$T\"}" | bash "$V/.claude/hooks/save-state.sh" sessionend
[ "$(grep -c 'auto-snapshot:start' "$S")" = 1 ]; ok $? "second save replaces the block, does not duplicate it"
perl -pi -e 's/^- \(none\)$/- hand-written note survives/ if /^- \(none\)$/ && !$d++' "$S"
grep -q "hand-written note survives" "$S" && echo '{"transcript_path":""}' | bash "$V/.claude/hooks/save-state.sh" sessionend && grep -q "hand-written note survives" "$S"; ok $? "your own notes are never overwritten"

# new session
O="$(echo '{"source":"startup"}' | bash "$V/.claude/hooks/session-start.sh")"
echo "$O" | grep -q "Active project: demo";           ok $? "new session: active project announced"
echo "$O" | grep -q "pick green";                     ok $? "new session: NEWEST decision loaded"
echo "$O" | grep -q "pick blue" && r=1 || r=0;        ok $r "new session: older decision not loaded"
echo "$O" | grep -q "add the pricing table";          ok $? "new session: saved state loaded"
echo "$O" | grep -q "not filled in yet";              ok $? "new session: blank identity is flagged"
C="$(echo '{"source":"compact"}' | bash "$V/.claude/hooks/post-compact.sh")"
echo "$C" | grep -q "Next: review the numbers";       ok $? "after compaction: state restored"

# empty / broken input must not break anything
echo 'not json' | bash "$V/.claude/hooks/save-state.sh" precompact; ok $? "garbage input: hook exits 0"
rm -f "$V/.claude/active-project"
O2="$(echo '{}' | bash "$V/.claude/hooks/session-start.sh")"; echo "$O2" | grep -q "No active project"; ok $? "no active project: handled"
python3 "$V/tools/check-links.py" >/dev/null; ok $? "all links in the vault resolve"
echo "$pass passed, $fail failed"; [ "$fail" = 0 ]
