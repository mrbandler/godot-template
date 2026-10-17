@tool
extends RefCounted
# Finds broken resource references two ways:
# 1. Plain res:// path strings (path="res://..." in scenes/resources, or
#    preload()/load() calls in scripts) that no longer point to a file on disk.
# 2. uid://... references, either on their own (preload("uid://...")) or
#    sitting next to a path= attribute on the same ext_resource line. A uid
#    is checked against Godot's own ResourceUID table first: if it still
#    resolves to a real file, the reference is NOT broken even though the
#    path string next to it has gone stale, because Godot repairs the path
#    from the uid automatically when the scene loads. Flagging every stale
#    path as broken — what a plain text search does — produces false
#    positives on any project that has moved files since Godot 4.4 started
#    writing uid= attributes into ext_resource lines.

const SCENE_EXTENSIONS := ["tscn", "tres"]
const SCRIPT_EXTENSIONS := ["gd", "cs"]
const SKIP_DIRS := [".godot", ".git", "addons/broken_reference_finder"]

func scan(root: String = "res://") -> Array:
	var all_entries: Array = []
	_walk(root, all_entries)

	var path_regex := RegEx.new()
	path_regex.compile("path=\"(res://[^\"]+)\"")
	var uid_regex := RegEx.new()
	uid_regex.compile("uid=\"(uid://[^\"]+)\"")
	var script_regex := RegEx.new()
	script_regex.compile("(?:preload|load)\\(\\s*[\"'](res://[^\"']+|uid://[^\"']+)[\"']")

	var broken: Array = []
	var seen := {}
	for full_path in all_entries:
		var ext: String = full_path.get_extension().to_lower()
		if ext in SCENE_EXTENSIONS:
			_scan_scene_file(full_path, path_regex, uid_regex, broken, seen)
		elif ext in SCRIPT_EXTENSIONS:
			_scan_script_file(full_path, script_regex, broken, seen)

	broken.sort_custom(func(a, b): return a["referenced_from"] < b["referenced_from"])
	return broken

# True if a uid string still points at a file that exists, meaning Godot
# can self-heal a stale path= on the same line.
func _uid_resolves(uid_string: String) -> bool:
	var id := ResourceUID.text_to_id(uid_string)
	if id == ResourceUID.INVALID_ID:
		return false
	if not ResourceUID.has_id(id):
		return false
	var resolved_path := ResourceUID.get_id_path(id)
	return not resolved_path.is_empty() and FileAccess.file_exists(resolved_path)

func _scan_scene_file(file_path: String, path_regex: RegEx, uid_regex: RegEx, broken: Array, seen: Dictionary) -> void:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return
	var line_num := 0
	while not f.eof_reached():
		var line := f.get_line()
		line_num += 1
		var pm := path_regex.search(line)
		if pm == null:
			continue
		var target: String = pm.get_string(1)
		var clean_target: String = target.split("::")[0]
		if clean_target == file_path:
			continue
		if FileAccess.file_exists(clean_target):
			continue
		var um := uid_regex.search(line)
		if um and _uid_resolves(um.get_string(1)):
			continue
		var key: String = file_path + "|" + str(line_num) + "|" + target
		if seen.has(key):
			continue
		seen[key] = true
		broken.append({"referenced_from": file_path, "line": line_num, "target": target})
	f.close()

func _scan_script_file(file_path: String, regex: RegEx, broken: Array, seen: Dictionary) -> void:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return
	var line_num := 0
	while not f.eof_reached():
		var line := f.get_line()
		line_num += 1
		for result in regex.search_all(line):
			var target: String = result.get_string(1)
			if target.begins_with("uid://"):
				if _uid_resolves(target):
					continue
				var key: String = file_path + "|" + str(line_num) + "|" + target
				if not seen.has(key):
					seen[key] = true
					broken.append({"referenced_from": file_path, "line": line_num, "target": target})
				continue
			var clean_target: String = target.split("::")[0]
			if clean_target == file_path:
				continue
			if FileAccess.file_exists(clean_target):
				continue
			var key2: String = file_path + "|" + str(line_num) + "|" + target
			if not seen.has(key2):
				seen[key2] = true
				broken.append({"referenced_from": file_path, "line": line_num, "target": target})
	f.close()

func _walk(path: String, results: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry in [".", ".."]:
			entry = dir.get_next()
			continue
		var full_path: String = path.path_join(entry)
		var relative: String = full_path.replace("res://", "")
		if dir.current_is_dir():
			var skip := false
			for skip_dir in SKIP_DIRS:
				if relative.begins_with(skip_dir):
					skip = true
					break
			if not skip:
				_walk(full_path, results)
		else:
			if not entry.ends_with(".import"):
				results.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
