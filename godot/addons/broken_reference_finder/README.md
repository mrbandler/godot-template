# Broken Reference Finder

Finds `res://` paths in your scenes, resources and scripts that point at
files which no longer exist — and knows when a path only *looks* broken
because Godot already repaired it through a `uid://`.

## The false-positive problem this solves

A plain text search for `path="res://old/sprite.png"` will flag that as
broken the moment the file moves, even though Godot scenes also carry a
`uid="uid://..."` right next to the path, and Godot resolves the resource by
that uid first — repairing the stale path silently on load. A scanner that
only checks the path reports a false positive on every project that's had
assets reorganized. This one checks the uid against Godot's own
`ResourceUID` table before deciding anything is actually broken, so you only
see the references that genuinely need fixing.

## What it checks

- Every `.tscn` and `.tres` file, for `path="res://..."` entries in
  `ext_resource`/`sub_resource` lines (plus the `uid="uid://..."` that often
  sits right beside them).
- Every `.gd` and `.cs` file, for `preload(...)` and `load(...)` calls using
  either a `res://` or a bare `uid://` string.
- Only string-literal paths and uids — a path assembled at runtime from a
  variable is outside what any static scan can see, so treat the results as
  a strong lead, not a guarantee.

## What you get back

A list with the exact file and line number of each genuinely broken
reference (uid-repairable ones are left out), double-click to reveal the
containing file in your system file manager, and an **Export Markdown**
button that writes `broken_references.md` so you can work through the list
outside the editor or hand it to someone else.

## Setup

Copy `addons/broken_reference_finder` into your project's `addons/` folder
and enable **Broken Reference Finder** under **Project > Project Settings >
Plugins**. Use the dock tab's **Scan Project** button after a rename pass,
after deleting old art, or right before you cut a release.

## Works with

Godot 4.2 and later (tested on 4.7).

## License

MIT — see `LICENSE`.
