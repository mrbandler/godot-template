# Changelog

## 1.1.0 — 2026-10-11
- Now checks `uid="uid://..."` attributes on `ext_resource` lines (and bare `preload("uid://...")`/`load("uid://...")` calls) against Godot's own `ResourceUID` table before reporting a reference as broken. A stale `path=` string next to a uid that still resolves is self-healed by Godot on load, so it is no longer reported as a false positive.

## 1.0.0 — 2026-10-11
- Initial release.
- Scans every `.tscn` and `.tres` file for `path="res://..."` entries.
- Scans every `.gd` and `.cs` file for `preload()`/`load()` calls with a string path.
- Flags any referenced `res://` path whose target file does not exist.
- Shows the exact file and line number for each broken reference.
- Double-click a result to reveal the containing file in your system file manager.
- "Export Markdown" button writes a `broken_references.md` checklist.
