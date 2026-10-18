#!/bin/bash
# PreCompact, SessionEnd and SessionStart call this to write a session recap (see recap.py).
#   recap.sh precompact | sessionend | sweep
# It hands the hook's JSON to recap.py, which moves to the background at once, so compaction,
# closing the window and starting a session are never held up. Fails open: always exits 0.
python3 -I "$(dirname "${BASH_SOURCE[0]}")/recap.py" "${1:-}" >/dev/null 2>&1
exit 0
