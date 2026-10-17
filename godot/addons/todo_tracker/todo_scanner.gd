@tool
extends RefCounted
# Walks res:// and collects TODO / FIXME / HACK / BUG / NOTE comments from script
# files, plus any project-defined custom tags (see custom_tags.cfg) matched by
# their own regex — so a team's own conventions (REVIEW(name):, PERF:, TODO.md
# style markers, whatever a .cs shop already uses) show up in the same dock.

const TAGS := ["TODO", "FIXME", "HACK", "BUG", "NOTE"]
const SCRIPT_EXTENSIONS := ["gd", "cs", "shader", "gdshader"]
const CONFIG_PATH := "res://addons/todo_tracker/custom_tags.cfg"

var _regex := RegEx.new()
var _custom_tags: Array = [] # [{ "name": String, "regex": RegEx }]

func _init() -> void:
	# Matches a line comment starting with one of the tags, optionally followed
	# by ":" or "-" and then the rest of the note.
	var pattern := "#\\s*(%s)\\b[:\\-]?\\s*(.*)" % "|".join(TAGS)
	_regex.compile(pattern)
	_load_custom_tags()

func _load_custom_tags() -> void:
	_custom_tags.clear()
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for key in cfg.get_section_keys("custom_tags"):
		var raw_pattern: String = cfg.get_value("custom_tags", key, "")
		# An empty pattern falls back to the same comment-tag shape as the
		# built-ins. A non-empty one is the user's own regex and must capture
		# the note text in its first group, so teams can match whatever
		# comment convention they already use (not just "# TAG: text").
		var pattern: String = raw_pattern
		if pattern.is_empty():
			pattern = "#\\s*%s\\b[:\\-]?\\s*(.*)" % key
		var regex := RegEx.new()
		if regex.compile(pattern) == OK:
			_custom_tags.append({"name": key, "regex": regex})

func get_custom_tag_names() -> Array:
	return _custom_tags.map(func(t): return t["name"])

func add_custom_tag(tag_name: String, pattern: String) -> bool:
	var clean_name := tag_name.strip_edges().to_upper()
	if clean_name.is_empty() or clean_name in TAGS:
		return false
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH) # ignore error, may not exist yet
	cfg.set_value("custom_tags", clean_name, pattern.strip_edges())
	if cfg.save(CONFIG_PATH) != OK:
		return false
	_load_custom_tags()
	return true

func scan(root: String = "res://", skip_dirs: PackedStringArray = ["addons/todo_tracker", ".godot"]) -> Array:
	var results: Array = []
	_scan_dir(root, skip_dirs, results)
	results.sort_custom(func(a, b):
		if a["file"] == b["file"]:
			return a["line"] < b["line"]
		return a["file"] < b["file"]
	)
	return results

func _scan_dir(path: String, skip_dirs: PackedStringArray, results: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry in [".", "..", ".git", ".import"]:
			entry = dir.get_next()
			continue
		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			var relative := full_path.replace("res://", "")
			var skip := false
			for skip_dir in skip_dirs:
				if relative.begins_with(skip_dir):
					skip = true
					break
			if not skip:
				_scan_dir(full_path, skip_dirs, results)
		else:
			var ext := entry.get_extension().to_lower()
			if ext in SCRIPT_EXTENSIONS:
				_scan_file(full_path, results)
		entry = dir.get_next()
	dir.list_dir_end()

func _scan_file(path: String, results: Array) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var line_number := 0
	while not file.eof_reached():
		var line := file.get_line()
		line_number += 1
		var m := _regex.search(line)
		if m:
			results.append({
				"type": m.get_string(1),
				"text": m.get_string(2).strip_edges(),
				"file": path,
				"line": line_number,
			})
			continue
		for custom in _custom_tags:
			var cm: RegExMatch = custom["regex"].search(line)
			if cm:
				var note := cm.get_string(1) if cm.get_group_count() >= 1 else ""
				results.append({
					"type": custom["name"],
					"text": note.strip_edges(),
					"file": path,
					"line": line_number,
				})
				break
	file.close()
