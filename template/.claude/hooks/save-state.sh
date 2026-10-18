#!/bin/bash
# PreCompact (just before compaction) and SessionEnd (when you close a session):
# save a snapshot of this session into the state file, between two marker comments.
# A hook cannot ask Claude to write; it can read the session transcript, so this script
# pulls out what you asked for, which files changed, and Claude's last message.
# Your own notes in state.md (Done / Next / Open questions) are never touched.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh" 2>/dev/null || exit 0
MODE="${1:-snapshot}"
STATE="$(state_file)"
IN="$(cat 2>/dev/null)"
mkdir -p "$(dirname "$STATE")" 2>/dev/null
[ -f "$STATE" ] || cp "$ROOT/00-meta/templates/state.md" "$STATE" 2>/dev/null

printf '%s' "$IN" | MODE="$MODE" STATE="$STATE" /usr/bin/env python3 -I -c '
import json, os, sys, datetime, tempfile
START, END = "<!-- auto-snapshot:start -->", "<!-- auto-snapshot:end -->"
try:
    hook = json.load(sys.stdin)
except Exception:
    hook = {}
tp = hook.get("transcript_path") or ""
asks, files, last = [], [], ""
try:
    for line in open(tp, encoding="utf-8"):
        try: e = json.loads(line)
        except Exception: continue
        m = e.get("message") or {}
        c = m.get("content")
        if e.get("type") == "user":
            parts = [c] if isinstance(c, str) else [p.get("text", "") for p in (c or []) if isinstance(p, dict) and p.get("type") == "text"]
            for t in parts:
                t = (t or "").strip()
                if t and not t.startswith("<"): asks.append(" ".join(t.split())[:300])
        elif e.get("type") == "assistant" and isinstance(c, list):
            for p in c:
                if not isinstance(p, dict): continue
                if p.get("type") == "tool_use" and p.get("name") in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
                    f = (p.get("input") or {}).get("file_path") or (p.get("input") or {}).get("notebook_path")
                    if f: files.append(f)
                elif p.get("type") == "text" and p.get("text", "").strip():
                    last = " ".join(p["text"].split())[:600]
except Exception:
    pass
if not (asks or files or last):
    sys.exit(0)   # nothing readable (no transcript): keep the earlier snapshot instead of blanking it
root = os.path.abspath(os.path.join(os.path.dirname(os.environ["STATE"]), "..", ".."))
seen, uniq = set(), []
for f in reversed(files):
    if f not in seen: seen.add(f); uniq.append(f)
uniq = [os.path.relpath(f, root) if f.startswith(root) else f for f in uniq[:15]]
now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
out = [START, "## Auto-snapshot (written by a hook, " + now + ", " + os.environ["MODE"] + ")", ""]
out.append("**Recent requests:**")
out += ["- " + a for a in asks[-5:]] or ["- (none found)"]
out += ["", "**Files changed this session:**"]
out += ["- " + f for f in uniq] or ["- (none)"]
out += ["", "**Claude last said:** " + (last or "(nothing)"), END]
block = "\n".join(out)
p = os.environ["STATE"]
try: s = open(p, encoding="utf-8").read()
except Exception: s = ""
if START in s and END in s:
    a = s.index(START); b = s.index(END) + len(END)
    s = s[:a] + block + s[b:]
else:
    s = s.rstrip("\n") + "\n\n" + block + "\n"
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p)); os.write(fd, s.encode("utf-8")); os.close(fd)
os.replace(tmp, p)
' 2>/dev/null
exit 0
