# Changelog

## 1.1.0 — 2026-10-11
- Custom tags: define your own tag name and, optionally, your own regex pattern (so a convention like `REVIEW(name):` or a C#-only shop's own marker works, not just the five built-ins). Custom tags get their own filter toggle, color, export section and status count, saved in `custom_tags.cfg` next to the plugin so they survive a project reopen.

## 1.0.0 — 2026-10-10
- Initial release.
- Scans `.gd`, `.cs` and shader files for `TODO`, `FIXME`, `HACK`, `BUG` and `NOTE` comments.
- Dock panel with per-tag colored results, counts, and filter toggles.
- Double-click a result to jump to that line in the script editor.
- Auto-refreshes whenever the filesystem changes.
- "Export Markdown" button writes a `todo_report.md` checklist grouped by tag.
