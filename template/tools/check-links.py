#!/usr/bin/env python3
"""Find dead relative Markdown links in the vault. Run from anywhere: python3 tools/check-links.py
Exit code 0 = all links resolve, 1 = at least one is dead. Ignores web links, mailto, #anchors,
code blocks, 00-meta/templates, and anything inside <angle-bracket placeholders> (templates)."""
import os, re, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
SKIP_DIRS = {".git", "node_modules", ".obsidian"}
bad = 0; checked = 0
for dp, dn, fn in os.walk(ROOT):
    dn[:] = [d for d in dn if d not in SKIP_DIRS]
    for f in fn:
        if not f.endswith(".md"): continue
        p = os.path.join(dp, f)
        if os.path.relpath(p, ROOT).startswith(os.path.join("00-meta", "templates")): continue  # templates hold placeholder links
        text = re.sub(r"```.*?```", "", open(p, encoding="utf-8", errors="replace").read(), flags=re.S)
        text = re.sub(r"`[^`\n]*`", "", text)
        for m in LINK.finditer(text):
            t = m.group(1)
            if re.match(r"^(https?:|mailto:|#)", t) or "<" in t or ">" in t: continue
            t = t.split("#")[0]
            if not t: continue
            checked += 1
            if not os.path.exists(os.path.normpath(os.path.join(dp, t))):
                bad += 1; print(f"DEAD  {os.path.relpath(p, ROOT)} -> {m.group(1)}")
print(f"{checked} links checked, {bad} dead")
sys.exit(1 if bad else 0)
