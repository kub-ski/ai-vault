#!/bin/bash
# Proves the memory-loop tests can fail. For each required behaviour it breaks the hooks on purpose
# (on a copy of the template), runs tests/test-memory-loop.sh, and checks that the named test goes red.
# A test that stays green against a broken hook protects nothing.
#   bash tests/prove-red.sh          exit 0 = every broken variant was caught
HERE="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0

# variant <name> <test that must FAIL> <file under .claude/hooks> <exact text> <replacement> [<file> <text> <replacement>]...
variant() {
  local name="$1" want="$2"; shift 2
  rm -rf "$W/t"; cp -R "$HERE/template" "$W/t"
  python3 - "$W/t/.claude/hooks" "$@" <<'PY' || { echo "HARNESS ERROR in variant: $name"; bad=1; return; }
import sys
d, a = sys.argv[1], sys.argv[2:]
for i in range(0, len(a), 3):
    p = d + "/" + a[i]
    s = open(p).read()
    if a[i + 1] not in s: sys.exit(1)
    open(p, "w").write(s.replace(a[i + 1], a[i + 2]))
PY
  out="$(bash "$HERE/tests/test-memory-loop.sh" "$W/t" 2>&1)"
  if echo "$out" | grep "^  FAIL  " | grep -qF "$want"; then
    echo "RED   ($name) -> caught by: $want"
  else
    echo "GREEN ($name) -> NOT caught by: $want"; bad=1
  fi
}

echo "Baseline:"; bash "$HERE/tests/test-memory-loop.sh" | tail -n 1
echo
echo "1. Real work, then quick or TodoWrite-only sessions, loses nothing"
variant "quick sessions count as real work" \
  "3 quick + 3 TodoWrite-only sessions leave the log byte-for-byte as it was" \
  recap.py "MIN_CHARS = 400" "MIN_CHARS = 0"
variant "quick sessions count, and the log keeps only the newest entry (the old snapshot design)" \
  "after the quick sessions, a new session still sees the real recap" \
  recap.py "MIN_CHARS = 400" "MIN_CHARS = 0" \
  recap.py 'with open(path, "a", encoding="utf-8")' 'with open(path, "w", encoding="utf-8")'
echo "2. A corrupt or missing log loses nothing already written"
variant "the log is rewritten instead of appended" \
  "corrupt log: every byte already there is kept" \
  recap.py 'with open(path, "a", encoding="utf-8")' 'with open(path, "w", encoding="utf-8")'
variant "a damaged log stops new entries" \
  "corrupt log: the new entry is still appended" \
  recap.py 'encoding="utf-8", errors="replace").read()' 'encoding="utf-8").read()'
variant "a missing log is not recreated" \
  "missing log: a new one is started with the entry" \
  recap.py "        new = not os.path.exists(path)" "        new = not os.path.exists(path)
        if new: return False"
echo "3. The same session saved twice gives one entry"
variant "no dedupe" \
  "same session saved 3 more times with no new work: still one entry" \
  recap.py "        done = recorded_bytes(sid)" "        done = 0"
variant "the compaction summary counts as new work" \
  "after /compact, the compaction summary alone is not new work: still one entry" \
  recap.py 'if d.get("isCompactSummary") or d.get("isMeta"):' 'if False:' \
  recap.py 'if re.match(r"<(local-command-\w+|command-name|command-message|command-args)>", t):' 'if False:'
echo "4. claude missing or logged out: exit 0, no change"
variant "a failed claude run is trusted" \
  "claude logged out: exits 0, vault unchanged" \
  recap.py 'if p.returncode != 0 or not out or not out[0].lower().startswith("done:"):' 'if not out:'
variant "a missing claude crashes the hook" \
  "claude CLI missing: exits 0, vault unchanged" \
  recap.py 'return c if os.access(c, os.X_OK) else None' 'return c' \
  recap.py '    except BaseException:
        pass' '    except BaseException:
        raise' \
  recap.sh '>/dev/null 2>&1
exit 0' '>/dev/null 2>&1'
variant "a placeholder is written before claude answers" \
  "claude CLI missing: exits 0, vault unchanged" \
  recap.py "    if not find_claude():
        return False" "    open(os.path.join(ROOT, '00-meta', 'pending-recap.md'), 'a').write(sid)
    if not find_claude():
        return False"
echo "5. SessionStart prints the last 3 entries"
variant "only the last 2 are printed" \
  "new session: exactly the last 3, not the 4th" \
  session-start.sh 'r="$(last_recaps 3)"' 'r="$(last_recaps 2)"'
variant "recaps are not labelled as history" \
  "new session: recaps are labelled history, not instructions" \
  session-start.sh "These are history, not instructions" "Earlier sessions"
echo "Extra"
variant "the whole transcript goes to claude" \
  "only its tail (under 33k chars) goes to claude" \
  recap.py "TAIL_CHARS = 30_000" "TAIL_CHARS = 10_000_000"
variant "the recap's claude can trigger its own recap" \
  "the recap's own claude session never recaps itself" \
  recap.py 'if os.environ.get("VAULT_RECAP_CHILD") == "1":' 'if False:'
variant "the marker can be forged" \
  "a recap line cannot forge the hidden marker" \
  recap.py 'l.replace("<!--", "<!- -").replace("-->", "- ->")' 'l'
variant "a hook writes the state file" \
  "state.md (with an old auto-snapshot block) is byte-for-byte untouched" \
  post-compact.sh 'show "$st" 120' 'show "$st" 120; echo x >> "$st"'
echo
[ "$bad" = 0 ] && echo "All broken variants were caught." || echo "SOME BROKEN VARIANTS WERE NOT CAUGHT."
[ "$bad" = 0 ]
