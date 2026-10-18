---
description: Create a project folder from the template (CLAUDE.md, index, state, docs folders) and add it to the index.
argument-hint: <project-slug> [one-line goal]
---

Create a project. `$ARGUMENTS` starts with the slug (lowercase, hyphens), optionally followed by a goal. If it is missing, ask for the slug and a one-line goal.

1. Refuse if `03-projects/<slug>/` already exists.
2. Copy `00-meta/templates/project/` to `03-projects/<slug>/`.
3. Rename `PROJECT-index.md` to `<slug>-index.md`. In every copied file replace `<slug>` with the slug, `<Project name>` with a readable name, `YYYY-MM-DD` with today's date.
4. Fill in `CLAUDE.md` Scope and Out of scope from the goal (ask one or two questions if the goal is vague).
5. Add a line for the project under "03 Projects" in `index.md`.
6. Add a log entry to `log.md` (three lines at most).
7. Write `<slug>` to `.claude/active-project`.
8. Run `python3 tools/check-links.py` and report the result.
