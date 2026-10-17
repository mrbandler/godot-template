@tool
extends RefCounted
# Audits a project's assets two ways and returns both in one pass:
#
# 1. "unused" — asset files that nothing appears to reference. A file counts
#    as used if either its res:// path OR its uid://... (resolved via
#    ResourceLoader.get_resource_uid, same as Godot's own importer uses)
#    shows up as plain text anywhere in the project's text-based files.
#    Checking the uid as well as the path matters because a scene can
#    reference a resource purely by uid="uid://..." with a stale path=
#    string sitting right next to it — a path-only search would wrongly
#    call that resource unused.
# 2. "oversized" — image files whose pixel dimensions are large enough
#    (default: either side over 2048px) that they are a common, easy-to-miss
#    cause of bloated exports and slow imports, independent of whether the
#    image is referenced anywhere.
#
# Both heuristics are static: they cannot see references built at runtime
# from a variable, and "oversized" is a size judgement call, not a defect —
# review before deleting or resizing anything.

const ASSET_EXTENSIONS := [
	"png", "jpg", "jpeg", "webp", "svg", "bmp", "hdr", "exr",
	"ogg", "wav", "mp3",
	"ttf", "otf", "woff", "woff2",
	"tres", "res", "theme",
	"glb", "gltf", "obj", "fbx", "mesh",
]
const TEXT_EXTENSIONS := ["tscn", "tres", "gd", "cs", "cfg", "import", "theme"]
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "bmp"]
const SKIP_DIRS := [".godot", ".git", "addons/unused_resource_finder"]
const OVERSIZED_DIMENSION_PX := 2048

func scan(root: String = "res://") -> Dictionary:
	var all_entries: Array = []
	_walk(root, all_entries)

	var assets: Array = []
	var text_blob := ""
	for entry in all_entries:
		var ext: String = entry["path"].get_extension().to_lower()
		if ext in ASSET_EXTENSIONS:
			assets.append(entry)
		if ext in TEXT_EXTENSIONS:
			var f := FileAccess.open(entry["path"], FileAccess.READ)
			if f:
				text_blob += f.get_as_text()
				text_blob += "\n"
				f.close()

	var orphans: Array = []
	var oversized: Array = []
	for asset in assets:
		var path: String = asset["path"]
		if not _is_referenced(path, text_blob):
			orphans.append(asset)
		var ext: String = path.get_extension().to_lower()
		if ext in IMAGE_EXTENSIONS:
			var dims := _image_dimensions(path)
			if dims.x > OVERSIZED_DIMENSION_PX or dims.y > OVERSIZED_DIMENSION_PX:
				oversized.append({"path": path, "size": asset["size"], "width": int(dims.x), "height": int(dims.y)})

	orphans.sort_custom(func(a, b): return a["path"] < b["path"])
	oversized.sort_custom(func(a, b): return (a["width"] * a["height"]) > (b["width"] * b["height"]))
	return {"unused": orphans, "oversized": oversized}

func _is_referenced(path: String, text_blob: String) -> bool:
	if text_blob.contains(path):
		return true
	var uid := ResourceLoader.get_resource_uid(path)
	if uid != ResourceUID.INVALID_ID:
		var uid_text := ResourceUID.id_to_text(uid)
		if text_blob.contains(uid_text):
			return true
	return false

func _image_dimensions(path: String) -> Vector2i:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return Vector2i.ZERO
	return Vector2i(img.get_width(), img.get_height())

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
				results.append({"path": full_path, "size": FileAccess.get_file_as_bytes(full_path).size()})
		entry = dir.get_next()
	dir.list_dir_end()
