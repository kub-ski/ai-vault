# Naming conventions

- Folders and files: lowercase, words joined by hyphens, no spaces (`my-shop`, `brand-voice.md`).
- Top-level folders have number prefixes (`00-meta` ... `99-archive`) so they sort the same everywhere.
- Add a date only to files that are inherently dated: decisions `YYYY-MM-DD-short-name.md`, journal entries, raw sources.
- Entity pages (a person, a tool, a place) use a singular noun: `supplier.md`, not `suppliers.md`.
- Project indexes carry the project name: `example-project-index.md`. A dozen files called `index.md` are impossible to tell apart in search and in the graph view.
- `CLAUDE.md` is always exactly that name, one per folder that needs rules.
- Links: Markdown, relative, for example `[Rules](../00-meta/rules.md)`. Never `[[wikilinks]]`.

## Related
- [Rules](rules.md): the working rules these names support.
