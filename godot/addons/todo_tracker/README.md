# Todo Tracker

Every `TODO`, `FIXME`, `HACK`, `BUG` and `NOTE` comment in your project, in one
dock, with a line and a file for each — plus room for whatever markers your
own team already uses that don't fit those five.

## Why a sixth tag matters

Most comment-scanning docks hardcode their tag list. If your studio writes
`// REVIEW(ana): check this math` or a C# team tags things `// PERF:`, those
comments either get ignored or you're stuck waiting on a plugin update. Todo
Tracker lets you type a tag name and, if the default `# TAG: text` shape
doesn't fit, your own regex, right from the dock toolbar. The tag gets its
own color, its own filter checkbox, and its own section in the exported
report, same as the five built-ins. It's saved per-project in a small config
file, so it's still there next time you open the editor.

## What it does

- Walks every `.gd`, `.cs`, `.shader` and `.gdshader` file under `res://` and
  pulls out comments matching `TODO`, `FIXME`, `HACK`, `BUG`, `NOTE`, and any
  custom tags you've added.
- Lists results with type, note text, file and line, color-coded per tag.
- Per-tag checkboxes hide or show a category instantly — handy once a scan
  turns up 40 TODOs and you only care about the three `BUG` ones right now.
- Double-click a row to jump straight to that line in the script editor.
- Re-scans automatically whenever a file is saved — no manual refresh needed
  mid-session.
- "Export Markdown" writes a `todo_report.md` checklist, grouped by tag,
  ready to paste into a PR description or an issue.

## Installing it

Drop `addons/todo_tracker` into your project's `addons/` folder, then enable
**Todo Tracker** under **Project > Project Settings > Plugins**. A new dock
tab appears on the left.

## Adding your own tag

In the dock, find the "Custom tag" row below the filter checkboxes. Type a
name (say, `REVIEW`) and click **Add Tag** — it'll match `# REVIEW: ...`
comments right away, same shape as the built-ins. If your convention looks
different, e.g. `// REVIEW(ana): fix this before merge`, type your own regex
with one capture group for the note text, for example:

```
#\s*REVIEW\(([a-z]+)\):\s*(.*)
```

and the dock will capture the reviewer name as the note. Tags you add stick
around across editor sessions for that project.

## A quick example

```gdscript
# TODO: persist high_score to a save file
# FIXME: jump buffering is missing, input feels unresponsive near ledges
# REVIEW(ana): double check this damage formula before the next build
```

Each line shows up instantly, color-coded, with its file and line number.

## Works with

Godot 4.2 and later (tested on 4.7).

## License

MIT — see `LICENSE`.
